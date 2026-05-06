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
