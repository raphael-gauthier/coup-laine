# CLAUDE.md

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. RN Stack (post-migration)

This worktree (`rn-migration` branch) targets **iOS + Android** via Expo + React Native, replacing the Flutter app on `main`. See [`docs/superpowers/specs/2026-05-03-migration-expo-rn-design/`](docs/superpowers/specs/2026-05-03-migration-expo-rn-design/README.md) for the full design.

**Quick reference:**
- Package manager: **pnpm** (never npm or yarn)
- Tests: `pnpm test` (vitest for `tests/domain/`, jest for `tests/data/` and `tests/infra/`)
- Typecheck: `pnpm typecheck`
- Lint: `pnpm lint`
- Dev: `pnpm start` (with `--dev-client`)
- DB migrations: `pnpm db:generate` (Drizzle)

**Conventions:**
- All durations and easings via `motion-tokens.ts`. No `ms: 250` literals in components.
- All pressables use `<PressScale>`. All critical actions trigger haptics from `@/ui/motion/haptics`.
- All strings via `t('...')` (i18next). No FR strings in JSX.
- TS strict mode is enforced. No `any`. Use `unknown` + narrowing or proper types.

## 6. Developer Requests

**Code is English-only. User-facing copy stays French (i18n only).**

- Identifiers (variables, functions, types, classes, constants), file names, folder names, route paths, DB table/column names, settings keys, i18n key paths, and code comments **MUST be in English**.
- French is allowed only inside `src/i18n/locales/*.json` **values** (the actual UI text). Never inside keys.
- If you spot a French identifier or path while working (e.g. `prestation`, `metier`, `tournee`), flag it. Don't introduce new ones — even temporarily.
- When the user gives a durable instruction or convention (like the rule above, a naming choice, a workflow preference, a hook setup) that future sessions should know, **update this `CLAUDE.md` in the same turn** before continuing. Memory files are for cross-conversation context; project conventions belong here so any agent in the repo picks them up.

**RGPD compliance — MVP shipped 2026-05-06.**

The app already implements the MVP RGPD : hosted legal docs surface (`src/infra/config/legal-urls.ts` + `app/(tabs)/settings/legal.tsx` + onboarding/login info notices), client anonymization (`ClientRepository.anonymize` + `planAnonymization` use case — scrubs identity, preserves compta per Code de commerce L123-22), cloud account deletion (`supabase/functions/delete-account` Edge Function + `useDeleteAccount` hook), data portability export (`useExportData` hook). Full spec: `docs/superpowers/specs/2026-05-06-rgpd-mvp-design.md`.

- Before implementing any new feature or behavior change, **evaluate the RGPD impact**. Triggers to watch for: new field/column storing personal data (identity, contact, geoloc, free-text notes), new external service or SDK processing personal data, change to retention / deletion / export / consent flows, new tracker or telemetry, modification of who can access backups, change to the anonymization scrub list.
- If the change touches personal data even indirectly, **stop, flag the impact explicitly to the user, and ask before continuing**. Don't proceed silently — the user is the data controller and must validate the trade-off (lawful basis, retention, sub-processors, info notice update).

**Drizzle migrations — `when` ordering and bundling.**

The Expo SQLite migrator skips any journal entry whose `when` is ≤ `max(when)` of already-applied migrations on the user's DB (it picks `lastDbMigration = max(created_at)` once, then runs entries strictly above it). A hand-written migration with a stale `when` is skipped silently and surfaces days later as `no such column …` errors. `drizzle-kit generate` uses `Date.now()` so it's safe by construction; the trap is hand-written migrations (renames, drops — drizzle-kit prompts interactively for those).

- When hand-writing a migration's journal entry in `src/infra/db/migrations/meta/_journal.json`, set `when: Date.now()` at the moment of editing. **Do not pick a "clean" date** — it can collide with an earlier entry's auto-generated `Date.now()`.
- After **any** edit to `_journal.json` or to a `*.sql` file under `src/infra/db/migrations/`, run `pnpm db:bundle`. The bundle script (`scripts/bundle-migrations.mjs`) regenerates `migrations.js` (loaded at runtime) **and** validates that every entry's `when` is strictly greater than the max of all preceding `when` values. If you see a `Migration "…" has when=…` error from `pnpm db:bundle`, bump that entry's `when` to at least `previousMax + 1` — never silence it via the `KNOWN_HISTORICAL_VIOLATIONS` allowlist (that list is for already-shipped violations only; bumping a shipped migration's `when` would force destructive re-execution on user DBs).

**Drizzle migrations — `--> statement-breakpoint` is mandatory in multi-statement SQL.**

`expo-sqlite`'s `prepareSync` compiles only the **first** SQL statement in a string; trailing statements are silently dropped. The migrator wraps all of a migration's statements in one transaction and INSERTs into `__drizzle_migrations` on success. If your `.sql` file is multi-statement and lacks `--> statement-breakpoint` separators, only the first statement runs, the migrator records the migration as applied, and **the schema change never lands**. The bug surfaces later as `no such column …` runtime errors, and the migrator refuses to retry because `__drizzle_migrations` claims success.

- Every `.sql` migration that contains more than one SQL statement **MUST** have `--> statement-breakpoint` between every pair of statements (including before/after `PRAGMA` lines). Look at `0001_r1_flutter_parity.sql` for the canonical pattern.
- `migrations.js` is a **runtime artifact** loaded by the app, not a build-time generated file. After any edit to a `.sql` or `_journal.json`, run `pnpm db:bundle` AND **commit the regenerated `migrations.js` in the same commit**. Forgetting this means the runtime keeps loading the previous (often broken) bundle.
- Prefer **idempotent migration SQL**: when recreating a table, start with `DROP TABLE IF EXISTS __new_X;` so a second run after a partial earlier failure can recover cleanly.

**Drizzle migrations — user data is sacred. Never tell the user to wipe.**

User data persistence is non-negotiable. The app is the user's source of truth for their business. A migration mistake is **always** recoverable via a follow-up migration; it is **never** acceptable to tell the user to clear app storage, uninstall/reinstall, factory-reset, or otherwise lose data.

- When a migration error reaches a user, the only acceptable recovery path is to ship a **corrective migration** that fixes the schema in place. Common pattern: bump the failing migration's `when` value past the highest `created_at` users may have for it (so the migrator re-attempts), and make the SQL idempotent against any partial state (e.g. `DROP TABLE IF EXISTS __new_X`, `INSERT OR IGNORE`, `ALTER TABLE … IF NOT EXISTS …` workarounds).
- Before merging any migration: run `pnpm jest tests/data/` (the repo tests boot a real SQLite DB and apply migrations end-to-end) AND boot the dev client against a populated DB to confirm the migration applies cleanly. `pnpm db:bundle` alone is not sufficient — it only validates `when` ordering, not that the SQL actually executes.
- If you suspect a migration shipped half-applied, **stop and design a recovery migration before any other action**. Don't suggest a wipe as a workaround, even temporarily — the user reads the suggestion and may act on it, losing their data.
