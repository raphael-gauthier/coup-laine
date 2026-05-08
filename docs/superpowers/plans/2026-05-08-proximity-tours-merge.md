# Proximity ↔ Tours merge — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Create tour" button on the Proximity tab that runs ORS+TSP on `pivot + nearbyClients` and pushes to `tours/new/draft`, plus harmonize the Proximity *map* view to use the same `ClientPinPopup` as the main Map tab (with a "Set as pivot" action overriding "Plan").

**Architecture:** Extract the ORS+TSP orchestration from `tours/new/optimized-config.tsx` into a pure domain use-case (`proposeOptimizedTour`) reused by a React Query mutation hook (`useProposeOptimizedTour`) consumed inside the Proximity screen. Add an optional `planAction` prop to `ClientPinPopup` to override the "Plan" button when the popup is rendered from Proximity. No new screens, no new stores, no new tables.

**Tech Stack:** Expo + React Native, expo-router, Zustand (`tour-draft-store`, `proximity-store`), TanStack Query (existing `useResolveDistanceMatrix`), pure-TS domain in `src/domain/use-cases/`, Vitest for domain tests, i18next (single locale `fr.json`).

**Spec:** `docs/superpowers/specs/2026-05-08-proximity-tours-merge-design.md`

**Pre-flight (run once before starting):**

```bash
pnpm typecheck && pnpm lint && pnpm test
```

If anything is red on `main` *before* you start, stop and fix the regression first — don't conflate it with this work.

---

## File map

| Path | Action | Purpose |
|------|--------|---------|
| `src/domain/use-cases/propose-optimized-tour.ts` | Create | Pure orchestration: build `[BASE, ...candidates]` coords, call `resolveMatrix`, run `optimizeTourOrder`, return `orderedIds`. |
| `tests/domain/propose-optimized-tour.test.ts` | Create | Vitest spec for the use-case. |
| `src/state/queries/use-propose-optimized-tour.ts` | Create | `useMutation` hook: calls the use-case, resets the draft store, sets the order, pushes to `tours/new/draft`. |
| `src/ui/components/client-pin-popup.tsx` | Modify | Add optional `planAction` prop that overrides the right-side "Plan" button (label, icon, onPress, disabled). Default behavior unchanged. |
| `app/(tabs)/tours/new/optimized-config.tsx` | Modify | Replace inline `coords` build + `optimizeTourOrder` call (lines 103-131) with a call to `proposeOptimizedTour`. Same UX, less code. |
| `app/(tabs)/proximity/index.tsx` | Modify | Add floating "Create tour" button (both views), and on the *map* view replace pin onPress (push detail) with bottom sheet via `ClientPinPopup`. |
| `src/i18n/locales/fr.json` | Modify | Add `proximity.create_tour_cta` and `proximity.set_as_pivot`. |

No file is removed. The codebase has only one locale file (`fr.json`); no `en.json` to update.

---

## Task 1: Add i18n keys

**Files:**
- Modify: `src/i18n/locales/fr.json`

- [ ] **Step 1: Add two new keys under the `proximity` block**

Locate the `"proximity": { ... }` object (currently around line 147-162). Add two entries before the closing `}`:

```jsonc
"create_tour_cta": "Créer tournée ({{count}})",
"set_as_pivot": "Définir comme pivot"
```

The block becomes:

```jsonc
"proximity": {
  "title": "Proximité",
  "pick_pivot_title": "Choisir un client pivot",
  "pick_pivot_cta": "Choisir un pivot",
  "no_pivot_title": "Aucun pivot sélectionné",
  "no_pivot_message": "Sélectionne un client comme point de référence pour voir les autres dans son rayon.",
  "no_geocoded_title": "Aucun client géolocalisé",
  "no_geocoded_message": "Aucun client n'a d'adresse géocodée. Édite une fiche client et choisis une adresse via l'auto-complétion.",
  "pivot_label": "Pivot",
  "clear_pivot": "Retirer le pivot",
  "radius_label": "Rayon",
  "view_list": "Liste",
  "view_map": "Carte",
  "empty_title": "Aucun client dans le rayon",
  "empty_message": "Augmente le rayon ou choisis un autre pivot.",
  "create_tour_cta": "Créer tournée ({{count}})",
  "set_as_pivot": "Définir comme pivot"
}
```

- [ ] **Step 2: Verify JSON is valid**

```bash
node -e "JSON.parse(require('fs').readFileSync('src/i18n/locales/fr.json','utf8'));console.log('OK')"
```

Expected: `OK`. If it fails, you have a trailing comma or quote issue.

- [ ] **Step 3: Commit**

```bash
git add src/i18n/locales/fr.json
git commit -m "i18n(proximity): add create_tour_cta and set_as_pivot keys"
```

---

## Task 2: Domain use-case `proposeOptimizedTour` (TDD)

**Files:**
- Create: `tests/domain/propose-optimized-tour.test.ts`
- Create: `src/domain/use-cases/propose-optimized-tour.ts`

The use-case is pure: it takes a `resolveMatrix` callback as input (no module-level import of the React hook), so it can be unit-tested by passing a mock.

`optimizeTourOrder` (in `src/domain/use-cases/tour-order-optimizer.ts`) hardcodes `'BASE'` as the implicit start — we MUST include a `{ id: 'BASE', lat, lon }` entry in the `coords` we hand to `resolveMatrix`, otherwise the matrix won't have `BASE-{id}` and `{id}-BASE` pairs and the optimizer's distance lookups will all return 0.

- [ ] **Step 1: Write the failing test**

Create `tests/domain/propose-optimized-tour.test.ts`:

```ts
import { describe, it, expect, vi } from 'vitest';
import { proposeOptimizedTour } from '@/domain/use-cases/propose-optimized-tour';
import type { MatrixCoord } from '@/infra/services/ors-routing';

function makeMatrix(entries: Array<[string, string, number]>) {
  const m = new Map<string, { distanceKm: number; durationMinutes: number; isEstimate: boolean }>();
  for (const [from, to, km] of entries) {
    m.set(`${from}-${to}`, { distanceKm: km, durationMinutes: km, isEstimate: false });
  }
  return m;
}

describe('proposeOptimizedTour', () => {
  const baseCoord = { lat: 48.0, lon: 2.0 };
  const candidates = [
    { id: 'A', lat: 48.1, lon: 2.0 },
    { id: 'B', lat: 48.2, lon: 2.0 },
  ];

  it('passes BASE as the first coord to resolveMatrix', async () => {
    const resolveMatrix = vi.fn(async (_coords: MatrixCoord[]) => ({
      matrix: makeMatrix([
        ['BASE', 'A', 1], ['BASE', 'B', 2],
        ['A', 'BASE', 1], ['A', 'B', 1],
        ['B', 'BASE', 2], ['B', 'A', 1],
      ]),
      source: 'cache' as const,
    }));

    await proposeOptimizedTour({ baseCoord, candidates, resolveMatrix });

    const [coordsArg] = resolveMatrix.mock.calls[0]!;
    expect(coordsArg[0]).toEqual({ id: 'BASE', lat: 48.0, lon: 2.0 });
    expect(coordsArg.slice(1)).toEqual([
      { id: 'A', lat: 48.1, lon: 2.0 },
      { id: 'B', lat: 48.2, lon: 2.0 },
    ]);
  });

  it('returns an ordered list of candidate ids', async () => {
    const resolveMatrix = vi.fn(async () => ({
      matrix: makeMatrix([
        ['BASE', 'A', 1], ['BASE', 'B', 5],
        ['A', 'BASE', 1], ['A', 'B', 4],
        ['B', 'BASE', 5], ['B', 'A', 4],
      ]),
      source: 'cache' as const,
    }));

    const { orderedIds } = await proposeOptimizedTour({ baseCoord, candidates, resolveMatrix });

    // Greedy starting at BASE picks A first (1 km < 5 km), then B.
    expect(orderedIds).toEqual(['A', 'B']);
  });

  it('propagates errors from resolveMatrix', async () => {
    const resolveMatrix = vi.fn(async () => {
      throw new Error('boom');
    });

    await expect(
      proposeOptimizedTour({ baseCoord, candidates, resolveMatrix }),
    ).rejects.toThrow('boom');
  });

  it('does not crash when matrix is missing some pairs', async () => {
    const resolveMatrix = vi.fn(async () => ({
      matrix: makeMatrix([['BASE', 'A', 1]]), // intentionally incomplete
      source: 'haversine' as const,
    }));

    const { orderedIds } = await proposeOptimizedTour({ baseCoord, candidates, resolveMatrix });
    // Missing pairs default to 0 — optimizer still returns both ids in some order.
    expect(orderedIds).toHaveLength(2);
    expect(new Set(orderedIds)).toEqual(new Set(['A', 'B']));
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
pnpm test tests/domain/propose-optimized-tour.test.ts
```

Expected: FAIL with `Cannot find module '@/domain/use-cases/propose-optimized-tour'` (or equivalent).

- [ ] **Step 3: Implement the use-case**

Create `src/domain/use-cases/propose-optimized-tour.ts`:

```ts
import type { MatrixCoord } from '@/infra/services/ors-routing';
import type { ResolvedMatrix } from '@/state/queries/distance-matrix';
import { optimizeTourOrder } from '@/domain/use-cases/tour-order-optimizer';

export interface ProposeOptimizedTourInput {
  baseCoord: { lat: number; lon: number };
  candidates: { id: string; lat: number; lon: number }[];
  resolveMatrix: (coords: MatrixCoord[]) => Promise<ResolvedMatrix>;
}

export interface ProposeOptimizedTourResult {
  orderedIds: string[];
}

export async function proposeOptimizedTour(
  input: ProposeOptimizedTourInput,
): Promise<ProposeOptimizedTourResult> {
  const coords: MatrixCoord[] = [
    { id: 'BASE', lat: input.baseCoord.lat, lon: input.baseCoord.lon },
    ...input.candidates.map((c) => ({ id: c.id, lat: c.lat, lon: c.lon })),
  ];
  const result = await input.resolveMatrix(coords);
  const distanceKm = (from: string, to: string) =>
    result.matrix.get(`${from}-${to}`)?.distanceKm ?? 0;
  const orderedIds = optimizeTourOrder({
    stopIds: input.candidates.map((c) => c.id),
    distanceKm,
  });
  return { orderedIds };
}
```

Note: Importing `ResolvedMatrix` from `src/state/queries/distance-matrix.ts` is a one-way arrow (domain → state queries) that's normally a smell, but `ResolvedMatrix` is a pure data type that just happens to live in that file alongside the hook. If the project lint forbids this dependency, move `ResolvedMatrix` to `src/infra/services/ors-routing.ts` (where `MatrixCoord` already lives) in a separate cleanup commit before this task.

- [ ] **Step 4: Run the test to verify it passes**

```bash
pnpm test tests/domain/propose-optimized-tour.test.ts
```

Expected: PASS, all 4 cases green.

- [ ] **Step 5: Run typecheck**

```bash
pnpm typecheck
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add src/domain/use-cases/propose-optimized-tour.ts tests/domain/propose-optimized-tour.test.ts
git commit -m "feat(domain): add proposeOptimizedTour use-case"
```

---

## Task 3: React hook `useProposeOptimizedTour`

**Files:**
- Create: `src/state/queries/use-propose-optimized-tour.ts`

This hook glues the pure use-case to React Query, the Zustand draft store, and the router. Pure plomberie — no test (per spec §10.2).

- [ ] **Step 1: Create the hook**

Create `src/state/queries/use-propose-optimized-tour.ts`:

```ts
import { useMutation } from '@tanstack/react-query';
import { useRouter } from 'expo-router';
import { proposeOptimizedTour } from '@/domain/use-cases/propose-optimized-tour';
import { useResolveDistanceMatrix } from '@/state/queries/distance-matrix';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';

export interface ProposeTourInput {
  baseCoord: { lat: number; lon: number };
  candidates: { id: string; lat: number; lon: number }[];
}

export function useProposeOptimizedTour() {
  const resolve = useResolveDistanceMatrix();
  const reset = useTourDraftStore((s) => s.reset);
  const setOrder = useTourDraftStore((s) => s.setOrder);
  const router = useRouter();

  return useMutation({
    mutationFn: async (input: ProposeTourInput) => {
      const { orderedIds } = await proposeOptimizedTour({
        ...input,
        resolveMatrix: resolve.mutateAsync,
      });
      reset();
      setOrder(orderedIds);
      router.push('/(tabs)/tours/new/draft' as never);
    },
  });
}
```

- [ ] **Step 2: Run typecheck**

```bash
pnpm typecheck
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add src/state/queries/use-propose-optimized-tour.ts
git commit -m "feat(state): add useProposeOptimizedTour mutation hook"
```

---

## Task 4: `ClientPinPopup` — optional `planAction` prop

**Files:**
- Modify: `src/ui/components/client-pin-popup.tsx`

The popup currently hardcodes the right-side button to "Planifier" → `setPivotId(client.id)` + `router.push('/(tabs)/proximity')`. We want to keep that as the default but allow callers to override the label/icon/handler/disabled. Also need to import `LucideIcon` type.

- [ ] **Step 1: Add the `planAction` prop type and import**

In `src/ui/components/client-pin-popup.tsx`, find the existing `import { X, ChevronRight, Compass, Route as RouteIcon, Phone, MessageSquare, Clock } from 'lucide-react-native';` line and add a type-only import on the next line:

```ts
import type { LucideIcon } from 'lucide-react-native';
```

Then locate the existing `interface Props` (around line 26-31) and replace it with:

```ts
export interface PlanAction {
  label: string;
  icon?: LucideIcon;
  onPress: () => void;
  disabled?: boolean;
}

interface Props {
  client: Client & { latitude: number; longitude: number };
  onClose: () => void;
  arrivalTime?: string;
  onNavigate?: () => void;
  planAction?: PlanAction;
}
```

- [ ] **Step 2: Accept the new prop in the component signature**

Find:

```ts
export function ClientPinPopup({ client, onClose, arrivalTime, onNavigate }: Props) {
```

Replace with:

```ts
export function ClientPinPopup({ client, onClose, arrivalTime, onNavigate, planAction }: Props) {
```

- [ ] **Step 3: Override the right-side button when `planAction` is provided**

Find the existing "Planifier" button block (around lines 211-219):

```tsx
<Button
  className="flex-1"
  variant="secondary"
  onPress={openPlan}
  accessibilityLabel={t('map.pin_popup_plan')}
>
  <RouteIcon size={16} color="#5C4E40" />
  <Text className="font-semibold">{t('map.pin_popup_plan')}</Text>
</Button>
```

Replace with the version below. Note: we keep `openPlan` defined above as the default `onPress`, so the existing default behavior (set pivot + route to proximity) is preserved when `planAction` is undefined.

```tsx
{(() => {
  const PlanIcon = planAction?.icon ?? RouteIcon;
  const planLabel = planAction?.label ?? t('map.pin_popup_plan');
  const planOnPress = planAction?.onPress ?? openPlan;
  const planDisabled = planAction?.disabled ?? false;
  return (
    <Button
      className="flex-1"
      variant="secondary"
      onPress={planOnPress}
      disabled={planDisabled}
      accessibilityLabel={planLabel}
    >
      <PlanIcon size={16} color="#5C4E40" />
      <Text className="font-semibold">{planLabel}</Text>
    </Button>
  );
})()}
```

- [ ] **Step 4: Run typecheck**

```bash
pnpm typecheck
```

Expected: no errors.

- [ ] **Step 5: Run lint**

```bash
pnpm lint
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add src/ui/components/client-pin-popup.tsx
git commit -m "feat(ClientPinPopup): add optional planAction override"
```

---

## Task 5: Refactor `optimized-config.tsx` to use `proposeOptimizedTour`

**Files:**
- Modify: `app/(tabs)/tours/new/optimized-config.tsx`

The screen keeps its own local `proposing` / `errorMsg` state (it renders an inline error in the page, not a toast — different UX from Proximity). We only swap the inline `coords` construction + `optimizeTourOrder` call for a single call to the new use-case.

- [ ] **Step 1: Add the import**

At the top of `app/(tabs)/tours/new/optimized-config.tsx`, after the existing imports of `optimizeTourOrder` and `findWaitingClientsInRadius`, add:

```ts
import { proposeOptimizedTour } from '@/domain/use-cases/propose-optimized-tour';
```

You can now also remove the import of `optimizeTourOrder` *and* the import of `MatrixCoord` if neither is used after the refactor (verify after Step 2).

- [ ] **Step 2: Replace the body of `onContinue`**

Find the current `onContinue` (lines 103-140) and replace its body with:

```ts
const onContinue = async () => {
  if (!commune || !base) return;
  const selected = inRadius.filter((c) => !unchecked.has(c.id));
  if (selected.length === 0) {
    void haptics.error();
    setErrorMsg(t('tours.optimized_propose_empty'));
    return;
  }
  setProposing(true);
  setErrorMsg(null);
  void haptics.selection();
  try {
    const { orderedIds } = await proposeOptimizedTour({
      baseCoord: { lat: base.lat, lon: base.lon },
      candidates: selected.map((s) => {
        const c = clientsById.get(s.id)!;
        return { id: c.id, lat: c.latitude!, lon: c.longitude! };
      }),
      resolveMatrix: resolve.mutateAsync,
    });
    reset();
    setOrder(orderedIds);
    router.push('/(tabs)/tours/new/draft' as never);
  } catch (err) {
    void haptics.error();
    setErrorMsg(
      err instanceof Error ? err.message : t('tours.optimized_propose_failed'),
    );
  } finally {
    setProposing(false);
  }
};
```

- [ ] **Step 3: Remove now-unused imports**

If `optimizeTourOrder` and `MatrixCoord` are no longer referenced anywhere else in the file, remove their imports:

```ts
// remove:
import { optimizeTourOrder } from '@/domain/use-cases/tour-order-optimizer';
import type { MatrixCoord } from '@/infra/services/ors-routing';
```

Verify with grep:

```bash
node -e "const s=require('fs').readFileSync('app/(tabs)/tours/new/optimized-config.tsx','utf8');console.log('optimizeTourOrder uses:',(s.match(/optimizeTourOrder/g)||[]).length);console.log('MatrixCoord uses:',(s.match(/MatrixCoord/g)||[]).length);"
```

If either count is `> 1` (the import line itself counts as 1), keep that import.

- [ ] **Step 4: Run typecheck and lint**

```bash
pnpm typecheck && pnpm lint
```

Expected: no errors.

- [ ] **Step 5: Sanity-check by re-reading the diff**

```bash
git diff app/(tabs)/tours/new/optimized-config.tsx
```

Verify: only `onContinue`'s body and the imports section changed. The commune picker, slider, checklist, and `proposing`/`errorMsg` rendering are untouched.

- [ ] **Step 6: Commit**

```bash
git add app/(tabs)/tours/new/optimized-config.tsx
git commit -m "refactor(tours): use proposeOptimizedTour in optimized-config"
```

---

## Task 6: Proximity — floating "Create tour" button

**Files:**
- Modify: `app/(tabs)/proximity/index.tsx`

The button is rendered once at the screen level (after the `view === 'list' ? ... : ...` ternary closes), so it sits on top of *both* views — exactly as the spec asks.

- [ ] **Step 1: Add imports**

At the top of `app/(tabs)/proximity/index.tsx`, add to the existing `lucide-react-native` import the `Route as RouteIcon` icon if not already present:

```ts
import { Search, ChevronRight, X, Route as RouteIcon } from 'lucide-react-native';
```

Then add the new imports:

```ts
import { Button } from '@/ui/primitives/button';      // already imported — no-op if present
import { useBaseAddress } from '@/state/queries/settings';
import { useProposeOptimizedTour } from '@/state/queries/use-propose-optimized-tour';
import { errorToast } from '@/ui/components/error-toast';
import type { Client } from '@/domain/models/client';
```

`Button` is already imported in the existing file (line 10). Keep the import statement deduplicated.

- [ ] **Step 2: Wire up state inside `ProximityScreen`**

Below the existing `const { data: pivot } = useClient(pivotId ?? undefined);` line (around line 30), add:

```ts
const { data: base } = useBaseAddress();
const propose = useProposeOptimizedTour();
```

Then below the existing `nearbyClients` `useMemo` (around line 52), add:

```ts
type GeoClient = Client & { latitude: number; longitude: number };

const geocodedCandidates = useMemo<GeoClient[]>(() => {
  if (!pivot) return [];
  const all: Array<typeof pivot> = [pivot, ...nearbyClients];
  return all.filter(
    (c): c is GeoClient => c.latitude != null && c.longitude != null,
  );
}, [pivot, nearbyClients]);

const onCreateTour = () => {
  if (!base || geocodedCandidates.length < 2) return;
  propose.mutate(
    {
      baseCoord: { lat: base.lat, lon: base.lon },
      candidates: geocodedCandidates.map((c) => ({
        id: c.id,
        lat: c.latitude,
        lon: c.longitude,
      })),
    },
    {
      onError: (err) => {
        errorToast(
          err instanceof Error ? err.message : t('tours.optimized_propose_failed'),
        );
      },
    },
  );
};
```

`errorToast` already triggers `haptics.error()` internally, so no extra haptic call is needed here.

- [ ] **Step 3: Render the floating button**

Inside the `return (...)`, find the closing `</Surface>` of the main render branch (the one that's hit when `pivot` exists, around line 176). Before that closing `</Surface>`, but after the `view === 'list' ? ... : ...` block, insert:

```tsx
{geocodedCandidates.length >= 2 && base ? (
  <View className="absolute bottom-4 left-4 right-4">
    <Button onPress={onCreateTour} disabled={propose.isPending}>
      {propose.isPending ? (
        <ActivityIndicator />
      ) : (
        <RouteIcon size={16} color="#5C4E40" />
      )}
      <Text className="font-semibold">
        {t('proximity.create_tour_cta', { count: geocodedCandidates.length })}
      </Text>
    </Button>
  </View>
) : null}
```

`ActivityIndicator` and `Text` are already imported. `View` too.

- [ ] **Step 4: Run typecheck and lint**

```bash
pnpm typecheck && pnpm lint
```

Expected: no errors.

- [ ] **Step 5: Manual smoke-test (dev server)**

Start the dev client and verify:

```bash
pnpm start
```

In the running app:
1. Pick a pivot client with at least 1 other geocoded client in radius.
2. Confirm "Créer tournée (N)" appears in both *list* and *map* views, with N = pivot + nearby count.
3. Tap it → spinner → arrival on `tours/new/draft` with the optimized order (pivot included).
4. Reduce the radius until 0 nearby → button disappears.

If anything misbehaves, fix before committing.

- [ ] **Step 6: Commit**

```bash
git add app/(tabs)/proximity/index.tsx
git commit -m "feat(proximity): add Create tour button (pivot+nearby → optimized)"
```

---

## Task 7: Proximity — bottom sheet harmonization on map view

**Files:**
- Modify: `app/(tabs)/proximity/index.tsx`

We replace the current `ClientPin onPress = router.push('/(tabs)/clients/{id}')` with `setSelectedClient(c)` on the *map* view only, and render `<ClientPinPopup planAction={...}>` below the map. The list view is intentionally left alone.

- [ ] **Step 1: Add imports**

Add `Crosshair` to the existing `lucide-react-native` import line:

```ts
import { Search, ChevronRight, X, Route as RouteIcon, Crosshair } from 'lucide-react-native';
```

Add the popup import:

```ts
import { ClientPinPopup } from '@/ui/components/client-pin-popup';
```

Also add `useState` to the existing `react` import if it isn't already there:

```ts
import { useMemo, useRef, useState } from 'react';
```

- [ ] **Step 2: Add `selectedClient` state**

Below the existing `const propose = useProposeOptimizedTour();` line (added in Task 6), add:

```ts
const [selectedClient, setSelectedClient] = useState<GeoClient | null>(null);
```

- [ ] **Step 3: Replace pin onPress handlers in the map branch**

In the `view === 'map'` branch (currently around lines 148-175), find:

```tsx
<ClientPin
  client={pivot as typeof pivot & { latitude: number; longitude: number }}
  onPress={() => router.push(`/(tabs)/clients/${pivot.id}`)}
/>
{nearbyClients
  .filter((c) => c.latitude != null && c.longitude != null)
  .map((c) => (
    <ClientPin
      key={c.id}
      client={c as typeof c & { latitude: number; longitude: number }}
      onPress={() => router.push(`/(tabs)/clients/${c.id}`)}
    />
  ))}
```

Replace with:

```tsx
<ClientPin
  client={pivot as GeoClient}
  onPress={() => setSelectedClient(pivot as GeoClient)}
/>
{nearbyClients
  .filter((c): c is GeoClient => c.latitude != null && c.longitude != null)
  .map((c) => (
    <ClientPin
      key={c.id}
      client={c}
      onPress={() => setSelectedClient(c)}
    />
  ))}
```

- [ ] **Step 4: Render the popup at the bottom of the map view**

Still in the `view === 'map'` branch, below the closing `</Map>` tag but inside the `<View className="flex-1">` wrapper, add:

```tsx
{selectedClient ? (
  <ClientPinPopup
    client={selectedClient}
    onClose={() => setSelectedClient(null)}
    planAction={{
      label: t('proximity.set_as_pivot'),
      icon: Crosshair,
      disabled: selectedClient.id === pivot.id,
      onPress: () => {
        setPivotId(selectedClient.id);
        setSelectedClient(null);
        mapRef.current?.flyTo(
          selectedClient.longitude,
          selectedClient.latitude,
          12,
        );
      },
    }}
  />
) : null}
```

`pivot` is in scope (the function returned early if `pivot` was null). `setPivotId` is already destructured from `useProximityStore` at the top.

- [ ] **Step 5: Run typecheck and lint**

```bash
pnpm typecheck && pnpm lint
```

Expected: no errors.

- [ ] **Step 6: Manual smoke-test**

```bash
pnpm start
```

Verify on the *map* view:
1. Tap a *nearby* pin → bottom sheet appears, "Définir comme pivot" enabled.
2. Tap "Définir comme pivot" → pivot updates, sheet closes, map re-centers on the new pivot.
3. Tap the *pivot* pin → bottom sheet appears, "Définir comme pivot" disabled.
4. Tap the popup card body → push to client detail.
5. Tap the X icon → sheet closes.
6. Switch to *list* view → tap a card → still pushes to client detail (unchanged).

Then verify the main Map tab is unaffected:
7. Open the Carte tab, tap a pin → "Planifier" button still says "Planifier" and routes to Proximité as before.

- [ ] **Step 7: Commit**

```bash
git add app/(tabs)/proximity/index.tsx
git commit -m "feat(proximity): show ClientPinPopup on map pin tap"
```

---

## Task 8: Final regression pass

- [ ] **Step 1: Full type/lint/test pass**

```bash
pnpm typecheck && pnpm lint && pnpm test
```

Expected: all green.

- [ ] **Step 2: Manual scenarios from the spec §12**

Run through, in this order:

1. Pivot with ≥2 geocoded nearby → "Créer tournée (N)" visible on both views, correct count.
2. Tap → 1-3s spinner → land on `tours/new/draft` with stops ordered.
3. Toggle airplane mode → tap → toast appears, no navigation, draft store untouched.
   *Note: `resolveDistanceMatrix` falls back to haversine on ORS failure (it doesn't reject), so this case won't trigger an error in normal conditions. It will only error if the cache cleanup or DB fails. Document this nuance in the PR if you observe success even offline.*
4. Reduce radius until 0 nearby → button disappears.
5. Map view: tap nearby pin → sheet, "Définir comme pivot" enabled → tap → pivot changes, recenters.
6. Map view: tap pivot pin → sheet, "Définir comme pivot" disabled.
7. Map view: tap popup card body → client detail.
8. Carte tab (main map): tap pin → "Planifier" routes to Proximité (default behavior unchanged).
9. `tours/new/optimized-config`: full commune+radius flow → ordered tour drafts identical to pre-refactor behavior.

- [ ] **Step 3: Open the PR**

```bash
git log --oneline main..HEAD
```

Expected: 7 commits (i18n, use-case, hook, popup prop, optimized-config refactor, proximity button, proximity sheet).

If everything is green, the branch is ready for PR.

---

## Self-review notes (for the implementer)

- **Spec coverage**: Goals 1 (button on both views), 2 (popup with set-as-pivot, pivot disabled), 3 (use-case reused by `optimized-config`), 4 (5 tabs intact) — covered by tasks 1, 6, 7, 4, 5 respectively. Non-goals 1-6 are observed (no merged tab, list untouched, no multi-select, no extra cache, optimized-config preserved, pivot still client-only).
- **Cross-task type consistency**: `GeoClient` is declared in Task 6 and reused in Task 7 — same name, same shape. `ProposeTourInput` exported from the hook matches the use-case input minus `resolveMatrix`. `PlanAction` exported from the popup is consumed in Task 7's call site by structural typing (no import needed unless you want it).
- **Known nuance**: `resolveDistanceMatrix` doesn't reject on ORS failure — it falls back to haversine. The error path in the use-case still propagates if the cache or DB fails. Don't waste time trying to engineer a way to surface a "network error" toast when offline; the spec acknowledges this in §9.2.
