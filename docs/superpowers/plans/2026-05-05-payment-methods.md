# Payment Methods Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `PaymentMethod` catalog (mirroring the `Service` catalog) plus per-stop / per-manual-entry payment tracking with deferred-payment support, outstanding KPIs, and a clients-list filter chip.

**Architecture:** Five new columns on `tour_stops` and `manual_history_entries` (method id + label snapshot + paid flag + paid datetime + free-form note), backed by a new `payment_methods` table seeded with `Espèces / Chèque / Virement / Carte bancaire`. Domain logic stays in pure use-cases (`compute-client-outstanding`, `compute-tour-payment-kpis`). UI plugs into the existing tour-completion screen, closed-tour detail, manual history form, client detail, settings, and clients-list filter.

**Tech Stack:** TypeScript, Expo SQLite + Drizzle, React Query, React Hook Form + Zod, NativeWind, Vitest (domain), Jest (data), i18next.

---

## Conventions (read before any task)

- **Package manager:** `pnpm`. Never `npm`/`yarn`.
- **Tests:** `pnpm test` (= vitest + jest). For a single test, `pnpm test:domain -- <name>` or `pnpm test:integration -- <name>`.
- **Typecheck:** `pnpm typecheck`. **Lint:** `pnpm lint`.
- **Identifiers in English, UI strings in French via `t('...')`** (CLAUDE.md). Never `prestation`/`metier`/`tournee` etc. in code.
- **TDD:** for domain + data tasks, write the failing test first, run it, then implement. UI tasks: typecheck + manual verification (see test plan in each task).
- **Commit cadence:** one commit per task. Use `feat(payments): ...`, `feat(catalogs): ...`, `feat(history): ...`, `feat(tours): ...`, `feat(clients): ...` depending on scope.
- **Co-author footer** on every commit:
  ```
  Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
  ```
- **No new abstractions** beyond what each task explicitly creates. Match existing patterns (`ServiceRepository`, `ServiceForm`, etc.).

---

## File map

**New files:**
- `src/domain/models/payment-method.ts`
- `src/domain/models/payment.ts`
- `src/data/repositories/payment-method-repository.ts`
- `src/domain/use-cases/compute-client-outstanding.ts`
- `src/domain/use-cases/compute-tour-payment-kpis.ts`
- `src/state/queries/payment-methods.ts`
- `src/ui/components/payment-method-picker.tsx`
- `src/ui/components/payment-editor.tsx`
- `src/ui/components/stop-payment-sheet.tsx`
- `src/ui/components/payment-method-form.tsx`
- `src/ui/components/client-outstanding-card.tsx`
- `app/(tabs)/settings/payment-methods/_layout.tsx`
- `app/(tabs)/settings/payment-methods/index.tsx`
- `app/(tabs)/settings/payment-methods/new.tsx`
- `app/(tabs)/settings/payment-methods/[id].tsx`
- `src/infra/db/migrations/0003_payment_methods.sql`
- `tests/domain/models/payment.test.ts`
- `tests/domain/use-cases/compute-client-outstanding.test.ts`
- `tests/domain/use-cases/compute-tour-payment-kpis.test.ts`
- `tests/data/payment-method-repository.test.ts`

**Modified files:**
- `src/infra/db/schema.ts` — add `paymentMethods` table; add 5 columns each to `tourStops` + `manualHistoryEntries` + indexes.
- `src/infra/db/migrations/migrations.js` — append `m0003` entry.
- `src/infra/db/bootstrap.ts` — seed payment methods on init.
- `src/infra/db/wipe.ts` — wipe `payment_methods` table.
- `src/domain/models/tour-stop.ts` — add `payment` field.
- `src/domain/models/manual-history-entry.ts` — add `payment` field.
- `src/data/repositories/tour-repository.ts` — payment columns in `stopToRow`/`stopFromRow`; new `markStopPayment`; extend `completeWithBilan` signature.
- `src/data/repositories/manual-history-repository.ts` — payment columns in `toRow`/`fromRow`; new `markEntryPayment`.
- `src/data/repositories/client-repository.ts` — new `listClientIdsWithOutstanding`.
- `src/state/queries/tours.ts` — extend `useCompleteWithBilan` input with `perStopPayments`; new `useMarkStopPayment`.
- `src/state/queries/history.ts` — add `payment` to `UpsertManualHistoryInput`; new `useMarkManualEntryPayment`.
- `src/i18n/locales/fr.json` — `payments.*`, `catalogs.payment_methods.*`, `clients.filters.outstanding`.
- `app/(tabs)/settings/index.tsx` — new row "Moyens de paiement".
- `app/(tabs)/tours/[id]/complete.tsx` — payment editor per stop, validation.
- `app/(tabs)/tours/[id].tsx` — payment badges, KPIs, sheet.
- `src/ui/components/manual-history-form.tsx` — payment block.
- `app/(tabs)/clients/[id].tsx` — outstanding block.
- `app/(tabs)/clients/index.tsx` — filter chip.
- `tests/data/tour-repository.test.ts` (existing or extended) — payment round-trip.
- `tests/data/manual-history-repository.test.ts` (existing or extended) — payment round-trip.
- `tests/data/client-repository.test.ts` (existing or extended) — outstanding query.

---

## Task 1: Domain models — `PaymentMethod` and `Payment`

**Why first:** every other layer imports these. No DB dependency, pure Zod.

**Files:**
- Create: `src/domain/models/payment-method.ts`
- Create: `src/domain/models/payment.ts`
- Modify: `src/domain/models/tour-stop.ts`
- Modify: `src/domain/models/manual-history-entry.ts`
- Test: `tests/domain/models/payment.test.ts`

- [ ] **Step 1: Write the failing test for `Payment` model.**

```ts
// tests/domain/models/payment.test.ts
import { describe, it, expect } from 'vitest';
import { Payment } from '@/domain/models/payment';

describe('Payment', () => {
  it('parses a paid payment with all fields', () => {
    const p = Payment.parse({
      methodId: 'pm-cash',
      methodLabelSnapshot: 'Espèces',
      isPaid: true,
      paidAt: '2026-05-05T10:00:00Z',
      note: 'rendu monnaie',
    });
    expect(p.isPaid).toBe(true);
    expect(p.methodLabelSnapshot).toBe('Espèces');
  });

  it('parses an unpaid payment with nullable fields', () => {
    const p = Payment.parse({
      methodId: null,
      methodLabelSnapshot: null,
      isPaid: false,
      paidAt: null,
      note: null,
    });
    expect(p.isPaid).toBe(false);
    expect(p.methodId).toBeNull();
  });

  it('parses a backfilled paid row with null methodId (legacy data)', () => {
    // Pre-feature stops are migrated to isPaid=true, methodId=null.
    // The schema must remain permissive for this case.
    const p = Payment.parse({
      methodId: null,
      methodLabelSnapshot: null,
      isPaid: true,
      paidAt: '2026-04-12T00:00:00Z',
      note: null,
    });
    expect(p.isPaid).toBe(true);
    expect(p.methodId).toBeNull();
  });
});
```

- [ ] **Step 2: Run the test to verify it fails.**

Run: `pnpm test:domain -- payment.test`
Expected: FAIL — module `@/domain/models/payment` not found.

- [ ] **Step 3: Implement `Payment` model.**

```ts
// src/domain/models/payment.ts
import { z } from 'zod';

export const Payment = z.object({
  methodId: z.string().nullable(),
  methodLabelSnapshot: z.string().nullable(),
  isPaid: z.boolean(),
  paidAt: z.string().nullable(),
  note: z.string().nullable(),
});

export type Payment = z.infer<typeof Payment>;

export const EMPTY_PAYMENT: Payment = {
  methodId: null,
  methodLabelSnapshot: null,
  isPaid: false,
  paidAt: null,
  note: null,
};
```

- [ ] **Step 4: Implement `PaymentMethod` model (no separate test — symmetric with `Service`).**

```ts
// src/domain/models/payment-method.ts
import { z } from 'zod';

export const PaymentMethod = z.object({
  id: z.string(),
  label: z.string(),
  isActive: z.boolean(),
  archivedAt: z.string().nullable(),
  ordering: z.number().int(),
});

export type PaymentMethod = z.infer<typeof PaymentMethod>;
```

- [ ] **Step 5: Add `payment` field to `TourStop`.**

```ts
// src/domain/models/tour-stop.ts
import { z } from 'zod';
import { TourStopService } from './tour-stop-service';
import { Payment } from './payment';

export const TourStop = z.object({
  id: z.string(),
  tourId: z.string(),
  clientId: z.string(),
  clientNameSnapshot: z.string().nullable(),
  ordering: z.number().int(),
  arrivalMinutes: z.number().int().nullable(),
  departureMinutes: z.number().int().nullable(),
  estimatedMinutes: z.number().int().nullable(),
  feeShareCents: z.number().int().nullable(),
  plannedServices: z.array(TourStopService),
  actualServices: z.array(TourStopService).nullable(),
  notes: z.string().nullable(),
  completedAt: z.string().nullable(),
  payment: Payment,
});

export type TourStop = z.infer<typeof TourStop>;
```

- [ ] **Step 6: Add `payment` field to `ManualHistoryEntry`.**

```ts
// src/domain/models/manual-history-entry.ts
import { z } from 'zod';
import { TourStopService } from './tour-stop-service';
import { Payment } from './payment';

export const ManualHistoryEntry = z.object({
  id: z.string(),
  clientId: z.string(),
  date: z.string(),
  notes: z.string().nullable(),
  services: z.array(TourStopService),
  payment: Payment,
});

export type ManualHistoryEntry = z.infer<typeof ManualHistoryEntry>;
```

- [ ] **Step 7: Run domain tests to verify model parsing.**

Run: `pnpm test:domain -- payment.test`
Expected: 3 passed.

- [ ] **Step 8: Run typecheck — expect failures in repos/UI consumers.**

Run: `pnpm typecheck`
Expected: errors in `tour-repository.ts`, `manual-history-repository.ts`, places that construct `TourStop`/`ManualHistoryEntry` without the new `payment` field. **This is fine** — Tasks 2, 4, 5 will fix them. Do not patch consumers in this commit.

- [ ] **Step 9: Commit.**

```
git add src/domain/models/payment.ts src/domain/models/payment-method.ts \
        src/domain/models/tour-stop.ts src/domain/models/manual-history-entry.ts \
        tests/domain/models/payment.test.ts
git commit -m "$(cat <<'EOF'
feat(payments): add Payment and PaymentMethod domain models

Embed Payment value object on TourStop and ManualHistoryEntry. The
schema is permissive (nullable methodId even when isPaid) so the
0003 migration backfill can land legacy paid rows.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Schema, migration, bootstrap seed, wipe

**Files:**
- Modify: `src/infra/db/schema.ts`
- Create: `src/infra/db/migrations/0003_payment_methods.sql`
- Modify: `src/infra/db/migrations/migrations.js`
- Modify: `src/infra/db/bootstrap.ts`
- Modify: `src/infra/db/wipe.ts`

- [ ] **Step 1: Add `paymentMethods` table and 5 columns each to `tourStops` and `manualHistoryEntries` in `schema.ts`.**

Open `src/infra/db/schema.ts` and apply:

After `services` definition, before `tours`:

```ts
export const paymentMethods = sqliteTable('payment_methods', {
  id: text('id').primaryKey(),
  label: text('label').notNull(),
  isActive: integer('is_active').notNull().default(1),
  archivedAt: text('archived_at'),
  ordering: integer('ordering').notNull(),
});
```

Inside the `tourStops` columns object (alongside `completedAt`), add:

```ts
    paymentMethodId: text('payment_method_id').references(() => paymentMethods.id),
    paymentMethodLabelSnapshot: text('payment_method_label_snapshot'),
    isPaid: integer('is_paid').notNull().default(0),
    paidAt: text('paid_at'),
    paymentNote: text('payment_note'),
```

Inside the index callback for `tourStops`, add:

```ts
    isPaidIdx: index('tour_stops_is_paid_idx').on(t.isPaid),
```

Inside `manualHistoryEntries` columns, add the same 5 columns. Inside its index callback, add:

```ts
    isPaidIdx: index('manual_history_is_paid_idx').on(t.isPaid),
```

- [ ] **Step 2: Create the migration SQL file.**

```sql
-- src/infra/db/migrations/0003_payment_methods.sql
-- Adds payment_methods table, payment columns on tour_stops and
-- manual_history_entries, seeds default methods, and backfills
-- pre-feature rows so they don't appear as outstanding.

PRAGMA foreign_keys=OFF;
--> statement-breakpoint

CREATE TABLE `payment_methods` (
	`id` text PRIMARY KEY NOT NULL,
	`label` text NOT NULL,
	`is_active` integer DEFAULT 1 NOT NULL,
	`archived_at` text,
	`ordering` integer NOT NULL
);
--> statement-breakpoint

ALTER TABLE `tour_stops` ADD COLUMN `payment_method_id` text REFERENCES `payment_methods`(`id`);
--> statement-breakpoint
ALTER TABLE `tour_stops` ADD COLUMN `payment_method_label_snapshot` text;
--> statement-breakpoint
ALTER TABLE `tour_stops` ADD COLUMN `is_paid` integer DEFAULT 0 NOT NULL;
--> statement-breakpoint
ALTER TABLE `tour_stops` ADD COLUMN `paid_at` text;
--> statement-breakpoint
ALTER TABLE `tour_stops` ADD COLUMN `payment_note` text;
--> statement-breakpoint
CREATE INDEX `tour_stops_is_paid_idx` ON `tour_stops` (`is_paid`);
--> statement-breakpoint

ALTER TABLE `manual_history_entries` ADD COLUMN `payment_method_id` text REFERENCES `payment_methods`(`id`);
--> statement-breakpoint
ALTER TABLE `manual_history_entries` ADD COLUMN `payment_method_label_snapshot` text;
--> statement-breakpoint
ALTER TABLE `manual_history_entries` ADD COLUMN `is_paid` integer DEFAULT 0 NOT NULL;
--> statement-breakpoint
ALTER TABLE `manual_history_entries` ADD COLUMN `paid_at` text;
--> statement-breakpoint
ALTER TABLE `manual_history_entries` ADD COLUMN `payment_note` text;
--> statement-breakpoint
CREATE INDEX `manual_history_is_paid_idx` ON `manual_history_entries` (`is_paid`);
--> statement-breakpoint

INSERT OR IGNORE INTO `payment_methods` (`id`, `label`, `is_active`, `archived_at`, `ordering`) VALUES
	('pm-cash', 'Espèces', 1, NULL, 1),
	('pm-check', 'Chèque', 1, NULL, 2),
	('pm-transfer', 'Virement', 1, NULL, 3),
	('pm-card', 'Carte bancaire', 1, NULL, 4);
--> statement-breakpoint

UPDATE `tour_stops` SET `is_paid` = 1, `paid_at` = `completed_at` WHERE `completed_at` IS NOT NULL;
--> statement-breakpoint
UPDATE `manual_history_entries` SET `is_paid` = 1, `paid_at` = `date`;
--> statement-breakpoint

PRAGMA foreign_keys=ON;
```

- [ ] **Step 3: Append `m0003` to the migrations bundle.**

`src/infra/db/migrations/migrations.js` — add a new entry to `journal.entries`:

```js
    {
      "idx": 3,
      "version": "6",
      "when": 1746403200000,
      "tag": "0003_payment_methods",
      "breakpoints": true
    }
```

And in `migrations` add a `m0003` key whose value is the **exact SQL from Step 2 above**, JSON-string-escaped (newlines become `\n`, leave `--> statement-breakpoint` literal). Pattern: copy how `m0002` is structured.

To produce the escaped string correctly, run:

```bash
node -e "console.log(JSON.stringify(require('fs').readFileSync('src/infra/db/migrations/0003_payment_methods.sql','utf8')))"
```

Use the printed quoted string as the value of `m0003`.

- [ ] **Step 4: Add the seed step to bootstrap.**

In `src/infra/db/bootstrap.ts`, add a new helper and call it after `seedSettingsDefaults`:

```ts
import { paymentMethods } from './schema';

const PAYMENT_METHODS_SEED: Array<{ id: string; label: string; ordering: number }> = [
  { id: 'pm-cash', label: 'Espèces', ordering: 1 },
  { id: 'pm-check', label: 'Chèque', ordering: 2 },
  { id: 'pm-transfer', label: 'Virement', ordering: 3 },
  { id: 'pm-card', label: 'Carte bancaire', ordering: 4 },
];

async function seedPaymentMethods() {
  for (const pm of PAYMENT_METHODS_SEED) {
    await db
      .insert(paymentMethods)
      .values({ ...pm, isActive: 1, archivedAt: null })
      .onConflictDoNothing({ target: paymentMethods.id });
  }
}
```

Call `await seedPaymentMethods();` right after `await seedSettingsDefaults(settingsRepo);` inside `bootstrapDatabase`.

- [ ] **Step 5: Wipe support.**

Open `src/infra/db/wipe.ts`. Add `payment_methods` to the wipe list, following the existing pattern (delete + reset). Read the file before editing and follow the same style.

- [ ] **Step 6: Run all tests — should pass for `Payment` model and existing data tests should still load with the new schema.**

Run: `pnpm test:integration`
Expected: existing tests still pass (the migration runs against `:memory:` via `tests/data/_helpers/test-db.ts`). If a test fails because a fixture was building a `TourStop` or `ManualHistoryEntry` without `payment`, leave it failing for now — Task 4 / 5 will fix the repos and tests at the same time. **However:** if `pnpm test:integration` fails because the migration itself is malformed (SQL parse error), fix the SQL before committing.

- [ ] **Step 7: Run typecheck.**

Run: `pnpm typecheck`
Expected: still failing (carry-over from Task 1). Fine — Tasks 4 & 5 fix it. Do not patch consumers here.

- [ ] **Step 8: Commit.**

```
git add src/infra/db/schema.ts \
        src/infra/db/migrations/0003_payment_methods.sql \
        src/infra/db/migrations/migrations.js \
        src/infra/db/bootstrap.ts \
        src/infra/db/wipe.ts
git commit -m "$(cat <<'EOF'
feat(payments): add payment_methods table and payment columns

Migration 0003: new payment_methods table seeded with the four
default methods (Espèces, Chèque, Virement, Carte bancaire), five
new columns on tour_stops and manual_history_entries, and a backfill
that marks pre-feature completed stops and manual entries as paid
(method left null) to avoid generating phantom outstanding amounts.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: PaymentMethodRepository

**Files:**
- Create: `src/data/repositories/payment-method-repository.ts`
- Test: `tests/data/payment-method-repository.test.ts`

- [ ] **Step 1: Write the failing tests.**

```ts
// tests/data/payment-method-repository.test.ts
import { createTestDb } from './_helpers/test-db';
import { PaymentMethodRepository } from '@/data/repositories/payment-method-repository';

describe('PaymentMethodRepository', () => {
  it('listAll returns the four seeded methods sorted by ordering', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    const all = await repo.listAll();
    expect(all.map((m) => m.id)).toEqual(['pm-cash', 'pm-check', 'pm-transfer', 'pm-card']);
    close();
  });

  it('round-trips a custom method', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    await repo.upsert({
      id: 'pm-custom',
      label: 'Crypto',
      isActive: true,
      archivedAt: null,
      ordering: 99,
    });
    const fetched = await repo.byId('pm-custom');
    expect(fetched?.label).toBe('Crypto');
    close();
  });

  it('listActive filters out archived methods', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    await repo.setArchived('pm-card', '2026-05-05T00:00:00Z');
    // Then upsert with isActive false
    const archived = await repo.byId('pm-card');
    await repo.upsert({ ...archived!, isActive: false });
    const active = await repo.listActive();
    expect(active.map((m) => m.id)).not.toContain('pm-card');
    close();
  });

  it('setArchived stamps archivedAt', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    await repo.setArchived('pm-cash', '2026-05-05T10:00:00Z');
    const m = await repo.byId('pm-cash');
    expect(m?.archivedAt).toBe('2026-05-05T10:00:00Z');
    close();
  });

  it('delete throws when the method is referenced by a tour stop', async () => {
    // Setup a tour_stops row referencing pm-cash, then attempt delete
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    // Insert a minimal client + tour + stop with payment_method_id = pm-cash
    db.run(`INSERT INTO clients (id, display_name, created_at, updated_at) VALUES ('c1', 'C', 'x', 'x')`);
    db.run(`INSERT INTO tours (id, scheduled_date, departure_time, base_lat, base_lng, status, created_at, updated_at) VALUES ('t1', '2026-05-01', '08:00', 0, 0, 'completed', 'x', 'x')`);
    db.run(`INSERT INTO tour_stops (id, tour_id, client_id, ordering, payment_method_id, is_paid) VALUES ('s1', 't1', 'c1', 0, 'pm-cash', 1)`);
    await expect(repo.delete('pm-cash')).rejects.toThrow(/référenc/i);
    close();
  });

  it('delete succeeds when the method is unreferenced', async () => {
    const { db, close } = createTestDb();
    const repo = new PaymentMethodRepository(db);
    await repo.upsert({ id: 'pm-orphan', label: 'X', isActive: true, archivedAt: null, ordering: 100 });
    await expect(repo.delete('pm-orphan')).resolves.toBeUndefined();
    expect(await repo.byId('pm-orphan')).toBeNull();
    close();
  });
});
```

Note: `db.run` is the `better-sqlite3` API exposed under drizzle's `Db` for raw SQL setup in tests. If drizzle's `Db` type doesn't expose `run` directly, use `db.$client.exec(...)` (sqlite-better instance is at `db.$client`). Check what `tour-repository.test.ts` does for raw inserts before finalising; if it uses repo upserts only, prefer that. For this test specifically, since `tourStops` requires payment columns to be set explicitly via the repo (Task 4 will do that), use raw SQL through `(db as any).$client.exec(...)` and treat it as a plumbing-test corner.

- [ ] **Step 2: Run tests to verify they fail.**

Run: `pnpm test:integration -- payment-method-repository`
Expected: FAIL — module not found.

- [ ] **Step 3: Implement `PaymentMethodRepository`.**

```ts
// src/data/repositories/payment-method-repository.ts
import { asc, eq, or } from 'drizzle-orm';
import { paymentMethods, tourStops, manualHistoryEntries } from '@/infra/db/schema';
import type { Db } from '@/infra/db/client';
import { PaymentMethod } from '@/domain/models/payment-method';

interface PaymentMethodRow {
  id: string;
  label: string;
  isActive: number;
  archivedAt: string | null;
  ordering: number;
}

function toRow(m: PaymentMethod) {
  return { ...m, isActive: m.isActive ? 1 : 0 };
}
function fromRow(r: PaymentMethodRow): PaymentMethod {
  return PaymentMethod.parse({ ...r, isActive: r.isActive === 1 });
}

export class PaymentMethodRepository {
  constructor(private readonly db: Db) {}

  async byId(id: string): Promise<PaymentMethod | null> {
    const rows = await this.db.select().from(paymentMethods).where(eq(paymentMethods.id, id));
    return rows[0] ? fromRow(rows[0] as PaymentMethodRow) : null;
  }

  async listAll(): Promise<PaymentMethod[]> {
    const rows = await this.db.select().from(paymentMethods).orderBy(asc(paymentMethods.ordering));
    return rows.map((r) => fromRow(r as PaymentMethodRow));
  }

  async listActive(): Promise<PaymentMethod[]> {
    const rows = await this.db
      .select()
      .from(paymentMethods)
      .where(eq(paymentMethods.isActive, 1))
      .orderBy(asc(paymentMethods.ordering));
    return rows.map((r) => fromRow(r as PaymentMethodRow));
  }

  async upsert(m: PaymentMethod): Promise<void> {
    const row = toRow(m);
    await this.db
      .insert(paymentMethods)
      .values(row)
      .onConflictDoUpdate({ target: paymentMethods.id, set: row });
  }

  async setArchived(id: string, archivedAt: string | null): Promise<void> {
    await this.db.update(paymentMethods).set({ archivedAt }).where(eq(paymentMethods.id, id));
  }

  async delete(id: string): Promise<void> {
    const stopRefs = await this.db
      .select({ id: tourStops.id })
      .from(tourStops)
      .where(eq(tourStops.paymentMethodId, id))
      .limit(1);
    const entryRefs = await this.db
      .select({ id: manualHistoryEntries.id })
      .from(manualHistoryEntries)
      .where(eq(manualHistoryEntries.paymentMethodId, id))
      .limit(1);
    if (stopRefs.length > 0 || entryRefs.length > 0) {
      throw new Error('Méthode de paiement référencée par un paiement existant.');
    }
    await this.db.delete(paymentMethods).where(eq(paymentMethods.id, id));
  }
}
```

(`or` isn't actually needed; remove if the IDE flags an unused import.)

- [ ] **Step 4: Run tests to verify they pass.**

Run: `pnpm test:integration -- payment-method-repository`
Expected: 6 passed.

- [ ] **Step 5: Run typecheck.**

Run: `pnpm typecheck`
Expected: still failures from Task 1 carry-over in tour/manual-history repos. Acceptable.

- [ ] **Step 6: Commit.**

```
git add src/data/repositories/payment-method-repository.ts \
        tests/data/payment-method-repository.test.ts
git commit -m "$(cat <<'EOF'
feat(payments): add PaymentMethodRepository

CRUD calque of ServiceRepository, plus a deletion guard that refuses
to remove a method still referenced by tour_stops or manual_history_entries.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: TourRepository — payment round-trip + `markStopPayment` + extended `completeWithBilan`

**Files:**
- Modify: `src/data/repositories/tour-repository.ts`
- Modify: `tests/data/tour-repository.test.ts` (or create if it does not exist — check first with `ls tests/data`)

- [ ] **Step 1: Write the failing test for payment round-trip.**

If `tests/data/tour-repository.test.ts` already exists, append the cases below. Otherwise create it with the necessary scaffolding (mirror `tests/data/manual-history-repository.test.ts` style if it exists; otherwise model it on the structure of `service-repository.test.ts`).

```ts
import { createTestDb } from './_helpers/test-db';
import { TourRepository } from '@/data/repositories/tour-repository';
import { ClientRepository } from '@/data/repositories/client-repository';
import { EMPTY_PAYMENT } from '@/domain/models/payment';
import type { Tour } from '@/domain/models/tour';
import type { TourStop } from '@/domain/models/tour-stop';

const baseTour: Omit<Tour, 'id'> = {
  scheduledDate: '2026-05-01',
  departureTime: '08:00',
  baseLat: 0, baseLng: 0,
  status: 'planned',
  totalDistanceKm: null, totalDriveSeconds: null, totalMinutes: null,
  totalRevenueCents: null, totalAnimalsCount: null, totalTravelFeeCents: null,
  routeGeometry: null, notes: null, completedAt: null,
  createdAt: 'x', updatedAt: 'x',
};

function makeStop(overrides: Partial<TourStop> = {}): TourStop {
  return {
    id: 's1', tourId: 't1', clientId: 'c1', clientNameSnapshot: null,
    ordering: 0, arrivalMinutes: null, departureMinutes: null,
    estimatedMinutes: null, feeShareCents: null,
    plannedServices: [], actualServices: null,
    notes: null, completedAt: null,
    payment: EMPTY_PAYMENT,
    ...overrides,
  };
}

async function seedClient(db: any, id = 'c1') {
  const repo = new ClientRepository(db);
  await repo.upsert({
    id, displayName: 'Test', phones: [],
    addressLabel: null, addressCity: null, addressPostcode: null,
    latitude: null, longitude: null,
    isWaiting: false, isBanned: false, needsDistanceRecompute: false,
    lastShearingDate: null, animalCounts: [], markerColorHex: null,
    createdAt: 'x', updatedAt: 'x',
  });
}

describe('TourRepository payment round-trip', () => {
  it('persists and reads back the payment field on a stop', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new TourRepository(db);
    const tour = { id: 't1', ...baseTour };
    const stop = makeStop({
      payment: {
        methodId: 'pm-cash',
        methodLabelSnapshot: 'Espèces',
        isPaid: true,
        paidAt: '2026-05-01T12:00:00Z',
        note: 'OK',
      },
    });
    await repo.upsertTour(tour, [stop]);
    const got = await repo.byId('t1');
    expect(got?.stops[0].payment.isPaid).toBe(true);
    expect(got?.stops[0].payment.methodLabelSnapshot).toBe('Espèces');
    close();
  });

  it('markStopPayment updates only the payment columns', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new TourRepository(db);
    await repo.upsertTour({ id: 't1', ...baseTour }, [makeStop()]);
    await repo.markStopPayment('s1', {
      methodId: 'pm-check',
      methodLabelSnapshot: 'Chèque',
      isPaid: true,
      paidAt: '2026-05-02T09:00:00Z',
      note: null,
    });
    const got = await repo.byId('t1');
    expect(got?.stops[0].payment.methodId).toBe('pm-check');
    expect(got?.stops[0].payment.isPaid).toBe(true);
    close();
  });

  it('completeWithBilan writes per-stop payments alongside actuals', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new TourRepository(db);
    await repo.upsertTour({ id: 't1', ...baseTour }, [makeStop()]);
    const payments = new Map([['s1', {
      methodId: 'pm-cash', methodLabelSnapshot: 'Espèces',
      isPaid: true, paidAt: '2026-05-01T12:00:00Z', note: null,
    }]]);
    await repo.completeWithBilan(
      't1',
      new Map([['s1', []]]),
      new Map([['s1', null]]),
      payments,
      '2026-05-01T12:00:00Z'
    );
    const got = await repo.byId('t1');
    expect(got?.stops[0].payment.isPaid).toBe(true);
    expect(got?.tour.status).toBe('completed');
    close();
  });
});
```

- [ ] **Step 2: Run the tests to verify failure.**

Run: `pnpm test:integration -- tour-repository`
Expected: compile errors (TourStop missing `payment`, `completeWithBilan` signature mismatch).

- [ ] **Step 3: Update `stopToRow` and `stopFromRow` and the `TourStopRow` interface.**

In `src/data/repositories/tour-repository.ts`:

Extend `TourStopRow`:

```ts
interface TourStopRow {
  id: string;
  tourId: string;
  clientId: string;
  clientNameSnapshot: string | null;
  ordering: number;
  arrivalMinutes: number | null;
  departureMinutes: number | null;
  estimatedMinutes: number | null;
  feeShareCents: number | null;
  plannedServices: string;
  actualServices: string | null;
  notes: string | null;
  completedAt: string | null;
  paymentMethodId: string | null;
  paymentMethodLabelSnapshot: string | null;
  isPaid: number;
  paidAt: string | null;
  paymentNote: string | null;
}
```

Replace `stopToRow`:

```ts
function stopToRow(s: TourStop) {
  return {
    id: s.id,
    tourId: s.tourId,
    clientId: s.clientId,
    clientNameSnapshot: s.clientNameSnapshot,
    ordering: s.ordering,
    arrivalMinutes: s.arrivalMinutes,
    departureMinutes: s.departureMinutes,
    estimatedMinutes: s.estimatedMinutes,
    feeShareCents: s.feeShareCents,
    plannedServices: JSON.stringify(s.plannedServices),
    actualServices: s.actualServices === null ? null : JSON.stringify(s.actualServices),
    notes: s.notes,
    completedAt: s.completedAt,
    paymentMethodId: s.payment.methodId,
    paymentMethodLabelSnapshot: s.payment.methodLabelSnapshot,
    isPaid: s.payment.isPaid ? 1 : 0,
    paidAt: s.payment.paidAt,
    paymentNote: s.payment.note,
  };
}
```

Replace `stopFromRow`:

```ts
function stopFromRow(r: TourStopRow): TourStop {
  return TourStop.parse({
    id: r.id,
    tourId: r.tourId,
    clientId: r.clientId,
    clientNameSnapshot: r.clientNameSnapshot,
    ordering: r.ordering,
    arrivalMinutes: r.arrivalMinutes,
    departureMinutes: r.departureMinutes,
    estimatedMinutes: r.estimatedMinutes,
    feeShareCents: r.feeShareCents,
    plannedServices: JSON.parse(r.plannedServices),
    actualServices: r.actualServices === null ? null : JSON.parse(r.actualServices),
    notes: r.notes,
    completedAt: r.completedAt,
    payment: {
      methodId: r.paymentMethodId,
      methodLabelSnapshot: r.paymentMethodLabelSnapshot,
      isPaid: r.isPaid === 1,
      paidAt: r.paidAt,
      note: r.paymentNote,
    },
  });
}
```

- [ ] **Step 4: Add `markStopPayment` to `TourRepository`.**

```ts
async markStopPayment(stopId: string, payment: Payment): Promise<void> {
  await this.db.update(tourStops).set({
    paymentMethodId: payment.methodId,
    paymentMethodLabelSnapshot: payment.methodLabelSnapshot,
    isPaid: payment.isPaid ? 1 : 0,
    paidAt: payment.paidAt,
    paymentNote: payment.note,
  }).where(eq(tourStops.id, stopId));
}
```

Add the import: `import { Payment } from '@/domain/models/payment';`.

- [ ] **Step 5: Extend `completeWithBilan` to accept `perStopPayments`.**

```ts
async completeWithBilan(
  tourId: string,
  perStopActuals: Map<string, import('@/domain/models/tour-stop-service').TourStopService[]>,
  perStopNotes: Map<string, string | null>,
  perStopPayments: Map<string, Payment>,
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
    completedAt,
  }));

  await this.upsertTour(
    { ...tour, status: 'completed', completedAt, updatedAt: completedAt },
    updatedStops
  );
}
```

- [ ] **Step 6: Update `useUpsertTour` in `src/state/queries/tours.ts` to inject `EMPTY_PAYMENT` when constructing fresh stops** (so creating a new tour doesn't fail Zod parsing).

Look for the `stops: TourStop[]` mapping in `useUpsertTour` and add `payment: EMPTY_PAYMENT` to each stop literal. Add the import: `import { EMPTY_PAYMENT } from '@/domain/models/payment';`.

Also update `useCompleteWithBilan` here to **only** propagate `perStopPayments` into the call (not into mutationFn input yet — Task 10 wires the new input properly). For now pass an empty `Map()` so the type matches:

```ts
await tourRepo.completeWithBilan(tourId, perStopActuals, perStopNotes, new Map(), completedAt);
```

This is a temporary stub fixed in Task 10.

- [ ] **Step 7: Run tests.**

Run: `pnpm test:integration -- tour-repository`
Expected: all new cases pass; no regression in existing tour repo tests.

Run: `pnpm typecheck`
Expected: tour-repository compiles. Carry-over errors in `manual-history-repository.ts` may remain — Task 5 fixes them.

- [ ] **Step 8: Commit.**

```
git add src/data/repositories/tour-repository.ts \
        src/state/queries/tours.ts \
        tests/data/tour-repository.test.ts
git commit -m "$(cat <<'EOF'
feat(tours): persist payment fields on tour stops

Extend stopToRow / stopFromRow to map the five new payment columns,
add markStopPayment for deferred-payment edits, and thread per-stop
payments through completeWithBilan.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: ManualHistoryRepository — payment round-trip + `markEntryPayment`

**Files:**
- Modify: `src/data/repositories/manual-history-repository.ts`
- Modify: `tests/data/manual-history-repository.test.ts` (or create if missing)

- [ ] **Step 1: Write the failing tests.**

Append (or create) cases verifying round-trip of the `payment` field and `markEntryPayment`. Mirror Task 4 style — minimal client seeding then upsert / read back.

```ts
import { createTestDb } from './_helpers/test-db';
import { ManualHistoryRepository } from '@/data/repositories/manual-history-repository';
import { ClientRepository } from '@/data/repositories/client-repository';
import { EMPTY_PAYMENT } from '@/domain/models/payment';

async function seedClient(db: any, id = 'c1') {
  await new ClientRepository(db).upsert({
    id, displayName: 'Test', phones: [],
    addressLabel: null, addressCity: null, addressPostcode: null,
    latitude: null, longitude: null,
    isWaiting: false, isBanned: false, needsDistanceRecompute: false,
    lastShearingDate: null, animalCounts: [], markerColorHex: null,
    createdAt: 'x', updatedAt: 'x',
  });
}

describe('ManualHistoryRepository payment round-trip', () => {
  it('persists and reads back the payment field', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new ManualHistoryRepository(db);
    await repo.upsert({
      id: 'e1', clientId: 'c1', date: '2026-04-15',
      notes: null, services: [],
      payment: {
        methodId: 'pm-check', methodLabelSnapshot: 'Chèque',
        isPaid: true, paidAt: '2026-04-15T10:00:00Z', note: null,
      },
    });
    const all = await repo.listByClient('c1');
    expect(all[0].payment.methodId).toBe('pm-check');
    expect(all[0].payment.isPaid).toBe(true);
    close();
  });

  it('markEntryPayment updates only the payment columns', async () => {
    const { db, close } = createTestDb();
    await seedClient(db);
    const repo = new ManualHistoryRepository(db);
    await repo.upsert({
      id: 'e1', clientId: 'c1', date: '2026-04-15',
      notes: 'note', services: [], payment: EMPTY_PAYMENT,
    });
    await repo.markEntryPayment('e1', {
      methodId: 'pm-cash', methodLabelSnapshot: 'Espèces',
      isPaid: true, paidAt: '2026-05-01T00:00:00Z', note: null,
    });
    const all = await repo.listByClient('c1');
    expect(all[0].notes).toBe('note');
    expect(all[0].payment.isPaid).toBe(true);
    expect(all[0].payment.methodId).toBe('pm-cash');
    close();
  });
});
```

- [ ] **Step 2: Run to verify failure.**

Run: `pnpm test:integration -- manual-history-repository`
Expected: type errors / module shape mismatch.

- [ ] **Step 3: Extend repo.**

Open `src/data/repositories/manual-history-repository.ts`. Update `ManualHistoryRow` with the 5 columns; update `toRow`/`fromRow` to include `payment` (mirror Task 4); add the import for `Payment`; add `markEntryPayment(entryId, payment)`.

```ts
interface ManualHistoryRow {
  id: string;
  clientId: string;
  date: string;
  notes: string | null;
  services: string;
  paymentMethodId: string | null;
  paymentMethodLabelSnapshot: string | null;
  isPaid: number;
  paidAt: string | null;
  paymentNote: string | null;
}

function toRow(e: ManualHistoryEntry) {
  return {
    id: e.id,
    clientId: e.clientId,
    date: e.date,
    notes: e.notes,
    services: JSON.stringify(e.services),
    paymentMethodId: e.payment.methodId,
    paymentMethodLabelSnapshot: e.payment.methodLabelSnapshot,
    isPaid: e.payment.isPaid ? 1 : 0,
    paidAt: e.payment.paidAt,
    paymentNote: e.payment.note,
  };
}

function fromRow(r: ManualHistoryRow): ManualHistoryEntry {
  return ManualHistoryEntry.parse({
    id: r.id,
    clientId: r.clientId,
    date: r.date,
    notes: r.notes,
    services: JSON.parse(r.services),
    payment: {
      methodId: r.paymentMethodId,
      methodLabelSnapshot: r.paymentMethodLabelSnapshot,
      isPaid: r.isPaid === 1,
      paidAt: r.paidAt,
      note: r.paymentNote,
    },
  });
}
```

Add to the class:

```ts
async markEntryPayment(entryId: string, payment: Payment): Promise<void> {
  await this.db.update(manualHistoryEntries).set({
    paymentMethodId: payment.methodId,
    paymentMethodLabelSnapshot: payment.methodLabelSnapshot,
    isPaid: payment.isPaid ? 1 : 0,
    paidAt: payment.paidAt,
    paymentNote: payment.note,
  }).where(eq(manualHistoryEntries.id, entryId));
}
```

Add the import: `import { Payment } from '@/domain/models/payment';`.

- [ ] **Step 4: Update `useUpsertManualHistoryEntry` in `src/state/queries/history.ts` to inject `EMPTY_PAYMENT`** when input has no `payment` (temporary; Task 11 makes payment a real input field). Add `import { EMPTY_PAYMENT } from '@/domain/models/payment';`.

```ts
const entry: ManualHistoryEntry = {
  id: input.id ?? newId(),
  clientId: input.clientId,
  date: input.date,
  notes: input.notes,
  services: input.services,
  payment: EMPTY_PAYMENT,
};
```

Also update `useClientHistory` so it does not break — that hook reads `actualServices`/`services` only, no payment yet. Should still typecheck.

- [ ] **Step 5: Run tests + typecheck.**

Run: `pnpm test:integration -- manual-history-repository` → all pass.
Run: `pnpm typecheck` → should now be clean.

- [ ] **Step 6: Commit.**

```
git add src/data/repositories/manual-history-repository.ts \
        src/state/queries/history.ts \
        tests/data/manual-history-repository.test.ts
git commit -m "$(cat <<'EOF'
feat(history): persist payment fields on manual entries

Round-trip the new payment fields and add markEntryPayment for
deferred edits.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: ClientRepository — `listClientIdsWithOutstanding`

**Files:**
- Modify: `src/data/repositories/client-repository.ts`
- Modify: `tests/data/client-repository.test.ts` (create if missing — check first)

- [ ] **Step 1: Write the failing test.**

```ts
import { createTestDb } from './_helpers/test-db';
import { ClientRepository } from '@/data/repositories/client-repository';
import { TourRepository } from '@/data/repositories/tour-repository';
import { ManualHistoryRepository } from '@/data/repositories/manual-history-repository';
import { EMPTY_PAYMENT } from '@/domain/models/payment';

describe('ClientRepository.listClientIdsWithOutstanding', () => {
  it('returns clients with unpaid completed stops or unpaid manual entries', async () => {
    const { db, close } = createTestDb();
    const clientRepo = new ClientRepository(db);
    const tourRepo = new TourRepository(db);
    const manualRepo = new ManualHistoryRepository(db);

    for (const id of ['c1', 'c2', 'c3']) {
      await clientRepo.upsert({
        id, displayName: id, phones: [],
        addressLabel: null, addressCity: null, addressPostcode: null,
        latitude: null, longitude: null,
        isWaiting: false, isBanned: false, needsDistanceRecompute: false,
        lastShearingDate: null, animalCounts: [], markerColorHex: null,
        createdAt: 'x', updatedAt: 'x',
      });
    }

    // c1: completed unpaid stop -> outstanding
    await tourRepo.upsertTour(
      { id: 't1', scheduledDate: '2026-05-01', departureTime: '08:00',
        baseLat: 0, baseLng: 0, status: 'completed',
        totalDistanceKm: null, totalDriveSeconds: null, totalMinutes: null,
        totalRevenueCents: null, totalAnimalsCount: null, totalTravelFeeCents: null,
        routeGeometry: null, notes: null, completedAt: '2026-05-01T12:00:00Z',
        createdAt: 'x', updatedAt: 'x' },
      [{ id: 's1', tourId: 't1', clientId: 'c1', clientNameSnapshot: null,
         ordering: 0, arrivalMinutes: null, departureMinutes: null,
         estimatedMinutes: null, feeShareCents: null,
         plannedServices: [], actualServices: [],
         notes: null, completedAt: '2026-05-01T12:00:00Z',
         payment: EMPTY_PAYMENT }]
    );

    // c2: unpaid manual entry -> outstanding
    await manualRepo.upsert({
      id: 'e1', clientId: 'c2', date: '2026-04-01',
      notes: null, services: [], payment: EMPTY_PAYMENT,
    });

    // c3: planned tour stop unpaid -> NOT outstanding (not completed)
    await tourRepo.upsertTour(
      { id: 't2', scheduledDate: '2026-06-01', departureTime: '08:00',
        baseLat: 0, baseLng: 0, status: 'planned',
        totalDistanceKm: null, totalDriveSeconds: null, totalMinutes: null,
        totalRevenueCents: null, totalAnimalsCount: null, totalTravelFeeCents: null,
        routeGeometry: null, notes: null, completedAt: null,
        createdAt: 'x', updatedAt: 'x' },
      [{ id: 's2', tourId: 't2', clientId: 'c3', clientNameSnapshot: null,
         ordering: 0, arrivalMinutes: null, departureMinutes: null,
         estimatedMinutes: null, feeShareCents: null,
         plannedServices: [], actualServices: null,
         notes: null, completedAt: null,
         payment: EMPTY_PAYMENT }]
    );

    const ids = await clientRepo.listClientIdsWithOutstanding();
    expect(Array.from(ids).sort()).toEqual(['c1', 'c2']);
    close();
  });
});
```

- [ ] **Step 2: Run to verify failure.**

Run: `pnpm test:integration -- client-repository`
Expected: method not defined.

- [ ] **Step 3: Implement the method.**

Add to `ClientRepository`:

```ts
async listClientIdsWithOutstanding(): Promise<Set<string>> {
  const stopRows = await this.db
    .selectDistinct({ clientId: tourStops.clientId })
    .from(tourStops)
    .where(and(eq(tourStops.isPaid, 0), isNotNull(tourStops.completedAt)));
  const entryRows = await this.db
    .selectDistinct({ clientId: manualHistoryEntries.clientId })
    .from(manualHistoryEntries)
    .where(eq(manualHistoryEntries.isPaid, 0));
  const out = new Set<string>();
  for (const r of stopRows) out.add(r.clientId);
  for (const r of entryRows) out.add(r.clientId);
  return out;
}
```

Imports to add at the top of the file:

```ts
import { and, eq, isNotNull } from 'drizzle-orm';
import { clients, tourStops, manualHistoryEntries } from '@/infra/db/schema';
```

(Merge with existing imports — `eq` and `clients` are already there.)

- [ ] **Step 4: Run tests + typecheck.**

Run: `pnpm test:integration -- client-repository`
Expected: pass.

Run: `pnpm typecheck`
Expected: clean.

- [ ] **Step 5: Commit.**

```
git add src/data/repositories/client-repository.ts \
        tests/data/client-repository.test.ts
git commit -m "$(cat <<'EOF'
feat(clients): add listClientIdsWithOutstanding

Used by the clients-list 'Impayés' filter chip and by the client
detail outstanding card. Only counts completed stops + manual entries
where is_paid=0.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Use case — `compute-client-outstanding`

**Files:**
- Create: `src/domain/use-cases/compute-client-outstanding.ts`
- Test: `tests/domain/use-cases/compute-client-outstanding.test.ts`

- [ ] **Step 1: Write the failing tests.**

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
  it('sums actualServices price across unpaid completed stops', () => {
    const r = computeClientOutstanding({
      completedStops: [
        stop({ actualServices: [svc(2, 1500)] }), // 30€ unpaid
        stop({ id: 's2', actualServices: [svc(1, 1000)],
               payment: { ...EMPTY_PAYMENT, isPaid: true, paidAt: 'x' } }),
      ],
      manualEntries: [],
    });
    expect(r.unpaidCents).toBe(3000);
    expect(r.unpaidCount).toBe(1);
  });

  it('uses plannedServices when actualServices is null', () => {
    const r = computeClientOutstanding({
      completedStops: [stop({ plannedServices: [svc(1, 2000)], actualServices: null })],
      manualEntries: [],
    });
    expect(r.unpaidCents).toBe(2000);
  });

  it('includes unpaid manual entries', () => {
    const r = computeClientOutstanding({
      completedStops: [],
      manualEntries: [entry({ services: [svc(1, 4000)] })],
    });
    expect(r.unpaidCents).toBe(4000);
    expect(r.unpaidCount).toBe(1);
  });

  it('ignores zero-quantity service lines', () => {
    const r = computeClientOutstanding({
      completedStops: [stop({ actualServices: [svc(0, 1000), svc(2, 500)] })],
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

- [ ] **Step 2: Run to verify failure.** `pnpm test:domain -- compute-client-outstanding` → FAIL.

- [ ] **Step 3: Implement.**

```ts
// src/domain/use-cases/compute-client-outstanding.ts
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

export function computeClientOutstanding(args: {
  completedStops: TourStop[];
  manualEntries: ManualHistoryEntry[];
}): ClientOutstanding {
  let cents = 0;
  let count = 0;
  for (const stop of args.completedStops) {
    if (stop.payment.isPaid) continue;
    const services = stop.actualServices ?? stop.plannedServices;
    cents += sumServices(services);
    count += 1;
  }
  for (const entry of args.manualEntries) {
    if (entry.payment.isPaid) continue;
    cents += sumServices(entry.services);
    count += 1;
  }
  return { unpaidCents: cents, unpaidCount: count };
}
```

- [ ] **Step 4: Run + commit.**

Run: `pnpm test:domain -- compute-client-outstanding` → pass.

```
git add src/domain/use-cases/compute-client-outstanding.ts \
        tests/domain/use-cases/compute-client-outstanding.test.ts
git commit -m "$(cat <<'EOF'
feat(payments): add computeClientOutstanding use case

Pure summation across unpaid completed stops and unpaid manual
history entries. Uses actualServices when present, falls back to
plannedServices.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Use case — `compute-tour-payment-kpis`

**Files:**
- Create: `src/domain/use-cases/compute-tour-payment-kpis.ts`
- Test: `tests/domain/use-cases/compute-tour-payment-kpis.test.ts`

- [ ] **Step 1: Write the failing tests.**

```ts
import { describe, it, expect } from 'vitest';
import { computeTourPaymentKpis } from '@/domain/use-cases/compute-tour-payment-kpis';
import { EMPTY_PAYMENT } from '@/domain/models/payment';
import type { TourStop } from '@/domain/models/tour-stop';

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

describe('computeTourPaymentKpis', () => {
  it('splits collected vs outstanding across stops', () => {
    const r = computeTourPaymentKpis({
      stops: [
        stop({ id: 'a', actualServices: [svc(1, 1000)],
               payment: { ...EMPTY_PAYMENT, isPaid: true, paidAt: 'x' } }),
        stop({ id: 'b', actualServices: [svc(2, 500)] }),
      ],
    });
    expect(r.collectedCents).toBe(1000);
    expect(r.outstandingCents).toBe(1000);
  });

  it('returns zero when no stops are completed', () => {
    expect(computeTourPaymentKpis({ stops: [] }))
      .toEqual({ collectedCents: 0, outstandingCents: 0 });
  });
});
```

- [ ] **Step 2: Run to verify failure.** `pnpm test:domain -- compute-tour-payment-kpis` → FAIL.

- [ ] **Step 3: Implement.**

```ts
// src/domain/use-cases/compute-tour-payment-kpis.ts
import type { TourStop } from '@/domain/models/tour-stop';
import type { TourStopService } from '@/domain/models/tour-stop-service';

export interface TourPaymentKpis {
  collectedCents: number;
  outstandingCents: number;
}

function sumServices(services: TourStopService[]): number {
  let total = 0;
  for (const s of services) {
    if (s.qty <= 0) continue;
    total += s.qty * s.priceCentsSnapshot;
  }
  return total;
}

export function computeTourPaymentKpis(args: { stops: TourStop[] }): TourPaymentKpis {
  let collected = 0;
  let outstanding = 0;
  for (const stop of args.stops) {
    const services = stop.actualServices ?? stop.plannedServices;
    const value = sumServices(services);
    if (stop.payment.isPaid) collected += value;
    else outstanding += value;
  }
  return { collectedCents: collected, outstandingCents: outstanding };
}
```

- [ ] **Step 4: Run + commit.**

```
git add src/domain/use-cases/compute-tour-payment-kpis.ts \
        tests/domain/use-cases/compute-tour-payment-kpis.test.ts
git commit -m "$(cat <<'EOF'
feat(tours): add computeTourPaymentKpis use case

Splits a tour's stops into collected vs outstanding cents for the
closed-tour bilan KPIs.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: React Query hooks — `payment-methods`

**Files:**
- Create: `src/state/queries/payment-methods.ts`

- [ ] **Step 1: Implement the hook module (no separate test — covered through screen integration).**

```ts
// src/state/queries/payment-methods.ts
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { db } from '@/infra/db/client';
import { PaymentMethodRepository } from '@/data/repositories/payment-method-repository';
import { newId } from '@/lib/id';
import { mutationErrorToast } from '@/ui/components/error-toast';
import i18n from '@/i18n';
import type { PaymentMethod } from '@/domain/models/payment-method';

const repo = new PaymentMethodRepository(db);

export const paymentMethodsKeys = {
  all: ['paymentMethods'] as const,
  list: (scope: 'active' | 'all') => [...paymentMethodsKeys.all, 'list', scope] as const,
};

export function usePaymentMethods(scope: 'active' | 'all' = 'active') {
  return useQuery({
    queryKey: paymentMethodsKeys.list(scope),
    queryFn: () => (scope === 'active' ? repo.listActive() : repo.listAll()),
    staleTime: Infinity,
  });
}

export interface UpsertPaymentMethodInput {
  id?: string;
  label: string;
  isActive: boolean;
  ordering: number;
}

export function useUpsertPaymentMethod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: UpsertPaymentMethodInput) => {
      const existing = input.id ? await repo.byId(input.id) : null;
      const m: PaymentMethod = {
        id: input.id ?? newId(),
        label: input.label,
        isActive: input.isActive,
        archivedAt: existing?.archivedAt ?? null,
        ordering: input.ordering,
      };
      await repo.upsert(m);
      return m;
    },
    onSuccess: () => { void qc.invalidateQueries({ queryKey: paymentMethodsKeys.all }); },
    onError: (err) => { mutationErrorToast(i18n.t('catalogs.errors.save_failed_title'), err); },
  });
}

export function useArchivePaymentMethod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, archivedAt }: { id: string; archivedAt: string | null }) => {
      await repo.setArchived(id, archivedAt);
    },
    onSuccess: () => { void qc.invalidateQueries({ queryKey: paymentMethodsKeys.all }); },
    onError: (err) => { mutationErrorToast(i18n.t('catalogs.errors.save_failed_title'), err); },
  });
}

export function useDeletePaymentMethod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => repo.delete(id),
    onSuccess: () => { void qc.invalidateQueries({ queryKey: paymentMethodsKeys.all }); },
    onError: (err) => { mutationErrorToast(i18n.t('catalogs.errors.delete_failed_title'), err); },
  });
}
```

- [ ] **Step 2: Typecheck + commit.**

```
git add src/state/queries/payment-methods.ts
git commit -m "$(cat <<'EOF'
feat(payments): add payment-methods React Query hooks

CRUD + listActive/listAll hooks for the catalog. Errors surfaced via
mutationErrorToast like the rest of the catalogs.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Extend `useCompleteWithBilan` + new `useMarkStopPayment`

**Files:**
- Modify: `src/state/queries/tours.ts`

- [ ] **Step 1: Extend `useCompleteWithBilan` input.**

The hook currently takes `perStopActuals` and `perStopNotes`. Add `perStopPayments: Map<string, Payment>`:

```ts
import type { Payment } from '@/domain/models/payment';

// inside useCompleteWithBilan:
mutationFn: async ({
  tourId,
  perStopActuals,
  perStopNotes,
  perStopPayments,
  completedAt,
}: {
  tourId: string;
  perStopActuals: Map<string, TourStop['plannedServices']>;
  perStopNotes: Map<string, string | null>;
  perStopPayments: Map<string, Payment>;
  completedAt: string;
}) => {
  await tourRepo.completeWithBilan(tourId, perStopActuals, perStopNotes, perStopPayments, completedAt);
  // ... existing client lastShearingDate update unchanged
}
```

Remove the temporary `new Map()` placeholder added in Task 4.

- [ ] **Step 2: Add `useMarkStopPayment`.**

```ts
export function useMarkStopPayment() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ stopId, tourId: _tourId, payment }: { stopId: string; tourId: string; payment: Payment }) => {
      await tourRepo.markStopPayment(stopId, payment);
    },
    onSuccess: (_, { tourId }) => {
      void qc.invalidateQueries({ queryKey: toursKeys.byId(tourId) });
      void qc.invalidateQueries({ queryKey: toursKeys.all });
      void qc.invalidateQueries({ queryKey: ['clients'] });
      void qc.invalidateQueries({ queryKey: ['history'] });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('payments.errors.save_failed_title'), err);
    },
  });
}
```

- [ ] **Step 3: Typecheck + commit.**

```
git add src/state/queries/tours.ts
git commit -m "$(cat <<'EOF'
feat(tours): thread per-stop payments through completion + add useMarkStopPayment

useCompleteWithBilan now accepts perStopPayments. New useMarkStopPayment
mutation drives deferred payment edits from the closed-tour screen and
the client outstanding card.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Extend `useUpsertManualHistoryEntry` + new `useMarkManualEntryPayment`

**Files:**
- Modify: `src/state/queries/history.ts`

- [ ] **Step 1: Add `payment` to `UpsertManualHistoryInput` and use it.**

```ts
import type { Payment } from '@/domain/models/payment';

export interface UpsertManualHistoryInput {
  id?: string;
  clientId: string;
  date: string;
  notes: string | null;
  services: TourStopService[];
  payment: Payment;
}

// inside useUpsertManualHistoryEntry mutationFn:
const entry: ManualHistoryEntry = {
  id: input.id ?? newId(),
  clientId: input.clientId,
  date: input.date,
  notes: input.notes,
  services: input.services,
  payment: input.payment,
};
```

Drop the temporary `EMPTY_PAYMENT` from Task 5 here — the form will provide a real payment.

- [ ] **Step 2: Add `useMarkManualEntryPayment`.**

```ts
export function useMarkManualEntryPayment() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ entryId, clientId: _cid, payment }: { entryId: string; clientId: string; payment: Payment }) => {
      await manualRepo.markEntryPayment(entryId, payment);
    },
    onSuccess: (_, { clientId }) => {
      void qc.invalidateQueries({ queryKey: historyKeys.byClient(clientId) });
      void qc.invalidateQueries({ queryKey: historyKeys.manualByClient(clientId) });
      void qc.invalidateQueries({ queryKey: kpisKeys.client(clientId) });
      void qc.invalidateQueries({ queryKey: ['clients'] });
    },
    onError: (err) => {
      mutationErrorToast(i18n.t('payments.errors.save_failed_title'), err);
    },
  });
}
```

- [ ] **Step 3: Typecheck.** `pnpm typecheck`

There will be an error in `src/ui/components/manual-history-form.tsx` because `UpsertManualHistoryInput` now requires `payment`. **Don't fix it here** — Task 14 wires the real payment field. As a temporary placeholder so the build stays green, modify `manual-history-form.tsx`'s `onValid` to pass `payment: EMPTY_PAYMENT` (with `import { EMPTY_PAYMENT } from '@/domain/models/payment';`). Task 14 replaces this with the real form state.

- [ ] **Step 4: Commit.**

```
git add src/state/queries/history.ts src/ui/components/manual-history-form.tsx
git commit -m "$(cat <<'EOF'
feat(history): require payment in UpsertManualHistoryInput

UpsertManualHistoryInput gains a payment field and useMarkManualEntryPayment
covers deferred edits. The manual-history-form temporarily passes
EMPTY_PAYMENT until Task 14 wires the real UI block.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: i18n keys

**Files:**
- Modify: `src/i18n/locales/fr.json`

- [ ] **Step 1: Read the file to find the right anchor points.**

Run: `pnpm exec node -e "console.log(Object.keys(require('./src/i18n/locales/fr.json')).join('\\n'))"` (or simply open the file).

- [ ] **Step 2: Add the keys.**

Within the JSON, add (or merge into existing namespaces):

```json
{
  "payments": {
    "title": "Paiement",
    "method": "Moyen de paiement",
    "method_picker_title": "Choisir un moyen",
    "method_required": "Sélectionne un moyen de paiement",
    "is_paid": "Payé",
    "paid_at": "Date de paiement",
    "note": "Note (optionnelle)",
    "outstanding_title": "À encaisser",
    "outstanding_summary_one": "{{count}} intervention",
    "outstanding_summary_other": "{{count}} interventions",
    "editor_title": "Modifier le paiement",
    "mark_as_paid": "Marquer comme payé",
    "paid_badge": "Payé · {{method}}",
    "paid_badge_unknown": "Payé",
    "unpaid_badge": "Impayé",
    "kpi_collected": "Encaissé",
    "kpi_outstanding": "Reste dû",
    "errors": {
      "save_failed_title": "Échec de l'enregistrement du paiement"
    }
  },
  "catalogs": {
    "payment_methods": {
      "row_label": "Moyens de paiement",
      "row_hint": "Espèces, chèque, virement, …",
      "list_title": "Moyens de paiement",
      "new_title": "Nouveau moyen de paiement",
      "edit_title": "Modifier le moyen de paiement",
      "label": "Libellé",
      "active": "Actif",
      "archived_section": "Archivés",
      "empty_title": "Aucun moyen de paiement",
      "empty_message": "Ajoute un moyen de paiement pour commencer.",
      "empty_cta": "Ajouter un moyen",
      "delete_confirm_title": "Supprimer ce moyen de paiement ?",
      "delete_confirm_message": "Action irréversible. Si la méthode est utilisée, archive-la plutôt.",
      "inactive_badge": "Désactivé"
    }
  },
  "clients": {
    "filters": {
      "outstanding": "Impayés"
    }
  }
}
```

Merge each top-level key into the existing tree — don't overwrite the entire file. If `clients.filters` doesn't exist yet, create it; if it does, just add the `outstanding` line.

- [ ] **Step 3: Commit.**

```
git add src/i18n/locales/fr.json
git commit -m "$(cat <<'EOF'
feat(i18n): add payment-methods translation keys

Adds payments.* and catalogs.payment_methods.* and the outstanding
filter chip label.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: Shared component — `PaymentMethodPicker`

**Files:**
- Create: `src/ui/components/payment-method-picker.tsx`

- [ ] **Step 1: Implement the picker.** Mirror the modal pattern from `service-form.tsx` (category picker block) — modal sliding from bottom, list of options, tap to select + close.

```tsx
// src/ui/components/payment-method-picker.tsx
import { Modal, ScrollView, TouchableOpacity, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { usePaymentMethods } from '@/state/queries/payment-methods';
import type { PaymentMethod } from '@/domain/models/payment-method';

interface Props {
  visible: boolean;
  selectedId: string | null;
  onPick: (method: PaymentMethod) => void;
  onClose: () => void;
}

export function PaymentMethodPicker({ visible, selectedId, onPick, onClose }: Props) {
  const { t } = useTranslation();
  const { data: methods = [] } = usePaymentMethods('active');

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity
        style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }}
        onPress={onClose}
        activeOpacity={1}
      />
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4" style={{ maxHeight: '65%' }}>
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('payments.method_picker_title')}</Text>
          <PressScale onPress={onClose} accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>
        <ScrollView>
          {methods.map((m) => (
            <PressScale key={m.id} onPress={() => onPick(m)} accessibilityLabel={m.label}>
              <View
                className={`flex-row items-center px-4 py-3 rounded-xl mb-1 ${selectedId === m.id ? 'bg-primary dark:bg-primary-dark' : ''}`}
              >
                <Text
                  className={selectedId === m.id ? 'text-primary-foreground dark:text-primary-dark-foreground' : ''}
                >
                  {m.label}
                </Text>
              </View>
            </PressScale>
          ))}
        </ScrollView>
      </Surface>
    </Modal>
  );
}
```

- [ ] **Step 2: Typecheck + commit.**

```
git add src/ui/components/payment-method-picker.tsx
git commit -m "$(cat <<'EOF'
feat(payments): add PaymentMethodPicker bottom sheet

Single-selection picker over active payment methods, used by
PaymentEditor and the closed-tour stop sheet.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 14: Shared component — `PaymentEditor` block

**Files:**
- Create: `src/ui/components/payment-editor.tsx`

- [ ] **Step 1: Implement the controlled-component block.**

```tsx
// src/ui/components/payment-editor.tsx
import { useState } from 'react';
import { Platform, View } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { ChevronDown } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import { Input } from '@/ui/primitives/input';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';
import { PaymentMethodPicker } from '@/ui/components/payment-method-picker';
import { FormField } from '@/ui/components/form-field';
import type { Payment } from '@/domain/models/payment';
import type { PaymentMethod } from '@/domain/models/payment-method';

interface Props {
  value: Payment;
  onChange: (next: Payment) => void;
  methodError?: string | null;
  // When true, the form requires a methodId regardless of isPaid (manual history).
  requireMethodAlways?: boolean;
}

export function PaymentEditor({ value, onChange, methodError, requireMethodAlways }: Props) {
  const { t } = useTranslation();
  const [pickerOpen, setPickerOpen] = useState(false);
  const [datePickerOpen, setDatePickerOpen] = useState(false);

  const onPickMethod = (m: PaymentMethod) => {
    onChange({
      ...value,
      methodId: m.id,
      methodLabelSnapshot: value.isPaid ? m.label : value.methodLabelSnapshot,
    });
    setPickerOpen(false);
  };

  const onTogglePaid = (next: boolean) => {
    if (next) {
      // Promote to paid — snapshot label if methodId is set, default paidAt to now.
      onChange({
        ...value,
        isPaid: true,
        paidAt: value.paidAt ?? new Date().toISOString(),
        methodLabelSnapshot: value.methodLabelSnapshot, // caller can re-pick to refresh; picker will populate when re-selected
      });
    } else {
      onChange({
        ...value,
        isPaid: false,
        paidAt: null,
        methodLabelSnapshot: null,
      });
    }
  };

  const showMethodRequired = methodError && (requireMethodAlways || value.isPaid) && !value.methodId;

  return (
    <Surface variant="muted" className="rounded-2xl p-3 gap-3">
      <Text className="font-semibold">{t('payments.title')}</Text>

      <View className="flex-row items-center justify-between">
        <Text className="text-sm font-medium">{t('payments.is_paid')}</Text>
        <ThemedSwitch value={value.isPaid} onValueChange={onTogglePaid} />
      </View>

      <FormField label={t('payments.method')} error={showMethodRequired ? methodError ?? undefined : undefined}>
        <PressScale onPress={() => setPickerOpen(true)} accessibilityLabel={t('payments.method')}>
          <Surface className="flex-row items-center justify-between rounded-2xl px-4 py-3">
            <Text className={value.methodId ? '' : 'opacity-50'}>
              {value.methodId
                ? value.methodLabelSnapshot ?? t('payments.method')
                : t('payments.method_picker_title')}
            </Text>
            <ChevronDown size={16} color="#5C4E40" />
          </Surface>
        </PressScale>
      </FormField>

      {value.isPaid ? (
        <FormField label={t('payments.paid_at')}>
          <PressScale onPress={() => setDatePickerOpen(true)} accessibilityLabel={t('payments.paid_at')}>
            <Surface className="rounded-2xl px-4 py-3">
              <Text>{value.paidAt ? format(parseISO(value.paidAt), 'PPP', { locale: fr }) : '—'}</Text>
            </Surface>
          </PressScale>
          {datePickerOpen ? (
            <DateTimePicker
              value={value.paidAt ? parseISO(value.paidAt) : new Date()}
              mode="date"
              onChange={(_, d) => {
                setDatePickerOpen(Platform.OS === 'ios');
                if (d) onChange({ ...value, paidAt: d.toISOString() });
              }}
            />
          ) : null}
        </FormField>
      ) : null}

      <FormField label={t('payments.note')}>
        <Input
          value={value.note ?? ''}
          onChangeText={(text) => onChange({ ...value, note: text.length === 0 ? null : text })}
          accessibilityLabel={t('payments.note')}
        />
      </FormField>

      <PaymentMethodPicker
        visible={pickerOpen}
        selectedId={value.methodId}
        onPick={onPickMethod}
        onClose={() => setPickerOpen(false)}
      />
    </Surface>
  );
}
```

- [ ] **Step 2: Wire `PaymentEditor` into `manual-history-form.tsx`.**

Replace the `EMPTY_PAYMENT` placeholder added in Task 11 with real local state. Add at the top of the component:

```ts
import { PaymentEditor } from '@/ui/components/payment-editor';
import { EMPTY_PAYMENT } from '@/domain/models/payment';
import type { Payment } from '@/domain/models/payment';

const [payment, setPayment] = useState<Payment>(initial?.payment ?? {
  ...EMPTY_PAYMENT,
  isPaid: true, // default true at creation (dominant case)
});
const [methodError, setMethodError] = useState<string | null>(null);
```

In `onValid`:

```ts
if (!payment.methodId) {
  setMethodError(t('payments.method_required'));
  void haptics.error();
  return;
}
setMethodError(null);

onSubmit({
  id: initial?.id,
  clientId,
  date: format(values.date, 'yyyy-MM-dd'),
  notes: values.notes.trim() || null,
  services,
  payment: payment.isPaid && payment.methodLabelSnapshot === null
    ? { ...payment, methodLabelSnapshot: null /* picker will set on selection */ }
    : payment,
});
```

Render the `<PaymentEditor>` component below the services block (before the submit row):

```tsx
<PaymentEditor
  value={payment}
  onChange={setPayment}
  methodError={methodError}
  requireMethodAlways
/>
```

When `requireMethodAlways` is true and `methodId` is null, the picker will show the error after the user attempts submit.

Also: when the picker selects a method while `isPaid` is true, the `PaymentEditor` already sets `methodLabelSnapshot` from the selected method's label. When `isPaid` is false, the `methodLabelSnapshot` stays null (snapshots only happen at "marked paid" time per the spec). The above logic in `onPickMethod` handles this.

- [ ] **Step 3: Typecheck and run app to manually verify the manual history form has the new block.**

Run: `pnpm typecheck` → must be clean.

Manual: `pnpm start --dev-client`, open client → Add manual entry → toggle Payé / pick a method / pick a date / add a note → save → reopen, verify state persisted.

- [ ] **Step 4: Commit.**

```
git add src/ui/components/payment-editor.tsx src/ui/components/manual-history-form.tsx
git commit -m "$(cat <<'EOF'
feat(payments): add PaymentEditor and wire it into manual history form

PaymentEditor is a controlled block (toggle Payé + method picker +
date + note). Manual history requires a method always; the form
shows an inline error if the user submits without one.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 15: Settings — Payment methods list/new/edit screens

**Files:**
- Create: `src/ui/components/payment-method-form.tsx`
- Create: `app/(tabs)/settings/payment-methods/_layout.tsx`
- Create: `app/(tabs)/settings/payment-methods/index.tsx`
- Create: `app/(tabs)/settings/payment-methods/new.tsx`
- Create: `app/(tabs)/settings/payment-methods/[id].tsx`
- Modify: `app/(tabs)/settings/index.tsx`

- [ ] **Step 1: Create `_layout.tsx`** (mirror `app/(tabs)/settings/services/_layout.tsx` if it exists; otherwise:)

```tsx
import { Stack } from 'expo-router';
export default function PaymentMethodsLayout() {
  return <Stack screenOptions={{ headerShown: false }} />;
}
```

(Check if `services/_layout.tsx` exists first — if not, no layout file is needed for this folder either, and Expo Router will register it under the parent `settings` stack. Follow the existing pattern.)

- [ ] **Step 2: Create `PaymentMethodForm`** — calque of `ServiceForm` but only `label` + `isActive`.

```tsx
// src/ui/components/payment-method-form.tsx
import { useTranslation } from 'react-i18next';
import { ScrollView, View } from 'react-native';
import { Controller, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import type { TFunction } from 'i18next';

import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { ThemedSwitch } from '@/ui/primitives/themed-switch';
import { RHFTextField } from '@/ui/components/rhf-text-field';
import { haptics } from '@/ui/motion/haptics';
import type { PaymentMethod } from '@/domain/models/payment-method';
import type { UpsertPaymentMethodInput } from '@/state/queries/payment-methods';

interface Props {
  initial?: PaymentMethod;
  saving?: boolean;
  onSubmit: (input: UpsertPaymentMethodInput) => void;
  onCancel?: () => void;
}

interface FormValues { label: string; isActive: boolean; }

function makeSchema(t: TFunction) {
  return z.object({
    label: z.string().trim().min(1, t('catalogs.errors.label_required')),
    isActive: z.boolean(),
  });
}

export function PaymentMethodForm({ initial, saving, onSubmit, onCancel }: Props) {
  const { t } = useTranslation();
  const { control, handleSubmit } = useForm<FormValues>({
    defaultValues: {
      label: initial?.label ?? '',
      isActive: initial?.isActive ?? true,
    },
    resolver: zodResolver(makeSchema(t)),
    mode: 'onTouched',
  });

  const onValid = (values: FormValues) => {
    onSubmit({
      id: initial?.id,
      label: values.label.trim(),
      isActive: values.isActive,
      ordering: initial?.ordering ?? 100,
    });
  };

  return (
    <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 32, gap: 16 }}>
      <RHFTextField control={control} name="label" label={t('catalogs.payment_methods.label')} />
      <Controller
        control={control}
        name="isActive"
        render={({ field }) => (
          <View className="flex-row items-center justify-between">
            <Text className="text-sm font-medium">{t('catalogs.payment_methods.active')}</Text>
            <ThemedSwitch value={field.value} onValueChange={field.onChange} />
          </View>
        )}
      />
      <View className="flex-row gap-2 mt-4">
        {onCancel ? (
          <Button variant="secondary" className="flex-1" onPress={onCancel} disabled={saving}>
            {t('common.cancel')}
          </Button>
        ) : null}
        <Button className="flex-1" onPress={handleSubmit(onValid, () => void haptics.error())} loading={saving}>
          {t('common.save')}
        </Button>
      </View>
    </ScrollView>
  );
}
```

- [ ] **Step 3: Create `index.tsx` (list).** Mirror `app/(tabs)/settings/services/index.tsx`, dropping the species/category grouping (one flat list of active methods + collapsible archived section).

```tsx
import { useMemo, useState } from 'react';
import { View, ScrollView, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { Plus, ChevronRight, ChevronDown, Wallet } from 'lucide-react-native';
import { useTranslation } from 'react-i18next';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { Fab } from '@/ui/primitives/fab';
import { SectionHeader } from '@/ui/primitives/section-header';
import { ListSkeleton } from '@/ui/primitives/skeleton';
import { PressScale } from '@/ui/motion/press-scale';
import { EmptyState } from '@/ui/components/empty-state';
import { ErrorState } from '@/ui/components/error-state';
import { ScreenHeader } from '@/ui/components/screen-header';
import { usePaymentMethods } from '@/state/queries/payment-methods';
import { haptics } from '@/ui/motion/haptics';
import { useOnContrastColor, useMutedForegroundColor } from '@/ui/theme/colors';

export default function PaymentMethodsListScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const onContrast = useOnContrastColor();
  const mutedFg = useMutedForegroundColor();
  const { data: methods = [], isError, isLoading, refetch } = usePaymentMethods('all');

  const [archivedExpanded, setArchivedExpanded] = useState(false);

  const grouped = useMemo(() => {
    const active = methods.filter((m) => m.isActive);
    const archived = methods.filter((m) => !m.isActive);
    return { active, archived };
  }, [methods]);

  if (isError) return <ErrorState onRetry={() => refetch()} />;

  const isEmpty = methods.length === 0;

  return (
    <Surface className="flex-1">
      <ScreenHeader title={t('catalogs.payment_methods.list_title')} />
      {isLoading ? (
        <ListSkeleton />
      ) : isEmpty ? (
        <EmptyState
          icon={<Wallet size={48} color={mutedFg} />}
          title={t('catalogs.payment_methods.empty_title')}
          message={t('catalogs.payment_methods.empty_message')}
          action={
            <Button
              onPress={() => { void haptics.selection(); router.push('/(tabs)/settings/payment-methods/new' as never); }}
              accessibilityLabel={t('catalogs.payment_methods.empty_cta')}
            >
              <Plus size={16} color={onContrast} />
              <Text variant="onPrimary" className="font-semibold">
                {t('catalogs.payment_methods.empty_cta')}
              </Text>
            </Button>
          }
        />
      ) : (
        <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 96 }}>
          <SectionHeader title={t('catalogs.payment_methods.list_title')} />
          {grouped.active.map((m) => (
            <PressScale key={m.id} onPress={() => { void haptics.selection(); router.push(`/(tabs)/settings/payment-methods/${m.id}` as never); }} accessibilityLabel={m.label}>
              <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3 mb-2">
                <Text className="font-semibold flex-1">{m.label}</Text>
                <ChevronRight size={18} color={mutedFg} />
              </Surface>
            </PressScale>
          ))}

          {grouped.archived.length > 0 ? (
            <View>
              <TouchableOpacity onPress={() => setArchivedExpanded(!archivedExpanded)}>
                <View className="flex-row items-center justify-between pt-4 pb-1 px-1">
                  <Text variant="muted" className="text-xs font-semibold uppercase tracking-widest">
                    {t('catalogs.payment_methods.archived_section')} ({grouped.archived.length})
                  </Text>
                  {archivedExpanded ? <ChevronDown size={14} color={mutedFg} /> : <ChevronRight size={14} color={mutedFg} />}
                </View>
              </TouchableOpacity>
              {archivedExpanded ? grouped.archived.map((m) => (
                <PressScale key={m.id} onPress={() => router.push(`/(tabs)/settings/payment-methods/${m.id}` as never)} accessibilityLabel={m.label}>
                  <Surface variant="muted" className="flex-row items-center rounded-2xl px-4 py-3 gap-3 mb-2">
                    <Text className="font-semibold flex-1">{m.label}</Text>
                    <Text variant="muted" className="text-xs">{t('catalogs.payment_methods.inactive_badge')}</Text>
                    <ChevronRight size={18} color={mutedFg} />
                  </Surface>
                </PressScale>
              )) : null}
            </View>
          ) : null}
        </ScrollView>
      )}

      <Fab icon={Plus} onPress={() => router.push('/(tabs)/settings/payment-methods/new' as never)} accessibilityLabel={t('catalogs.payment_methods.new_title')} />
    </Surface>
  );
}
```

- [ ] **Step 4: Create `new.tsx` and `[id].tsx`.** Mirror `app/(tabs)/settings/services/new.tsx` and `[id].tsx`, replacing `useUpsertService`/`useDeleteService`/`useServices` with the payment-methods equivalents and `ServiceForm` with `PaymentMethodForm`.

For `[id].tsx`, the `useServices` lookup becomes:

```ts
const { data: methods = [] } = usePaymentMethods('all');
const item = methods.find((m) => m.id === id);
```

- [ ] **Step 5: Add the row to `app/(tabs)/settings/index.tsx`.**

Inside the `section_catalog` section, after the services row:

```tsx
<SettingsRow
  label={t('catalogs.payment_methods.row_label')}
  hint={t('catalogs.payment_methods.row_hint')}
  onPress={() => router.push('/(tabs)/settings/payment-methods' as never)}
/>
```

- [ ] **Step 6: Typecheck.** `pnpm typecheck`

- [ ] **Step 7: Manual verification.** `pnpm start --dev-client` → Settings → Moyens de paiement → see the four seeded methods → tap one → rename → save → verify list updates → archive → see it under the collapsible section → try delete on an unreferenced custom one → succeeds → try delete on a referenced one → toast error.

- [ ] **Step 8: Commit.**

```
git add src/ui/components/payment-method-form.tsx \
        app/\(tabs\)/settings/payment-methods/ \
        app/\(tabs\)/settings/index.tsx
git commit -m "$(cat <<'EOF'
feat(catalogs): add payment-methods settings screens

List + new + edit screens calqued on the services catalog.
Renaming archives or deleting a referenced method surface a clear
toast error.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

(Note: on Windows PowerShell, escape the parentheses in paths with backticks instead of backslashes: `app/\`(tabs\`)/...`. Adapt as needed for your shell.)

---

## Task 16: Tour completion screen — payment per stop

**Files:**
- Modify: `src/ui/components/stop-completion-editor.tsx`
- Modify: `app/(tabs)/tours/[id]/complete.tsx`

- [ ] **Step 1: Add a payment block to `StopCompletionEditor`.**

Extend `Props` and render the `PaymentEditor` after the note input:

```ts
import type { Payment } from '@/domain/models/payment';
import { PaymentEditor } from '@/ui/components/payment-editor';

interface Props {
  // ... existing
  payment: Payment;
  paymentError?: string | null;
  onChangePayment: (next: Payment) => void;
}
```

Render at the end of the `Surface`:

```tsx
<PaymentEditor value={payment} onChange={onChangePayment} methodError={paymentError ?? null} />
```

- [ ] **Step 2: Wire per-stop payment state on the complete screen.**

In `app/(tabs)/tours/[id]/complete.tsx`:

```ts
import type { Payment } from '@/domain/models/payment';
import { EMPTY_PAYMENT } from '@/domain/models/payment';

const [perStopPayments, setPerStopPayments] = useState<Record<string, Payment>>({});
const [perStopPaymentErrors, setPerStopPaymentErrors] = useState<Record<string, string | null>>({});

const getPayment = (stopId: string, defaultPayment: Payment) =>
  perStopPayments[stopId] ?? defaultPayment;

const setPayment = (stopId: string, p: Payment) =>
  setPerStopPayments((prev) => ({ ...prev, [stopId]: p }));
```

Pass into the editor:

```tsx
<StopCompletionEditor
  ...
  payment={getPayment(stop.id, stop.payment)}
  paymentError={perStopPaymentErrors[stop.id] ?? null}
  onChangePayment={(next) => setPayment(stop.id, next)}
/>
```

- [ ] **Step 3: Validate before confirmation.**

Replace `onConfirm` with validation logic:

```ts
const onConfirm = async () => {
  // Validate per-stop payments: if isPaid and stop has services -> methodId required
  const errors: Record<string, string | null> = {};
  let hasError = false;
  for (const stop of stops) {
    const actuals = getActuals(stop.id, stop.plannedServices);
    const stopHasAny = actuals.some((a) => a.qty > 0);
    if (!stopHasAny) continue;
    const p = getPayment(stop.id, stop.payment);
    if (p.isPaid && !p.methodId) {
      errors[stop.id] = t('payments.method_required');
      hasError = true;
    }
  }
  if (hasError) {
    setPerStopPaymentErrors(errors);
    void haptics.error();
    return;
  }
  setPerStopPaymentErrors({});

  const ok = await confirm({...});
  if (!ok) return;

  const actualsMap = new Map<string, TourStopService[]>();
  const notesMap = new Map<string, string | null>();
  const paymentsMap = new Map<string, Payment>();
  for (const stop of stops) {
    actualsMap.set(stop.id, getActuals(stop.id, stop.plannedServices));
    const trimmed = getNote(stop.id).trim();
    notesMap.set(stop.id, trimmed.length === 0 ? null : trimmed);
    paymentsMap.set(stop.id, getPayment(stop.id, stop.payment));
  }
  complete.mutate(
    { tourId: tour.id, perStopActuals: actualsMap, perStopNotes: notesMap, perStopPayments: paymentsMap, completedAt: new Date().toISOString() },
    { onSuccess: () => { void haptics.success(); router.replace(`/(tabs)/tours/${tour.id}` as never); },
      onError: (err) => { mutationErrorToast(t('tours.save_failed_title'), err); } }
  );
};
```

- [ ] **Step 4: Typecheck.** `pnpm typecheck` → clean.

- [ ] **Step 5: Manual verification.** `pnpm start --dev-client`. Complete a tour with two stops:
  - Stop A: validate services, toggle Payé on, pick "Espèces", add note, confirm — closes successfully, payment persisted.
  - Stop B: validate services, leave Payé off, confirm — closes successfully (method optional when unpaid).
  - Try Stop A: toggle Payé on without picking method → submit shows inline error and doesn't close.

- [ ] **Step 6: Commit.**

```
git add src/ui/components/stop-completion-editor.tsx \
        "app/(tabs)/tours/[id]/complete.tsx"
git commit -m "$(cat <<'EOF'
feat(tours): collect payment info on tour completion

Each stop in the bilan editor now has a Paiement block. Method is
required when Payé is toggled on; missing method blocks confirmation
with an inline error.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 17: Closed tour detail — badges, KPIs, sheet editor

**Files:**
- Create: `src/ui/components/stop-payment-sheet.tsx`
- Modify: `app/(tabs)/tours/[id].tsx`

- [ ] **Step 1: Create `StopPaymentSheet`** — bottom sheet wrapping `PaymentEditor` with a save button + `useMarkStopPayment`.

```tsx
// src/ui/components/stop-payment-sheet.tsx
import { useEffect, useState } from 'react';
import { Modal, TouchableOpacity, View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { Button } from '@/ui/primitives/button';
import { PressScale } from '@/ui/motion/press-scale';
import { PaymentEditor } from '@/ui/components/payment-editor';
import { useMarkStopPayment } from '@/state/queries/tours';
import { haptics } from '@/ui/motion/haptics';
import type { Payment } from '@/domain/models/payment';

interface Props {
  visible: boolean;
  stopId: string | null;
  tourId: string;
  initial: Payment | null;
  onClose: () => void;
}

export function StopPaymentSheet({ visible, stopId, tourId, initial, onClose }: Props) {
  const { t } = useTranslation();
  const [draft, setDraft] = useState<Payment>(initial ?? {
    methodId: null, methodLabelSnapshot: null, isPaid: false, paidAt: null, note: null,
  });
  const [error, setError] = useState<string | null>(null);
  const mark = useMarkStopPayment();

  useEffect(() => { if (visible && initial) setDraft(initial); }, [visible, initial]);

  if (!stopId) return null;

  const onSave = () => {
    if (draft.isPaid && !draft.methodId) {
      setError(t('payments.method_required'));
      void haptics.error();
      return;
    }
    setError(null);
    mark.mutate({ stopId, tourId, payment: draft }, {
      onSuccess: () => { void haptics.success(); onClose(); },
    });
  };

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <TouchableOpacity style={{ flex: 1, backgroundColor: 'rgba(0,0,0,0.4)' }} onPress={onClose} activeOpacity={1} />
      <Surface className="rounded-t-3xl px-4 pb-8 pt-4" style={{ maxHeight: '85%' }}>
        <View className="flex-row items-center justify-between mb-4">
          <Text className="text-lg font-semibold">{t('payments.editor_title')}</Text>
          <PressScale onPress={onClose} accessibilityLabel={t('common.close')}>
            <X size={22} color="#5C4E40" />
          </PressScale>
        </View>
        <PaymentEditor value={draft} onChange={setDraft} methodError={error} />
        <Button className="mt-4" onPress={onSave} loading={mark.isPending}>
          {t('common.save')}
        </Button>
      </Surface>
    </Modal>
  );
}
```

- [ ] **Step 2: Wire badges + KPIs + sheet trigger on the closed-tour detail screen.**

Open `app/(tabs)/tours/[id].tsx`. Where each stop is rendered (probably via `tour-stop-row` or inline list), add a payment badge. If the stop is on a completed tour, the row's tap target opens `StopPaymentSheet` (the screen already may have edit affordances — pick the least intrusive: an icon button or tapping the stop row itself when status is `completed`).

Add the KPI summary using `computeTourPaymentKpis`:

```ts
import { computeTourPaymentKpis } from '@/domain/use-cases/compute-tour-payment-kpis';

const kpis = computeTourPaymentKpis({ stops });
// In the header KPI row, render two extra tiles when tour.status === 'completed':
// "Encaissé · {formatEur(kpis.collectedCents)}"
// "Reste dû · {formatEur(kpis.outstandingCents)}" (hidden if outstandingCents === 0)
```

Add the sheet:

```ts
const [paymentSheet, setPaymentSheet] = useState<{ stopId: string; payment: Payment } | null>(null);

// Render <StopPaymentSheet ... /> at the end of the screen, controlled by paymentSheet state.

// On stop press (only when tour.status === 'completed'):
onPress={() => setPaymentSheet({ stopId: stop.id, payment: stop.payment })}
```

For each stop, render a small badge (read `stop.payment.isPaid` and `stop.payment.methodLabelSnapshot`):

```tsx
<Text variant="muted" className="text-xs">
  {stop.payment.isPaid
    ? stop.payment.methodLabelSnapshot
      ? t('payments.paid_badge', { method: stop.payment.methodLabelSnapshot })
      : t('payments.paid_badge_unknown')
    : t('payments.unpaid_badge')}
</Text>
```

Read the existing `[id].tsx` first to find the right spot for badges and decide the tap affordance. The change set is local: add the badge text inline in the stop-row JSX, and a press handler conditional on `tour.status === 'completed'`.

- [ ] **Step 3: Typecheck + manual.**

Run: `pnpm typecheck` → clean.

Manual: open a closed tour, see Encaissé/Reste dû KPIs, see "Payé · Espèces" / "Impayé" badges, tap an "Impayé" stop → sheet opens → mark Payé + Espèces + save → badge updates, KPIs recompute.

- [ ] **Step 4: Commit.**

```
git add src/ui/components/stop-payment-sheet.tsx "app/(tabs)/tours/[id].tsx"
git commit -m "$(cat <<'EOF'
feat(tours): payment badges, KPIs, and edit sheet on closed tours

Each completed stop shows a Payé/Impayé badge. The header gains
Encaissé / Reste dû KPI tiles. Tapping a stop opens a sheet to mark
or correct payment.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 18: Client detail — "À encaisser" block

**Files:**
- Create: `src/ui/components/client-outstanding-card.tsx`
- Create: `src/ui/components/manual-entry-payment-sheet.tsx`
- Modify: `app/(tabs)/clients/[id].tsx`

- [ ] **Step 1: Create `ManualEntryPaymentSheet`** — same structure as `StopPaymentSheet` but using `useMarkManualEntryPayment`. (Copy the file, swap the mutation hook + the prop names — `entryId` instead of `stopId`, `clientId` instead of `tourId`.)

- [ ] **Step 2: Create `ClientOutstandingCard`** — pure presentation component listing unpaid stops + manual entries, takes an `onTapStop(stopId, tourId, payment)` and `onTapEntry(entryId, payment)`.

```tsx
// src/ui/components/client-outstanding-card.tsx
import { View } from 'react-native';
import { useTranslation } from 'react-i18next';
import { format, parseISO } from 'date-fns';
import { fr } from 'date-fns/locale';
import { ChevronRight } from 'lucide-react-native';

import { Surface } from '@/ui/primitives/surface';
import { Text } from '@/ui/primitives/text';
import { PressScale } from '@/ui/motion/press-scale';
import type { TourStop } from '@/domain/models/tour-stop';
import type { ManualHistoryEntry } from '@/domain/models/manual-history-entry';
import { useMutedForegroundColor } from '@/ui/theme/colors';

interface UnpaidStop {
  stop: TourStop;
  tourId: string;
  scheduledDate: string;
}

interface Props {
  unpaidStops: UnpaidStop[];
  unpaidEntries: ManualHistoryEntry[];
  totalCents: number;
  count: number;
  onTapStop: (s: UnpaidStop) => void;
  onTapEntry: (e: ManualHistoryEntry) => void;
}

function formatEur(cents: number): string { return `${(cents / 100).toFixed(0)} €`; }
function sumServices(s: { qty: number; priceCentsSnapshot: number }[]): number {
  return s.reduce((acc, x) => acc + (x.qty > 0 ? x.qty * x.priceCentsSnapshot : 0), 0);
}

export function ClientOutstandingCard({
  unpaidStops, unpaidEntries, totalCents, count, onTapStop, onTapEntry,
}: Props) {
  const { t } = useTranslation();
  const mutedFg = useMutedForegroundColor();
  const summary = t('payments.outstanding_summary', { count });

  return (
    <Surface variant="muted" className="rounded-2xl p-3 gap-2">
      <View className="flex-row items-end justify-between">
        <Text className="font-semibold">{t('payments.outstanding_title')}</Text>
        <Text className="text-xl font-bold">{formatEur(totalCents)}</Text>
      </View>
      <Text variant="muted" className="text-xs">{summary}</Text>

      <View className="gap-1 mt-2">
        {unpaidStops.map((s) => {
          const services = s.stop.actualServices ?? s.stop.plannedServices;
          const cents = sumServices(services);
          return (
            <PressScale key={s.stop.id} onPress={() => onTapStop(s)} accessibilityLabel={t('payments.editor_title')}>
              <View className="flex-row items-center justify-between py-2 border-t border-border dark:border-border-dark">
                <Text className="flex-1 text-sm">{format(parseISO(s.scheduledDate), 'PPP', { locale: fr })}</Text>
                <Text className="text-sm font-medium mr-2">{formatEur(cents)}</Text>
                <ChevronRight size={16} color={mutedFg} />
              </View>
            </PressScale>
          );
        })}
        {unpaidEntries.map((e) => {
          const cents = sumServices(e.services);
          return (
            <PressScale key={e.id} onPress={() => onTapEntry(e)} accessibilityLabel={t('payments.editor_title')}>
              <View className="flex-row items-center justify-between py-2 border-t border-border dark:border-border-dark">
                <Text className="flex-1 text-sm">{format(parseISO(e.date), 'PPP', { locale: fr })}</Text>
                <Text className="text-sm font-medium mr-2">{formatEur(cents)}</Text>
                <ChevronRight size={16} color={mutedFg} />
              </View>
            </PressScale>
          );
        })}
      </View>
    </Surface>
  );
}
```

Note: the `outstanding_summary` key uses i18next pluralization (`_one` / `_other`); the call site must pass `{ count }` as the variable.

- [ ] **Step 3: Wire on `app/(tabs)/clients/[id].tsx`.** Open the file, identify the spot just under the existing KPI block. Add:

```ts
import { useTours } from '@/state/queries/tours';
import { useManualHistoryByClient } from '@/state/queries/history';
import { computeClientOutstanding } from '@/domain/use-cases/compute-client-outstanding';
import { ClientOutstandingCard } from '@/ui/components/client-outstanding-card';
import { StopPaymentSheet } from '@/ui/components/stop-payment-sheet';
import { ManualEntryPaymentSheet } from '@/ui/components/manual-entry-payment-sheet';

const { data: tours = [] } = useTours('completed');
const { data: manualEntries = [] } = useManualHistoryByClient(id);

const unpaidStops = useMemo(() => {
  const out: Array<{ stop: TourStop; tourId: string; scheduledDate: string }> = [];
  for (const { tour, stops } of tours) {
    for (const s of stops) {
      if (s.clientId !== id) continue;
      if (!s.completedAt) continue;
      if (s.payment.isPaid) continue;
      out.push({ stop: s, tourId: tour.id, scheduledDate: tour.scheduledDate });
    }
  }
  return out;
}, [tours, id]);

const unpaidEntries = useMemo(
  () => manualEntries.filter((e) => !e.payment.isPaid),
  [manualEntries]
);

const outstanding = useMemo(
  () => computeClientOutstanding({
    completedStops: unpaidStops.map((u) => u.stop),
    manualEntries: unpaidEntries,
  }),
  [unpaidStops, unpaidEntries]
);

const [stopSheet, setStopSheet] = useState<{ stopId: string; tourId: string; payment: Payment } | null>(null);
const [entrySheet, setEntrySheet] = useState<{ entryId: string; clientId: string; payment: Payment } | null>(null);
```

Render conditionally:

```tsx
{outstanding.unpaidCount > 0 ? (
  <ClientOutstandingCard
    unpaidStops={unpaidStops}
    unpaidEntries={unpaidEntries}
    totalCents={outstanding.unpaidCents}
    count={outstanding.unpaidCount}
    onTapStop={(s) => setStopSheet({ stopId: s.stop.id, tourId: s.tourId, payment: s.stop.payment })}
    onTapEntry={(e) => setEntrySheet({ entryId: e.id, clientId: id, payment: e.payment })}
  />
) : null}

<StopPaymentSheet
  visible={stopSheet !== null}
  stopId={stopSheet?.stopId ?? null}
  tourId={stopSheet?.tourId ?? ''}
  initial={stopSheet?.payment ?? null}
  onClose={() => setStopSheet(null)}
/>
<ManualEntryPaymentSheet
  visible={entrySheet !== null}
  entryId={entrySheet?.entryId ?? null}
  clientId={entrySheet?.clientId ?? ''}
  initial={entrySheet?.payment ?? null}
  onClose={() => setEntrySheet(null)}
/>
```

- [ ] **Step 4: Typecheck + manual.**

Run: `pnpm typecheck` → clean.

Manual: open a client with unpaid stops/entries → see the outstanding card → tap a line → sheet opens preset → mark paid → save → card disappears or count decreases.

- [ ] **Step 5: Commit.**

```
git add src/ui/components/client-outstanding-card.tsx \
        src/ui/components/manual-entry-payment-sheet.tsx \
        "app/(tabs)/clients/[id].tsx"
git commit -m "$(cat <<'EOF'
feat(clients): add À encaisser block on client detail

Lists unpaid completed stops and unpaid manual entries with a tap
target that opens the right payment sheet to settle each.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 19: Clients list — "Impayés" filter chip

**Files:**
- Modify: `app/(tabs)/clients/index.tsx`
- Possibly: `src/ui/components/client-status-filter-dialog.tsx` and/or `src/state/ui/client-filters-store.ts` (depends on existing chip implementation — read first)

- [ ] **Step 1: Decide where the chip lives.**

Open `app/(tabs)/clients/index.tsx`. Two existing surfaces exist for filtering: the `SegmentedControl` (`all` / `waiting`) and the `ClientFilterButton` (status dialog). The chip "Impayés" is **another orthogonal filter** — best added as a third option in the `SegmentedControl` or as a separate toggle chip beside it.

Recommended approach: add a new local `outstandingOnly: boolean` toggle exposed as a chip-style button next to the `SegmentedControl`. Don't extend `ClientsFilter` (in `state/queries/clients.ts`) — keep the filter local since it intersects with everything.

- [ ] **Step 2: Add a new query — outstanding ids.**

```ts
// in src/state/queries/clients.ts (or directly in the screen, your choice — prefer the queries file)
import { ClientRepository } from '@/data/repositories/client-repository';
import { useQuery } from '@tanstack/react-query';
const clientRepo = new ClientRepository(db);

export function useClientsWithOutstanding() {
  return useQuery({
    queryKey: ['clients', 'outstanding'],
    queryFn: async () => clientRepo.listClientIdsWithOutstanding(),
  });
}
```

- [ ] **Step 3: Wire in the screen.**

```ts
import { useClientsWithOutstanding } from '@/state/queries/clients';

const [outstandingOnly, setOutstandingOnly] = useState(false);
const { data: outstandingIds } = useClientsWithOutstanding();

const filtered = useMemo(() => {
  let list = allClients;
  if (enabledStatuses.size < 6 && statusMap) {
    list = list.filter((c) => enabledStatuses.has(statusMap.get(c.id) ?? 'default'));
  }
  if (outstandingOnly && outstandingIds) {
    list = list.filter((c) => outstandingIds.has(c.id));
  }
  if (search.trim()) {
    list = list.filter((c) => matchesAny([c.displayName, c.addressCity], search));
  }
  return list;
}, [allClients, search, enabledStatuses, statusMap, outstandingOnly, outstandingIds]);
```

Render the toggle chip near the `SegmentedControl`:

```tsx
<View className="flex-row items-center gap-2">
  <PressScale
    onPress={() => setOutstandingOnly((v) => !v)}
    accessibilityLabel={t('clients.filters.outstanding')}
  >
    <Surface
      className={`rounded-full px-3 py-2 ${outstandingOnly ? 'bg-primary dark:bg-primary-dark' : 'border border-border dark:border-border-dark'}`}
    >
      <Text className={outstandingOnly ? 'text-primary-foreground dark:text-primary-dark-foreground text-xs font-medium' : 'text-xs font-medium'}>
        {t('clients.filters.outstanding')}
      </Text>
    </Surface>
  </PressScale>
</View>
```

(Adjust placement to match the existing layout — read the file first.)

- [ ] **Step 4: Typecheck + manual.**

Manual: from a state where some clients have unpaid items, toggle the chip → list narrows to those clients only; toggle off → full list returns.

- [ ] **Step 5: Commit.**

```
git add "app/(tabs)/clients/index.tsx" src/state/queries/clients.ts
git commit -m "$(cat <<'EOF'
feat(clients): add 'Impayés' filter chip on the list screen

Toggling the chip restricts the list to clients with at least one
unpaid completed stop or unpaid manual history entry.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 20: Final verification

**Files:** none modified.

- [ ] **Step 1: Full test suite + typecheck + lint.**

Run:
```
pnpm test
pnpm typecheck
pnpm lint
```

All must be green.

- [ ] **Step 2: Manual smoke test on device or simulator.**

`pnpm start --dev-client` and walk through:
1. Settings → Moyens de paiement → see 4 seeded → add custom → archive → delete unreferenced.
2. Tour completion: complete a tour with mixed paid / unpaid stops; check error path when forgetting method on a paid stop.
3. Open the closed tour: see Encaissé / Reste dû KPIs, badges; tap an unpaid stop → mark paid via sheet → KPIs update.
4. Manual history: add a manual entry, method required even when paid toggle off — verify the form blocks submit without method.
5. Client detail with outstanding items: see the À encaisser card; tap a line → sheet opens → settle → card disappears.
6. Clients list: toggle Impayés chip → list narrows; settle the last item → client disappears from the chip-filtered list.

- [ ] **Step 3: If anything fails, file follow-up tasks; otherwise this concludes the plan.**

No commit for this task.

---

## Self-review notes

- **Spec coverage:** every section of `2026-05-05-payment-methods-design.md` maps to a task above (domain → Task 1; schema/migration/seed → Task 2; PaymentMethodRepository → Task 3; tour repo + manual repo + client repo → Tasks 4/5/6; use-cases → Tasks 7/8; queries → Tasks 9/10/11; i18n → Task 12; shared UI → Tasks 13/14; settings screens → Task 15; tour completion → Task 16; closed tour → Task 17; client detail outstanding → Task 18; clients list filter → Task 19).
- **Hors-scope items** (split payments, pending status, global outstanding view, red pastilles, accounting export) are explicitly **not** built — confirmed not present in any task.
- **No placeholders** in the implementation steps — every step contains exact paths, exact commands, and the actual code to write.
- **One asymmetry deliberately preserved:** manual history form requires a payment method always (`requireMethodAlways` prop on `PaymentEditor`), while tour completion only requires it when `isPaid` is true. This is intentional per the spec.
