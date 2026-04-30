import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/distance_matrix_entry.dart';
import 'package:coup_laine/domain/models/settings.dart';
import 'package:coup_laine/domain/use_cases/build_tour_draft.dart';
import 'package:flutter_test/flutter_test.dart';

Client _c(int id, String name, int total) => Client(
      id: id,
      name: name,
      addressLabel: 'a',
      postcode: '00000',
      city: 'X',
      coordinates: const Coordinates(lat: 48, lon: -3),
      animals: [AnimalCount(categoryId: 1, count: total)],
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

const _categoryLookup = <int,
    ({String speciesName, String categoryName, int minutes})>{
  1: (speciesName: 'Mouton', categoryName: 'Adulte', minutes: 8),
};

void main() {
  test('builds a draft with optimised order, totals and fee shares', () {
    final settings = Settings(
      baseCoordinates: const Coordinates(lat: 48.5, lon: -2.7),
      baseAddressLabel: 'base',
      seasonStartedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    final clients = [_c(1, 'A', 5), _c(2, 'B', 3), _c(3, 'C', 8)]; // totals: 5, 3, 8
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
      categoryLookup: _categoryLookup,
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
    // Per-stop planned animals carry the snapshot data from the lookup.
    expect(draft.plannedAnimalsPerStop.length, 3);
    expect(draft.plannedAnimalsPerStop[0].first.categoryId, 1);
    expect(draft.plannedAnimalsPerStop[0].first.count, 5);
    expect(draft.plannedAnimalsPerStop[0].first.minutesSnapshot, 8);
    expect(draft.plannedAnimalsPerStop[0].first.categoryNameSnapshot, 'Adulte');
    expect(draft.plannedAnimalsPerStop[0].first.speciesNameSnapshot, 'Mouton');
    expect(draft.plannedAnimalsPerStop[1].first.count, 3);
    expect(draft.plannedAnimalsPerStop[2].first.count, 8);
  });

  test('AnimalCount entries with unknown categoryId are skipped silently', () {
    final settings = Settings(
      baseCoordinates: const Coordinates(lat: 48.5, lon: -2.7),
      baseAddressLabel: 'base',
      seasonStartedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    final client = Client(
      id: 1,
      name: 'A',
      addressLabel: 'a',
      postcode: '00000',
      city: 'X',
      coordinates: const Coordinates(lat: 48, lon: -3),
      animals: const [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 99, count: 7), // category deleted/unknown
      ],
      isWaiting: true,
    );
    final matrix = [
      _e(0, 1, 5000, 600),
      _e(1, 0, 5000, 600),
    ];
    final draft = const BuildTourDraft().build(
      candidateIds: const [1],
      candidates: [client],
      matrix: matrix,
      settings: settings,
      categoryLookup: _categoryLookup,
      startTimeMinutes: 8 * 60,
    );
    expect(draft.plannedAnimalsPerStop.first.length, 1);
    expect(draft.plannedAnimalsPerStop.first.first.categoryId, 1);
  });
}
