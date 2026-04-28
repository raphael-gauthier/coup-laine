import 'package:coupe_laine/domain/models/client.dart';
import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:coupe_laine/domain/models/distance_matrix_entry.dart';
import 'package:coupe_laine/domain/models/settings.dart';
import 'package:coupe_laine/domain/use_cases/build_tour_draft.dart';
import 'package:flutter_test/flutter_test.dart';

Client _c(int id, String name, int sheep) => Client(
      id: id,
      name: name,
      addressLabel: 'a',
      postcode: '00000',
      city: 'X',
      coordinates: const Coordinates(lat: 48, lon: -3),
      sheepCount: sheep,
      isWaiting: true,
    );

DistanceMatrixEntry _e(int from, int to, int dist, int dur) =>
    DistanceMatrixEntry(
      fromId: from,
      toId: to,
      distanceMeters: dist,
      durationSeconds: dur,
      computedAt: DateTime(2026),
    );

void main() {
  test('builds a draft with optimised order, totals and fee shares', () {
    const settings = Settings(
      baseCoordinates: Coordinates(lat: 48.5, lon: -2.7),
      baseAddressLabel: 'base',
    );
    final clients = [_c(1, 'A', 5), _c(2, 'B', 3), _c(3, 'C', 8)];
    // Distances chosen so that NN/2-opt visit order is 1,2,3.
    final matrix = [
      _e(0, 1, 5000, 600), _e(1, 0, 5000, 600),
      _e(0, 2, 8000, 900), _e(2, 0, 8000, 900),
      _e(0, 3, 25000, 1800), _e(3, 0, 25000, 1800),
      _e(1, 2, 4000, 480), _e(2, 1, 4000, 480),
      _e(1, 3, 22000, 1500), _e(3, 1, 22000, 1500),
      _e(2, 3, 18000, 1200), _e(3, 2, 18000, 1200),
    ];
    final draft = const BuildTourDraft().build(
      candidateIds: const [1, 2, 3],
      candidates: clients,
      matrix: matrix,
      settings: settings,
      startTimeMinutes: 8 * 60,
    );
    // Visit order should be [1, 2, 3]: closest first then progressing outward
    expect(draft.orderedClientIds, [1, 2, 3]);
    // Total distance: base→1 (5) + 1→2 (4) + 2→3 (18) + 3→base (25) = 52 km
    expect(draft.totalDistanceMeters, 5000 + 4000 + 18000 + 25000);
    // Farthest stop = 3 (25 km) → 3 brackets → 24 €
    // Inter = 4 + 18 = 22 km → 3 brackets → 24 €
    // Total fee = 48 € = 4800 cents
    expect(draft.totalFeeCents, 4800);
    // Shares: 4800 / 3 = 1600 each, no remainder
    expect(draft.feeShareCents, [1600, 1600, 1600]);
    // Arrivals: 8:00 + 10 min drive = 8:10 first stop
    expect(draft.arrivalMinutes.first, 8 * 60 + 10);
  });
}
