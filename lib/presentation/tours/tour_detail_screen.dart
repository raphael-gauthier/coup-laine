// lib/presentation/tours/tour_detail_screen.dart
import 'package:flutter/widgets.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format_minutes.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/models/tour.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider;
import 'tours_list_screen.dart' show toursAsyncProvider;

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

    return FScaffold(
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
    await Share.share(lines.join('\n'), subject: 'Tournée du $dateLine');
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  FBadge(
                    variant: completed
                        ? FBadgeVariant.secondary
                        : FBadgeVariant.primary,
                    child: Text(completed
                        ? l.toursStatusCompleted
                        : l.toursStatusPlanned),
                  ),
                  const SizedBox(height: 12),
                  // Total fee
                  Text(
                    formatEuros(bundle.tour.totalTravelFeeCents),
                    style: theme.typography.xl4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colors.foreground,
                    ),
                  ),
                  Text(
                    l.tourDetailFeeTotalCaption,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sub-line
                  Text(
                    '$km km · ${formatDuration(driveMin)} de trajet · Départ ${formatHm(bundle.tour.startTimeMinutes)}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Long-day badge
          if (_estimatedTourEnd(bundle) > 20 * 60) ...[
            FBadge(
              variant: FBadgeVariant.secondary,
              child: Text(l.tourDetailLongDay),
            ),
            const SizedBox(height: 12),
          ],

          // Schedule card
          FCard(
            title: Text(l.tourDetailScheduleTitle),
            child: Column(
              children: [
                for (var i = 0; i < bundle.stops.length; i++)
                  FTile(
                    prefix: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primaryForeground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(bundle.stops[i].clientId == null
                        ? '${bundle.stops[i].clientNameSnapshot} ${l.tourDetailDeleted}'
                        : bundle.stops[i].clientNameSnapshot),
                    subtitle: Text(
                      '${formatHm(bundle.stops[i].estimatedArrivalMinutes)} → '
                      '${formatHm(bundle.stops[i].estimatedDepartureMinutes)} · '
                      '${bundle.stops[i].sheepCountSnapshot} moutons',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    suffix: Text(
                      formatEuros(bundle.stops[i].feeShareCents),
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mark-as-completed CTA
          if (!completed)
            FButton(
              prefix: const Icon(FIcons.check),
              onPress: () => _confirmComplete(context, ref),
              child: Text(l.tourDetailComplete),
            ),
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
                s.sheepCountSnapshot * s.minutesPerSheepSnapshot);
  }

  Future<void> _confirmComplete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l.tourDetailCompleteConfirmTitle),
        body: Text(l.tourDetailCompleteConfirmBody(bundle.stops.length)),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FButton(
            onPress: () => Navigator.of(context).pop(true),
            child: Text(l.tourDetailComplete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(tourRepositoryProvider).markCompleted(tourId);
      ref.invalidate(_tourByIdProvider(tourId));
      ref.invalidate(toursAsyncProvider);
      ref.invalidate(clientsAsyncProvider);
    }
  }
}
