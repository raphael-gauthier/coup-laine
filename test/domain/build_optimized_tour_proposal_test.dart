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
  int large = 0,
}) =>
    Client(
      id: id,
      name: 'C$id',
      addressLabel: 'a',
      postcode: '00000',
      city: city,
      coordinates: Coordinates(lat: lat, lon: lon),
      sheepCountSmall: small,
      sheepCountLarge: large,
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
}
