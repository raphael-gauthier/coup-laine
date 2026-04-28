// lib/presentation/clients/clients_list_screen.dart
import 'package:flutter/material.dart' show FloatingActionButton, RefreshIndicator, ScaffoldMessenger, SegmentedButton, ButtonSegment, SnackBar;
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models/client.dart';
import '../../state/providers.dart';

enum _Filter { all, waiting }

final _filterProvider = StateProvider<_Filter>((_) => _Filter.all);

final clientsAsyncProvider = FutureProvider<List<Client>>((ref) {
  return ref.watch(clientRepositoryProvider).listAll();
});

final clientsPendingProvider = FutureProvider<int>((ref) async {
  final clients = ref.watch(clientRepositoryProvider);
  return (await clients.listNeedingRecompute()).length;
});

class ClientsListScreen extends ConsumerWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final filter = ref.watch(_filterProvider);
    final async = ref.watch(clientsAsyncProvider);

    return FScaffold(
      child: async.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final waiting = all.where((c) => c.isWaiting).toList();
          final list = filter == _Filter.waiting ? waiting : all;
          final pending = ref.watch(clientsPendingProvider).value ?? 0;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(clientsAsyncProvider);
                  ref.invalidate(clientsPendingProvider);
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Page heading
                            Text(
                              l.clientsListTitle,
                              style: theme.typography.xl3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Stats row
                            Text(
                              '${l.clientsCountFmt(all.length)} · ${l.clientsWaitingCountFmt(waiting.length)}',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Filter row
                            SegmentedButton<_Filter>(
                              segments: [
                                ButtonSegment(value: _Filter.all, label: Text(l.clientsFilterAll)),
                                ButtonSegment(value: _Filter.waiting, label: Text(l.clientsFilterWaiting)),
                              ],
                              selected: {filter},
                              onSelectionChanged: (s) =>
                                  ref.read(_filterProvider.notifier).state = s.first,
                            ),
                            const SizedBox(height: 16),
                            // Recompute banner
                            if (pending > 0) ...[
                              FCard(
                                child: Row(
                                  children: [
                                    Icon(
                                      FIcons.triangleAlert,
                                      color: theme.colors.destructive,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '$pending client(s) sans distances calculées',
                                        style: theme.typography.sm,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FButton(
                                      variant: FButtonVariant.outline,
                                      size: FButtonSizeVariant.sm,
                                      onPress: () async {
                                        final sync = ref.read(distanceMatrixSyncProvider);
                                        final fixed = await sync.retryAllPending();
                                        ref.invalidate(clientsPendingProvider);
                                        ref.invalidate(clientsAsyncProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('$fixed client(s) recalculés')),
                                          );
                                        }
                                      },
                                      child: Text(l.clientsRetryRecompute.split(' ').first),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Client list or empty state
                    if (list.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  FIcons.users,
                                  size: 56,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l.emptyClientsTitle,
                                  style: theme.typography.xl.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colors.foreground,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.emptyClientsBody,
                                  textAlign: TextAlign.center,
                                  style: theme.typography.sm.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        sliver: SliverList.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 0),
                          itemBuilder: (_, i) => _ClientTile(client: list[i]),
                        ),
                      ),
                  ],
                ),
              ),
              // FAB (Material; styled cleanly enough)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => context.push('/clients/new'),
                  child: const Icon(FIcons.userPlus),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final Client client;
  const _ClientTile({required this.client});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final isOverdue = client.lastShearingDate != null &&
        DateTime.now().difference(client.lastShearingDate!).inDays > 395;

    final lastShearing = client.lastShearingDate == null
        ? l.clientsLastShearingNever
        : l.clientsLastShearingFmt(
            DateFormat('dd/MM/yyyy').format(client.lastShearingDate!),
          );

    final badges = <Widget>[
      if (client.isWaiting)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: FBadge(child: Text(l.clientsBadgeWaiting)),
        ),
      if (isOverdue)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: FBadge(variant: FBadgeVariant.destructive, child: Text(l.clientsBadgeOverdue)),
        ),
      if (client.needsDistanceRecompute)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: FBadge(variant: FBadgeVariant.secondary, child: Text(l.clientsBadgeRecompute.split(' ').first)),
        ),
    ];

    return FTile(
      prefix: FAvatar.raw(
        size: 36,
        child: Text(
          _initials(client.name),
          style: theme.typography.sm.copyWith(
            color: theme.colors.primaryForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        client.name,
        style: theme.typography.md.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${client.city} · $lastShearing',
        style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
      ),
      suffix: badges.isNotEmpty
          ? Wrap(spacing: 0, runSpacing: 4, children: badges)
          : const Icon(FIcons.chevronRight),
      onPress: () => context.push('/clients/${client.id}'),
    );
  }
}
