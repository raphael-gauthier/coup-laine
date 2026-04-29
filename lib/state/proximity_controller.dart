import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/models/client.dart';
import '../domain/use_cases/find_nearby_clients.dart';
import 'providers.dart';

class ProximityRequest {
  final int pivotId;
  final int radiusKm;
  const ProximityRequest({required this.pivotId, required this.radiusKm});
}

final proximityRequestProvider = StateProvider<ProximityRequest?>((_) => null);

final proximityResultsProvider =
    FutureProvider.autoDispose<List<NearbyClient>>((ref) async {
  final req = ref.watch(proximityRequestProvider);
  if (req == null) return const [];
  final clients = ref.watch(clientRepositoryProvider);
  final matrix = ref.watch(distanceMatrixRepositoryProvider);
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final withStatus = await clients.listAllWithStatus(seasonStart);
  final candidates = [for (final r in withStatus) r.$1];
  final statusByClientId = {
    for (final r in withStatus) r.$1.id: r.$2,
  };
  final entries = await matrix.distancesFromPivot(
    pivotId: req.pivotId,
    maxDistanceMeters: req.radiusKm * 1000,
  );
  return const FindNearbyClients().call(
    pivotId: req.pivotId,
    maxRadiusMeters: req.radiusKm * 1000,
    candidates: candidates,
    pivotDistances: entries,
    statusByClientId: statusByClientId,
  );
});

final pivotClientProvider =
    FutureProvider.autoDispose.family<Client?, int>((ref, id) {
  return ref.watch(clientRepositoryProvider).findById(id);
});

/// Selected client ids to add to a draft tour. The pivot is implicitly
/// always included.
final tourSelectionProvider =
    StateNotifierProvider<TourSelection, Set<int>>((_) => TourSelection());

class TourSelection extends StateNotifier<Set<int>> {
  TourSelection() : super(const {});

  void toggle(int id) {
    final next = {...state};
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  void clear() => state = const {};
}
