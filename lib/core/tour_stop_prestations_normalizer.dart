import '../domain/models/tour_stop_prestation.dart';

/// Canonicalizes a list of [TourStopPrestation] before persistence:
///   - drops `qty <= 0`,
///   - DOES NOT dedup by `prestationId` (multiple distinct rows are allowed),
///   - stable sort by `prestationId` ascending; insertion order preserved
///     for ties.
List<TourStopPrestation> normalizeTourStopPrestations(
    List<TourStopPrestation> input) {
  final filtered = [
    for (final p in input)
      if (p.qty > 0) p,
  ];
  filtered.sort((a, b) => a.prestationId.compareTo(b.prestationId));
  return filtered;
}
