import '../models/client.dart';
import '../models/distance_matrix_entry.dart';
import '../models/settings.dart';
import '../models/tour_stop_animal.dart';
import 'bracket_counter.dart';
import 'cost_split_calculator.dart';
import 'tour_duration_estimator.dart';
import 'tour_order_optimizer.dart';

class TourDraftResult {
  final List<int> orderedClientIds;
  final List<int> arrivalMinutes;
  final List<int> departureMinutes;
  final int endTimeMinutes;
  final int totalDistanceMeters;
  final int totalDriveSeconds;
  final int totalInterventionMinutes;
  final int totalFeeCents;
  final List<int> feeShareCents;
  final List<List<TourStopAnimal>> plannedAnimalsPerStop;
  final int feeFarthestCents;
  final int feeInterCents;

  const TourDraftResult({
    required this.orderedClientIds,
    required this.arrivalMinutes,
    required this.departureMinutes,
    required this.endTimeMinutes,
    required this.totalDistanceMeters,
    required this.totalDriveSeconds,
    required this.totalInterventionMinutes,
    required this.totalFeeCents,
    required this.feeShareCents,
    required this.plannedAnimalsPerStop,
    required this.feeFarthestCents,
    required this.feeInterCents,
  });
}

class BuildTourDraft {
  const BuildTourDraft();

  TourDraftResult build({
    required List<int> candidateIds,
    required List<Client> candidates,
    required List<DistanceMatrixEntry> matrix,
    required Settings settings,
    required Map<int, ({String speciesName, String categoryName, int minutes})>
        categoryLookup,
    required int startTimeMinutes,
    List<int>? presetOrder, // skip optimiser if provided
  }) {
    if (candidateIds.isEmpty) {
      throw ArgumentError('Cannot build a draft with zero candidates');
    }
    final byId = {for (final c in candidates) c.id: c};
    for (final id in candidateIds) {
      if (!byId.containsKey(id)) {
        throw ArgumentError('Missing client id=$id');
      }
    }

    final nodeIds = <int>[0, ...candidateIds];
    final n = nodeIds.length;
    final dm = List.generate(n, (_) => List<int>.filled(n, 0));
    final tm = List.generate(n, (_) => List<int>.filled(n, 0));
    final lookup = <int, int>{};
    for (final e in matrix) {
      lookup[e.fromId * 1000000 + e.toId] = e.distanceMeters;
    }
    final lookupT = <int, int>{};
    for (final e in matrix) {
      lookupT[e.fromId * 1000000 + e.toId] = e.durationSeconds;
    }
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        final key = nodeIds[i] * 1000000 + nodeIds[j];
        dm[i][j] = lookup[key] ??
            (throw StateError(
                'Missing matrix entry ${nodeIds[i]} -> ${nodeIds[j]}'));
        tm[i][j] = lookupT[key] ?? 0;
      }
    }

    final visitIndices = presetOrder != null
        ? presetOrder.map((id) => nodeIds.indexOf(id)).toList()
        : const TourOrderOptimizer().optimise(distanceMatrix: dm);
    final orderedIds = visitIndices.map((i) => nodeIds[i]).toList();

    final driveToStops = <int>[
      for (var k = 0; k < visitIndices.length; k++)
        tm[k == 0 ? 0 : visitIndices[k - 1]][visitIndices[k]]
    ];
    final driveBack = tm[visitIndices.last][0];

    // Build per-stop planned animals from each client's animals + the
    // category lookup. Categories no longer in the lookup (deleted) are
    // skipped silently.
    final plannedAnimalsPerStop = <List<TourStopAnimal>>[
      for (final id in orderedIds)
        [
          for (final ac in byId[id]!.animals)
            if (categoryLookup[ac.categoryId] != null)
              TourStopAnimal(
                categoryId: ac.categoryId,
                count: ac.count,
                categoryNameSnapshot:
                    categoryLookup[ac.categoryId]!.categoryName,
                speciesNameSnapshot:
                    categoryLookup[ac.categoryId]!.speciesName,
                minutesSnapshot: categoryLookup[ac.categoryId]!.minutes,
              ),
        ],
    ];

    final duration = const TourDurationEstimator().estimate(
      startTimeMinutes: startTimeMinutes,
      driveSecondsToStops: driveToStops,
      driveSecondsBackToBase: driveBack,
      stops: plannedAnimalsPerStop,
    );

    final baseToStopMeters = <int>[
      for (final id in orderedIds) dm[0][nodeIds.indexOf(id)]
    ];
    final interStopMeters = <int>[
      for (var k = 0; k < orderedIds.length - 1; k++)
        dm[nodeIds.indexOf(orderedIds[k])]
            [nodeIds.indexOf(orderedIds[k + 1])]
    ];
    final returnMeters = dm[nodeIds.indexOf(orderedIds.last)][0];

    final brackets = BracketCounter(
      bracketKm: settings.bracketKm,
      feeEurosPerBracket: settings.travelFeeEurosPerBracket,
    );
    final split = CostSplitCalculator(brackets: brackets).split(
      baseToStopMeters: baseToStopMeters,
      interStopMeters: interStopMeters,
    );

    final totalDistance =
        baseToStopMeters.first + interStopMeters.fold<int>(0, (a, b) => a + b) + returnMeters;

    return TourDraftResult(
      orderedClientIds: orderedIds,
      arrivalMinutes: duration.stopArrivalMinutes,
      departureMinutes: duration.stopDepartureMinutes,
      endTimeMinutes: duration.endTimeMinutes,
      totalDistanceMeters: totalDistance,
      totalDriveSeconds: duration.totalDriveSeconds,
      totalInterventionMinutes: duration.totalInterventionMinutes,
      totalFeeCents: split.totalFeeCents,
      feeShareCents: split.shareCents,
      plannedAnimalsPerStop: plannedAnimalsPerStop,
      feeFarthestCents: split.feeFarthestCents,
      feeInterCents: split.feeInterCents,
    );
  }
}
