import '../domain/models/animal_count.dart';
import '../domain/models/tour_stop_animal.dart';

/// Canonicalizes a list of [AnimalCount] before persistence:
///   - drops entries with `count <= 0`,
///   - dedups by `categoryId` (sums counts of duplicates),
///   - sorts by `categoryId` ascending (stable for equal keys).
List<AnimalCount> normalizeAnimalCounts(List<AnimalCount> input) {
  final byCategory = <int, int>{};
  for (final a in input) {
    if (a.count <= 0) continue;
    byCategory[a.categoryId] = (byCategory[a.categoryId] ?? 0) + a.count;
  }
  final ids = byCategory.keys.toList()..sort();
  return [
    for (final id in ids) AnimalCount(categoryId: id, count: byCategory[id]!),
  ];
}

/// Canonicalizes a list of [TourStopAnimal]:
///   - drops `count <= 0`,
///   - dedups by `categoryId` keeping the **first** snapshot encountered,
///   - sums counts of duplicates,
///   - sorts by `categoryId` ascending.
List<TourStopAnimal> normalizeTourStopAnimals(List<TourStopAnimal> input) {
  final firstSnapshot = <int, TourStopAnimal>{};
  final summedCount = <int, int>{};
  for (final a in input) {
    if (a.count <= 0) continue;
    firstSnapshot.putIfAbsent(a.categoryId, () => a);
    summedCount[a.categoryId] = (summedCount[a.categoryId] ?? 0) + a.count;
  }
  final ids = summedCount.keys.toList()..sort();
  return [
    for (final id in ids)
      TourStopAnimal(
        categoryId: id,
        count: summedCount[id]!,
        categoryNameSnapshot: firstSnapshot[id]!.categoryNameSnapshot,
        speciesNameSnapshot: firstSnapshot[id]!.speciesNameSnapshot,
        minutesSnapshot: firstSnapshot[id]!.minutesSnapshot,
      ),
  ];
}
