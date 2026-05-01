import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';

void main() {
  const a = TourStopPrestation(
    prestationId: 1,
    qty: 12,
    nameSnapshot: 'Tonte',
    priceCentsSnapshot: 800,
    minutesSnapshot: 8,
    categoryIdSnapshot: 3,
    categoryNameSnapshot: 'Petit',
    speciesNameSnapshot: 'Mouton',
  );

  test('equality on identical fields', () {
    const b = TourStopPrestation(
      prestationId: 1,
      qty: 12,
      nameSnapshot: 'Tonte',
      priceCentsSnapshot: 800,
      minutesSnapshot: 8,
      categoryIdSnapshot: 3,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
    );
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });

  test('inequality when qty differs', () {
    const b = TourStopPrestation(
      prestationId: 1,
      qty: 11,
      nameSnapshot: 'Tonte',
      priceCentsSnapshot: 800,
      minutesSnapshot: 8,
      categoryIdSnapshot: 3,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
    );
    expect(a, isNot(equals(b)));
  });

  test('libre prestation: category snapshots are null', () {
    const free = TourStopPrestation(
      prestationId: 9,
      qty: 1,
      nameSnapshot: 'Visite',
      priceCentsSnapshot: 2000,
      minutesSnapshot: 0,
    );
    expect(free.categoryIdSnapshot, isNull);
    expect(free.categoryNameSnapshot, isNull);
    expect(free.speciesNameSnapshot, isNull);
  });
}
