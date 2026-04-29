import '../models/client.dart';
import '../models/distance_matrix_entry.dart';
import 'client_status.dart';

class NearbyClient {
  final Client client;
  final int distanceMeters;
  final int durationSeconds;
  const NearbyClient({
    required this.client,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class FindNearbyClients {
  const FindNearbyClients();

  List<NearbyClient> call({
    required int pivotId,
    required int maxRadiusMeters,
    required List<Client> candidates,
    required List<DistanceMatrixEntry> pivotDistances,
    required Map<int, ClientStatus> statusByClientId,
  }) {
    final byId = {for (final c in candidates) c.id: c};
    final results = <NearbyClient>[];
    for (final e in pivotDistances) {
      if (e.distanceMeters > maxRadiusMeters) continue;
      if (e.toId == pivotId) continue;
      final c = byId[e.toId];
      if (c == null) continue;
      if (statusByClientId[c.id] != ClientStatus.waiting) continue;
      results.add(NearbyClient(
        client: c,
        distanceMeters: e.distanceMeters,
        durationSeconds: e.durationSeconds,
      ));
    }
    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }
}
