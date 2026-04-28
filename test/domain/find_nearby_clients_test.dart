import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/distance_matrix_entry.dart';
import 'package:coup_laine/domain/use_cases/find_nearby_clients.dart';
import 'package:flutter_test/flutter_test.dart';

Client _c(int id, String name, {bool waiting = true}) => Client(
      id: id,
      name: name,
      addressLabel: 'a',
      postcode: '00000',
      city: 'X',
      coordinates: const Coordinates(lat: 48, lon: -3),
      isWaiting: waiting,
    );

DistanceMatrixEntry _e(int from, int to, int dist) =>
    DistanceMatrixEntry(
      fromId: from,
      toId: to,
      distanceMeters: dist,
      durationSeconds: dist ~/ 14,
      computedAt: DateTime(2026),
    );

void main() {
  test('FindNearbyClients sorts by distance and excludes pivot', () {
    final result = const FindNearbyClients().call(
      pivotId: 1,
      maxRadiusMeters: 15000,
      candidates: [
        _c(2, 'B'),
        _c(3, 'C'),
        _c(4, 'D', waiting: false),
        _c(5, 'E'),
      ],
      pivotDistances: [
        _e(1, 2, 10000),
        _e(1, 3, 5000),
        _e(1, 5, 20000), // out of radius
      ],
    );
    expect(result.map((r) => r.client.name), ['C', 'B']);
    expect(result.first.distanceMeters, 5000);
  });
}
