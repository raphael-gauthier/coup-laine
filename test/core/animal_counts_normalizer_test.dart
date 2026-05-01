import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/animal_counts_normalizer.dart';
import 'package:coup_laine/domain/models/animal_count.dart';

void main() {
  group('normalizeAnimalCounts', () {
    test('drops entries with count <= 0', () {
      final out = normalizeAnimalCounts(const [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 0),
        AnimalCount(categoryId: 3, count: -2),
      ]);
      expect(out, const [AnimalCount(categoryId: 1, count: 5)]);
    });

    test('dedups by categoryId (sums counts) and sorts by categoryId', () {
      final out = normalizeAnimalCounts(const [
        AnimalCount(categoryId: 3, count: 1),
        AnimalCount(categoryId: 1, count: 4),
        AnimalCount(categoryId: 3, count: 2),
      ]);
      expect(out, const [
        AnimalCount(categoryId: 1, count: 4),
        AnimalCount(categoryId: 3, count: 3),
      ]);
    });

    test('returns empty list when input is empty', () {
      expect(normalizeAnimalCounts(const []), isEmpty);
    });
  });
}
