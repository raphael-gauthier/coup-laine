import 'package:coup_laine/domain/models/tour_stop_prestation.dart';
import 'package:coup_laine/domain/use_cases/tour_duration_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

TourStopPrestation _p({
  int prestationId = 1,
  required int qty,
  required int minutes,
  String name = 'Tonte',
  int priceCents = 1000,
  int? categoryId = 1,
  String? category = 'Adulte',
  String? species = 'Mouton',
}) =>
    TourStopPrestation(
      prestationId: prestationId,
      qty: qty,
      nameSnapshot: name,
      priceCentsSnapshot: priceCents,
      minutesSnapshot: minutes,
      categoryIdSnapshot: categoryId,
      categoryNameSnapshot: category,
      speciesNameSnapshot: species,
    );

void main() {
  group('TourDurationEstimator', () {
    final estimator = const TourDurationEstimator();

    test('one stop, mixed prestations, drives 30 min each way', () {
      final result = estimator.estimate(
        startTimeMinutes: 8 * 60,
        driveSecondsToStops: const [1800],
        driveSecondsBackToBase: 1800,
        stops: [
          [
            _p(prestationId: 1, qty: 10, minutes: 8),
            _p(prestationId: 2, qty: 0, minutes: 25),
          ],
        ],
      );
      // stopMin = 10*8 + 0*25 = 80
      expect(result.stopArrivalMinutes, [8 * 60 + 30]);
      expect(result.stopDepartureMinutes, [8 * 60 + 30 + 80]);
      expect(result.endTimeMinutes, 8 * 60 + 30 + 80 + 30);
      expect(result.totalInterventionMinutes, 80);
    });

    test('three stops accumulate per-prestation intervention + drive', () {
      final result = estimator.estimate(
        startTimeMinutes: 8 * 60,
        driveSecondsToStops: const [600, 900, 1200],
        driveSecondsBackToBase: 1500,
        stops: [
          [_p(prestationId: 1, qty: 5, minutes: 8)],
          [_p(prestationId: 2, qty: 3, minutes: 25)],
          [
            _p(prestationId: 1, qty: 4, minutes: 8),
            _p(prestationId: 2, qty: 4, minutes: 25),
          ],
        ],
      );
      // intervention: 5*8=40, 3*25=75, 4*8+4*25=132 → total 247
      expect(result.totalInterventionMinutes, 40 + 75 + 132);
      // arrivals chain: 8:00 + 10 = 8:10, then 8:10 + 40 + 15 = 9:05, then +75 + 20 = 10:40
      expect(result.stopArrivalMinutes[0], 8 * 60 + 10);
      expect(result.stopArrivalMinutes[1], 8 * 60 + 10 + 40 + 15);
      expect(result.stopArrivalMinutes[2],
          8 * 60 + 10 + 40 + 15 + 75 + 20);
    });

    test('minutesSnapshot=0 contributes only drive time', () {
      final result = estimator.estimate(
        startTimeMinutes: 8 * 60,
        driveSecondsToStops: const [600],
        driveSecondsBackToBase: 600,
        stops: [
          [_p(prestationId: 1, qty: 5, minutes: 0)],
        ],
      );
      expect(result.totalInterventionMinutes, 0);
      expect(result.stopArrivalMinutes, [8 * 60 + 10]);
      expect(result.stopDepartureMinutes, [8 * 60 + 10]);
      expect(result.endTimeMinutes, 8 * 60 + 20);
    });

    test('libre prestation (categoryIdSnapshot null) still contributes its '
        'qty × minutesSnapshot', () {
      final result = estimator.estimate(
        startTimeMinutes: 8 * 60,
        driveSecondsToStops: const [600],
        driveSecondsBackToBase: 600,
        stops: [
          [
            _p(
              prestationId: 99,
              qty: 3,
              minutes: 12,
              categoryId: null,
              category: null,
              species: null,
            ),
          ],
        ],
      );
      // 3 × 12 = 36 contributed even though libre (no category binding).
      expect(result.totalInterventionMinutes, 36);
      expect(result.stopDepartureMinutes, [8 * 60 + 10 + 36]);
    });

    test('rejects mismatched stops vs driveSecondsToStops length', () {
      expect(
        () => estimator.estimate(
          startTimeMinutes: 0,
          driveSecondsToStops: const [60, 60],
          driveSecondsBackToBase: 60,
          stops: [
            [_p(prestationId: 1, qty: 1, minutes: 8)],
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
