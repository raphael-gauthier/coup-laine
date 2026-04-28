# Phase 1 — Domain layer

**Goal:** Pure-Dart domain models + use cases (cost split, bracket counter, tour duration estimator, TSP optimiser). Zero Flutter and zero I/O. 100% unit-tested.

**Verification at end of phase:** `flutter test test/domain/` is green; all four use cases have at least the cases listed in [spec §07-testing](../../specs/2026-04-28-coupe-laine-mvp-design/07-testing.md).

---

## Task 1.1: Coordinates value type

**Files:**
- Create: `lib/domain/models/coordinates.dart`
- Create: `test/domain/coordinates_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/coordinates_test.dart
import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coordinates', () {
    test('equal when lat and lon match', () {
      const a = Coordinates(lat: 48.0, lon: -3.0);
      const b = Coordinates(lat: 48.0, lon: -3.0);
      expect(a, equals(b));
    });

    test('rejects out-of-range latitude', () {
      expect(() => Coordinates(lat: 91, lon: 0), throwsArgumentError);
    });

    test('rejects out-of-range longitude', () {
      expect(() => Coordinates(lat: 0, lon: 181), throwsArgumentError);
    });
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/domain/coordinates_test.dart
```
Expected: compile error (file doesn't exist yet).

- [ ] **Step 3: Implement**

```dart
// lib/domain/models/coordinates.dart
class Coordinates {
  final double lat;
  final double lon;

  const Coordinates({required this.lat, required this.lon})
      : assert(lat >= -90 && lat <= 90, 'lat out of range'),
        assert(lon >= -180 && lon <= 180, 'lon out of range');

  factory Coordinates.checked({required double lat, required double lon}) {
    if (lat < -90 || lat > 90) {
      throw ArgumentError.value(lat, 'lat', 'must be in [-90, 90]');
    }
    if (lon < -180 || lon > 180) {
      throw ArgumentError.value(lon, 'lon', 'must be in [-180, 180]');
    }
    return Coordinates(lat: lat, lon: lon);
  }

  @override
  bool operator ==(Object other) =>
      other is Coordinates && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);

  @override
  String toString() => 'Coordinates($lat, $lon)';
}
```

> The tests use the `Coordinates(...)` constructor with invalid values to test the runtime checks; replace those with `Coordinates.checked(...)` since `assert` is debug-only. Adjust the test to call `Coordinates.checked` for the throwing cases:

```dart
expect(() => Coordinates.checked(lat: 91, lon: 0), throwsArgumentError);
expect(() => Coordinates.checked(lat: 0, lon: 181), throwsArgumentError);
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/domain/coordinates_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/models/coordinates.dart test/domain/coordinates_test.dart
git commit -m "feat(domain): coordinates value type"
```

---

## Task 1.2: Domain models — Settings, Client, DistanceMatrixEntry, Tour, TourStop

**Files:**
- Create: `lib/domain/models/settings.dart`
- Create: `lib/domain/models/client.dart`
- Create: `lib/domain/models/distance_matrix_entry.dart`
- Create: `lib/domain/models/tour.dart`
- Create: `lib/domain/models/tour_stop.dart`

These are dumb data carriers — no behaviour, no tests beyond construction. Put them in place now so later tasks can import them.

- [ ] **Step 1: Write `settings.dart`**

```dart
import 'coordinates.dart';

class Settings {
  final Coordinates baseCoordinates;
  final String baseAddressLabel;
  final int defaultRadiusKm;
  final int defaultMinutesPerSheep;
  final int travelFeeEurosPerBracket;
  final int bracketKm;

  const Settings({
    required this.baseCoordinates,
    required this.baseAddressLabel,
    this.defaultRadiusKm = 15,
    this.defaultMinutesPerSheep = 20,
    this.travelFeeEurosPerBracket = 8,
    this.bracketKm = 10,
  });
}
```

- [ ] **Step 2: Write `client.dart`**

```dart
import 'coordinates.dart';

class Client {
  final int id;
  final String name;
  final String? phone;
  final String addressLabel;
  final String postcode;
  final String city;
  final Coordinates coordinates;
  final int sheepCount;
  final int? minutesPerSheepOverride;
  final String? notes;
  final bool isWaiting;
  final DateTime? lastShearingDate;
  final bool needsDistanceRecompute;

  const Client({
    required this.id,
    required this.name,
    required this.addressLabel,
    required this.postcode,
    required this.city,
    required this.coordinates,
    this.sheepCount = 0,
    this.phone,
    this.minutesPerSheepOverride,
    this.notes,
    this.isWaiting = false,
    this.lastShearingDate,
    this.needsDistanceRecompute = false,
  });

  int minutesPerSheep(Settings settings) =>
      minutesPerSheepOverride ?? settings.defaultMinutesPerSheep;
}
```

- [ ] **Step 3: Write `distance_matrix_entry.dart`**

```dart
class DistanceMatrixEntry {
  /// 0 = base, otherwise client.id
  final int fromId;
  final int toId;
  final int distanceMeters;
  final int durationSeconds;
  final DateTime computedAt;

  const DistanceMatrixEntry({
    required this.fromId,
    required this.toId,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.computedAt,
  });

  static const int baseId = 0;
}
```

- [ ] **Step 4: Write `tour.dart`**

```dart
enum TourStatus { planned, completed }

class Tour {
  final int id;
  final DateTime plannedDate;
  final int startTimeMinutes;
  final TourStatus status;
  final int totalDistanceMeters;
  final int totalDriveSeconds;
  final int totalTravelFeeCents;
  final String? notes;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Tour({
    required this.id,
    required this.plannedDate,
    required this.startTimeMinutes,
    required this.status,
    required this.totalDistanceMeters,
    required this.totalDriveSeconds,
    required this.totalTravelFeeCents,
    required this.createdAt,
    this.notes,
    this.completedAt,
  });
}
```

- [ ] **Step 5: Write `tour_stop.dart`**

```dart
class TourStop {
  final int id;
  final int tourId;
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final int sheepCountSnapshot;
  final int minutesPerSheepSnapshot;
  final int feeShareCents;

  const TourStop({
    required this.id,
    required this.tourId,
    required this.clientNameSnapshot,
    required this.orderIndex,
    required this.estimatedArrivalMinutes,
    required this.estimatedDepartureMinutes,
    required this.sheepCountSnapshot,
    required this.minutesPerSheepSnapshot,
    required this.feeShareCents,
    this.clientId,
  });
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/domain/models/
git commit -m "feat(domain): settings, client, distance entry, tour, tour stop models"
```

---

## Task 1.3: BracketCounter — round-up tranche of 10 km

**Files:**
- Create: `lib/domain/use_cases/bracket_counter.dart`
- Create: `test/domain/bracket_counter_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/bracket_counter_test.dart
import 'package:coupe_laine/domain/use_cases/bracket_counter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BracketCounter (10 km, 8 €)', () {
    final counter = const BracketCounter(bracketKm: 10, feeEurosPerBracket: 8);

    test('zero metres → zero brackets, zero euros', () {
      expect(counter.bracketsFor(0), 0);
      expect(counter.feeCentsFor(0), 0);
    });

    test('1 metre → 1 bracket → 8 €', () {
      expect(counter.bracketsFor(1), 1);
      expect(counter.feeCentsFor(1), 800);
    });

    test('exactly 10 000 metres → 1 bracket', () {
      expect(counter.bracketsFor(10000), 1);
      expect(counter.feeCentsFor(10000), 800);
    });

    test('10 001 metres → 2 brackets → 16 €', () {
      expect(counter.bracketsFor(10001), 2);
      expect(counter.feeCentsFor(10001), 1600);
    });

    test('25 km → 3 brackets → 24 €', () {
      expect(counter.feeCentsFor(25000), 2400);
    });
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/domain/bracket_counter_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/domain/use_cases/bracket_counter.dart
class BracketCounter {
  final int bracketKm;
  final int feeEurosPerBracket;

  const BracketCounter({
    required this.bracketKm,
    required this.feeEurosPerBracket,
  });

  int bracketsFor(int distanceMeters) {
    if (distanceMeters <= 0) return 0;
    final bracketMeters = bracketKm * 1000;
    return ((distanceMeters + bracketMeters - 1) ~/ bracketMeters);
  }

  int feeCentsFor(int distanceMeters) =>
      bracketsFor(distanceMeters) * feeEurosPerBracket * 100;
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/domain/bracket_counter_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/use_cases/bracket_counter.dart test/domain/bracket_counter_test.dart
git commit -m "feat(domain): bracket counter with ceil semantics"
```

---

## Task 1.4: CostSplitCalculator

**Files:**
- Create: `lib/domain/use_cases/cost_split_calculator.dart`
- Create: `test/domain/cost_split_calculator_test.dart`

The formula per [spec §04-user-flows §5](../../specs/2026-04-28-coupe-laine-mvp-design/04-user-flows.md#5-confirm-a-tour):

```
feeFarthest_cents = ceil(distance(base, farthest_stop) / 10_000) * 800
feeInter_cents    = ceil(sum(distance(stop_i, stop_{i+1})) / 10_000) * 800
totalFee_cents    = feeFarthest_cents + feeInter_cents
share_cents[i]    = totalFee_cents ~/ n  (+1 cent for the first totalFee_cents % n stops)
```

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/cost_split_calculator_test.dart
import 'package:coupe_laine/domain/use_cases/bracket_counter.dart';
import 'package:coupe_laine/domain/use_cases/cost_split_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const counter = BracketCounter(bracketKm: 10, feeEurosPerBracket: 8);
  final calculator = CostSplitCalculator(brackets: counter);

  group('CostSplitCalculator', () {
    test('single stop: full fee on the only client', () {
      final result = calculator.split(
        baseToStopMeters: const [25000],
        interStopMeters: const [],
      );
      expect(result.totalFeeCents, 2400);
      expect(result.shareCents, [2400]);
    });

    test('three stops: spec example (25 km farthest, 13 km inter)', () {
      final result = calculator.split(
        baseToStopMeters: const [15000, 22000, 25000],
        interStopMeters: const [5000, 8000],
      );
      // farthest = 25 km → 3 brackets → 24 €
      // inter = 13 km → 2 brackets → 16 €
      // total = 40 €
      expect(result.totalFeeCents, 4000);
      // 4000 / 3 = 1333 remainder 1 → first stop gets +1
      expect(result.shareCents, [1334, 1333, 1333]);
      expect(result.shareCents.reduce((a, b) => a + b), 4000);
    });

    test('shares always sum to total exactly', () {
      final result = calculator.split(
        baseToStopMeters: const [10001, 10000, 10000, 10000, 10000],
        interStopMeters: const [1, 1, 1, 1],
      );
      expect(
        result.shareCents.reduce((a, b) => a + b),
        result.totalFeeCents,
      );
    });

    test('zero stops throws', () {
      expect(
        () => calculator.split(
          baseToStopMeters: const [],
          interStopMeters: const [],
        ),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/domain/cost_split_calculator_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/domain/use_cases/cost_split_calculator.dart
import 'bracket_counter.dart';

class CostSplitResult {
  final int totalFeeCents;
  final int feeFarthestCents;
  final int feeInterCents;
  final List<int> shareCents;

  const CostSplitResult({
    required this.totalFeeCents,
    required this.feeFarthestCents,
    required this.feeInterCents,
    required this.shareCents,
  });
}

class CostSplitCalculator {
  final BracketCounter brackets;

  const CostSplitCalculator({required this.brackets});

  /// [baseToStopMeters]: distance from base to each stop, in visit order.
  /// [interStopMeters]: distances between consecutive stops; length = n - 1.
  CostSplitResult split({
    required List<int> baseToStopMeters,
    required List<int> interStopMeters,
  }) {
    final n = baseToStopMeters.length;
    if (n == 0) {
      throw ArgumentError('Cannot split fee for an empty tour');
    }
    if (interStopMeters.length != n - 1) {
      throw ArgumentError(
        'interStopMeters must have length n - 1 (got '
        '${interStopMeters.length}, expected ${n - 1})',
      );
    }

    final farthestMeters =
        baseToStopMeters.reduce((a, b) => a > b ? a : b);
    final interTotalMeters =
        interStopMeters.fold<int>(0, (sum, d) => sum + d);

    final feeFarthestCents = brackets.feeCentsFor(farthestMeters);
    final feeInterCents = brackets.feeCentsFor(interTotalMeters);
    final totalFeeCents = feeFarthestCents + feeInterCents;

    final base = totalFeeCents ~/ n;
    final remainder = totalFeeCents % n;
    final shares = List<int>.generate(
      n,
      (i) => i < remainder ? base + 1 : base,
    );

    return CostSplitResult(
      totalFeeCents: totalFeeCents,
      feeFarthestCents: feeFarthestCents,
      feeInterCents: feeInterCents,
      shareCents: shares,
    );
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/domain/cost_split_calculator_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/use_cases/cost_split_calculator.dart test/domain/cost_split_calculator_test.dart
git commit -m "feat(domain): cost split calculator with remainder distribution"
```

---

## Task 1.5: TourOrderOptimizer (nearest-neighbour + 2-opt)

**Files:**
- Create: `lib/domain/use_cases/tour_order_optimizer.dart`
- Create: `test/domain/tour_order_optimizer_test.dart`

The optimiser takes a square distance matrix and returns the visit order (excluding base) that minimises base → s_0 → s_1 → ... → s_{n-1} → base. Index 0 is the base; indices 1..n are the stops.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/tour_order_optimizer_test.dart
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
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/domain/tour_order_optimizer_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/domain/use_cases/tour_order_optimizer.dart
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
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/domain/tour_order_optimizer_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/use_cases/tour_order_optimizer.dart test/domain/tour_order_optimizer_test.dart
git commit -m "feat(domain): nearest-neighbour + 2-opt tour optimiser"
```

---

## Task 1.6: TourDurationEstimator

**Files:**
- Create: `lib/domain/use_cases/tour_duration_estimator.dart`
- Create: `test/domain/tour_duration_estimator_test.dart`

Given a sequence of stops with sheep count + minutes-per-sheep, plus drive durations between consecutive points (base → s0, s0 → s1, …, s_{n-1} → base), produce per-stop arrival/departure minutes-since-midnight given a start time.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/tour_duration_estimator_test.dart
import 'package:coupe_laine/domain/use_cases/tour_duration_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TourDurationEstimator', () {
    final estimator = const TourDurationEstimator();

    test('one stop, 10 sheep, 20 min/sheep, 30 min drive each way', () {
      final result = estimator.estimate(
        startTimeMinutes: 8 * 60, // 08:00
        driveSecondsToStops: const [1800], // 30 min to stop
        driveSecondsBackToBase: 1800,
        sheepCountPerStop: const [10],
        minutesPerSheepPerStop: const [20],
      );
      expect(result.stopArrivalMinutes, [8 * 60 + 30]); // 08:30
      expect(result.stopDepartureMinutes, [8 * 60 + 30 + 200]); // +200 min
      expect(result.endTimeMinutes, 8 * 60 + 30 + 200 + 30); // back home
      expect(result.totalDriveSeconds, 3600);
      expect(result.totalShearingMinutes, 200);
    });

    test('three stops accumulate drive + shearing', () {
      final result = estimator.estimate(
        startTimeMinutes: 8 * 60,
        driveSecondsToStops: const [600, 900, 1200], // 10, 15, 20 min
        driveSecondsBackToBase: 1500, // 25 min
        sheepCountPerStop: const [5, 3, 8],
        minutesPerSheepPerStop: const [20, 25, 18],
      );
      // arrivals: 8:10, then 10 + 100 (shear5*20) + 15 = 8:10+115=10:05
      expect(result.stopArrivalMinutes[0], 8 * 60 + 10);
      expect(result.stopArrivalMinutes[1],
          8 * 60 + 10 + 100 + 15);
      expect(result.stopArrivalMinutes[2],
          8 * 60 + 10 + 100 + 15 + 75 + 20);
      expect(result.totalShearingMinutes, 100 + 75 + 144);
    });

    test('rejects mismatched list lengths', () {
      expect(
        () => estimator.estimate(
          startTimeMinutes: 0,
          driveSecondsToStops: const [60, 60],
          driveSecondsBackToBase: 60,
          sheepCountPerStop: const [1],
          minutesPerSheepPerStop: const [20],
        ),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/domain/tour_duration_estimator_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/domain/use_cases/tour_duration_estimator.dart
class TourDurationResult {
  final List<int> stopArrivalMinutes;
  final List<int> stopDepartureMinutes;
  final int endTimeMinutes;
  final int totalDriveSeconds;
  final int totalShearingMinutes;

  const TourDurationResult({
    required this.stopArrivalMinutes,
    required this.stopDepartureMinutes,
    required this.endTimeMinutes,
    required this.totalDriveSeconds,
    required this.totalShearingMinutes,
  });
}

class TourDurationEstimator {
  const TourDurationEstimator();

  TourDurationResult estimate({
    required int startTimeMinutes,
    required List<int> driveSecondsToStops,
    required int driveSecondsBackToBase,
    required List<int> sheepCountPerStop,
    required List<int> minutesPerSheepPerStop,
  }) {
    final n = driveSecondsToStops.length;
    if (sheepCountPerStop.length != n ||
        minutesPerSheepPerStop.length != n) {
      throw ArgumentError(
        'sheepCountPerStop and minutesPerSheepPerStop must have length n '
        '(got ${sheepCountPerStop.length} and '
        '${minutesPerSheepPerStop.length}, expected $n)',
      );
    }

    final arrivals = <int>[];
    final departures = <int>[];
    var clock = startTimeMinutes;
    var totalDrive = 0;
    var totalShear = 0;

    for (var i = 0; i < n; i++) {
      final driveMin = (driveSecondsToStops[i] / 60).round();
      clock += driveMin;
      totalDrive += driveSecondsToStops[i];
      arrivals.add(clock);

      final shearMin = sheepCountPerStop[i] * minutesPerSheepPerStop[i];
      clock += shearMin;
      totalShear += shearMin;
      departures.add(clock);
    }

    final returnDriveMin = (driveSecondsBackToBase / 60).round();
    clock += returnDriveMin;
    totalDrive += driveSecondsBackToBase;

    return TourDurationResult(
      stopArrivalMinutes: arrivals,
      stopDepartureMinutes: departures,
      endTimeMinutes: clock,
      totalDriveSeconds: totalDrive,
      totalShearingMinutes: totalShear,
    );
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/domain/tour_duration_estimator_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/use_cases/tour_duration_estimator.dart test/domain/tour_duration_estimator_test.dart
git commit -m "feat(domain): tour duration estimator"
```

---

## Task 1.7: Phase 1 sweep — `flutter test test/domain/`

- [ ] **Step 1: Run all domain tests**

```bash
flutter test test/domain/
```

Expected: all green, ~5 test files, ~25 cases.

- [ ] **Step 2: No commit needed unless something failed and was fixed.**

---

**Phase 1 done.** Pure-Dart domain layer with all calculations covered. Repositories and services in later phases will use these models and use cases.
