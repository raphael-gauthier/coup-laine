# 5. Services externes

## MapLibre — config & tuiles

- **Lib:** `@maplibre/maplibre-react-native`
- **Config plugin Expo** dans `app.json` (permissions location iOS + SDK natif Android)
- **Build:** dev client custom obligatoire (pas Expo Go) → `npx expo prebuild` une fois, puis `eas build --profile development`
- **Style de tuiles:** MapTiler "OpenStreetMap" en HTTPS, clé API en `MAPTILER_API_KEY`
- **Plan B documenté:** si dépassement free tier ou auto-hébergement souhaité → fichier `.pmtiles` (protomaps) sur Supabase Storage ou bucket S3. Pas en setup initial.

### Composants carte à construire

- `<Map />` wrapper qui encapsule MapLibre, expose props (center, zoom, onPress)
- `<ClientPin />` marker stylisé selon état (waiting, recently shorn, base)
- `<ProximityCircle />` cercle de rayon autour d'un pivot (GeoJSON layer)
- `<TourRouteLayer />` polyline depuis ORS directions API (GeoJSON LineString)

### Performance avec 200 pins

Utiliser des **markers natifs MapLibre** (SymbolLayer GeoJSON) plutôt que des composants RN custom. Les pins stylés par data-driven styling pour éviter de monter 200 composants RN à l'écran.

## BAN (geocoding + autocomplete)

- **API:** `https://api-adresse.data.gouv.fr/search?q=...&autocomplete=1&limit=5`
- **Pas d'auth** (public, gratuit, sans clé)
- **Appel direct depuis l'app** via `fetch`, pas de proxy
- **Service:** `src/infra/services/ban-geocoding.ts` expose `searchAddresses(query)` → `Promise<BanResult[]>`
- **Composant:** `<AddressAutocompleteInput />` avec debounce 300ms + dropdown de suggestions (basé sur primitive `Combobox` de react-native-reusables)

## ORS (matrices + directions)

- **API:** déjà proxiée via une **Edge Function Supabase existante** (clé ORS cachée côté serveur)
- **Service côté RN:** `src/infra/services/ors-routing.ts` expose:
  - `getDistanceMatrix(coords[])` → matrice km + minutes
  - `getRouteGeometry(coords[])` → GeoJSON LineString
- **Cache local:** paires `(from, to)` stockées dans `distance_matrix`. Avant un appel ORS, on vérifie le cache. Entrée plus ancienne que TTL → re-fetch (config `distance_matrix_ttl_days`, default 90).
- **Resilience:** timeout 10s, retry 1 fois, fallback sur distance haversine (vol d'oiseau) avec flag `is_estimate: true` si ORS échoue. UX: badge "estimation" sur les écrans concernés.

### Inconnue à lever

Le contrat exact de l'edge function ORS (signature requêtes/réponses) doit être extrait depuis `lib/infra/services/ors_routing_service.dart` côté Flutter avant le Jalon 7. Si le contrat est trop spécifique au format Drift, on amende l'edge function (sous notre contrôle).

## Auth Supabase + Cloud backups

- **Auth:** `@supabase/supabase-js` configuré avec storage adapter custom utilisant `expo-secure-store`
- **Magic-link:** flow `signInWithOtp({ email, options: { emailRedirectTo: 'coupelaine://auth/callback' } })` → email contient un deep link vers l'app
- **Backup/restore:** `src/infra/cloud/backups.ts` réutilise les endpoints existants
  - `createBackup()` → snapshot JSON de toutes les tables Drizzle → upload Supabase Storage
  - `listBackups()` → liste des snapshots du user
  - `restoreBackup(id)` → wipe DB locale + import du snapshot
- **Schéma de snapshot** versionné: `{ schemaVersion: 1, tables: { clients: [...], ... } }` pour pouvoir migrer les anciens snapshots si on change le schéma local plus tard.

## Variables d'environnement

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
MAPTILER_API_KEY=...
ORS_BASE_URL=https://<project>.supabase.co/functions/v1/ors-proxy
```

Stockées en `app.config.ts` via `process.env`, exposées à l'app via `Constants.expoConfig.extra`. Pour les builds EAS: déclarées en **EAS secrets** (`eas secret:create`).
