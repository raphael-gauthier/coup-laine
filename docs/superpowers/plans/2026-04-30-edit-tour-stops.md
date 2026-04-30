# Edit tour stops — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow the user to add, remove, and reorder clients on an existing `planned` tour by reusing `TourDraftScreen` in an "edit mode", and persisting the change in place via a new `TourRepository.update` method.

**Architecture:** No new use case, no new screen. `TourDraftScreen` gains an optional `editingTourId` parameter. When set, it loads the tour at init, prefills date/time/selection/order, and routes the confirm action to `TourRepository.update(id, draft)` instead of `plan(draft)`. `WaitingClientsMultiPicker` is extended with an `alwaysIncludeIds` parameter so currently-on-tour clients remain visible in the picker even when their status is no longer "waiting".

**Tech Stack:** Flutter 3.41, Drift 2.32, Riverpod 3, go_router, ForUI.

**Spec:** `docs/superpowers/specs/2026-04-30-edit-tour-stops-design.md`

---

## Task 1 — `TourRepository.update`

**Files:**
- Modify: `lib/data/repositories/tour_repository.dart`
- Test: `test/data/tour_repository_test.dart`

- [ ] **Step 1: Write the failing tests**

Append the following tests inside the existing `void main() { ... }` of `test/data/tour_repository_test.dart`, before the closing `}`:

```dart
test('update replaces stops and updates totals while preserving id, '
    'createdAt and status', () async {
  final c1 = await addClient('A');
  final c2 = await addClient('B');
  final c3 = await addClient('C');

  final tourId = await tours.plan(TourDraft(
    plannedDate: DateTime(2026, 5, 12),
    startTimeMinutes: 8 * 60,
    totalDistanceMeters: 30000,
    totalDriveSeconds: 3600,
    totalTravelFeeCents: 4000,
    stops: [
      TourStopDraft(
        clientId: c1,
        clientNameSnapshot: 'A',
        orderIndex: 0,
        estimatedArrivalMinutes: 8 * 60 + 20,
        estimatedDepartureMinutes: 8 * 60 + 80,
        plannedSmall: 5,
        plannedLarge: 0,
        minutesPerSmallSnapshot: 8,
        minutesPerLargeSnapshot: 25,
        feeShareCents: 2000,
      ),
      TourStopDraft(
        clientId: c2,
        clientNameSnapshot: 'B',
        orderIndex: 1,
        estimatedArrivalMinutes: 9 * 60 + 30,
        estimatedDepartureMinutes: 10 * 60 + 30,
        plannedSmall: 5,
        plannedLarge: 0,
        minutesPerSmallSnapshot: 8,
        minutesPerLargeSnapshot: 25,
        feeShareCents: 2000,
      ),
    ],
  ));
  final beforeRead = await tours.findById(tourId);
  final originalCreatedAt = beforeRead!.tour.createdAt;

  // Replace [A, B] with [C, A] and bump the date / start / totals.
  await tours.update(
    tourId,
    TourDraft(
      plannedDate: DateTime(2026, 5, 14),
      startTimeMinutes: 9 * 60,
      totalDistanceMeters: 50000,
      totalDriveSeconds: 7200,
      totalTravelFeeCents: 6000,
      stops: [
        TourStopDraft(
          clientId: c3,
          clientNameSnapshot: 'C',
          orderIndex: 0,
          estimatedArrivalMinutes: 9 * 60 + 40,
          estimatedDepartureMinutes: 10 * 60 + 20,
          plannedSmall: 5,
          plannedLarge: 0,
          minutesPerSmallSnapshot: 8,
          minutesPerLargeSnapshot: 25,
          feeShareCents: 3000,
        ),
        TourStopDraft(
          clientId: c1,
          clientNameSnapshot: 'A',
          orderIndex: 1,
          estimatedArrivalMinutes: 11 * 60,
          estimatedDepartureMinutes: 11 * 60 + 40,
          plannedSmall: 5,
          plannedLarge: 0,
          minutesPerSmallSnapshot: 8,
          minutesPerLargeSnapshot: 25,
          feeShareCents: 3000,
        ),
      ],
    ),
  );

  final after = await tours.findById(tourId);
  expect(after, isNotNull);
  expect(after!.tour.id, tourId);
  expect(after.tour.createdAt, originalCreatedAt);
  expect(after.tour.status, TourStatus.planned);
  expect(after.tour.plannedDate, DateTime(2026, 5, 14));
  expect(after.tour.startTimeMinutes, 9 * 60);
  expect(after.tour.totalDistanceMeters, 50000);
  expect(after.tour.totalDriveSeconds, 7200);
  expect(after.tour.totalTravelFeeCents, 6000);
  expect(after.stops.map((s) => s.clientNameSnapshot), ['C', 'A']);
  expect(after.stops.map((s) => s.clientId), [c3, c1]);
});

test('update does not leak stops from other tours', () async {
  final c1 = await addClient('A');
  final c2 = await addClient('B');
  final tourA = await tours.plan(TourDraft(
    plannedDate: DateTime(2026, 5, 12),
    startTimeMinutes: 8 * 60,
    totalDistanceMeters: 0,
    totalDriveSeconds: 0,
    totalTravelFeeCents: 0,
    stops: [
      TourStopDraft(
        clientId: c1,
        clientNameSnapshot: 'A',
        orderIndex: 0,
        estimatedArrivalMinutes: 480,
        estimatedDepartureMinutes: 580,
        plannedSmall: 1,
        plannedLarge: 0,
        minutesPerSmallSnapshot: 8,
        minutesPerLargeSnapshot: 25,
        feeShareCents: 0,
      ),
    ],
  ));
  final tourB = await tours.plan(TourDraft(
    plannedDate: DateTime(2026, 5, 13),
    startTimeMinutes: 8 * 60,
    totalDistanceMeters: 0,
    totalDriveSeconds: 0,
    totalTravelFeeCents: 0,
    stops: [
      TourStopDraft(
        clientId: c2,
        clientNameSnapshot: 'B',
        orderIndex: 0,
        estimatedArrivalMinutes: 480,
        estimatedDepartureMinutes: 580,
        plannedSmall: 1,
        plannedLarge: 0,
        minutesPerSmallSnapshot: 8,
        minutesPerLargeSnapshot: 25,
        feeShareCents: 0,
      ),
    ],
  ));

  // Replace tourA's stops only — tourB must remain untouched.
  await tours.update(
    tourA,
    TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: const [],
    ),
  );

  final readA = await tours.findById(tourA);
  final readB = await tours.findById(tourB);
  expect(readA!.stops, isEmpty);
  expect(readB!.stops.map((s) => s.clientNameSnapshot), ['B']);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/tour_repository_test.dart`
Expected: 2 FAILS with `The method 'update' isn't defined for the class 'TourRepository'.` (compile error).

- [ ] **Step 3: Implement `update`**

Edit `lib/data/repositories/tour_repository.dart`. Add the following method to `TourRepository`, immediately after `markCompleted` and before `delete`:

```dart
  /// Replace the contents of a planned tour: tour totals, date, start time,
  /// notes, and the entire stops list. Stop ids are not preserved (we delete
  /// then reinsert) — there is no consumer that holds onto them.
  ///
  /// Status, completedAt, id and createdAt are intentionally left untouched.
  /// The caller (UI) must only invoke this for tours with status `planned`.
  Future<void> update(int id, TourDraft draft) async {
    await _db.transaction(() async {
      await (_db.update(_db.toursTable)..where((t) => t.id.equals(id))).write(
        ToursTableCompanion(
          plannedDate: Value(_toEpochDay(draft.plannedDate)),
          startTimeMinutes: Value(draft.startTimeMinutes),
          totalDistanceMeters: Value(draft.totalDistanceMeters),
          totalDriveSeconds: Value(draft.totalDriveSeconds),
          totalTravelFeeCents: Value(draft.totalTravelFeeCents),
          notes: Value(draft.notes),
        ),
      );

      await (_db.delete(_db.tourStopsTable)
            ..where((s) => s.tourId.equals(id)))
          .go();

      for (final s in draft.stops) {
        await _db.into(_db.tourStopsTable).insert(
              TourStopsTableCompanion.insert(
                tourId: id,
                clientId: Value(s.clientId),
                clientNameSnapshot: s.clientNameSnapshot,
                orderIndex: s.orderIndex,
                estimatedArrivalMinutes: s.estimatedArrivalMinutes,
                estimatedDepartureMinutes: s.estimatedDepartureMinutes,
                plannedSmall: Value(s.plannedSmall),
                plannedLarge: Value(s.plannedLarge),
                minutesPerSmallSnapshot: Value(s.minutesPerSmallSnapshot),
                minutesPerLargeSnapshot: Value(s.minutesPerLargeSnapshot),
                feeShareCents: s.feeShareCents,
              ),
            );
      }
    });
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/data/tour_repository_test.dart`
Expected: PASS (5 tests total: the 3 existing + the 2 new ones).

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/tour_repository.dart test/data/tour_repository_test.dart
git commit -m "feat(tour-repo): add update for in-place tour replacement"
```

---

## Task 2 — Add l10n key `tourEditTitle`

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add the FR key**

Edit `lib/l10n/app_fr.arb`. Replace the last 3 lines:

```json
  "tourDraftEditSelection": "Modifier",
  "tourDraftEditSelectionSheetTitle": "Modifier la sélection",
  "tourDraftEditSelectionValidate": "Valider"
}
```

with:

```json
  "tourDraftEditSelection": "Modifier",
  "tourDraftEditSelectionSheetTitle": "Modifier la sélection",
  "tourDraftEditSelectionValidate": "Valider",
  "tourEditTitle": "Modifier la tournée",
  "tourDetailEdit": "Modifier"
}
```

- [ ] **Step 2: Add the EN key**

Edit `lib/l10n/app_en.arb`. Replace the last 3 lines:

```json
  "tourDraftEditSelection": "Edit",
  "tourDraftEditSelectionSheetTitle": "Edit selection",
  "tourDraftEditSelectionValidate": "Confirm"
}
```

with:

```json
  "tourDraftEditSelection": "Edit",
  "tourDraftEditSelectionSheetTitle": "Edit selection",
  "tourDraftEditSelectionValidate": "Confirm",
  "tourEditTitle": "Edit tour",
  "tourDetailEdit": "Edit"
}
```

- [ ] **Step 3: Regenerate localisation Dart files**

Run: `flutter gen-l10n`
Expected: no output, files `lib/l10n/app_localizations*.dart` updated. The new getters `l.tourEditTitle` and `l.tourDetailEdit` are now available.

- [ ] **Step 4: Run analyzer to confirm no breakage**

Run: `flutter analyze --no-fatal-infos lib/l10n`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_fr.dart lib/l10n/app_localizations_en.dart
git commit -m "i18n: add tourEditTitle and tourDetailEdit keys"
```

---

## Task 3 — `WaitingClientsMultiPicker.alwaysIncludeIds`

**Why:** When editing a tour, clients already on the tour may no longer satisfy the "waiting" filter (e.g. their season status changed since the tour was planned). They must still be visible in the picker so the user can deselect them. We extend the picker with an opt-in `alwaysIncludeIds` parameter that fetches those clients separately and prepends them to the eligible list (dedup by id).

**Files:**
- Modify: `lib/presentation/widgets/waiting_clients_multi_picker.dart`

- [ ] **Step 1: Add the parameter and merge logic**

Edit `lib/presentation/widgets/waiting_clients_multi_picker.dart`.

Replace the class declaration block (lines 15–28):

```dart
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
```

with:

```dart
class WaitingClientsMultiPicker extends ConsumerStatefulWidget {
  final Set<int> initialSelection;
  final ValueChanged<Set<int>> onSelectionChanged;

  /// Clients listed here are forced into the picker even when they don't
  /// satisfy the "waiting" filter — used by tour edit mode so a client that
  /// is already on the tour stays visible (and therefore deselectable) even
  /// if its status has since moved out of `waiting`.
  final Set<int> alwaysIncludeIds;

  const WaitingClientsMultiPicker({
    super.key,
    required this.initialSelection,
    required this.onSelectionChanged,
    this.alwaysIncludeIds = const {},
  });

  @override
  ConsumerState<WaitingClientsMultiPicker> createState() =>
      _WaitingClientsMultiPickerState();
}
```

Then, in `_WaitingClientsMultiPickerState.build`, replace the body of the `data:` callback (currently starting at line 55 with `if (data.eligible.isEmpty) {`) so that we merge the always-include clients into `eligible`. The full new `build` body inside `async.when(... data: (data) { ... })` should be:

```dart
      data: (data) {
        // Pull in clients that must stay visible even if they're not waiting.
        final extraIds =
            widget.alwaysIncludeIds.difference(data.eligible.map((c) => c.id).toSet());
        final extraAsync = extraIds.isEmpty
            ? const AsyncData<List<Client>>(<Client>[])
            : ref.watch(_clientsByIdsProvider(extraIds));
        return extraAsync.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (extras) {
            final eligible = [...extras, ...data.eligible];
            if (eligible.isEmpty) {
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
                          clients: eligible,
                          selection: _selection,
                          query: _query,
                          onQueryChanged: (q) => setState(() => _query = q),
                          onToggle: _toggle,
                        ),
                      ),
                      FTabEntry(
                        label: Text(l.manualPickerTabMap),
                        child: _MapTab(
                          clients: eligible,
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
      },
```

- [ ] **Step 2: Add the `_clientsByIdsProvider` near the top of the file**

Insert this provider right after the imports (i.e. after the last `import ...;` line), before the `class WaitingClientsMultiPicker` declaration:

```dart
/// One-shot loader for a fixed set of client ids. Used by
/// [WaitingClientsMultiPicker] to surface clients that don't satisfy the
/// "waiting" filter but must remain selectable (e.g. tour edit mode).
final _clientsByIdsProvider = FutureProvider.autoDispose
    .family<List<Client>, Set<int>>((ref, ids) async {
  final repo = ref.watch(clientRepositoryProvider);
  final out = <Client>[];
  for (final id in ids) {
    final c = await repo.findById(id);
    if (c != null) out.add(c);
  }
  return out;
});
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze --no-fatal-infos lib/presentation/widgets/waiting_clients_multi_picker.dart`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/waiting_clients_multi_picker.dart
git commit -m "feat(picker): allow forcing clients into the waiting picker"
```

---

## Task 4 — Promote `_tourByIdProvider` to a public provider

**Why:** Currently this provider is private to `tour_detail_screen.dart`. After the edit flow saves, we route back to `/tours/:id` — but go_router reuses the existing detail screen instance (it was already in the stack), so the provider keeps its cached value and the screen shows stale data. The edit screen needs to call `ref.invalidate(tourByIdProvider(id))` after saving, which requires the provider to be reachable from elsewhere.

**Files:**
- Modify: `lib/state/providers.dart`
- Modify: `lib/presentation/tours/tour_detail_screen.dart`

- [ ] **Step 1: Add the public provider in `providers.dart`**

Edit `lib/state/providers.dart`. Find the existing `goRouterProvider` line (around line 106) and insert immediately after it:

```dart
final tourByIdProvider =
    FutureProvider.autoDispose.family<TourWithStops?, int>((ref, id) {
  return ref.watch(tourRepositoryProvider).findById(id);
});
```

Make sure the file imports `TourWithStops` from `tour_repository.dart`. If the import is missing, add at the top:

```dart
import '../data/repositories/tour_repository.dart';
```

(Run `flutter analyze lib/state/providers.dart` after this step to confirm.)

- [ ] **Step 2: Switch `tour_detail_screen.dart` to the public provider**

Edit `lib/presentation/tours/tour_detail_screen.dart`.

Delete the private declaration (lines 22–25):

```dart
final _tourByIdProvider =
    FutureProvider.autoDispose.family<TourWithStops?, int>((ref, id) {
  return ref.watch(tourRepositoryProvider).findById(id);
});
```

Replace the single usage at line 34:

```dart
    final async = ref.watch(_tourByIdProvider(tourId));
```

with:

```dart
    final async = ref.watch(tourByIdProvider(tourId));
```

Verify imports — `tour_detail_screen.dart` already imports `../../state/providers.dart`, so `tourByIdProvider` resolves. The import of `tour_repository.dart` for the `TourWithStops` type can be kept as-is.

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze --no-fatal-infos lib/state/providers.dart lib/presentation/tours/tour_detail_screen.dart`
Expected: no errors.

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: all tests pass (no behavioural change).

- [ ] **Step 5: Commit**

```bash
git add lib/state/providers.dart lib/presentation/tours/tour_detail_screen.dart
git commit -m "refactor(state): promote tourByIdProvider to providers.dart"
```

---

## Task 5 — `TourDraftScreen` edit mode (prefill + reroute confirm)

**Files:**
- Modify: `lib/presentation/tours/tour_draft_screen.dart`

- [ ] **Step 1: Add `editingTourId` field and the loader provider**

Edit `lib/presentation/tours/tour_draft_screen.dart`.

Replace the class declaration (lines 22–28):

```dart
class TourDraftScreen extends ConsumerStatefulWidget {
  final int? pivotId;
  const TourDraftScreen({super.key, this.pivotId});

  @override
  ConsumerState<TourDraftScreen> createState() => _TourDraftScreenState();
}
```

with:

```dart
class TourDraftScreen extends ConsumerStatefulWidget {
  final int? pivotId;
  final int? editingTourId;
  const TourDraftScreen({super.key, this.pivotId, this.editingTourId});

  @override
  ConsumerState<TourDraftScreen> createState() => _TourDraftScreenState();
}

/// One-shot loader for the tour being edited. Local to this screen — no
/// other consumer needs it.
final _editingTourLoaderProvider =
    FutureProvider.autoDispose.family<TourWithStops?, int>((ref, id) {
  return ref.watch(tourRepositoryProvider).findById(id);
});
```

- [ ] **Step 2: Replace the state class with the prefill-aware version**

In the same file, replace the entire `_TourDraftScreenState` class (everything from `class _TourDraftScreenState extends ConsumerState<TourDraftScreen> {` to its closing `}` — currently lines 30–343) with:

```dart
class _TourDraftScreenState extends ConsumerState<TourDraftScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  int _startMinutes = 8 * 60;
  List<int>? _manualOrder;
  bool _prefilled = false;

  bool get _isEditing => widget.editingTourId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadForEdit());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  Future<void> _loadForEdit() async {
    final tour = await ref.read(_editingTourLoaderProvider(widget.editingTourId!).future);
    if (!mounted) return;
    if (tour == null) {
      // Tour vanished (deleted concurrently). Pop back.
      if (context.canPop()) context.pop();
      return;
    }
    final orderedIds = [
      for (final s in tour.stops)
        if (s.clientId != null) s.clientId!,
    ];
    setState(() {
      _date = tour.tour.plannedDate;
      _startMinutes = tour.tour.startTimeMinutes;
      _manualOrder = orderedIds;
      _prefilled = true;
    });
    final notifier = ref.read(tourSelectionProvider.notifier);
    notifier.clear();
    for (final id in orderedIds) {
      notifier.toggle(id);
    }
    _refresh();
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
        plannedSmall: bundle.result.plannedSmallPerStop[i],
        plannedLarge: bundle.result.plannedLargePerStop[i],
        minutesPerSmallSnapshot: bundle.result.minutesPerSmallPerStop[i],
        minutesPerLargeSnapshot: bundle.result.minutesPerLargePerStop[i],
        feeShareCents: bundle.result.feeShareCents[i],
      ));
    }
    final draft = TourDraft(
      plannedDate: _date,
      startTimeMinutes: _startMinutes,
      totalDistanceMeters: bundle.result.totalDistanceMeters,
      totalDriveSeconds: bundle.result.totalDriveSeconds,
      totalTravelFeeCents: bundle.result.totalFeeCents,
      stops: stops,
    );

    final repo = ref.read(tourRepositoryProvider);
    final int destinationId;
    if (_isEditing) {
      await repo.update(widget.editingTourId!, draft);
      destinationId = widget.editingTourId!;
    } else {
      destinationId = await repo.plan(draft);
    }
    if (!mounted) return;
    ref.read(tourSelectionProvider.notifier).clear();
    ref.invalidate(toursAsyncProvider);
    if (_isEditing) {
      ref.invalidate(_editingTourLoaderProvider(widget.editingTourId!));
      ref.invalidate(tourByIdProvider(widget.editingTourId!));
    }
    context.go('/tours/$destinationId');
  }

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
                        alwaysIncludeIds: initial,
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
                              final notifier =
                                  ref.read(tourSelectionProvider.notifier);
                              notifier.clear();
                              for (final id in working) {
                                notifier.toggle(id);
                              }
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = context.theme;
    final async = ref.watch(tourDraftProvider);
    final title = _isEditing ? l.tourEditTitle : l.tourDraftTitle;

    // While the tour is loading in edit mode, show a spinner instead of the
    // empty draft (which would otherwise flash with default values).
    if (_isEditing && !_prefilled) {
      return SafeArea(
        child: FScaffold(
          header: FHeader.nested(title: Text(title)),
          child: const Center(child: FCircularProgress()),
        ),
      );
    }

    return SafeArea(
      child: FScaffold(
        resizeToAvoidBottomInset: true,
        header: FHeader.nested(title: Text(title)),
        child: async.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(child: Text('$e')),
        data: (bundle) {
          if (bundle == null) {
            return const Center(child: FCircularProgress());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date/time card
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: AppSectionCard(
                  icon: FIcons.calendarClock,
                  title: l.tourDraftWhenTitle,
                  child: Row(
                    children: [
                      Expanded(
                        child: FTile(
                          prefix: const Icon(FIcons.calendar),
                          title: Text(l.tourDraftDate),
                          subtitle: Text(DateFormat('d MMM yyyy', 'fr').format(_date)),
                          onPress: _pickDate,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FTile(
                          prefix: const Icon(FIcons.clock),
                          title: Text(l.tourDraftStart),
                          subtitle: Text(formatHm(_startMinutes)),
                          onPress: _pickTime,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // "Étapes" heading
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
              // Reorderable list
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
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
                      final fee = formatEuros(bundle.result.feeShareCents[i]);
                      return Padding(
                        key: ValueKey(c.id),
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: FTile(
                          prefix: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.colors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.primaryForeground,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(c.name),
                          subtitle: Text(
                            l.tourDraftStopArrivalFmt(formatHm(arr), formatHm(dep)),
                          ),
                          details: Text(fee),
                          suffix: const Icon(FIcons.gripVertical),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Summary footer
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: AppHeroCard(
                  bigNumber:
                      (bundle.result.totalDistanceMeters / 1000).toStringAsFixed(0),
                  label: 'km au total',
                  subtitle:
                      '${formatDuration(bundle.result.totalDriveSeconds ~/ 60)} de trajet · Fin ${formatHm(bundle.result.endTimeMinutes)}',
                ),
              ),
              // Action row
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      FButton(
                        variant: FButtonVariant.outline,
                        onPress: () {
                          setState(() => _manualOrder = null);
                          _refresh();
                        },
                        child: Text(l.tourDraftOptimise),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppPrimaryButton(
                          label: l.tourDraftConfirm,
                          onPress: () => _save(bundle),
                        ),
                      ),
                    ],
                  ),
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

Note the small but important changes vs. the original:
- New `editingTourId`, `_isEditing`, `_prefilled` plumbing.
- New `_loadForEdit` runs once at mount.
- `_save` branches on `_isEditing` and calls `update` instead of `plan`, then routes back to the existing tour id.
- The "Modifier la sélection" sheet now passes `alwaysIncludeIds: initial` to the picker, and also syncs `tourSelectionProvider` after the user validates (the original only updated `tourDraftInputProvider` — fine for fresh creation but problematic when the user re-opens the sheet because `bundle.orderedClients` recomputes from the input, not from the legacy notifier).
- Title becomes `tourEditTitle` in edit mode.
- Loading curtain while `_prefilled` is false in edit mode.

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze --no-fatal-infos lib/presentation/tours/tour_draft_screen.dart`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/tours/tour_draft_screen.dart
git commit -m "feat(tour-draft): edit mode (load existing tour, save via update)"
```

---

## Task 6 — Register `/tours/:id/edit` route

**Files:**
- Modify: `lib/core/routing/app_router.dart`

- [ ] **Step 1: Add the route**

Edit `lib/core/routing/app_router.dart`. Find the existing `/tours/draft` route block (lines 45–53):

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

Insert immediately after it (before the `/tours/new/manual` block):

```dart
        GoRoute(
          path: '/tours/:id/edit',
          builder: (_, state) => TourDraftScreen(
            editingTourId: int.parse(state.pathParameters['id']!),
          ),
        ),
```

**Why a top-level route, not a child of `/tours/:id`?** The `/tours/:id` route lives inside the `StatefulShellRoute` (so it shows the bottom nav). The draft screen is a full-screen modal with its own header and no shell — putting `/tours/:id/edit` next to `/tours/draft` keeps that consistent.

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze --no-fatal-infos lib/core/routing/app_router.dart`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/routing/app_router.dart
git commit -m "feat(routing): /tours/:id/edit -> TourDraftScreen edit mode"
```

---

## Task 7 — "Modifier" button on `TourDetailScreen`

**Files:**
- Modify: `lib/presentation/tours/tour_detail_screen.dart`

- [ ] **Step 1: Add the button**

Edit `lib/presentation/tours/tour_detail_screen.dart`. Replace the `header:` block of the outer `FScaffold` (currently lines 38–51):

```dart
        header: FHeader.nested(
          title: Text(async.value == null
              ? '...'
              : DateFormat('EEE d MMM yyyy', 'fr')
                  .format(async.value!.tour.plannedDate)),
          suffixes: [
            FButton.icon(
              onPress: async.value == null
                  ? null
                  : () => _share(async.value!, context, l),
              child: const Icon(FIcons.share2),
            ),
          ],
        ),
```

with:

```dart
        header: FHeader.nested(
          title: Text(async.value == null
              ? '...'
              : DateFormat('EEE d MMM yyyy', 'fr')
                  .format(async.value!.tour.plannedDate)),
          suffixes: [
            if (async.value != null &&
                async.value!.tour.status == TourStatus.planned)
              FButton.icon(
                onPress: () => context.push('/tours/$tourId/edit'),
                child: const Icon(FIcons.pencil),
              ),
            FButton.icon(
              onPress: async.value == null
                  ? null
                  : () => _share(async.value!, context, l),
              child: const Icon(FIcons.share2),
            ),
          ],
        ),
```

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze --no-fatal-infos lib/presentation/tours/tour_detail_screen.dart`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/tours/tour_detail_screen.dart
git commit -m "feat(tour-detail): show Modifier button for planned tours"
```

---

## Task 8 — Manual smoke test

**Files:** none (manual verification).

- [ ] **Step 1: Full-suite green**

Run: `flutter test`
Expected: all tests pass.

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 2: Launch the app**

Run: `flutter run -d <device>`

- [ ] **Step 3: Verify the edit flow end-to-end**

Walkthrough (in order, on a debug build with at least 3 clients in waiting + 1 planned tour):

1. Navigate to **Tournées → tap a planned tour**.
2. Confirm the **pencil "Modifier"** icon appears in the top-right (left of share). It must NOT appear if you tap a `completed` tour — verify by completing one first if needed.
3. Tap **Modifier**. The `TourDraftScreen` opens, header reads **"Modifier la tournée"**.
4. Confirm date, start time, and the existing stop order are pre-filled (same as on the detail screen).
5. Tap **"Modifier"** (the small button next to "Étapes"). The picker sheet opens with all current tour clients pre-checked.
6. Uncheck one client, check a new one. Validate the sheet.
7. Reorder the list with drag handles.
8. Tap **"Enregistrer la tournée"**. App returns to `TourDetailScreen` of the same tour id.
9. Verify the schedule reflects the new client list and order, totals updated.
10. Re-open **Modifier**, deselect all clients except one. Validate; the "Enregistrer" button must remain enabled (one client is fine). Save.
11. Re-open **Modifier**, deselect everything in the picker. Confirm the picker's **"Valider"** button is disabled. Cancel out.
12. Open a tour that contains a client whose status is no longer `waiting` (e.g. mark one as completed in another tour first). Open the edit-selection picker. **Verify that client appears in the list** (with eligible clients) and can be deselected.
13. Quit the app mid-edit (no save). Re-open. Tour is unchanged.

If any step fails, file an issue against this plan rather than patching ad-hoc.

- [ ] **Step 4: Commit only if anything had to be tweaked**

If the smoke test surfaced a fix, commit it under a descriptive message and re-run from Step 1. Otherwise no commit for this task.

---

## Self-review notes

- **Spec coverage:** UI changes (Tasks 5, 7) ✓, repository (Task 1) ✓, state/provider (Tasks 4, 5) ✓, routing (Task 6) ✓, picker fix (Task 3) ✓, l10n (Task 2) ✓, edge cases (Task 8 manual + repo tests) ✓, tests (Task 1) ✓.
- **No placeholders:** every code step has full code; every command has expected output.
- **Type consistency:** `editingTourId`, `_isEditing`, `_prefilled`, `_loadForEdit`, `_editingTourLoaderProvider`, `alwaysIncludeIds`, `_clientsByIdsProvider`, `TourRepository.update` — names match across all tasks.
- **Hard skipped:** widget tests for the edit screen. The codebase has near-zero widget tests today (one skipped) and adding harness for `TourDraftScreen` (Riverpod overrides, ForUI theme, drift in-memory, gen-l10n) is out of proportion. Manual smoke test (Task 7) covers the user-visible behaviour; the heavy logic (`BuildTourDraft`, `update`) is covered by unit tests.
