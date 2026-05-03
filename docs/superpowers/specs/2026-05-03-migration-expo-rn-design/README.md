# Migration Expo + React Native — Design

> Réécriture de l'app `coup_laine` (Flutter, Android-only) vers Expo + React Native (iOS + Android), avec parité fonctionnelle et liberté de redesign UI/UX.

Ce spec est découpé en documents ciblés. Lire dans l'ordre.

| # | Document | Contenu |
|---|---|---|
| 1 | [Vision & scope](./01-vision-scope.md) | Objectif, ce qu'on garde, ce qui change, critères de succès |
| 2 | [Stack](./02-stack.md) | Choix techniques détaillés (RN, Expo, Drizzle, NativeWind, etc.) |
| 3 | [Architecture](./03-architecture.md) | Couches, organisation du code, règles de dépendance |
| 4 | [Persistance](./04-persistence.md) | Schéma Drizzle, migrations, conventions SQLite |
| 5 | [Services externes](./05-services-externes.md) | MapLibre, BAN, ORS, Supabase auth/backups |
| 6 | [Theming & i18n](./06-theming-i18n.md) | Palette Modern Craft light + dark, switch, i18next |
| 7 | [Cloud, deep links & build](./07-cloud-build-distribution.md) | Magic-link, EAS profiles, distribution iOS/Android |
| 8 | [Tests & qualité](./08-tests-qualite.md) | Stratégie par couche, qualité statique, CI |
| 9 | [Worktree & roadmap](./09-worktree-roadmap.md) | Setup git worktree, jalons de build détaillés |
| 10 | [Risques & inconnus](./10-risques-inconnus.md) | Risques techniques, risques produit, décisions différées |
| 11 | [UX, esthétique & motion](./11-ux-motion.md) | **Priorité de premier rang.** Principes UX, motion patterns, librairies, critères "done" augmentés |

## Conventions

- **Langue spec:** français (cohérent avec la conversation de design et l'UI app)
- **Langue code et identifiants:** anglais (convention standard)
- **Plateformes cibles:** iOS + Android dès le départ
- **Aujourd'hui:** 2026-05-03. Auteur: Raphaël Gauthier.
- **Branche dédiée:** `rn-migration` dans worktree `../coupe-laine-rn`
- **Référence métier:** ce spec hérite des règles métier de [`2026-04-28-coupe-laine-mvp-design/`](../2026-04-28-coupe-laine-mvp-design/). En cas de divergence, le spec MVP fait foi sur le métier ; ce spec fait foi sur la stack et l'organisation.
