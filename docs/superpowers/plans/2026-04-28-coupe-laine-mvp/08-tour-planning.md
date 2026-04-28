# Phase 8 — Tour planning

**Goal:** Compose a draft tour from a pivot + selected clients, optimise order via the TSP solver, allow drag-and-drop, show estimated arrivals, compute fee split, and confirm/save the planned tour.

**Verification at end of phase:** Composing a draft from 3+ selected clients yields an optimised order, accurate totals, a fee split summing to the total, and saving creates a `tours` row + `tour_stops` rows in the database.

---

## Task 8.1: BuildTourDraft use case

Combines the matrix repository, the optimiser, the duration estimator, and the cost split calculator into one orchestrator. Pure business logic — testable in isolation.

**Files:**
- Create: `lib/domain/use_cases/build_tour_draft.dart`
- Create: `test/domain/build_tour_draft_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/build_tour_draft_test.dart
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
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/domain/build_tour_draft_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/domain/use_cases/build_tour_draft.dart
import '../models/client.dart';
import '../models/distance_matrix_entry.dart';
import '../models/settings.dart';
import 'bracket_counter.dart';
import 'cost_split_calculator.dart';
import 'tour_duration_estimator.dart';
import 'tour_order_optimizer.dart';

class TourDraftResult {
  final List<int> orderedClientIds;
  final List<int> arrivalMinutes;
  final List<int> departureMinutes;
  final int endTimeMinutes;
  final int totalDistanceMeters;
  final int totalDriveSeconds;
  final int totalShearingMinutes;
  final int totalFeeCents;
  final List<int> feeShareCents;
  final List<int> minutesPerSheepPerStop;
  final int feeFarthestCents;
  final int feeInterCents;

  const TourDraftResult({
    required this.orderedClientIds,
    required this.arrivalMinutes,
    required this.departureMinutes,
    required this.endTimeMinutes,
    required this.totalDistanceMeters,
    required this.totalDriveSeconds,
    required this.totalShearingMinutes,
    required this.totalFeeCents,
    required this.feeShareCents,
    required this.minutesPerSheepPerStop,
    required this.feeFarthestCents,
    required this.feeInterCents,
  });
}

class BuildTourDraft {
  const BuildTourDraft();

  TourDraftResult build({
    required List<int> candidateIds,
    required List<Client> candidates,
    required List<DistanceMatrixEntry> matrix,
    required Settings settings,
    required int startTimeMinutes,
    List<int>? presetOrder, // skip optimiser if provided
  }) {
    if (candidateIds.isEmpty) {
      throw ArgumentError('Cannot build a draft with zero candidates');
    }
    final byId = {for (final c in candidates) c.id: c};
    for (final id in candidateIds) {
      if (!byId.containsKey(id)) {
        throw ArgumentError('Missing client id=$id');
      }
    }

    final nodeIds = <int>[0, ...candidateIds];
    final n = nodeIds.length;
    final dm = List.generate(n, (_) => List<int>.filled(n, 0));
    final tm = List.generate(n, (_) => List<int>.filled(n, 0));
    final lookup = <int, int>{};
    for (final e in matrix) {
      lookup[e.fromId * 1000000 + e.toId] = e.distanceMeters;
    }
    final lookupT = <int, int>{};
    for (final e in matrix) {
      lookupT[e.fromId * 1000000 + e.toId] = e.durationSeconds;
    }
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        final key = nodeIds[i] * 1000000 + nodeIds[j];
        dm[i][j] = lookup[key] ??
            (throw StateError(
                'Missing matrix entry ${nodeIds[i]} -> ${nodeIds[j]}'));
        tm[i][j] = lookupT[key] ?? 0;
      }
    }

    final visitIndices = presetOrder != null
        ? presetOrder.map((id) => nodeIds.indexOf(id)).toList()
        : const TourOrderOptimizer().optimise(distanceMatrix: dm);
    final orderedIds = visitIndices.map((i) => nodeIds[i]).toList();

    final driveToStops =
        <int>[for (var k = 0; k < visitIndices.length; k++) tm[k == 0 ? 0 : visitIndices[k - 1]][visitIndices[k]]];
    final driveBack = tm[visitIndices.last][0];
    final sheepCounts = orderedIds.map((id) => byId[id]!.sheepCount).toList();
    final minPerSheep = orderedIds
        .map((id) => byId[id]!.minutesPerSheep(settings))
        .toList();

    final duration = const TourDurationEstimator().estimate(
      startTimeMinutes: startTimeMinutes,
      driveSecondsToStops: driveToStops,
      driveSecondsBackToBase: driveBack,
      sheepCountPerStop: sheepCounts,
      minutesPerSheepPerStop: minPerSheep,
    );

    final baseToStopMeters = <int>[
      for (final id in orderedIds) dm[0][nodeIds.indexOf(id)]
    ];
    final interStopMeters = <int>[
      for (var k = 0; k < orderedIds.length - 1; k++)
        dm[nodeIds.indexOf(orderedIds[k])]
            [nodeIds.indexOf(orderedIds[k + 1])]
    ];
    final returnMeters = dm[nodeIds.indexOf(orderedIds.last)][0];

    final brackets = BracketCounter(
      bracketKm: settings.bracketKm,
      feeEurosPerBracket: settings.travelFeeEurosPerBracket,
    );
    final split = CostSplitCalculator(brackets: brackets).split(
      baseToStopMeters: baseToStopMeters,
      interStopMeters: interStopMeters,
    );

    final totalDistance =
        baseToStopMeters.first + interStopMeters.fold<int>(0, (a, b) => a + b) + returnMeters;

    return TourDraftResult(
      orderedClientIds: orderedIds,
      arrivalMinutes: duration.stopArrivalMinutes,
      departureMinutes: duration.stopDepartureMinutes,
      endTimeMinutes: duration.endTimeMinutes,
      totalDistanceMeters: totalDistance,
      totalDriveSeconds: duration.totalDriveSeconds,
      totalShearingMinutes: duration.totalShearingMinutes,
      totalFeeCents: split.totalFeeCents,
      feeShareCents: split.shareCents,
      minutesPerSheepPerStop: minPerSheep,
      feeFarthestCents: split.feeFarthestCents,
      feeInterCents: split.feeInterCents,
    );
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/domain/build_tour_draft_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/use_cases/build_tour_draft.dart \
        test/domain/build_tour_draft_test.dart
git commit -m "feat(domain): build tour draft orchestrator"
```

---

## Task 8.2: Tour draft controller

**Files:**
- Create: `lib/state/tour_draft_controller.dart`

- [ ] **Step 1: Write the controller**

```dart
// lib/state/tour_draft_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/client.dart';
import '../domain/models/distance_matrix_entry.dart';
import '../domain/use_cases/build_tour_draft.dart';
import 'providers.dart';

class TourDraftInput {
  final int pivotId;
  final List<int> selectedIds;
  final DateTime plannedDate;
  final int startTimeMinutes;
  final List<int>? overrideOrder;
  const TourDraftInput({
    required this.pivotId,
    required this.selectedIds,
    required this.plannedDate,
    required this.startTimeMinutes,
    this.overrideOrder,
  });
}

final tourDraftInputProvider = StateProvider<TourDraftInput?>((_) => null);

class TourDraftBundle {
  final TourDraftResult result;
  final List<Client> orderedClients;
  const TourDraftBundle({required this.result, required this.orderedClients});
}

final tourDraftProvider =
    FutureProvider.autoDispose<TourDraftBundle?>((ref) async {
  final input = ref.watch(tourDraftInputProvider);
  if (input == null) return null;
  final clients = ref.watch(clientRepositoryProvider);
  final matrix = ref.watch(distanceMatrixRepositoryProvider);
  final settings = await ref.watch(settingsRepositoryProvider).read();
  if (settings == null) return null;

  final all = await clients.listAll();
  final ids = [input.pivotId, ...input.selectedIds.where((id) => id != input.pivotId)];

  // We need every matrix cell in the sub-matrix. Pull all rows from any of
  // these node ids. Including base (0) explicitly.
  final nodeIds = [0, ...ids];
  final entries = <DistanceMatrixEntry>[];
  for (final from in nodeIds) {
    for (final to in nodeIds) {
      if (from == to) continue;
      final m = await matrix.distanceMeters(from: from, to: to);
      final s = await matrix.durationSeconds(from: from, to: to);
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

  final result = const BuildTourDraft().build(
    candidateIds: ids,
    candidates: all,
    matrix: entries,
    settings: settings,
    startTimeMinutes: input.startTimeMinutes,
    presetOrder: input.overrideOrder,
  );
  final byId = {for (final c in all) c.id: c};
  final orderedClients =
      result.orderedClientIds.map((id) => byId[id]!).toList();
  return TourDraftBundle(result: result, orderedClients: orderedClients);
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/state/tour_draft_controller.dart
git commit -m "feat(state): tour draft controller wiring repositories to BuildTourDraft"
```

---

## Task 8.3: Tour draft screen

**Files:**
- Create: `lib/presentation/tours/tour_draft_screen.dart`
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/l10n/app_fr.arb` / `app_en.arb`

- [ ] **Step 1: Strings**

`app_fr.arb`:
```json
{
  "tourDraftTitle": "Composer la tournée",
  "tourDraftDate": "Date",
  "tourDraftStart": "Départ",
  "tourDraftOptimise": "Optimiser l'ordre",
  "tourDraftConfirm": "Enregistrer la tournée",
  "tourDraftStopArrivalFmt": "{time} → {dep}",
  "@tourDraftStopArrivalFmt": {"placeholders": {"time": {"type": "String"}, "dep": {"type": "String"}}},
  "tourDraftSummaryTotal": "Trajet : {km} km · {drive} · Tonte : {shear} · Fin : {end}",
  "@tourDraftSummaryTotal": {"placeholders": {"km": {"type": "String"}, "drive": {"type": "String"}, "shear": {"type": "String"}, "end": {"type": "String"}}},
  "tourDraftFeeSplitTitle": "Partage des frais",
  "tourDraftFeeShareFmt": "{name} — {amount}",
  "@tourDraftFeeShareFmt": {"placeholders": {"name": {"type": "String"}, "amount": {"type": "String"}}}
}
```

Mirror EN, regenerate.

- [ ] **Step 2: Helpers — minute formatting**

Create `lib/core/format_minutes.dart`:

```dart
String formatHm(int minutesSinceMidnight) {
  final h = (minutesSinceMidnight ~/ 60).toString().padLeft(2, '0');
  final m = (minutesSinceMidnight % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String formatDuration(int totalMinutes) {
  if (totalMinutes < 60) return '$totalMinutes min';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return m == 0 ? '${h}h' : '${h}h$m';
}

String formatEuros(int cents) {
  final euros = cents ~/ 100;
  final c = (cents % 100).toString().padLeft(2, '0');
  return '$euros,$c €';
}
```

- [ ] **Step 3: Write the draft screen**

```dart
// lib/presentation/tours/tour_draft_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format_minutes.dart';
import '../../data/repositories/tour_repository.dart';
import '../../state/proximity_controller.dart';
import '../../state/providers.dart';
import '../../state/tour_draft_controller.dart';

class TourDraftScreen extends ConsumerStatefulWidget {
  final int pivotId;
  const TourDraftScreen({super.key, required this.pivotId});

  @override
  ConsumerState<TourDraftScreen> createState() => _TourDraftScreenState();
}

class _TourDraftScreenState extends ConsumerState<TourDraftScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  int _startMinutes = 8 * 60;
  List<int>? _manualOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _refresh();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _startMinutes ~/ 60, minute: _startMinutes % 60),
    );
    if (picked != null) {
      setState(() => _startMinutes = picked.hour * 60 + picked.minute);
      _refresh();
    }
  }

  Future<void> _save(TourDraftBundle bundle) async {
    final stops = <TourStopDraft>[];
    for (var i = 0; i < bundle.orderedClients.length; i++) {
      final c = bundle.orderedClients[i];
      stops.add(TourStopDraft(
        clientId: c.id,
        clientNameSnapshot: c.name,
        orderIndex: i,
        estimatedArrivalMinutes: bundle.result.arrivalMinutes[i],
        estimatedDepartureMinutes: bundle.result.departureMinutes[i],
        sheepCountSnapshot: c.sheepCount,
        minutesPerSheepSnapshot: bundle.result.minutesPerSheepPerStop[i],
        feeShareCents: bundle.result.feeShareCents[i],
      ));
    }
    final tourId = await ref.read(tourRepositoryProvider).plan(
          TourDraft(
            plannedDate: _date,
            startTimeMinutes: _startMinutes,
            totalDistanceMeters: bundle.result.totalDistanceMeters,
            totalDriveSeconds: bundle.result.totalDriveSeconds,
            totalTravelFeeCents: bundle.result.totalFeeCents,
            stops: stops,
          ),
        );
    if (!mounted) return;
    ref.read(tourSelectionProvider.notifier).clear();
    context.go('/tours/$tourId');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(tourDraftProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.tourDraftTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (bundle) {
          if (bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(l.tourDraftDate),
                subtitle: Text(DateFormat('EEE dd/MM/yyyy', 'fr').format(_date)),
                onTap: _pickDate,
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(l.tourDraftStart),
                subtitle: Text(formatHm(_startMinutes)),
                onTap: _pickTime,
              ),
              const Divider(),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: bundle.orderedClients.length,
                  onReorder: (oldIndex, newIndex) {
                    final order =
                        bundle.orderedClients.map((c) => c.id).toList();
                    if (newIndex > oldIndex) newIndex -= 1;
                    final id = order.removeAt(oldIndex);
                    order.insert(newIndex, id);
                    setState(() => _manualOrder = order);
                    _refresh();
                  },
                  itemBuilder: (_, i) {
                    final c = bundle.orderedClients[i];
                    final arr = bundle.result.arrivalMinutes[i];
                    final dep = bundle.result.departureMinutes[i];
                    return ListTile(
                      key: ValueKey(c.id),
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(c.name),
                      subtitle: Text(l.tourDraftStopArrivalFmt(
                        formatHm(arr),
                        formatHm(dep),
                      )),
                      trailing: Text(formatEuros(bundle.result.feeShareCents[i])),
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(l.tourDraftSummaryTotal(
                  (bundle.result.totalDistanceMeters / 1000).toStringAsFixed(1),
                  formatDuration(bundle.result.totalDriveSeconds ~/ 60),
                  formatDuration(bundle.result.totalShearingMinutes),
                  formatHm(bundle.result.endTimeMinutes),
                )),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() => _manualOrder = null);
                          _refresh();
                        },
                        child: Text(l.tourDraftOptimise),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => _save(bundle),
                        child: Text(l.tourDraftConfirm),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Wire route**

In `app_router.dart`, top-level (alongside `/proximity`):

```dart
import '../../presentation/tours/tour_draft_screen.dart';
// ...
GoRoute(
  path: '/tours/draft',
  builder: (_, state) => TourDraftScreen(
    pivotId: int.parse(state.uri.queryParameters['pivot']!),
  ),
),
```

- [ ] **Step 5: Run on Android**, walk the flow:
1. Mark 3 clients as waiting.
2. From client A's detail screen, tap "Voir les clients à proximité".
3. Select B and C, tap "Composer la tournée".
4. Verify ordered list, totals, drag-and-drop reorders, "Optimiser" restores algorithmic order.
5. Tap "Enregistrer la tournée" — should navigate to `/tours/<id>` (placeholder for now until Phase 9).

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/tours/tour_draft_screen.dart \
        lib/state/tour_draft_controller.dart \
        lib/core/format_minutes.dart \
        lib/core/routing/app_router.dart \
        lib/l10n/
git commit -m "feat(tours): tour draft screen with optimise + drag-and-drop + save"
```

---

**Phase 8 done.** A draft is composed, optimised, reorderable, and saves a planned tour to the database.
