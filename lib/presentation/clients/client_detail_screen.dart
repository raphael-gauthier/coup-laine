// lib/presentation/clients/client_detail_screen.dart
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/confirm_dialog.dart';
import 'client_actions.dart';
import '../../domain/models/client.dart';
import 'manual_history_entry_sheet.dart';
import '../../domain/models/intervention.dart';
import '../../domain/use_cases/client_status.dart';
import '../../infra/services/ors_routing_service.dart';
import '../../state/providers.dart';
import '../../state/providers/client_kpis.dart';
import '../widgets/animal_counts_badges.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_header.dart';
import '../widgets/app_kpi_row.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import 'clients_list_screen.dart' show clientsAsyncProvider, clientsPendingProvider;

final _clientByIdProvider =
    FutureProvider.family<(Client, ClientStatus)?, int>((ref, id) async {
  // Watch the FutureProvider for settings (not the repo Provider), so this
  // auto-refreshes when the season is reset or settings change.
  final settings = await ref.watch(settingsRepositoryFutureProvider.future);
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  return ref.watch(clientRepositoryProvider).findByIdWithStatus(id, seasonStart);
});

class ClientDetailScreen extends ConsumerWidget {
  final int clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clientByIdProvider(clientId));
    final l = AppLocalizations.of(context)!;

    return FScaffold(
      child: SafeArea(
        top: true,
        bottom: false,
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (record) {
            if (record == null) return const SizedBox.shrink();
            final client = record.$1;
            final status = record.$2;
            return Column(
              children: [
                AppHeader(
                  title: client.name,
                  subtitle: client.city,
                  actions: [
                    AppHeaderAction(
                      icon: FIcons.trash,
                      label: l.clientDetailDelete,
                      destructive: true,
                      onPress: () => _confirmDelete(context, ref, l),
                    ),
                  ],
                ),
                Expanded(
                  child: _Body(client: client, status: status),
                ),
                AppActionBar(
                  secondary: AppPrimaryButton(
                    label: l.clientHistoryAddAction,
                    variant: FButtonVariant.outline,
                    onPress: () => showManualHistoryEntrySheet(
                      context,
                      clientId: client.id,
                    ),
                  ),
                  primary: AppPrimaryButton(
                    label: l.clientDetailEdit,
                    variant: FButtonVariant.outline,
                    onPress: () => context.push('/clients/${client.id}/edit'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final ok = await showDestructiveConfirm(
      context,
      title: l.clientDetailDelete,
      body: l.clientDetailDeleteConfirm,
      confirmLabel: l.clientDetailDelete,
    );
    if (!ok) return;
    await ref.read(clientRepositoryProvider).delete(clientId);
    await ref.read(distanceMatrixRepositoryProvider).deleteForClient(clientId);
    ref.invalidate(_clientByIdProvider(clientId));
    ref.invalidate(clientsAsyncProvider);
    ref.invalidate(clientsPendingProvider);
    if (context.mounted) context.pop();
  }
}

class _Body extends ConsumerWidget {
  final Client client;
  final ClientStatus status;
  const _Body({required this.client, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final kpisAsync = ref.watch(clientKpisProvider(client.id));
    final plannedTourAsync = ref.watch(_plannedTourForClientProvider(client.id));

    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KpiRow synthèse
          kpisAsync.when(
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox.shrink(),
            data: (kpis) => AppKpiRow(
              cells: [
                AppKpiCell(
                  value: '${kpis.interventionCount}',
                  label: l.kpiLabelInterventions,
                ),
                AppKpiCell(
                  value: kpis.totalRevenueCents == 0
                      ? '—'
                      : formatEuros(kpis.totalRevenueCents),
                  label: l.kpiLabelRevenue,
                  valueColor: theme.colors.secondary,
                ),
                AppKpiCell(
                  value: kpis.lastInterventionDate == null
                      ? '—'
                      : _relativeShort(kpis.lastInterventionDate!),
                  label: l.kpiLabelLastVisit,
                ),
                AppKpiCell(
                  value: kpis.firstInterventionDate == null
                      ? '—'
                      : '${DateTime.now().year - kpis.firstInterventionDate!.year + 1}',
                  label: l.kpiLabelYears,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Status badge inline
          Row(
            children: [
              AppBadge.fromStatus(
                context,
                status: status,
                label: _statusLabel(l, status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Prochaine action
          plannedTourAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (date) => AppSectionCard(
              icon: FIcons.calendar,
              title: l.clientDetailNextActionTitle,
              child: date == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.clientDetailNoPlannedTour,
                          style: theme.typography.md.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppPrimaryButton(
                          label: l.clientDetailFindNearby,
                          onPress: status == ClientStatus.waiting
                              ? () => context.push('/proximity/${client.id}')
                              : null,
                        ),
                      ],
                    )
                  : Text(
                      l.clientDetailPlannedTourFmt(
                          DateFormat('EEEE d MMMM', 'fr').format(date)),
                      style: theme.typography.md.copyWith(
                        color: theme.colors.foreground,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Recompute banner (gardé)
          if (client.needsDistanceRecompute) ...[
            AppSectionCard(
              icon: FIcons.triangleAlert,
              title: l.commonDistancesTitle,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.clientDetailRecomputeBanner,
                      style: theme.typography.sm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    onPress: () async {
                      final sync = ref.read(distanceMatrixSyncProvider);
                      try {
                        await sync.recomputeForClient(client.id);
                        ref.invalidate(_clientByIdProvider(client.id));
                        ref.invalidate(clientsAsyncProvider);
                        ref.invalidate(clientsPendingProvider);
                      } on OrsException catch (e) {
                        if (context.mounted) {
                          showFToast(context: context, title: Text(e.message));
                        }
                      }
                    },
                    child: Text(l.clientDetailRetryRecompute),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Animaux
          if (client.animals.isNotEmpty) ...[
            AppSectionCard(
              icon: FIcons.pawPrint,
              title: l.clientFormSectionAnimals,
              child: AnimalCountsBadges(
                counts: client.animals,
                mode: AnimalCountsBadgesMode.detailed,
                style: theme.typography.md.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Coordonnées
          AppSectionCard(
            icon: FIcons.mapPin,
            title: l.clientDetailSectionAddress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.addressLabel, style: theme.typography.md),
                Text(
                  '${client.postcode} ${client.city}',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Phones
          if (client.phones.isNotEmpty) ...[
            AppSectionCard(
              icon: FIcons.phone,
              title: l.clientDetailSectionContact,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < client.phones.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(FIcons.phone,
                            color: theme.colors.mutedForeground, size: 16),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            client.phones[i],
                            style: tabularStyle(theme.typography.md),
                          ),
                        ),
                        if (i == 0)
                          Text(
                            l.clientDetailPhonePrincipal,
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: FButton(
                            variant: FButtonVariant.outline,
                            prefix: const Icon(FIcons.phone),
                            onPress: () =>
                                callPhone(context, client.phones[i]),
                            child: Text(l.commonCall),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FButton(
                            variant: FButtonVariant.outline,
                            prefix: const Icon(FIcons.messageCircle),
                            onPress: () =>
                                sendSms(context, client.phones[i]),
                            child: Text(l.commonSms),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Status & actions
          _StatusActionsCard(client: client, status: status, l: l),
          const SizedBox(height: AppSpacing.md),

          // Historique (3 derniers + lien)
          _InterventionsCard(clientId: client.id),
          const SizedBox(height: AppSizes.bottomScrollPadding),
        ],
      ),
    );
  }

  String _relativeShort(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays < 30) return 'il y a ${diff.inDays}j';
    final months = (diff.inDays / 30).round();
    if (months < 12) return 'il y a ${months}m';
    final years = (months / 12).round();
    return 'il y a ${years}an${years > 1 ? 's' : ''}';
  }
}

class _StatusActionsCard extends ConsumerWidget {
  final Client client;
  final ClientStatus status;
  final AppLocalizations l;
  const _StatusActionsCard(
      {required this.client, required this.status, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final waitingToggleDisabled = status == ClientStatus.banned ||
        status == ClientStatus.noAnimals ||
        status == ClientStatus.scheduled ||
        status == ClientStatus.done;

    return AppSectionCard(
      icon: FIcons.bellRing,
      title: l.clientDetailSectionStatus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FTile(
            title: Text(l.clientStatusWaiting),
            subtitle: waitingToggleDisabled
                ? Text(
                    l.clientDetailWaitingDisabledHintFmt(
                      _statusLabel(l, status),
                    ),
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  )
                : null,
            suffix: FSwitch(
              value: client.isWaiting,
              onChange: waitingToggleDisabled
                  ? null
                  : (v) async {
                      await ref
                          .read(clientRepositoryProvider)
                          .setWaiting(id: client.id, isWaiting: v);
                      ref.invalidate(_clientByIdProvider(client.id));
                      ref.invalidate(clientsAsyncProvider);
                    },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FButton(
            variant: client.isBanned
                ? FButtonVariant.outline
                : FButtonVariant.destructive,
            prefix: Icon(client.isBanned ? FIcons.shieldOff : FIcons.ban),
            onPress: () async {
              await ref
                  .read(clientRepositoryProvider)
                  .setBanned(client.id, !client.isBanned);
              ref.invalidate(_clientByIdProvider(client.id));
              ref.invalidate(clientsAsyncProvider);
            },
            child: Text(
              client.isBanned ? l.clientDetailUnban : l.clientDetailBan,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ResetToDefaultButton(client: client),
        ],
      ),
    );
  }
}

String _statusLabel(AppLocalizations l, ClientStatus status) => switch (status) {
      ClientStatus.defaultStatus => l.clientStatusDefault,
      ClientStatus.waiting => l.clientStatusWaiting,
      ClientStatus.scheduled => l.clientStatusScheduled,
      ClientStatus.done => l.clientStatusDone,
      ClientStatus.noAnimals => l.clientStatusNoAnimals,
      ClientStatus.banned => l.clientStatusBanned,
    };

class _ResetToDefaultButton extends ConsumerWidget {
  final Client client;
  const _ResetToDefaultButton({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final plannedTourAsync = ref.watch(_plannedTourForClientProvider(client.id));

    return plannedTourAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tourDate) {
        final blocked = tourDate != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FButton(
              variant: FButtonVariant.outline,
              prefix: const Icon(FIcons.rotateCcw),
              onPress: blocked
                  ? null
                  : () async {
                      final repo = ref.read(clientRepositoryProvider);
                      await repo.setWaiting(id: client.id, isWaiting: false);
                      await repo.setBanned(client.id, false);
                      ref.invalidate(_clientByIdProvider(client.id));
                      ref.invalidate(clientsAsyncProvider);
                    },
              child: Text(l.clientDetailResetToDefault),
            ),
            if (blocked) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.clientDetailResetDisabledFmt(
                  DateFormat('dd/MM/yyyy').format(tourDate),
                ),
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

final _plannedTourForClientProvider =
    FutureProvider.family.autoDispose<DateTime?, int>((ref, clientId) async {
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final db = ref.watch(appDatabaseProvider);
  final seasonEpochDays = seasonStart.millisecondsSinceEpoch ~/ 86400000;

  final rows = await (db.select(db.tourStopsTable).join([
    innerJoin(db.toursTable, db.toursTable.id.equalsExp(db.tourStopsTable.tourId)),
  ])
        ..where(
          db.tourStopsTable.clientId.equals(clientId) &
              db.toursTable.status.equals('planned') &
              db.toursTable.plannedDate.isBiggerOrEqualValue(seasonEpochDays),
        )
        ..orderBy([
          OrderingTerm.asc(db.toursTable.plannedDate),
        ])
        ..limit(1))
      .get();

  if (rows.isEmpty) return null;
  final tour = rows.first.readTable(db.toursTable);
  return DateTime.fromMillisecondsSinceEpoch(tour.plannedDate * 86400000);
});

class _InterventionsCard extends ConsumerWidget {
  final int clientId;
  const _InterventionsCard({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final async = ref.watch(historyForClientProvider(clientId));

    return AppSectionCard(
      icon: FIcons.history,
      title: l.clientDetailSectionHistory,
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(child: FCircularProgress()),
        ),
        error: (e, _) => Text('$e'),
        data: (items) {
          final visible = items.take(3).toList();
          final hasMore = items.length > visible.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (items.isEmpty)
                Text(
                  l.clientDetailHistoryEmpty,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                )
              else
                for (final it in visible) ...[
                  _InterventionTile(
                    intervention: it,
                    onTap: () => _openIntervention(context, ref, it),
                  ),
                  if (it != visible.last)
                    const SizedBox(height: AppSpacing.xs),
                ],
              if (hasMore) ...[
                const SizedBox(height: AppSpacing.sm),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () =>
                      context.push('/clients/$clientId/history'),
                  child: Text(l.clientDetailHistoryViewAll),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openIntervention(
      BuildContext context, WidgetRef ref, Intervention it) async {
    if (it.kind == InterventionKind.tour && it.tourId != null) {
      context.push('/tours/${it.tourId}');
      return;
    }
    if (it.kind == InterventionKind.manual && it.manualEntryId != null) {
      final manualRepo = ref.read(manualHistoryRepositoryProvider);
      final all = await manualRepo.listForClient(clientId);
      final matches = all.where((e) => e.id == it.manualEntryId);
      final entry = matches.isEmpty ? null : matches.first;
      if (entry != null && context.mounted) {
        await showManualHistoryEntrySheet(
          context,
          clientId: clientId,
          existing: entry,
        );
      }
    }
  }
}

/// Tile pour une intervention dans la card historique de la fiche client.
/// Layout 2 colonnes :
/// - Gauche  : icône kind + breakdown (bold) + date avec année (muted italic)
/// - Droite  : revenu (bold accent) + durée (muted) en tabular
class _InterventionTile extends StatefulWidget {
  final Intervention intervention;
  final VoidCallback onTap;

  const _InterventionTile({
    required this.intervention,
    required this.onTap,
  });

  @override
  State<_InterventionTile> createState() => _InterventionTileState();
}

class _InterventionTileState extends State<_InterventionTile> {
  bool _pressed = false;

  String _breakdown(AppLocalizations l) {
    final parts = <String>[];
    for (final p in widget.intervention.prestations) {
      parts.add('${p.qty} ${p.nameSnapshot}');
      if (parts.length >= 3) break;
    }
    if (widget.intervention.prestations.length > 3) {
      parts.add(l.clientHistoryAndOthersFmt(
          widget.intervention.prestations.length - 3));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final it = widget.intervention;
    final breakdown = _breakdown(l);
    final dateStr = DateFormat('EEE d MMM yyyy', 'fr').format(it.date);
    final mainTitle = breakdown.isEmpty
        ? (it.kind == InterventionKind.tour
            ? l.clientHistoryKindTour
            : l.clientHistoryKindManual)
        : breakdown;

    final kindIcon = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colors.muted,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        it.kind == InterventionKind.manual
            ? FIcons.pencil
            : FIcons.scissors,
        size: 14,
        color: theme.colors.foreground,
      ),
    );

    Widget rightCol = const SizedBox.shrink();
    if (it.totalRevenueCents > 0 || it.totalMinutes > 0) {
      rightCol = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (it.totalRevenueCents > 0)
            Text(
              formatEuros(it.totalRevenueCents),
              style: tabularStyle(theme.typography.lg).copyWith(
                color: theme.colors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (it.totalMinutes > 0) ...[
            const SizedBox(height: 2),
            Text(
              formatDuration(it.totalMinutes),
              style: tabularStyle(theme.typography.sm).copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            padding: AppSizes.listTilePadding,
            decoration: BoxDecoration(
              color: theme.colors.card,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: theme.colors.border,
                width: AppSizes.hairlineBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    kindIcon,
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mainTitle,
                            style: theme.typography.lg.copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    rightCol,
                  ],
                ),
                if (it.note != null && it.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          FIcons.stickyNote,
                          size: 13,
                          color: theme.colors.mutedForeground,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            it.note!.trim(),
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
