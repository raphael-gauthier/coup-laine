# Manual & Optimized Tours Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two new tour-creation entry points on the Tours tab: a fully manual multi-pick (F1) and a "by-commune" optimized proposal (F2). Both reuse the existing `TourDraftScreen` and bypass the pivot/proximity flow.

**Architecture:** A FAB on `ToursListScreen` opens a bottom sheet with two choices that route to dedicated config screens. A new shared widget `WaitingClientsMultiPicker` (list+map, no pivot) drives both the F1 selection and a new "Modifier la sélection" sheet on `TourDraftScreen`. F2 uses a greedy-by-barycentre algorithm in a pure use case `BuildOptimizedTourProposal`. `TourDraftInput.pivotId` becomes nullable so the existing draft pipeline works without a pivot.

**Tech Stack:** Flutter / Dart, Drift (sqlite), Riverpod, ForUI, flutter_map, go_router.

**Spec:** `docs/superpowers/specs/2026-04-29-manual-and-optimized-tours-design.md`.

---

## File Structure

**New files:**
- `lib/domain/use_cases/find_communes_with_waiting.dart` — pure aggregator: `(List<Client>, Map<int, ClientStatus>) → List<({String name, int count})>` sorted alphabetically.
- `lib/domain/use_cases/build_optimized_tour_proposal.dart` — greedy-by-barycentre algorithm. Pure, no I/O.
- `lib/presentation/widgets/waiting_clients_multi_picker.dart` — reusable list+map picker with internal selection state.
- `lib/presentation/tours/tour_manual_picker_screen.dart` — F1 entry screen.
- `lib/presentation/tours/tour_optimized_config_screen.dart` — F2 entry screen.

**Modified files:**
- `lib/state/tour_draft_controller.dart` — `TourDraftInput.pivotId` becomes `int?`; provider conditionally prepends pivot.
- `lib/presentation/tours/tour_draft_screen.dart` — `pivotId` constructor arg becomes `int?`; add "Modifier la sélection" button that opens the picker in a sheet.
- `lib/core/routing/app_router.dart` — `/tours/draft` `pivot` query param becomes optional; add `/tours/new/manual` and `/tours/new/optimized` routes.
- `lib/presentation/tours/tours_list_screen.dart` — add a FAB that opens a bottom sheet with two choices.
- `lib/l10n/app_fr.arb` — add new strings.
- `lib/l10n/app_en.arb` — add new strings.

**New test files:**
- `test/domain/find_communes_with_waiting_test.dart`
- `test/domain/build_optimized_tour_proposal_test.dart`

---

## Task 1: Make `TourDraftInput.pivotId` nullable

**Files:**
- Modify: `lib/state/tour_draft_controller.dart`

- [ ] **Step 1: Update `TourDraftInput` to accept null pivot**

Edit `lib/state/tour_draft_controller.dart`. Change the class so `pivotId` is `int?` and is no longer `required`:

```dart
class TourDraftInput {
  final int? pivotId;
  final List<int> selectedIds;
  final DateTime plannedDate;
  final int startTimeMinutes;
  final List<int>? overrideOrder;
  const TourDraftInput({
    this.pivotId,
    required this.selectedIds,
    required this.plannedDate,
    required this.startTimeMinutes,
    this.overrideOrder,
  });
}
```

- [ ] **Step 2: Update the provider to handle null pivot**

In the same file, replace the line that prepends the pivot:

```dart
final ids = [input.pivotId, ...input.selectedIds.where((id) => id != input.pivotId)];
```

with:

```dart
final ids = input.pivotId == null
    ? [...input.selectedIds]
    : [input.pivotId!, ...input.selectedIds.where((id) => id != input.pivotId)];
```

Leave `final nodeIds = [0, ...ids];` and the rest of the function untouched.

- [ ] **Step 3: Run analyzer to make sure we did not break callers**

Run: `flutter analyze lib/state/tour_draft_controller.dart lib/presentation/proximity/proximity_screen.dart lib/presentation/tours/tour_draft_screen.dart`

Expected: clean (the existing call sites pass a non-null `pivotId`, which is still valid).

- [ ] **Step 4: Commit**

```bash
git add lib/state/tour_draft_controller.dart
git commit -m "refactor(tour-draft): make TourDraftInput.pivotId nullable"
```

---

## Task 2: Make `TourDraftScreen` accept a null pivot

**Files:**
- Modify: `lib/presentation/tours/tour_draft_screen.dart`
- Modify: `lib/core/routing/app_router.dart`

- [ ] **Step 1: Update `TourDraftScreen` constructor**

Edit `lib/presentation/tours/tour_draft_screen.dart`. Change `pivotId` to nullable:

```dart
class TourDraftScreen extends ConsumerStatefulWidget {
  final int? pivotId;
  const TourDraftScreen({super.key, this.pivotId});

  @override
  ConsumerState<TourDraftScreen> createState() => _TourDraftScreenState();
}
```

- [ ] **Step 2: Update `_refresh` to pass null pivot through**

In the same file, find `_refresh()` and change the `TourDraftInput(...)` construction so `pivotId` is forwarded as-is (it's already a field on the widget, just keep `pivotId: widget.pivotId`):

```dart
void _refresh() {
  final selection = ref.read(tourSelectionProvider);
  ref.read(tourDraftInputProvider.notifier).state = TourDraftInput(
    pivotId: widget.pivotId,
    selectedIds: selection.toList(),
    plannedDate: _date,
    startTimeMinutes: _startMinutes,
    overrideOrder: _manualOrder,
  );
}
```

(No structural change — only ensures the new nullable type compiles fine here.)

- [ ] **Step 3: Update the `/tours/draft` route to accept optional `pivot` query param**

Edit `lib/core/routing/app_router.dart`. Find:

```dart
GoRoute(
  path: '/tours/draft',
  builder: (_, state) => TourDraftScreen(
    pivotId: int.parse(state.uri.queryParameters['pivot']!),
  ),
),
```

Replace with:

```dart
GoRoute(
  path: '/tours/draft',
  builder: (_, state) {
    final raw = state.uri.queryParameters['pivot'];
    return TourDraftScreen(
      pivotId: raw == null ? null : int.parse(raw),
    );
  },
),
```

- [ ] **Step 4: Verify analyzer is clean**

Run: `flutter analyze lib/core/routing/app_router.dart lib/presentation/tours/tour_draft_screen.dart`

Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add lib/core/routing/app_router.dart lib/presentation/tours/tour_draft_screen.dart
git commit -m "refactor(tour-draft): accept null pivot from route"
```

---

## Task 3: `FindCommunesWithWaiting` use case

**Files:**
- Create: `lib/domain/use_cases/find_communes_with_waiting.dart`
- Create: `test/domain/find_communes_with_waiting_test.dart`

- [ ] **Step 1: Write the failing tests first**

Create `test/domain/find_communes_with_waiting_test.dart`:

```dart
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/use_cases/client_status.dart';
import 'package:coup_laine/domain/use_cases/find_communes_with_waiting.dart';
import 'package:flutter_test/flutter_test.dart';

Client _c(int id, String city, {bool needsRecompute = false}) => Client(
      id: id,
      name: 'C$id',
      addressLabel: 'a',
      postcode: '00000',
      city: city,
      coordinates: const Coordinates(lat: 48, lon: -3),
      sheepCountSmall: 5,
      sheepCountLarge: 0,
      isWaiting: true,
      needsDistanceRecompute: needsRecompute,
    );

void main() {
  test('groups waiting clients by city and sorts alphabetically', () {
    final clients = [
      _c(1, 'Quimper'),
      _c(2, 'Carhaix'),
      _c(3, 'Quimper'),
      _c(4, 'Brest'),
    ];
    final statuses = {
      1: ClientStatus.waiting,
      2: ClientStatus.waiting,
      3: ClientStatus.waiting,
      4: ClientStatus.waiting,
    };
    final result = const FindCommunesWithWaiting().call(
      clients: clients,
      statusByClientId: statuses,
    );
    expect(result.map((e) => e.name), ['Brest', 'Carhaix', 'Quimper']);
    expect(result.map((e) => e.count), [1, 1, 2]);
  });

  test('excludes non-waiting clients', () {
    final clients = [_c(1, 'Quimper'), _c(2, 'Quimper')];
    final statuses = {
      1: ClientStatus.waiting,
      2: ClientStatus.scheduled,
    };
    final result = const FindCommunesWithWaiting().call(
      clients: clients,
      statusByClientId: statuses,
    );
    expect(result, [(name: 'Quimper', count: 1)]);
  });

  test('excludes clients with needsDistanceRecompute', () {
    final clients = [
      _c(1, 'Quimper'),
      _c(2, 'Quimper', needsRecompute: true),
    ];
    final statuses = {
      1: ClientStatus.waiting,
      2: ClientStatus.waiting,
    };
    final result = const FindCommunesWithWaiting().call(
      clients: clients,
      statusByClientId: statuses,
    );
    expect(result, [(name: 'Quimper', count: 1)]);
  });

  test('omits communes whose only client was filtered out', () {
    final clients = [_c(1, 'Carhaix', needsRecompute: true)];
    final statuses = {1: ClientStatus.waiting};
    final result = const FindCommunesWithWaiting().call(
      clients: clients,
      statusByClientId: statuses,
    );
    expect(result, isEmpty);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/domain/find_communes_with_waiting_test.dart`

Expected: compile error / "use_cases/find_communes_with_waiting.dart" not found.

- [ ] **Step 3: Write the implementation**

Create `lib/domain/use_cases/find_communes_with_waiting.dart`:

```dart
import '../models/client.dart';
import 'client_status.dart';

typedef CommuneWithWaiting = ({String name, int count});

class FindCommunesWithWaiting {
  const FindCommunesWithWaiting();

  List<CommuneWithWaiting> call({
    required List<Client> clients,
    required Map<int, ClientStatus> statusByClientId,
  }) {
    final counts = <String, int>{};
    for (final c in clients) {
      if (c.needsDistanceRecompute) continue;
      if (statusByClientId[c.id] != ClientStatus.waiting) continue;
      counts[c.city] = (counts[c.city] ?? 0) + 1;
    }
    final entries = counts.entries
        .map((e) => (name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return entries;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/domain/find_communes_with_waiting_test.dart`

Expected: all 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/use_cases/find_communes_with_waiting.dart test/domain/find_communes_with_waiting_test.dart
git commit -m "feat(domain): add FindCommunesWithWaiting use case"
```

---

## Task 4: `BuildOptimizedTourProposal` use case — basics

This task lays down the pure use case + the simple "seed only fits" path. Extension and contraction come in Tasks 5–6.

**Files:**
- Create: `lib/domain/use_cases/build_optimized_tour_proposal.dart`
- Create: `test/domain/build_optimized_tour_proposal_test.dart`

- [ ] **Step 1: Write the failing test for "seed alone fits target"**

Create `test/domain/build_optimized_tour_proposal_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/build_optimized_tour_proposal_test.dart`

Expected: compile error / file not found.

- [ ] **Step 3: Write the use case skeleton + "seed only" path**

Create `lib/domain/use_cases/build_optimized_tour_proposal.dart`:

```dart
import 'dart:math' as math;

import '../models/client.dart';
import '../models/coordinates.dart';
import '../models/distance_matrix_entry.dart';
import '../models/settings.dart';
import 'build_tour_draft.dart';

class OptimizedProposal {
  final List<int> selectedClientIds; // already in optimal order
  final int estimatedDurationMinutes;
  final bool isUnderTarget;
  final bool isOverTarget;

  const OptimizedProposal({
    required this.selectedClientIds,
    required this.estimatedDurationMinutes,
    required this.isUnderTarget,
    required this.isOverTarget,
  });

  factory OptimizedProposal.empty() => const OptimizedProposal(
        selectedClientIds: [],
        estimatedDurationMinutes: 0,
        isUnderTarget: false,
        isOverTarget: false,
      );
}

class BuildOptimizedTourProposal {
  static const int toleranceMinutes = 30;

  const BuildOptimizedTourProposal();

  OptimizedProposal call({
    required String communeName,
    required int targetMinutes,
    required int startTimeMinutes,
    required List<Client> waitingClients,
    required List<DistanceMatrixEntry> matrix,
    required Settings settings,
  }) {
    final eligible = waitingClients
        .where((c) => !c.needsDistanceRecompute)
        .toList();
    final byId = {for (final c in eligible) c.id: c};
    final seedIds = eligible
        .where((c) => c.city == communeName)
        .map((c) => c.id)
        .toList();
    if (seedIds.isEmpty) return OptimizedProposal.empty();

    var current = List<int>.from(seedIds);
    var draft = _buildDraft(
      candidateIds: current,
      candidates: eligible,
      matrix: matrix,
      settings: settings,
      startTimeMinutes: startTimeMinutes,
    );
    var duration = draft.endTimeMinutes - startTimeMinutes;

    // Compute barycentre of the seed for distance tie-breaking.
    final bary = _barycentre([for (final id in seedIds) byId[id]!.coordinates]);

    if (duration < targetMinutes - toleranceMinutes) {
      // EXTENSION
      final extras = eligible
          .where((c) => c.city != communeName && !seedIds.contains(c.id))
          .toList()
        ..sort((a, b) => _distSq(a.coordinates, bary)
            .compareTo(_distSq(b.coordinates, bary)));
      for (final cand in extras) {
        final next = [...current, cand.id];
        final nextDraft = _buildDraft(
          candidateIds: next,
          candidates: eligible,
          matrix: matrix,
          settings: settings,
          startTimeMinutes: startTimeMinutes,
        );
        final nextDuration = nextDraft.endTimeMinutes - startTimeMinutes;
        if (nextDuration > targetMinutes + toleranceMinutes) break;
        current = nextDraft.orderedClientIds;
        draft = nextDraft;
        duration = nextDuration;
      }
    } else if (duration > targetMinutes + toleranceMinutes) {
      // CONTRACTION
      while (current.length > 1 &&
          duration > targetMinutes + toleranceMinutes) {
        // Remove the candidate farthest from the barycentre.
        var farthestId = current.first;
        var farthestDistSq = -1.0;
        for (final id in current) {
          final d = _distSq(byId[id]!.coordinates, bary);
          if (d > farthestDistSq) {
            farthestDistSq = d;
            farthestId = id;
          }
        }
        final next = current.where((id) => id != farthestId).toList();
        final nextDraft = _buildDraft(
          candidateIds: next,
          candidates: eligible,
          matrix: matrix,
          settings: settings,
          startTimeMinutes: startTimeMinutes,
        );
        current = nextDraft.orderedClientIds;
        draft = nextDraft;
        duration = nextDraft.endTimeMinutes - startTimeMinutes;
      }
    }

    return OptimizedProposal(
      selectedClientIds: current,
      estimatedDurationMinutes: duration,
      isUnderTarget: duration < targetMinutes - toleranceMinutes,
      isOverTarget: duration > targetMinutes + toleranceMinutes,
    );
  }

  TourDraftResult _buildDraft({
    required List<int> candidateIds,
    required List<Client> candidates,
    required List<DistanceMatrixEntry> matrix,
    required Settings settings,
    required int startTimeMinutes,
  }) {
    return const BuildTourDraft().build(
      candidateIds: candidateIds,
      candidates: candidates,
      matrix: matrix,
      settings: settings,
      startTimeMinutes: startTimeMinutes,
    );
  }

  Coordinates _barycentre(List<Coordinates> points) {
    var lat = 0.0;
    var lon = 0.0;
    for (final p in points) {
      lat += p.lat;
      lon += p.lon;
    }
    final n = points.length;
    return Coordinates(lat: lat / n, lon: lon / n);
  }

  double _distSq(Coordinates a, Coordinates b) {
    final dLat = a.lat - b.lat;
    final dLon = a.lon - b.lon;
    return dLat * dLat + dLon * dLon;
  }
}

// Suppress unused-import warning if math is not used elsewhere; kept for
// possible future haversine swap.
// ignore: unused_element
double _unused() => math.pi;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/build_optimized_tour_proposal_test.dart`

Expected: 1 test passes.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/use_cases/build_optimized_tour_proposal.dart test/domain/build_optimized_tour_proposal_test.dart
git commit -m "feat(domain): scaffold BuildOptimizedTourProposal use case"
```

---

## Task 5: `BuildOptimizedTourProposal` — extension branch tests

The implementation already includes the extension branch from Task 4. This task adds the targeted tests and verifies behaviour.

**Files:**
- Modify: `test/domain/build_optimized_tour_proposal_test.dart`

- [ ] **Step 1: Add extension test cases**

Append the following tests inside the existing `void main() { ... }` block:

```dart
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
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/domain/build_optimized_tour_proposal_test.dart`

Expected: all 4 tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/domain/build_optimized_tour_proposal_test.dart
git commit -m "test(domain): cover extension branch of BuildOptimizedTourProposal"
```

---

## Task 6: `BuildOptimizedTourProposal` — contraction & edge case tests

**Files:**
- Modify: `test/domain/build_optimized_tour_proposal_test.dart`

- [ ] **Step 1: Add contraction & edge tests**

Append inside `void main() { ... }`:

```dart
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
        sheepCountSmall: 5,
        sheepCountLarge: 0,
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
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/domain/build_optimized_tour_proposal_test.dart`

Expected: all 8 tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/domain/build_optimized_tour_proposal_test.dart
git commit -m "test(domain): cover contraction & edge cases of BuildOptimizedTourProposal"
```

---

## Task 7: Add localization strings

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add the FR strings**

Add the following keys at the end of the JSON object in `lib/l10n/app_fr.arb` (before the closing `}`). Maintain the trailing-comma JSON-without-trailing-comma style — add the comma to the previous entry if needed:

```json
  "newTourFabLabel": "Nouvelle tournée",
  "newTourSheetTitle": "Type de tournée",
  "newTourSheetManual": "Manuelle",
  "newTourSheetManualSubtitle": "Choisir librement les clients",
  "newTourSheetOptimized": "Optimisée par commune",
  "newTourSheetOptimizedSubtitle": "Proposer une tournée centrée sur une commune",
  "manualPickerTitle": "Nouvelle tournée",
  "manualPickerEmptyTitle": "Aucun client en attente",
  "manualPickerEmptyBody": "Marquez un client en attente depuis sa fiche pour pouvoir l'inclure dans une tournée.",
  "manualPickerContinue": "Continuer",
  "manualPickerSelectedFmt": "{n} sélectionné(s)",
  "@manualPickerSelectedFmt": {"placeholders": {"n": {"type": "int"}}},
  "manualPickerExcludedFmt": "{n} client(s) indisponible(s) — recalcul de distance en attente",
  "@manualPickerExcludedFmt": {"placeholders": {"n": {"type": "int"}}},
  "manualPickerTabList": "Liste",
  "manualPickerTabMap": "Carte",
  "manualPickerSearchHint": "Rechercher un client…",
  "optimizedConfigTitle": "Tournée optimisée",
  "optimizedConfigCommuneTitle": "Commune",
  "optimizedConfigCommuneHint": "Choisir une commune",
  "optimizedConfigCommuneOptionFmt": "{name} ({n})",
  "@optimizedConfigCommuneOptionFmt": {"placeholders": {"name": {"type": "String"}, "n": {"type": "int"}}},
  "optimizedConfigDurationTitle": "Durée cible",
  "optimizedConfigPropose": "Proposer une tournée",
  "optimizedConfigEmptyTitle": "Aucune commune disponible",
  "optimizedConfigEmptyBody": "Tous les clients en attente nécessitent un recalcul de distance. Lancez la synchronisation depuis les Paramètres.",
  "tourDraftEditSelection": "Modifier",
  "tourDraftEditSelectionSheetTitle": "Modifier la sélection",
  "tourDraftEditSelectionValidate": "Valider"
```

- [ ] **Step 2: Add the EN strings**

Add the same keys (no `@`-metadata duplication needed if already declared in FR — but `flutter gen-l10n` reads metadata from the template; check `l10n.yaml` for `template-arb-file`. To stay safe, mirror the metadata in EN too). In `lib/l10n/app_en.arb`:

```json
  "newTourFabLabel": "New tour",
  "newTourSheetTitle": "Tour type",
  "newTourSheetManual": "Manual",
  "newTourSheetManualSubtitle": "Pick clients freely",
  "newTourSheetOptimized": "Optimized by commune",
  "newTourSheetOptimizedSubtitle": "Propose a tour centred on a commune",
  "manualPickerTitle": "New tour",
  "manualPickerEmptyTitle": "No waiting client",
  "manualPickerEmptyBody": "Mark a client as waiting from their profile to include them in a tour.",
  "manualPickerContinue": "Continue",
  "manualPickerSelectedFmt": "{n} selected",
  "@manualPickerSelectedFmt": {"placeholders": {"n": {"type": "int"}}},
  "manualPickerExcludedFmt": "{n} unavailable — distance recomputation pending",
  "@manualPickerExcludedFmt": {"placeholders": {"n": {"type": "int"}}},
  "manualPickerTabList": "List",
  "manualPickerTabMap": "Map",
  "manualPickerSearchHint": "Search a client…",
  "optimizedConfigTitle": "Optimized tour",
  "optimizedConfigCommuneTitle": "Commune",
  "optimizedConfigCommuneHint": "Pick a commune",
  "optimizedConfigCommuneOptionFmt": "{name} ({n})",
  "@optimizedConfigCommuneOptionFmt": {"placeholders": {"name": {"type": "String"}, "n": {"type": "int"}}},
  "optimizedConfigDurationTitle": "Target duration",
  "optimizedConfigPropose": "Propose a tour",
  "optimizedConfigEmptyTitle": "No commune available",
  "optimizedConfigEmptyBody": "Every waiting client needs distance recomputation. Run sync from Settings.",
  "tourDraftEditSelection": "Edit",
  "tourDraftEditSelectionSheetTitle": "Edit selection",
  "tourDraftEditSelectionValidate": "Confirm"
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`

Expected: succeeds, regenerates `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_fr.dart`, `lib/l10n/app_localizations_en.dart`.

- [ ] **Step 4: Verify no analyzer regression**

Run: `flutter analyze lib/l10n`

Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n
git commit -m "i18n: add strings for manual + optimized tour features"
```

---

## Task 8: `WaitingClientsMultiPicker` widget

**Files:**
- Create: `lib/presentation/widgets/waiting_clients_multi_picker.dart`

This widget owns the list+map tabs and an internal `Set<int>` selection. It does NOT own a footer. Hosts mount their own CTA.

- [ ] **Step 1: Add a provider for the eligible waiting clients**

Edit `lib/state/providers.dart`. Append at the end of the file:

```dart
final waitingPickerCandidatesProvider = FutureProvider.autoDispose<
    ({List<Client> eligible, int excludedCount})>((ref) async {
  final clients = ref.watch(clientRepositoryProvider);
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final withStatus = await clients.listAllWithStatus(seasonStart);
  final waiting = [
    for (final r in withStatus)
      if (r.$2 == ClientStatus.waiting) r.$1,
  ];
  final eligible = waiting.where((c) => !c.needsDistanceRecompute).toList();
  return (
    eligible: eligible,
    excludedCount: waiting.length - eligible.length,
  );
});
```

Add the missing imports at the top of the file:

```dart
import '../domain/models/client.dart';
import '../domain/use_cases/client_status.dart';
```

- [ ] **Step 2: Create the widget**

Create `lib/presentation/widgets/waiting_clients_multi_picker.dart`:

```dart
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../../core/design_tokens.dart';
import '../../core/text_search.dart';
import '../../domain/models/client.dart';
import '../../state/providers.dart';
import 'app_empty_state.dart';

class WaitingClientsMultiPicker extends ConsumerStatefulWidget {
  final Set<int> initialSelection;
  final ValueChanged<Set<int>> onSelectionChanged;

  const WaitingClientsMultiPicker({
    super.key,
    required this.initialSelection,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<WaitingClientsMultiPicker> createState() =>
      _WaitingClientsMultiPickerState();
}

class _WaitingClientsMultiPickerState
    extends ConsumerState<WaitingClientsMultiPicker> {
  late Set<int> _selection;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selection = {...widget.initialSelection};
  }

  void _toggle(int id) {
    setState(() {
      if (!_selection.add(id)) _selection.remove(id);
    });
    widget.onSelectionChanged({..._selection});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(waitingPickerCandidatesProvider);
    return async.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) {
        if (data.eligible.isEmpty) {
          return AppEmptyState(
            illustrationAsset: 'assets/illustrations/empty-clients.svg',
            title: l.manualPickerEmptyTitle,
            body: l.manualPickerEmptyBody,
          );
        }
        return Column(
          children: [
            if (data.excludedCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
                child: FCard.raw(
                  child: Padding(
                    padding: AppSizes.cardPadding,
                    child: Text(
                      l.manualPickerExcludedFmt(data.excludedCount),
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: FTabs(
                expands: true,
                children: [
                  FTabEntry(
                    label: Text(l.manualPickerTabList),
                    child: _ListTab(
                      clients: data.eligible,
                      selection: _selection,
                      query: _query,
                      onQueryChanged: (q) => setState(() => _query = q),
                      onToggle: _toggle,
                    ),
                  ),
                  FTabEntry(
                    label: Text(l.manualPickerTabMap),
                    child: _MapTab(
                      clients: data.eligible,
                      selection: _selection,
                      onToggle: _toggle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ListTab extends StatelessWidget {
  final List<Client> clients;
  final Set<int> selection;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onToggle;
  const _ListTab({
    required this.clients,
    required this.selection,
    required this.query,
    required this.onQueryChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final filtered = query.trim().isEmpty
        ? clients
        : clients.where((c) =>
            matchesSearch(query, [c.name, c.city])).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: FTextField(
            hint: l.manualPickerSearchHint,
            onChange: onQueryChanged,
          ),
        ),
        Expanded(
          child: Material(
            type: MaterialType.transparency,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final c = filtered[i];
                final selected = selection.contains(c.id);
                return FTile(
                  prefix:
                      Icon(FIcons.mapPin, color: theme.colors.mutedForeground),
                  title: Text(c.name),
                  subtitle: Text(c.city),
                  suffix: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? theme.colors.primary : null,
                      border: selected
                          ? null
                          : Border.all(color: theme.colors.border, width: 2),
                    ),
                    child: selected
                        ? Icon(FIcons.check,
                            color: theme.colors.primaryForeground, size: 16)
                        : null,
                  ),
                  onPress: () => onToggle(c.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MapTab extends StatelessWidget {
  final List<Client> clients;
  final Set<int> selection;
  final ValueChanged<int> onToggle;
  const _MapTab({
    required this.clients,
    required this.selection,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    if (clients.isEmpty) {
      return const SizedBox.shrink();
    }
    final centre = clients.first;
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centre.coordinates.lat, centre.coordinates.lon),
        initialZoom: 9,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'fr.raphaelgauthier.couplaine',
        ),
        MarkerLayer(
          markers: [
            for (final c in clients)
              Marker(
                point: LatLng(c.coordinates.lat, c.coordinates.lon),
                width: 28,
                height: 28,
                child: GestureDetector(
                  onTap: () => onToggle(c.id),
                  child: Icon(
                    FIcons.mapPin,
                    color: selection.contains(c.id)
                        ? theme.colors.primary
                        : theme.colors.mutedForeground,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Verify analyzer is clean**

Run: `flutter analyze lib/presentation/widgets/waiting_clients_multi_picker.dart lib/state/providers.dart`

Expected: clean. If `text_search.dart` exposes a different helper than `matchesSearch`, open it and use the right symbol; the goal is a case-insensitive contains across name + city.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/waiting_clients_multi_picker.dart lib/state/providers.dart
git commit -m "feat(picker): add WaitingClientsMultiPicker widget"
```

---

## Task 9: F1 — `TourManualPickerScreen`

**Files:**
- Create: `lib/presentation/tours/tour_manual_picker_screen.dart`
- Modify: `lib/core/routing/app_router.dart`

- [ ] **Step 1: Create the screen**

Create `lib/presentation/tours/tour_manual_picker_screen.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../state/proximity_controller.dart';
import '../../state/tour_draft_controller.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/waiting_clients_multi_picker.dart';

class TourManualPickerScreen extends ConsumerStatefulWidget {
  const TourManualPickerScreen({super.key});

  @override
  ConsumerState<TourManualPickerScreen> createState() =>
      _TourManualPickerScreenState();
}

class _TourManualPickerScreenState
    extends ConsumerState<TourManualPickerScreen> {
  Set<int> _selection = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tourSelectionProvider.notifier).clear();
    });
  }

  void _continue() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    ref.read(tourDraftInputProvider.notifier).state = TourDraftInput(
      pivotId: null,
      selectedIds: _selection.toList(),
      plannedDate: tomorrow,
      startTimeMinutes: 8 * 60,
    );
    // Mirror selection so the legacy provider stays consistent if any UI
    // observes it.
    final notifier = ref.read(tourSelectionProvider.notifier);
    notifier.clear();
    for (final id in _selection) {
      notifier.toggle(id);
    }
    context.push('/tours/draft');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final footer = _selection.isEmpty
        ? null
        : Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colors.border)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Text(l.manualPickerSelectedFmt(_selection.length)),
                const Spacer(),
                AppPrimaryButton(
                  label: l.manualPickerContinue,
                  prefixIcon: FIcons.arrowRight,
                  onPress: _continue,
                ),
              ],
            ),
          );
    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(title: Text(l.manualPickerTitle)),
        footer: footer,
        child: WaitingClientsMultiPicker(
          initialSelection: _selection,
          onSelectionChanged: (s) => setState(() => _selection = s),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add the route**

Edit `lib/core/routing/app_router.dart`. Add after the existing `/tours/draft` route (still outside the `StatefulShellRoute`):

```dart
GoRoute(
  path: '/tours/new/manual',
  builder: (_, __) => const TourManualPickerScreen(),
),
```

Add the import:

```dart
import '../../presentation/tours/tour_manual_picker_screen.dart';
```

- [ ] **Step 3: Verify analyzer**

Run: `flutter analyze lib/presentation/tours/tour_manual_picker_screen.dart lib/core/routing/app_router.dart`

Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/tours/tour_manual_picker_screen.dart lib/core/routing/app_router.dart
git commit -m "feat(tours): add manual picker screen + route"
```

---

## Task 10: F2 — `TourOptimizedConfigScreen`

**Files:**
- Create: `lib/presentation/tours/tour_optimized_config_screen.dart`
- Modify: `lib/state/providers.dart` (new providers for the F2 inputs/outputs)
- Modify: `lib/core/routing/app_router.dart`

- [ ] **Step 1: Add providers for F2**

Edit `lib/state/providers.dart`. Append at the bottom:

```dart
final waitingCommunesProvider =
    FutureProvider.autoDispose<List<({String name, int count})>>(
        (ref) async {
  final clients = ref.watch(clientRepositoryProvider);
  final settings = await ref.watch(settingsRepositoryProvider).read();
  final seasonStart = settings?.seasonStartedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final withStatus = await clients.listAllWithStatus(seasonStart);
  final clientList = [for (final r in withStatus) r.$1];
  final statusByClientId = {
    for (final r in withStatus) r.$1.id: r.$2,
  };
  return const FindCommunesWithWaiting().call(
    clients: clientList,
    statusByClientId: statusByClientId,
  );
});

class OptimizedRequest {
  final String communeName;
  final int targetMinutes;
  const OptimizedRequest({
    required this.communeName,
    required this.targetMinutes,
  });
}

final optimizedProposalProvider = FutureProvider.autoDispose
    .family<OptimizedProposal, OptimizedRequest>((ref, req) async {
  final clientsRepo = ref.watch(clientRepositoryProvider);
  final matrixRepo = ref.watch(distanceMatrixRepositoryProvider);
  final settings = await ref.watch(settingsRepositoryProvider).read();
  if (settings == null) return OptimizedProposal.empty();
  final seasonStart = settings.seasonStartedAt;
  final withStatus = await clientsRepo.listAllWithStatus(seasonStart);
  final waiting = [
    for (final r in withStatus)
      if (r.$2 == ClientStatus.waiting) r.$1,
  ];
  // Pull the full pairwise matrix between base and every waiting client
  // (eligibility filtered inside the use case).
  final ids = [0, ...waiting.map((c) => c.id)];
  final entries = <DistanceMatrixEntry>[];
  for (final from in ids) {
    for (final to in ids) {
      if (from == to) continue;
      final m = await matrixRepo.distanceMeters(from: from, to: to);
      final s = await matrixRepo.durationSeconds(from: from, to: to);
      if (m == null || s == null) continue;
      entries.add(DistanceMatrixEntry(
        fromId: from,
        toId: to,
        distanceMeters: m,
        durationSeconds: s,
        computedAt: DateTime.now(),
      ));
    }
  }
  return const BuildOptimizedTourProposal().call(
    communeName: req.communeName,
    targetMinutes: req.targetMinutes,
    startTimeMinutes: 8 * 60,
    waitingClients: waiting,
    matrix: entries,
    settings: settings,
  );
});
```

Add the imports at the top of the file:

```dart
import '../domain/models/distance_matrix_entry.dart';
import '../domain/use_cases/build_optimized_tour_proposal.dart';
import '../domain/use_cases/find_communes_with_waiting.dart';
```

- [ ] **Step 2: Create the screen**

Create `lib/presentation/tours/tour_optimized_config_screen.dart`:

```dart
import 'package:flutter/material.dart' show Material, MaterialType, Slider;
import 'package:flutter/widgets.dart';
import 'package:coup_laine/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import '../../state/proximity_controller.dart';
import '../../state/providers.dart';
import '../../state/tour_draft_controller.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_section_card.dart';

class TourOptimizedConfigScreen extends ConsumerStatefulWidget {
  const TourOptimizedConfigScreen({super.key});

  @override
  ConsumerState<TourOptimizedConfigScreen> createState() =>
      _TourOptimizedConfigScreenState();
}

class _TourOptimizedConfigScreenState
    extends ConsumerState<TourOptimizedConfigScreen> {
  String? _commune;
  int _targetMinutes = 8 * 60;
  bool _proposing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tourSelectionProvider.notifier).clear();
    });
  }

  Future<void> _propose() async {
    if (_commune == null) return;
    setState(() => _proposing = true);
    try {
      final proposal = await ref.read(optimizedProposalProvider(
        OptimizedRequest(
            communeName: _commune!, targetMinutes: _targetMinutes),
      ).future);
      if (!mounted) return;
      if (proposal.selectedClientIds.isEmpty) {
        setState(() => _proposing = false);
        return;
      }
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      ref.read(tourDraftInputProvider.notifier).state = TourDraftInput(
        pivotId: null,
        selectedIds: proposal.selectedClientIds,
        plannedDate: tomorrow,
        startTimeMinutes: 8 * 60,
        overrideOrder: proposal.selectedClientIds, // already optimal
      );
      final notifier = ref.read(tourSelectionProvider.notifier);
      notifier.clear();
      for (final id in proposal.selectedClientIds) {
        notifier.toggle(id);
      }
      context.push('/tours/draft');
    } finally {
      if (mounted) setState(() => _proposing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final communesAsync = ref.watch(waitingCommunesProvider);
    return SafeArea(
      child: FScaffold(
        header: FHeader.nested(title: Text(l.optimizedConfigTitle)),
        footer: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.colors.border)),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: AppPrimaryButton(
            label: l.optimizedConfigPropose,
            onPress: (_commune == null || _proposing) ? null : _propose,
            prefixIcon: FIcons.route,
          ),
        ),
        child: communesAsync.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (communes) {
            if (communes.isEmpty) {
              return AppEmptyState(
                illustrationAsset: 'assets/illustrations/empty-clients.svg',
                title: l.optimizedConfigEmptyTitle,
                body: l.optimizedConfigEmptyBody,
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
              children: [
                AppSectionCard(
                  icon: FIcons.mapPin,
                  title: l.optimizedConfigCommuneTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final c in communes)
                        FTile(
                          title: Text(c.name),
                          details: Text(
                              l.optimizedConfigCommuneOptionFmt(c.name, c.count)),
                          suffix: _commune == c.name
                              ? Icon(FIcons.check,
                                  color: theme.colors.primary, size: 18)
                              : null,
                          onPress: () =>
                              setState(() => _commune = c.name),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppSectionCard(
                  icon: FIcons.clock,
                  title: l.optimizedConfigDurationTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(_targetMinutes / 60).toStringAsFixed(1)} h',
                        style: theme.typography.xl2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colors.foreground,
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: Slider(
                          min: 5 * 60,
                          max: 10 * 60,
                          divisions: 10, // 30 min steps
                          value: _targetMinutes.toDouble(),
                          label: '${(_targetMinutes / 60).toStringAsFixed(1)} h',
                          onChanged: (v) =>
                              setState(() => _targetMinutes = v.round()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add the route**

Edit `lib/core/routing/app_router.dart`. Add after the manual route:

```dart
GoRoute(
  path: '/tours/new/optimized',
  builder: (_, __) => const TourOptimizedConfigScreen(),
),
```

Add the import:

```dart
import '../../presentation/tours/tour_optimized_config_screen.dart';
```

- [ ] **Step 4: Verify analyzer**

Run: `flutter analyze lib/presentation/tours/tour_optimized_config_screen.dart lib/state/providers.dart lib/core/routing/app_router.dart`

Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/tours/tour_optimized_config_screen.dart lib/state/providers.dart lib/core/routing/app_router.dart
git commit -m "feat(tours): add optimized-by-commune config screen + route"
```

---

## Task 11: FAB on Tours list with bottom sheet

**Files:**
- Modify: `lib/presentation/tours/tours_list_screen.dart`

- [ ] **Step 1: Add the FAB and the bottom sheet**

Edit `lib/presentation/tours/tours_list_screen.dart`. In `ToursListScreen.build`, wrap the existing `FScaffold` so it carries a FAB. ForUI's `FScaffold` does not expose a Material `floatingActionButton` slot — we'll mount the FAB inside the body via a `Stack`. Replace the `FScaffold(child: SafeArea(...))` block with:

```dart
return FScaffold(
  child: SafeArea(
    top: true,
    bottom: false,
    child: Stack(
      children: [
        Material(
          type: MaterialType.transparency,
          child: async.when(
            // ... existing async.when body unchanged
          ),
        ),
        Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: _NewTourFab(),
        ),
      ],
    ),
  ),
);
```

(Keep the inner content of `async.when` exactly as it is today; only the wrapping changes.)

- [ ] **Step 2: Add the FAB widget at the bottom of the file**

At the end of `tours_list_screen.dart`, append:

```dart
class _NewTourFab extends StatelessWidget {
  const _NewTourFab();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    return GestureDetector(
      onTap: () => _open(context, l),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colors.foreground.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(FIcons.plus,
            color: theme.colors.primaryForeground, size: 28),
      ),
    );
  }

  Future<void> _open(BuildContext context, AppLocalizations l) async {
    await showFSheet<void>(
      context: context,
      side: FLayout.btt,
      builder: (sheetCtx) {
        final theme = sheetCtx.theme;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l.newTourSheetTitle,
                  style: theme.typography.lg
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              FTile(
                prefix: const Icon(FIcons.users),
                title: Text(l.newTourSheetManual),
                subtitle: Text(l.newTourSheetManualSubtitle),
                onPress: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/tours/new/manual');
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              FTile(
                prefix: const Icon(FIcons.route),
                title: Text(l.newTourSheetOptimized),
                subtitle: Text(l.newTourSheetOptimizedSubtitle),
                onPress: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/tours/new/optimized');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Verify analyzer**

Run: `flutter analyze lib/presentation/tours/tours_list_screen.dart`

Expected: clean. If `showFSheet` / `FLayout.btt` are not the exact ForUI API in this version, adjust to the project's existing sheet helper (search `showFDialog`/`showFSheet` usage in repo for the matching call style).

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/tours/tours_list_screen.dart
git commit -m "feat(tours): add FAB + bottom sheet to start new tours"
```

---

## Task 12: "Modifier la sélection" on draft screen

**Files:**
- Modify: `lib/presentation/tours/tour_draft_screen.dart`

- [ ] **Step 1: Add an "Edit" button next to the "Étapes" heading**

Edit `lib/presentation/tours/tour_draft_screen.dart`. Replace the `Padding` block that renders the `l.tourDraftStepsTitle` with a `Row` that also contains an outline button:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(
      AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxs),
  child: Row(
    children: [
      Expanded(
        child: Text(
          l.tourDraftStepsTitle,
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
      ),
      FButton(
        variant: FButtonVariant.outline,
        prefix: const Icon(FIcons.pencil, size: 16),
        onPress: () => _openEditSelection(context, bundle),
        child: Text(l.tourDraftEditSelection),
      ),
    ],
  ),
),
```

- [ ] **Step 2: Add the `_openEditSelection` method**

Inside `_TourDraftScreenState`, add (next to `_save`):

```dart
Future<void> _openEditSelection(
    BuildContext context, TourDraftBundle bundle) async {
  final l = AppLocalizations.of(context)!;
  final initial = bundle.orderedClients.map((c) => c.id).toSet();
  var working = {...initial};
  await showFSheet<void>(
    context: context,
    side: FLayout.btt,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (innerCtx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              height: MediaQuery.of(innerCtx).size.height * 0.85,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      l.tourDraftEditSelectionSheetTitle,
                      style: innerCtx.theme.typography.lg.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: WaitingClientsMultiPicker(
                      initialSelection: working,
                      onSelectionChanged: (s) =>
                          setSheetState(() => working = s),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppPrimaryButton(
                    label: l.tourDraftEditSelectionValidate,
                    onPress: working.isEmpty
                        ? null
                        : () {
                            Navigator.of(innerCtx).pop();
                            setState(() => _manualOrder = null);
                            ref.read(tourDraftInputProvider.notifier).state =
                                TourDraftInput(
                              pivotId: widget.pivotId,
                              selectedIds: working.toList(),
                              plannedDate: _date,
                              startTimeMinutes: _startMinutes,
                              overrideOrder: null,
                            );
                          },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
```

Add the missing import at the top:

```dart
import '../widgets/waiting_clients_multi_picker.dart';
```

- [ ] **Step 3: Verify analyzer**

Run: `flutter analyze lib/presentation/tours/tour_draft_screen.dart`

Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/tours/tour_draft_screen.dart
git commit -m "feat(tour-draft): add 'Modifier la sélection' sheet"
```

---

## Task 13: Run the full test suite & smoke test

**Files:** none (verification only).

- [ ] **Step 1: Run all unit + widget tests**

Run: `flutter test`

Expected: all green. The two new domain test files (`find_communes_with_waiting_test.dart`, `build_optimized_tour_proposal_test.dart`) plus the existing suite must pass with no regression.

- [ ] **Step 2: Run analyzer on the whole project**

Run: `flutter analyze`

Expected: clean (no new warnings or errors).

- [ ] **Step 3: Manual smoke (CLAUDE.md §4)**

Build/run the app on the connected device. Verify:

- Tap the FAB on the Tournées tab → bottom sheet shows "Manuelle" / "Optimisée par commune".
- "Manuelle" → picker shows waiting clients (list + map). Selecting at least one enables "Continuer" → arrive on the draft screen.
- "Optimisée par commune" → commune list with counts; pick one + slide duration → "Proposer" → arrives on the draft screen with a sensible selection.
- On the draft screen, "Modifier" opens the picker pre-cocked with the current stops; toggling and validating updates the draft (order recomputed).
- Existing pivot flow (`/clients/:id` → "Tournée à proximité" → ProximityScreen → draft) still works end-to-end.

- [ ] **Step 4: If smoke failed, fix the actual root cause**

Do not paper over symptoms; trace failures back to a misnamed key, missing route, or null-pivot regression. Re-run `flutter test` after each fix.

- [ ] **Step 5: Final commit if cleanup edits were made**

```bash
git status
# only commit if there are pending edits from step 4
```

---

## Self-review notes

Spec coverage check:

- §2 architecture (new + modified files): Tasks 1–12 cover every entry. ✅
- §3 F1: Task 9 (screen) + Task 11 (FAB entry) + Task 8 (picker) + Task 1 (null pivot). ✅
- §4 F2: Task 10 (config screen + provider) + Tasks 4–6 (algorithm) + Task 3 (commune use case) + Task 11 (FAB entry). ✅
- §5 Shared picker & draft editing: Task 8 + Task 12. ✅
- §6 Edge cases: needsDistanceRecompute filtered in `FindCommunesWithWaiting` (Task 3) + `BuildOptimizedTourProposal` (Task 4) + picker provider (Task 8). Empty-state screens covered in Tasks 8, 9, 10. ✅
- §7 Testing: Tasks 3, 5, 6 (domain tests). Widget tests are deliberately limited (CLAUDE.md §2 — YAGNI). Manual smoke in Task 13. ✅
