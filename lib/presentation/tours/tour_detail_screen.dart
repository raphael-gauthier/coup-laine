// lib/presentation/tours/tour_detail_screen.dart
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/tour.dart';
import '../../domain/models/tour_stop.dart';
import '../../state/map_controller.dart';
import '../../state/providers.dart';
import '../../state/providers/tour_kpis.dart';
import '../widgets/animal_counts_badges.dart';
import '../widgets/app_action_bar.dart';
import '../widgets/app_header.dart';
import '../widgets/app_kpi_row.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';
import '../widgets/app_stat.dart';
import '../widgets/mini_map.dart';

final _tourWaypointsProvider = FutureProvider.family
    .autoDispose<List<LatLng>, int>((ref, tourId) async {
  final bundle = await ref.watch(tourByIdProvider(tourId).future);
  if (bundle == null) return const [];
  final repo = ref.watch(clientRepositoryProvider);
  final out = <LatLng>[];
  for (final s in bundle.stops) {
    final cid = s.clientId;
    if (cid == null) continue;
    final c = await repo.findById(cid);
    if (c != null) out.add(LatLng(c.coordinates.lat, c.coordinates.lon));
  }
  return out;
});

class TourDetailScreen extends ConsumerWidget {
  final int tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(tourByIdProvider(tourId));

    return FScaffold(
      child: SafeArea(
        top: true,
        bottom: false,
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (bundle) {
            if (bundle == null) return const SizedBox.shrink();
            final completed = bundle.tour.status == TourStatus.completed;
            final dateStr = DateFormat('EEE d MMM yyyy', 'fr')
                .format(bundle.tour.plannedDate);
            final dayStr = DateFormat('EEEE', 'fr')
                .format(bundle.tour.plannedDate);
            final statusLabel = completed ? l.tourStatusCompleted : l.tourStatusPlanned;
            return Column(
              children: [
                AppHeader(
                  title: dateStr,
                  subtitle:
                      '${dayStr[0].toUpperCase()}${dayStr.substring(1)} · ${bundle.stops.length} stops · $statusLabel',
                ),
                Expanded(
                  child: _Body(bundle: bundle, tourId: tourId),
                ),
                if (!completed)
                  AppActionBar(
                    primary: AppPrimaryButton(
                      label: l.tourDetailComplete,
                      onPress: () => context.push('/tours/$tourId/complete'),
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

class _Body extends ConsumerWidget {
  final TourWithStops bundle;
  final int tourId;
  const _Body({required this.bundle, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final completed = bundle.tour.status == TourStatus.completed;
    final km = (bundle.tour.totalDistanceMeters / 1000).toStringAsFixed(1);
    final driveMin = bundle.tour.totalDriveSeconds ~/ 60;

    final source = completed
        ? bundle.stops
            .map((s) => s.actualPrestations ?? s.plannedPrestations)
            .toList()
        : bundle.stops.map((s) => s.plannedPrestations).toList();
    final summary = aggregatePrestations(source);
    final prestationsCents =
        summary.fold<int>(0, (s, r) => s + r.totalCents);
    final totalCents = prestationsCents + bundle.tour.totalTravelFeeCents;
    final totalAnimals = source.fold<int>(
        0, (s, list) => s + list.fold<int>(0, (a, p) => a + p.qty));
    final prestationsMin = source.fold<int>(
        0,
        (s, list) =>
            s + list.fold<int>(0, (a, p) => a + p.qty * p.minutesSnapshot));
    final totalMin = driveMin + prestationsMin;

    final settingsAsync = ref.watch(settingsRepositoryFutureProvider);
    final waypointsAsync = ref.watch(_tourWaypointsProvider(tourId));
    final base = settingsAsync.value?.baseCoordinates;

    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppKpiRow(
            cells: [
              AppKpiCell(value: km, label: l.kpiLabelKm),
              AppKpiCell(value: formatDuration(totalMin), label: l.kpiLabelDuration),
              AppKpiCell(
                value: formatEuros(totalCents),
                label: l.kpiLabelRevenue,
                valueColor: theme.colors.secondary,
              ),
              AppKpiCell(value: '$totalAnimals', label: l.kpiLabelAnimals),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // MiniMap
          if (base != null)
            waypointsAsync.when(
              loading: () => const SizedBox(height: 160),
              error: (_, __) => const SizedBox.shrink(),
              data: (wps) {
                if (wps.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MiniMap(
                    base: LatLng(base.lat, base.lon),
                    waypoints: wps,
                    height: 160,
                    onTap: () {
                      ref.read(mapPendingFocusProvider.notifier).state = null;
                      context.go('/map');
                    },
                  ),
                );
              },
            ),

          // Étapes
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.xs, bottom: AppSpacing.xs),
            child: Text(
              l.tourDetailScheduleTitle,
              style: theme.typography.xl
                  .copyWith(color: theme.colors.foreground),
            ),
          ),
          for (var i = 0; i < bundle.stops.length; i++) ...[
            _StopTile(stop: bundle.stops[i], index: i + 1, l: l),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.md),

          // Résumé prestations
          AppSectionCard(
            icon: FIcons.listChecks,
            title: l.tourDetailPrestationSummaryTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in summary)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: theme.typography.md
                                .copyWith(color: theme.colors.foreground),
                          ),
                        ),
                        Text(
                          '×${s.qty}',
                          style: tabularStyle(theme.typography.sm).copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 72,
                          child: Text(
                            formatEuros(s.totalCents),
                            textAlign: TextAlign.end,
                            style: tabularStyle(theme.typography.md).copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (bundle.tour.totalTravelFeeCents > 0) ...[
                  Container(
                    height: AppSizes.hairlineBorder,
                    color: theme.colors.border,
                    margin: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.tourDetailFraisDeplacement,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Text(
                          formatEuros(bundle.tour.totalTravelFeeCents),
                          style: tabularStyle(theme.typography.sm).copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Container(
                  height: AppSizes.hairlineBorder,
                  color: theme.colors.border,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.tourDetailTotal,
                          style: theme.typography.lg.copyWith(
                            color: theme.colors.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formatEuros(totalCents),
                        style: tabularStyle(theme.typography.xl).copyWith(
                          color: theme.colors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.bottomScrollPadding),
        ],
      ),
    );
  }
}

class _StopTile extends ConsumerWidget {
  final TourStop stop;
  final int index;
  final AppLocalizations l;
  const _StopTile({required this.stop, required this.index, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final clientId = stop.clientId;
    final source = stop.actualPrestations ?? stop.plannedPrestations;
    final counts = [
      for (final a in source)
        if (a.categoryIdSnapshot != null)
          AnimalCount(categoryId: a.categoryIdSnapshot!, count: a.qty),
    ];

    final indexBadge = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: theme.colors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: theme.typography.sm.copyWith(
          color: theme.colors.primaryForeground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final stopMin =
        source.fold<int>(0, (sum, p) => sum + p.qty * p.minutesSnapshot);
    final stopPrestationsCents =
        source.fold<int>(0, (sum, p) => sum + p.qty * p.priceCentsSnapshot);
    final stopTotalCents = stopPrestationsCents + stop.feeShareCents;

    final note = stop.interventionNote?.trim();
    final hasNote = note != null && note.isNotEmpty;

    return AppListTile(
      variant: AppListTileVariant.rich,
      prefix: indexBadge,
      title: clientId == null
          ? '${stop.clientNameSnapshot} ${l.tourDetailDeleted}'
          : stop.clientNameSnapshot,
      subtitle:
          '${formatHm(stop.estimatedArrivalMinutes)} → ${formatHm(stop.estimatedDepartureMinutes)}',
      metadata: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xxs,
            children: [
              AppStat(
                icon: FIcons.banknote,
                value: formatEuros(stopTotalCents),
              ),
              AppStat(
                icon: FIcons.clock,
                value: formatDuration(stopMin),
              ),
              if (counts.isNotEmpty)
                AnimalCountsBadges(
                  counts: counts,
                  mode: AnimalCountsBadgesMode.compact,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
            ],
          ),
          if (hasNote) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  FIcons.stickyNote,
                  size: 14,
                  color: theme.colors.mutedForeground,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    note,
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
          ],
        ],
      ),
      suffix: Icon(FIcons.chevronRight, color: theme.colors.mutedForeground),
      onTap: clientId == null
          ? null
          : () {
              ref.read(mapPendingFocusProvider.notifier).state = clientId;
              ref.read(mapSelectedClientIdProvider.notifier).state = clientId;
              context.go('/map');
            },
    );
  }
}
