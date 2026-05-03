# 10. Risques & inconnus

## Risques techniques

### R1 — MapLibre + Expo: friction de setup

- **Risque:** le config plugin MapLibre peut avoir des incompatibilités avec la version d'Expo SDK choisie. C'est arrivé historiquement.
- **Mitigation:** on valide MapLibre **dès le Jalon 0** (un écran de hello-map dans le bootstrap, pas seulement quand on arrive au Jalon 4). Si bug bloquant: bascule vers `react-native-maps` + tile overlay OSM.
- **Coût du fallback:** perte de la stylabilité vectorielle. Acceptable.

### R2 — Deep link magic-link

- **Risque:** configuration scheme + Supabase email template + Universal Links (iOS) historiquement source de bugs subtils. Le clic email peut ouvrir Safari au lieu de l'app si mal configuré.
- **Mitigation:** tester le flow magic-link de bout en bout au Jalon 11, sur les deux plateformes, sur **device physique** (le simulator iOS gère mal certains deep links).
- **Plan B si bloqué:** OTP code à 6 chiffres au lieu de magic-link (Supabase le supporte nativement). UX moins fluide mais 100% fiable.

### R3 — Drizzle + expo-sqlite migrations

- **Risque:** les migrations Drizzle sur expo-sqlite ont eu des cas chelous historiquement (ALTER TABLE limité par SQLite).
- **Mitigation:** schéma figé en Jalon 1 avant les features. Toute modification ultérieure passe par migration générée par drizzle-kit + testée sur DB réelle (avec données seedées) avant merge.
- **Note:** zéro utilisateur — un drop+recreate complet est toujours possible en dernier recours.

### R4 — ORS edge function existante: contrat d'API

- **Inconnue:** le contrat (signature des requêtes/réponses) doit matcher ce que le client RN envoie. Pas inspecté pendant le brainstorm.
- **Mitigation:** lire `lib/infra/services/ors_routing_service.dart` côté Flutter pour extraire le contrat exact, et l'implémenter à l'identique en TS au Jalon 7. Si l'edge function s'avère trop spécifique au format Drift, on peut l'amender (sous notre contrôle).

### R5 — Performance MapLibre avec 200 pins

- **Risque:** MapLibre est très perf en général, mais 200 pins en composants RN custom peut ramer.
- **Mitigation:** utiliser des **markers natifs MapLibre** (SymbolLayer GeoJSON) plutôt que des composants RN custom. Pins stylés par data-driven styling.

### R6 — EAS Build quota / coût

- **Risque:** 30 builds/mois free, mais on en fera plus pendant le dev intensif (chaque dépendance native = nouveau dev client à builder).
- **Mitigation:** limiter les changements de deps natives, builder le dev client une fois et le réutiliser tant que possible. Si quota dépassé: plan Expo payant temporaire (~$19/mois) le temps de finir le projet.

## Risques produit

### R7 — Glissement de scope via "redesign"

- **Risque:** "liberté de redesign" peut devenir un puits sans fond.
- **Mitigation:** règle de discipline — on **commence par reproduire** le flux actuel (les specs existants) ; on ne redesigne que là où on identifie un problème **concret** pendant le build. Pas de redesign spéculatif.

### R8 — Livrer des features visuellement plates

- **Risque:** la pression de livrer des features fonctionnelles peut faire couper sur l'UX (motion, empty states, micro-interactions). Résultat: une app "qui marche" mais qui ne ressent pas comme un produit fini, et qu'on doit retravailler ensuite.
- **Mitigation:** critères "feature done" augmentés (cf. §8 et §11) bloquants à chaque PR. Si un compromis vélocité/UX se présente: **on coupe une feature secondaire**, on ne dégrade pas l'UX d'une feature livrée.
- **Mitigation #2:** motion setup en Jalon 0 (tokens, primitives, presets) pour que la motion devienne mécanique sur les jalons suivants, pas une charge cognitive supplémentaire à chaque écran.

### R9 — Performance motion sur device bas/milieu de gamme

- **Risque:** Reanimated worklets bien faits = 60 FPS. Mauvaise utilisation (animations sur le thread JS, layout shifts non animés, re-renders non maîtrisés) = saccades visibles.
- **Mitigation:** test régulier sur **device physique milieu de gamme** dès le Jalon 3, pas seulement à la fin. Si une animation pose problème de perf: la simplifier ou la supprimer, pas la dégrader.

## Inconnues à lever avant ou pendant le travail

### I1 — Modern Craft palette: extraction & déclinaison dark

- Extraire la palette light depuis `lib/core/theme/app_color_scheme.dart` et **concevoir** la déclinaison dark. Choix créatif.
- **Action:** Jalon 0, validation visuelle avant d'aller plus loin.

### I2 — Assets (icônes, illustrations)

- `assets/illustrations/` et `assets/icons/` du projet Flutter — sont-ils tous adaptés à un usage RN (formats SVG / PNG haute résolution) ?
- **Action:** audit au Jalon 0, conversion si nécessaire.

### I3 — Données de test / seeds

- Les seeds dans `lib/data/seeds/` côté Flutter sont à porter pour bootstrap les tests RN.
- **Action:** relire `lib/data/seeds/` et `test/` Flutter au Jalon 1.

### I4 — Email template Supabase

- Template Modern Craft (commit `f817232`) doit pointer vers `coupelaine://auth/callback` (pas une URL web).
- **Action:** check dashboard Supabase à n'importe quel moment, pas un blocker, à régler avant Jalon 11.

## Décisions différées

- **Sync temps-réel multi-device:** repoussé. Refonte schéma backend ciblée si besoin émerge.
- **Web build:** repoussé. Stack le permet mais hors scope v1.
- **Optimisation tournée multi-jours:** repoussé. Pas dans la version Flutter actuelle.
- **Notifications push:** repoussé. Pas dans la version Flutter actuelle.
- **Tests E2E (Maestro):** repoussé. À envisager si bugs récurrents en intégration.
- **Husky / lint-staged:** repoussé. À envisager si la discipline lint slip.
