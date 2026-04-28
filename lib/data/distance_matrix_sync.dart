import '../domain/models/coordinates.dart';
import '../domain/models/distance_matrix_entry.dart';
import '../infra/services/ors_routing_service.dart';
import 'repositories/client_repository.dart';
import 'repositories/distance_matrix_repository.dart';
import 'repositories/settings_repository.dart';

class DistanceMatrixSync {
  final ClientRepository clients;
  final DistanceMatrixRepository matrix;
  final SettingsRepository settings;
  final OrsRoutingService ors;

  DistanceMatrixSync({
    required this.clients,
    required this.matrix,
    required this.settings,
    required this.ors,
  });

  /// Compute outbound (X→all) and inbound (all→X) rows for [clientId],
  /// where "all" = base + every other existing client.
  Future<void> recomputeForClient(int clientId) async {
    final settingsRow = await settings.read();
    if (settingsRow == null) {
      throw StateError('Cannot compute matrix without home base');
    }
    final target = await clients.findById(clientId);
    if (target == null) {
      throw StateError('Unknown client $clientId');
    }
    final others = (await clients.listAll())
        .where((c) => c.id != clientId)
        .toList();

    // Build the locations list: index 0 = X, then base, then every other.
    final locations = <Coordinates>[
      target.coordinates,
      settingsRow.baseCoordinates,
      ...others.map((c) => c.coordinates),
    ];
    final ids = <int>[
      clientId,
      DistanceMatrixEntry.baseId,
      ...others.map((c) => c.id),
    ];

    try {
      // Outbound: from X (index 0) to all (indices 1..n)
      final outbound = await ors.matrix(
        locations: locations,
        sources: const [0],
        destinations: List.generate(locations.length - 1, (i) => i + 1),
      );
      // Inbound: from all (indices 1..n) to X (index 0)
      final inbound = await ors.matrix(
        locations: locations,
        sources: List.generate(locations.length - 1, (i) => i + 1),
        destinations: const [0],
      );

      final now = DateTime.now();
      final rows = <DistanceMatrixEntry>[];
      for (var j = 0; j < ids.length - 1; j++) {
        rows.add(DistanceMatrixEntry(
          fromId: ids[0],
          toId: ids[j + 1],
          distanceMeters: outbound.distances[0][j],
          durationSeconds: outbound.durations[0][j],
          computedAt: now,
        ));
        rows.add(DistanceMatrixEntry(
          fromId: ids[j + 1],
          toId: ids[0],
          distanceMeters: inbound.distances[j][0],
          durationSeconds: inbound.durations[j][0],
          computedAt: now,
        ));
      }
      await matrix.upsertMany(rows);
      await clients.setRecomputeDone(clientId);
    } on OrsException {
      await clients.setRecomputePending(clientId);
      rethrow;
    }
  }

  /// Recompute base ↔ all clients (when the base address changes).
  Future<void> recomputeAllForBase() async {
    final settingsRow = await settings.read();
    if (settingsRow == null) return;
    final all = await clients.listAll();
    if (all.isEmpty) return;

    final locations = <Coordinates>[
      settingsRow.baseCoordinates,
      ...all.map((c) => c.coordinates),
    ];
    final ids = <int>[
      DistanceMatrixEntry.baseId,
      ...all.map((c) => c.id),
    ];

    final outbound = await ors.matrix(
      locations: locations,
      sources: const [0],
      destinations: List.generate(all.length, (i) => i + 1),
    );
    final inbound = await ors.matrix(
      locations: locations,
      sources: List.generate(all.length, (i) => i + 1),
      destinations: const [0],
    );

    final now = DateTime.now();
    final rows = <DistanceMatrixEntry>[];
    for (var j = 0; j < all.length; j++) {
      rows.add(DistanceMatrixEntry(
        fromId: ids[0],
        toId: ids[j + 1],
        distanceMeters: outbound.distances[0][j],
        durationSeconds: outbound.durations[0][j],
        computedAt: now,
      ));
      rows.add(DistanceMatrixEntry(
        fromId: ids[j + 1],
        toId: ids[0],
        distanceMeters: inbound.distances[j][0],
        durationSeconds: inbound.durations[j][0],
        computedAt: now,
      ));
    }
    await matrix.upsertMany(rows);
  }

  /// Retry every client flagged `needsDistanceRecompute`.
  Future<int> retryAllPending() async {
    final pending = await clients.listNeedingRecompute();
    var done = 0;
    for (final c in pending) {
      try {
        await recomputeForClient(c.id);
        done++;
      } on OrsException {
        // Leave it pending; banner stays.
      }
    }
    return done;
  }
}
