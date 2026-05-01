import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';
import 'package:coup_laine/infra/db/tour_stop_prestation_list_converter.dart';

void main() {
  const c = TourStopPrestationListConverter();

  test('empty list round-trips', () {
    expect(c.toSql(const []), '[]');
    expect(c.fromSql('[]'), const <TourStopPrestation>[]);
  });

  test('round-trips bound prestation', () {
    const list = [
      TourStopPrestation(
        prestationId: 1,
        qty: 12,
        nameSnapshot: 'Tonte',
        priceCentsSnapshot: 800,
        minutesSnapshot: 8,
        categoryIdSnapshot: 3,
        categoryNameSnapshot: 'Petit',
        speciesNameSnapshot: 'Mouton',
      ),
    ];
    expect(c.fromSql(c.toSql(list)), list);
  });

  test('round-trips libre prestation (null category fields)', () {
    const list = [
      TourStopPrestation(
        prestationId: 9,
        qty: 1,
        nameSnapshot: 'Visite',
        priceCentsSnapshot: 2000,
        minutesSnapshot: 0,
      ),
    ];
    expect(c.fromSql(c.toSql(list)), list);
  });

  test('round-trips mixed list', () {
    const list = [
      TourStopPrestation(
        prestationId: 1,
        qty: 12,
        nameSnapshot: 'Tonte',
        priceCentsSnapshot: 800,
        minutesSnapshot: 8,
        categoryIdSnapshot: 3,
        categoryNameSnapshot: 'Petit',
        speciesNameSnapshot: 'Mouton',
      ),
      TourStopPrestation(
        prestationId: 9,
        qty: 1,
        nameSnapshot: 'Visite',
        priceCentsSnapshot: 2000,
        minutesSnapshot: 0,
      ),
    ];
    expect(c.fromSql(c.toSql(list)), list);
  });
}
