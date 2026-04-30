import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/animal_counts_normalizer.dart';
import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/tour_stop_animal.dart';

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

  group('normalizeTourStopAnimals', () {
    test('keeps first occurrence snapshot when deduping; sums counts', () {
      final out = normalizeTourStopAnimals(const [
        TourStopAnimal(
          categoryId: 1,
          count: 2,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
        TourStopAnimal(
          categoryId: 1,
          count: 3,
          categoryNameSnapshot: 'Petit (renommé)',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 9,
        ),
      ]);
      expect(out, const [
        TourStopAnimal(
          categoryId: 1,
          count: 5,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
      ]);
    });

    test('drops zero / negative counts and sorts by categoryId', () {
      final out = normalizeTourStopAnimals(const [
        TourStopAnimal(
          categoryId: 5,
          count: 1,
          categoryNameSnapshot: 'Adulte',
          speciesNameSnapshot: 'Cheval',
          minutesSnapshot: 45,
        ),
        TourStopAnimal(
          categoryId: 2,
          count: 0,
          categoryNameSnapshot: 'Grand',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 25,
        ),
        TourStopAnimal(
          categoryId: 1,
          count: 3,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
      ]);
      expect(out.map((e) => e.categoryId), [1, 5]);
    });
  });
}
