# 8. Tests, qualité, CI

## Stratégie de tests par couche

### Domain layer — priorité haute, couverture quasi-100%

- **Outil:** Vitest (plus rapide que Jest pour du TS pur, pas besoin de l'env RN)
- Use cases purs (`cost-split-calculator`, `bracket-counter`, `tour-duration-estimator`, `find-nearby-clients`, `tour-order-optimizer`) testés exhaustivement
- Cas limites: 0 client, 1 client, exactement à la limite d'un bracket, distances égales, etc.
- **Référence:** les tests Dart existants (`test/domain/`) servent de gold standard — on les traduit en TS

### Data layer (repositories) — couverture moyenne

- **Outil:** Jest + `expo-sqlite` en mémoire (`:memory:`)
- Tests d'intégration: création, lecture, mise à jour, suppression, requêtes filtrées (clients en attente, etc.)
- Vérification que les converters JSON (phones, animal_counts) marchent dans les deux sens
- Pas de mock SQLite — utiliser le vrai driver en mémoire est plus fiable

### Infra layer (services HTTP) — couverture sélective

- **Outil:** Jest + `msw` (Mock Service Worker) pour mocker les réponses HTTP
- Tests pour BAN service: query → résultats parsés correctement, erreurs réseau gérées
- Tests pour ORS service: matrice parsée, fallback haversine si erreur, cache vérifié
- Tests pour Supabase auth/backup: happy path + erreurs majeures

### UI / écrans — couverture sélective, pas exhaustive

- **Outil:** React Native Testing Library + Jest
- Cibles: composants à logique non triviale (formulaires avec validation, command palette, autocomplete)
- **Pas** de test sur chaque écran — coût élevé pour ROI faible
- **Pas** de snapshots (instables, peu utiles)

### E2E — pas en v1

- Maestro reste une option si le besoin émerge plus tard
- Risque sinon: maintenance lourde pour bénéfices marginaux à ce stade

## Qualité statique

- **TypeScript strict:** `strict: true`, `noUncheckedIndexedAccess: true`, `noImplicitOverride: true`
- **ESLint:** preset Expo + `@typescript-eslint` + `eslint-plugin-react-hooks`
- **Prettier:** config par défaut, formatage automatique
- **Pas de Husky / lint-staged au démarrage** — on ajoute si besoin (le pre-commit qui ralentit chaque commit est souvent contre-productif tôt dans un projet)

## CI (GitHub Actions)

- Workflow `ci.yml` sur push: `pnpm install` + `pnpm typecheck` + `pnpm test` + `pnpm lint`
- Pas de build EAS en CI au démarrage (build manuel suffit, quota EAS limité)
- À ajouter quand le repo a une stabilité suffisante — pas en jour 1

## Critères de "feature done"

Pour considérer une feature de la roadmap (cf. §9) comme terminée:

1. ✅ Use cases du domain testés en vitest
2. ✅ Repository testé en intégration SQLite
3. ✅ Écran(s) fonctionnel(s) sur device iOS et Android (pas juste simulator)
4. ✅ Strings via i18next (pas de FR en dur)
5. ✅ Light + dark mode rendus correctement
6. ✅ Pas de warning TS, pas de warning ESLint
7. ✅ Doc minimale dans le PR / commit message: ce qui a changé, ce qui a été redessiné vs Flutter
