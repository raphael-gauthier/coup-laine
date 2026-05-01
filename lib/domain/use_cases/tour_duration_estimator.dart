import '../models/tour_stop_prestation.dart';

class TourDurationResult {
  final List<int> stopArrivalMinutes;
  final List<int> stopDepartureMinutes;
  final int endTimeMinutes;
  final int totalDriveSeconds;
  final int totalInterventionMinutes;

  const TourDurationResult({
    required this.stopArrivalMinutes,
    required this.stopDepartureMinutes,
    required this.endTimeMinutes,
    required this.totalDriveSeconds,
    required this.totalInterventionMinutes,
  });
}

class TourDurationEstimator {
  const TourDurationEstimator();

  /// Estimates per-stop arrival/departure clock minutes plus totals.
  /// Per-stop time = `Σ prestation.qty × prestation.minutesSnapshot`.
  /// `minutesSnapshot == 0` (prestation without a duration set) contributes 0.
  TourDurationResult estimate({
    required int startTimeMinutes,
    required List<int> driveSecondsToStops,
    required int driveSecondsBackToBase,
    required List<List<TourStopPrestation>> stops,
  }) {
    final n = driveSecondsToStops.length;
    if (stops.length != n) {
      throw ArgumentError(
        'stops and driveSecondsToStops must have length n '
        '(got ${stops.length} and $n)',
      );
    }

    final arrivals = <int>[];
    final departures = <int>[];
    var clock = startTimeMinutes;
    var totalDrive = 0;
    var totalIntervention = 0;

    for (var i = 0; i < n; i++) {
      final driveMin = (driveSecondsToStops[i] / 60).round();
      clock += driveMin;
      totalDrive += driveSecondsToStops[i];
      arrivals.add(clock);

      var stopMin = 0;
      for (final p in stops[i]) {
        stopMin += p.qty * p.minutesSnapshot;
      }
      clock += stopMin;
      totalIntervention += stopMin;
      departures.add(clock);
    }

    final returnDriveMin = (driveSecondsBackToBase / 60).round();
    clock += returnDriveMin;
    totalDrive += driveSecondsBackToBase;

    return TourDurationResult(
      stopArrivalMinutes: arrivals,
      stopDepartureMinutes: departures,
      endTimeMinutes: clock,
      totalDriveSeconds: totalDrive,
      totalInterventionMinutes: totalIntervention,
    );
  }
}
