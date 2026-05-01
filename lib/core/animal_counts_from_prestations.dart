import '../domain/models/animal_count.dart';
import '../domain/models/tour_stop_prestation.dart';

/// Derives `AnimalCount` per category from a list of completed prestations.
///
/// Rules :
/// - Prestations with `categoryIdSnapshot == null` (libres) are ignored.
/// - For multiple prestations bound to the same category, the **MAX qty**
///   wins (not the sum). Rationale (from spec): doing two prestations on the
///   same animal in one day shouldn't double-count the herd.
/// - Result is sorted ascending by `categoryId`.
List<AnimalCount> animalCountsFromPrestations(
    List<TourStopPrestation> prestations) {
  final byCategory = <int, int>{};
  for (final p in prestations) {
    final cid = p.categoryIdSnapshot;
    if (cid == null) continue;
    final existing = byCategory[cid];
    if (existing == null || p.qty > existing) {
      byCategory[cid] = p.qty;
    }
  }
  final ids = byCategory.keys.toList()..sort();
  return [
    for (final id in ids) AnimalCount(categoryId: id, count: byCategory[id]!),
  ];
}
