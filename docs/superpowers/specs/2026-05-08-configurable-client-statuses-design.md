# Configurable client statuses — design

**Date:** 2026-05-08
**Branch target:** `main` (RN/Expo)

## Goal

Allow the user to:

1. Rename and recolor the 6 existing system statuses (`default`, `waiting`, `scheduled`, `done`, `noAnimals`, `banned`).
2. Create / delete arbitrary **manual statuses** (label + color) and assign them to individual clients.
3. Pick from a richer color palette than today's marker-colors screen.

The 6 system statuses' **business rules** stay frozen. `computeClientStatus()` keeps deriving a `systemKey` from `isBanned`, `isWaiting`, animal counts, and tour history — exactly as today. The work in this spec is presentation + a new manual-override mechanism.

## Non-goals

- Modifying derivation rules (e.g. changing the "Sans animaux" threshold).
- Deleting system statuses.
- Reordering statuses (drag-and-drop). The `sortOrder` column exists for future use; for now order = seed order for system + creation order for manual.
- Multi-status / tag model. Each client has one displayed status at a time.
- Bulk assignment of manual statuses across many clients.

## Core model decisions

- **Manual status is a display-only override.** When `client.manualStatusId` is set, it replaces the *displayed* status. The underlying flags (`isWaiting`, `isBanned`) and all business logic that reads them (tour creation, "Mark waiting" toggle, completion auto-flip) keep working untouched.
- **System and manual live in one unified table.** A single `statuses` table holds both kinds. System rows are seeded by migration, identified by a stable `systemKey`, are renameable and recolorable, but never deletable. Manual rows have full CRUD.
- **`computeClientStatus()` stays pure and unchanged.** It still returns a `systemKey`. A new presentation-layer helper resolves `(client, systemKey, registry) → Status row`.
- **The "default" status becomes a real status.** No more `transparent` color, no more hidden badge. It gets seeded with a neutral hex, displays a chip on the map, and can be renamed/recolored like any other system status.

## Data model

### New table: `statuses`

Added to `src/infra/db/schema.ts`.

```
statuses
  id          text PRIMARY KEY                 -- ulid
  kind        text NOT NULL                    -- 'system' | 'manual'
  systemKey   text NULL                        -- 'default'|'waiting'|'scheduled'
                                               -- |'done'|'noAnimals'|'banned' (system rows)
                                               -- | NULL (manual rows)
  label       text NOT NULL                    -- user-editable
  colorLight  text NOT NULL                    -- '#RRGGBB', used in light theme
  colorDark   text NOT NULL                    -- '#RRGGBB', used in dark theme
  sortOrder   integer NOT NULL                 -- ordering in pickers/filters
  createdAt   text NOT NULL                    -- ISO

  INDEX statuses_kind_idx (kind)
  UNIQUE INDEX statuses_system_key_idx (systemKey) WHERE systemKey IS NOT NULL
```

### Modified table: `clients`

```
clients.manualStatusId  text NULL  REFERENCES statuses(id) ON DELETE SET NULL
                                   INDEX clients_manual_status_id_idx
```

`ON DELETE SET NULL` so that deleting a manual status clears the assignment from all clients atomically. The application-level confirmation (with count) happens before the delete is issued.

### Migration

Hand-written Drizzle migration under `src/infra/db/migrations/`. Per CLAUDE.md:

- Set `when: Date.now()` at the time of editing the journal entry — never a "clean" date.
- Run `pnpm db:bundle` after writing the SQL and journal entry.
- Never silence `bundle-migrations` violations via the historical-violations allowlist.

Migration steps:

1. `CREATE TABLE statuses` with the columns and indexes above.
2. `ALTER TABLE clients ADD COLUMN manual_status_id TEXT REFERENCES statuses(id) ON DELETE SET NULL` + index.
3. Seed 6 system rows with `kind='system'`, `systemKey` set, `sortOrder` = 10/20/30/40/50/60. Initial labels and per-theme colors (preserve current hardcoded theme tokens pixel-perfect):

   | systemKey  | label             | colorLight | colorDark |
   |------------|-------------------|------------|-----------|
   | default    | Par défaut        | `#94A3B8`  | `#64748B` |
   | waiting    | En attente de RDV | `#C88226`  | `#DC9E4E` |
   | scheduled  | Planifié          | `#A1602F`  | `#C68A58` |
   | done       | Réalisé           | `#5C7548`  | `#98B282` |
   | noAnimals  | Sans animaux      | `#EAE0D3`  | `#302820` |
   | banned     | Banni             | `#B23832`  | `#DC605A` |

   The exact hexes for `default` are starting values; user can change them. All values target WCAG AA contrast against their respective theme backgrounds.

4. For each `marker_*_color` key in `settings` (e.g. `marker_waiting_color`), copy its value into **both** `colorLight` and `colorDark` of the corresponding system row, then `DELETE FROM settings WHERE settings_key = '<key>'`. Rationale: the legacy customization stored a single hex with no per-theme split, so we preserve the user's chosen color exactly as today (visible in both themes); the user can re-tune via the new Statuts screen if they want a different dark variant.

The migration is idempotent on a fresh DB (no `marker_*_color` keys exist; defaults are used).

## Domain & data layer

### Pure domain (`src/domain/use-cases/`)

- `computeClientStatus()` — **unchanged**. Pure, returns `systemKey`.
- `resolveDisplayedStatus(client, systemKey, registry): Status` — pure. Returns the row to display:
  - if `client.manualStatusId` is set and `registry.byId(manualStatusId)` exists and `kind === 'manual'` → that row;
  - else → `registry.bySystemKey(systemKey)` (always exists; system rows are seeded and undeletable).
- `validateStatusLabel(label): { ok: true, value: string } | { ok: false, error }` — trim, non-empty, ≤ 30 chars.
- `validateColorHex(hex): boolean` — `/^#[0-9A-Fa-f]{6}$/`.
- `validateColorPair({ light, dark })` — both must pass `validateColorHex`. Used at every status mutation entry point.

### Repository (`src/data/repositories/status-repository.ts`, new)

```
StatusRepository
  list(): Status[]                     // ordered by sortOrder
  byId(id): Status | null
  bySystemKey(key): Status             // never null after migration
  createManual({ label, colorLight, colorDark }): Status
  update(id, { label?, colorLight?, colorDark?, sortOrder? }): Status
  deleteManual(id): void               // throws if kind === 'system'
  countClientsUsing(id): number
```

`ClientRepository` extended with `setManualStatus(clientId, statusId | null)`. If `statusId` is non-null, asserts the row exists and `kind === 'manual'`.

### Application use cases

- `createManualStatus({ label, colorLight, colorDark }) → Status` — validate, set `sortOrder = max(sortOrder) + 10`, persist.
- `renameStatus(id, label)` — validate, persist. Works for both kinds.
- `recolorStatus(id, { colorLight, colorDark })` — validate, persist. Works for both kinds.
- `deleteManualStatus(id)` — assert `kind === 'manual'`, delegate to repo (FK `ON DELETE SET NULL` clears assignments).
- `assignManualStatus(clientId, statusId | null)` — assert manual kind when non-null.

### React Query layer (`src/state/queries/statuses.ts`, new)

- `useStatusRegistry()` — `{ list, bySystemKey, byId }`. Cache invalidated on any status mutation.
- `useDisplayedStatusMap()` — combines `useClientStatusMap()` (existing, returns `Map<clientId, systemKey>`) and `useStatusRegistry()` → `Map<clientId, Status>`. This is the source of truth for **display and status-based filtering**.
- `useClientStatusMap()` — **unchanged**. Remains the source of truth for **business logic** (tour creation, toggles, derivation).
- Mutations: `useCreateManualStatus`, `useRenameStatus`, `useRecolorStatus`, `useDeleteManualStatus`, `useAssignManualStatus`. All invalidate `useStatusRegistry`. `useAssignManualStatus` and `useDeleteManualStatus` also invalidate `useDisplayedStatusMap`.

## UI

### Settings: new `Statuts` screen

`app/(tabs)/settings/statuses.tsx` (replaces `marker-colors.tsx`).

Layout: two sections — "Statuts système" (6 fixed rows) and "Mes statuts" (manual rows + "+ Nouveau statut" button at the bottom). Each row shows a colored swatch and the current label, taps open the `StatusEditSheet`.

`StatusEditSheet`:
- Label input with inline validation (`validateStatusLabel`).
- `<ColorPalette>` (see below).
- "Supprimer" button **only for manual rows**. Tapping it shows a confirmation dialog: *"Ce statut est assigné à N clients. Le supprimer retirera cette assignation et ces clients reviendront à leur statut automatique. Continuer ?"* The count comes from `StatusRepository.countClientsUsing(id)`.
- Save / Cancel.

`app/(tabs)/settings/index.tsx` updated: "Couleurs des marqueurs" → "Statuts".

### `<ColorPalette>` (new, `src/ui/components/color-palette.tsx`)

Curated grid of 24 swatches (6 columns × 4 rows) covering warm/cool/neutral. **Each swatch is a coordinated `{ light, dark }` pair** — the user picks a single visual swatch, and the component returns both hexes. Pairs are designed so that each side of the pair meets WCAG AA against its respective theme background (per the project's NativeWind theming pattern).

The 24 pairs are a frozen constant `PALETTE_PAIRS: ReadonlyArray<{ light: string; dark: string }>` in the component module.

The swatch preview itself shows a split or layered representation (e.g. light/dark diagonal split) so the user can see both variants at a glance.

A "Couleur personnalisée" button below the grid opens a hex input. Custom hex flow: the user enters **one** hex; the component sets both `colorLight` and `colorDark` to that value, with an inline note explaining that this single value will be used in both themes.

No `transparent` swatch — the special case is gone.

### Client detail: manual status assignment

New `<ClientManualStatusCard>` (`src/ui/components/client-manual-status-card.tsx`), inserted into the client detail screen alongside the existing `<ClientStatusActionsCard>` (which stays untouched — it acts on underlying business flags).

States:
- No manual status: card shows `[Aucun]   Choisir un statut`. Tap opens `<ManualStatusPicker>` (a sheet listing all manual statuses with badge previews + "Aucun (statut auto)" option + a "Créer un statut" shortcut that pushes to the Statuts settings screen).
- Manual status set: card shows `[<badge>]   Retirer`. Plus a help text: *"Quand un statut manuel est défini, il remplace le statut automatique."*
- No manual statuses exist yet: empty state — *"Aucun statut manuel défini. Créer dans Réglages → Statuts."*

### Filter dialog

`src/ui/components/client-status-filter-dialog.tsx` refactored:
- Source = `useStatusRegistry().list` (system + manual mixed, ordered by `sortOrder`).
- The store `src/state/ui/client-filters-store.ts` switches its persisted state from `Set<ClientStatus>` to `Set<statusId>`. Bump the Zustand `persist` version to invalidate any saved filter sets.
- The list query that previously filtered using `useClientStatusMap` now filters using `useDisplayedStatusMap` so filtering matches what's actually displayed.

### Map: status chips

`src/ui/components/map-status-chips.tsx` refactored:
- Chip list = `[chip "all"] + useStatusRegistry().list`. The `default` chip appears here automatically; manual statuses appear too.
- Active chip background = the row's `colorHex` (or kept as primary, see implementation).
- `src/state/ui/map-filters-store.ts` switches `activeFilter` from `'all' | ClientStatus` to `string | null` (null = all, otherwise `statusId`).
- `src/state/queries/kpis.ts` (`useMapKpis`) returns `Map<statusId, number>` instead of fixed keys. Counts are computed from `useDisplayedStatusMap`, so a client with a manual override is counted under that manual status, not its derived one.
- i18n keys `map.chip_*` (per-status) are removed; `map.chip_all` stays for the "Tous" pseudo-chip.

### Components updated to consume `useDisplayedStatusMap`

| File | Change |
|---|---|
| `src/ui/components/client-status-badge.tsx` | Takes a `Status` row; label from the row, color = `colorLight`/`colorDark` picked via existing `useResolvedColorScheme()`. |
| `src/ui/components/client-card.tsx` | Uses `useDisplayedStatusMap`. |
| `src/ui/components/client-pin.tsx` | Pin color = `colorLight`/`colorDark` of displayed status, picked via `useResolvedColorScheme()`. |
| `src/ui/components/client-pin-popup.tsx` | Same — displays manual override when set; per-theme hex via `useResolvedColorScheme()`. |
| `src/ui/components/client-status-actions-card.tsx` | **Unchanged**. Continues to act on underlying flags via `useClientStatusMap`. |

### Files removed

- `src/lib/client-status-color.ts` — color now lives on the `Status` row.
- `app/(tabs)/settings/marker-colors.tsx` — replaced by the Statuts screen.
- i18n keys (now dead): `clients.filter_status_*`, `map.status_*`, `map.chip_<status>` (keep `map.chip_all`), `settings.marker_colors.*`.

## Cloud sync (backups)

Backups already capture the full local DB by snapshot, but `src/infra/cloud/backups.ts` and `backup-schema.ts` enumerate tables explicitly and validate via versioned Zod schemas. The new table is **not** captured automatically.

Changes:

- `dumpAllTables()`: add `statuses: await db.select().from(schema.statuses)`. The new `manualStatusId` column on `clients` is captured automatically by `db.select().from(schema.clients)`.
- `wipeAndRestore()`: insert `statuses` **before** `clients` (FK constraint). Delete order is unconstrained thanks to `ON DELETE SET NULL`, but for readability we delete clients before statuses.
- `backup-schema.ts`: new `BackupSnapshotV5Schema` (`schemaVersion: 5`, adds `tables.statuses` shape with `colorLight` + `colorDark` and optional `manualStatusId` on the client shape).
- `createBackup()` writes `schemaVersion: 5`.
- New migration `migrateV4ToV5(snapshot) → v5 snapshot`:
  - Seeds the 6 system rows in `tables.statuses` (same labels and `colorLight`/`colorDark` pairs as the local migration's defaults).
  - For any `marker_*_color` key in `tables.settings`, overwrite **both** `colorLight` and `colorDark` of the corresponding system row with that value, then strip the key from `tables.settings`.
  - Sets `manualStatusId = null` on every restored client.
- Restore chain: v2 → v3 → v4 → v5. Older format paths reuse the existing v2→v3 and v3→v4 migrations and then chain through v4→v5.

## Validation, edge cases, guard rails

- **Label validation:** trimmed, non-empty, ≤ 30 chars. Inline error in `StatusEditSheet`.
- **Color validation:** strictly `#RRGGBB` for both `colorLight` and `colorDark`. Palette pairs valid by construction.
- **No label uniqueness enforced** — low value, adds friction.
- **Repo defenses:** `deleteManual` throws on system rows; `assignManualStatus` throws on system rows (UI never offers them, but defense in depth).
- **Stale `manualStatusId` between renders:** `resolveDisplayedStatus` falls back to the derived status if the manual row is missing.
- **Migration idempotency:** seeding logic only runs on the migration; on a DB that already has the rows (re-run of bundle, etc.) the migration version gate prevents re-execution.
- **Saved filter state:** Zustand `persist` version bumped on `client-filters-store` and `map-filters-store` so old `Set<ClientStatus>` / `'all' | ClientStatus` shapes are dropped and re-initialized.

## RGPD impact

- No new personal data: a manual status is a user-supplied qualifier, not a personal attribute. No new sub-processor; no new external sync.
- `ClientRepository.anonymize` (per `docs/superpowers/specs/2026-05-06-rgpd-mvp-design.md`) must additionally clear `manualStatusId` so anonymized clients carry no qualification trace. Add `manualStatusId` to the scrub list and cover it in the test.
- Data portability export (`useExportData`) inherits the change automatically if it serializes the full DB; otherwise the `statuses` table and the `manualStatusId` column must be added to its output.

## Testing

- `tests/domain/` (vitest):
  - `validateStatusLabel` — empty / whitespace-only / too long / valid.
  - `validateColorHex` — valid / invalid / no-transparent.
  - `validateColorPair` — both valid / one invalid / both invalid.
  - `resolveDisplayedStatus` — 4 cases: no manual → derived; manual valid → manual; manual ID with missing row → fallback; banned client + manual → manual.
- `tests/data/` (jest):
  - `StatusRepository` CRUD; `countClientsUsing`; `deleteManual` throws on system row.
  - `ClientRepository.setManualStatus` happy path + assertion on system kind.
  - FK `ON DELETE SET NULL` clears `manualStatusId` after `deleteManual`.
  - `ClientRepository.anonymize` clears `manualStatusId`.
  - Migration: 6 system rows seeded, with `marker_*_color` carry-over verified, with `marker_*_color` keys stripped from settings.
- `tests/infra/` (jest):
  - Backup v5 round-trip (snapshot → restore → compare).
  - `migrateV4ToV5` with and without `marker_*_color` keys in the v4 settings.

## Out-of-scope reminders

- Drag-and-drop reordering of statuses.
- Bulk assignment of manual statuses.
- Modifying derivation rules.
- Multi-tag model.

## Implementation conventions

- All identifiers, file names, table/column names in **English** (per CLAUDE.md). Only the seeded labels in the migration and i18n value strings are French.
- All new pressables use `<PressScale>`. Critical actions (assign, delete) trigger haptics from `@/ui/motion/haptics`.
- All new strings via `t('...')`.
- TS strict — no `any`. Status row inferred from Drizzle schema.
- Durations and easings via `motion-tokens.ts`. No literal ms in components.
