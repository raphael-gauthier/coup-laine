import 'package:coup_laine/domain/use_cases/tour_duration_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TourDurationEstimator', () {
    final estimator = const TourDurationEstimator();

    test('one stop, mixed breeds, drives 30 min each way', () {
      final result = estimator.estimate(
        startTimeMinutes: 8 * 60,
        driveSecondsToStops: const [1800],
        driveSecondsBackToBase: 1800,
        stops: const [
          (small: 10, large: 0, minutesSmall: 8, minutesLarge: 25),
        ],
      );
      // shearMin = 10*8 + 0*25 = 80
      expect(result.stopArrivalMinutes, [8 * 60 + 30]);
      expect(result.stopDepartureMinutes, [8 * 60 + 30 + 80]);
      expect(result.endTimeMinutes, 8 * 60 + 30 + 80 + 30);
      expect(result.totalShearingMinutes, 80);
    });

    test('three stops accumulate breed-weighted shearing + drive', () {
      final result = estimator.estimate(
        startTimeMinutes: 8 * 60,
        driveSecondsToStops: const [600, 900, 1200],
        driveSecondsBackToBase: 1500,
        stops: const [
          (small: 5, large: 0, minutesSmall: 8, minutesLarge: 25),
          (small: 0, large: 3, minutesSmall: 8, minutesLarge: 25),
          (small: 4, large: 4, minutesSmall: 8, minutesLarge: 25),
        ],
      );
      // shear: 5*8=40, 3*25=75, 4*8+4*25=132 → total 247
      expect(result.totalShearingMinutes, 40 + 75 + 132);
      // arrivals chain: 8:00 + 10 = 8:10, then 8:10 + 40 + 15 = 9:05, then +75 + 20 = 10:40
      expect(result.stopArrivalMinutes[0], 8 * 60 + 10);
      expect(result.stopArrivalMinutes[1], 8 * 60 + 10 + 40 + 15);
      expect(result.stopArrivalMinutes[2],
          8 * 60 + 10 + 40 + 15 + 75 + 20);
    });

    test('rejects mismatched stops vs driveSecondsToStops length', () {
      expect(
        () => estimator.estimate(
          startTimeMinutes: 0,
          driveSecondsToStops: const [60, 60],
          driveSecondsBackToBase: 60,
          stops: const [
            (small: 1, large: 0, minutesSmall: 8, minutesLarge: 25),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
