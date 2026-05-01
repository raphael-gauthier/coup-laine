import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/animal_counts_from_prestations.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';

TourStopPrestation _bound(int prestId, int qty, int catId) =>
    TourStopPrestation(
      prestationId: prestId,
      qty: qty,
      nameSnapshot: 'P$prestId',
      priceCentsSnapshot: 0,
      minutesSnapshot: 0,
      categoryIdSnapshot: catId,
      categoryNameSnapshot: 'Cat$catId',
      speciesNameSnapshot: 'S',
    );

TourStopPrestation _free(int prestId, int qty) => TourStopPrestation(
      prestationId: prestId,
      qty: qty,
      nameSnapshot: 'Free',
      priceCentsSnapshot: 0,
      minutesSnapshot: 0,
    );

void main() {
  test('empty input → empty output', () {
    expect(animalCountsFromPrestations(const []), isEmpty);
  });

  test('libre prestation → ignored', () {
    final out = animalCountsFromPrestations([_free(1, 5)]);
    expect(out, isEmpty);
  });

  test('one bound prestation → one count', () {
    final out = animalCountsFromPrestations([_bound(1, 12, 3)]);
    expect(out, hasLength(1));
    expect(out.first.categoryId, 3);
    expect(out.first.count, 12);
  });

  test('two bound on same category → MAX rule (not sum)', () {
    final out = animalCountsFromPrestations([
      _bound(1, 12, 3), // Tonte × 12 sur Petit
      _bound(2, 12, 3), // Vermifuge × 12 sur Petit
    ]);
    expect(out, hasLength(1));
    expect(out.first.categoryId, 3);
    expect(out.first.count, 12, reason: 'MAX, not 24');
  });

  test('two bound on same category, different qty → MAX', () {
    final out = animalCountsFromPrestations([
      _bound(1, 5, 3),
      _bound(2, 12, 3),
    ]);
    expect(out.first.count, 12);
  });

  test('mixed bound + libre → libre ignored, bound aggregated', () {
    final out = animalCountsFromPrestations([
      _bound(1, 12, 3),
      _free(9, 100),
      _bound(2, 4, 5),
    ]);
    expect(out, hasLength(2));
    expect(out.firstWhere((e) => e.categoryId == 3).count, 12);
    expect(out.firstWhere((e) => e.categoryId == 5).count, 4);
  });

  test('result is sorted by categoryId ascending', () {
    final out = animalCountsFromPrestations([
      _bound(1, 1, 5),
      _bound(2, 2, 1),
      _bound(3, 3, 3),
    ]);
    expect(out.map((e) => e.categoryId).toList(), [1, 3, 5]);
  });
}
