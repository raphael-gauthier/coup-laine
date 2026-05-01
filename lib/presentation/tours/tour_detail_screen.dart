// lib/presentation/tours/tour_detail_screen.dart
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

import '../../core/design_tokens.dart';
import '../../core/format_minutes.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/tour.dart';
import '../../domain/models/tour_stop.dart';
import '../../state/map_controller.dart';
import '../../state/providers.dart';
import '../widgets/animal_counts_badges.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_hero_card.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';


class TourDetailScreen extends ConsumerWidget {
  final int tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(tourByIdProvider(tourId));

    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(
          title: Text(async.value == null
              ? '...'
              : DateFormat('EEE d MMM yyyy', 'fr')
                  .format(async.value!.tour.plannedDate)),
          suffixes: [
            if (async.value != null &&
                async.value!.tour.status == TourStatus.planned)
              FButton.icon(
                onPress: () => context.push('/tours/$tourId/edit'),
                child: const Icon(FIcons.pencil),
              ),
            FButton.icon(
              onPress: async.value == null
                  ? null
                  : () => _share(async.value!, context, l),
              child: const Icon(FIcons.share2),
            ),
          ],
        ),
        child: async.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (bundle) {
            if (bundle == null) return const SizedBox.shrink();
            return _Body(bundle: bundle, tourId: tourId);
          },
        ),
      ),
    );
  }

  Future<void> _share(TourWithStops bundle, BuildContext context, AppLocalizations l) async {
    final dateLine = DateFormat('dd/MM/yyyy').format(bundle.tour.plannedDate);
    final lines = <String>[
      'Tournée du $dateLine',
      ...bundle.stops.map(
        (s) => '- ${s.clientNameSnapshot} : ${formatEuros(s.feeShareCents)}',
      ),
      'Total : ${formatEuros(bundle.tour.totalTravelFeeCents)}',
    ];
    await SharePlus.instance.share(
      ShareParams(text: lines.join('\n'), subject: 'Tournée du $dateLine'),
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
    final completed = bundle.tour.status == TourStatus.completed;
    final km = (bundle.tour.totalDistanceMeters / 1000).toStringAsFixed(1);
    final driveMin = bundle.tour.totalDriveSeconds ~/ 60;

    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card
          AppHeroCard(
            badge: completed
                ? AppBadge.completed(context)
                : AppBadge.planned(context),
            bigNumber: formatEuros(bundle.tour.totalTravelFeeCents),
            label: l.tourDetailFeeTotalCaption,
            subtitle: '$km km · ${formatDuration(driveMin)} de trajet · Départ ${formatHm(bundle.tour.startTimeMinutes)}',
          ),
          const SizedBox(height: AppSpacing.md),

          // Long-day badge
          if (_estimatedTourEnd(bundle) > 20 * 60) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: AppBadge.longDay(context),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Schedule section
          AppSectionCard(
            icon: FIcons.listOrdered,
            title: l.tourDetailScheduleTitle,
            child: Column(
              children: [
                for (var i = 0; i < bundle.stops.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _ScheduleRow(stop: bundle.stops[i], index: i + 1),
                ],
              ],
            ),
          ),

          // Mark-as-completed CTA
          if (!completed) ...[
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: l.tourDetailComplete,
              prefixIcon: FIcons.check,
              onPress: () => context.push('/tours/$tourId/complete'),
            ),
          ],
        ],
      ),
    );
  }

  int _estimatedTourEnd(TourWithStops bundle) {
    return bundle.tour.startTimeMinutes +
        (bundle.tour.totalDriveSeconds ~/ 60) +
        bundle.stops.fold<int>(
            0,
            (sum, s) =>
                sum +
                s.plannedPrestations.fold<int>(
                    0, (acc, a) => acc + a.qty * a.minutesSnapshot));
  }
}

class _ScheduleRow extends ConsumerWidget {
  final TourStop stop;
  final int index;
  const _ScheduleRow({required this.stop, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final note = stop.interventionNote;
    final clientId = stop.clientId;
    final source = stop.actualPrestations ?? stop.plannedPrestations;
    final counts = [
      for (final a in source)
        if (a.categoryIdSnapshot != null)
          AnimalCount(categoryId: a.categoryIdSnapshot!, count: a.qty),
    ];

    return FTile(
      prefix: Container(
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        clientId == null
            ? '${stop.clientNameSnapshot} ${l.tourDetailDeleted}'
            : stop.clientNameSnapshot,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${formatHm(stop.estimatedArrivalMinutes)} → '
            '${formatHm(stop.estimatedDepartureMinutes)} · '
            '${formatEuros(stop.feeShareCents)}',
          ),
          AnimalCountsBadges(
            counts: counts,
            mode: AnimalCountsBadgesMode.compact,
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.hairline),
            Text(
              note,
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      onPress: clientId == null
          ? null
          : () {
              ref.read(mapPendingFocusProvider.notifier).state = clientId;
              ref.read(mapSelectedClientIdProvider.notifier).state = clientId;
              context.go('/map');
            },
    );
  }
}
