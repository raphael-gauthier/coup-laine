import '../domain/models/animal_count.dart';

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
