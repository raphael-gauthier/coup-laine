# 2. Stack

| Concern | Choix | Notes |
|---|---|---|
| Runtime | **Expo SDK 53+** (latest stable) | Dev client custom (pas Expo Go vu MapLibre + SQLite natif) |
| Langage | **TypeScript strict** | `"strict": true`, `noUncheckedIndexedAccess: true` |
| Routing | **Expo Router (file-based)** | Tabs + stacks via convention de fichiers |
| UI primitives | **NativeWind v4 + react-native-reusables** | Composants shadcn-like éditables, classes Tailwind |
| Theming | **Tokens Modern Craft** (light + dark) en `tailwind.config.js` | Switch utilisateur 3-positions Système / Clair / Sombre |
| Icons | **lucide-react-native** | Cohérent avec écosystème shadcn |
| State UI | **Zustand** | Stores par domaine (tour-draft, filters, settings) |
| State serveur/async | **TanStack Query (React Query)** | Cache, invalidation, optimistic updates |
| Forms | **react-hook-form + zod** | Validation typée |
| DB locale | **expo-sqlite + Drizzle ORM** | Schéma TS, migrations via drizzle-kit |
| HTTP | **fetch natif** (BAN) + **@supabase/supabase-js** (auth, backup, ORS proxy) | Pas d'axios |
| Map | **@maplibre/maplibre-react-native** | Tuiles vectorielles via MapTiler free tier |
| Routing (chemins) | **OpenRouteService** via Edge Function Supabase existante | Inchangé |
| Geocoding | **API Adresse (BAN)** appel direct fetch | Inchangé |
| Auth | **Supabase Auth** magic-link | Réutilise projet existant |
| Backup | **Supabase Storage** + endpoints existants | Snapshots JSON versionnés |
| i18n | **i18next + react-i18next + expo-localization** | Français only en v1, infra prête |
| Dates | **date-fns** + locale `fr` | Pas de moment.js |
| Build & dist | **EAS Build** (iOS + Android) + **EAS Update** (OTA JS-only) | Profils dev / preview / prod |
| Tests | **Vitest** (domain) + **Jest** (data/infra) + **React Native Testing Library** (UI) | Maestro pour E2E plus tard si besoin |
| Lint/format | **ESLint + Prettier** (preset Expo) | Config par défaut au démarrage |
| Secrets | **Expo Constants + EAS secrets** | `.env` local pour dev |
| Package manager | **pnpm** | Perf, disk efficiency |

## Coûts à anticiper

- **Apple Developer Program:** $99/an. Requis pour TestFlight + device physique iOS. Pas requis pour simulator.
- **Google Play Console:** $25 one-time.
- **EAS Build free tier:** 30 builds/mois (suffit pour le dev). Au-delà → plan Expo (~$19/mois).
- **MapTiler free tier:** 100k tile requests/mois (largement suffisant pour l'usage).
- **Supabase free tier:** déjà utilisé, inchangé.

## Plans B documentés (pas en setup initial)

- **Tuiles vectorielles auto-hébergées** si on dépasse MapTiler free tier → `.pmtiles` (protomaps) sur Supabase Storage ou bucket S3.
- **OTP code à 6 chiffres** au lieu de magic-link si deep link bloque.
- **react-native-maps + UrlTile OSM** si MapLibre pose des problèmes de setup Expo.
