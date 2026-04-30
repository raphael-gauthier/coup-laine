import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/animal_count.dart';

void main() {
  test('AnimalCount stores categoryId and count', () {
    const a = AnimalCount(categoryId: 7, count: 12);
    expect(a.categoryId, 7);
    expect(a.count, 12);
  });

  test('two AnimalCount with the same fields are equal', () {
    expect(
      const AnimalCount(categoryId: 1, count: 5),
      const AnimalCount(categoryId: 1, count: 5),
    );
  });
}
