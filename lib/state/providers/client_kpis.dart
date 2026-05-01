// lib/state/providers/client_kpis.dart
//
// KPIs de Client detail. Calcule à partir de l'historique des interventions
// (déjà fourni par historyForClientProvider) :
// - nb interventions
// - revenu cumulé (somme priceCentsSnapshot × qty)
// - première / dernière intervention (pour years-of-relationship affichage).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/intervention.dart';
import '../providers.dart';

class ClientKpis {
  final int interventionCount;
  final int totalRevenueCents;
  final DateTime? firstInterventionDate;
  final DateTime? lastInterventionDate;

  const ClientKpis({
    required this.interventionCount,
    required this.totalRevenueCents,
    this.firstInterventionDate,
    this.lastInterventionDate,
  });
}

ClientKpis computeClientKpis(List<Intervention> interventions) {
  if (interventions.isEmpty) {
    return const ClientKpis(interventionCount: 0, totalRevenueCents: 0);
  }
  var revenue = 0;
  DateTime? firstDate;
  DateTime? lastDate;
  for (final it in interventions) {
    for (final p in it.prestations) {
      revenue += p.priceCentsSnapshot * p.qty;
    }
    if (firstDate == null || it.date.isBefore(firstDate)) firstDate = it.date;
    if (lastDate == null || it.date.isAfter(lastDate)) lastDate = it.date;
  }
  return ClientKpis(
    interventionCount: interventions.length,
    totalRevenueCents: revenue,
    firstInterventionDate: firstDate,
    lastInterventionDate: lastDate,
  );
}

/// Provider qui dérive les KPIs depuis `historyForClientProvider`.
final clientKpisProvider =
    FutureProvider.family.autoDispose<ClientKpis, int>((ref, clientId) async {
  final interventions = await ref.watch(historyForClientProvider(clientId).future);
  return computeClientKpis(interventions);
});
