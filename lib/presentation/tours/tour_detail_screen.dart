// lib/presentation/tours/tour_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format_minutes.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/models/tour.dart';
import '../../state/providers.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(async.value == null
            ? '...'
            : DateFormat('EEE dd/MM/yyyy', 'fr')
                .format(async.value!.tour.plannedDate)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: async.value == null
                ? null
                : () => _share(async.value!, context),
            tooltip: l.tourDetailShare,
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (bundle) {
          if (bundle == null) return const SizedBox.shrink();
          return _Body(bundle: bundle, tourId: tourId);
        },
      ),
    );
  }

  Future<void> _share(TourWithStops bundle, BuildContext context) async {
    final dateLine =
        DateFormat('dd/MM/yyyy').format(bundle.tour.plannedDate);
    final lines = <String>[
      'Tournée du $dateLine',
      ...bundle.stops.map(
        (s) =>
            '- ${s.clientNameSnapshot} : ${formatEuros(s.feeShareCents)}',
      ),
      'Total : ${formatEuros(bundle.tour.totalTravelFeeCents)}',
    ];
    // share_plus 13.x requires SharePlus.instance.share(ShareParams(...))
    await SharePlus.instance.share(ShareParams(
      text: lines.join('\n'),
      subject: 'Tournée du $dateLine',
    ));
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              completed ? Icons.check_circle : Icons.alt_route,
              color: completed ? Colors.green : null,
            ),
            title: Text(completed
                ? l.toursStatusCompleted
                : l.toursStatusPlanned),
            subtitle: Text(
              '${(bundle.tour.totalDistanceMeters / 1000).toStringAsFixed(1)} km · '
              '${formatDuration(bundle.tour.totalDriveSeconds ~/ 60)} de trajet · '
              'Départ ${formatHm(bundle.tour.startTimeMinutes)}',
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_estimatedTourEnd(bundle) > 20 * 60)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Chip(
              label: Text('Journée longue'),
              backgroundColor: Color(0xFFFFE0B2),
            ),
          ),
        Text(l.tourDetailScheduleTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < bundle.stops.length; i++)
          ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(bundle.stops[i].clientId == null
                ? '${bundle.stops[i].clientNameSnapshot} ${l.tourDetailDeleted}'
                : bundle.stops[i].clientNameSnapshot),
            subtitle: Text(
              '${formatHm(bundle.stops[i].estimatedArrivalMinutes)} → '
              '${formatHm(bundle.stops[i].estimatedDepartureMinutes)} · '
              '${bundle.stops[i].sheepCountSnapshot} moutons',
            ),
            trailing: Text(formatEuros(bundle.stops[i].feeShareCents)),
          ),
        const SizedBox(height: 16),
        Text(l.tourDetailFeeTitle,
            style: Theme.of(context).textTheme.titleMedium),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Total : ${formatEuros(bundle.tour.totalTravelFeeCents)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!completed)
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text(l.tourDetailComplete),
            onPressed: () => _confirmComplete(context, ref),
          ),
      ],
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.tourDetailCompleteConfirmTitle),
        content: Text(l.tourDetailCompleteConfirmBody(bundle.stops.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.tourDetailComplete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(tourRepositoryProvider).markCompleted(tourId);
      ref.invalidate(_tourByIdProvider(tourId));
    }
  }
}
