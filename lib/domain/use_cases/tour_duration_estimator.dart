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

class TourDurationEstimator {
  const TourDurationEstimator();

  TourDurationResult estimate({
    required int startTimeMinutes,
    required List<int> driveSecondsToStops,
    required int driveSecondsBackToBase,
    required List<int> sheepCountPerStop,
    required List<int> minutesPerSheepPerStop,
  }) {
    final n = driveSecondsToStops.length;
    if (sheepCountPerStop.length != n ||
        minutesPerSheepPerStop.length != n) {
      throw ArgumentError(
        'sheepCountPerStop and minutesPerSheepPerStop must have length n '
        '(got ${sheepCountPerStop.length} and '
        '${minutesPerSheepPerStop.length}, expected $n)',
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

      final shearMin = sheepCountPerStop[i] * minutesPerSheepPerStop[i];
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
