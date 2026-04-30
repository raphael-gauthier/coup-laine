import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/tour_stop_animal.dart';
import 'package:coup_laine/infra/db/tour_stop_animal_list_converter.dart';

void main() {
  const c = TourStopAnimalListConverter();

  test('empty list round-trips', () {
    expect(c.toSql(const []), '[]');
    expect(c.fromSql('[]'), const <TourStopAnimal>[]);
  });

  test('round-trips with snapshots', () {
    final list = const [
      TourStopAnimal(
        categoryId: 1,
        count: 5,
        categoryNameSnapshot: 'Petit',
        speciesNameSnapshot: 'Mouton',
        minutesSnapshot: 8,
      ),
    ];
    expect(c.fromSql(c.toSql(list)), list);
  });
}
