import '../domain/models/animal_count.dart';
import 'animal_counts_normalizer.dart';

/// Merges [incoming] counts into [existing] per `categoryId`. Entries in
/// [incoming] overwrite the count for matching ids; other categories remain
/// untouched. Result is normalized (sorted, zeros dropped, dedup-summed).
List<AnimalCount> mergeAnimalCountsByCategory(
  List<AnimalCount> existing,
  List<AnimalCount> incoming,
) {
  final byId = <int, int>{
    for (final a in existing) a.categoryId: a.count,
  };
  for (final a in incoming) {
    byId[a.categoryId] = a.count;
  }
  return normalizeAnimalCounts([
    for (final entry in byId.entries)
      AnimalCount(categoryId: entry.key, count: entry.value),
  ]);
}
