import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/distance_matrix_entry.dart';
import 'package:coup_laine/domain/models/settings.dart';
import 'package:coup_laine/domain/use_cases/build_optimized_tour_proposal.dart';
import 'package:flutter_test/flutter_test.dart';

Client _c(
  int id,
  String city, {
  double lat = 48,
  double lon = -3,
  int small = 5,
}) =>
    Client(
      id: id,
      name: 'C$id',
      addressLabel: 'a',
      postcode: '00000',
      city: city,
      coordinates: Coordinates(lat: lat, lon: lon),
      animals: [AnimalCount(categoryId: 1, count: small)],
      isWaiting: true,
    );

DistanceMatrixEntry _e(int from, int to, int dist, [int? dur]) =>
    DistanceMatrixEntry(
      fromId: from,
      toId: to,
      distanceMeters: dist,
      durationSeconds: dur ?? (dist ~/ 14), // ~50 km/h average
      computedAt: DateTime(2026),
    );

Settings _settings() => Settings(
      baseCoordinates: const Coordinates(lat: 48.5, lon: -2.7),
      baseAddressLabel: 'base',
      seasonStartedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

/// Build a fully-symmetric matrix between every pair in [ids] (incl. base 0).
List<DistanceMatrixEntry> _fullMatrix(
  List<int> ids,
  int Function(int from, int to) distFn,
) {
  final out = <DistanceMatrixEntry>[];
  for (final a in ids) {
    for (final b in ids) {
      if (a == b) continue;
      out.add(_e(a, b, distFn(a, b)));
    }
  }
  return out;
}

void main() {
  test('seed of two clients close to target returns seed unchanged', () {
    final clients = [_c(1, 'Quimper'), _c(2, 'Quimper')];
    final matrix = _fullMatrix(
      [0, 1, 2],
      (a, b) => 8000, // 8 km between any pair → ~10 min drive
    );
    final result = const BuildOptimizedTourProposal().call(
      communeName: 'Quimper',
      targetMinutes: 90, // generous → seed fits well
      startTimeMinutes: 8 * 60,
      waitingClients: clients,
      matrix: matrix,
      settings: _settings(),
    );
    expect(result.selectedClientIds.toSet(), {1, 2});
    expect(result.isUnderTarget, isFalse);
    expect(result.isOverTarget, isFalse);
  });

  test('extension: under-target seed picks up nearest waiting outsiders', () {
    // Seed is 1 client → ~25 min, target 4h. Extension must add the closest
    // outsider (id=10, same coords) before the farther one (id=20).
    final clients = [
      _c(1, 'Quimper', lat: 48.0, lon: -4.0),
      _c(10, 'Plomelin', lat: 48.0, lon: -4.0), // close
      _c(20, 'Brest', lat: 48.4, lon: -4.5),    // far
    ];
    final matrix = _fullMatrix(
      [0, 1, 10, 20],
      (a, b) {
        // Define a metric that makes (0,1,10) cheap and 20 expensive.
        const cheap = 5000;
        const far = 25000;
        if (a == 20 || b == 20) return far;
        return cheap;
      },
    );
    final result = const BuildOptimizedTourProposal().call(
      communeName: 'Quimper',
      targetMinutes: 90, // ~1h30, fits seed + 1 cheap outsider
      startTimeMinutes: 8 * 60,
      waitingClients: clients,
      matrix: matrix,
      settings: _settings(),
    );
    expect(result.selectedClientIds, contains(1));
    expect(result.selectedClientIds, contains(10));
    expect(result.selectedClientIds, isNot(contains(20)));
  });

  test('extension stops when adding next candidate would exceed tolerance', () {
    // Seed = 1 client. Target = small. Two candidates: the first fits, the
    // second pushes us past target+30.
    final clients = [
      _c(1, 'Quimper'),
      _c(10, 'Plomelin'),
      _c(20, 'Brest'),
    ];
    final matrix = _fullMatrix(
      [0, 1, 10, 20],
      (a, b) => 8000,
    );
    final result = const BuildOptimizedTourProposal().call(
      communeName: 'Quimper',
      targetMinutes: 70, // tight: roughly fits 2 stops
      startTimeMinutes: 8 * 60,
      waitingClients: clients,
      matrix: matrix,
      settings: _settings(),
    );
    expect(result.selectedClientIds.length, lessThanOrEqualTo(2));
  });

  test('extension: no eligible neighbours leaves seed alone', () {
    final clients = [
      _c(1, 'Quimper', small: 1),
      _c(2, 'Quimper', small: 1),
    ]; // tiny seed → under-target
    final matrix = _fullMatrix([0, 1, 2], (a, b) => 5000);
    final result = const BuildOptimizedTourProposal().call(
      communeName: 'Quimper',
      targetMinutes: 8 * 60, // 8 h target, seed is way short
      startTimeMinutes: 8 * 60,
      waitingClients: clients,
      matrix: matrix,
      settings: _settings(),
    );
    expect(result.selectedClientIds.toSet(), {1, 2});
    expect(result.isUnderTarget, isTrue);
  });

  test('contraction: over-target seed sheds the farthest from barycentre', () {
    // Seed of 4 clients in Quimper, three clustered tightly + one outlier.
    // Target small enough that the outlier must be removed.
    final clients = [
      _c(1, 'Quimper', lat: 48.00, lon: -4.10, small: 5),
      _c(2, 'Quimper', lat: 48.00, lon: -4.11, small: 5),
      _c(3, 'Quimper', lat: 48.00, lon: -4.12, small: 5),
      _c(4, 'Quimper', lat: 48.30, lon: -4.50, small: 5), // outlier
    ];
    final matrix = _fullMatrix(
      [0, 1, 2, 3, 4],
      (a, b) {
        // Cluster 1/2/3 close, 4 far from everyone.
        if (a == 4 || b == 4) return 30000;
        return 4000;
      },
    );
    final result = const BuildOptimizedTourProposal().call(
      communeName: 'Quimper',
      targetMinutes: 120,
      startTimeMinutes: 8 * 60,
      waitingClients: clients,
      matrix: matrix,
      settings: _settings(),
    );
    expect(result.selectedClientIds, isNot(contains(4)));
    expect(result.selectedClientIds.length, greaterThanOrEqualTo(1));
  });

  test('contraction never goes below 1 stop even if target is irrealistic', () {
    final clients = [
      _c(1, 'Quimper', small: 50),
      _c(2, 'Quimper', small: 50),
    ];
    final matrix = _fullMatrix([0, 1, 2], (a, b) => 30000);
    final result = const BuildOptimizedTourProposal().call(
      communeName: 'Quimper',
      targetMinutes: 30, // way too short
      startTimeMinutes: 8 * 60,
      waitingClients: clients,
      matrix: matrix,
      settings: _settings(),
    );
    expect(result.selectedClientIds.length, 1);
    expect(result.isOverTarget, isTrue);
  });

  test('returns empty proposal when commune has no eligible clients', () {
    final clients = [_c(1, 'Quimper', small: 5)];
    final matrix = _fullMatrix([0, 1], (a, b) => 5000);
    final result = const BuildOptimizedTourProposal().call(
      communeName: 'Brest', // no client there
      targetMinutes: 8 * 60,
      startTimeMinutes: 8 * 60,
      waitingClients: clients,
      matrix: matrix,
      settings: _settings(),
    );
    expect(result.selectedClientIds, isEmpty);
  });

  test('skips clients flagged needsDistanceRecompute', () {
    final clients = [
      _c(1, 'Quimper'),
      Client(
        id: 2,
        name: 'C2',
        addressLabel: 'a',
        postcode: '00000',
        city: 'Quimper',
        coordinates: const Coordinates(lat: 48, lon: -3),
        animals: const [AnimalCount(categoryId: 1, count: 5)],
        isWaiting: true,
        needsDistanceRecompute: true,
      ),
    ];
    final matrix = _fullMatrix([0, 1], (a, b) => 5000);
    final result = const BuildOptimizedTourProposal().call(
      communeName: 'Quimper',
      targetMinutes: 90,
      startTimeMinutes: 8 * 60,
      waitingClients: clients,
      matrix: matrix,
      settings: _settings(),
    );
    expect(result.selectedClientIds, [1]);
  });
}
