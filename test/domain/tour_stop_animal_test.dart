import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/tour_stop_animal.dart';

void main() {
  test('TourStopAnimal carries snapshots', () {
    const a = TourStopAnimal(
      categoryId: 3,
      count: 5,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
      minutesSnapshot: 8,
    );
    expect(a.categoryId, 3);
    expect(a.count, 5);
    expect(a.categoryNameSnapshot, 'Petit');
    expect(a.speciesNameSnapshot, 'Mouton');
    expect(a.minutesSnapshot, 8);
  });

  test('TourStopAnimal equality compares all fields', () {
    const a = TourStopAnimal(
      categoryId: 3,
      count: 5,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
      minutesSnapshot: 8,
    );
    const b = TourStopAnimal(
      categoryId: 3,
      count: 5,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
      minutesSnapshot: 8,
    );
    expect(a, b);
  });
}
