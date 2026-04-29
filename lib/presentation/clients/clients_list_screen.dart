// lib/presentation/clients/clients_list_screen.dart
import 'package:flutter/material.dart' show FloatingActionButton, Material, MaterialType, RefreshIndicator;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../core/text_search.dart';
import '../../domain/models/client.dart';
import '../../domain/models/settings.dart';
import '../../domain/use_cases/client_status.dart';
import '../../state/providers.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';

final _visibleStatusesProvider = StateProvider<Set<ClientStatus>>(
  (_) => ClientStatus.values.toSet(),
);
final _searchQueryProvider = StateProvider<String>((_) => '');

final clientsAsyncProvider =
    FutureProvider<List<(Client, ClientStatus)>>((ref) async {
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  return ref.watch(clientRepositoryProvider).listAllWithStatus(seasonStart);
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
    final visible = ref.watch(_visibleStatusesProvider);
    final query = ref.watch(_searchQueryProvider);
    final async = ref.watch(clientsAsyncProvider);

    return FScaffold(
      child: SafeArea(
        top: true,
        bottom: false,
        child: Material(
          type: MaterialType.transparency,
          child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (all) {
          final waiting = all.where((r) => r.$2 == ClientStatus.waiting).toList();
          final base = all.where((r) => visible.contains(r.$2)).toList();
          final normalizedQuery = normalize(query.trim());
          final list = [...base.where((r) => matchesClient(r.$1, normalizedQuery))]
            ..sort((a, b) {
              final byCity = normalize(a.$1.city).compareTo(normalize(b.$1.city));
              if (byCity != 0) return byCity;
              return normalize(a.$1.name).compareTo(normalize(b.$1.name));
            });
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
                            const SizedBox(height: AppSpacing.xxs),
                            // Stats row
                            Text(
                              '${l.clientsCountFmt(all.length)} · ${l.clientsWaitingCountFmt(waiting.length)}',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Status filter chips
                            _StatusChipsRow(
                              visible: visible,
                              onToggle: (s) {
                                final next = {...visible};
                                if (!next.add(s)) next.remove(s);
                                ref.read(_visibleStatusesProvider.notifier).state = next;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Search field
                            const _SearchField(),
                            const SizedBox(height: AppSpacing.md),
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
                              const SizedBox(height: AppSpacing.xs),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Client list or empty state
                    if (visible.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              'Aucun statut sélectionné',
                              style: theme.typography.sm,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    else if (list.isEmpty)
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
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSizes.bottomScrollPadding),
                        sliver: SliverList.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) => _ClientTile(
                            client: list[i].$1,
                            status: list[i].$2,
                          ),
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
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(_searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FTextField(
      control: FTextFieldControl.managed(
        controller: _controller,
        onChange: (v) => ref.read(_searchQueryProvider.notifier).state = v.text,
      ),
      hint: l.clientsSearchHint,
    );
  }
}

class _ClientTile extends ConsumerWidget {
  final Client client;
  final ClientStatus status;
  const _ClientTile({required this.client, required this.status});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final settingsAsync = ref.watch(_settingsForChipProvider);
    final hex = settingsAsync.value == null
        ? '#9CA3AF'
        : _hexForStatus(settingsAsync.value!, status);
    final dotColor = _hexToColor(hex);

    return AppListTile(
      prefix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Container(
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
        ],
      ),
      title: client.name,
      subtitle:
          '${client.city} · ${l.clientsListSheepCountFmt(client.sheepCount)}',
      suffix: client.needsDistanceRecompute
          ? AppBadge.recompute(context)
          : Icon(FIcons.chevronRight, color: theme.colors.mutedForeground),
      onPress: () => context.push('/clients/${client.id}'),
    );
  }
}

class _StatusChipsRow extends StatelessWidget {
  final Set<ClientStatus> visible;
  final ValueChanged<ClientStatus> onToggle;
  const _StatusChipsRow({required this.visible, required this.onToggle});

  String _label(AppLocalizations l, ClientStatus s) => switch (s) {
        ClientStatus.defaultStatus => l.clientStatusDefault,
        ClientStatus.waiting => l.clientStatusWaiting,
        ClientStatus.scheduled => l.clientStatusScheduled,
        ClientStatus.done => l.clientStatusDone,
        ClientStatus.noSheep => l.clientStatusNoSheep,
        ClientStatus.banned => l.clientStatusBanned,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final s in ClientStatus.values)
          _StatusChip(
            status: s,
            label: _label(l, s),
            selected: visible.contains(s),
            onTap: () => onToggle(s),
          ),
      ],
    );
  }
}

class _StatusChip extends ConsumerWidget {
  final ClientStatus status;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.status,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final settingsAsync = ref.watch(_settingsForChipProvider);
    final hex = settingsAsync.value == null
        ? '#9CA3AF'
        : _hexForStatus(settingsAsync.value!, status);
    final color = _hexToColor(hex);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(0x33) : theme.colors.muted,
          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
          border: Border.all(
            color: selected ? color : theme.colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: theme.typography.xs.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _hexForStatus(Settings s, ClientStatus status) => switch (status) {
      ClientStatus.defaultStatus => s.markerDefaultColor,
      ClientStatus.waiting => s.markerWaitingColor,
      ClientStatus.scheduled => s.markerScheduledColor,
      ClientStatus.done => s.markerDoneColor,
      ClientStatus.noSheep => s.markerNoSheepColor,
      ClientStatus.banned => s.markerBannedColor,
    };

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
}

final _settingsForChipProvider = FutureProvider<Settings?>(
  (ref) => ref.watch(settingsRepositoryProvider).read(),
);
