import '../models/distance_matrix_entry.dart';

class FindClientsNearAnchors {
  const FindClientsNearAnchors();

  /// Returns the subset of [candidateIds] whose minimum routing distance
  /// (via [matrix]) to any of the [anchorIds] is less than or equal to
  /// [radiusMeters]. Anchors themselves are always included (a candidate
  /// that is also an anchor is at distance 0 to itself).
  ///
  /// A candidate with no matrix entry to any anchor is excluded.
  Set<int> call({
    required Set<int> anchorIds,
    required List<int> candidateIds,
    required List<DistanceMatrixEntry> matrix,
    required int radiusMeters,
  }) {
    if (anchorIds.isEmpty || candidateIds.isEmpty) return const {};

    // Build a quick lookup: (from, to) -> distance.
    final dist = <int, Map<int, int>>{};
    for (final e in matrix) {
      (dist[e.fromId] ??= {})[e.toId] = e.distanceMeters;
    }

    final out = <int>{};
    for (final cid in candidateIds) {
      if (anchorIds.contains(cid)) {
        out.add(cid);
        continue;
      }
      var best = -1;
      for (final aid in anchorIds) {
        final d = dist[aid]?[cid] ?? dist[cid]?[aid];
        if (d == null) continue;
        if (best == -1 || d < best) best = d;
      }
      if (best != -1 && best <= radiusMeters) out.add(cid);
    }
    return out;
  }
}
