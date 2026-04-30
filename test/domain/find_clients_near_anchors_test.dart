import 'package:coup_laine/domain/models/distance_matrix_entry.dart';
import 'package:coup_laine/domain/use_cases/find_clients_near_anchors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DistanceMatrixEntry e(int from, int to, int meters) => DistanceMatrixEntry(
        fromId: from,
        toId: to,
        distanceMeters: meters,
        durationSeconds: 0,
        computedAt: DateTime(2026, 1, 1),
      );

  group('FindClientsNearAnchors', () {
    test('anchors are always included even with no matrix', () {
      final out = const FindClientsNearAnchors().call(
        anchorIds: {1, 2},
        candidateIds: const [1, 2, 3],
        matrix: const [],
        radiusMeters: 5000,
      );
      expect(out, {1, 2});
    });

    test('candidate within radius of any anchor is included', () {
      final out = const FindClientsNearAnchors().call(
        anchorIds: {1},
        candidateIds: const [2, 3],
        matrix: [e(1, 2, 4000), e(1, 3, 6000)],
        radiusMeters: 5000,
      );
      expect(out, {2});
    });

    test('uses min distance across multiple anchors', () {
      final out = const FindClientsNearAnchors().call(
        anchorIds: {1, 10},
        candidateIds: const [2],
        matrix: [e(1, 2, 9000), e(10, 2, 3000)],
        radiusMeters: 5000,
      );
      expect(out, {2});
    });

    test('falls back to reverse direction if forward entry missing', () {
      final out = const FindClientsNearAnchors().call(
        anchorIds: {1},
        candidateIds: const [2],
        matrix: [e(2, 1, 4000)],
        radiusMeters: 5000,
      );
      expect(out, {2});
    });

    test('candidate with no matrix entry is excluded', () {
      final out = const FindClientsNearAnchors().call(
        anchorIds: {1},
        candidateIds: const [99],
        matrix: const [],
        radiusMeters: 100000,
      );
      expect(out, isEmpty);
    });

    test('empty inputs return empty', () {
      const uc = FindClientsNearAnchors();
      expect(uc.call(anchorIds: const {}, candidateIds: const [1], matrix: const [], radiusMeters: 5000), isEmpty);
      expect(uc.call(anchorIds: {1}, candidateIds: const [], matrix: const [], radiusMeters: 5000), isEmpty);
    });
  });
}
