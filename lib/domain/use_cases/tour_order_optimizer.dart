class TourOrderOptimizer {
  const TourOrderOptimizer();

  /// [distanceMatrix] is square, index 0 is the base, indices 1..n are stops.
  /// Returns visit order over [1..n] minimising the closed tour cost.
  List<int> optimise({required List<List<int>> distanceMatrix}) {
    final n = distanceMatrix.length;
    for (final row in distanceMatrix) {
      if (row.length != n) {
        throw ArgumentError('Matrix must be square (got non-square row)');
      }
    }
    if (n <= 1) return const [];
    if (n == 2) return [1];

    final seed = _nearestNeighbour(distanceMatrix);
    final improved = _twoOpt(distanceMatrix, seed);
    return improved;
  }

  List<int> _nearestNeighbour(List<List<int>> m) {
    final n = m.length;
    final visited = List<bool>.filled(n, false);
    visited[0] = true;
    final order = <int>[];
    var current = 0;
    while (order.length < n - 1) {
      var best = -1;
      var bestD = 1 << 62;
      for (var j = 1; j < n; j++) {
        if (visited[j]) continue;
        final d = m[current][j];
        if (d < bestD) {
          bestD = d;
          best = j;
        }
      }
      visited[best] = true;
      order.add(best);
      current = best;
    }
    return order;
  }

  List<int> _twoOpt(List<List<int>> m, List<int> initial) {
    final order = List<int>.from(initial);
    var improved = true;
    while (improved) {
      improved = false;
      for (var i = 0; i < order.length - 1; i++) {
        for (var k = i + 1; k < order.length; k++) {
          final delta = _twoOptDelta(m, order, i, k);
          if (delta < 0) {
            _reverseSegment(order, i, k);
            improved = true;
          }
        }
      }
    }
    return order;
  }

  int _twoOptDelta(List<List<int>> m, List<int> order, int i, int k) {
    final a = i == 0 ? 0 : order[i - 1];
    final b = order[i];
    final c = order[k];
    final d = k == order.length - 1 ? 0 : order[k + 1];
    final before = m[a][b] + m[c][d];
    final after = m[a][c] + m[b][d];
    return after - before;
  }

  void _reverseSegment(List<int> order, int i, int k) {
    while (i < k) {
      final tmp = order[i];
      order[i] = order[k];
      order[k] = tmp;
      i++;
      k--;
    }
  }
}
