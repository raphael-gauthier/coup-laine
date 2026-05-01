// lib/state/providers/map_kpis.dart
//
// KPI de la Map : count de clients par statut. Utilisé pour l'AppKpiRow
// flottante de la Map (chips tappables qui togglent l'affichage par statut).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/use_cases/client_status.dart';
import '../providers.dart';

/// Map de `ClientStatus → nombre de clients dans cet état`.
final clientCountByStatusProvider =
    FutureProvider.autoDispose<Map<ClientStatus, int>>((ref) async {
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart =
      settings?.seasonStartedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final all = await ref
      .watch(clientRepositoryProvider)
      .listAllWithStatus(seasonStart);
  final out = <ClientStatus, int>{
    for (final s in ClientStatus.values) s: 0,
  };
  for (final r in all) {
    out[r.$2] = (out[r.$2] ?? 0) + 1;
  }
  return out;
});
