# Payment methods — Design

**Date:** 2026-05-05
**Status:** approved (pending implementation plan)

## Summary

Add a `PaymentMethod` catalog (mirroring the `Service` catalog: seed at install + manageable in Settings), and per-stop / per-manual-entry payment tracking (method, paid/unpaid, paid date, optional note).

A stop's payment method is required when marked paid, optional otherwise (deferred payment). Manual history entries follow the same payment cycle. Outstanding payments are visible on the client detail screen, on the closed tour bilan, and via a filter chip on the clients list.

## Goals

- Capture how each client paid at tour close.
- Allow deferred payments (mark as paid later from the client detail screen or the closed tour screen).
- Make outstanding amounts visible without adding noise to the clients list.
- Keep the payment method catalog editable (rename, archive, reorder, add) from Settings.

## Non-goals (YAGNI)

- Splitting a single payment across multiple methods.
- An intermediate `pending` status (e.g. check handed over but not cashed).
- A global cross-client "all outstanding" screen.
- Red pastilles on client list cards (the filter chip is sufficient).
- Automatic reminders or accounting export.

## Domain model

### `PaymentMethod` (new entity)

`src/domain/models/payment-method.ts`

```ts
export const PaymentMethod = z.object({
  id: z.string(),
  label: z.string(),
  isActive: z.boolean(),
  archivedAt: z.string().nullable(),
  ordering: z.number().int(),
});
```

### `Payment` (new value object, embedded inline)

`src/domain/models/payment.ts`

```ts
export const Payment = z.object({
  methodId: z.string().nullable(),
  methodLabelSnapshot: z.string().nullable(),
  isPaid: z.boolean(),
  paidAt: z.string().nullable(),  // ISO datetime
  note: z.string().nullable(),
});
```

Embedded as `payment: Payment` on both `TourStop` and `ManualHistoryEntry`.

### Invariants

The Zod schema for `Payment` is permissive (each field validated independently) to accommodate the migration backfill (paid rows with `methodId = null`). The stricter invariants below are enforced at the **UI / mutation boundary** (form validation + payment editor):

- When the user marks a row paid: `methodId` must be set, `paidAt` must be set, `methodLabelSnapshot` must be populated from the catalog at write time.
- `isPaid === false` ⇒ `paidAt` must be null. `methodId` may be null or pre-filled (kept across toggle for ergonomics).
- When `isPaid` flips `false → true`, the consumer populates `methodLabelSnapshot` from the catalog.
- When `isPaid` flips `true → false`, `paidAt` and `methodLabelSnapshot` are cleared. `methodId` is kept (correction-friendly).

The manual history form has a stricter rule (method always required regardless of `isPaid`) — see UI section.

## Data layer

### Schema

New table `payment_methods`:

```ts
export const paymentMethods = sqliteTable('payment_methods', {
  id: text('id').primaryKey(),
  label: text('label').notNull(),
  isActive: integer('is_active').notNull().default(1),
  archivedAt: text('archived_at'),
  ordering: integer('ordering').notNull(),
});
```

Five columns added to both `tour_stops` and `manual_history_entries`:

| Column                          | Type    | Null | Notes                                  |
|---------------------------------|---------|------|----------------------------------------|
| `payment_method_id`             | TEXT    | YES  | FK → `payment_methods(id)`             |
| `payment_method_label_snapshot` | TEXT    | YES  | Snapshot at the time of payment        |
| `is_paid`                       | INTEGER | NO   | Default `0`                            |
| `paid_at`                       | TEXT    | YES  | ISO datetime                           |
| `payment_note`                  | TEXT    | YES  | Free text                              |

Indexes: `tour_stops_is_paid_idx` on `(is_paid)` and `manual_history_is_paid_idx` on `(is_paid)`.

### Migration `0003_payment_methods.sql`

1. `CREATE TABLE payment_methods (...)`.
2. `ALTER TABLE tour_stops ADD COLUMN ...` × 5.
3. `ALTER TABLE manual_history_entries ADD COLUMN ...` × 5.
4. `CREATE INDEX ...` × 2.
5. Seed the four default methods (idempotent via `INSERT OR IGNORE`):
   - `pm-cash` — Espèces — ordering 1
   - `pm-check` — Chèque — ordering 2
   - `pm-transfer` — Virement — ordering 3
   - `pm-card` — Carte bancaire — ordering 4
6. Backfill pre-feature data so it does not appear as outstanding:
   - `UPDATE tour_stops SET is_paid = 1, paid_at = completed_at WHERE completed_at IS NOT NULL`.
   - `UPDATE manual_history_entries SET is_paid = 1, paid_at = date`.
   - `payment_method_id` and `payment_method_label_snapshot` stay NULL on backfilled rows.

The bootstrap also re-runs the seed step on every start (idempotent) so an empty install gets the default catalog.

### Repositories

`PaymentMethodRepository` (`src/data/repositories/payment-method-repository.ts`) — calque of `ServiceRepository`:

- `byId(id)`, `listAll()`, `listActive()` (sorted by `ordering`).
- `upsert(pm)`, `setArchived(id, archivedAt)`, `delete(id)`.
- `delete` rejects (throws) if the method is referenced by any `tour_stops` or `manual_history_entries` row. UI surfaces this as a toast.

`TourRepository` and `ManualHistoryRepository`:

- `toRow` / `fromRow` extended to map the five new columns to / from the `payment` value object.
- `upsertTour`, `completeWithBilan`, `upsert` (manual history) take the `payment` through their existing input shapes — no new public methods for the create path.
- New focused methods:
  - `TourRepository.markStopPayment(stopId, payment)` — used by the deferred-payment editor.
  - `ManualHistoryRepository.markEntryPayment(entryId, payment)` — same.

`ClientRepository` gets a helper used by the filter chip:

```ts
async listClientIdsWithOutstanding(): Promise<Set<string>>
```

Implementation: union of two `SELECT DISTINCT client_id` queries (`tour_stops WHERE is_paid = 0 AND completed_at IS NOT NULL`, `manual_history_entries WHERE is_paid = 0`).

### React Query hooks

`src/state/queries/payment-methods.ts`:

- `usePaymentMethods()` (active by default; option `'all'`).
- `useUpsertPaymentMethod()`, `useArchivePaymentMethod()`, `useDeletePaymentMethod()`.

`src/state/queries/tours.ts` — `useCompleteWithBilan` extended: the input gains `perStopPayments: Map<stopId, Payment>` alongside `perStopActuals` / `perStopNotes`. New `useMarkStopPayment()` for deferred edits.

`src/state/queries/history.ts` — `UpsertManualHistoryInput` gains `payment: Payment`. New `useMarkManualEntryPayment()`.

Invalidations on payment mutations: `['tours']`, `['history']`, `['clients']` (KPIs).

## Use cases

### `compute-client-outstanding.ts` (new)

```ts
interface ClientOutstanding {
  unpaidCents: number;
  unpaidCount: number;
}

function computeClientOutstanding(args: {
  completedStops: TourStop[];
  manualEntries: ManualHistoryEntry[];
}): ClientOutstanding;
```

Sums `qty * priceCentsSnapshot` over `actualServices` (or `services` for manual entries) on every row where `payment.isPaid === false`. Pure, testable.

### `compute-tour-payment-kpis.ts` (new)

```ts
interface TourPaymentKpis {
  collectedCents: number;
  outstandingCents: number;
}
```

Used on the closed-tour screen to show "Encaissé" / "Reste dû" alongside the existing revenue KPI.

### Existing KPIs

`compute-client-kpis.ts` gains an `unpaidCents` field on its return shape. Existing fields and their computations are unchanged.

## UI

### Settings → Payment methods

New folder `app/(tabs)/settings/payment-methods/` with `index.tsx`, `new.tsx`, `[id].tsx`. Calque of `settings/services/` minus category / species / price / minutes (label + active + archive + ordering only).

A new entry in `app/(tabs)/settings/index.tsx` next to "Prestations".

Reusable `PaymentMethodForm` (label required, RHF + Zod, aligned with `ServiceForm`).

### Tour completion (`app/(tabs)/tours/[id]/complete.tsx`)

Each `StopCompletionEditor` gets a payment block under the services block. Local state extended with `perStopPayments: Record<stopId, Payment>`.

```
┌ Services ─────────────────┐
│ ... (existing)            │
└───────────────────────────┘
┌ Paiement ─────────────────┐
│ [☐ Payé]                  │
│ Moyen : [ Espèces ▾ ]     │  ← required when Payé is on
│ Date  : [ Aujourd'hui ▾ ] │  ← visible when Payé is on, default = now
│ Note  : [_________]       │  ← optional
└───────────────────────────┘
```

Validation on confirm: for every stop that has at least one validated service AND `isPaid === true`, `methodId` must be set. Otherwise: error haptic + inline highlight + scroll into view.

`useCompleteWithBilan` writes the per-stop payments alongside `actualServices` in the same transaction.

### Closed tour detail (`app/(tabs)/tours/[id].tsx`)

Each stop displays a payment badge ("Payé · Espèces" or "Impayé"). Tapping a stop opens a `StopPaymentEditor` bottom sheet (toggle Payé, method picker, date, note) → `useMarkStopPayment`.

Header KPIs gain "Encaissé · X €" and "Reste dû · Y €" (the latter hidden when zero) using `compute-tour-payment-kpis`.

### Manual history form (`src/ui/components/manual-history-form.tsx`)

Add the same payment block under the services block. **Method required by the form's Zod schema regardless of `isPaid`** — the user explicitly knows how the past intervention was settled (or will be) when they enter it manually. `isPaid` defaults to `true` at creation (dominant case) but is toggleable for "intervention done, not yet paid". `paidAt` defaults to the entry's `date` when toggled on for the first time.

This is the one asymmetry with tour-stop completion (where method is optional when unpaid). Rationale: at tour close, the user often hasn't decided yet how a defaulting client will eventually pay. At manual-entry time, they're recording a past or planned event with full context.

### Client detail (`app/(tabs)/clients/[id].tsx`)

A new "À encaisser" block appears under the existing KPIs **only when** `outstanding.unpaidCount > 0`:

```
┌─ À encaisser ─────────────┐
│ 90 €  ·  2 interventions  │
│ ───────────────────────── │
│ Tournée 12/04/26 · 50 €  >│
│ Saisie 03/03/26   · 40 €  >│
└───────────────────────────┘
```

Each line opens the appropriate payment editor (`StopPaymentEditor` for tour stops, equivalent for manual entries) preset to "mark as paid".

### Clients list (`app/(tabs)/clients/index.tsx`)

A new "Impayés" filter chip in the existing chips row. Filter uses the intersection with `listClientIdsWithOutstanding()` and combines with other active chips.

### Shared components

- `PaymentMethodPicker` — bottom sheet listing active methods, single selection. Used everywhere.
- `PaymentEditor` — the Payé / Méthode / Date / Note block. Reused in tour completion, manual history form, and the deferred-payment bottom sheet.

### i18n (`src/i18n/locales/fr.json`)

New keys under:

- `payments.*` — `title`, `method`, `is_paid`, `paid_at`, `note`, `outstanding_title`, `outstanding_summary`, `method_required`, `method_picker_title`, `editor_title`, `mark_as_paid`, `paid_badge`, `unpaid_badge`, `kpi_collected`, `kpi_outstanding`.
- `catalogs.payment_methods.*` — list / new / edit screen copy, mirroring `catalogs.services.*`.
- `clients.filters.outstanding` — chip label.
- Seed labels (already French): `Espèces`, `Chèque`, `Virement`, `Carte bancaire`.

All identifiers (file paths, query keys, props, settings keys) stay English; only the JSON values are French.

## Edge cases

### Method archived after use

Archiving (`isActive = 0` + `archivedAt`) hides the method from pickers. Existing payments still resolve through the snapshot (`payment_method_label_snapshot`) for display. The Settings list shows archived methods under a collapsible "Archivés" section, mirroring services.

### Method deletion

Refused if any `tour_stops.payment_method_id` or `manual_history_entries.payment_method_id` references the row. Toast: "Cette méthode est utilisée — archive-la plutôt." Allowed otherwise.

### Method renamed after payment

The snapshot (`payment_method_label_snapshot`) preserves the original label on past payments. New payments snapshot the current label.

### Toggling `isPaid` true → false

Allowed (correction). `paidAt` and `methodLabelSnapshot` cleared. `methodId` kept (the user typically just mis-clicked the toggle).

### Editing `actualServices` of an already-paid stop

The total can change but the payment status is preserved as-is. The bilan reflects the new total. No partial-payment notion: if the user over- or under-paid, they can leave a free-form note. Documented as a deliberate simplification.

### Planned (non-completed) tours

Stops on planned tours (`completedAt IS NULL`) are excluded from outstanding queries and KPIs — they are not yet financially real.

### Wipe / reset

`src/infra/db/wipe.ts` adds `payment_methods` to the wiped tables. The next bootstrap re-seeds the four defaults.

## Testing

### vitest (`tests/domain/`)

- `compute-client-outstanding`: mixed paid / unpaid stops + manual entries, zero-quantity services, pre-feature backfilled rows (paid).
- `compute-tour-payment-kpis`: collected vs outstanding split.
- `Payment` model invariants: refuses `isPaid: true` without `methodId`; clears `paidAt` on `isPaid: false`.

### jest (`tests/data/`)

- `payment-method-repository`: CRUD, `listActive` ordering, archive round-trip, deletion guard when referenced.
- `tour-repository`: payment round-trip via `upsertTour` / `completeWithBilan` / `markStopPayment`.
- `manual-history-repository`: payment round-trip via `upsert` / `markEntryPayment`.
- `client-repository.listClientIdsWithOutstanding`: union of stop-based and manual-based outstanding.
- Migration `0003`: backfill correctness (existing completed stops & entries become paid; new ones default unpaid).

## Out of scope (deferred)

- Global "All outstanding" screen across clients.
- Red pastille on client list cards.
- Split payments (multiple methods / partial amounts per stop).
- `pending` status (check handed over, not yet cashed).
- Accounting export, automated reminders.
