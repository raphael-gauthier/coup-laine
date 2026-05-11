# Système de tutorial et d'aide — Phase 1 (MVP)

**Date :** 2026-05-11
**Référence TODO :** `#8 — Système de tutorial et d'aide`
**Statut :** spec validée, prête pour planification
**Phase 2 :** suivi dans `TODO.md` après merge de la Phase 1

---

## 1. Contexte et objectif

L'app a un onboarding initial (welcome → profession → base → species → services → recap) qui couvre la configuration de départ, mais une fois cet onboarding terminé l'utilisateur arrive sur l'écran Clients vide sans guidage. Beaucoup de fonctionnalités (catalogue de prestations, statuts manuels, sauvegarde cloud, suggestions à proximité) restent invisibles tant que l'utilisateur ne les cherche pas.

L'objectif est de mettre en place un **système d'aide à deux mécanismes** :

1. **Sheets contextuelles à la demande** — une icône `?` discrète dans le header de chaque écran principal ouvre une bottom sheet qui explique l'écran courant. L'utilisateur consulte quand il veut.
2. **Coach-marks de première fois** — un tooltip non-bloquant qui apparaît la première fois qu'un écran clé est ouvert avec une condition métier (ex. liste clients vide), pointe le CTA principal, et ne réapparaît plus une fois fermé.

Cette spec couvre la **Phase 1 — MVP**. Elle pose toute l'infrastructure (table, hooks, composants UI réutilisables, écran Réglages) et l'utilise pour 3 sheets et 2 coach-marks. La Phase 2 (~7 sheets et ~5 coach-marks supplémentaires) est une simple addition de contenu sur l'infra existante, suivie séparément.

## 2. Périmètre

### 2.1 Inclus dans la Phase 1

**Infrastructure :**
- Nouvelle table Drizzle `tutorial_progress` avec migration hand-written `0010_tutorial_progress.sql`.
- Bump du backup format v5 → v6 avec migration symétrique côté restore.
- Repository `TutorialProgressRepository` (`list`, `isSeen`, `markSeen`, `resetAll`).
- Hooks React Query (`useTutorialProgress`, `useIsTutorialSeen`, `useMarkTutorialSeen`, `useResetTutorials`).
- Hooks de plus haut niveau (`useHelpSheet`, `useCoachMark`).
- Composants UI : `<HelpButton>`, `<HelpSheet>` + sous-composants (`<HelpSection>`, `<HelpScreenshot>`), `<CoachMark>`.

**Écran Réglages :**
- Nouvelle entrée « Aide & tutoriels » dans Réglages.
- Nouvel écran `app/(tabs)/settings/help.tsx` avec compteur « X tutoriels vus sur Y » et bouton « Rejouer les tutoriels ».

**Contenu Phase 1 :**
- 3 sheets contextuelles : `sheet.clients`, `sheet.tours`, `sheet.completion`.
- 2 coach-marks 1re fois : `coachmark.first_client`, `coachmark.first_tour`.
- ~46 clés i18n (FR — l'app est FR-only, pas de fichier `en.json` à maintenir).
- 5 composants **previews in-app** (copies visuellement fidèles, sans données réelles) : `ClientCardDemo`, `ClientFilterDemo`, `TourCardDemo`, `TourPlanningDemo`, `CompletionRowDemo`. Pas de captures `.webp` (pivot post-design — voir §6.2).

### 2.2 Phase 2 — non couverte ici, suivie dans le TODO

- 7 sheets restantes : Carte, Fiche client, Détail tournée, Catalogue de prestations, Statuts, Cloud, Paramètres root.
- 5 coach-marks à seuils métier :
  - Sauvegarde cloud (déclencheur : 5+ clients OU 1re tournée complétée).
  - Découverte catalogue (après 1re tournée créée).
  - Statuts manuels (10+ clients).
  - Suggestions à proximité (à la 2e tournée).
  - Payment methods personnalisés (au 1er bilan avec paiement enregistré).

### 2.3 Non-goals explicites

- Pas d'écran d'aide centralisé. Les sheets contextuelles couvrent le besoin.
- Pas de GIF / vidéo. Texte + captures statiques uniquement.
- Pas de télémétrie « tuto vu / ignoré » (à reprendre si on déploie Sentry/PostHog plus tard).
- Pas de tutoriel intra-sheet interactif (« tape sur ce bouton pour continuer »). Texte explicatif et coach-marks discrets uniquement.
- Pas de modification de l'onboarding existant. Les coach-marks Phase 1 prennent le relais juste après la fin de l'onboarding, sur les écrans réels.

## 3. Modèle de données

### 3.1 Table `tutorial_progress`

```ts
export const tutorialProgress = sqliteTable('tutorial_progress', {
  key: text('key').primaryKey(),       // ex: 'sheet.clients', 'coachmark.first_client'
  seenAt: text('seen_at').notNull(),   // ISO timestamp
});
```

- `key` PK = string libre, namespacée par préfixe (`sheet.*` / `coachmark.*`). Ajouter de nouvelles clés en Phase 2 ne demande pas de migration.
- `seenAt` ISO — utile si on décide un jour d'analyser « quand un coach-mark est vu en moyenne » ; le coût marginal vs un bool est nul.
- Pas d'`id` UUID séparé : la `key` EST l'identité. Pas de doublon possible.
- Pas de FK vers d'autres tables : c'est un store local de progression UI, indépendant du métier.

### 3.2 Migration Drizzle `0010_tutorial_progress.sql`

Hand-written, suit le pattern des migrations 0005/0008/0009. Crée la table, pas de seed (toutes les clés démarrent « non vues » = absence de ligne).

Respect strict des règles documentées dans `CLAUDE.md` :
- `_journal.json` : `when: Date.now()` au moment de l'édition (jamais une date « propre »).
- `--> statement-breakpoint` entre tous les statements (même si une seule instruction `CREATE TABLE`, le pattern reste appliqué pour ne pas se faire piéger lors d'ajouts ultérieurs).
- `pnpm db:bundle` après l'édition + commit du `migrations.js` régénéré dans le même commit.
- Test bout-en-bout via `pnpm jest tests/data/` avant merge.

### 3.3 Backup format v5 → v6

Nouveau `BackupSnapshotV6Schema` qui ajoute `tutorialProgress: TutorialProgressRow[]`. `migrateV5ToV6` initialise la liste à `[]` côté restore d'un ancien snapshot V5 (au pire un user qui restaure un backup pré-Phase 1 revoit les nudges — pas un drame). Chaîne complète v2 → v3 → v4 → v5 → v6 préservée.

**Sync cloud des tutos vus** : un utilisateur qui restaure un backup v6 retrouve l'état exact de ses tutos vus, pas de re-déclenchement intempestif. Comportement attendu et explicité ici.

### 3.4 Anonymisation RGPD

Aucun impact. La table `tutorial_progress` ne contient aucune donnée personnelle (que des clés de feature techniques). Pas d'ajout au scrub `planAnonymization`.

### 3.5 Réinitialisation

`resetAll()` = `DELETE FROM tutorial_progress;`. Pas de soft-delete. Pas de notion de version : on assume que le contenu d'un tuto peut évoluer dans le code sans qu'on force une re-lecture. Mono-utilisateur, pas un produit où les onboardings changent à chaque release.

## 4. Couche domaine

### 4.1 Catalogue des clés

`src/domain/tutorial/keys.ts` :

```ts
export const TUTORIAL_KEYS = {
  // Phase 1 — sheets contextuelles
  sheetClients:      'sheet.clients',
  sheetTours:        'sheet.tours',
  sheetCompletion:   'sheet.completion',
  // Phase 1 — coach-marks 1re fois
  coachmarkFirstClient: 'coachmark.first_client',
  coachmarkFirstTour:   'coachmark.first_tour',
} as const;

export type TutorialKey = typeof TUTORIAL_KEYS[keyof typeof TUTORIAL_KEYS];
```

- Objet const + type dérivé : autocomplétion + check à la compilation. Aucune string magique dans le code.
- Préfixes `sheet.*` / `coachmark.*` réservés ; Phase 2 ajoutera `sheet.map`, `coachmark.cloud_backup`, etc.

**Distinction sémantique :**
- Une sheet « vue » = « le user l'a ouverte au moins une fois » (sert à ne plus pulser le `?` après).
- Un coach-mark « vu » = « il a été affiché et fermé » (ne se réaffichera plus).

### 4.2 Helpers domaine purs

`src/domain/tutorial/validate.ts` :

- `validateTutorialKey(key: string): boolean` — vérifie que la clé est dans `TUTORIAL_KEYS`. Utilisé runtime pour défense en profondeur (ex. lors de la restauration d'un backup contenant une clé inconnue parce que produite par une version plus récente de l'app).

Pas de `computeShouldShow` dans le domaine — la logique « doit-on afficher » est triviale (`!progress[key]`) et vit dans le hook React. Externaliser pour 2 conditions triviales serait de l'over-engineering.

### 4.3 Modèle Zod

```ts
export const TutorialProgressRowSchema = z.object({
  key: z.string(),
  seenAt: z.string().datetime(),
});
export type TutorialProgressRow = z.infer<typeof TutorialProgressRowSchema>;
```

## 5. Couche données et state

### 5.1 Repository

`src/data/tutorial-progress-repository.ts` :

```ts
class TutorialProgressRepository {
  list(): Promise<TutorialProgressRow[]>;
  isSeen(key: TutorialKey): Promise<boolean>;
  markSeen(key: TutorialKey, now: string): Promise<void>;  // INSERT OR IGNORE
  resetAll(): Promise<void>;                               // DELETE FROM tutorial_progress
}
```

- `markSeen` utilise `INSERT OR IGNORE` → idempotent. Appeler 2× ne change pas `seenAt`.
- Pas de `unmarkSeen(key)` granulaire en Phase 1 : reset = tout ou rien. YAGNI sinon.

### 5.2 Hooks React Query

`src/state/queries/tutorial.ts` :

```ts
const tutorialKeys = {
  all: ['tutorial'] as const,
  list: () => [...tutorialKeys.all, 'list'] as const,
};

useTutorialProgress();      // Map<TutorialKey, TutorialProgressRow>
useIsTutorialSeen(key);     // boolean (sélecteur dérivé)
useMarkTutorialSeen();      // mutation, invalide tutorialKeys.list
useResetTutorials();        // mutation, invalide tutorialKeys.list
```

Une seule query (`list`) dont on dérive tout — évite N queries indépendantes pour 7+ clés. `useIsTutorialSeen(key)` est un sélecteur pur sur le résultat, garantit qu'aucun écran ne re-fetch indépendamment.

### 5.3 Hooks de plus haut niveau (API consommée par les écrans)

`src/ui/help/hooks.ts` :

```ts
useHelpSheet(key: TutorialKey): {
  isOpen: boolean;
  open: () => void;        // marque seen + ouvre
  close: () => void;
  hasBeenSeen: boolean;    // pour styliser le `?` (pastille « pas vu »)
};

useCoachMark(key: TutorialKey, shouldShow: boolean): {
  isVisible: boolean;       // true si shouldShow ET !hasBeenSeen
  dismiss: () => void;       // marque seen + ferme
};
```

- `useCoachMark` prend un `shouldShow` externe (passé par l'écran) — c'est l'écran qui possède la logique de déclenchement (« 0 clients », « 1+ clients et 0 tournées »). Le hook AND avec « pas encore vu ». Logique simple, testable indépendamment.
- `useHelpSheet.open` marque seen au moment de l'ouverture (pas à la fermeture) : si l'utilisateur ouvre puis swipe pour fermer immédiatement, le `?` ne pulsera plus — comportement attendu.

### 5.4 Backup integration

- `BackupService.exportSnapshot` ajoute `tutorialProgress: await repo.list()`.
- `BackupService.importSnapshot` appelle `repo.resetAll()` puis bulk-inserte les lignes du snapshot.
- Au restore, on filtre les clés inconnues via `validateTutorialKey` — défense en profondeur si le snapshot vient d'une version plus récente.

## 6. Composants UI réutilisables

Tous dans `src/ui/help/`. S'appuient sur les primitives existantes (`Surface`, `Text`, `Button`, `PressScale`, bottom sheets via la lib déjà en place).

### 6.1 `<HelpButton tutorialKey="..." />`

L'icône `?` à poser dans le header d'un écran.

```tsx
<HelpButton tutorialKey={TUTORIAL_KEYS.sheetClients} />
```

- `PressScale` autour d'un `<HelpCircle size={22} />` (icône lucide).
- Couleur `text-muted` par défaut. Si `!hasBeenSeen` → pastille `bg-primary` 6×6 en haut à droite. Pas de pulse animé continu (trop bruyant).
- Tap → ouvre la `<HelpSheet>` correspondante (montée plus haut dans l'arbre, via le hook).
- Haptique léger au tap (`@/ui/motion/haptics`).
- Accessibilité : `accessibilityLabel={t('help.button_label')}`, `accessibilityRole="button"`, `accessibilityHint={t('help.button_hint')}`.

### 6.2 `<HelpSheet tutorialKey="..." title="...">`

La bottom sheet de contenu. Chaque sheet est un composant React dédié dans `src/ui/help/sheets/` (pas de JSON dynamique).

```tsx
<HelpSheet tutorialKey={TUTORIAL_KEYS.sheetClients} title={t('help.clients.title')}>
  <HelpSection icon={Users} title={t('help.clients.what_is_title')}>
    <Text>{t('help.clients.what_is_body')}</Text>
  </HelpSection>
  <HelpPreview caption={t('help.clients.caption_list')}>
    <ClientCardDemo />
  </HelpPreview>
  <HelpSection icon={Plus} title={t('help.clients.how_to_add_title')}>
    <Text>{t('help.clients.how_to_add_body')}</Text>
  </HelpSection>
  ...
</HelpSheet>
```

Sous-composants :
- **`<HelpSection icon title>`** — bloc avec icône à gauche, titre + paragraphe.
- **`<HelpPreview caption?>`** — frame `Surface variant="muted"` arrondie qui enveloppe n'importe quel JSX (typiquement un composant `*Demo`) avec une caption optionnelle. Pas d'image, pas d'asset.
- **Composants `*Demo` (`src/ui/help/previews/*.tsx`)** — 5 composants visuellement fidèles aux surfaces réelles (`ClientCardDemo`, `ClientFilterDemo`, `TourCardDemo`, `TourPlanningDemo`, `CompletionRowDemo`), sans dépendances aux hooks de données réels. Données hardcodées au contexte tondeur (Famille Le Goff, Plouhinec, etc.).

**Pivot post-design (2026-05-11) :** la conception initiale prévoyait des `<HelpScreenshot>` chargeant des `.webp` depuis `assets/help/`. Pivot vers des previews in-app pour éliminer la maintenance des captures à chaque refonte UI et garantir un rendu light/dark correct par construction. Trade-off accepté : risque de divergence visuelle entre demos et composants réels — mitigé par `src/ui/help/previews/README.md` qui documente la convention de maintenance.

Décisions UI :
- Sheet **scrollable** (les screenshots peuvent rendre le contenu long). Hauteur 85 % de la viewport, snap au plein écran si overflow.
- Bouton « Compris » full-width (`variant="primary"`) en bas pour fermer — confort tactile.
- Background opaque obligatoire (audit `showFSheet` du chantier précédent — pas de sheet semi-transparente).

### 6.3 `<CoachMark anchorRef tutorialKey shouldShow>`

Tooltip non-bloquant qui pointe un élément.

```tsx
const ctaRef = useRef<View>(null);
const { isVisible, dismiss } = useCoachMark(TUTORIAL_KEYS.coachmarkFirstClient, clients.length === 0);

return (
  <>
    <View ref={ctaRef}><Button>...</Button></View>
    <CoachMark anchorRef={ctaRef} visible={isVisible} onDismiss={dismiss} arrowDirection="up">
      <Text>{t('coachmark.first_client.body')}</Text>
    </CoachMark>
  </>
);
```

- Overlay non-bloquant : cartouche (`Surface variant="primary"`) avec flèche pointant l'ancre, positionné via `measure()` sur le ref.
- Pas de backdrop sombre (ce n'est pas un walkthrough impératif). L'utilisateur peut tap où il veut, le coach-mark se ferme via son `×` ou via tap sur l'overlay.
- Animation d'entrée : fade + slide léger depuis la flèche, durée et easing depuis `motion-tokens.ts`. Haptique discret à l'apparition.
- Si l'écran change ou l'ancre disparaît → `onDismiss` auto (cleanup `useEffect`).
- Z-index élevé via `Modal` RN ou un overlay positionné dans le root layout — décision tactique à l'impl, le composant absorbe la complexité.

**Ce que les composants n'incluent pas :**
- Pas de séquençage multi-step (« coach-mark 1 → 2 → 3 »). Chaque coach-mark est indépendant. Si on a besoin d'un walkthrough un jour, ce sera un autre composant.
- Pas de positionnement intelligent contre les bords d'écran : `up` ou `down` selon l'ancre, pas d'auto-flip. Les 2 ancres Phase 1 (CTA empty state Clients, CTA empty state Tournées) sont dans des positions prévisibles.

## 7. Intégrations Phase 1

### 7.1 Écran Clients (`app/(tabs)/clients/index.tsx`)

- Header : ajout de `<HelpButton tutorialKey={TUTORIAL_KEYS.sheetClients} />` à droite, à côté des actions existantes (filtre, recherche).
- Empty state (`clients.length === 0`) : ajout d'un `<CoachMark>` ancré sur le bouton « Nouveau client » (FAB ou CTA dans l'empty state — choisir l'ancre la plus naturelle au moment de l'impl).

### 7.2 Écran Tournées (`app/(tabs)/tours/index.tsx`)

- Header : `<HelpButton tutorialKey={TUTORIAL_KEYS.sheetTours} />`.
- Empty state intelligent : déclencher le coach-mark `coachmarkFirstTour` **uniquement si** `clients.length >= 1 && tours.length === 0`. Quand le user n'a pas encore créé de client, le coach-mark Tournées ne se montre pas (priorité au coach-mark Clients sur l'autre onglet, pour ne pas overload avec deux nudges en simultané).
- Ancre : bouton « Nouvelle tournée » (sheet déclencheur). Flèche pointant vers le haut.

### 7.3 Écran Complétion de tournée

- Header : `<HelpButton tutorialKey={TUTORIAL_KEYS.sheetCompletion} />`.
- Pas de coach-mark Phase 1 sur cet écran (scope serré). Un coach-mark « bilan » sera ajouté en Phase 2 si on constate de l'abandon.
- L'écran le plus dense de l'app — la sheet a beaucoup de valeur ici.

### 7.4 Pas de changement Phase 1 sur

Carte, Fiche client, Détail tournée, Catalogue, Statuts, Cloud, Paramètres root. Tous reçoivent leur `<HelpButton>` en Phase 2.

### 7.5 Pas de changement à l'onboarding existant

Les coach-marks Phase 1 prennent le relais juste *après* la fin de l'onboarding, sur les écrans réels.

### 7.6 Réglages

`app/(tabs)/settings/index.tsx` : nouvelle section « Aide » entre « Légal » et le bas de l'écran. Une `SettingsRow` : `Aide & tutoriels` → ouvre `app/(tabs)/settings/help.tsx`.

`app/(tabs)/settings/help.tsx` (nouvel écran) :
- Bloc explicatif court (`settings.help.intro`).
- Compteur `X tutoriels vus sur Y disponibles` (informatif, dérivé de `useTutorialProgress`).
- Bouton « Rejouer les tutoriels » (`variant="secondary"`) → `AlertDialog` de confirmation → `useResetTutorials.mutate()` → toast succès.
  - Pas de `ConfirmTypedDialog` : action non-destructive, un simple dialog suffit.

## 8. Contenu (i18n)

Toutes les chaînes dans `src/i18n/locales/fr.json`. L'app est FR-only à ce stade (pas de `en.json` au moment de la spec) ; clés en anglais comme imposé par `CLAUDE.md`, valeurs en français.

### 8.1 Bloc `help`

```
help.button_label                  "Aide"
help.button_hint                   "Affiche une explication de cet écran"
help.dismiss_cta                   "Compris"

help.clients.title                 "Tes clients"
help.clients.what_is_title         "Le point de départ"
help.clients.what_is_body          "Cet écran liste tous tes clients : éleveurs, particuliers, exploitations. Chaque client a une adresse et un ou plusieurs animaux à entretenir."
help.clients.how_to_add_title      "Ajouter un client"
help.clients.how_to_add_body       "Tape sur le bouton « + » en bas à droite pour créer une fiche client. Indique son nom, son adresse, et combien d'animaux il a."
help.clients.statuses_title        "Les statuts"
help.clients.statuses_body         "Chaque client a un statut : « En attente de RDV », « Planifié », « Fait », etc. L'app les calcule automatiquement, mais tu peux aussi les personnaliser dans Réglages > Statuts."
help.clients.filter_title          "Filtrer & rechercher"
help.clients.filter_body           "Tape sur l'icône loupe pour rechercher par nom, téléphone, adresse ou note. L'icône filtre permet de n'afficher que certains statuts."
help.clients.caption_list          "La liste des clients"
help.clients.caption_filter        "Le menu de filtre par statut"

help.tours.title                   "Tes tournées"
help.tours.what_is_title           "Une tournée, c'est quoi"
help.tours.what_is_body            "Une tournée regroupe les clients que tu visites le même jour, dans l'ordre où tu vas les voir. L'app calcule la durée, le trajet et le revenu prévu."
help.tours.how_to_create_title     "Créer une tournée"
help.tours.how_to_create_body      "Tape sur « Nouvelle tournée ». Choisis une date, sélectionne tes clients, et l'app organise l'itinéraire. Tu peux choisir l'ordre toi-même ou laisser l'app optimiser."
help.tours.statuses_title          "Planifiée vs complétée"
help.tours.statuses_body           "Une tournée « planifiée » peut être modifiée. Une fois la tournée terminée sur le terrain, tu la marques « complétée » via le bilan — c'est là que tu enregistres ce qui s'est vraiment passé."
help.tours.caption_list            "La liste des tournées"
help.tours.caption_planning        "L'écran de planification"

help.completion.title              "Faire le bilan d'une tournée"
help.completion.what_is_title      "Pourquoi ce bilan"
help.completion.what_is_body       "Sur le terrain, ce qui se passe ne correspond pas toujours au plan : un client a plus de moutons que prévu, un autre a annulé. Le bilan permet d'enregistrer la réalité — c'est ce qui alimente l'historique et la facturation."
help.completion.adjust_title       "Ajuster les quantités"
help.completion.adjust_body        "Pour chaque client, tu peux modifier la quantité de chaque prestation. Tape sur les flèches « + » et « - ». Si une prestation n'a pas été faite, mets la quantité à zéro."
help.completion.extra_title        "Ajouter une prestation hors plan"
help.completion.extra_body         "Si tu as fait une prestation qui n'était pas prévue, tape sur « + Ajouter une prestation hors plan » et choisis-la dans le catalogue."
help.completion.payment_title      "Enregistrer le paiement"
help.completion.payment_body       "Tu peux noter le mode de paiement utilisé pour chaque client (espèces, virement, chèque…). Cette info reste dans l'historique."
help.completion.caption_main       "L'écran de bilan, prestation par prestation"
```

### 8.2 Bloc `coachmark`

```
coachmark.dismiss_label            "Fermer cette bulle"

coachmark.first_client.title       "Commence par ajouter un client"
coachmark.first_client.body        "Pour utiliser l'app, ajoute au moins un client. Tape sur le bouton « + » ci-dessus."

coachmark.first_tour.title         "Maintenant, planifie ta première tournée"
coachmark.first_tour.body          "Tu as au moins un client. Tape sur « Nouvelle tournée » pour organiser ta journée."
```

### 8.3 Bloc `settings.help`

```
settings.help.row_label            "Aide & tutoriels"
settings.help.row_hint             "Revoir les explications, rejouer les bulles d'introduction"
settings.help.screen_title         "Aide & tutoriels"
settings.help.intro                "L'app affiche des bulles d'aide la première fois que tu utilises certaines fonctionnalités. Tu peux les revoir en tapant l'icône « ? » dans chaque écran, ou rejouer toutes les bulles d'introduction."
settings.help.replay_cta           "Rejouer les tutoriels"
settings.help.replay_confirm_title "Rejouer les tutoriels ?"
settings.help.replay_confirm_body  "Les bulles d'introduction réapparaîtront aux prochains usages."
settings.help.replay_success       "Tutoriels réinitialisés"
settings.help.counter              "{{seen}} tutoriels vus sur {{total}}"
```

### 8.4 Previews in-app

5 composants dans `src/ui/help/previews/`, chacun ~30-60 lignes de JSX pur, hardcodé au contexte métier (tondeur ovin) :

| Demo | Mirrors | Utilisé par |
| --- | --- | --- |
| `client-card-demo.tsx` | `src/ui/components/client-card.tsx` | help-sheet-clients (caption_list) |
| `client-filter-demo.tsx` | `src/ui/components/client-status-filter-dialog.tsx` | help-sheet-clients (caption_filter) |
| `tour-card-demo.tsx` | tour list row | help-sheet-tours (caption_list) |
| `tour-planning-demo.tsx` | tour planning UI | help-sheet-tours (caption_planning) |
| `completion-row-demo.tsx` | prestation row in `complete.tsx` | help-sheet-completion (caption_main) |

**Convention de maintenance** documentée dans `src/ui/help/previews/README.md` : mettre à jour le demo correspondant à chaque évolution **visible** (layout, padding, style de badge, couleurs structurantes) du composant réel mirroré. Les ajustements de tokens / espacement mineurs ne déclenchent pas une mise à jour. Pas de production de captures, pas d'asset binaire.

## 9. Tests

Découpage existant du repo : domain → vitest, data/infra → jest. Aucun test widget (la base est quasi-inexistante, hors-scope).

### 9.1 Domain (`tests/domain/tutorial/`) — vitest, ~5 tests

- `validateTutorialKey` : accepte les clés du catalogue, rejette une clé inconnue (3 cas).
- `TutorialProgressRowSchema` Zod : valide une row correcte, rejette `seenAt` mal formé (2 cas).

### 9.2 Data (`tests/data/tutorial-progress-repository.test.ts`) — jest avec real SQLite, ~6 tests

- `markSeen` insère une ligne.
- `markSeen` est idempotent (2 appels successifs ne dupliquent pas et ne changent pas `seenAt`).
- `isSeen` retourne `true` après `markSeen`, `false` sinon.
- `list` retourne toutes les lignes.
- `resetAll` vide la table.
- Migration `0010_tutorial_progress` applique end-to-end (la table existe, peut accepter des INSERTs).

### 9.3 Backup migration (`tests/data/backup-migrations.test.ts` étendu) — jest, ~3 tests

- `migrateV5ToV6` : ajoute `tutorialProgress: []` à un snapshot V5.
- Round-trip V6 → restore → re-export : préserve les lignes `tutorial_progress`.
- Restore d'un V6 contenant une clé inconnue : skip silencieux (filtre via `validateTutorialKey`), pas de crash.

### 9.4 Hooks et UI

- `useHelpSheet` et `useCoachMark` : pas de tests dédiés. Triviaux (lecture d'un boolean dérivé + appel mutation). Tester demanderait de mocker React Query pour zéro valeur ajoutée.
- Composants UI : pas de tests automatisés. Validation manuelle via dev client.

### 9.5 Checklist de validation manuelle (avant merge)

- [ ] Au 1er lancement post-onboarding sur une DB vide : coach-mark « 1er client » apparaît sur l'écran Clients.
- [ ] Après création du 1er client : coach-mark disparaît, ne réapparaît pas en navigant ailleurs et en revenant.
- [ ] Sur l'écran Tournées avec 1+ client et 0 tournée : coach-mark « 1re tournée » apparaît.
- [ ] Sur l'écran Tournées avec 0 client : coach-mark « 1re tournée » NE s'affiche pas.
- [ ] Tap sur `<HelpButton>` Clients : la sheet s'ouvre, contenu scrollable, captures en bonne résolution, basculement light/dark correct.
- [ ] Sheet ouverte → close (swipe down + tap « Compris ») → la pastille « non vue » disparaît du `?`.
- [ ] Réglages > Aide & tutoriels > Rejouer : confirmation, succès, retour sur les écrans → les coach-marks réapparaissent et la pastille `?` revient.
- [ ] Backup → restore : les tutos vus avant le backup restent vus après restore.
- [ ] Backup d'une version Phase 2 (qui contient des clés `sheet.map` etc.) restauré sur Phase 1 → pas de crash, clés inconnues ignorées.

## 10. Risques et décisions à l'implémentation

### 10.1 Risques techniques

- **Mesure de position du `<CoachMark>` flaky en RN** : `View.measure()` peut renvoyer des coordonnées avant que l'écran soit pleinement layout. Mitigation : envelopper dans `requestAnimationFrame` ou utiliser `onLayout` de l'ancre. À expérimenter en début d'impl ; si trop fragile, fallback sur un coach-mark « fixed bottom » sans flèche d'ancre (légère perte UX, acceptable).
- **Previews à maintenir alignés avec les composants réels** : depuis le pivot post-design (cf §6.2), les previews sont des composants `*Demo` séparés des composants réels. Risque de divergence visuelle si une refonte oublie de propager les changements. Mitigation : `src/ui/help/previews/README.md` documente la convention + l'idéal est une pass de revue de ce dossier à chaque refonte UI majeure. Coût bien moindre qu'avant (édition de JSX vs production de captures), et la divergence éventuelle reste cosmétique (pas un crash, juste un demo qui ne ressemble plus exactement au réel).
- **Clés `sheet.*` pas vues sur les écrans pas encore couverts en Phase 2** : si on ajoute `sheet.map` en Phase 2, son `?` apparaîtra avec la pastille « pas vu » même chez les users existants. C'est le comportement attendu (c'est *une nouvelle feature pour eux*) — pas un bug.

### 10.2 Décisions à trancher à l'implémentation (non bloquantes pour la spec)

- Position exacte du `<HelpButton>` dans le `<ScreenHeader>` (existant) — gauche du titre, droite, à côté des autres actions. Décision à l'œil au moment de l'impl.
- Wording exact des CTAs (« Compris » vs « OK » vs « Fermer »). Itérable post-merge.
- ~~Bascule light/dark des screenshots via 2 fichiers `.webp`~~ — **caduc depuis le pivot vers les previews in-app** (§6.2). Les composants `*Demo` utilisent les primitives `<Surface>`, `<Text>` qui adaptent automatiquement leur couleur via `useResolvedColorScheme()`.

### 10.3 Pas un risque

- **RGPD** : la table ne contient pas de PII. Pas de DPIA, pas d'ajout au scrub.
- **Performance** : ~10 lignes max dans la table en Phase 1 (~17 en Phase 2). Lue 1× au mount d'un écran via React Query, cache infini en pratique avec invalidation manuelle. Coût négligeable.

## 11. Critères d'acceptation

La Phase 1 est mergeable quand :

1. La table `tutorial_progress`, sa migration `0010`, et le bump backup v5 → v6 passent `pnpm jest tests/data/` et `pnpm db:bundle` sans warning.
2. Les 11 tests automatisés (domain + data + backup) sont verts.
3. La checklist de validation manuelle (§9.5) est entièrement cochée sur dev client (Android au minimum, iOS si disponible).
4. Le contenu i18n est complet en FR.
5. Les 5 composants previews `src/ui/help/previews/*Demo.tsx` rendent visuellement (à la lecture) en cohérence avec les composants réels qu'ils mirrorent. Le README de maintenance est en place.
6. Les écrans Clients / Tournées / Complétion ont leur `<HelpButton>` ; les écrans Clients / Tournées ont leur `<CoachMark>` empty state.
7. L'écran Réglages > Aide & tutoriels existe et le reset fonctionne end-to-end.
8. Aucune `any` introduite, `pnpm typecheck` vert, `pnpm lint` vert.
