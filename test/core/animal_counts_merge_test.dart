import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/animal_counts_merge.dart';
import 'package:coup_laine/domain/models/animal_count.dart';

void main() {
  group('mergeAnimalCountsByCategory', () {
    test('empty existing + non-empty incoming → returns incoming normalized', () {
      final incoming = [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 3),
      ];

      final result = mergeAnimalCountsByCategory([], incoming);

      expect(result, [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 3),
      ]);
    });

    test('non-empty existing + empty incoming → returns existing', () {
      final existing = [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 3),
      ];

      final result = mergeAnimalCountsByCategory(existing, []);

      expect(result, [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 3),
      ]);
    });

    test('overlapping categoryId → incoming wins for that key, others kept', () {
      final existing = [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 3),
        AnimalCount(categoryId: 3, count: 7),
      ];
      final incoming = [
        AnimalCount(categoryId: 2, count: 10),
      ];

      final result = mergeAnimalCountsByCategory(existing, incoming);

      expect(result, [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 10),
        AnimalCount(categoryId: 3, count: 7),
      ]);
    });

    test('normalizes (zeros dropped via normalizeAnimalCounts)', () {
      final existing = [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 3),
      ];
      final incoming = [
        AnimalCount(categoryId: 1, count: 0),
        AnimalCount(categoryId: 3, count: 8),
      ];

      final result = mergeAnimalCountsByCategory(existing, incoming);

      expect(result, [
        AnimalCount(categoryId: 2, count: 3),
        AnimalCount(categoryId: 3, count: 8),
      ]);
    });

    test('result is sorted by categoryId', () {
      final existing = [
        AnimalCount(categoryId: 3, count: 2),
      ];
      final incoming = [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 3),
      ];

      final result = mergeAnimalCountsByCategory(existing, incoming);

      expect(result, [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 3),
        AnimalCount(categoryId: 3, count: 2),
      ]);
    });
  });
}
