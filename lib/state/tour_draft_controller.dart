import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/models/client.dart';
import '../domain/models/distance_matrix_entry.dart';
import '../domain/use_cases/build_tour_draft.dart';
import 'providers.dart';

class TourDraftInput {
  final int? pivotId;
  final List<int> selectedIds;
  final DateTime plannedDate;
  final int startTimeMinutes;
  final List<int>? overrideOrder;
  const TourDraftInput({
    this.pivotId,
    required this.selectedIds,
    required this.plannedDate,
    required this.startTimeMinutes,
    this.overrideOrder,
  });
}

final tourDraftInputProvider = StateProvider<TourDraftInput?>((_) => null);

class TourDraftBundle {
  final TourDraftResult result;
  final List<Client> orderedClients;
  const TourDraftBundle({required this.result, required this.orderedClients});
}

final tourDraftProvider =
    FutureProvider.autoDispose<TourDraftBundle?>((ref) async {
  final input = ref.watch(tourDraftInputProvider);
  if (input == null) return null;
  // All ref.watch calls happen synchronously up-front so the dependency
  // graph is registered before any await — otherwise the ref can be
  // disposed mid-build if the input changes during the matrix loop.
  final clients = ref.watch(clientRepositoryProvider);
  final matrix = ref.watch(distanceMatrixRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);

  final settings = await settingsRepo.read();
  if (settings == null) return null;

  final all = await clients.listAll();
  final ids = input.pivotId == null
      ? [...input.selectedIds]
      : [input.pivotId!, ...input.selectedIds.where((id) => id != input.pivotId)];

  // We need every matrix cell in the sub-matrix. Pull all rows from any of
  // these node ids. Including base (0) explicitly.
  final nodeIds = [0, ...ids];
  final entries = <DistanceMatrixEntry>[];
  for (final from in nodeIds) {
    for (final to in nodeIds) {
      if (from == to) continue;
      final m = await matrix.distanceMeters(from: from, to: to);
      final s = await matrix.durationSeconds(from: from, to: to);
      if (m == null || s == null) continue;
      entries.add(DistanceMatrixEntry(
        fromId: from,
        toId: to,
        distanceMeters: m,
        durationSeconds: s,
        computedAt: DateTime.now(),
      ));
    }
  }

  final result = const BuildTourDraft().build(
    candidateIds: ids,
    candidates: all,
    matrix: entries,
    settings: settings,
    prestationsPerClient: const {},
    startTimeMinutes: input.startTimeMinutes,
    presetOrder: input.overrideOrder,
  );
  final byId = {for (final c in all) c.id: c};
  final orderedClients =
      result.orderedClientIds.map((id) => byId[id]!).toList();
  return TourDraftBundle(result: result, orderedClients: orderedClients);
});
