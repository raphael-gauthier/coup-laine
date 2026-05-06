# Travel Fees Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the equally-divided tour travel fee with a per-client bracket-based fee (computed from base→client distance, captured at tour bilan, modifiable). Add an optional `travelFeeCents` field on manual history entries. Include travel fees in client revenue (CA) and outstanding everywhere.

**Architecture:** New pure domain use case `compute-client-travel-fee` replaces `cost-split-calculator`. Travel fee is persisted **per stop** on `tour_stops.travel_fee_cents` (renamed from `fee_share_cents`) and **per entry** on the new `manual_history_entries.travel_fee_cents`. The tour-level total (`tours.total_travel_fee_cents`) is dropped — derived from stops at read time. KPI/outstanding use cases gain a `travelFeeCents` input.

**Tech Stack:** TypeScript, Expo / React Native, Drizzle ORM (SQLite via `expo-sqlite`), Zod, react-hook-form, vitest (`tests/domain`), jest (`tests/data`), i18next, NativeWind.

---

## Spec reference

This plan implements `docs/superpowers/specs/2026-05-06-travel-fees-rework-design.md`. Re-read it if anything below is unclear.

## Conventions (from CLAUDE.md)

- Package manager: **pnpm**.
- All identifiers / file names / DB columns / i18n key paths in **English**. French only inside i18n JSON values.
- Tests run with `pnpm test:domain` (vitest) or `pnpm test:integration` (jest) or both via `pnpm test`.
- Type-check with `pnpm typecheck`. Lint with `pnpm lint`.
- Cents are integers everywhere money is stored or transported.

## File structure

### Created

- `src/domain/use-cases/compute-client-travel-fee.ts`
- `src/domain/use-cases/resolve-base-distance.ts`
- `tests/domain/use-cases/compute-client-travel-fee.test.ts`
- `tests/domain/use-cases/resolve-base-distance.test.ts`
- `src/infra/db/migrations/0004_travel_fees_rework.sql`

### Modified

- `src/domain/models/tour.ts` (drop `totalTravelFeeCents`)
- `src/domain/models/tour-stop.ts` (rename `feeShareCents` → `travelFeeCents`)
- `src/domain/models/manual-history-entry.ts` (add `travelFeeCents`)
- `src/domain/models/intervention.ts` (add `travelFeeCents`)
- `src/domain/use-cases/compute-client-kpis.ts` (include travel fees in revenue)
- `src/domain/use-cases/compute-client-outstanding.ts` (include travel fees in unpaid)
- `src/domain/use-cases/compute-tour-kpis.ts` (compute travel fees from stops; include in revenue)
- `src/domain/use-cases/merge-client-history.ts` (carry `travelFeeCents` into `Intervention`)
- `src/infra/db/schema.ts` (column renames)
- `src/infra/db/migrations/migrations.js` (regenerated)
- `src/infra/db/migrations/meta/_journal.json` (add idx 4)
- `src/infra/cloud/backup-schema.ts` (mirror schema changes)
- `src/data/repositories/tour-repository.ts` (rename property)
- `src/data/repositories/manual-history-repository.ts` (new field)
- `src/state/queries/tours.ts` (drop fee inputs; add `perStopTravelFees` to bilan)
- `src/state/queries/history.ts` (add `travelFeeCents` to upsert input + history merge)
- `src/state/queries/kpis.ts` (pass `travelFeeCents` into use cases)
- `src/ui/components/tour-draft-editor.tsx` (live per-client compute, drop split)
- `src/ui/components/stop-completion-editor.tsx` (new editable field)
- `src/ui/components/manual-history-form.tsx` (new optional field + breakdown)
- `src/ui/components/history-row.tsx` (display total amount)
- `app/(tabs)/tours/new/draft.tsx` (drop fee fields in onSubmit)
- `app/(tabs)/tours/[id]/edit.tsx` (drop fee fields in onSubmit)
- `app/(tabs)/tours/[id]/complete.tsx` (per-stop travel fee state, send in mutation)
- `app/(tabs)/settings/tour-rate.tsx` (re-i18n labels)
- `src/i18n/locales/fr.json` (new keys, reword `settings.tour_rate.*` and `tours.total_cost`)
- `tests/domain/use-cases/compute-client-kpis.test.ts`
- `tests/domain/use-cases/compute-client-outstanding.test.ts`
- `tests/domain/use-cases/compute-tour-kpis.test.ts`
- `tests/data/manual-history-repository.test.ts`

### Deleted

- `src/domain/use-cases/cost-split-calculator.ts`
- `src/domain/use-cases/bracket-counter.ts` is **kept** (still used by `compute-client-travel-fee`).
- `tests/domain/use-cases/cost-split-calculator.test.ts` (if it exists)

---

## Phase 1 — Domain logic (pure TS, TDD)

Phase 1 introduces the new pure functions and adapts the KPI/outstanding/merge use cases. No DB changes yet; existing callers keep compiling against current models until Phase 2.

### Task 1: Add `compute-client-travel-fee` use case

**Files:**
- Create: `src/domain/use-cases/compute-client-travel-fee.ts`
- Create: `tests/domain/use-cases/compute-client-travel-fee.test.ts`

- [ ] **Step 1: Write the failing test**

Create `tests/domain/use-cases/compute-client-travel-fee.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { computeClientTravelFee } from '@/domain/use-cases/compute-client-travel-fee';

describe('computeClientTravelFee', () => {
  it('charges 1 bracket minimum even at 0 km', () => {
    expect(computeClientTravelFee({ distanceKm: 0, bracketKm: 10, feePerBracket: 8 })).toBe(0);
  });

  it('charges 1 bracket below the bracket size', () => {
    expect(computeClientTravelFee({ distanceKm: 4, bracketKm: 10, feePerBracket: 8 })).toBe(800);
  });

  it('rounds up to the next bracket (ceil)', () => {
    expect(computeClientTravelFee({ distanceKm: 23, bracketKm: 10, feePerBracket: 8 })).toBe(2400);
    expect(computeClientTravelFee({ distanceKm: 25, bracketKm: 10, feePerBracket: 8 })).toBe(2400);
    expect(computeClientTravelFee({ distanceKm: 25.01, bracketKm: 10, feePerBracket: 8 })).toBe(3200);
  });

  it('returns integer cents from float fee', () => {
    // 2 brackets × 7.5 € = 15 € = 1500 cents
    expect(computeClientTravelFee({ distanceKm: 15, bracketKm: 10, feePerBracket: 7.5 })).toBe(1500);
  });

  it('returns 0 when distance is exactly 0 (no brackets)', () => {
    expect(computeClientTravelFee({ distanceKm: 0, bracketKm: 10, feePerBracket: 8 })).toBe(0);
  });
});
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `pnpm test:domain compute-client-travel-fee`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement the use case**

Create `src/domain/use-cases/compute-client-travel-fee.ts`:

```ts
import { countBrackets } from './bracket-counter';

interface Input {
  /** Distance from base to client in kilometers (>= 0). */
  distanceKm: number;
  /** Size of one bracket in km (e.g. 10). */
  bracketKm: number;
  /** Price per bracket in euros (e.g. 8). */
  feePerBracket: number;
}

/** Returns the fee in integer cents. */
export function computeClientTravelFee(input: Input): number {
  const brackets = countBrackets(input.distanceKm, input.bracketKm);
  return Math.round(brackets * input.feePerBracket * 100);
}
```

Note: existing `bracket-counter.ts` already returns 0 when `distanceKm <= 0`, so the "0 km → 0 €" case is correct. A non-zero distance below `bracketKm` produces 1 bracket via `Math.ceil`.

- [ ] **Step 4: Run the test to confirm it passes**

Run: `pnpm test:domain compute-client-travel-fee`
Expected: PASS, all 5 cases.

- [ ] **Step 5: Commit**

```bash
git add src/domain/use-cases/compute-client-travel-fee.ts tests/domain/use-cases/compute-client-travel-fee.test.ts
git commit -m "feat(domain): add compute-client-travel-fee use case"
```

---

### Task 2: Add `resolve-base-distance` helper

**Files:**
- Create: `src/domain/use-cases/resolve-base-distance.ts`
- Create: `tests/domain/use-cases/resolve-base-distance.test.ts`

This helper reads the distance-matrix cache first (routing-based), falling back to haversine when the pair is missing or marked failed. It takes the cache lookup as a function param so the use case stays pure (no repo coupling).

- [ ] **Step 1: Write the failing test**

Create `tests/domain/use-cases/resolve-base-distance.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { resolveBaseDistance } from '@/domain/use-cases/resolve-base-distance';

const base = { lat: 48.0, lon: 2.0 };
const client = { lat: 48.1, lon: 2.1 }; // ~13.4 km haversine

describe('resolveBaseDistance', () => {
  it('uses cached routing distance when present and not failed', () => {
    const r = resolveBaseDistance({
      base,
      client,
      lookup: () => ({ distanceKm: 18.5, failed: false }),
    });
    expect(r).toBeCloseTo(18.5, 5);
  });

  it('falls back to haversine when cache miss', () => {
    const r = resolveBaseDistance({
      base,
      client,
      lookup: () => null,
    });
    expect(r).toBeGreaterThan(13);
    expect(r).toBeLessThan(14);
  });

  it('falls back to haversine when cache entry is failed', () => {
    const r = resolveBaseDistance({
      base,
      client,
      lookup: () => ({ distanceKm: 0, failed: true }),
    });
    expect(r).toBeGreaterThan(13);
    expect(r).toBeLessThan(14);
  });

  it('returns 0 when client coords missing', () => {
    expect(
      resolveBaseDistance({ base, client: null, lookup: () => null })
    ).toBe(0);
  });
});
```

- [ ] **Step 2: Run the test to confirm it fails**

Run: `pnpm test:domain resolve-base-distance`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement the helper**

Create `src/domain/use-cases/resolve-base-distance.ts`:

```ts
import { haversineDistanceKm } from '@/lib/haversine-distance';
import type { Coordinates } from '@/domain/models/coordinates';

interface CachedDistance {
  distanceKm: number;
  failed: boolean;
}

interface Input {
  base: Coordinates;
  client: Coordinates | null;
  /** Returns the cached entry for (base, client) or null if absent. */
  lookup: () => CachedDistance | null;
}

export function resolveBaseDistance({ base, client, lookup }: Input): number {
  if (!client) return 0;
  const cached = lookup();
  if (cached && !cached.failed) return cached.distanceKm;
  return haversineDistanceKm(base, client);
}
```

- [ ] **Step 4: Run the test to confirm it passes**

Run: `pnpm test:domain resolve-base-distance`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/use-cases/resolve-base-distance.ts tests/domain/use-cases/resolve-base-distance.test.ts
git commit -m "feat(domain): add resolve-base-distance helper"
```

---

### Task 3: Update `Intervention` model + `merge-client-history`

The history list (`history-row.tsx`) needs to display a per-row amount. The `Intervention` shape is what feeds it; we add `travelFeeCents` so the row can show `services + travelFee`.

**Files:**
- Modify: `src/domain/models/intervention.ts`
- Modify: `src/domain/use-cases/merge-client-history.ts`
- Modify: `tests/domain/use-cases/merge-client-history.test.ts`

- [ ] **Step 1: Update the failing test**

Open `tests/domain/use-cases/merge-client-history.test.ts` and read its current shape. Add a new test case asserting `travelFeeCents` is carried through. Example to add inside the existing `describe`:

```ts
it('carries travelFeeCents from both sources', () => {
  const result = mergeClientHistory({
    tourStopsWithDate: [
      { tourId: 't1', stopId: 's1', date: '2026-01-01', services: [], notes: null, travelFeeCents: 1500 },
    ],
    manualEntries: [
      { id: 'm1', date: '2026-02-01', services: [], notes: null, travelFeeCents: 800 },
    ],
  });
  expect(result.find((i) => i.source === 'tour')!.travelFeeCents).toBe(1500);
  expect(result.find((i) => i.source === 'manual')!.travelFeeCents).toBe(800);
});
```

Adapt the existing tests in this file to add `travelFeeCents: null` (or a value) to their item factories so they still pass.

- [ ] **Step 2: Run the test to confirm new case fails**

Run: `pnpm test:domain merge-client-history`
Expected: FAIL — input shape doesn't accept `travelFeeCents`.

- [ ] **Step 3: Update the model**

Edit `src/domain/models/intervention.ts`:

```ts
import { z } from 'zod';
import { TourStopService } from './tour-stop-service';

export const InterventionSource = z.enum(['tour', 'manual']);

export const Intervention = z.object({
  source: InterventionSource,
  date: z.string(),
  services: z.array(TourStopService),
  travelFeeCents: z.number().int().nullable(),
  notes: z.string().nullable(),
  tourId: z.string().nullable(),
  tourStopId: z.string().nullable(),
  manualEntryId: z.string().nullable(),
});

export type Intervention = z.infer<typeof Intervention>;
```

- [ ] **Step 4: Update the merge use case**

Edit `src/domain/use-cases/merge-client-history.ts`:

```ts
import type { Intervention } from '@/domain/models/intervention';
import type { TourStopService } from '@/domain/models/tour-stop-service';

interface TourStopHistoryItem {
  tourId: string;
  stopId: string;
  date: string;
  services: TourStopService[];
  notes: string | null;
  travelFeeCents: number | null;
}

interface ManualHistoryItem {
  id: string;
  date: string;
  services: TourStopService[];
  notes: string | null;
  travelFeeCents: number | null;
}

interface Input {
  tourStopsWithDate: TourStopHistoryItem[];
  manualEntries: ManualHistoryItem[];
}

export function mergeClientHistory({ tourStopsWithDate, manualEntries }: Input): Intervention[] {
  const fromTours: Intervention[] = tourStopsWithDate.map((t) => ({
    source: 'tour',
    date: t.date,
    services: t.services,
    travelFeeCents: t.travelFeeCents,
    notes: t.notes,
    tourId: t.tourId,
    tourStopId: t.stopId,
    manualEntryId: null,
  }));
  const fromManual: Intervention[] = manualEntries.map((m) => ({
    source: 'manual',
    date: m.date,
    services: m.services,
    travelFeeCents: m.travelFeeCents,
    notes: m.notes,
    tourId: null,
    tourStopId: null,
    manualEntryId: m.id,
  }));
  return [...fromTours, ...fromManual].sort((a, b) => b.date.localeCompare(a.date));
}
```

- [ ] **Step 5: Run the test suite to confirm passes**

Run: `pnpm test:domain merge-client-history`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add src/domain/models/intervention.ts src/domain/use-cases/merge-client-history.ts tests/domain/use-cases/merge-client-history.test.ts
git commit -m "feat(domain): carry travelFeeCents into Intervention/merge"
```

---

### Task 4: Update `compute-client-kpis` to include travel fees in revenue

**Files:**
- Modify: `src/domain/use-cases/compute-client-kpis.ts`
- Modify: `tests/domain/use-cases/compute-client-kpis.test.ts`

- [ ] **Step 1: Update the test**

Edit `tests/domain/use-cases/compute-client-kpis.test.ts`. Replace the file with:

```ts
import { describe, it, expect } from 'vitest';
import { computeClientKpis } from '@/domain/use-cases/compute-client-kpis';
import type { TourStopService } from '@/domain/models/tour-stop-service';

const ps = (over: Partial<TourStopService>): TourStopService => ({
  serviceId: 'p',
  qty: 1,
  nameSnapshot: 'X',
  priceCentsSnapshot: 0,
  minutesSnapshot: 0,
  categoryIdSnapshot: null,
  categoryNameSnapshot: null,
  speciesNameSnapshot: null,
  ...over,
});

describe('computeClientKpis', () => {
  it('returns zeros when no interventions', () => {
    expect(
      computeClientKpis({
        tourStops: [],
        manualEntries: [],
        today: '2026-05-03',
      })
    ).toEqual({
      interventionsCount: 0,
      totalRevenueCents: 0,
      firstInterventionDate: null,
      lastInterventionDate: null,
      yearsSinceFirst: 0,
    });
  });

  it('counts and sums services + travel fees across both sources', () => {
    const r = computeClientKpis({
      tourStops: [
        { date: '2026-03-10', services: [ps({ qty: 5, priceCentsSnapshot: 800 })], travelFeeCents: 1500 },
        { date: '2025-04-05', services: [ps({ qty: 3, priceCentsSnapshot: 600 })], travelFeeCents: null },
      ],
      manualEntries: [
        { date: '2024-06-15', services: [ps({ qty: 2, priceCentsSnapshot: 500 })], travelFeeCents: 700 },
      ],
      today: '2026-05-03',
    });
    expect(r.interventionsCount).toBe(3);
    // services: 5*800 + 3*600 + 2*500 = 6800 ; fees: 1500 + 0 + 700 = 2200 ; total: 9000
    expect(r.totalRevenueCents).toBe(9000);
    expect(r.firstInterventionDate).toBe('2024-06-15');
    expect(r.lastInterventionDate).toBe('2026-03-10');
    expect(r.yearsSinceFirst).toBe(1);
  });
});
```

- [ ] **Step 2: Run the test, confirm fail**

Run: `pnpm test:domain compute-client-kpis`
Expected: FAIL — `travelFeeCents` not accepted.

- [ ] **Step 3: Update the use case**

Edit `src/domain/use-cases/compute-client-kpis.ts`:

```ts
import type { TourStopService } from '@/domain/models/tour-stop-service';

interface InterventionItem {
  date: string;
  services: TourStopService[];
  travelFeeCents: number | null;
}

interface Input {
  tourStops: InterventionItem[];
  manualEntries: InterventionItem[];
  today: string;
}

export interface ClientKpis {
  interventionsCount: number;
  totalRevenueCents: number;
  firstInterventionDate: string | null;
  lastInterventionDate: string | null;
  yearsSinceFirst: number;
}

export function computeClientKpis({ tourStops, manualEntries, today }: Input): ClientKpis {
  const all = [...tourStops, ...manualEntries];
  if (all.length === 0) {
    return {
      interventionsCount: 0,
      totalRevenueCents: 0,
      firstInterventionDate: null,
      lastInterventionDate: null,
      yearsSinceFirst: 0,
    };
  }
  const totalRevenueCents = all.reduce(
    (sum, item) =>
      sum +
      item.services.reduce((s, p) => s + p.qty * p.priceCentsSnapshot, 0) +
      (item.travelFeeCents ?? 0),
    0
  );
  const sortedDates = all.map((i) => i.date).sort();
  const firstDate = sortedDates[0]!;
  const lastDate = sortedDates[sortedDates.length - 1]!;

  const firstYear = parseInt(firstDate.slice(0, 4), 10);
  const todayYear = parseInt(today.slice(0, 4), 10);
  const fullYears = (() => {
    const diff = todayYear - firstYear;
    if (today.slice(5) < firstDate.slice(5)) return Math.max(0, diff - 1);
    return diff;
  })();

  return {
    interventionsCount: all.length,
    totalRevenueCents,
    firstInterventionDate: firstDate,
    lastInterventionDate: lastDate,
    yearsSinceFirst: fullYears,
  };
}
```

- [ ] **Step 4: Run the test, confirm pass**

Run: `pnpm test:domain compute-client-kpis`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/use-cases/compute-client-kpis.ts tests/domain/use-cases/compute-client-kpis.test.ts
git commit -m "feat(kpis): include travel fees in client revenue"
```

---

### Task 5: Update `compute-client-outstanding` to include travel fees

**Files:**
- Modify: `src/domain/use-cases/compute-client-outstanding.ts`
- Modify: `tests/domain/use-cases/compute-client-outstanding.test.ts`

The test file builds `TourStop` with `feeShareCents: null`. **We do not rename the model property in this task** — the test keeps using `feeShareCents` until Phase 2 renames it. Phase 1 changes only the *use case input shape* (adds an explicit `travelFeeCents` field passed by the caller). The use case is decoupled from the storage shape.

- [ ] **Step 1: Update the test**

Replace `tests/domain/use-cases/compute-client-outstanding.test.ts` with:

```ts
import { describe, it, expect } from 'vitest';
import { computeClientOutstanding } from '@/domain/use-cases/compute-client-outstanding';
import { EMPTY_PAYMENT } from '@/domain/models/payment';
import type { TourStop } from '@/domain/models/tour-stop';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';

const svc = (qty: number, priceCents: number) => ({
  serviceId: 'a', qty, nameSnapshot: 'A',
  priceCentsSnapshot: priceCents, minutesSnapshot: 0,
  categoryIdSnapshot: null, categoryNameSnapshot: null, speciesNameSnapshot: null,
});

const stop = (overrides: Partial<TourStop> = {}): TourStop => ({
  id: 's', tourId: 't', clientId: 'c', clientNameSnapshot: null,
  ordering: 0, arrivalMinutes: null, departureMinutes: null,
  estimatedMinutes: null, feeShareCents: null,
  plannedServices: [], actualServices: [],
  notes: null, completedAt: '2026-05-01T12:00:00Z',
  payment: EMPTY_PAYMENT, ...overrides,
});

const entry = (overrides: Partial<ManualHistoryEntry> = {}): ManualHistoryEntry => ({
  id: 'e', clientId: 'c', date: '2026-04-15',
  notes: null, services: [], payment: EMPTY_PAYMENT, ...overrides,
});

describe('computeClientOutstanding', () => {
  it('sums services + travel fees across unpaid completed stops', () => {
    const r = computeClientOutstanding({
      completedStops: [
        { ...stop({ actualServices: [svc(2, 1500)] }), travelFeeCents: 1000 }, // 30€ + 10€
        { ...stop({ id: 's2', actualServices: [svc(1, 1000)],
                    payment: { ...EMPTY_PAYMENT, isPaid: true, paidAt: 'x' } }), travelFeeCents: 500 },
      ],
      manualEntries: [],
    });
    expect(r.unpaidCents).toBe(4000);
    expect(r.unpaidCount).toBe(1);
  });

  it('treats null travelFeeCents as 0', () => {
    const r = computeClientOutstanding({
      completedStops: [{ ...stop({ actualServices: [svc(2, 1500)] }), travelFeeCents: null }],
      manualEntries: [],
    });
    expect(r.unpaidCents).toBe(3000);
  });

  it('uses plannedServices when actualServices is null', () => {
    const r = computeClientOutstanding({
      completedStops: [{ ...stop({ plannedServices: [svc(1, 2000)], actualServices: null }), travelFeeCents: null }],
      manualEntries: [],
    });
    expect(r.unpaidCents).toBe(2000);
  });

  it('includes unpaid manual entries with travel fees', () => {
    const r = computeClientOutstanding({
      completedStops: [],
      manualEntries: [{ ...entry({ services: [svc(1, 4000)] }), travelFeeCents: 1500 }],
    });
    expect(r.unpaidCents).toBe(5500);
    expect(r.unpaidCount).toBe(1);
  });

  it('ignores zero-quantity service lines', () => {
    const r = computeClientOutstanding({
      completedStops: [{ ...stop({ actualServices: [svc(0, 1000), svc(2, 500)] }), travelFeeCents: null }],
      manualEntries: [],
    });
    expect(r.unpaidCents).toBe(1000);
  });

  it('returns zero when nothing is outstanding', () => {
    expect(
      computeClientOutstanding({ completedStops: [], manualEntries: [] })
    ).toEqual({ unpaidCents: 0, unpaidCount: 0 });
  });
});
```

- [ ] **Step 2: Run the test, confirm fail**

Run: `pnpm test:domain compute-client-outstanding`
Expected: FAIL — input shape doesn't have `travelFeeCents` in the use case.

- [ ] **Step 3: Update the use case**

Edit `src/domain/use-cases/compute-client-outstanding.ts`:

```ts
import type { TourStop } from '@/domain/models/tour-stop';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
import type { TourStopService } from '@/domain/models/tour-stop-service';

export interface ClientOutstanding {
  unpaidCents: number;
  unpaidCount: number;
}

function sumServices(services: TourStopService[]): number {
  let total = 0;
  for (const s of services) {
    if (s.qty <= 0) continue;
    total += s.qty * s.priceCentsSnapshot;
  }
  return total;
}

interface CompletedStopInput extends TourStop {
  travelFeeCents: number | null;
}

interface ManualEntryInput extends ManualHistoryEntry {
  travelFeeCents: number | null;
}

export function computeClientOutstanding(args: {
  completedStops: CompletedStopInput[];
  manualEntries: ManualEntryInput[];
}): ClientOutstanding {
  let cents = 0;
  let count = 0;
  for (const stop of args.completedStops) {
    if (stop.payment.isPaid) continue;
    const services = stop.actualServices ?? stop.plannedServices;
    cents += sumServices(services) + (stop.travelFeeCents ?? 0);
    count += 1;
  }
  for (const entry of args.manualEntries) {
    if (entry.payment.isPaid) continue;
    cents += sumServices(entry.services) + (entry.travelFeeCents ?? 0);
    count += 1;
  }
  return { unpaidCents: cents, unpaidCount: count };
}
```

- [ ] **Step 4: Run the test, confirm pass**

Run: `pnpm test:domain compute-client-outstanding`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/domain/use-cases/compute-client-outstanding.ts tests/domain/use-cases/compute-client-outstanding.test.ts
git commit -m "feat(outstanding): include travel fees in unpaid amount"
```

---

### Task 6: Update `compute-tour-kpis` to compute & include travel fees

The use case loses `totalTravelFeeCents` from input and gains `travelFeeCentsByStop` (or just per-stop in `stops`). `revenueCents` now includes travel fees.

**Files:**
- Modify: `src/domain/use-cases/compute-tour-kpis.ts`
- Modify: `tests/domain/use-cases/compute-tour-kpis.test.ts`

- [ ] **Step 1: Update the test**

Replace `tests/domain/use-cases/compute-tour-kpis.test.ts` with:

```ts
import { describe, it, expect } from 'vitest';
import { computeTourKpis } from '@/domain/use-cases/compute-tour-kpis';
import type { TourStopService } from '@/domain/models/tour-stop-service';

const ps = (over: Partial<TourStopService>): TourStopService => ({
  serviceId: 'shearing', qty: 1,
  nameSnapshot: 'Tonte', priceCentsSnapshot: 0, minutesSnapshot: 0,
  categoryIdSnapshot: null, categoryNameSnapshot: null, speciesNameSnapshot: null,
  ...over,
});

describe('computeTourKpis', () => {
  it('zeros for an empty tour', () => {
    expect(
      computeTourKpis({
        stops: [],
        totalDistanceKm: 0,
        totalDriveSeconds: 0,
        animalCountsByClient: new Map(),
      })
    ).toEqual({
      stopCount: 0,
      animalsTotal: 0,
      revenueCents: 0,
      durationMinutes: 0,
      driveMinutes: 0,
      travelFeeCents: 0,
      distanceKm: 0,
      serviceAggregates: [],
    });
  });

  it('aggregates services + per-stop travel fees, includes fees in revenue', () => {
    const r = computeTourKpis({
      stops: [
        { clientId: 'c1', plannedServices: [ps({ qty: 5, priceCentsSnapshot: 800, minutesSnapshot: 20 })], travelFeeCents: 1500 },
        { clientId: 'c2', plannedServices: [ps({ qty: 3, priceCentsSnapshot: 800, minutesSnapshot: 20 })], travelFeeCents: null },
      ],
      totalDistanceKm: 25,
      totalDriveSeconds: 1800,
      animalCountsByClient: new Map([
        ['c1', 5],
        ['c2', 3],
      ]),
    });
    expect(r.stopCount).toBe(2);
    expect(r.animalsTotal).toBe(8);
    // services: 8 * 800 = 6400 ; fees: 1500 ; revenue includes both => 7900
    expect(r.revenueCents).toBe(7900);
    expect(r.travelFeeCents).toBe(1500);
    expect(r.distanceKm).toBe(25);
    expect(r.driveMinutes).toBe(30);
    expect(r.durationMinutes).toBe(30 + 8 * 20);
    expect(r.serviceAggregates).toHaveLength(1);
    expect(r.serviceAggregates[0]?.totalQty).toBe(8);
  });
});
```

- [ ] **Step 2: Run the test, confirm fail**

Run: `pnpm test:domain compute-tour-kpis`
Expected: FAIL.

- [ ] **Step 3: Update the use case**

Edit `src/domain/use-cases/compute-tour-kpis.ts`:

```ts
import { aggregateServices, type ServiceAggregate } from './aggregate-services';
import type { TourStopService } from '@/domain/models/tour-stop-service';

interface Stop {
  clientId: string;
  plannedServices: TourStopService[];
  travelFeeCents: number | null;
}

interface Input {
  stops: Stop[];
  totalDistanceKm: number;
  totalDriveSeconds: number;
  animalCountsByClient: Map<string, number>;
}

export interface TourKpis {
  stopCount: number;
  animalsTotal: number;
  revenueCents: number;
  durationMinutes: number;
  driveMinutes: number;
  travelFeeCents: number;
  distanceKm: number;
  serviceAggregates: ServiceAggregate[];
}

export function computeTourKpis({
  stops, totalDistanceKm, totalDriveSeconds, animalCountsByClient,
}: Input): TourKpis {
  if (stops.length === 0) {
    return {
      stopCount: 0,
      animalsTotal: 0,
      revenueCents: 0,
      durationMinutes: 0,
      driveMinutes: 0,
      travelFeeCents: 0,
      distanceKm: 0,
      serviceAggregates: [],
    };
  }
  const aggregates = aggregateServices(stops.map((s) => s.plannedServices));
  const servicesRevenue = aggregates.reduce((s, a) => s + a.totalRevenueCents, 0);
  const travelFeeCents = stops.reduce((s, st) => s + (st.travelFeeCents ?? 0), 0);
  const serviceMinutes = aggregates.reduce((s, a) => s + a.totalMinutes, 0);
  const driveMinutes = Math.round(totalDriveSeconds / 60);
  const animalsTotal = stops.reduce((s, stop) => s + (animalCountsByClient.get(stop.clientId) ?? 0), 0);
  return {
    stopCount: stops.length,
    animalsTotal,
    revenueCents: servicesRevenue + travelFeeCents,
    durationMinutes: driveMinutes + serviceMinutes,
    driveMinutes,
    travelFeeCents,
    distanceKm: totalDistanceKm,
    serviceAggregates: aggregates,
  };
}
```

- [ ] **Step 4: Run the test, confirm pass**

Run: `pnpm test:domain compute-tour-kpis`
Expected: PASS.

Note: this change BREAKS callers in `src/state/queries/kpis.ts` that pass `totalTravelFeeCents`. We will fix those in Phase 3 — `pnpm typecheck` will fail until then. Don't run typecheck yet; commit and continue.

- [ ] **Step 5: Commit**

```bash
git add src/domain/use-cases/compute-tour-kpis.ts tests/domain/use-cases/compute-tour-kpis.test.ts
git commit -m "feat(tour-kpis): compute travel fees from stops, include in revenue"
```

---

## Phase 2 — Schema & persistence

Phase 2 changes the DB schema, the Zod models, the repos, and the backup snapshot. After this phase the codebase will not typecheck because state queries still pass old fields — Phase 3 reconnects everything.

### Task 7: Update Drizzle schema

**Files:**
- Modify: `src/infra/db/schema.ts`

- [ ] **Step 1: Apply edits**

In `src/infra/db/schema.ts`:

1. Inside `tours` (lines 75-93), **remove** the line:
   ```ts
   totalTravelFeeCents: integer('total_travel_fee_cents'),
   ```

2. Inside `tourStops` (lines 95-121), **rename** `feeShareCents` to `travelFeeCents` and the column name from `'fee_share_cents'` to `'travel_fee_cents'`:
   ```ts
   travelFeeCents: integer('travel_fee_cents'),
   ```

3. Inside `manualHistoryEntries` (lines 123-140), **add** above `paymentMethodId`:
   ```ts
   travelFeeCents: integer('travel_fee_cents'),
   ```

- [ ] **Step 2: Commit**

Don't typecheck — many call sites are still on the old names. Continue.

```bash
git add src/infra/db/schema.ts
git commit -m "refactor(db-schema): rename feeShareCents->travelFeeCents, drop tour total, add manual entry fee"
```

---

### Task 8: Hand-write migration `0004_travel_fees_rework.sql`

We hand-write because (1) drizzle-kit prompts interactively for renames/drops, and (2) prior migrations (`0001`, `0002`) follow this exact pattern.

**Files:**
- Create: `src/infra/db/migrations/0004_travel_fees_rework.sql`
- Modify: `src/infra/db/migrations/meta/_journal.json`

- [ ] **Step 1: Write the SQL**

Create `src/infra/db/migrations/0004_travel_fees_rework.sql`:

```sql
-- 0004 migration: travel fees rework.
-- - Rename tour_stops.fee_share_cents -> travel_fee_cents (preserve values).
-- - Drop tours.total_travel_fee_cents (now derived from stops).
-- - Add manual_history_entries.travel_fee_cents (nullable).
-- Hand-written because drizzle-kit prompts interactively for renames/drops.

PRAGMA foreign_keys=OFF;
--> statement-breakpoint

-- =============================================================
-- tour_stops: rename fee_share_cents -> travel_fee_cents.
-- =============================================================

ALTER TABLE `tour_stops` RENAME COLUMN `fee_share_cents` TO `travel_fee_cents`;
--> statement-breakpoint

-- =============================================================
-- tours: drop total_travel_fee_cents (derived from stops now).
-- SQLite supports DROP COLUMN since 3.35; expo-sqlite ships >= 3.45.
-- =============================================================

ALTER TABLE `tours` DROP COLUMN `total_travel_fee_cents`;
--> statement-breakpoint

-- =============================================================
-- manual_history_entries: add nullable travel_fee_cents.
-- =============================================================

ALTER TABLE `manual_history_entries` ADD COLUMN `travel_fee_cents` integer;
--> statement-breakpoint

PRAGMA foreign_keys=ON;
```

- [ ] **Step 2: Append to the journal**

Edit `src/infra/db/migrations/meta/_journal.json`. Add a 5th entry (idx: 4) with a stable timestamp greater than `0003`:

```json
{
  "version": "7",
  "dialect": "sqlite",
  "entries": [
    { "idx": 0, "version": "6", "when": 1777802693393, "tag": "0000_last_madripoor", "breakpoints": true },
    { "idx": 1, "version": "6", "when": 1746230400000, "tag": "0001_r1_flutter_parity", "breakpoints": true },
    { "idx": 2, "version": "6", "when": 1746316800000, "tag": "0002_rename_prestations_to_services", "breakpoints": true },
    { "idx": 3, "version": "6", "when": 1778025600000, "tag": "0003_payment_methods", "breakpoints": true },
    { "idx": 4, "version": "6", "when": 1778457600000, "tag": "0004_travel_fees_rework", "breakpoints": true }
  ]
}
```

- [ ] **Step 3: Bundle migrations**

Run: `pnpm db:bundle`
Expected: rewrites `src/infra/db/migrations/migrations.js` to include `m0004` and updates the journal. Verify the file mentions `0004_travel_fees_rework` and the new SQL.

- [ ] **Step 4: Commit**

```bash
git add src/infra/db/migrations/0004_travel_fees_rework.sql src/infra/db/migrations/meta/_journal.json src/infra/db/migrations/migrations.js
git commit -m "feat(db): migration 0004 travel fees rework"
```

---

### Task 9: Update Zod models

**Files:**
- Modify: `src/domain/models/tour.ts`
- Modify: `src/domain/models/tour-stop.ts`
- Modify: `src/domain/models/manual-history-entry.ts`

- [ ] **Step 1: `Tour` — drop `totalTravelFeeCents`**

In `src/domain/models/tour.ts`, remove line 18 (`totalTravelFeeCents: z.number().int().nullable(),`).

- [ ] **Step 2: `TourStop` — rename property**

In `src/domain/models/tour-stop.ts` line 14, change `feeShareCents` to `travelFeeCents`:

```ts
travelFeeCents: z.number().int().nullable(),
```

- [ ] **Step 3: `ManualHistoryEntry` — add field**

In `src/domain/models/manual-history-entry.ts`, add `travelFeeCents` to the schema:

```ts
import { z } from 'zod';
import { TourStopService } from './tour-stop-service';
import { Payment } from './payment';

export const ManualHistoryEntry = z.object({
  id: z.string(),
  clientId: z.string(),
  date: z.string(),
  notes: z.string().nullable(),
  services: z.array(TourStopService),
  travelFeeCents: z.number().int().nullable(),
  payment: Payment,
});

export type ManualHistoryEntry = z.infer<typeof ManualHistoryEntry>;
```

- [ ] **Step 4: Commit**

```bash
git add src/domain/models/tour.ts src/domain/models/tour-stop.ts src/domain/models/manual-history-entry.ts
git commit -m "refactor(models): rename feeShareCents, drop tour total, add manual entry fee"
```

---

### Task 10: Update `tour-repository`

**Files:**
- Modify: `src/data/repositories/tour-repository.ts`

- [ ] **Step 1: Apply edits**

In `src/data/repositories/tour-repository.ts`:

1. In `TourRow` interface (line 8-26), **remove** `totalTravelFeeCents: number | null;`.
2. In `TourStopRow` interface (line 28-46), **rename** `feeShareCents: number | null;` → `travelFeeCents: number | null;`.
3. In `stopToRow` (line 52-72), replace `feeShareCents: s.feeShareCents,` with `travelFeeCents: s.travelFeeCents,`.
4. In `stopFromRow` (line 74-96), replace `feeShareCents: r.feeShareCents,` with `travelFeeCents: r.travelFeeCents,`.

Drizzle infers types directly from the schema — when Drizzle returns rows, the property name follows the JS-side definition (now `travelFeeCents`). The cast `as TourStopRow` keeps the explicit shape.

Since `tours` no longer has `totalTravelFeeCents`, the cast `r as TourRow` will mismatch if `TourRow` still has the field. Make sure both schema and `TourRow` are in sync.

- [ ] **Step 2: Commit**

```bash
git add src/data/repositories/tour-repository.ts
git commit -m "refactor(tour-repo): rename feeShareCents, drop tour travel fee total"
```

---

### Task 11: Update `manual-history-repository` + tests

**Files:**
- Modify: `src/data/repositories/manual-history-repository.ts`
- Modify: `tests/data/manual-history-repository.test.ts`

- [ ] **Step 1: Add a failing test**

In `tests/data/manual-history-repository.test.ts`, add a new test inside the existing top-level describe (or a new one):

```ts
describe('ManualHistoryRepository travel fee round-trip', () => {
  it('persists and reads back travelFeeCents', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new ManualHistoryRepository(db);
    await repo.upsert({
      id: 'e1', clientId: 'c1', date: '2026-04-15',
      notes: null, services: [], travelFeeCents: 1500,
      payment: EMPTY_PAYMENT,
    });
    const all = await repo.listByClient('c1');
    expect(all[0]!.travelFeeCents).toBe(1500);
    close();
  });

  it('persists null travelFeeCents', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new ManualHistoryRepository(db);
    await repo.upsert({
      id: 'e2', clientId: 'c1', date: '2026-04-16',
      notes: null, services: [], travelFeeCents: null,
      payment: EMPTY_PAYMENT,
    });
    const all = await repo.listByClient('c1');
    expect(all[0]!.travelFeeCents).toBeNull();
    close();
  });
});
```

Also adapt all existing `repo.upsert({...})` calls in this file to add `travelFeeCents: null` in the object — otherwise Zod parsing will fail. Search and update.

- [ ] **Step 2: Run jest, confirm new tests fail**

Run: `pnpm test:integration manual-history-repository`
Expected: FAIL (column doesn't exist OR property not handled).

- [ ] **Step 3: Update the repo**

Edit `src/data/repositories/manual-history-repository.ts`:

1. In `ManualHistoryRow`, add `travelFeeCents: number | null;`.
2. In `toRow`, add `travelFeeCents: e.travelFeeCents,`.
3. In `fromRow`, add `travelFeeCents: r.travelFeeCents,` to the parsed object.

Final shape:

```ts
interface ManualHistoryRow {
  id: string;
  clientId: string;
  date: string;
  notes: string | null;
  services: string;
  travelFeeCents: number | null;
  paymentMethodId: string | null;
  paymentMethodLabelSnapshot: string | null;
  isPaid: number;
  paidAt: string | null;
}

function toRow(e: ManualHistoryEntry) {
  return {
    id: e.id,
    clientId: e.clientId,
    date: e.date,
    notes: e.notes,
    services: JSON.stringify(e.services),
    travelFeeCents: e.travelFeeCents,
    paymentMethodId: e.payment.methodId,
    paymentMethodLabelSnapshot: e.payment.methodLabelSnapshot,
    isPaid: e.payment.isPaid ? 1 : 0,
    paidAt: e.payment.paidAt,
  };
}

function fromRow(r: ManualHistoryRow): ManualHistoryEntry {
  return ManualHistoryEntry.parse({
    id: r.id,
    clientId: r.clientId,
    date: r.date,
    notes: r.notes,
    services: JSON.parse(r.services),
    travelFeeCents: r.travelFeeCents,
    payment: {
      methodId: r.paymentMethodId,
      methodLabelSnapshot: r.paymentMethodLabelSnapshot,
      isPaid: r.isPaid === 1,
      paidAt: r.paidAt,
    },
  });
}
```

- [ ] **Step 4: Run jest, confirm pass**

Run: `pnpm test:integration manual-history-repository`
Expected: PASS, including the new round-trip cases.

- [ ] **Step 5: Commit**

```bash
git add src/data/repositories/manual-history-repository.ts tests/data/manual-history-repository.test.ts
git commit -m "feat(manual-history-repo): add travelFeeCents round-trip"
```

---

### Task 12: Update backup schema

**Files:**
- Modify: `src/infra/cloud/backup-schema.ts`

- [ ] **Step 1: Apply edits**

In `src/infra/cloud/backup-schema.ts`:

1. In `TourRow` (lines 59-77), **remove** `totalTravelFeeCents: optInt,`.
2. In `TourStopRow` (lines 79-93), **rename** `feeShareCents: optInt,` → `travelFeeCents: optInt,`.
3. In `ManualHistoryEntryRow` (lines 95-101), add `travelFeeCents: optInt,` before the closing brace.

Leave `schemaVersion: z.literal(2)` unchanged — backward compat with older backups is **out of scope per spec section 10**. The team will handle versioning in a follow-up.

- [ ] **Step 2: Commit**

```bash
git add src/infra/cloud/backup-schema.ts
git commit -m "refactor(backup-schema): mirror travel-fee schema changes"
```

---

## Phase 3 — State queries

Reconnect mutations & queries with the new shapes.

### Task 13: Update `useUpsertTour` and tour-draft submit shape

**Files:**
- Modify: `src/state/queries/tours.ts`

- [ ] **Step 1: Apply edits**

In `src/state/queries/tours.ts`:

1. In `UpsertTourStopInput` (line 37-46), **remove** `feeShareCents: number | null;`.
2. In `UpsertTourInput` (line 48-59), **remove** `totalTravelFeeCents: number | null;`.
3. Inside `useUpsertTour` mutationFn (line 61-105):
   - Remove `totalTravelFeeCents` from the `tour` object literal (delete the line at 80).
   - Remove `feeShareCents: s.feeShareCents,` from the stops mapping (line 96).
   - The new stop has no `travelFeeCents` field set (left as default `null` in DB after upsert) — but since `TourStop` Zod requires `travelFeeCents: z.number().int().nullable()`, we must set it explicitly. Add `travelFeeCents: null,` in the stop literal returned from the map (planned tours start with no fee; it's filled at completion).

Final stop literal in `useUpsertTour`:

```ts
const stops: TourStop[] = input.stops.map((s, index) => ({
  id: s.id ?? newId(),
  tourId,
  clientId: s.clientId,
  clientNameSnapshot: s.clientNameSnapshot ?? null,
  ordering: index,
  arrivalMinutes: s.arrivalMinutes,
  departureMinutes: null,
  estimatedMinutes: s.estimatedMinutes,
  travelFeeCents: null,
  plannedServices: s.plannedServices,
  actualServices: null,
  notes: s.notes,
  completedAt: null,
  payment: EMPTY_PAYMENT,
}));
```

Also adapt `tour` literal (drop `totalTravelFeeCents`).

4. Inside `useCompleteTour` mutationFn (around line 215-225), the `stops.map((s) => ({ ...s, completedAt }))` already spreads correctly — no change needed since the property name already updated. Same for `useCompleteWithBilan` (next task).

- [ ] **Step 2: Update `useCompleteWithBilan` to take `perStopTravelFees`**

In `useCompleteWithBilan`:

1. Add a `perStopTravelFees: Map<string, number>` parameter to the mutation input.
2. Forward it to `tourRepo.completeWithBilan(...)` (we'll update the repo signature in the next sub-step).

```ts
export function useCompleteWithBilan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      tourId,
      perStopActuals,
      perStopNotes,
      perStopPayments,
      perStopTravelFees,
      completedAt,
    }: {
      tourId: string;
      perStopActuals: Map<string, TourStop['plannedServices']>;
      perStopNotes: Map<string, string | null>;
      perStopPayments: Map<string, Payment>;
      perStopTravelFees: Map<string, number>;
      completedAt: string;
    }) => {
      await tourRepo.completeWithBilan(tourId, perStopActuals, perStopNotes, perStopPayments, perStopTravelFees, completedAt);
      // ...rest unchanged
```

- [ ] **Step 3: Update `tour-repository.ts` `completeWithBilan` signature**

In `src/data/repositories/tour-repository.ts`, update `completeWithBilan`:

```ts
async completeWithBilan(
  tourId: string,
  perStopActuals: Map<string, import('@/domain/models/tour-stop-service').TourStopService[]>,
  perStopNotes: Map<string, string | null>,
  perStopPayments: Map<string, Payment>,
  perStopTravelFees: Map<string, number>,
  completedAt: string
): Promise<void> {
  const result = await this.byId(tourId);
  if (!result) throw new Error('Tour introuvable');
  const { tour, stops } = result;

  const updatedStops = stops.map((s) => ({
    ...s,
    actualServices: perStopActuals.get(s.id) ?? s.plannedServices,
    notes: perStopNotes.has(s.id) ? perStopNotes.get(s.id) ?? null : s.notes,
    payment: perStopPayments.get(s.id) ?? s.payment,
    travelFeeCents: perStopTravelFees.has(s.id) ? perStopTravelFees.get(s.id)! : s.travelFeeCents,
    completedAt,
  }));

  await this.upsertTour(
    { ...tour, status: 'completed', completedAt, updatedAt: completedAt },
    updatedStops
  );
}
```

- [ ] **Step 4: Commit**

```bash
git add src/state/queries/tours.ts src/data/repositories/tour-repository.ts
git commit -m "feat(tours-state): drop fee inputs, accept perStopTravelFees at bilan"
```

---

### Task 14: Update `useUpsertManualHistoryEntry`

**Files:**
- Modify: `src/state/queries/history.ts`

- [ ] **Step 1: Apply edits**

In `src/state/queries/history.ts`:

1. In `UpsertManualHistoryInput` (line 65-72), add `travelFeeCents: number | null;`.
2. In the mutationFn (line 76-87), add `travelFeeCents: input.travelFeeCents,` in the entry literal.

```ts
export interface UpsertManualHistoryInput {
  id?: string;
  clientId: string;
  date: string;
  notes: string | null;
  services: TourStopService[];
  travelFeeCents: number | null;
  payment: Payment;
}

// inside mutationFn:
const entry: ManualHistoryEntry = {
  id: input.id ?? newId(),
  clientId: input.clientId,
  date: input.date,
  notes: input.notes,
  services: input.services,
  travelFeeCents: input.travelFeeCents,
  payment: input.payment,
};
```

3. In `useClientHistory` (line 22-55), update the mapping to pass `travelFeeCents` to `mergeClientHistory`:

```ts
const tourStopsWithDate = completed.flatMap(({ tour, stops }) =>
  stops
    .filter((s) => s.clientId === clientId)
    .map((s) => ({
      tourId: tour.id,
      stopId: s.id,
      date: tour.scheduledDate,
      services: s.actualServices ?? s.plannedServices,
      travelFeeCents: s.travelFeeCents,
      notes: s.notes,
    }))
);

// ...
return mergeClientHistory({
  tourStopsWithDate,
  manualEntries: manualEntries.map((e) => ({
    id: e.id,
    date: e.date,
    services: e.services,
    travelFeeCents: e.travelFeeCents,
    notes: e.notes,
  })),
});
```

- [ ] **Step 2: Commit**

```bash
git add src/state/queries/history.ts
git commit -m "feat(history-state): add travelFeeCents to upsert input + history merge"
```

---

### Task 15: Update `useClientKpis` and `useTourKpis`

**Files:**
- Modify: `src/state/queries/kpis.ts`

- [ ] **Step 1: Apply edits**

In `src/state/queries/kpis.ts`:

1. In `useClientKpis` (line 28-49), update the mapping to pass `travelFeeCents`:

```ts
const tourStops = completed.flatMap(({ tour, stops }) =>
  stops
    .filter((s) => s.clientId === clientId)
    .map((s) => ({
      date: tour.scheduledDate,
      services: s.actualServices ?? s.plannedServices,
      travelFeeCents: s.travelFeeCents,
    }))
);
const manualEntries = await manualRepo.listByClient(clientId);
// ...
return computeClientKpis({
  tourStops,
  manualEntries: manualEntries.map((e) => ({
    date: e.date,
    services: e.services,
    travelFeeCents: e.travelFeeCents,
  })),
  today,
});
```

2. In `useTourKpis` (line 51-77), update the call:

```ts
return computeTourKpis({
  stops: stops.map((s) => ({
    clientId: s.clientId,
    plannedServices: s.actualServices ?? s.plannedServices,
    travelFeeCents: s.travelFeeCents,
  })),
  totalDistanceKm: tour.totalDistanceKm ?? 0,
  totalDriveSeconds: tour.totalDriveSeconds ?? 0,
  animalCountsByClient,
});
```

(Drops `totalTravelFeeCents: tour.totalTravelFeeCents ?? 0,` — the tour no longer has that field.)

- [ ] **Step 2: Run typecheck**

Run: `pnpm typecheck`
Expected: still failing — UI still references old props. Continue.

- [ ] **Step 3: Commit**

```bash
git add src/state/queries/kpis.ts
git commit -m "feat(kpis-state): pass travelFeeCents to use cases"
```

---

### Task 16: Wire `useClientOutstanding` (state side)

**Files:**
- Modify: any state-side caller of `computeClientOutstanding`.

- [ ] **Step 1: Locate the caller**

Run: `pnpm exec rg -l "computeClientOutstanding\b" src/`
Expected: a query file (likely `src/state/queries/clients.ts` or similar) that builds the input from repos.

- [ ] **Step 2: Update the mapping**

Wherever the caller passes `completedStops` and `manualEntries` to `computeClientOutstanding`, ensure each item has `travelFeeCents` (already present on the model — but the use case interface uses an explicit intersection). Since `TourStop` and `ManualHistoryEntry` already have `travelFeeCents` after Phase 2, you can pass them directly without a map; the structural type matches.

If the caller already spreads `stop` objects with `...stop`, no change is needed beyond the rename of `feeShareCents` → `travelFeeCents` propagating through.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor(outstanding-state): pass travelFeeCents through to use case"
```

If no changes are needed (state side already passes whole entities), skip this commit.

---

## Phase 4 — UI

### Task 17: Add i18n keys + reword existing ones

**Files:**
- Modify: `src/i18n/locales/fr.json`

- [ ] **Step 1: Apply edits**

In `src/i18n/locales/fr.json`:

1. Inside `tours` (around line 158-280), **change**:
   - `"total_cost": "Frais kilométriques"` → `"total_cost": "Frais de déplacement (estimation)"`
   - `"cost_split": "Partage des frais"` → **remove this key** (no longer used).
   - `"stop_share": "Part"` → **remove this key** (no longer used).
   - **Add** under `tours`:
     ```json
     "bilan_travel_fee_label": "Frais de déplacement",
     "bilan_travel_fee_hint": "Montant facturé à ce client (modifiable)",
     ```

2. Inside `history.manual` (around line 364-377), **add**:
   ```json
   "travel_fee_label": "Frais de déplacement",
   "travel_fee_hint": "Optionnel — facturé en plus des prestations",
   "services_subtotal": "Prestations",
   "travel_fee_subtotal": "Frais de déplacement",
   "grand_total": "Total facturé"
   ```

3. Inside `history`, add a `total_amount` formatter if not present (used by `history-row`):
   ```json
   "total_amount": "{{value}} €"
   ```

4. Inside `settings.tour_rate` (lines 422-433), **reword**:

```json
"tour_rate": {
  "row_label": "Frais de déplacement",
  "row_hint": "Tranche de km × forfait, par client",
  "screen_title": "Frais de déplacement",
  "bracket_km_label": "Tranche (km)",
  "bracket_km_hint": "Taille d'une tranche depuis l'adresse de base",
  "fee_per_bracket_label": "Forfait par tranche (€)",
  "fee_per_bracket_hint": "Montant facturé par tranche entamée",
  "explanation": "Chaque client paie ces frais selon sa distance depuis l'adresse de base. Modifiable à la clôture de tournée.",
  "error_bracket": "Doit être un nombre positif.",
  "error_fee": "Doit être un nombre positif.",
  "save_failed": "Enregistrement impossible"
}
```

- [ ] **Step 2: Verify the JSON parses**

Run: `pnpm exec node -e "JSON.parse(require('fs').readFileSync('src/i18n/locales/fr.json','utf8'))"`
Expected: no error.

- [ ] **Step 3: Commit**

```bash
git add src/i18n/locales/fr.json
git commit -m "i18n(fr): rework travel-fee labels for per-client model"
```

---

### Task 18: Update `tour-rate.tsx` to surface the new explanation

**Files:**
- Modify: `app/(tabs)/settings/tour-rate.tsx`

- [ ] **Step 1: Apply edits**

In `app/(tabs)/settings/tour-rate.tsx`, after the `<ScreenHeader />` and before the first field, add an explanation block:

```tsx
<Text variant="muted" className="text-sm">
  {t('settings.tour_rate.explanation')}
</Text>
```

(Import `Text` from `@/ui/primitives/text` if not already there.) The two RHFTextField calls remain unchanged — only their hint text is reworded via i18n.

- [ ] **Step 2: Commit**

```bash
git add app/\(tabs\)/settings/tour-rate.tsx
git commit -m "feat(settings): explain per-client travel-fee model"
```

---

### Task 19: Update `tour-draft-editor.tsx` to compute per-client live

**Files:**
- Modify: `src/ui/components/tour-draft-editor.tsx`

- [ ] **Step 1: Apply edits**

In `src/ui/components/tour-draft-editor.tsx`:

1. **Replace** the import of `splitTravelCost`:
   ```ts
   // remove:
   import { splitTravelCost } from '@/domain/use-cases/cost-split-calculator';
   // add:
   import { computeClientTravelFee } from '@/domain/use-cases/compute-client-travel-fee';
   ```

2. **Update** the `Props.onSubmit` type (line 40-49) — drop `totalTravelFeeCents` and `feeShareCentsByClient`:
   ```ts
   onSubmit: (input: {
     scheduledDate: string;
     departureTime: string;
     status: TourStatus;
     stops: DraftStop[];
     totalDistanceKm: number;
     totalMinutes: number;
   }) => void;
   ```

3. **Replace** the `split` memo (lines 136-148) with a per-stop fee computation:

```ts
const perStopFeeCents = useMemo(() => {
  return initialStops.map((s) =>
    computeClientTravelFee({
      distanceKm: distanceKm('BASE', s.clientId),
      bracketKm,
      feePerBracket,
    })
  );
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, [initialStops, base, clients, bracketKm, feePerBracket]);

const totalFeeCents = useMemo(
  () => perStopFeeCents.reduce((s, c) => s + c, 0),
  [perStopFeeCents]
);
```

4. **Update** the `submit` function (lines 150-179) — drop `feeShareCentsByClient` and `totalTravelFeeCents`:

```ts
const submit = async () => {
  if (initialStops.length === 0) return;
  const stopsWithoutServices = initialStops.filter((s) => s.plannedServices.length === 0);
  if (stopsWithoutServices.length > 0) {
    const ok = await confirm({
      title: t('tours.no_service_warning_title'),
      message: t('tours.no_service_warning_message', { count: stopsWithoutServices.length }),
      confirmLabel: t('tours.no_service_warning_continue'),
      cancelLabel: t('common.cancel'),
    });
    if (!ok) return;
  }
  onSubmit({
    scheduledDate: format(date, 'yyyy-MM-dd'),
    departureTime: time,
    status: 'planned',
    stops: initialStops.map((s) => ({
      ...s,
      clientNameSnapshot: clientsById.get(s.clientId)?.displayName ?? null,
    })),
    totalDistanceKm,
    totalMinutes,
  });
};
```

5. **Update** the header total cost display (around line 260-263):

```tsx
<View className="flex-row justify-between mt-1">
  <Text variant="muted">{t('tours.total_cost')}</Text>
  <Text className="font-semibold">{(totalFeeCents / 100).toFixed(0)} €</Text>
</View>
```

6. **Update** the per-stop sub-line (around line 297, 314):

```ts
const stopFee = perStopFeeCents[index] ?? 0;
// ...
<Text variant="muted" className="text-xs">
  {t('tours.stop_arrival')} {arr.arrivalTime} · {formatMinutes(arr.estimatedMinutes)} · {(stopFee / 100).toFixed(0)} €
</Text>
```

(The variable name `share` was renamed to `stopFee` — semantics changed.)

- [ ] **Step 2: Commit**

```bash
git add src/ui/components/tour-draft-editor.tsx
git commit -m "feat(tour-draft): per-client travel fee, drop split logic"
```

---

### Task 20: Update tour draft submit screens

**Files:**
- Modify: `app/(tabs)/tours/new/draft.tsx`
- Modify: `app/(tabs)/tours/[id]/edit.tsx`

- [ ] **Step 1: `new/draft.tsx`**

In `app/(tabs)/tours/new/draft.tsx`, update the `upsert.mutate` payload (line 62-70):

```ts
upsert.mutate(
  {
    ...input,
    baseLat: base.lat,
    baseLng: base.lon,
    stops: input.stops.map((s) => ({
      clientId: s.clientId,
      clientNameSnapshot: s.clientNameSnapshot ?? null,
      plannedServices: s.plannedServices,
      arrivalMinutes: null,
      estimatedMinutes: null,
      notes: s.notes,
    })),
  },
  // ...
);
```

(Removes `feeShareCents`.)

- [ ] **Step 2: `[id]/edit.tsx`**

Same change as above in `app/(tabs)/tours/[id]/edit.tsx` (around line 83-91): drop the `feeShareCents` line.

- [ ] **Step 3: Commit**

```bash
git add app/\(tabs\)/tours/new/draft.tsx app/\(tabs\)/tours/\[id\]/edit.tsx
git commit -m "refactor(tour-draft-screens): drop feeShareCents from submit"
```

---

### Task 21: Add travel-fee field to `stop-completion-editor.tsx`

**Files:**
- Modify: `src/ui/components/stop-completion-editor.tsx`

- [ ] **Step 1: Apply edits**

In `src/ui/components/stop-completion-editor.tsx`:

1. Add two props to `Props`:

```ts
interface Props {
  stop: TourStop;
  client: Client | undefined;
  actuals: TourStopService[];
  note: string;
  onChangeActuals: (next: TourStopService[]) => void;
  onChangeNote: (next: string) => void;
  onAddOffPlan: () => void;
  payment: Payment;
  paymentError?: string | null;
  onChangePayment: (next: Payment) => void;
  travelFeeCents: number;
  onChangeTravelFee: (cents: number) => void;
}
```

2. Add the new field UI between the note block and `<PaymentEditor />` (after line 134):

```tsx
<View className="gap-1">
  <Text className="text-sm font-semibold">{t('tours.bilan_travel_fee_label')}</Text>
  <Input
    value={travelFeeCents === 0 ? '' : (travelFeeCents / 100).toString()}
    onChangeText={(v) => {
      if (v.trim() === '') {
        onChangeTravelFee(0);
        return;
      }
      const n = parseFloat(v.replace(',', '.'));
      if (Number.isNaN(n) || n < 0) return;
      onChangeTravelFee(Math.round(n * 100));
    }}
    keyboardType="decimal-pad"
    placeholder="0"
    accessibilityLabel={t('tours.bilan_travel_fee_label')}
  />
  <Text variant="muted" className="text-xs">{t('tours.bilan_travel_fee_hint')}</Text>
</View>
```

Add the props in the destructured args, and update the call sites (next task).

- [ ] **Step 2: Commit**

```bash
git add src/ui/components/stop-completion-editor.tsx
git commit -m "feat(bilan): add per-stop travel fee field"
```

---

### Task 22: Wire `complete.tsx` (bilan screen) for travel fees

**Files:**
- Modify: `app/(tabs)/tours/[id]/complete.tsx`

- [ ] **Step 1: Add state + default initialization**

In `app/(tabs)/tours/[id]/complete.tsx`, add a state map and an init helper. Place them alongside the existing `perStopActuals` state (line 69-72):

```tsx
import { useEffect } from 'react';
// ...
import { computeClientTravelFee } from '@/domain/use-cases/compute-client-travel-fee';
import { resolveBaseDistance } from '@/domain/use-cases/resolve-base-distance';
import { DistanceMatrixRepository } from '@/data/repositories/distance-matrix-repository';
import { db } from '@/infra/db/client';
import { useAllSettings } from '@/state/queries/settings';

const distanceMatrixRepo = new DistanceMatrixRepository(db);
const DEFAULT_BRACKET_KM = 10;
const DEFAULT_FEE_PER_BRACKET = 8;

// Inside component, alongside other state:
const [perStopTravelFees, setPerStopTravelFees] = useState<Record<string, number>>({});
const { data: allSettings } = useAllSettings();
const bracketKm = parseFloat(allSettings?.tour_bracket_km ?? '') || DEFAULT_BRACKET_KM;
const feePerBracket = parseFloat(allSettings?.tour_fee_eur_per_bracket ?? '') || DEFAULT_FEE_PER_BRACKET;
```

Initialize the map once when the tour and clients are loaded. Add this `useEffect`:

```tsx
useEffect(() => {
  if (!data) return;
  if (Object.keys(perStopTravelFees).length > 0) return;
  let cancelled = false;
  (async () => {
    const next: Record<string, number> = {};
    for (const stop of data.stops) {
      // If the stop already has a stored fee (e.g. tour was reopened), reuse it.
      if (stop.travelFeeCents !== null) {
        next[stop.id] = stop.travelFeeCents;
        continue;
      }
      const client = clientsById.get(stop.clientId);
      const cached = await distanceMatrixRepo.byPair('BASE', stop.clientId);
      const distanceKm = resolveBaseDistance({
        base: { lat: data.tour.baseLat, lon: data.tour.baseLng },
        client: client?.latitude != null && client?.longitude != null
          ? { lat: client.latitude, lon: client.longitude }
          : null,
        lookup: () => cached ? { distanceKm: cached.distanceKm, failed: cached.failed } : null,
      });
      next[stop.id] = computeClientTravelFee({ distanceKm, bracketKm, feePerBracket });
    }
    if (!cancelled) setPerStopTravelFees(next);
  })();
  return () => { cancelled = true; };
  // eslint-disable-next-line react-hooks/exhaustive-deps
}, [data?.tour.id, clientsById, bracketKm, feePerBracket]);
```

- [ ] **Step 2: Wire helpers and KPIs**

Add accessors (next to other helpers around line 80-95):

```tsx
const getTravelFee = (stopId: string) => perStopTravelFees[stopId] ?? 0;
const setTravelFee = (stopId: string, cents: number) =>
  setPerStopTravelFees((prev) => ({ ...prev, [stopId]: cents }));
```

Update the live KPI (line 121-143):

```tsx
const feeCents = Object.values(perStopTravelFees).reduce((s, c) => s + c, 0);
let actualMinutes = 0;
let actualRevenueCents = 0;
let plannedRevenueCents = 0;
let stopsValidated = 0;

for (const stop of stops) {
  const actuals = getActuals(stop.id, stop.plannedServices);
  let stopHasAny = false;
  for (const a of actuals) {
    if (a.qty <= 0) continue;
    stopHasAny = true;
    actualMinutes += a.qty * a.minutesSnapshot;
    actualRevenueCents += a.qty * a.priceCentsSnapshot;
  }
  if (stopHasAny) stopsValidated += 1;
  for (const p of stop.plannedServices) {
    plannedRevenueCents += p.qty * p.priceCentsSnapshot;
  }
}

const totalActualRevenue = actualRevenueCents + feeCents;
```

(Logic identical to existing — only `feeCents` changes source.)

- [ ] **Step 3: Pass per-stop fee to `StopCompletionEditor`**

Inside the `stops.map(...)` JSX block (around line 244-258), pass the new props:

```tsx
{stops.map((stop) => (
  <StopCompletionEditor
    key={stop.id}
    stop={stop}
    client={clientsById.get(stop.clientId)}
    actuals={getActuals(stop.id, stop.plannedServices)}
    note={getNote(stop.id)}
    onChangeActuals={(next) => setActuals(stop.id, next)}
    onChangeNote={(next) => setNote(stop.id, next)}
    onAddOffPlan={() => setOffPlanForStopId(stop.id)}
    payment={getPayment(stop.id, stop.payment)}
    paymentError={perStopPaymentErrors[stop.id] ?? null}
    onChangePayment={(next) => setPayment(stop.id, next)}
    travelFeeCents={getTravelFee(stop.id)}
    onChangeTravelFee={(cents) => setTravelFee(stop.id, cents)}
  />
))}
```

- [ ] **Step 4: Build and pass the travel-fee map in the mutation**

Inside `onConfirm` (around line 176-203), build and pass the map:

```tsx
const actualsMap = new Map<string, TourStopService[]>();
const notesMap = new Map<string, string | null>();
const paymentsMap = new Map<string, Payment>();
const travelFeesMap = new Map<string, number>();
for (const stop of stops) {
  actualsMap.set(stop.id, getActuals(stop.id, stop.plannedServices));
  const trimmed = getNote(stop.id).trim();
  notesMap.set(stop.id, trimmed.length === 0 ? null : trimmed);
  paymentsMap.set(stop.id, getPayment(stop.id, stop.payment));
  travelFeesMap.set(stop.id, getTravelFee(stop.id));
}
complete.mutate(
  {
    tourId: tour.id,
    perStopActuals: actualsMap,
    perStopNotes: notesMap,
    perStopPayments: paymentsMap,
    perStopTravelFees: travelFeesMap,
    completedAt: new Date().toISOString(),
  },
  // ...
);
```

- [ ] **Step 5: Commit**

```bash
git add app/\(tabs\)/tours/\[id\]/complete.tsx
git commit -m "feat(bilan): per-stop travel fee state, default from formula"
```

---

### Task 23: Add travel-fee field to `manual-history-form.tsx`

**Files:**
- Modify: `src/ui/components/manual-history-form.tsx`

- [ ] **Step 1: Apply edits**

In `src/ui/components/manual-history-form.tsx`:

1. Add state for the fee:

```tsx
const [travelFeeCents, setTravelFeeCents] = useState<number>(initial?.travelFeeCents ?? 0);
```

2. Update the `onValid` submit to send `travelFeeCents`:

```ts
onSubmit({
  id: initial?.id,
  clientId,
  date: format(values.date, 'yyyy-MM-dd'),
  notes: values.notes.trim() || null,
  services,
  travelFeeCents: travelFeeCents > 0 ? travelFeeCents : null,
  payment,
});
```

3. **Replace** the existing total surface block (the one rendering services list + `history.manual.total`) with a breakdown:

```tsx
<FormField label={t('history.manual.services')}>
  <Surface variant="muted" className="rounded-2xl p-3 gap-2">
    {services.length === 0 ? (
      <Text variant="muted" className="text-sm">{t('history.manual.no_services')}</Text>
    ) : (
      services.map((s) => (
        <View key={s.serviceId} className="flex-row items-center justify-between">
          <Text className="text-sm flex-1">
            {s.nameSnapshot} × {s.qty}
          </Text>
          <Text className="text-sm font-medium">
            {((s.qty * s.priceCentsSnapshot) / 100).toFixed(2)} €
          </Text>
        </View>
      ))
    )}
    <View className="flex-row items-center justify-between pt-2 border-t border-border dark:border-border-dark">
      <Text className="text-sm font-medium">{t('history.manual.services_subtotal')}</Text>
      <Text className="text-sm font-medium">{(totalCents / 100).toFixed(2)} €</Text>
    </View>
    {travelFeeCents > 0 ? (
      <View className="flex-row items-center justify-between">
        <Text className="text-sm font-medium">{t('history.manual.travel_fee_subtotal')}</Text>
        <Text className="text-sm font-medium">{(travelFeeCents / 100).toFixed(2)} €</Text>
      </View>
    ) : null}
    <View className="flex-row items-center justify-between pt-2 border-t border-border dark:border-border-dark">
      <Text className="text-sm font-semibold">{t('history.manual.grand_total')}</Text>
      <Text className="text-base font-semibold">{((totalCents + travelFeeCents) / 100).toFixed(2)} €</Text>
    </View>
    <Button variant="secondary" onPress={() => setPickerOpen(true)}>
      {services.length === 0 ? t('history.manual.add_services') : t('history.manual.edit_services')}
    </Button>
  </Surface>
</FormField>
```

4. **Add** a new field BETWEEN the services FormField and `<PaymentEditor />`:

```tsx
<FormField label={t('history.manual.travel_fee_label')} hint={t('history.manual.travel_fee_hint')}>
  <Input
    value={travelFeeCents === 0 ? '' : (travelFeeCents / 100).toString()}
    onChangeText={(v) => {
      if (v.trim() === '') {
        setTravelFeeCents(0);
        return;
      }
      const n = parseFloat(v.replace(',', '.'));
      if (Number.isNaN(n) || n < 0) return;
      setTravelFeeCents(Math.round(n * 100));
    }}
    keyboardType="decimal-pad"
    placeholder="0"
    accessibilityLabel={t('history.manual.travel_fee_label')}
  />
</FormField>
```

(Add `import { Input } from '@/ui/primitives/input';` if not already imported.)

Note: `FormField` may not accept a `hint` prop. If it doesn't, render the hint as a `<Text variant="muted" className="text-xs">` below the `<Input>` instead — check the `FormField` source to confirm.

- [ ] **Step 2: Commit**

```bash
git add src/ui/components/manual-history-form.tsx
git commit -m "feat(manual-history): optional travel fee field with breakdown"
```

---

### Task 24: Display total amount in `history-row.tsx`

**Files:**
- Modify: `src/ui/components/history-row.tsx`

- [ ] **Step 1: Apply edits**

Currently the row shows date + notes + source pill. Add a total amount on the right (services + travelFeeCents). The `Intervention` now carries `services` and `travelFeeCents`.

Replace the closing block of the row (lines 56-62) with one that shows the amount before the chevron:

```tsx
import { sumServiceRevenue } from '@/lib/sum-service-revenue';

// ...

const servicesCents = entry.services.reduce(
  (sum, s) => sum + (s.qty > 0 ? s.qty * s.priceCentsSnapshot : 0),
  0
);
const totalCents = servicesCents + (entry.travelFeeCents ?? 0);

return (
  <PressScale ... >
    <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3">
      <View className="flex-1">
        {/* existing content unchanged */}
      </View>
      {totalCents > 0 ? (
        <Text className="text-sm font-semibold">
          {(totalCents / 100).toFixed(0)} €
        </Text>
      ) : null}
      {entry.source === 'manual' ? (
        <Pencil size={16} color="#5C4E40" />
      ) : (
        <ChevronRight size={18} color="#5C4E40" />
      )}
    </Surface>
  </PressScale>
);
```

(Skip the `sumServiceRevenue` import line above — that helper doesn't exist; compute inline as shown.)

- [ ] **Step 2: Commit**

```bash
git add src/ui/components/history-row.tsx
git commit -m "feat(history-row): display total amount (services + travel fee)"
```

---

## Phase 5 — Cleanup & verification

### Task 25: Delete `cost-split-calculator` and its test

**Files:**
- Delete: `src/domain/use-cases/cost-split-calculator.ts`
- Delete: `tests/domain/use-cases/cost-split-calculator.test.ts` (if present)

- [ ] **Step 1: Confirm no references remain**

Run: `pnpm exec rg "splitTravelCost|cost-split-calculator" src/ app/ tests/`
Expected: no matches.

- [ ] **Step 2: Delete the files**

```bash
rm src/domain/use-cases/cost-split-calculator.ts
rm tests/domain/use-cases/cost-split-calculator.test.ts 2>/dev/null || true
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove obsolete cost-split-calculator"
```

---

### Task 26: End-to-end verification

- [ ] **Step 1: Typecheck**

Run: `pnpm typecheck`
Expected: PASS, zero errors. If errors remain, fix them — the fix is most likely a missed `feeShareCents` → `travelFeeCents` rename or a missing `travelFeeCents: null` literal in a `TourStop` / `ManualHistoryEntry` constructor.

- [ ] **Step 2: Lint**

Run: `pnpm lint`
Expected: PASS.

- [ ] **Step 3: Tests**

Run: `pnpm test`
Expected: ALL pass (vitest domain + jest data/infra).

- [ ] **Step 4: Manual smoke (DB)**

The user must run the app on a physical device (or simulator) at least once after this plan lands so migration `0004` runs against their actual DB. The plan does not automate this — flag it as a follow-up:

> Migration runs at app boot via `src/infra/db/bootstrap.ts`. After install, open the app and:
> - create a tour, plan it, complete it: per-stop travel fee field shows pre-filled, modifiable.
> - open a client's history: tour-stop and manual-entry rows show a total amount on the right; CA and outstanding KPIs include the fees.
> - create a manual entry with a travel fee: the field is optional; the breakdown shows services + frais + total.
> - settings > frais de déplacement: labels reflect the per-client model.

- [ ] **Step 5: Commit any final fixes**

If typecheck/lint produced patches:

```bash
git add -A
git commit -m "fix: post-rework typecheck and lint cleanups"
```

---

## Self-review checklist

This was checked when writing the plan. Re-run if you discover gaps:

- **Spec § 3 formula:** Task 1 (computeClientTravelFee with ceil + cents).
- **Spec § 3 distance source:** Task 2 (resolve-base-distance) + Task 22 (caller wires the cache).
- **Spec § 4.1 schema:** Task 7 + Task 8 (migration).
- **Spec § 4.2 Zod models:** Task 9.
- **Spec § 4.3 backfill:** Migration in Task 8 uses `RENAME COLUMN` (preserves values) and `ADD COLUMN` defaulting to NULL.
- **Spec § 4.4 backup schema:** Task 12.
- **Spec § 5.1 new use case:** Task 1.
- **Spec § 5.2 distance helper:** Task 2.
- **Spec § 5.3 deletions:** Task 25.
- **Spec § 5.4 KPIs/outstanding:** Tasks 4, 5, 6.
- **Spec § 6.1 planification:** Task 19 + Task 20.
- **Spec § 6.2 bilan:** Tasks 21, 22.
- **Spec § 6.3 manual entry form:** Task 23.
- **Spec § 6.4 history list/detail:** Task 24 (list) + Task 23 covers the detail breakdown (the manual-history-form IS the detail screen).
- **Spec § 6.5 paiement/outstanding:** Task 5 (single isPaid covers services+fees).
- **Spec § 7 settings:** Tasks 17, 18.
- **Spec § 8 i18n:** Task 17.
- **Spec § 9 tests:** Tasks 1, 2, 4, 5, 6, 11.

Type consistency check: `travelFeeCents` is consistently used across schema, models, repos, queries, use cases, and UI props. The mutation key in `useCompleteWithBilan` is `perStopTravelFees` (plural) — matches Task 13/22.
