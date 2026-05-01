import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/distance_matrix_entry.dart';
import 'package:coup_laine/domain/models/settings.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';
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

TourStopPrestation _p({
  int prestationId = 1,
  required int qty,
  int minutes = 8,
  int priceCents = 1000,
}) =>
    TourStopPrestation(
      prestationId: prestationId,
      qty: qty,
      nameSnapshot: 'Tonte',
      priceCentsSnapshot: priceCents,
      minutesSnapshot: minutes,
      categoryIdSnapshot: 1,
      categoryNameSnapshot: 'Adulte',
      speciesNameSnapshot: 'Mouton',
    );

Settings _settings() => Settings(
      baseCoordinates: const Coordinates(lat: 48.5, lon: -2.7),
      baseAddressLabel: 'base',
      seasonStartedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

void main() {
  test('builds a draft with optimised order, totals and fee shares', () {
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
    final prestationsPerClient = <int, List<TourStopPrestation>>{
      1: [_p(qty: 5)],
      2: [_p(qty: 3)],
      3: [_p(qty: 8)],
    };
    final draft = const BuildTourDraft().build(
      candidateIds: const [1, 2, 3],
      candidates: clients,
      matrix: matrix,
      settings: _settings(),
      prestationsPerClient: prestationsPerClient,
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
    // Per-stop planned prestations come from the input map.
    expect(draft.plannedPrestationsPerStop.length, 3);
    expect(draft.plannedPrestationsPerStop[0].first.prestationId, 1);
    expect(draft.plannedPrestationsPerStop[0].first.qty, 5);
    expect(draft.plannedPrestationsPerStop[0].first.minutesSnapshot, 8);
    expect(draft.plannedPrestationsPerStop[0].first.nameSnapshot, 'Tonte');
    expect(draft.plannedPrestationsPerStop[1].first.qty, 3);
    expect(draft.plannedPrestationsPerStop[2].first.qty, 8);
  });

  test('revenue and net are computed from prestation snapshots', () {
    final clients = [_c(1, 'A', 5), _c(2, 'B', 3)];
    final matrix = [
      _e(0, 1, 5000, 600), _e(1, 0, 5000, 600),
      _e(0, 2, 8000, 900), _e(2, 0, 8000, 900),
      _e(1, 2, 4000, 480), _e(2, 1, 4000, 480),
    ];
    final prestationsPerClient = <int, List<TourStopPrestation>>{
      1: [_p(prestationId: 1, qty: 5, priceCents: 1000)], // 5 × 1000 = 5000
      2: [
        _p(prestationId: 1, qty: 3, priceCents: 1000),    // 3000
        _p(prestationId: 2, qty: 2, priceCents: 2500),    // 5000
      ],
    };
    final draft = const BuildTourDraft().build(
      candidateIds: const [1, 2],
      candidates: clients,
      matrix: matrix,
      settings: _settings(),
      prestationsPerClient: prestationsPerClient,
      startTimeMinutes: 8 * 60,
    );
    // Order is [1, 2] (1 is closer to base).
    expect(draft.orderedClientIds, [1, 2]);
    expect(draft.revenueCentsPerStop, [5000, 8000]);
    expect(draft.totalRevenueCents, 13000);
    expect(draft.totalNetCents, 13000 - draft.totalFeeCents);
  });

  test('revenue is 0 when no prestation provided', () {
    final clients = [_c(1, 'A', 5)];
    final matrix = [
      _e(0, 1, 5000, 600),
      _e(1, 0, 5000, 600),
    ];
    final draft = const BuildTourDraft().build(
      candidateIds: const [1],
      candidates: clients,
      matrix: matrix,
      settings: _settings(),
      prestationsPerClient: const {},
      startTimeMinutes: 8 * 60,
    );
    expect(draft.totalRevenueCents, 0);
    expect(draft.revenueCentsPerStop, [0]);
    expect(draft.totalInterventionMinutes, 0);
    // Net is just -fee in that case.
    expect(draft.totalNetCents, -draft.totalFeeCents);
  });

  test('intervention duration is 0 when prestationsPerClient lacks an entry '
      'for a candidate', () {
    final clients = [_c(1, 'A', 5), _c(2, 'B', 3)];
    final matrix = [
      _e(0, 1, 5000, 600), _e(1, 0, 5000, 600),
      _e(0, 2, 8000, 900), _e(2, 0, 8000, 900),
      _e(1, 2, 4000, 480), _e(2, 1, 4000, 480),
    ];
    // Only client 1 has prestations. Client 2 is missing → empty list.
    final prestationsPerClient = <int, List<TourStopPrestation>>{
      1: [_p(prestationId: 1, qty: 4, minutes: 10, priceCents: 1500)],
    };
    final draft = const BuildTourDraft().build(
      candidateIds: const [1, 2],
      candidates: clients,
      matrix: matrix,
      settings: _settings(),
      prestationsPerClient: prestationsPerClient,
      startTimeMinutes: 8 * 60,
    );
    // Only client 1 contributes intervention time: 4 × 10 = 40.
    expect(draft.totalInterventionMinutes, 40);
    // Stop for client 2 has no prestations → empty list.
    final idx2 = draft.orderedClientIds.indexOf(2);
    expect(draft.plannedPrestationsPerStop[idx2], isEmpty);
    expect(draft.revenueCentsPerStop[idx2], 0);
  });
}
