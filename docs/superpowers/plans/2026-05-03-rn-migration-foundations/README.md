# RN Migration — Foundations Implementation Plan (J0 + J1 + J2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bootstrap a working Expo + React Native project (iOS + Android) with the full foundations: Drizzle/SQLite persistence, the entire domain layer ported from Dart to TypeScript, and a functional Settings screen with theming (light/dark switch + base/domicile form using BAN address autocomplete).

**Architecture:** Layered (app/screens → state → domain → data → infra). Domain layer is pure TS, 100% unit-tested. Persistence via Drizzle ORM on `expo-sqlite`. UI built with NativeWind v4 + react-native-reusables. State managed with Zustand (UI) + TanStack Query (server/async). Motion via Reanimated v3 + Moti + expo-haptics, baked into primitives from day one.

**Tech Stack:** Expo SDK 53+, TypeScript strict, Expo Router (file-based), NativeWind v4, react-native-reusables, Drizzle ORM, expo-sqlite, Zustand, TanStack Query, react-hook-form + zod, i18next, react-native-reanimated, react-native-gesture-handler, moti, expo-haptics, lottie-react-native, @supabase/supabase-js, expo-secure-store, lucide-react-native, date-fns. Package manager: pnpm.

**Spec:** [`../../specs/2026-05-03-migration-expo-rn-design/`](../../specs/2026-05-03-migration-expo-rn-design/README.md)

**Worktree location:** `C:\Users\rapha\Documents\Development\coupe-laine-rn\` on branch `rn-migration`.

---

## Phases

The plan is split per phase. Tackle in order — each phase produces something verifiable on its own.

| # | Phase | Focus | File |
|---|---|---|---|
| 0 | Bootstrap | Worktree + Expo project + NativeWind + motion + Drizzle + Supabase + Expo Router + tests + EAS, ending with hello-screen running on iOS + Android | [00-bootstrap.md](./00-bootstrap.md) |
| 1 | Persistence + Domain | Drizzle schema (all tables) + migrations + seeds + repositories + all pure TS use cases ported from Dart, 100% tested | [01-persistence-domain.md](./01-persistence-domain.md) |
| 2 | Settings + theming | BAN service + AddressAutocompleteInput + Settings root + Apparence (theme toggle) + Domicile/Base form, theming fully wired | [02-settings-theming.md](./02-settings-theming.md) |

After this plan completes (J0+J1+J2 merged), subsequent jalons (J3 Clients, J4 Map, ...) will get their own plan documents written just-in-time.

---

## File-structure plan

Target shape for the worktree after this foundations plan completes. Phases create files into this structure.

```
coupe-laine-rn/                          (worktree root)
├── app/
│   ├── _layout.tsx                      # root layout: providers (Theme, QueryClient, i18n, GestureHandlerRoot)
│   ├── index.tsx                        # hello screen for J0; redirected to /clients later
│   ├── (tabs)/
│   │   ├── _layout.tsx                  # tabs layout with placeholder routes
│   │   ├── settings/
│   │   │   ├── _layout.tsx              # stack
│   │   │   ├── index.tsx                # Settings root
│   │   │   ├── appearance.tsx           # theme toggle
│   │   │   └── base.tsx                 # base/domicile form
│   │   ├── clients/index.tsx            # placeholder for J3
│   │   ├── tours/index.tsx              # placeholder for J6
│   │   ├── proximity/index.tsx          # placeholder for J5
│   │   └── map/index.tsx                # placeholder for J4
├── src/
│   ├── domain/
│   │   ├── models/
│   │   │   ├── coordinates.ts
│   │   │   ├── animal-count.ts
│   │   │   ├── client.ts
│   │   │   ├── species.ts
│   │   │   ├── animal-category.ts
│   │   │   ├── prestation.ts
│   │   │   ├── tour.ts
│   │   │   ├── tour-stop.ts
│   │   │   ├── tour-stop-prestation.ts
│   │   │   ├── manual-history-entry.ts
│   │   │   ├── distance-matrix-entry.ts
│   │   │   └── intervention.ts
│   │   └── use-cases/
│   │       ├── bracket-counter.ts
│   │       ├── cost-split-calculator.ts
│   │       ├── tour-duration-estimator.ts
│   │       ├── find-nearby-clients.ts
│   │       ├── find-clients-near-anchors.ts
│   │       ├── tour-order-optimizer.ts
│   │       ├── build-tour-draft.ts
│   │       ├── build-optimized-tour-proposal.ts
│   │       ├── client-status.ts
│   │       └── find-communes-with-waiting.ts
│   ├── data/
│   │   ├── repositories/
│   │   │   ├── client-repository.ts
│   │   │   ├── tour-repository.ts
│   │   │   ├── distance-matrix-repository.ts
│   │   │   ├── prestation-repository.ts
│   │   │   ├── species-repository.ts
│   │   │   ├── animal-category-repository.ts
│   │   │   ├── manual-history-repository.ts
│   │   │   └── settings-repository.ts
│   │   └── seeds/
│   │       ├── species-seeds.ts
│   │       └── prestation-seeds.ts
│   ├── infra/
│   │   ├── db/
│   │   │   ├── schema.ts                # Drizzle table definitions
│   │   │   ├── client.ts                # expo-sqlite + Drizzle setup
│   │   │   └── migrations/              # generated by drizzle-kit
│   │   ├── services/
│   │   │   ├── ban-geocoding.ts
│   │   │   └── supabase.ts
│   │   └── config/
│   │       └── env.ts
│   ├── state/
│   │   ├── stores/
│   │   │   └── theme-store.ts
│   │   └── queries/
│   │       └── settings.ts              # useThemeMode, useBaseAddress, mutations
│   ├── ui/
│   │   ├── primitives/                  # copied from react-native-reusables, editable
│   │   │   ├── button.tsx
│   │   │   ├── text.tsx
│   │   │   ├── input.tsx
│   │   │   ├── label.tsx
│   │   │   └── ...
│   │   ├── components/
│   │   │   ├── address-autocomplete-input.tsx
│   │   │   └── theme-toggle.tsx
│   │   ├── motion/
│   │   │   ├── motion-tokens.ts
│   │   │   ├── press-scale.tsx
│   │   │   ├── haptics.ts
│   │   │   └── transitions.ts
│   │   └── theme/
│   │       ├── tokens.ts                # Modern Craft palette (light + dark)
│   │       └── theme-provider.tsx       # applies theme based on settings + system
│   ├── lib/
│   │   ├── format-minutes.ts
│   │   ├── phone-formatter.ts
│   │   ├── phone-normalizer.ts
│   │   ├── text-search.ts
│   │   ├── text-pluralization.ts
│   │   ├── animal-counts-merge.ts
│   │   ├── animal-counts-normalizer.ts
│   │   └── haversine-distance.ts
│   └── i18n/
│       ├── index.ts
│       └── locales/
│           └── fr.json
├── tests/
│   ├── domain/                          # vitest pure TS
│   ├── data/                            # jest with sqlite :memory:
│   └── infra/                           # jest + msw
├── assets/
│   ├── icons/
│   └── illustrations/
├── app.json                             # Expo config
├── eas.json                             # EAS profiles
├── tailwind.config.js
├── babel.config.js
├── metro.config.js
├── drizzle.config.ts
├── tsconfig.json
├── vitest.config.ts
├── jest.config.js
├── .env.example
├── package.json
└── pnpm-lock.yaml
```

---

## Conventions used in every phase

- **TDD where it pays off.** Domain logic, repositories, services, lib utilities: write the test first, watch it fail, implement, watch it pass, commit. UI screens get one or two RNTL tests at most for non-trivial interaction logic; visual rendering is verified manually on device.
- **Commit cadence.** One commit per task (sometimes per step for tasks with multiple sub-changes). Conventional commits (`feat:`, `test:`, `refactor:`, `chore:`, `docs:`).
- **TS strict mode is non-negotiable.** Every file compiles cleanly under `tsc --noEmit` with `strict`, `noUncheckedIndexedAccess`, `noImplicitOverride`. Don't disable rules.
- **No `any`.** Use `unknown` + narrowing, or proper types. Tools like Drizzle and Zod give us inference — use it. For repository constructors that must accept both prod (`expo-sqlite`) and test (`better-sqlite3`) Drizzle instances, use the abstract `Db` type exported from `src/infra/db/client.ts` (defined in Task 0.7).
- **Run command for tests:**
  - Domain (pure TS, no RN): `pnpm vitest run tests/domain/<file>` or `pnpm vitest` for full domain suite
  - Data + infra (jest with RN env or sqlite): `pnpm jest tests/data/<file>` or `pnpm jest` for the jest suite
  - UI/RNTL: `pnpm jest tests/ui/<file>`
- **Every primitive that responds to taps uses `<PressScale>`** wrapper (defined in J0). Buttons, list items, cards — anything pressable gets the scale-on-press feel by default.
- **Every critical action triggers haptics.** Toggle = `selectionAsync()`, success = `notificationAsync('success')`, error = `notificationAsync('error')`. Not on every micro-tap, but on actions the user invests in (saving a form, completing a tour, etc.).
- **All durations and easings come from `motion-tokens.ts`.** No `ms: 250` or `'ease-in-out'` literal in components.
- **All strings via `t()`.** No FR string in JSX.
- **PNPM only.** `pnpm install`, `pnpm add`, `pnpm dev`, `pnpm test`. No `npm` or `yarn`.

---

## Self-pacing for the user

Phase ETA (rough, with LLM assistance):
- **Phase 0 — Bootstrap:** 1.5–2 days. The longest because everything is from scratch. Many tools to install, palette to design, dev client to build for both platforms.
- **Phase 1 — Persistence + Domain:** 2.5–3 days. Lots of code to port from Dart, but mechanical. The use case tests are the gold standard — they're already designed and battle-tested in the Flutter codebase, we translate them.
- **Phase 2 — Settings + theming:** 1–1.5 days. Concrete UI work, less code than Phase 1, but more interactive verification.

**Total foundations: ~5–7 days of focused work.** After this, the project is ready for J3 (Clients) which gets its own plan document.
