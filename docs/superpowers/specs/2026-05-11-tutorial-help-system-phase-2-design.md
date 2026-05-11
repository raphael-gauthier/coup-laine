# Système de tutorial et d'aide — Phase 2

**Date :** 2026-05-11
**Référence TODO :** `#8b — Système de tutorial et d'aide (Phase 2)`
**Spec parente :** `docs/superpowers/specs/2026-05-11-tutorial-help-system-design.md` (Phase 1)
**Statut :** spec validée, prête pour planification

---

## 1. Contexte

Phase 1 a livré l'infrastructure complète (table `tutorial_progress`, hooks, composants `<HelpButton>`/`<HelpSheet>`/`<CoachMark>`, écran Réglages > Aide) + 3 sheets contextuelles (Clients, Tours, Completion) + 2 coach-marks essentiels (`first_client`, `first_tour`).

Phase 2 = **pure addition de contenu** sur cette infra. Pas de schéma, pas de hooks neufs, pas de nouveau composant à concevoir. Une petite extension du catalogue de clés (ajout d'une catégorisation `essential` vs `discovery`) et un store de session pour la politique anti-fatigue.

## 2. Périmètre

### 2.1 Inclus

**Catalogue + politique**
- Extension de `TUTORIAL_KEYS` avec 12 nouvelles clés : 7 sheets + 5 coach-marks (cf §6).
- Catégorisation `essential | discovery` au niveau du catalogue (les 2 coach-marks Phase 1 deviennent `essential`, les 5 nouveaux Phase 2 sont `discovery`).
- Nouveau store de session minimal (`src/ui/help/session-store.ts`) avec un boolean `discoveryFiredThisSession` (pas de DB, pas d'AsyncStorage — module-level mutable state, reset automatique au cold start).
- Modification de `useCoachMark` pour respecter la politique : un coach-mark `discovery` ne fire que si `!discoveryFiredThisSession`. Un `essential` ignore le flag.

**Sheets contextuelles (7 nouvelles)**
- `sheet.map` — onglet Carte
- `sheet.client_detail` — fiche client (vue détail)
- `sheet.tour_detail` — détail d'une tournée (planifiée ou complétée)
- `sheet.services_catalog` — Réglages > Catalogue de prestations
- `sheet.statuses` — Réglages > Statuts
- `sheet.cloud` — Réglages > Cloud
- `sheet.settings` — Réglages > root

**Coach-marks à seuils métier (5 nouveaux)**
| Clé | Écran | Trigger |
| --- | --- | --- |
| `coachmark.cloud_backup` | Clients (FAB ou empty/non-empty state) | `clients.length >= 5 OR completedTours.length >= 1`, ET utilisateur non connecté au cloud (session anonyme), ET pas vu |
| `coachmark.discover_catalog` | Tours (header) | `completedTours.length >= 1` ET pas vu |
| `coachmark.manual_statuses` | Clients (header, à côté du filtre) | `clients.length >= 10` ET pas vu |
| `coachmark.proximity_suggestions` | écran de planification de tournée (TourDraft) | la 2e fois que l'utilisateur ouvre le picker de clients sur une tournée (`completedTours.length + plannedTours.length >= 1`, donc à la création de la 2e tournée) ET pas vu |
| `coachmark.payment_methods` | écran de complétion (header) | la 1re fois qu'un paiement est enregistré sur un stop (DB-level : 1+ ligne `tour_stops.is_paid = 1`) ET pas vu |

**Demos additionnels (3 nouveaux)**
- `service-row-demo.tsx` — utilisée dans `help-sheet-services-catalog.tsx`
- `status-row-demo.tsx` — utilisée dans `help-sheet-statuses.tsx`
- `tour-stop-list-demo.tsx` — utilisée dans `help-sheet-tour-detail.tsx`

Sheets sans demo (text + icônes lucide uniquement) : `sheet.map`, `sheet.client_detail`, `sheet.cloud`, `sheet.settings`.

**Contenu i18n** — environ 80–100 nouvelles clés FR (texte des 7 sheets + titles/bodies des 5 coach-marks).

### 2.2 Non-goals

- Pas de modification de la table `tutorial_progress` ni de bump backup format. Les 12 nouvelles clés s'ajoutent dans le catalogue ; rien à migrer (les anciennes lignes restent valides).
- Pas de modification des composants UI (`<HelpButton>`, `<HelpSheet>`, `<HelpSection>`, `<HelpPreview>`, `<CoachMark>`). On les réutilise tels quels.
- Pas de modification du flux de reset Réglages > Aide & tutoriels (le compteur Y/total montera mécaniquement de 5 à 17 — c'est correct).
- Pas de coach-mark séquentiel (« vois aussi celui-ci → »). Chaque coach-mark reste indépendant.
- Pas de personnalisation utilisateur de la politique anti-fatigue (« je ne veux jamais voir de coach-marks »). Si demandé plus tard, c'est une feature à part.

## 3. Politique anti-fatigue

### 3.1 Catégorisation des clés

Extension du catalogue dans `src/domain/tutorial/keys.ts` :

```ts
export const TUTORIAL_KEYS = { ... } as const;
export type TutorialKey = ...;

export const ESSENTIAL_COACHMARKS: ReadonlySet<TutorialKey> = new Set([
  TUTORIAL_KEYS.coachmarkFirstClient,
  TUTORIAL_KEYS.coachmarkFirstTour,
]);

export function isEssentialCoachmark(key: TutorialKey): boolean {
  return ESSENTIAL_COACHMARKS.has(key);
}
```

Tout coach-mark non listé est implicitement `discovery`.

### 3.2 Session store

Nouveau module `src/ui/help/session-store.ts` :

```ts
let discoveryFiredThisSession = false;

export function markDiscoveryFired(): void {
  discoveryFiredThisSession = true;
}

export function hasDiscoveryFiredThisSession(): boolean {
  return discoveryFiredThisSession;
}
```

Module-level mutable state. **Pas de Zustand, pas de Context, pas de React state** : on n'a pas besoin de re-render, juste d'un flag consulté à la demande dans `useCoachMark`. Reset implicite à chaque cold start (le module est ré-évalué). Resume après backgrounding préserve le flag (même process, même module instance).

### 3.3 Modification de `useCoachMark`

```ts
export function useCoachMark(key: TutorialKey, shouldShow: boolean): CoachMarkController {
  const [locallyDismissed, setLocallyDismissed] = useState(false);
  const hasBeenSeen = useIsTutorialSeen(key);
  const markSeen = useMarkTutorialSeen();

  const isEssential = isEssentialCoachmark(key);
  const sessionGate = isEssential || !hasDiscoveryFiredThisSession();

  const dismiss = useCallback(() => {
    setLocallyDismissed(true);
    if (!hasBeenSeen) markSeen.mutate(key);
  }, [hasBeenSeen, key, markSeen]);

  // Side-effect: when a discovery coach-mark first becomes visible this session,
  // burn the session token so no other discovery coach-mark fires until the next
  // cold start.
  const isVisible = shouldShow && !hasBeenSeen && !locallyDismissed && sessionGate;
  useEffect(() => {
    if (isVisible && !isEssential) {
      markDiscoveryFired();
    }
  }, [isVisible, isEssential]);

  return { isVisible, dismiss };
}
```

**Observation importante** : `markDiscoveryFired()` est appelé quand le coach-mark devient visible (effet de bord), pas quand il est dismissé. Conséquence : si l'user voit le coach-mark cloud puis quitte l'écran sans le dismisser, le flag reste à true → aucun autre `discovery` ne fire dans la session, et le cloud coach-mark restera marqué « pas vu » dans la DB → il revient au prochain lancement. C'est le comportement voulu : on évite la cascade.

### 3.4 Reset

Le bouton « Rejouer les tutoriels » dans Réglages > Aide :
- Vide la table `tutorial_progress` (déjà fait en Phase 1).
- Doit aussi reset `discoveryFiredThisSession = false`. Ajout d'un `resetSessionDiscoveryFlag()` exporté depuis le session store, appelé par `useResetTutorials.onSuccess` (à wirer dans `src/state/queries/tutorial.ts`).

## 4. Catalogue de clés étendu

```ts
export const TUTORIAL_KEYS = {
  // Phase 1 — sheets
  sheetClients:        'sheet.clients',
  sheetTours:          'sheet.tours',
  sheetCompletion:     'sheet.completion',
  // Phase 1 — coach-marks (essential)
  coachmarkFirstClient: 'coachmark.first_client',
  coachmarkFirstTour:   'coachmark.first_tour',

  // Phase 2 — sheets
  sheetMap:                'sheet.map',
  sheetClientDetail:       'sheet.client_detail',
  sheetTourDetail:         'sheet.tour_detail',
  sheetServicesCatalog:    'sheet.services_catalog',
  sheetStatuses:           'sheet.statuses',
  sheetCloud:              'sheet.cloud',
  sheetSettings:           'sheet.settings',
  // Phase 2 — coach-marks (discovery)
  coachmarkCloudBackup:           'coachmark.cloud_backup',
  coachmarkDiscoverCatalog:       'coachmark.discover_catalog',
  coachmarkManualStatuses:        'coachmark.manual_statuses',
  coachmarkProximitySuggestions:  'coachmark.proximity_suggestions',
  coachmarkPaymentMethods:        'coachmark.payment_methods',
} as const;
```

Compteur total dans `app/(tabs)/settings/help.tsx` : `Object.values(TUTORIAL_KEYS).length` → passe automatiquement de 5 à 17. La copie i18n `settings.help.counter` n'a pas à être touchée.

## 5. Triggers détaillés des coach-marks

Pour chaque coach-mark, on précise (a) sur quel écran il vit, (b) quel `shouldShow` predicate, (c) quelle ancre `<View>`.

### 5.1 `coachmark.cloud_backup`

- **Écran :** `app/(tabs)/clients/index.tsx` (déjà host de `coachmark.first_client`)
- **shouldShow :**
  ```ts
  !isLoading && !isError
    && !isCloudOptedIn        // session anonyme
    && (allClients.length >= 5 || completedToursCount >= 1)
  ```
- **Ancre :** une nouvelle `<View ref={cloudCoachmarkAnchorRef} collapsable={false}>` enveloppant le `<HelpButton>` du header — le coach-mark pointe « tape ici pour comprendre la sauvegarde » et la sheet `sheet.cloud` couvre le reste. Alternative : ancrer sur le bouton de `<RecomputeBanner>` ou créer un mini-banner. Décision : ancre sur le `HelpButton` du header (moins intrusif, naturel).
- **Hooks à consommer :** `useSession()` (déjà en place), `useTours('completed')` ou équivalent pour le compte completed.

### 5.2 `coachmark.discover_catalog`

- **Écran :** `app/(tabs)/tours/index.tsx`
- **shouldShow :** `!isLoading && !isError && completedToursCount >= 1`
- **Ancre :** `<HelpButton>` du header Tours (le coach-mark suggère « tape ici pour découvrir le catalogue », la sheet `sheet.services_catalog` explique). Alternative : un bouton dédié sur la TourCard d'une tournée complétée — rejeté car ça multiplie les surfaces.
- **Hooks :** `useTours('completed')` pour le compte.

### 5.3 `coachmark.manual_statuses`

- **Écran :** `app/(tabs)/clients/index.tsx`
- **shouldShow :** `!isLoading && !isError && allClients.length >= 10`
- **Ancre :** le `<ClientFilterButton />` (existant dans le rightSlot du header) — coach-mark « tu peux filtrer et créer tes propres statuts ». La sheet `sheet.statuses` détaille.
- **Conflit potentiel avec `coachmark.cloud_backup` (même écran) :** si le user a 10+ clients ET pas connecté cloud, les deux sont éligibles. Ordre : `cloud_backup` prioritaire (la sauvegarde est plus critique que la qualification). Implémentation : on ne calcule `manual_statuses` que si `!cloud_backup_visible` — concrètement, on chaîne les `useCoachMark` et le 2e prend en compte le `isVisible` du 1er via une variable locale. Pattern :
  ```ts
  const cloudCoach = useCoachMark(KEYS.cloud_backup, cloudPredicate);
  const statusesCoach = useCoachMark(KEYS.manual_statuses, statusesPredicate && !cloudCoach.isVisible);
  ```

### 5.4 `coachmark.proximity_suggestions`

- **Écran :** la sheet/screen de création de tournée (`<TourDraftScreen>` ou équivalent — à confirmer en lecture). C'est l'écran qui contient `<WaitingClientsMultiPicker>` avec les sections « Suggérés à proximité » / « Autres clients en attente ».
- **shouldShow :** `tours.length >= 1` (au moment où le user crée sa 2e tournée). Détectable via `useTours('all')` au montage.
- **Ancre :** la section header « Suggérés à proximité » du picker. Si la section est masquée parce que vide, on n'affiche pas le coach-mark (pas pertinent). Predicate complémentaire : `nearbyClients.length > 0`.

### 5.5 `coachmark.payment_methods`

- **Écran :** `app/(tabs)/tours/[id]/complete.tsx`
- **shouldShow :** `!isLoading && hasAnyPaidStop` où `hasAnyPaidStop` = la 1re tournée à entrer en complétion contient au moins 1 stop avec `isPaid = 1` enregistré (data-level — interroge `tour_stops.is_paid` côté DB pour savoir si l'user a déjà enregistré au moins 1 paiement, n'importe où).
- **Ancre :** la zone de saisie du paiement sur le 1er stop affiché à l'écran de complétion. Si l'écran présente plusieurs stops et que le 1er n'a pas de paiement encore, ancrer sur le bouton d'ouverture de la sheet de paiement.
- **Pourquoi ce trigger un peu spécial :** on veut introduire l'idée des « modes de paiement personnalisés » au moment où le user enregistre son 1er paiement, pas avant (sinon ça ne signifie rien).
- **Implémentation :** nouveau hook `useHasAnyPaidStop()` dans `src/state/queries/tours.ts` qui exécute un `SELECT 1 FROM tour_stops WHERE is_paid = 1 LIMIT 1` (cheap).

## 6. Contenu i18n (volume estimé)

7 sheets × ~10 clés (title + 4-5 sections + captions éventuelles) = ~70 clés.
5 coach-marks × 2 clés (title + body) = 10 clés.
+ quelques clés transverses (placeholder, etc.) = ~5 clés.

**Total Phase 2 : ~85 clés FR.**

Le contenu textuel exact sera produit à l'implémentation, en suivant le ton et la longueur des sheets Phase 1 (paragraphes courts, ton informel à la 2e personne du singulier, vocabulaire métier tondeur ovin). Le plan d'implémentation détaillera le contenu de chaque sheet.

## 7. Tests

Pas de schéma, pas de logique métier complexe — la couverture automatique est limitée :

- **Domain :** test que `isEssentialCoachmark` renvoie `true` pour les 2 essentiels Phase 1 et `false` pour les 5 nouveaux discovery (1 test vitest avec assertions sur chaque clé).
- **Session store :** 3 tests vitest — flag commence à false, `markDiscoveryFired()` le passe à true, `resetSessionDiscoveryFlag()` le repasse à false.
- **`useCoachMark` policy** : pas de test unitaire (mocker React Query + le module-level state pour zéro valeur ajoutée). Validation via dev client.
- **Validation manuelle dev client :** déroulement explicite des 5 triggers (créer 5 clients → ouvrir Clients → vérifier coach-mark cloud_backup ; etc.), plus la vérification que la politique 1/session marche (créer 5 clients → voir cloud_backup → naviguer Tours avec 1 tournée complétée → discover_catalog NE DOIT PAS apparaître), plus la vérification du reset.

## 8. Risques et points ouverts

### 8.1 Risques

- **Effet "Module mutable state" en hot reload** : pendant le développement, un Fast Refresh peut ne pas reset le flag `discoveryFiredThisSession`. C'est OK parce que c'est le comportement voulu en prod (resume après bg ne reset pas). En dev on peut forcer reset via le bouton Réglages.
- **Couplage `useCoachMark` × side-effect `markDiscoveryFired`** : le hook devient impur (side-effect via `useEffect`). Ce n'est pas idéal mais reste contenu et explicite. Alternative rejetée : un controller global qui orchestre les coach-marks (over-engineering pour 7 instances).
- **Détection de `hasAnyPaidStop`** : un nouveau hook qui interroge la DB. Risque de re-render inutile sur chaque mount de l'écran completion. Mitigation : React Query cache infinite jusqu'à invalidation manuelle (au save d'un paiement).
- **Cascade de coach-marks lors d'un reset** : si l'utilisateur clique « Rejouer », la session est reset (§3.4), donc le 1er coach-mark `discovery` éligible refire. C'est le comportement voulu (le user a explicitement demandé à revoir les tutos).

### 8.2 Points ouverts non bloquants pour le plan

- Le contenu textuel exact des 7 sheets (ton, longueur de chaque section). À itérer au moment du draft FR.
- Position visuelle exacte du coach-mark `payment_methods` dans l'écran de complétion (sur le 1er stop, sur le bouton d'ouverture, etc.) — décision tactique à l'impl.

## 9. Critères d'acceptation

1. Tests automatisés Phase 1 + nouveaux tests Phase 2 (~4 tests) verts.
2. `pnpm typecheck` + `pnpm lint` PASS.
3. Validation manuelle des 5 triggers et de la politique anti-fatigue 1/session sur dev client.
4. 7 sheets s'ouvrent avec leur `<HelpButton>` dans le header de leur écran respectif. La pastille "non vue" disparaît à l'ouverture.
5. Bouton « Rejouer les tutoriels » dans Réglages > Aide : reset DB **et** reset flag session — les coach-marks discovery refirent dans la même session après reset.
6. Compteur dans Réglages > Aide passe à `X tutoriels vus sur 17`.
