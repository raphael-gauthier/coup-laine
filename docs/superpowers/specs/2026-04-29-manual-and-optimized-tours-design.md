# Manual & optimized tours — Design

**Date:** 2026-04-29
**Status:** Approved (brainstorming) — pending implementation plan

## 1. Context

Today, the only way to create a tour is from a pivot client: open a client → "Tournée à proximité" → `ProximityScreen` (radius around pivot) → select waiting clients → `TourDraftScreen`. This forces the user through a proximity-driven flow even when several waiting clients are not clustered around any single pivot, or when the user wants to compose a tour by intuition.

Two new entry points are added:

- **F1 — Tournée manuelle.** Free multi-selection of waiting clients without a pivot or radius constraint.
- **F2 — Tournée optimisée par commune.** The user picks a commune and a target day length; the app proposes a realistic tour centred on that commune.

Both features land in the existing `TourDraftScreen`, where date, time, order and selection can still be tweaked before saving.

## 2. Architecture

### New files

- `lib/presentation/widgets/waiting_clients_multi_picker.dart` — reusable widget with list+map tabs, takes `Set<int> initialSelection` and `ValueChanged<Set<int>> onSelectionChanged`. No pivot, no radius. Used by F1 and by the draft "edit selection" sheet.
- `lib/presentation/tours/tour_manual_picker_screen.dart` — F1 screen: header "Nouvelle tournée", body = the picker, footer "Continuer" when ≥1 selected.
- `lib/presentation/tours/tour_optimized_config_screen.dart` — F2 screen: commune dropdown (with waiting-count badges) + duration slider (5h–10h, default 8h) + button "Proposer une tournée".
- `lib/domain/use_cases/build_optimized_tour_proposal.dart` — pure use case implementing the greedy-by-barycentre algorithm.
- `lib/domain/use_cases/find_communes_with_waiting.dart` — pure use case aggregating waiting clients by `city`, returning `(name, count)` pairs.

### Modified files

- `lib/presentation/tours/tours_list_screen.dart` — adds a FAB that opens an `FBottomSheet` with two choices: "Manuelle" / "Optimisée par commune".
- `lib/core/routing/app_router.dart` — `pivot` query param on `/tours/draft` becomes optional; new routes `/tours/new/manual` and `/tours/new/optimized`.
- `lib/state/tour_draft_controller.dart` — `TourDraftInput.pivotId` becomes `int?`. When null, the provider uses `selectedIds` directly without prepending a pivot.
- `lib/presentation/tours/tour_draft_screen.dart` — adds an "Modifier la sélection" outline button next to the "Étapes" heading; opens the picker in a full-screen sheet.

### End-to-end flows

```
F1 :  Tours list → FAB → "Manuelle"
        → /tours/new/manual (TourManualPickerScreen)
        → /tours/draft (TourDraftScreen, no pivot)
        → save → /tours/:id

F2 :  Tours list → FAB → "Optimisée par commune"
        → /tours/new/optimized (TourOptimizedConfigScreen)
        → /tours/draft (TourDraftScreen, no pivot, selection pre-filled)
        → save → /tours/:id
```

## 3. F1 — Tournée manuelle

**Pool.** Waiting clients only (`ClientStatus.waiting`). Clients with `needsDistanceRecompute=true` are excluded (see §6).

**Picker.** `WaitingClientsMultiPicker` with two tabs:
- **List** — search field on top (filters name + city, case-insensitive via `core/text_search.dart`); below it, alphabetical `FTile` list with a checkbox suffix.
- **Map** — pins for waiting clients; tap toggles selection. Selected pins visually distinct (uses `markerColorHex` plus an outline/check). Reuses logic from `proximity_map_view.dart` but without the radius circle and without a pivot pin.

**Footer.** Visible only when ≥1 selected: `"{n} sélectionnés"` left, primary button `"Continuer"` right.

**Empty state.** If no waiting clients are eligible, the picker shows `AppEmptyState` ("Aucun client en attente") and "Continuer" stays disabled.

**Routing.** "Continuer" pushes `/tours/draft` after writing the input:

```dart
ref.read(tourDraftInputProvider.notifier).state = TourDraftInput(
  pivotId: null,
  selectedIds: selection.toList(),
  plannedDate: tomorrow,
  startTimeMinutes: 8 * 60,
);
```

## 4. F2 — Tournée optimisée par commune

### Config screen

**Carte "Commune"** (`AppSectionCard`, icon `FIcons.mapPin`): an `FSelect<String>` listing communes returned by `FindCommunesWithWaiting`, formatted `"Carhaix-Plouguer (5)"`. Sorted alphabetically. If zero communes, the screen shows an empty state pointing to Settings (where the existing "Réessayer" button lives).

**Carte "Durée cible"** (`AppSectionCard`, icon `FIcons.clock`): a `Slider`, range 5h–10h, step 30 min, default 8h. Big value displayed above the slider (same pattern as the radius card on `ProximityScreen`).

**Footer.** Primary button "Proposer une tournée", disabled until a commune is chosen.

### Use case `BuildOptimizedTourProposal`

```dart
class OptimizedProposal {
  final List<int> selectedClientIds;     // ordered (already optimised)
  final int estimatedDurationMinutes;    // total drive + shearing + return
  final bool isUnderTarget;
  final bool isOverTarget;               // mutually exclusive with isUnderTarget
}

OptimizedProposal call({
  required String communeName,           // matches Client.city (strict equality)
  required int targetMinutes,
  required int startTimeMinutes,         // for TourDurationEstimator (default 8:00)
  required List<Client> waitingClients,  // app-wide
  required List<DistanceMatrixEntry> matrix, // all pairs (existing cache)
  required Settings settings,
});
```

### Algorithm (greedy by barycentre)

Tolerance constant: `30 min` either side of the target.

1. **Seed.** All waiting clients with `client.city == communeName`. Excluded if `needsDistanceRecompute=true`. If empty after filtering, return an empty proposal (guarded — should not happen since the dropdown is filtered).
2. **Barycentre.** Mean of seed coordinates (lat, lon).
3. **Estimate seed duration.** Call `BuildTourDraft.build(candidateIds: seed, …)` — its `TourDraftResult.endTimeMinutes - startTimeMinutes` is the total estimated duration.
4. **Branch EXTENSION** if `seedDuration < target - 30`:
   - Sort other waiting clients (`status==waiting && city != communeName`, matrix-eligible) by ascending distance to the barycentre.
   - One by one, append a candidate to the working set, recompute via `BuildTourDraft`. Keep the candidate iff `newDuration ≤ target + 30`. Stop at the first refusal *or* when no more candidates remain.
   - Final `isUnderTarget = duration < target - 30`.
5. **Branch CONTRACTION** if `seedDuration > target + 30`:
   - Sort the seed by descending distance to the barycentre.
   - Remove one candidate at a time and recompute, until `duration ≤ target + 30` *or* only 1 stop remains.
   - Final `isOverTarget = duration > target + 30`.
6. **Branch OK** otherwise: keep the seed unchanged.
7. Return the final list of IDs in the optimal order (already produced by `BuildTourDraft`).

**Cost.** Each iteration calls `BuildTourDraft` (TSP nearest-neighbour + 2-opt). For ≤ ~15 stops it is sub-millisecond. Worst plausible case (~50 candidates considered) stays under 1 s on mobile.

### Routing

"Proposer une tournée" runs the use case via a `FutureProvider` (spinner displayed). On success, writes a `TourDraftInput` with `pivotId: null` and the proposed selection, then pushes `/tours/draft`. The draft screen does not surface the under/over-target flag — total duration is already visible in the summary card. **YAGNI.**

## 5. Shared picker & draft editing

### `WaitingClientsMultiPicker`

```dart
class WaitingClientsMultiPicker extends ConsumerStatefulWidget {
  final Set<int> initialSelection;
  final ValueChanged<Set<int>> onSelectionChanged;
  final List<int>? excludeIds; // optional, unused initially
}
```

`FTabs(expands: true, [List, Map])`. Internal `Set<int> _selection` initialised from `initialSelection`, fires `onSelectionChanged` on toggle. **No footer** — host screens own their CTA.

### `ProximityScreen` is not refactored

Proximity has pivot- and radius-specific UI (distance per row, sort by distance, radius circle on map). Merging would force conditionals everywhere. The duplication is accepted: the two flows are distinct.

### "Modifier la sélection" on `TourDraftScreen`

- **Placement.** `FButton.outline`, icon `FIcons.pencil`, label "Modifier", to the right of the "Étapes" heading.
- **Behaviour.** Opens a full-screen `FSheet` with a header "Modifier la sélection", the picker as body, and a footer "Valider".
- On "Valider": writes the new selection to `tourDraftInputProvider` with `overrideOrder: null` (so the optimiser re-runs), closes the sheet. The draft recomputes via `tourDraftProvider`.
- "Valider" disabled if selection empty.
- Cancel = no change.
- Visible regardless of pivot/no-pivot. If the original pivot is removed, no special handling: the provider already treats pivot as just another `selectedId`.

### Updated `TourDraftInput`

```dart
class TourDraftInput {
  final int? pivotId;          // null for F1/F2
  final List<int> selectedIds; // all clients of the tour
  final DateTime plannedDate;
  final int startTimeMinutes;
  final List<int>? overrideOrder;
}
```

Provider:

```dart
final ids = input.pivotId == null
    ? input.selectedIds
    : [input.pivotId!, ...input.selectedIds.where((id) => id != input.pivotId)];
```

## 6. Edge cases

**Missing matrix entries.** `BuildTourDraft` throws `StateError` on a missing pair. To avoid this in F1/F2, clients with `needsDistanceRecompute=true` are filtered out of the picker pool and the F2 candidate set. A banner at the top of the picker reports excluded clients ("3 clients indisponibles — recalcul de distance en attente"). If a draft is being edited and a previously-included client becomes ineligible, the picker shows it greyed out and not de-selectable; the draft is built with it as before.

**Commune with no eligible clients.** `FindCommunesWithWaiting` already filters out empty communes (after the recompute exclusion). Zero communes → empty state with a link to Settings.

**One-stop proposal.** Allowed. F2 may return a single client with `isUnderTarget=true`; the user can extend manually via the draft picker.

**Empty selection in draft editing.** "Valider" disabled.

**`Client.city` inconsistency.** Strict equality on `city`. BAN provides a canonical name per address, so two clients of the same real-world commune share the same `city`. Manual edits are the user's responsibility. No fuzzy matching, no normalisation.

**F2 performance.** Synchronous call inside a `FutureProvider`. Spinner during compute. No progress indicator: the operation is bounded and fast.

**Default date/time.** Same as today: tomorrow, 8:00. Adjusted on the draft as before.

**Mid-flow cancel.** Back button returns to the previous screen. The two new screens reset `tourDraftInputProvider` and `tourSelectionProvider` on entry to start fresh; on save, both providers are cleared (already done today).

## 7. Testing

### Domain — `build_optimized_tour_proposal_test.dart`

1. `seed only fits target` — seed near target, returned unchanged, neither flag set.
2. `expansion: under-target seed extends to neighbours` — seed too short, extension adds nearest-to-barycentre clients.
3. `expansion stops before exceeding tolerance` — last accepted candidate keeps duration ≤ target + 30.
4. `expansion: no neighbours available` — seed alone, `isUnderTarget=true`.
5. `contraction: over-target seed shrinks` — removes farthest from barycentre until ≤ target + 30.
6. `contraction never goes below 1 stop` — irrealistic target → 1 stop, `isOverTarget=true`.
7. `single-client commune` — returns 1 stop without error.
8. `barycentre is mean of seed coordinates` — pure unit test of the centroid calculation.

### Domain — `find_communes_with_waiting_test.dart`

1. Groups waiting clients by city, sorted alphabetically.
2. Excludes clients with `needsDistanceRecompute`.
3. Excludes non-waiting clients.
4. Omits communes with zero eligible clients.

### State / repo

- Extend `tour_repository_test.dart`: `plan()` accepts a `TourDraft` whose stops do not include any specific pivot — confirm no FK or invariant relied implicitly on a pivot.
- New `tour_draft_controller_test.dart`:
  1. Null pivot → uses `selectedIds` only.
  2. Non-null pivot → prepends pivot (regression of existing flow).
  3. `overrideOrder` honoured (regression).

### Widget tests

- `TourManualPickerScreen`: empty state renders; footer disabled with no selection; enabled with ≥1.
- `TourOptimizedConfigScreen`: "Proposer" disabled until a commune is chosen; slider updates the displayed duration.
- `WaitingClientsMultiPicker`: tap toggles selection; search filters the list.

No widget test on the modified `TourDraftScreen` (sheet interaction, manual verification).

### Out of scope

- No benchmark (algorithm bounded by construction).
- No ORS/matrix tests (covered by existing tests).
- No regression test for the full pivot flow if not already present (relies on unchanged `BuildTourDraft`).
