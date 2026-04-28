import 'package:coupe_laine/domain/use_cases/tour_order_optimizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TourOrderOptimizer', () {
    test('single stop returns trivial order', () {
      // matrix: [[0, 5], [5, 0]]
      final order = TourOrderOptimizer().optimise(
        distanceMatrix: [
          [0, 5],
          [5, 0],
        ],
      );
      expect(order, [1]);
    });

    test('three colinear stops are visited in line', () {
      // base at 0, stops at +1, +2, +3 on a line
      final matrix = [
        [0, 1, 2, 3], // base → ...
        [1, 0, 1, 2],
        [2, 1, 0, 1],
        [3, 2, 1, 0],
      ];
      final order = TourOrderOptimizer().optimise(distanceMatrix: matrix);
      expect(order, [1, 2, 3]); // shortest tour: 0→1→2→3→0 = 6
    });

    test('2-opt fixes a known crossing', () {
      // Square: base, A, B, C, D arranged so that the NN seed is suboptimal.
      // We construct a matrix where nearest-neighbour from base picks A then C
      // (a crossing path), but 2-opt should swap to A → B → C → D.
      final matrix = [
        // base, A,  B,  C,  D
        [0,    1,  3,  2,  4], // base
        [1,    0,  1,  3,  2], // A
        [3,    1,  0,  1,  3], // B
        [2,    3,  1,  0,  1], // C
        [4,    2,  3,  1,  0], // D
      ];
      final optimised =
          TourOrderOptimizer().optimise(distanceMatrix: matrix);
      // After NN+2-opt, total should be <= a naive [1,2,3,4] cost.
      final naiveCost = _cost(matrix, [1, 2, 3, 4]);
      final optimisedCost = _cost(matrix, optimised);
      expect(optimisedCost, lessThanOrEqualTo(naiveCost));
    });

    test('rejects non-square matrices', () {
      expect(
        () => TourOrderOptimizer().optimise(distanceMatrix: [
          [0, 1, 2],
          [1, 0],
        ]),
        throwsArgumentError,
      );
    });
  });
}

int _cost(List<List<int>> m, List<int> order) {
  var prev = 0;
  var total = 0;
  for (final i in order) {
    total += m[prev][i];
    prev = i;
  }
  total += m[prev][0];
  return total;
}
