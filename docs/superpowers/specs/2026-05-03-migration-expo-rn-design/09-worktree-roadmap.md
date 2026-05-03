# 9. Worktree git & roadmap de build

## Setup worktree

**Position:** `C:\Users\rapha\Documents\Development\coupe-laine-rn\` (dossier soeur du repo Flutter)

**Branche dédiée:** `rn-migration` dans le même repo git que `main`

### Commandes de bootstrap (une seule fois)

```powershell
# Depuis le repo principal
git tag flutter-final-v0.7.0       # marqueur sur le dernier commit Flutter
git branch rn-migration main
git worktree add ../coupe-laine-rn rn-migration

# Dans le worktree
cd ../coupe-laine-rn
# Le code Flutter est encore présent ici (même contenu que main au moment du worktree).
# On le supprime dans le premier commit de la branche rn-migration.
```

### Layout retenu

- On **supprime** le code Flutter du worktree (`lib/`, `android/`, `pubspec.yaml`, `build/`, etc.)
- On bâtit le projet Expo **à la racine** du worktree
- **Conservés:** `docs/superpowers/specs/`, `docs/superpowers/plans/`, `CLAUDE.md`, ce nouveau spec
- `CLAUDE.md` sera étendu avec une section "Stack RN" au fur et à mesure

### Pourquoi à la racine plutôt qu'`apps/mobile/`

- Pas de cohabitation longue prévue
- À la fin, quand on mergue `rn-migration` dans `main`, l'app RN est à la racine — plus simple
- Le code Flutter reste accessible via `git checkout flutter-final-v0.7.0` ou `git log` si besoin de relire

## Roadmap de build (jalons à respecter dans l'ordre)

### Jalon 0 — Bootstrap & infra (1 PR)

1. Créer worktree, supprimer Flutter, init projet Expo TypeScript
2. Configurer NativeWind + tokens Modern Craft (light + dark)
3. Configurer Expo Router avec layout racine (providers Theme, QueryClient, i18n)
4. Configurer Drizzle + expo-sqlite, schéma vide migrable
5. Configurer Supabase client + secure-store
6. Configurer EAS profiles (development / preview / production)
7. Setup tests Vitest + Jest + RNTL, CI GitHub Actions minimal
8. **Verify:** `npx expo start --dev-client` ouvre une page d'accueil "Hello", dark mode toggle marche, MapLibre rend une carte test, `pnpm test` passe

### Jalon 1 — Persistance & domain (1 PR)

1. Implémenter le schéma Drizzle complet (toutes les tables de §4)
2. Migration initiale + seeds (espèces standard, prestations défaut)
3. Repositories: clients, tours, tour_stops, prestations, species, animal_categories, manual_history, distance_matrix, settings
4. Use cases purs portés depuis Dart: bracket-counter, cost-split-calculator, tour-duration-estimator, find-nearby-clients, find-clients-near-anchors, tour-order-optimizer, build-tour-draft, build-optimized-tour-proposal, client-status, find-communes-with-waiting
5. Tests vitest pour use cases + tests jest intégration pour repos
6. **Verify:** suite de tests passe, scripts de seed fonctionnent

### Jalon 2 — Settings minimal & theming complet (1 PR)

1. Écran Settings racine
2. Sous-écran "Apparence" avec toggle 3-positions thème, persisté en DB
3. Sous-écran "Domicile / Base" avec form (adresse via BAN, géocodage, sauvegardé en settings)
4. **Verify:** thème change instantanément, base persistée entre redémarrages

### Jalon 3 — Clients (2 PR)

1. Service BAN geocoding + composant `<AddressAutocompleteInput>`
2. Liste clients (filtres: tous / en attente, recherche full-text avec normalisation)
3. Détail client (toutes les infos, last-shorn, animal counts, notes, phones)
4. Form création / édition client
5. Toggle "en attente" rapide depuis la liste
6. **Verify:** parcours CRUD complet sur device iOS et Android

### Jalon 4 — Map (1 PR)

1. Wrapper `<Map>` MapLibre + config plugin
2. Écran Map global montrant tous les clients avec pins colorés par état
3. Tap sur pin → popup avec détails + lien vers détail client
4. Centrage initial sur la base/domicile
5. **Verify:** carte rend bien iOS + Android, performance OK avec 200 pins

### Jalon 5 — Proximité (1 PR)

1. Écran Proximité: sélection pivot, slider rayon, vue liste + vue carte
2. Cercle de rayon dessiné sur la carte
3. Use case `find-nearby-clients` câblé
4. **Verify:** sélection d'un pivot → liste cohérente avec rayon

### Jalon 6 — Tournées manuelles (2 PR)

1. Liste des tournées (draft / planned / completed)
2. Création tournée draft: pick clients (depuis proximité ou liste), ordre manuel drag-and-drop
3. Détail tournée: timeline avec horaires, prestations par stop, total km/temps/€
4. Calcul split en live via use cases (distances haversine en attendant ORS — flag "estimation" affiché)
5. Écran clôture tournée (mark completed → met à jour last_shorn, vide is_waiting)
6. **Verify:** scénario complet bout-en-bout: créer 3 clients → marquer en attente → créer tournée → ordonner → clôturer → vérifier dates

**Note:** ce jalon précède l'intégration ORS (Jalon 7). Les distances utilisées pour le split sont haversine (vol d'oiseau), avec un badge "estimation" UI. Au Jalon 7 les vraies distances routières remplacent les estimations.

### Jalon 7 — ORS routing & optim auto (1 PR)

1. Service ORS via edge function Supabase
2. Cache `distance_matrix` avec TTL
3. Fallback haversine si erreur
4. Écran "tournée optimisée": choisir clients → fetch matrice → use case `tour-order-optimizer` → preview ordre suggéré → accepter/modifier
5. Polyline ORS sur la vue détail tournée
6. **Verify:** matrice bien cachée (pas de double appel), optim donne un ordre cohérent

### Jalon 8 — Catalogues custom (1 PR)

1. Écrans Settings: gestion espèces, animal_categories, prestations
2. Form création / édition / réorganisation
3. **Verify:** ajout d'une espèce custom apparaît bien dans les pickers de client

### Jalon 9 — Historique client (1 PR)

1. Écran historique (tournées passées + manual entries fusionnés, tri chronologique)
2. Form ajout manuel d'une entrée d'historique (date, prestations, notes)
3. **Verify:** historique cohérent et complet

### Jalon 10 — Onboarding (1 PR)

1. Détection premier lancement (settings vide)
2. Flow guidé: bienvenue → saisie base/domicile → premiers clients (optionnel) → terminé
3. **Verify:** fresh install passe par onboarding ; install existant ne le revoit pas

### Jalon 11 — Cloud (1 PR)

1. Écran login magic-link
2. Deep link callback Supabase → setSession
3. Écran Settings → Sauvegardes cloud (liste + créer + restaurer)
4. **Verify:** login complet sur device, sauvegarde + restauration roundtrip OK

### Jalon 12 — Polish & release (1 PR)

1. Splash screen + app icon (réutiliser les assets du repo Flutter si possibles)
2. Animations transitions, haptics sur actions importantes
3. Audit accessibility (labels VoiceOver / TalkBack)
4. Audit performance (200 clients, 50 tournées simulées)
5. Build production EAS, upload TestFlight + Play Console Internal
6. **Verify:** app prête à être testée par utilisateurs réels

## Estimation grossière

À titre indicatif (avec assistance LLM, solo dev): **6 à 10 semaines** de travail effectif pour atteindre le jalon 12. Le bootstrap (J0-J2) prend ~1 semaine, ensuite chaque jalon feature 2-5 jours.
