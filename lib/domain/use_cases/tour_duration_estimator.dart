class TourDurationResult {
  final List<int> stopArrivalMinutes;
  final List<int> stopDepartureMinutes;
  final int endTimeMinutes;
  final int totalDriveSeconds;
  final int totalShearingMinutes;

  const TourDurationResult({
    required this.stopArrivalMinutes,
    required this.stopDepartureMinutes,
    required this.endTimeMinutes,
    required this.totalDriveSeconds,
    required this.totalShearingMinutes,
  });
}

/// Per-stop input for the estimator. Time spent shearing at the stop is
/// `small * minutesSmall + large * minutesLarge`.
typedef TourStopEstimateInput = ({
  int small,
  int large,
  int minutesSmall,
  int minutesLarge,
});

class TourDurationEstimator {
  const TourDurationEstimator();

  TourDurationResult estimate({
    required int startTimeMinutes,
    required List<int> driveSecondsToStops,
    required int driveSecondsBackToBase,
    required List<TourStopEstimateInput> stops,
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
    var totalShear = 0;

    for (var i = 0; i < n; i++) {
      final driveMin = (driveSecondsToStops[i] / 60).round();
      clock += driveMin;
      totalDrive += driveSecondsToStops[i];
      arrivals.add(clock);

      final stop = stops[i];
      final shearMin = stop.small * stop.minutesSmall +
          stop.large * stop.minutesLarge;
      clock += shearMin;
      totalShear += shearMin;
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
      totalShearingMinutes: totalShear,
    );
  }
}
