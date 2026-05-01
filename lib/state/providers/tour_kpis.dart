// lib/state/providers/tour_kpis.dart
//
// KPIs de Tour detail. Agrège les prestations de tous les stops d'une
// tournée pour produire un résumé « Tonte Petit ×8 | Parage ×1 | total 480 € ».

import '../../domain/models/tour_stop_prestation.dart';

class PrestationSummary {
  final String name;
  final int qty;
  final int totalCents;
  const PrestationSummary({
    required this.name,
    required this.qty,
    required this.totalCents,
  });
}

/// Agrège une liste de listes de prestations (typiquement une par stop)
/// en regroupant par `nameSnapshot`, sommant les qty et multipliant
/// `priceCentsSnapshot * qty` pour le total.
List<PrestationSummary> aggregatePrestations(
  List<List<TourStopPrestation>> stopsPrestations,
) {
  final byName = <String, ({int qty, int totalCents})>{};
  for (final stop in stopsPrestations) {
    for (final p in stop) {
      final entry = byName[p.nameSnapshot];
      final addedQty = (entry?.qty ?? 0) + p.qty;
      final addedTotal =
          (entry?.totalCents ?? 0) + (p.priceCentsSnapshot * p.qty);
      byName[p.nameSnapshot] = (qty: addedQty, totalCents: addedTotal);
    }
  }
  return [
    for (final entry in byName.entries)
      PrestationSummary(
        name: entry.key,
        qty: entry.value.qty,
        totalCents: entry.value.totalCents,
      ),
  ];
}
