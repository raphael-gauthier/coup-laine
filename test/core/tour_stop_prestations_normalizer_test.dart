import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/tour_stop_prestations_normalizer.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';

TourStopPrestation _p(int id, int qty) => TourStopPrestation(
      prestationId: id,
      qty: qty,
      nameSnapshot: 'P$id',
      priceCentsSnapshot: 0,
      minutesSnapshot: 0,
    );

void main() {
  test('drops qty <= 0', () {
    final out = normalizeTourStopPrestations([_p(1, 5), _p(2, 0), _p(3, -1)]);
    expect(out.map((e) => e.prestationId), [1]);
  });

  test('does not dedup same prestationId', () {
    final out = normalizeTourStopPrestations([_p(1, 5), _p(1, 3)]);
    expect(out, hasLength(2));
    expect(out.every((e) => e.prestationId == 1), isTrue);
  });

  test('sorts by prestationId ascending then preserves insertion order', () {
    final out = normalizeTourStopPrestations(
        [_p(3, 1), _p(1, 5), _p(1, 3), _p(2, 2)]);
    expect(out.map((e) => (e.prestationId, e.qty)).toList(),
        [(1, 5), (1, 3), (2, 2), (3, 1)]);
  });

  test('empty input', () {
    expect(normalizeTourStopPrestations(const []), isEmpty);
  });
}
