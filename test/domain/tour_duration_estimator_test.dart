import 'package:coupe_laine/domain/use_cases/tour_duration_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TourDurationEstimator', () {
    final estimator = const TourDurationEstimator();

    test('one stop, 10 sheep, 20 min/sheep, 30 min drive each way', () {
      final result = estimator.estimate(
        startTimeMinutes: 8 * 60, // 08:00
        driveSecondsToStops: const [1800], // 30 min to stop
        driveSecondsBackToBase: 1800,
        sheepCountPerStop: const [10],
        minutesPerSheepPerStop: const [20],
      );
      expect(result.stopArrivalMinutes, [8 * 60 + 30]); // 08:30
      expect(result.stopDepartureMinutes, [8 * 60 + 30 + 200]); // +200 min
      expect(result.endTimeMinutes, 8 * 60 + 30 + 200 + 30); // back home
      expect(result.totalDriveSeconds, 3600);
      expect(result.totalShearingMinutes, 200);
    });

    test('three stops accumulate drive + shearing', () {
      final result = estimator.estimate(
        startTimeMinutes: 8 * 60,
        driveSecondsToStops: const [600, 900, 1200], // 10, 15, 20 min
        driveSecondsBackToBase: 1500, // 25 min
        sheepCountPerStop: const [5, 3, 8],
        minutesPerSheepPerStop: const [20, 25, 18],
      );
      // arrivals: 8:10, then 10 + 100 (shear5*20) + 15 = 8:10+115=10:05
      expect(result.stopArrivalMinutes[0], 8 * 60 + 10);
      expect(result.stopArrivalMinutes[1],
          8 * 60 + 10 + 100 + 15);
      expect(result.stopArrivalMinutes[2],
          8 * 60 + 10 + 100 + 15 + 75 + 20);
      expect(result.totalShearingMinutes, 100 + 75 + 144);
    });

    test('rejects mismatched list lengths', () {
      expect(
        () => estimator.estimate(
          startTimeMinutes: 0,
          driveSecondsToStops: const [60, 60],
          driveSecondsBackToBase: 60,
          sheepCountPerStop: const [1],
          minutesPerSheepPerStop: const [20],
        ),
        throwsArgumentError,
      );
    });
  });
}
