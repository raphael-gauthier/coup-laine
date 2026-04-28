// lib/presentation/clients/clients_list_screen.dart
import 'package:flutter/material.dart' show ButtonSegment, FloatingActionButton, Material, MaterialType, RefreshIndicator, SegmentedButton;
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/client.dart';
import '../../state/providers.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';

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
      child: Material(
        type: MaterialType.transparency,
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
                        padding: AppSizes.rootScreenPadding.copyWith(bottom: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Page heading
                            Text(
                              l.clientsListTitle,
                              style: theme.typography.xl3.copyWith(
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
                              AppSectionCard(
                                icon: FIcons.triangleAlert,
                                iconBackground: theme.colors.destructive,
                                title: 'Distances',
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$pending client(s) sans distances calculées',
                                        style: theme.typography.sm,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    FButton(
                                      variant: FButtonVariant.outline,
                                      size: FButtonSizeVariant.sm,
                                      onPress: () async {
                                        final sync = ref.read(distanceMatrixSyncProvider);
                                        final fixed = await sync.retryAllPending();
                                        ref.invalidate(clientsPendingProvider);
                                        ref.invalidate(clientsAsyncProvider);
                                        if (context.mounted) {
                                          showFToast(
                                            context: context,
                                            title: Text('$fixed client(s) recalculés'),
                                          );
                                        }
                                      },
                                      child: const Text('Recalculer'),
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
                        hasScrollBody: false,
                        child: AppEmptyState(
                          illustrationAsset: 'assets/illustrations/empty-clients.svg',
                          title: l.emptyClientsTitle,
                          body: l.emptyClientsBody,
                          action: AppPrimaryButton(
                            label: l.clientsAddNew,
                            prefixIcon: FIcons.userPlus,
                            onPress: () => context.push('/clients/new'),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        sliver: SliverList.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
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

    final badges = <Widget>[];
    if (client.isWaiting) badges.add(AppBadge.waiting(context));
    if (isOverdue) badges.add(AppBadge.overdue(context));
    if (client.needsDistanceRecompute) badges.add(AppBadge.recompute(context));

    return AppListTile(
      prefix: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          _initials(client.name),
          style: theme.typography.sm.copyWith(
            color: theme.colors.primaryForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: client.name,
      subtitle: '${client.city} · $lastShearing',
      suffix: badges.isNotEmpty
          ? Wrap(spacing: 4, runSpacing: 4, children: badges)
          : Icon(FIcons.chevronRight, color: theme.colors.mutedForeground),
      onPress: () => context.push('/clients/${client.id}'),
    );
  }
}
