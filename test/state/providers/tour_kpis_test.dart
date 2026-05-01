import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';
import 'package:coup_laine/state/providers/tour_kpis.dart';

TourStopPrestation _row({
  required String name,
  required int qty,
  required int price,
}) =>
    TourStopPrestation(
      prestationId: name.hashCode,
      qty: qty,
      nameSnapshot: name,
      priceCentsSnapshot: price,
      minutesSnapshot: 0,
      categoryIdSnapshot: null,
      categoryNameSnapshot: null,
      speciesNameSnapshot: null,
    );

void main() {
  group('aggregatePrestations', () {
    test('regroupe par nameSnapshot, somme qty, multiplie prix × qty', () {
      final result = aggregatePrestations([
        [_row(name: 'Tonte Petit', qty: 3, price: 6000)],
        [_row(name: 'Tonte Petit', qty: 5, price: 6000)],
        [_row(name: 'Parage', qty: 1, price: 4000)],
      ]);

      expect(result.length, 2);
      final tonte = result.firstWhere((r) => r.name == 'Tonte Petit');
      expect(tonte.qty, 8);
      expect(tonte.totalCents, 8 * 6000);
      final parage = result.firstWhere((r) => r.name == 'Parage');
      expect(parage.qty, 1);
      expect(parage.totalCents, 4000);
    });

    test('liste vide → résultat vide', () {
      expect(aggregatePrestations(const []), isEmpty);
    });

    test('total global = somme des qty × priceCentsSnapshot', () {
      final result = aggregatePrestations([
        [_row(name: 'A', qty: 2, price: 1000)],
        [_row(name: 'B', qty: 3, price: 500)],
      ]);
      final total = result.fold<int>(0, (s, r) => s + r.totalCents);
      expect(total, 2 * 1000 + 3 * 500);
    });
  });
}
