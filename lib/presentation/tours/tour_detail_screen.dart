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
import '../../domain/models/tour.dart';
import '../../domain/models/tour_stop.dart';
import '../../state/providers.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_hero_card.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';

final _tourByIdProvider =
    FutureProvider.autoDispose.family<TourWithStops?, int>((ref, id) {
  return ref.watch(tourRepositoryProvider).findById(id);
});

class TourDetailScreen extends ConsumerWidget {
  final int tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(_tourByIdProvider(tourId));

    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(
          title: Text(async.value == null
              ? '...'
              : DateFormat('EEE d MMM yyyy', 'fr')
                  .format(async.value!.tour.plannedDate)),
          suffixes: [
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
                s.plannedSmall * s.minutesPerSmallSnapshot +
                s.plannedLarge * s.minutesPerLargeSnapshot);
  }
}

class _ScheduleRow extends StatelessWidget {
  final TourStop stop;
  final int index;
  const _ScheduleRow({required this.stop, required this.index});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final plannedTotal = stop.plannedSmall + stop.plannedLarge;
    final actualSmall = stop.actualSmall;
    final actualLarge = stop.actualLarge;
    final hasActuals = actualSmall != null && actualLarge != null;
    final actualTotal = hasActuals ? actualSmall + actualLarge : null;
    final note = stop.interventionNote;

    return Container(
      padding: AppSizes.listTilePadding,
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: theme.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stop.clientId == null
                      ? '${stop.clientNameSnapshot} ${l.tourDetailDeleted}'
                      : stop.clientNameSnapshot,
                  style: theme.typography.md.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.hairline),
                Text(
                  '${formatHm(stop.estimatedArrivalMinutes)} → '
                  '${formatHm(stop.estimatedDepartureMinutes)} · '
                  'Planifié : $plannedTotal moutons '
                  '(${stop.plannedSmall}/${stop.plannedLarge})',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                if (hasActuals) ...[
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    'Effectif : $actualTotal moutons '
                    '($actualSmall/$actualLarge)',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatEuros(stop.feeShareCents),
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
