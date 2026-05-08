# Tour drafts — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permettre la création de tournées en mode "brouillon" sans date, leur ajout incrémental de clients, puis leur planification ultérieure via une sheet date+time.

**Architecture:** Étendre le modèle `Tour` (nouveau status `'draft'`, `scheduledDate`/`departureTime` nullable, nouvelle colonne `title`). Migration Drizzle hand-écrite (SQLite ne sait pas drop `NOT NULL` directement). Découper `useUpsertTour` en deux hooks (`useSaveDraft` / `useScheduleTour`) pour empêcher au compile-time la création d'une planifiée sans date. Ajouter un troisième filtre dans la liste Tournées.

**Tech Stack:** Expo + React Native, expo-router, Drizzle ORM (SQLite), Zustand (`tour-draft-store`), TanStack Query, Zod, Vitest, i18next (locale unique `fr.json`).

**Spec:** `docs/superpowers/specs/2026-05-08-tour-drafts-design.md`

**Pre-flight (run once before starting):**

```bash
pnpm typecheck && pnpm lint && pnpm vitest run && pnpm jest --testPathPattern="tests/(data|infra|ui)/"
```

Tout doit être vert avant de commencer. Si rouge, corriger sur main d'abord.

---

## File map

| Path | Action | Purpose |
|------|--------|---------|
| `src/i18n/locales/fr.json` | Modify | Nouvelles clés `tours.*` (filtre brouillon, labels boutons, sheet, fallback titre, etc.) |
| `src/infra/db/schema.ts` | Modify | `scheduledDate`/`departureTime` nullable + `title` nullable |
| `src/infra/db/migrations/0008_tour_drafts.sql` | Create | Recréer la table `tours` avec les nouveaux types |
| `src/infra/db/migrations/meta/_journal.json` | Modify | Nouvelle entry `idx=8`, `when=Date.now()` |
| `src/infra/db/migrations.js` | Modify (auto) | Régénéré par `pnpm db:bundle` |
| `src/domain/models/tour.ts` | Modify | Zod schema : `TourStatus` étendu, `scheduledDate`/`departureTime`/`title` nullable |
| `src/data/repositories/tour-repository.ts` | Modify | TourRow type adapté + mapper `title` + tri par status |
| `src/domain/use-cases/assert-tour-invariants.ts` | Create | Garde des invariants applicatifs |
| `tests/domain/assert-tour-invariants.test.ts` | Create | Vitest, 8 cas |
| `tests/data/tour-repository.test.ts` | Modify | Ajouter `title:null` aux fixtures + 1 cas brouillon |
| `src/state/queries/tours.ts` | Modify | Retirer `useUpsertTour` ; ajouter `useSaveDraft` + `useScheduleTour` |
| `src/ui/components/schedule-tour-sheet.tsx` | Create | Modal date+time pour planifier |
| `src/ui/components/tour-draft-editor.tsx` | Modify | Champ titre, date/time nullable, 2 boutons, integration sheet, delete |
| `src/ui/components/tour-card.tsx` | Modify | Rendu adapté pour `status='draft'` |
| `app/tour-new/draft.tsx` | Modify | Charge par `?id=`, branche `useSaveDraft` + `useScheduleTour`, bouton supprimer |
| `app/(tabs)/tours/[id]/edit.tsx` | Modify | Branche `useScheduleTour` uniquement |
| `app/(tabs)/tours/[id].tsx` | Modify | Redirect si `status==='draft'` |
| `app/(tabs)/tours/index.tsx` | Modify | SegmentedControl 3 valeurs + empty states |

---

## Task 1: i18n keys

**Files:**
- Modify: `src/i18n/locales/fr.json`

- [ ] **Step 1: Add new tours.* keys**

Locate the `"tours": {` block (around line 163). Add the following keys *anywhere* inside the block (next to similar keys for readability), preserving the JSON validity:

```jsonc
"filter_draft": "Brouillons",
"draft_status_label": "Brouillon",
"draft_fallback_title": "Brouillon du {{date}}",
"save_as_draft": "Enregistrer brouillon",
"schedule_cta": "Planifier",
"schedule_sheet_title": "Planifier la tournée",
"schedule_sheet_confirm": "Confirmer",
"title_label": "Titre du brouillon",
"title_placeholder": "Optionnel",
"draft_empty_title": "Aucun brouillon",
"draft_empty_message": "Crée une tournée pour commencer un brouillon.",
"delete_draft_cta": "Supprimer le brouillon",
"delete_draft_confirm_title": "Supprimer ce brouillon ?",
"delete_draft_confirm_message": "Cette action est irréversible.",
"stop_summary_count_label_one": "{{count}} client",
"stop_summary_count_label_other": "{{count}} clients",
"draft_modified_at": "modifié {{when}}"
```

(`stop_summary_count_label` est plurialisé — i18next applique le suffixe automatiquement avec `t('tours.stop_summary_count_label', { count: n })`.)

- [ ] **Step 2: Verify JSON parses**

```bash
node -e "JSON.parse(require('fs').readFileSync('src/i18n/locales/fr.json','utf8'));console.log('OK')"
```

Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add src/i18n/locales/fr.json
git commit -m "i18n(tours): add draft-related keys"
```

---

## Task 2: Drizzle schema update

**Files:**
- Modify: `src/infra/db/schema.ts`

Le schéma TS pilote la génération de queries Drizzle. On le rend cohérent avec ce que la migration appliquera à la DB réelle (Task 3).

- [ ] **Step 1: Edit the `tours` table definition**

Find `export const tours = sqliteTable('tours', { … })` (around line 76) and replace by:

```ts
export const tours = sqliteTable('tours', {
  id: text('id').primaryKey(),
  scheduledDate: text('scheduled_date'),
  departureTime: text('departure_time'),
  title: text('title'),
  baseLat: real('base_lat').notNull(),
  baseLng: real('base_lng').notNull(),
  status: text('status').notNull(),
  totalDistanceKm: real('total_distance_km'),
  totalDriveSeconds: integer('total_drive_seconds'),
  totalMinutes: integer('total_minutes'),
  totalRevenueCents: integer('total_revenue_cents'),
  totalAnimalsCount: integer('total_animals_count'),
  routeGeometry: text('route_geometry'),
  notes: text('notes'),
  completedAt: text('completed_at'),
  createdAt: text('created_at').notNull(),
  updatedAt: text('updated_at').notNull(),
});
```

Changes vs. current: `scheduledDate` and `departureTime` lose `.notNull()`; new column `title` (nullable text) inserted between `departureTime` and `baseLat`.

- [ ] **Step 2: Don't run typecheck yet**

`Tour` zod schema and the `TourRow` interface don't match yet — they will after Task 4. Skip typecheck for now and proceed to the migration.

- [ ] **Step 3: Commit**

```bash
git add src/infra/db/schema.ts
git commit -m "feat(db): drop NOT NULL on tour date/time and add title column"
```

---

## Task 3: Hand-written SQL migration + journal + bundle

**Files:**
- Create: `src/infra/db/migrations/0008_tour_drafts.sql`
- Modify: `src/infra/db/migrations/meta/_journal.json`
- Modify (auto-generated): `src/infra/db/migrations.js`

SQLite ne peut pas drop `NOT NULL` directement → recréer la table.

- [ ] **Step 1: Create the SQL migration**

File `src/infra/db/migrations/0008_tour_drafts.sql`:

```sql
PRAGMA foreign_keys=OFF;

CREATE TABLE __new_tours (
  id text PRIMARY KEY NOT NULL,
  scheduled_date text,
  departure_time text,
  title text,
  base_lat real NOT NULL,
  base_lng real NOT NULL,
  status text NOT NULL,
  total_distance_km real,
  total_drive_seconds integer,
  total_minutes integer,
  total_revenue_cents integer,
  total_animals_count integer,
  route_geometry text,
  notes text,
  completed_at text,
  created_at text NOT NULL,
  updated_at text NOT NULL
);

INSERT INTO __new_tours
SELECT
  id, scheduled_date, departure_time,
  NULL,
  base_lat, base_lng, status,
  total_distance_km, total_drive_seconds, total_minutes,
  total_revenue_cents, total_animals_count,
  route_geometry, notes, completed_at, created_at, updated_at
FROM tours;

DROP TABLE tours;
ALTER TABLE __new_tours RENAME TO tours;

PRAGMA foreign_keys=ON;
```

- [ ] **Step 2: Add the journal entry**

In `src/infra/db/migrations/meta/_journal.json`, the `entries` array currently ends with `idx: 7` (`0007_rename_travel_fee_settings`). Append a new entry. **CRITICAL** : `when` must be `Date.now()` at the actual moment of editing — paste the literal milliseconds value the runtime returns *now*. Compute it freshly:

```bash
node -e "console.log(Date.now())"
```

Take that integer and append:

```jsonc
    {
      "idx": 8,
      "version": "6",
      "when": <PASTE_THE_INTEGER_HERE>,
      "tag": "0008_tour_drafts",
      "breakpoints": true
    }
```

Make sure to add a comma after the previous entry's closing brace.

- [ ] **Step 3: Bundle migrations**

```bash
pnpm db:bundle
```

Expected: `Bundled 9 migrations.` (8 historic + 1 new). If you see `Migration "0008_tour_drafts" has when=…`, your `when` collided with a previous one — re-run `node -e "console.log(Date.now())"` to get a higher value and update the journal.

- [ ] **Step 4: Smoke-test the migration locally**

```bash
pnpm typecheck
```

The DB layer schema is now nullable, but `tour.ts` (Zod) and `tour-repository.ts` (TourRow) still expect non-null → typecheck **WILL FAIL**. That's expected; Task 4 fixes it. Don't commit yet — combine with Task 4.

- [ ] **Step 5: Stage but don't commit**

```bash
git add src/infra/db/migrations/0008_tour_drafts.sql src/infra/db/migrations/meta/_journal.json src/infra/db/migrations.js
```

Commit at end of Task 4.

---

## Task 4: Tour domain model + repository row type

**Files:**
- Modify: `src/domain/models/tour.ts`
- Modify: `src/data/repositories/tour-repository.ts`

- [ ] **Step 1: Update Tour zod schema**

Replace the contents of `src/domain/models/tour.ts` with:

```ts
import { z } from 'zod';

export const TourStatus = z.enum(['draft', 'planned', 'completed']);
export type TourStatus = z.infer<typeof TourStatus>;

export const Tour = z.object({
  id: z.string(),
  scheduledDate: z.string().nullable(),
  departureTime: z.string().nullable(),
  title: z.string().nullable(),
  baseLat: z.number(),
  baseLng: z.number(),
  status: TourStatus,
  totalDistanceKm: z.number().nullable(),
  totalDriveSeconds: z.number().int().nullable(),
  totalMinutes: z.number().int().nullable(),
  totalRevenueCents: z.number().int().nullable(),
  totalAnimalsCount: z.number().int().nullable(),
  routeGeometry: z.string().nullable(),
  notes: z.string().nullable(),
  completedAt: z.string().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type Tour = z.infer<typeof Tour>;
```

- [ ] **Step 2: Update TourRow in the repository**

In `src/data/repositories/tour-repository.ts`, locate the `interface TourRow` (around line 8) and replace by:

```ts
interface TourRow {
  id: string;
  scheduledDate: string | null;
  departureTime: string | null;
  title: string | null;
  baseLat: number;
  baseLng: number;
  status: string;
  totalDistanceKm: number | null;
  totalDriveSeconds: number | null;
  totalMinutes: number | null;
  totalRevenueCents: number | null;
  totalAnimalsCount: number | null;
  routeGeometry: string | null;
  notes: string | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}
```

- [ ] **Step 3: Run typecheck**

```bash
pnpm typecheck
```

Expect a number of errors in **other** files (consumers of `Tour` that did `tour.scheduledDate.localeCompare(...)` etc.). That's expected; subsequent tasks fix each consumer. The repository itself should typecheck cleanly because `tourFromRow(r)` runs `Tour.parse(r)` which now allows nulls, and `r.title` flows through the spread without explicit handling.

Document the failing locations (you'll need them for the subsequent tasks):

```bash
pnpm typecheck 2>&1 | grep "error TS" | head -30
```

Note the call sites, but don't try to fix them yet — they're handled in Tasks 7-15.

- [ ] **Step 4: Commit Tasks 2-4 together**

```bash
git add src/infra/db/schema.ts src/infra/db/migrations/0008_tour_drafts.sql src/infra/db/migrations/meta/_journal.json src/infra/db/migrations.js src/domain/models/tour.ts src/data/repositories/tour-repository.ts
git commit -m "feat(tour): support nullable date/time + title column"
```

(Note: schema.ts was staged in Task 2 but not committed; this commit bundles the data-layer changes together so the repo never sees a half-applied state.)

---

## Task 5: Update existing tour-repository test

**Files:**
- Modify: `tests/data/tour-repository.test.ts`

The test fixtures don't yet include `title`. Tour.parse will throw because `title` is required (even if nullable, the key must exist).

- [ ] **Step 1: Add `title: null` to fixtures**

In `tests/data/tour-repository.test.ts`, find the `sampleTour` constant (around line 30) and add `title: null,` after `departureTime`:

```ts
const sampleTour = {
  id: 't1',
  scheduledDate: '2026-05-10',
  departureTime: '08:00',
  title: null,                           // ← new
  baseLat: 48.0,
  // … rest unchanged
};
```

Find the second tour fixture (around line 124, used by another test):

```ts
{
  // …
  scheduledDate: '2026-05-01',
  // …
  baseLat: 0, baseLng: 0,
  status: 'planned',
  // …
}
```

Add `title: null,` somewhere in this object too (next to `scheduledDate` for consistency).

- [ ] **Step 2: Add a draft test case**

Add a new test at the end of the `describe` block:

```ts
it('persists and retrieves a draft tour with null date/time and a title', async () => {
  const { db } = await createTestDb();
  const tRepo = new TourRepository(db);
  const cRepo = new ClientRepository(db);
  await cRepo.upsert(sampleClient('c1'));

  const draft = {
    id: 'draft1',
    scheduledDate: null,
    departureTime: null,
    title: 'Mardi nord',
    baseLat: 48.0,
    baseLng: -3.0,
    status: 'draft' as const,
    totalDistanceKm: null,
    totalDriveSeconds: null,
    totalMinutes: null,
    totalRevenueCents: null,
    totalAnimalsCount: null,
    routeGeometry: null,
    notes: null,
    completedAt: null,
    createdAt: NOW,
    updatedAt: NOW,
  };

  await tRepo.upsertTour(draft, []);
  const fetched = await tRepo.byId('draft1');

  expect(fetched).not.toBeNull();
  expect(fetched!.tour.status).toBe('draft');
  expect(fetched!.tour.title).toBe('Mardi nord');
  expect(fetched!.tour.scheduledDate).toBeNull();
  expect(fetched!.tour.departureTime).toBeNull();
});
```

- [ ] **Step 3: Run jest**

```bash
pnpm jest tests/data/tour-repository.test.ts
```

Expected: all tests pass (existing + new draft test).

- [ ] **Step 4: Commit**

```bash
git add tests/data/tour-repository.test.ts
git commit -m "test(tours): cover draft persistence with null date/time"
```

---

## Task 6: `assertTourInvariants` use-case (TDD)

**Files:**
- Create: `tests/domain/assert-tour-invariants.test.ts`
- Create: `src/domain/use-cases/assert-tour-invariants.ts`

- [ ] **Step 1: Write the failing tests**

`tests/domain/assert-tour-invariants.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { assertTourInvariants } from '@/domain/use-cases/assert-tour-invariants';
import type { Tour } from '@/domain/models/tour';

const baseTour: Tour = {
  id: 't1',
  scheduledDate: null,
  departureTime: null,
  title: null,
  baseLat: 48,
  baseLng: -3,
  status: 'draft',
  totalDistanceKm: null,
  totalDriveSeconds: null,
  totalMinutes: null,
  totalRevenueCents: null,
  totalAnimalsCount: null,
  routeGeometry: null,
  notes: null,
  completedAt: null,
  createdAt: '2026-05-08T12:00:00.000Z',
  updatedAt: '2026-05-08T12:00:00.000Z',
};

describe('assertTourInvariants', () => {
  it('accepts a draft with both date and time null', () => {
    expect(() => assertTourInvariants(baseTour)).not.toThrow();
  });

  it('accepts a planned with both date and time set', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'planned',
        scheduledDate: '2026-05-10',
        departureTime: '08:00',
      }),
    ).not.toThrow();
  });

  it('accepts a completed with both date and time set', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'completed',
        scheduledDate: '2026-05-10',
        departureTime: '08:00',
        completedAt: '2026-05-10T17:00:00.000Z',
      }),
    ).not.toThrow();
  });

  it('throws when planned has scheduledDate null', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'planned',
        scheduledDate: null,
        departureTime: '08:00',
      }),
    ).toThrow(/requires scheduledDate and departureTime/);
  });

  it('throws when planned has departureTime null', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'planned',
        scheduledDate: '2026-05-10',
        departureTime: null,
      }),
    ).toThrow(/requires scheduledDate and departureTime/);
  });

  it('throws when completed has scheduledDate null', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'completed',
        scheduledDate: null,
        departureTime: '08:00',
      }),
    ).toThrow(/requires scheduledDate and departureTime/);
  });

  it('throws when draft has scheduledDate set', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'draft',
        scheduledDate: '2026-05-10',
      }),
    ).toThrow(/draft must not carry scheduledDate or departureTime/);
  });

  it('throws when draft has departureTime set', () => {
    expect(() =>
      assertTourInvariants({
        ...baseTour,
        status: 'draft',
        departureTime: '08:00',
      }),
    ).toThrow(/draft must not carry scheduledDate or departureTime/);
  });
});
```

- [ ] **Step 2: Run the test (must fail)**

```bash
pnpm vitest run tests/domain/assert-tour-invariants.test.ts
```

Expected: FAIL — `Cannot find module '@/domain/use-cases/assert-tour-invariants'`.

- [ ] **Step 3: Implement the use-case**

`src/domain/use-cases/assert-tour-invariants.ts`:

```ts
import type { Tour } from '@/domain/models/tour';

export function assertTourInvariants(tour: Tour): void {
  if (tour.status === 'planned' || tour.status === 'completed') {
    if (tour.scheduledDate == null || tour.departureTime == null) {
      throw new Error(
        `Tour ${tour.id} status=${tour.status} requires scheduledDate and departureTime`,
      );
    }
  }
  if (tour.status === 'draft') {
    if (tour.scheduledDate != null || tour.departureTime != null) {
      throw new Error(
        `Tour ${tour.id} status=draft must not carry scheduledDate or departureTime`,
      );
    }
  }
}
```

- [ ] **Step 4: Run the test (must pass)**

```bash
pnpm vitest run tests/domain/assert-tour-invariants.test.ts
```

Expected: PASS, 8/8.

- [ ] **Step 5: Commit**

```bash
git add src/domain/use-cases/assert-tour-invariants.ts tests/domain/assert-tour-invariants.test.ts
git commit -m "feat(domain): add assertTourInvariants guard"
```

---

## Task 7: Repository — tri par status

**Files:**
- Modify: `src/data/repositories/tour-repository.ts`

`listByStatus` doit trier différemment selon le statut. La méthode utilise actuellement `eq(tours.status, status)` sans `orderBy`.

- [ ] **Step 1: Add the orderBy logic**

In `src/data/repositories/tour-repository.ts`, find the `listByStatus` method (around line 136) and replace its body with:

```ts
async listByStatus(status: TourStatus): Promise<TourWithStops[]> {
  const orderColumn = (() => {
    switch (status) {
      case 'draft':     return desc(tours.updatedAt);
      case 'planned':   return asc(tours.scheduledDate);
      case 'completed': return desc(tours.scheduledDate);
    }
  })();
  const tRows = await this.db
    .select()
    .from(tours)
    .where(eq(tours.status, status))
    .orderBy(orderColumn);

  const result: TourWithStops[] = [];
  for (const tr of tRows) {
    const sRows = await this.db
      .select()
      .from(tourStops)
      .where(eq(tourStops.tourId, (tr as TourRow).id))
      .orderBy(asc(tourStops.ordering));
    result.push({
      tour: tourFromRow(tr as TourRow),
      stops: sRows.map((r) => stopFromRow(r as TourStopRow)),
    });
  }
  return result;
}
```

- [ ] **Step 2: Add `desc` to the imports**

At the top of the same file, change:

```ts
import { asc, eq } from 'drizzle-orm';
```

to:

```ts
import { asc, desc, eq } from 'drizzle-orm';
```

- [ ] **Step 3: Run jest on tour-repository tests**

```bash
pnpm jest tests/data/tour-repository.test.ts
```

Expected: all green (no test asserts ordering specifically, but the new orderBy must not break existing assertions).

- [ ] **Step 4: Commit**

```bash
git add src/data/repositories/tour-repository.ts
git commit -m "feat(tours): order tour list by status (draft=updatedAt, planned=ASC, completed=DESC)"
```

---

## Task 8: Mutations split — `useSaveDraft` + `useScheduleTour`

**Files:**
- Modify: `src/state/queries/tours.ts`

On garde `useUpsertTour` pour l'instant (les call-sites `tour-new/draft.tsx` et `tours/[id]/edit.tsx` l'utilisent encore). Tasks 11 et 12 vont migrer ces call-sites, puis Task 13 supprimera `useUpsertTour`.

- [ ] **Step 1: Add new exports + helper**

Open `src/state/queries/tours.ts`. Add the imports needed:

```ts
import { assertTourInvariants } from '@/domain/use-cases/assert-tour-invariants';
```

After `UpsertTourStopInput` (around line 45) but BEFORE `useUpsertTour`, add the following block:

```ts
function buildStops(tourId: string, inputs: UpsertTourStopInput[]): TourStop[] {
  return inputs.map((s, index) => ({
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
}

export interface SaveDraftInput {
  id?: string;
  title: string | null;
  baseLat: number;
  baseLng: number;
  stops: UpsertTourStopInput[];
  totalDistanceKm: number | null;
  totalMinutes: number | null;
}

export function useSaveDraft() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: SaveDraftInput) => {
      const now = new Date().toISOString();
      const existing = input.id ? await tourRepo.byId(input.id) : null;
      const tourId = input.id ?? newId();
      const tour: Tour = {
        id: tourId,
        scheduledDate: null,
        departureTime: null,
        title: input.title,
        baseLat: input.baseLat,
        baseLng: input.baseLng,
        status: 'draft',
        totalDistanceKm: input.totalDistanceKm,
        totalDriveSeconds: existing?.tour.totalDriveSeconds ?? null,
        totalMinutes: input.totalMinutes,
        totalRevenueCents: existing?.tour.totalRevenueCents ?? null,
        totalAnimalsCount: existing?.tour.totalAnimalsCount ?? null,
        routeGeometry: existing?.tour.routeGeometry ?? null,
        notes: existing?.tour.notes ?? null,
        completedAt: null,
        createdAt: existing?.tour.createdAt ?? now,
        updatedAt: now,
      };
      assertTourInvariants(tour);
      const stops = buildStops(tourId, input.stops);
      await tourRepo.upsertTour(tour, stops);
      return { tour, stops };
    },
    onSuccess: ({ tour }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['kpis'] });
      qc.removeQueries({ queryKey: toursKeys.byId(tour.id) });
    },
  });
}

export interface ScheduleTourInput {
  id?: string;
  title: string | null;
  scheduledDate: string;
  departureTime: string;
  baseLat: number;
  baseLng: number;
  stops: UpsertTourStopInput[];
  totalDistanceKm: number | null;
  totalMinutes: number | null;
}

export function useScheduleTour() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: ScheduleTourInput) => {
      const now = new Date().toISOString();
      const existing = input.id ? await tourRepo.byId(input.id) : null;
      const tourId = input.id ?? newId();
      const tour: Tour = {
        id: tourId,
        scheduledDate: input.scheduledDate,
        departureTime: input.departureTime,
        title: input.title,
        baseLat: input.baseLat,
        baseLng: input.baseLng,
        status: 'planned',
        totalDistanceKm: input.totalDistanceKm,
        totalDriveSeconds: existing?.tour.totalDriveSeconds ?? null,
        totalMinutes: input.totalMinutes,
        totalRevenueCents: existing?.tour.totalRevenueCents ?? null,
        totalAnimalsCount: existing?.tour.totalAnimalsCount ?? null,
        routeGeometry: existing?.tour.routeGeometry ?? null,
        notes: existing?.tour.notes ?? null,
        completedAt: null,
        createdAt: existing?.tour.createdAt ?? now,
        updatedAt: now,
      };
      assertTourInvariants(tour);
      const stops = buildStops(tourId, input.stops);
      await tourRepo.upsertTour(tour, stops);
      return { tour, stops };
    },
    onSuccess: ({ tour }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['clients'] });
      void qc.invalidateQueries({ queryKey: ['kpis'] });
      qc.removeQueries({ queryKey: toursKeys.byId(tour.id) });
    },
  });
}
```

- [ ] **Step 2: Fix `useNextPlannedTourForClient` for nullable scheduledDate**

In the same file, find the function (around line 112). Its sort uses `a.tour.scheduledDate.localeCompare(b.tour.scheduledDate)`. Since the type is now `string | null`, but this function only deals with planned tours (which always have scheduledDate per invariants), wrap with non-null assertions:

```ts
const matching = planned
  .filter(({ stops }) => stops.some((s) => s.clientId === clientId))
  .sort((a, b) =>
    (a.tour.scheduledDate ?? '').localeCompare(b.tour.scheduledDate ?? ''),
  );
```

- [ ] **Step 3: Fix `useUpsertTour`'s tour construction (now requires `title`)**

Still in the same file, find `useUpsertTour` (around line 59). The constructed `Tour` object is missing `title`. Add `title: existing?.tour.title ?? null,` after `status` (around line 73):

```ts
const tour: Tour = {
  id: tourId,
  scheduledDate: input.scheduledDate,
  departureTime: input.departureTime,
  title: existing?.tour.title ?? null,    // ← added
  baseLat: input.baseLat,
  // … rest unchanged
};
```

This keeps `useUpsertTour` compatible with the new Tour shape during the interim period.

- [ ] **Step 4: Fix `useCompleteTour` and `useCompleteWithBilan` for null lastShearingDate**

In `useCompleteTour` (around line 230) and `useCompleteWithBilan` (around line 169), there's:

```ts
lastShearingDate: tour.scheduledDate,
lastShearingDate: result.tour.scheduledDate,
```

`tour.scheduledDate` is now `string | null`. But these functions only operate on tours that are being completed → they MUST have a date (planned → completed is the only path). Use a fallback to today's date if null (defensive — should never trigger, but keeps types safe):

In `useCompleteTour`:

```ts
lastShearingDate: tour.scheduledDate ?? completedAt.slice(0, 10),
```

In `useCompleteWithBilan`:

```ts
lastShearingDate: result.tour.scheduledDate ?? completedAt.slice(0, 10),
```

- [ ] **Step 5: Run typecheck**

```bash
pnpm typecheck
```

`tours.ts` should now typecheck cleanly. Other consumers (`draft.tsx`, `[id].tsx`, `[id]/edit.tsx`, `tour-card.tsx`) may still have errors — handled in Tasks 11-15.

- [ ] **Step 6: Run vitest + jest sanity**

```bash
pnpm vitest run && pnpm jest --testPathPattern="tests/(data|infra|ui)/"
```

Expected: green.

- [ ] **Step 7: Commit**

```bash
git add src/state/queries/tours.ts
git commit -m "feat(state): add useSaveDraft + useScheduleTour mutations"
```

---

## Task 9: `ScheduleTourSheet` component

**Files:**
- Create: `src/ui/components/schedule-tour-sheet.tsx`

- [ ] **Step 1: Create the file**

`src/ui/components/schedule-tour-sheet.tsx`:

```tsx
import { useState } from 'react';
import { Modal, Platform, TouchableOpacity, View } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';

interface Props {
  visible: boolean;
  initialDate: Date | null;
  initialTime: string | null;
  onClose: () => void;
  onConfirm: (input: { scheduledDate: string; departureTime: string }) => void;
}

export function ScheduleTourSheet({ visible, initialDate, initialTime, onClose, onConfirm }: Props) {
  const { t } = useTranslation();
  const [date, setDate] = useState<Date>(initialDate ?? new Date());
  const [time, setTime] = useState<string>(initialTime ?? '08:00');
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);

  const confirm = () => {
    onConfirm({
      scheduledDate: format(date, 'yyyy-MM-dd'),
      departureTime: time,
    });
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      presentationStyle="overFullScreen"
      onRequestClose={onClose}
    >
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl px-4 pt-4 pb-8">
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('tours.schedule_sheet_title')}</Text>
          <PressScale onPress={onClose} className="p-1" accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>

        <View className="gap-2 mb-4">
          <Text className="text-sm font-medium">{t('tours.scheduled_date')}</Text>
          <PressScale
            onPress={() => setShowDatePicker(true)}
            accessibilityLabel={t('tours.scheduled_date')}
          >
            <Surface variant="muted" className="rounded-2xl px-4 py-3">
              <Text>{format(date, 'PPPP', { locale: fr })}</Text>
            </Surface>
          </PressScale>
          {showDatePicker ? (
            <DateTimePicker
              value={date}
              mode="date"
              onChange={(_, d) => {
                setShowDatePicker(Platform.OS === 'ios');
                if (d) setDate(d);
              }}
            />
          ) : null}
        </View>

        <View className="gap-2 mb-4">
          <Text className="text-sm font-medium">{t('tours.departure_time')}</Text>
          <PressScale
            onPress={() => setShowTimePicker(true)}
            accessibilityLabel={t('tours.departure_time')}
          >
            <Surface variant="muted" className="rounded-2xl px-4 py-3">
              <Text>{time}</Text>
            </Surface>
          </PressScale>
          {showTimePicker ? (
            <DateTimePicker
              value={(() => {
                const [h, m] = time.split(':').map(Number);
                const d = new Date();
                d.setHours(h ?? 0, m ?? 0, 0, 0);
                return d;
              })()}
              mode="time"
              is24Hour
              onChange={(_, d) => {
                setShowTimePicker(Platform.OS === 'ios');
                if (d) setTime(format(d, 'HH:mm'));
              }}
            />
          ) : null}
        </View>

        <View className="flex-row gap-2">
          <Button variant="ghost" className="flex-1" onPress={onClose}>
            {t('common.cancel')}
          </Button>
          <Button className="flex-1" onPress={confirm}>
            {t('tours.schedule_sheet_confirm')}
          </Button>
        </View>
      </Surface>
    </Modal>
  );
}
```

- [ ] **Step 2: Run typecheck**

```bash
pnpm typecheck
```

Expected: this file compiles cleanly. Other files may still error.

- [ ] **Step 3: Commit**

```bash
git add src/ui/components/schedule-tour-sheet.tsx
git commit -m "feat(tours): add ScheduleTourSheet modal"
```

---

## Task 10: `TourDraftEditor` refactor

**Files:**
- Modify: `src/ui/components/tour-draft-editor.tsx`

Le composant doit accepter un `tourStatus`, un titre optionnel, des date/time nullable, deux callbacks (`onSaveDraft`, `onSchedule`), et exposer un bouton supprimer si `id` fourni et status='draft'.

- [ ] **Step 1: Add imports**

At the top of the file, ensure these imports exist (some are already there):

```ts
import { useState, useMemo } from 'react';
import { TextInput, View, Platform } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { GripVertical, Trash2, Plus, ChevronRight, AlertTriangle } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { formatMinutes } from '@/lib/format-minutes';
import { DraggableList } from '@/ui/components/draggable-list';
import { ServicePickerSheet } from '@/ui/components/service-picker-sheet';
import { ScheduleTourSheet } from '@/ui/components/schedule-tour-sheet';
import { confirm } from '@/ui/components/confirm-dialog';
import { TourMapPreview, type PreviewStop } from '@/ui/components/tour-map-preview';
import { useClients } from '@/state/queries/clients';
import { haversineDistanceKm } from '@/lib/haversine-distance';
import { estimateTourArrivals } from '@/domain/use-cases/estimate-tour-arrivals';
import { computeClientTravelFee } from '@/domain/use-cases/compute-client-travel-fee';
import { useBaseAddress, useAllSettings } from '@/state/queries/settings';
import { useForegroundColor, useOnContrastColor } from '@/ui/theme/colors';
import type { TourStatus } from '@/domain/models/tour';
import type { TourStopService } from '@/domain/models/tour-stop-service';
```

The new imports vs current: `TextInput` from react-native, `ScheduleTourSheet`, `useOnContrastColor`.

- [ ] **Step 2: Update Props interface**

Replace the existing `Props` interface (around line 34) with:

```ts
interface Props {
  initialStops: DraftStop[];
  initialDate?: string | null;
  initialTime?: string | null;
  initialTitle?: string | null;
  initialId?: string;
  tourStatus?: TourStatus;            // 'draft' | 'planned' | 'completed' — default 'draft'
  saving?: boolean;
  onSaveDraft?: (input: {
    title: string | null;
    stops: DraftStop[];
    totalDistanceKm: number;
    totalMinutes: number;
  }) => void;
  onSchedule: (input: {
    title: string | null;
    scheduledDate: string;
    departureTime: string;
    stops: DraftStop[];
    totalDistanceKm: number;
    totalMinutes: number;
  }) => void;
  onDelete?: () => void;             // visible only when status='draft' AND initialId is present
  onAddClients: () => void;
  onRemoveStop: (clientId: string) => void;
  onReorderStops: (next: DraftStop[]) => void;
  onUpdateStopServices?: (clientId: string, prests: TourStopService[]) => void;
}
```

- [ ] **Step 3: Update destructuring + state**

Replace the function signature and the first state block:

```tsx
export function TourDraftEditor({
  initialStops, initialDate, initialTime, initialTitle, initialId,
  tourStatus = 'draft',
  saving, onSaveDraft, onSchedule, onDelete,
  onAddClients, onRemoveStop, onReorderStops, onUpdateStopServices,
}: Props) {
  const { t } = useTranslation();
  const [title, setTitle] = useState<string | null>(initialTitle ?? null);
  const [date, setDate] = useState<Date | null>(initialDate ? parseISO(initialDate) : null);
  const [time, setTime] = useState<string | null>(initialTime ?? null);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [scheduleSheetVisible, setScheduleSheetVisible] = useState(false);
```

- [ ] **Step 4: Update `arrivals` memo to handle null `time`**

Find the `arrivals` useMemo (around line 107). Since `time` may now be null, default to '08:00' for the estimation calculation:

```ts
const arrivals = useMemo(
  () =>
    estimateTourArrivals({
      departureTime: time ?? '08:00',
      stops: initialStops.map((s) => ({
        clientId: s.clientId,
        plannedServices: s.plannedServices,
      })),
      travelMinutesBetween: minutesBetween,
    }),
  // eslint-disable-next-line react-hooks/exhaustive-deps
  [initialStops, time, base, clients]
);
```

- [ ] **Step 5: Replace `submit` with two handlers**

Find the existing `submit` function (around line 150) and replace it with:

```ts
const submitSchedule = async (scheduledDate: string, departureTime: string) => {
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
  onSchedule({
    title,
    scheduledDate,
    departureTime,
    stops: initialStops.map((s) => ({
      ...s,
      clientNameSnapshot: clientsById.get(s.clientId)?.displayName ?? null,
    })),
    totalDistanceKm,
    totalMinutes,
  });
};

const submitDraft = () => {
  if (initialStops.length === 0) return;
  if (!onSaveDraft) return;
  onSaveDraft({
    title,
    stops: initialStops.map((s) => ({
      ...s,
      clientNameSnapshot: clientsById.get(s.clientId)?.displayName ?? null,
    })),
    totalDistanceKm,
    totalMinutes,
  });
};

const onConfirmSchedule = (input: { scheduledDate: string; departureTime: string }) => {
  setScheduleSheetVisible(false);
  void submitSchedule(input.scheduledDate, input.departureTime);
};

const onDeletePress = async () => {
  if (!onDelete) return;
  const ok = await confirm({
    title: t('tours.delete_draft_confirm_title'),
    message: t('tours.delete_draft_confirm_message'),
    confirmLabel: t('common.delete'),
    cancelLabel: t('common.cancel'),
    destructive: true,
  });
  if (ok) onDelete();
};
```

- [ ] **Step 6: Update the `Header` JSX to render the title input + nullable pickers**

Find the existing `Header` constant and replace its body (the JSX inside `<View style={{ gap: 16, paddingTop: 16, paddingBottom: 8 }}>`) with the version below. The structure: title input first, then preview map (unchanged), then date picker (with "Optional" placeholder when null), then time picker (same), then KPI row (unchanged), then Add Stops button (unchanged).

```tsx
const Header = (
  <View style={{ gap: 16, paddingTop: 16, paddingBottom: 8 }}>
    {tourStatus === 'draft' ? (
      <View className="gap-2">
        <Text className="text-sm font-medium">{t('tours.title_label')}</Text>
        <TextInput
          value={title ?? ''}
          onChangeText={(v) => setTitle(v.length > 0 ? v : null)}
          placeholder={t('tours.title_placeholder')}
          className="rounded-2xl px-4 py-3 bg-muted dark:bg-muted-dark"
          style={{ color: fg }}
          placeholderTextColor="#5C4E40"
        />
      </View>
    ) : null}

    {base && previewStops.length > 0 ? (
      <TourMapPreview base={{ lat: base.lat, lon: base.lon }} stops={previewStops} />
    ) : null}

    {tourStatus !== 'draft' ? (
      <>
        <View className="gap-2">
          <Text className="text-sm font-medium">{t('tours.scheduled_date')}</Text>
          <PressScale
            onPress={() => setShowDatePicker(true)}
            accessibilityLabel={t('tours.scheduled_date')}
          >
            <Surface variant="muted" className="rounded-2xl px-4 py-3">
              <Text>{date ? format(date, 'PPPP', { locale: fr }) : t('tours.title_placeholder')}</Text>
            </Surface>
          </PressScale>
          {showDatePicker ? (
            <DateTimePicker
              value={date ?? new Date()}
              mode="date"
              onChange={(_, d) => {
                setShowDatePicker(Platform.OS === 'ios');
                if (d) setDate(d);
              }}
            />
          ) : null}
        </View>

        <View className="gap-2">
          <Text className="text-sm font-medium">{t('tours.departure_time')}</Text>
          <PressScale
            onPress={() => setShowTimePicker(true)}
            accessibilityLabel={t('tours.departure_time')}
          >
            <Surface variant="muted" className="rounded-2xl px-4 py-3">
              <Text>{time ?? t('tours.title_placeholder')}</Text>
            </Surface>
          </PressScale>
          {showTimePicker ? (
            <DateTimePicker
              value={(() => {
                const [h, m] = (time ?? '08:00').split(':').map(Number);
                const d = new Date();
                d.setHours(h ?? 0, m ?? 0, 0, 0);
                return d;
              })()}
              mode="time"
              is24Hour
              onChange={(_, d) => {
                setShowTimePicker(Platform.OS === 'ios');
                if (d) setTime(format(d, 'HH:mm'));
              }}
            />
          ) : null}
        </View>
      </>
    ) : null}

    <Surface variant="muted" className="rounded-2xl px-4 py-3">
      <View className="flex-row justify-between">
        <Text variant="muted">{t('tours.total_distance')}</Text>
        <Text className="font-semibold">{totalDistanceKm.toFixed(1)} km</Text>
      </View>
      <View className="flex-row justify-between mt-1">
        <Text variant="muted">{t('tours.total_duration')}</Text>
        <Text className="font-semibold">{formatMinutes(totalMinutes)}</Text>
      </View>
      <View className="flex-row justify-between mt-1">
        <Text variant="muted">{t('tours.total_cost')}</Text>
        <Text className="font-semibold">{(totalFeeCents / 100).toFixed(0)} €</Text>
      </View>
    </Surface>

    <View className="flex-row items-center justify-between">
      <Text className="text-sm font-medium">{t('tours.stops_section')}</Text>
      <Button
        size="sm"
        variant="ghost"
        onPress={onAddClients}
        accessibilityLabel={t('tours.add_stops')}
      >
        <Plus size={14} color={fg} />
        <Text className="font-semibold text-sm">{t('tours.add_stops')}</Text>
      </Button>
    </View>
    <Text variant="muted" className="text-xs">{t('tours.reorder_hint')}</Text>

    {tourStatus === 'draft' && initialId && onDelete ? (
      <Button
        variant="danger"
        onPress={() => void onDeletePress()}
        accessibilityLabel={t('tours.delete_draft_cta')}
      >
        <Trash2 size={16} color={onContrast} />
        <Text variant="onPrimary" className="font-semibold">{t('tours.delete_draft_cta')}</Text>
      </Button>
    ) : null}
  </View>
);
```

Add the `useOnContrastColor` hook earlier in the function:

```ts
const onContrast = useOnContrastColor();
```

(Place near the existing `const fg = useForegroundColor();`.)

- [ ] **Step 7: Replace the footer (Save button)**

Find the footer:

```tsx
<View className="px-4 pt-3 pb-6 border-t border-border dark:border-border-dark bg-background dark:bg-background-dark">
  <Button
    onPress={() => void submit()}
    loading={saving}
    disabled={initialStops.length === 0 || saving}
  >
    {t('common.save')}
  </Button>
</View>
```

Replace it with:

```tsx
<View className="px-4 pt-3 pb-6 border-t border-border dark:border-border-dark bg-background dark:bg-background-dark flex-row gap-2">
  {tourStatus === 'draft' && onSaveDraft ? (
    <Button
      variant="secondary"
      className="flex-1"
      onPress={submitDraft}
      disabled={initialStops.length === 0 || saving}
      accessibilityLabel={t('tours.save_as_draft')}
    >
      <Text className="font-semibold">{t('tours.save_as_draft')}</Text>
    </Button>
  ) : null}
  <Button
    className="flex-1"
    onPress={() => setScheduleSheetVisible(true)}
    disabled={initialStops.length === 0 || saving}
    accessibilityLabel={t('tours.schedule_cta')}
  >
    <Text variant="onPrimary" className="font-semibold">{t('tours.schedule_cta')}</Text>
  </Button>
</View>
```

- [ ] **Step 8: Render ScheduleTourSheet**

Just before the closing `</>` of the JSX (just below the existing `<ServicePickerSheet … />` block), add:

```tsx
<ScheduleTourSheet
  visible={scheduleSheetVisible}
  initialDate={date}
  initialTime={time}
  onClose={() => setScheduleSheetVisible(false)}
  onConfirm={onConfirmSchedule}
/>
```

- [ ] **Step 9: Run typecheck**

```bash
pnpm typecheck
```

Expected: this component now type-checks. The two call sites (`tour-new/draft.tsx` and `[id]/edit.tsx`) will fail because they pass an `onSubmit` prop that no longer exists. Tasks 11/12 fix them.

- [ ] **Step 10: Commit**

```bash
git add src/ui/components/tour-draft-editor.tsx
git commit -m "feat(TourDraftEditor): support drafts (title input, two actions, schedule sheet)"
```

---

## Task 11: `app/tour-new/draft.tsx` — wire useSaveDraft + useScheduleTour + load by id

**Files:**
- Modify: `app/tour-new/draft.tsx`

- [ ] **Step 1: Replace the file contents**

Replace the entire contents of `app/tour-new/draft.tsx` with:

```tsx
import { useEffect, useMemo, useState } from 'react';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { TourDraftEditor } from '@/ui/components/tour-draft-editor';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';
import {
  useSaveDraft,
  useScheduleTour,
  useDeleteTour,
  useTour,
} from '@/state/queries/tours';
import { useBaseAddress } from '@/state/queries/settings';
import { errorToast, mutationErrorToast } from '@/ui/components/error-toast';
import { haptics } from '@/ui/motion/haptics';

export default function NewTourDraftScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id?: string }>();

  const picked = useTourDraftStore((s) => s.pickedClientIds);
  const servicesByClient = useTourDraftStore((s) => s.servicesByClient);
  const setOrder = useTourDraftStore((s) => s.setOrder);
  const reset = useTourDraftStore((s) => s.reset);
  const toggle = useTourDraftStore((s) => s.toggle);
  const setStopServices = useTourDraftStore((s) => s.setStopServices);
  const hydrateServices = useTourDraftStore((s) => s.hydrateServices);

  const { data: existing } = useTour(id);
  const saveDraft = useSaveDraft();
  const scheduleTour = useScheduleTour();
  const deleteTour = useDeleteTour();
  const { data: base } = useBaseAddress();

  const [hydrated, setHydrated] = useState(false);

  // Load existing draft into the store when arriving with ?id=...
  useEffect(() => {
    if (!id) {
      // New flow: if store empty, redirect to pick-clients
      if (picked.length === 0) {
        router.push('/tour-new/pick-clients' as never);
      }
      setHydrated(true);
      return;
    }
    if (existing && !hydrated) {
      reset();
      setOrder(existing.stops.map((s) => s.clientId));
      hydrateServices(
        existing.stops.map((s) => ({ clientId: s.clientId, services: s.plannedServices })),
      );
      setHydrated(true);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, existing?.tour.id]);

  const stops = useMemo(
    () => picked.map((cid) => ({
      clientId: cid,
      plannedServices: servicesByClient[cid] ?? [],
      notes: null,
    })),
    [picked, servicesByClient]
  );

  const tourStatus = existing?.tour.status ?? 'draft';
  const saving = saveDraft.isPending || scheduleTour.isPending;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('tours.new_title')} />
      <TourDraftEditor
        initialId={id}
        initialDate={existing?.tour.scheduledDate ?? null}
        initialTime={existing?.tour.departureTime ?? null}
        initialTitle={existing?.tour.title ?? null}
        initialStops={stops}
        tourStatus={tourStatus}
        saving={saving}
        onAddClients={() => router.push('/tour-new/pick-clients' as never)}
        onRemoveStop={toggle}
        onReorderStops={(next) => setOrder(next.map((s) => s.clientId))}
        onUpdateStopServices={setStopServices}
        onSaveDraft={(input) => {
          if (!base) {
            errorToast(t('tours.errors.base_missing_title'), t('tours.errors.base_missing_message'));
            return;
          }
          saveDraft.mutate(
            {
              id,
              title: input.title,
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
              totalDistanceKm: input.totalDistanceKm,
              totalMinutes: input.totalMinutes,
            },
            {
              onSuccess: () => {
                void haptics.success();
                reset();
                router.replace('/(tabs)/tours' as never);
              },
              onError: (err) => {
                mutationErrorToast(t('tours.save_failed_title'), err);
              },
            }
          );
        }}
        onSchedule={(input) => {
          if (!base) {
            errorToast(t('tours.errors.base_missing_title'), t('tours.errors.base_missing_message'));
            return;
          }
          scheduleTour.mutate(
            {
              id,
              title: input.title,
              scheduledDate: input.scheduledDate,
              departureTime: input.departureTime,
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
              totalDistanceKm: input.totalDistanceKm,
              totalMinutes: input.totalMinutes,
            },
            {
              onSuccess: () => {
                void haptics.success();
                reset();
                router.replace('/(tabs)/tours' as never);
              },
              onError: (err) => {
                mutationErrorToast(t('tours.save_failed_title'), err);
              },
            }
          );
        }}
        onDelete={id ? () => {
          deleteTour.mutate(id, {
            onSuccess: () => {
              void haptics.success();
              reset();
              router.replace('/(tabs)/tours' as never);
            },
            onError: (err) => {
              mutationErrorToast(t('tours.delete_failed_title'), err);
            },
          });
        } : undefined}
      />
    </Surface>
  );
}
```

- [ ] **Step 2: Run typecheck**

```bash
pnpm typecheck
```

Expected: file compiles. `[id]/edit.tsx` still fails — Task 12.

- [ ] **Step 3: Commit**

```bash
git add app/tour-new/draft.tsx
git commit -m "feat(tour-new): wire save-as-draft and schedule, support edit by id"
```

---

## Task 12: `app/(tabs)/tours/[id]/edit.tsx` — wire useScheduleTour

**Files:**
- Modify: `app/(tabs)/tours/[id]/edit.tsx`

L'écran d'édition d'une tournée existe pour les planifiées (et terminées en lecture). Il ne propose plus que "Planifier" (re-planifier) — pas de "Enregistrer brouillon".

- [ ] **Step 1: Replace the file contents**

Replace the entire contents of `app/(tabs)/tours/[id]/edit.tsx` with:

```tsx
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useMemo } from 'react';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { ScreenHeader } from '@/ui/components/screen-header';
import { TourDraftEditor } from '@/ui/components/tour-draft-editor';
import { ErrorState } from '@/ui/components/error-state';
import { useTour, useScheduleTour } from '@/state/queries/tours';
import { useBaseAddress } from '@/state/queries/settings';
import { errorToast, mutationErrorToast } from '@/ui/components/error-toast';
import { haptics } from '@/ui/motion/haptics';
import { useTourDraftStore } from '@/state/stores/tour-draft-store';

export default function EditTourScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { t } = useTranslation();
  const { data, isError, refetch } = useTour(id);
  const scheduleTour = useScheduleTour();
  const { data: base } = useBaseAddress();
  const setOrder = useTourDraftStore((s) => s.setOrder);
  const picked = useTourDraftStore((s) => s.pickedClientIds);
  const toggle = useTourDraftStore((s) => s.toggle);
  const servicesByClient = useTourDraftStore((s) => s.servicesByClient);
  const setStopServices = useTourDraftStore((s) => s.setStopServices);
  const hydrateServices = useTourDraftStore((s) => s.hydrateServices);

  useEffect(() => {
    if (data) {
      setOrder(data.stops.map((s) => s.clientId));
      hydrateServices(
        data.stops.map((s) => ({ clientId: s.clientId, services: s.plannedServices }))
      );
    }
    return () => {
      useTourDraftStore.getState().reset();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data?.tour.id]);

  const stops = useMemo(
    () =>
      picked.map((cid) => {
        const original = data?.stops.find((s) => s.clientId === cid);
        return {
          clientId: cid,
          plannedServices: servicesByClient[cid] ?? original?.plannedServices ?? [],
          notes: original?.notes ?? null,
        };
      }),
    [picked, data, servicesByClient]
  );

  if (isError) return <ErrorState onRetry={() => refetch()} />;
  if (!data) return <Surface className="flex-1" />;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('tours.edit_title')} />
      <TourDraftEditor
        initialId={data.tour.id}
        initialDate={data.tour.scheduledDate}
        initialTime={data.tour.departureTime}
        initialTitle={data.tour.title}
        initialStops={stops}
        tourStatus={data.tour.status}
        saving={scheduleTour.isPending}
        onAddClients={() => router.push('/tour-new/pick-clients' as never)}
        onRemoveStop={toggle}
        onReorderStops={(next) => setOrder(next.map((s) => s.clientId))}
        onUpdateStopServices={setStopServices}
        onSchedule={(input) => {
          if (!base) {
            errorToast(t('tours.errors.base_missing_title'), t('tours.errors.base_missing_message'));
            return;
          }
          scheduleTour.mutate(
            {
              id: data.tour.id,
              title: input.title,
              scheduledDate: input.scheduledDate,
              departureTime: input.departureTime,
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
              totalDistanceKm: input.totalDistanceKm,
              totalMinutes: input.totalMinutes,
            },
            {
              onSuccess: () => {
                void haptics.success();
                router.back();
              },
              onError: (err) => {
                mutationErrorToast(t('tours.save_failed_title'), err);
              },
            }
          );
        }}
      />
    </Surface>
  );
}
```

Note: `onSaveDraft` and `onDelete` are NOT passed → the editor won't render those buttons (the props are optional). `tourStatus` is passed from `data.tour.status`, so for a planned tour the title input is hidden and the date/time pickers are shown.

- [ ] **Step 2: Run typecheck**

```bash
pnpm typecheck
```

Expected: green for this file. Maybe other consumers still error.

- [ ] **Step 3: Commit**

```bash
git add app/'(tabs)'/tours/'[id]'/edit.tsx
git commit -m "feat(tours-edit): use useScheduleTour for re-planning"
```

---

## Task 13: Remove `useUpsertTour`

**Files:**
- Modify: `src/state/queries/tours.ts`

Plus aucun call-site n'utilise `useUpsertTour` (vérifier d'abord).

- [ ] **Step 1: Verify no remaining call-sites**

```bash
node -e "const{execSync}=require('child_process');console.log(execSync('git grep -n useUpsertTour -- \"*.ts\" \"*.tsx\"',{encoding:'utf8'}).trim()||'(no matches)');"
```

Expected: only matches inside `src/state/queries/tours.ts` itself. If any external caller is found, fix it before proceeding.

- [ ] **Step 2: Remove the export**

In `src/state/queries/tours.ts`, delete the entire `useUpsertTour` function and the `UpsertTourInput` interface (lines around 47-110). Keep the `UpsertTourStopInput` interface — it's still used by `SaveDraftInput`/`ScheduleTourInput`.

- [ ] **Step 3: Run typecheck + tests**

```bash
pnpm typecheck && pnpm vitest run && pnpm jest --testPathPattern="tests/(data|infra|ui)/"
```

Expected: all green.

- [ ] **Step 4: Commit**

```bash
git add src/state/queries/tours.ts
git commit -m "refactor(state): remove useUpsertTour (replaced by useSaveDraft + useScheduleTour)"
```

---

## Task 14: `app/(tabs)/tours/[id].tsx` — redirect drafts to editor

**Files:**
- Modify: `app/(tabs)/tours/[id].tsx`

- [ ] **Step 1: Add the redirect effect**

In `app/(tabs)/tours/[id].tsx`, locate the `TourDetailScreen` function (around line 57). Right after the `useTour(id)` call (around line 63), add:

```tsx
useEffect(() => {
  if (data?.tour.status === 'draft') {
    router.replace(`/tour-new/draft?id=${data.tour.id}` as never);
  }
}, [data?.tour.status, data?.tour.id, router]);
```

Add `useEffect` to the existing react import (around line 3):

```ts
import { useEffect, useMemo, useState } from 'react';
```

(if not already imported.)

- [ ] **Step 2: Guard the rendering against null scheduledDate/departureTime**

The render at line 148 uses `tour.scheduledDate` and `tour.departureTime` directly:

```tsx
{format(parseISO(`${tour.scheduledDate}T${tour.departureTime}:00`), 'PPPp', { locale: fr })}
```

For drafts the redirect will fire before render, but TypeScript will still complain because the types are `string | null`. Add a guard *just below* the existing `if (!data) return <Surface className="flex-1" />;` line:

```tsx
if (data.tour.status === 'draft') return <Surface className="flex-1" />;  // redirect in flight
const { tour, stops } = data;
if (tour.scheduledDate == null || tour.departureTime == null) {
  return <Surface className="flex-1" />;  // defensive: should not happen for non-draft
}
```

Remove the original `const { tour, stops } = data;` line (was at line 101) so it isn't duplicated. The render below can now use `tour.scheduledDate` and `tour.departureTime` as non-null (TS narrows them).

- [ ] **Step 3: Same guard inside the `arrivals` useMemo**

The `arrivals` memo (around line 71) uses `data.tour.departureTime`. Update to use a fallback:

```ts
return estimateTourArrivals({
  departureTime: data.tour.departureTime ?? '08:00',
  // … rest unchanged
});
```

- [ ] **Step 4: Run typecheck**

```bash
pnpm typecheck
```

Expected: green.

- [ ] **Step 5: Commit**

```bash
git add app/'(tabs)'/tours/'[id].tsx'
git commit -m "feat(tours-detail): redirect draft tours to the editor"
```

---

## Task 15: `tour-card.tsx` — adapt rendering for drafts

**Files:**
- Modify: `src/ui/components/tour-card.tsx`

- [ ] **Step 1: Replace the file contents**

Replace `src/ui/components/tour-card.tsx` with:

```tsx
import { View } from 'react-native';
import { ChevronRight, Calendar, FileText } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO, formatDistanceToNow } from 'date-fns';
import { fr } from 'date-fns/locale';
import { PressScale } from '@/ui/motion/press-scale';
import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { haptics } from '@/ui/motion/haptics';
import type { Tour, TourStatus } from '@/domain/models/tour';
import { useTourKpis } from '@/state/queries/kpis';
import { formatMinutes } from '@/lib/format-minutes';
import { cn } from '@/lib/cn';

interface Props {
  tour: Tour;
  stopCount: number;
  onPress: () => void;
}

const STATUS_BG: Record<TourStatus, string> = {
  draft: 'bg-muted dark:bg-muted-dark',
  planned: 'bg-waiting dark:bg-waiting-dark',
  completed: 'bg-shorn dark:bg-shorn-dark',
};
const STATUS_TEXT: Record<TourStatus, string> = {
  draft: 'text-muted-foreground dark:text-muted-dark-foreground',
  planned: 'text-primary-foreground dark:text-primary-dark-foreground',
  completed: 'text-primary-foreground dark:text-primary-dark-foreground',
};

function formatEur(cents: number): string {
  return `${(cents / 100).toFixed(0)} €`;
}

export function TourCard({ tour, stopCount, onPress }: Props) {
  const { t } = useTranslation();
  const kpisQuery = useTourKpis(tour.status === 'draft' ? undefined : tour.id);
  const kpis = kpisQuery.data;

  if (tour.status === 'draft') {
    const titleDisplay = tour.title ?? t('tours.draft_fallback_title', {
      date: format(parseISO(tour.createdAt), 'd MMM', { locale: fr }),
    });
    const modifiedAt = formatDistanceToNow(parseISO(tour.updatedAt), { locale: fr, addSuffix: true });

    return (
      <PressScale
        onPress={() => {
          void haptics.selection();
          onPress();
        }}
        accessibilityLabel={titleDisplay}
      >
        <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-2">
          <View className="flex-row items-center justify-between">
            <View className={cn('px-2 py-0.5 rounded-full', STATUS_BG.draft)}>
              <Text className={cn('text-xs font-semibold', STATUS_TEXT.draft)}>
                {t('tours.draft_status_label')}
              </Text>
            </View>
            <ChevronRight size={18} color="#5C4E40" />
          </View>
          <View className="flex-row items-center gap-1">
            <FileText size={14} color="#5C4E40" />
            <Text className="font-semibold">{titleDisplay}</Text>
          </View>
          <Text variant="muted" className="text-xs">
            {t('tours.stop_summary_count_label', { count: stopCount })} · {t('tours.draft_modified_at', { when: modifiedAt })}
          </Text>
        </Surface>
      </PressScale>
    );
  }

  // planned / completed (existing rendering, kept identical)
  const dateString = tour.scheduledDate && tour.departureTime
    ? format(parseISO(`${tour.scheduledDate}T${tour.departureTime}:00`), 'PPPp', { locale: fr })
    : '';

  return (
    <PressScale
      onPress={() => {
        void haptics.selection();
        onPress();
      }}
      accessibilityLabel={dateString}
    >
      <Surface variant="muted" className="rounded-2xl px-4 py-3 gap-2">
        <View className="flex-row items-center justify-between">
          <View className="flex-row items-center gap-2">
            <View className={cn('px-2 py-0.5 rounded-full', STATUS_BG[tour.status])}>
              <Text className={cn('text-xs font-semibold', STATUS_TEXT[tour.status])}>
                {t(`tours.status_${tour.status}`)}
              </Text>
            </View>
          </View>
          <ChevronRight size={18} color="#5C4E40" />
        </View>

        <View className="flex-row items-center gap-1">
          <Calendar size={14} color="#5C4E40" />
          <Text className="font-semibold">{dateString}</Text>
        </View>

        {kpis ? (
          <View className="flex-row flex-wrap gap-x-3 gap-y-1">
            <Text variant="muted" className="text-xs">
              {t('tours.stops_count', { count: kpis.stopCount })}
            </Text>
            <Text variant="muted" className="text-xs">
              {kpis.animalsTotal} {t('tours.kpi_animals')}
            </Text>
            <Text variant="muted" className="text-xs">
              {kpis.distanceKm.toFixed(1)} km
            </Text>
            <Text variant="muted" className="text-xs">
              {formatMinutes(kpis.durationMinutes)}
              {kpis.driveMinutes > 0 ? ` (+${formatMinutes(kpis.driveMinutes)} ${t('tours.kpi_drive')})` : ''}
            </Text>
            <Text variant="muted" className="text-xs">
              {formatEur(kpis.revenueCents)}
            </Text>
            {kpis.travelFeeCents > 0 ? (
              <Text variant="muted" className="text-xs">
                {t('tours.kpi_travel_fees')}: {formatEur(kpis.travelFeeCents)}
              </Text>
            ) : null}
          </View>
        ) : (
          <Text variant="muted" className="text-xs">
            {t('tours.stops_count', { count: stopCount })}
          </Text>
        )}
      </Surface>
    </PressScale>
  );
}
```

- [ ] **Step 2: Run typecheck**

```bash
pnpm typecheck
```

Expected: green.

- [ ] **Step 3: Commit**

```bash
git add src/ui/components/tour-card.tsx
git commit -m "feat(TourCard): render draft status with title fallback and no KPI"
```

---

## Task 16: `app/(tabs)/tours/index.tsx` — 3-filter SegmentedControl + empty states

**Files:**
- Modify: `app/(tabs)/tours/index.tsx`

- [ ] **Step 1: Replace the file contents**

Replace `app/(tabs)/tours/index.tsx` with:

```tsx
import { useState } from 'react';
import { View } from 'react-native';
import { useRouter } from 'expo-router';
import { FlashList } from '@shopify/flash-list';
import Animated, { FadeIn, FadeOut, LinearTransition } from 'react-native-reanimated';
import { Plus, Route as RouteIcon, FileText } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { motion } from '@/ui/motion/motion-tokens';
import { Surface } from '@/ui/primitives/surface';
import { Fab } from '@/ui/primitives/fab';
import { ListSkeleton } from '@/ui/primitives/skeleton';
import { SegmentedControl } from '@/ui/components/segmented-control';
import { TourCard } from '@/ui/components/tour-card';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { CreateTourSheet } from '@/ui/components/create-tour-sheet';
import { useTours } from '@/state/queries/tours';
import type { TourStatus } from '@/domain/models/tour';
import { useMutedForegroundColor } from '@/ui/theme/colors';

type Filter = 'draft' | 'planned' | 'completed';

export default function ToursListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const mutedFg = useMutedForegroundColor();
  const [filter, setFilter] = useState<Filter>('planned');
  const [createSheetVisible, setCreateSheetVisible] = useState(false);

  const { data: tours = [], isError, isLoading, refetch } = useTours(filter as TourStatus);

  const closeSheet = () => setCreateSheetVisible(false);

  const renderEmpty = () => {
    if (filter === 'draft') {
      return (
        <EmptyState
          icon={<FileText size={48} color={mutedFg} />}
          title={t('tours.draft_empty_title')}
          message={t('tours.draft_empty_message')}
        />
      );
    }
    return (
      <EmptyState
        icon={<RouteIcon size={48} color={mutedFg} />}
        title={t('tours.empty_filtered_title')}
        message={t('tours.empty_filtered_message')}
      />
    );
  };

  return (
    <Surface className="flex-1">
      <ScreenHeader variant="root" title={t('tours.list_title')} />

      <View className="px-4 pt-1">
        <SegmentedControl<Filter>
          value={filter}
          onChange={setFilter}
          options={[
            { value: 'draft',     label: t('tours.filter_draft') },
            { value: 'planned',   label: t('tours.filter_planned') },
            { value: 'completed', label: t('tours.filter_completed') },
          ]}
        />
      </View>

      {isError ? (
        <ErrorState onRetry={() => refetch()} />
      ) : isLoading ? (
        <ListSkeleton />
      ) : tours.length === 0 ? (
        renderEmpty()
      ) : (
        <FlashList
          data={tours}
          keyExtractor={(t) => t.tour.id}
          contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 12, paddingBottom: 96 }}
          ItemSeparatorComponent={() => <View className="h-2" />}
          renderItem={({ item }) => (
            <Animated.View
              entering={FadeIn.duration(motion.duration.fast)}
              exiting={FadeOut.duration(motion.duration.fast)}
              layout={LinearTransition.duration(motion.duration.normal)}
            >
              <TourCard
                tour={item.tour}
                stopCount={item.stops.length}
                onPress={() => router.push(`/(tabs)/tours/${item.tour.id}` as never)}
              />
            </Animated.View>
          )}
        />
      )}

      <Fab
        icon={Plus}
        onPress={() => setCreateSheetVisible(true)}
        accessibilityLabel={t('tours.empty_cta')}
      />

      <CreateTourSheet
        visible={createSheetVisible}
        onClose={closeSheet}
        onPickManual={() => {
          closeSheet();
          router.push('/tour-new/draft' as never);
        }}
        onPickOptimized={() => {
          closeSheet();
          router.push('/tour-new/optimized-config' as never);
        }}
      />
    </Surface>
  );
}
```

Note: route paths to `/tour-new/...` were already updated in a previous refactor — kept as-is.

- [ ] **Step 2: Run typecheck + lint**

```bash
pnpm typecheck && pnpm lint
```

Expected: green.

- [ ] **Step 3: Commit**

```bash
git add app/'(tabs)'/tours/index.tsx
git commit -m "feat(tours-list): add Brouillons filter to SegmentedControl"
```

---

## Task 17: Final regression pass

- [ ] **Step 1: Full type/lint/test pass**

```bash
pnpm typecheck && pnpm lint && pnpm vitest run && pnpm jest --testPathPattern="tests/(data|infra|ui)/"
```

Expected: all green.

- [ ] **Step 2: Reset emulator DB and run migration smoke test**

If the emulator app is running with a previous DB state:

1. Open the app → it should boot with the new migration applied (no crash).
2. Existing tournées planifiées + terminées are intact, status preserved, dates preserved.

- [ ] **Step 3: Manual scenarios from spec §11**

Run through, in order:

1. Migration sur DB pré-existante (déjà couvert Step 2).
2. Créer un brouillon depuis FAB Manuel → pick 2 clients → Enregistrer brouillon → toast → liste filtre Planifiées (default) → switch Brouillons → card "Brouillon du 8 mai · 2 clients" présente.
3. Saisir un titre → "Mardi nord" → Enregistrer brouillon → liste affiche "Mardi nord".
4. Proximité → set pivot → Créer tournée (3) → éditeur pré-rempli → Enregistrer brouillon → 2e card.
5. Planifier un brouillon → ouvrir → Planifier → sheet date+time → Confirmer → liste switch Planifiées → tournée présente avec titre.
6. Supprimer un brouillon → bouton Supprimer le brouillon (header) → confirm → disparaît.
7. Sauver vide : ouvrir éditeur sans clients → 2 boutons disabled.
8. Min 1 client respecté.
9. Stop sans services + Planifier → confirm "Continuer ?" → planifie.
10. Stop sans services + Enregistrer brouillon → pas de prompt.
11. Édition d'une planifiée → seul Planifier visible, date/time pré-remplis.
12. Sync cloud (si compte cloud) — voir §12 spec, hors scope strict mais à valider si possible.
13. Empty state brouillons.
14. Tap card brouillon → éditeur (flash imperceptible).
15. Optimized-config flow → Enregistrer brouillon ou Planifier → conforme.

Si un scénario échoue, fix-le avant de continuer ; ne marque pas la tâche complétée.

- [ ] **Step 4: Commit count check**

```bash
git log --oneline main..HEAD
```

Expected: ~14 commits (Tasks 1, 2-4 (combined), 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16). If you bundled differently, count accordingly.

---

## Self-review notes

- **Spec coverage**: Goal 1 (status='draft', nullable date) — Tasks 2-4. Goal 2 (deux boutons) — Tasks 9, 10. Goal 3 (3 filters) — Task 16. Goal 4 (sync cloud) — automatic via existing tour sync (no task; verify in §11.12). Goal 5 (Proximité crée brouillon) — automatic via Task 11 (the editor's primary save is now `Enregistrer brouillon`). Goal 6 (titre libre) — Task 10 + Task 1 + Task 4. Goal 7 (min 1 client) — Task 10 (button disabled). Non-goals all observed.

- **Cross-task type consistency**:
  - `SaveDraftInput` and `ScheduleTourInput` (Task 8) are consumed identically in Task 11 (`draft.tsx`) and Task 12 (`edit.tsx`). Same shape.
  - `Props` of `TourDraftEditor` (Task 10) accept `tourStatus`, `initialDate`, `initialTime` as nullable, `initialTitle`, `onSaveDraft` (optional), `onSchedule` (required), `onDelete` (optional). All callers in Tasks 11 and 12 pass the right shape.
  - `Tour.title` is `string | null` everywhere it's read (Tasks 4, 10, 11, 12, 14, 15, 16).
  - `Tour.scheduledDate` and `Tour.departureTime` are `string | null` everywhere; non-null assertions are used only in `tour-detail/[id].tsx` (Task 14) where the redirect guards drafts out, and in `useNextPlannedTourForClient` / `useCompleteTour` (Task 8) where the planned-only invariant guarantees non-null at runtime.

- **Migration nuance**: the new `0008_tour_drafts.sql` migration recreates `tours`. It uses `PRAGMA foreign_keys=OFF` to avoid breaking the `tour_stops.tour_id` FK during the swap. After `RENAME`, the FK references the renamed table by name so it remains valid.

- **Known nuance**: `useUpsertTour` retains existing tour metadata (`totalDriveSeconds`, `totalRevenueCents`, etc.) when present. The new `useSaveDraft` and `useScheduleTour` do the same via `existing?.tour.totalDriveSeconds ?? null`, preserving completed-tour metrics through re-saves.

- **Files not in this plan but indirectly impacted**: a few consumers of `Tour.scheduledDate` (e.g. `useNextPlannedTourForClient` sort, `useCompleteTour` lastShearingDate) needed null-safe handling — covered in Task 8. If typecheck flags any other consumer, the implementer applies a `?? <fallback>` or non-null assertion as appropriate, with a comment noting the invariant that justifies it.
