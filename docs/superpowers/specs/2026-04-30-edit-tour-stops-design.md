# Edit tour stops — design

**Date:** 2026-04-30
**Scope:** Allow adding / removing / reordering clients on an already-created tour.

## Goal

A user must be able to modify the client list of a `planned` tour after creation:
add a forgotten client, remove one, change the order. All derived values (ETA, total
distance, drive time, fee split) must be recomputed and persisted atomically.

## Scope

**In scope:** tours with status `planned`.

**Out of scope:**
- Tours with status `completed` (no edit affordance).
- Deleting the tour from the edit screen.
- Editing actual sheep counts (`actualSmall` / `actualLarge`) or intervention notes
  on individual stops.

## Approach

Reuse `TourDraftScreen` with an "edit mode" toggle, rather than build a new screen
or a new use case. The screen already supports the full draft flow: date / time
pickers, multi-select picker, reorder, re-optimise, fee split, ETA. The only
difference in edit mode is the source of the initial values and the persistence
call at confirmation time.

## User flow

1. On `TourDetailScreen`, when `tour.status == planned`, an "Edit" button (pencil
   icon) appears in the header next to the share button.
2. Tap → `context.push('/tours/$tourId/edit')`.
3. The route mounts `TourDraftScreen(editingTourId: id)`.
4. On init, the screen loads the tour, prefills date / start time / selection /
   manual order (current stops in their current order, used as `presetOrder`).
5. The user adds, removes, reorders, or re-optimises — same UX as creation.
6. On "Confirm", the screen calls `tourRepo.update(id, draft)` (instead of
   `plan(draft)`) and routes back to `/tours/$tourId`.

## UI changes

### `TourDetailScreen` (`lib/presentation/tours/tour_detail_screen.dart`)

- Add an `FButton.icon` with `FIcons.pencil` to `FHeader.nested.suffixes`, before
  the existing share button.
- Visible only when `bundle.tour.status == TourStatus.planned`.
- `onPress`: `context.push('/tours/$tourId/edit')`.

### `TourDraftScreen` (`lib/presentation/tours/tour_draft_screen.dart`)

- New optional parameter `final int? editingTourId`, alongside the existing
  `pivotId`.
- When `editingTourId != null`:
  - Header title becomes "Modifier la tournée" (new l10n key `tourEditTitle`).
  - In `initState`, load the tour via `tourRepository.findById(editingTourId!)`,
    then set:
    - `_date` ← `tour.plannedDate`
    - `_startMinutes` ← `tour.startTimeMinutes`
    - `_manualOrder` ← `[for stop in stops where stop.clientId != null: stop.clientId!]`
    - `tourSelectionProvider` ← same ids (to keep the legacy provider consistent)
  - Call `_refresh()` after the load completes to push the input into
    `tourDraftInputProvider`.
  - Show `FCircularProgress` while the tour is loading.
- The `_save()` method routes on `editingTourId`:
  - `null` → `tourRepo.plan(draft)` (existing behavior)
  - non-null → `tourRepo.update(editingTourId!, draft)`

### Routing

- Add `/tours/:id/edit` → `TourDraftScreen(editingTourId: int.parse(id))`.

### Picker

No changes to `WaitingClientsMultiPicker` itself. However: verify during
implementation that `waitingPickerCandidatesProvider` (in `state/providers.dart`)
includes clients whose id is in the current selection, even if they no longer
qualify as "waiting". If it filters them out, adjust the provider so that
`initialSelection` clients always appear — otherwise users cannot deselect a
no-longer-waiting client that is on the tour.

## Repository changes

### `TourRepository.update`

New method on `lib/data/repositories/tour_repository.dart`:

```dart
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

    await (_db.delete(_db.tourStopsTable)..where((s) => s.tourId.equals(id))).go();

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

Fields not touched: `id`, `createdAt`, `status`, `completedAt`. The status guard
lives in the UI (no edit button on completed tours); the repository does not
re-check.

## State / Riverpod

`TourDraftInput`, `tourDraftProvider` and the use case `BuildTourDraft` are
**unchanged**. The whole computation pipeline (matrix lookup → optimiser → ETA
→ fee split) is reused as-is.

A small local provider in `TourDraftScreen` loads the tour for prefill in edit
mode:

```dart
final _editTourLoaderProvider =
    FutureProvider.autoDispose.family<TourWithStops?, int>((ref, id) {
  return ref.watch(tourRepositoryProvider).findById(id);
});
```

This stays inside the screen file — it is one-shot init data, not shared state.

## Edge cases

| Case | Handling |
|---|---|
| Empty selection | "Confirm" button already disabled in existing draft flow. |
| Stop with `clientId == null` (deleted client) | Excluded from `_manualOrder` on entry. Disappears on confirm. Net effect: editing cleans up orphan stops. |
| Newly added client missing matrix entries | `BuildTourDraft` throws `StateError`, identical to creation. In practice `DistanceMatrixSync.recomputeForClient` keeps the matrix complete for every existing client. |
| User backs out without confirming | No persistence, tour intact. Default Flutter behavior. |
| Tour deleted concurrently while editing | `findById` returns `null` → display "Tournée introuvable" and pop. |

## Tests

### Unit — `test/data/tour_repository_test.dart`

- `update()` replaces all stops for the tour and updates totals.
- `update()` preserves `id`, `createdAt`, `status` ("planned").
- `update()` is atomic: simulating an insert error leaves the tour and stops in
  their pre-update state.

### Widget — new `test/widget/tour_edit_test.dart`

- "Edit" button visible on a `planned` tour, absent on a `completed` tour.
- Entering edit mode prefills date, start time, and the stop order from the
  saved tour.
- After modifying the selection and confirming, the persisted tour reflects the
  new client list and recomputed totals.

### Domain

No new domain tests. `BuildTourDraft`, `CostSplitCalculator`,
`TourOrderOptimizer`, `TourDurationEstimator` are unchanged.

## Localisation

New key: `tourEditTitle` → "Modifier la tournée" (FR). EN translation if the app
ships with one.

## Out of scope (future)

- Delete tour from the edit screen.
- Edit completed tours (would require rolling back client count snapshots — a
  separate feature).
- Surgical diff persistence preserving `tour_stop.id` (no current consumer
  needs it).
