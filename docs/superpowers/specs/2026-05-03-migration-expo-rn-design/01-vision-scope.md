# 1. Vision & scope

## Objectif

Réécrire `coup_laine` (Flutter/Android) en application **Expo + React Native** avec **parité fonctionnelle de services** et **liberté de redesign UI/flux**. Travail dans un **worktree git séparé** sur la même base de repo.

Aucun utilisateur actuel ⇒ aucune contrainte de migration de données ni de cohabitation longue.

## Motivations

- **Écosystème JS/RN plus riche** que Flutter sur certains plans (UI libs, AI tooling, intégrations cloud)
- **Plus facilement vibe-codable** par LLMs (corpus TS/RN énorme, conventions stables)
- **Design plus souple** (NativeWind = Tailwind, composants éditables, tuiles vectorielles stylables)
- **iOS dès le départ** sans pipeline build à monter à la main

## Ce qu'on garde

- Le **domaine métier** entier (clients, tournées, proximité, calcul de split €8/10km, optimisation d'ordre, last-shorn date, espèces/prestations, base/domicile)
- Les **specs existants** (`docs/superpowers/specs/2026-04-28-coupe-laine-mvp-design/`) comme source de vérité métier
- L'**infra Supabase** (auth magic-link, edge function ORS proxy, schéma backup) telle quelle
- Le **template email** Modern Craft récemment finalisé (commit `f817232`)
- L'**API BAN** (autocomplete + geocoding) en appel direct depuis le client
- L'**API ORS** via le proxy edge function existant

## Ce qui change

| Domaine | Avant (Flutter) | Après (RN) |
|---|---|---|
| Plateformes | Android-only | **iOS + Android** dès le départ |
| Langage | Dart | **TypeScript strict** |
| Framework | Flutter | **Expo SDK 53+** |
| Routing app | `go_router` | **Expo Router** (file-based) |
| State mgmt | Riverpod | **Zustand** + **TanStack Query** |
| DB locale | Drift (SQLite typé) | **Drizzle ORM + expo-sqlite** |
| UI | Forui (kit prêt à l'emploi) | **NativeWind + react-native-reusables** (composants éditables) |
| Carte | `flutter_map` raster OSM | **MapLibre** vectoriel stylable |
| Forms | Formulaires Flutter custom | **react-hook-form + zod** |
| i18n | ARB files + codegen | **i18next** + JSON |
| Build | Gradle local | **EAS Build** (iOS + Android) |
| Theming | Light only | **Light + dark + switch utilisateur** |

## Critères de succès

1. App buildée et installable iOS + Android via EAS
2. Toutes les fonctionnalités de la version Flutter présentes (les 6 du core loop + onboarding + cloud + catalogues custom + historique)
3. Domain layer testé unitairement avec couverture équivalente ou meilleure (use cases purs en TS, triviaux à tester)
4. Code lisible et editable par un LLM sans contexte préalable lourd
5. Light + dark mode rendus correctement sur tous les écrans
6. Toutes les strings UI passent par i18next (pas de FR en dur)

## Hors scope explicite

- **Pas** de migration de données depuis l'app Flutter (personne ne l'utilise)
- **Pas** de Web pour l'instant (mais stack compatible si on le veut plus tard)
- **Pas** de sync temps-réel multi-device (on garde le backup/restore manuel)
- **Pas** d'optim multi-jours / tournée hebdomadaire (pas dans la version Flutter actuelle)
- **Pas** de notifications push
- **Pas** d'invoice generation
