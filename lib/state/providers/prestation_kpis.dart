// lib/state/providers/prestation_kpis.dart
//
// KPIs du catalogue de prestations : count actives/archivées et revenu du mois
// courant (somme des prestations réalisées sur les tournées complétées dans le
// mois).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/tour.dart';
import '../providers.dart';

typedef PrestationCatalogKpis = ({
  int activeCount,
  int archivedCount,
  int monthRevenueCents,
});

final prestationCatalogKpisProvider =
    FutureProvider.autoDispose<PrestationCatalogKpis>((ref) async {
  final active = await ref.watch(activePrestationsProvider.future);
  final archived = await ref.watch(archivedPrestationsProvider.future);

  // Revenue = sum of priceCentsSnapshot * qty for actualPrestations on every
  // stop of every completed tour whose plannedDate falls in the current month.
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 1);

  final tourRepo = ref.watch(tourRepositoryProvider);
  final allTours = await tourRepo.listAll();

  final completedThisMonth = allTours.where((t) =>
      t.status == TourStatus.completed &&
      !t.plannedDate.isBefore(monthStart) &&
      t.plannedDate.isBefore(monthEnd));

  var monthRevenueCents = 0;
  for (final tour in completedThisMonth) {
    final bundle = await tourRepo.findById(tour.id);
    if (bundle == null) continue;
    for (final stop in bundle.stops) {
      final prestations = stop.actualPrestations ?? stop.plannedPrestations;
      for (final p in prestations) {
        monthRevenueCents += p.priceCentsSnapshot * p.qty;
      }
    }
  }

  return (
    activeCount: active.length,
    archivedCount: archived.length,
    monthRevenueCents: monthRevenueCents,
  );
});
