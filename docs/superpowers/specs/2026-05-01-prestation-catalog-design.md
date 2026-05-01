# Catalogue de prestations et tarifs — design

**Date :** 2026-05-01
**Scope :** Ajouter à l'app un catalogue de prestations (label, prix HT, durée, lien
optionnel à une catégorie animale) que le praticien définit dans Settings, puis
sélectionne par arrêt à la planification d'une tournée et ajuste au bilan.
Débloque la suite (#7 facturation) et remplace l'ancien mécanisme de durée
basé sur `AnimalCategory.defaultMinutes`.

## Goal

Permettre à tout praticien itinérant (déjà multi-espèces depuis #5) de
modéliser explicitement ce qu'il vend : combien d'unités, à quel prix, en
combien de temps. La planification d'une tournée affiche désormais une durée
**et** un revenu indicatif. L'historique des interventions devient lisible en
prestations (« 12 tontes Petit, 4 tontes Grand ») plutôt qu'en compteurs
bruts d'animaux.

## Scope

**In scope :**
- Nouvelle entité `Prestation` (CRUD complet : créer, renommer, archiver,
  désarchiver). Liée à une catégorie animale **ou** libre.
- Nouvel écran Settings → « Catalogue de prestations ».
- Picker de prestations par arrêt à la création (et à l'édition) d'une
  tournée, avec section « Suggérées » / « Autres » et pré-remplissage des
  qty depuis `client.animals`.
- Refonte de `TourStop.planned`/`actual` : stockage des prestations
  sélectionnées (avec snapshots) en lieu et place des `TourStopAnimal`.
- Calcul du revenu HT par stop, par tournée, du net indicatif.
- Refonte du bilan (`TourCompletionScreen`) : ajustement de qty par
  prestation, ajout de prestations hors plan.
- Refonte de la saisie manuelle (`ManualHistoryEntrySheet`) : prestations
  au lieu de compteurs.
- Dérivation des compteurs `client.animals` à partir des prestations
  effectuées (règle MAX par catégorie sur les prestations liées).
- Seeding minimal d'une prestation par catégorie d'espèce seedée à
  l'activation (Mouton/Petit → « Tonte », Caprin/Chèvre → « Onglons », etc.).
- Schéma Drift `schemaVersion: 11 → 12` (drop+recreate, pas d'utilisateurs
  en prod).

**Out of scope :**
- Facturation, TVA, numérotation, mentions légales : c'est #7. Le
  `priceCentsSnapshot` sur `TourStopPrestation` est conçu pour servir de
  source à #7.
- Recherche / filtre dans le picker (à réintroduire si le catalogue dépasse
  ~20 prestations).
- Création d'une prestation à la volée depuis le picker. Friction
  acceptable au MVP : sortir → créer dans le catalogue → revenir.
- Filtres par espèce / par prestation dans les pickers de tournée et la
  liste de clients (déjà follow-up de #5, reste follow-up).
- Dénormalisation des totaux revenu/net sur la table `tours` (recalcul à
  la lecture suffit).
- Stats / reporting (revenu par période, top prestations, etc.).
- Bulk edit / duplication de prestations.
- Migration des données : drop+recreate, pas d'utilisateurs en prod.

## Approach

Ajout d'une couche « catalogue » au-dessus du modèle d'animaux par catégorie
livré en #5. Une `Prestation` peut être **liée** à une `AnimalCategory`
(héritage d'espèce, qty pré-remplie depuis `client.animals` au picker) ou
**libre** (categoryId nul, qty saisie manuellement, toujours visible dans le
picker). Les snapshots (nom, prix, durée, catégorie) sont figés sur chaque
`TourStopPrestation` au moment de la sélection — pattern identique à celui
déjà en place pour `TourStopAnimal` aujourd'hui (qui disparaît).

`AnimalCategory.defaultMinutes` et `defaultPriceCents` sont supprimés : ces
colonnes existaient depuis #5 mais n'étaient jamais lues en prod ; les
prestations les remplacent fonctionnellement.

## Architecture & modèle de domaine

### Nouvelles entités

```dart
// lib/domain/models/prestation.dart
class Prestation {
  final int id;
  final String name;
  final int? priceCents;        // null = à compléter par l'utilisateur
  final int? minutes;           // null = à compléter
  final int? categoryId;        // null = libre/universelle
  final DateTime? archivedAt;   // soft-delete
}

// lib/domain/models/tour_stop_prestation.dart
class TourStopPrestation {
  final int prestationId;
  final int qty;
  final String nameSnapshot;            // ex: "Tonte"
  final int priceCentsSnapshot;         // 0 si non renseigné au snapshot
  final int minutesSnapshot;            // 0 si non renseigné au snapshot
  final int? categoryIdSnapshot;        // null si libre
  final String? categoryNameSnapshot;   // ex: "Petit"
  final String? speciesNameSnapshot;    // ex: "Mouton"
}
```

### Mutations sur les entités existantes

**`TourStop`** — refonte du modèle planifié/réel :
- Supprimés : `planned: List<TourStopAnimal>`, `actual: List<TourStopAnimal>?`.
- Ajoutés : `plannedPrestations: List<TourStopPrestation>`,
  `actualPrestations: List<TourStopPrestation>?` (rempli au bilan).

`TourStopAnimal` est supprimé entièrement. Les compteurs d'animaux à un
arrêt sont dérivés à la lecture depuis les prestations liées
(cf. `animalCountsFromPrestations`).

**`AnimalCategory`** :
- Supprimés : `defaultMinutes`, `defaultPriceCents`.

**`ManualHistoryEntry`** :
- Supprimé : `animals: List<TourStopAnimal>`.
- Ajouté : `prestations: List<TourStopPrestation>`.

**`Client.animals: List<AnimalCount>`** : conservé tel quel. C'est l'attribut
éditable du client (« combien d'animaux par catégorie »). Distinct des
prestations sélectionnées sur un arrêt. Reste utilisé pour :
- Le pré-remplissage du picker à un arrêt (qty proposée =
  `client.animals[categoryId].count` quand la prestation est liée à cette
  catégorie).
- Le statut `noAnimals` (inchangé).
- Le widget `AnimalCountsBadges` sur la fiche client / map / liste.

### Schéma Drift

`schemaVersion: 11 → 12`. Drop+recreate via `onUpgrade` (consistent avec le
pattern de #5).

#### Nouvelle table

```dart
@DataClassName('PrestationRow')
class PrestationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get priceCents => integer().nullable()();
  IntColumn get minutes => integer().nullable()();
  IntColumn get categoryId => integer().nullable()
      .references(AnimalCategoriesTable, #id, onDelete: KeyAction.setNull)();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}
```

`onDelete: setNull` : si une catégorie était hard-deletée (jamais dans le
MVP, mais robuste), la prestation devient libre plutôt qu'orpheline.

#### Tables modifiées

`AnimalCategoriesTable` :
- Supprimées : `defaultMinutes`, `defaultPriceCents`.

`TourStopsTable` :
- Supprimées : `plannedAnimals`, `actualAnimals`.
- Ajoutées :
  - `TextColumn plannedPrestations` (JSON via `TourStopPrestationListConverter`,
    défaut `'[]'`).
  - `TextColumn actualPrestations` (JSON via même converter, nullable).

`ManualHistoryEntriesTable` :
- Supprimée : `animals`.
- Ajoutée : `TextColumn prestations` (JSON, défaut `'[]'`).

#### Format JSON du converter

```jsonc
[
  {
    "prestationId": 3,
    "qty": 12,
    "nameSnapshot": "Tonte",
    "priceCentsSnapshot": 800,
    "minutesSnapshot": 8,
    "categoryIdSnapshot": 1,
    "categoryNameSnapshot": "Petit",
    "speciesNameSnapshot": "Mouton"
  },
  {
    "prestationId": 7,
    "qty": 1,
    "nameSnapshot": "Visite déplacement",
    "priceCentsSnapshot": 2000,
    "minutesSnapshot": 0,
    "categoryIdSnapshot": null,
    "categoryNameSnapshot": null,
    "speciesNameSnapshot": null
  }
]
```

### Helper de normalisation

`normalizeTourStopPrestations(List<TourStopPrestation>)` :
- Drop les entrées avec `qty <= 0`.
- Pas de dédup (le user peut intentionnellement avoir plusieurs lignes
  distinctes pour la même prestation, ex. saisie progressive).
- Tri stable par `prestationId` puis ordre d'insertion.

Tous les writes passent par ce helper.

## Settings : éditeur de catalogue

### `SettingsScreen` — nouveau bloc

Insertion d'un nouveau bloc juste **sous** « Espèces & catégories ». Carte
cliquable avec :
- Titre : « Catalogue de prestations » (l10n `prestationCatalogTitle`).
- Sous-texte : « X prestation(s) active(s) »
  (l10n `prestationCatalogCountFmt`).
- Tap → `context.push('/settings/prestations')`.

### `PrestationCatalogScreen` (route `/settings/prestations`)

Structure verticale, calquée sur `SpeciesManagementScreen` :

1. Section « Actives » — regroupées par espèce (et un groupe « Libres » pour
   les `categoryId == null`). Chaque prestation affichée sur une carte :
   - Ligne 1 : nom de la prestation.
   - Ligne 2 (sous-texte) : `[catégorie] · [prix € HT] · [N min]` avec
     dashes pour les valeurs nulles (ex. « Petit · — · — »).
   - Tap → push `PrestationEditScreen(id)`.
   - Menu `⋮` : Modifier, Archiver.
2. Section « Archivées » repliable.
3. CTA bas d'écran : « + Ajouter une prestation » → push
   `PrestationEditScreen.create()` (mode création).

### `PrestationEditScreen` (route `/settings/prestations/:id` ou `/new`)

Formulaire plein écran (cohérent avec `client_form_screen` et
`species_edit_screen`) :

- **Nom** (`TextField`, obligatoire).
- **Liée à une catégorie ?** (`Switch`) :
  - OFF → prestation libre.
  - ON → un picker à deux niveaux apparaît : `Espèce` (chips horizontaux
    des espèces actives), puis `Catégorie` (chips des catégories actives
    de l'espèce sélectionnée). Sélection unique. Les catégories archivées
    sont masquées.
- **Prix HT (€)** — numeric input, vide autorisé. Helper text : « Sera
  utilisé pour la facturation (#7). »
- **Durée (min)** — numeric input, vide autorisé. Helper text : « Utilisée
  pour estimer la durée d'une tournée. »
- **Bouton primaire** : « Enregistrer ».
- **Bouton secondaire** (mode édition seulement) : « Archiver » (ou
  « Désarchiver » si déjà archivée).

### Règles de validation

- Nom obligatoire, non vide.
- Si `Liée à une catégorie` est ON, espèce **et** catégorie obligatoires.
- Pas de hard-delete. Pas de fusion. Pas de duplication automatique.
- Une prestation peut être archivée à tout moment, indépendamment des
  autres. Aucune contrainte « au moins N actives ».
- Archiver une espèce ou une catégorie n'auto-archive pas les prestations
  liées. Le user les gère depuis le catalogue. Une prestation liée à une
  catégorie archivée reste sélectionnable dans le picker (la catégorie
  archivée peut encore figurer dans `client.animals` en lecture seule
  tant qu'elle n'a pas été effacée).

### Seeding à l'activation d'une espèce

Étendre `kSpeciesSeeds` :

```dart
class CategorySeed {
  final String name;
  final String? defaultPrestationName;  // nom de la prestation à créer
  const CategorySeed({required this.name, this.defaultPrestationName});
}

const kSpeciesSeeds = <SpeciesSeed>[
  SpeciesSeed(name: 'Mouton', categories: [
    CategorySeed(name: 'Petit', defaultPrestationName: 'Tonte'),
    CategorySeed(name: 'Grand', defaultPrestationName: 'Tonte'),
  ]),
  SpeciesSeed(name: 'Cheval', categories: [
    CategorySeed(name: 'Poulain', defaultPrestationName: 'Parage'),
    CategorySeed(name: 'Adulte',  defaultPrestationName: 'Parage'),
  ]),
  SpeciesSeed(name: 'Bovin', categories: [
    CategorySeed(name: 'Veau',   defaultPrestationName: 'Parage'),
    CategorySeed(name: 'Adulte', defaultPrestationName: 'Parage'),
  ]),
  SpeciesSeed(name: 'Caprin', categories: [
    CategorySeed(name: 'Chèvre', defaultPrestationName: 'Onglons'),
  ]),
];
```

À l'onboarding et au « Restaurer un template » dans `SpeciesManagementScreen`,
après insertion de l'espèce + catégories, on crée également les prestations
seedées (prix/durée nuls, `categoryId` pointant sur la catégorie qu'on vient
d'insérer). Pour les espèces custom, **rien de seedé**.

## Picker des prestations à un arrêt

### Quand le picker s'ouvre

Lors de la création d'un draft de tournée, dans `TourDraftScreen`. Chaque
ligne d'arrêt (déjà calculée par `BuildTourDraft` avec ordre optimisé/préset)
affiche un bouton/zone tappable. Tap → `PrestationPickerSheet`.

Au retour du picker, le draft recalcule (durée totale, revenu total, share
fee). Si un stop n'a aucune prestation sélectionnée, il reste valide (durée
intervention = 0 sur ce stop), juste prévenu visuellement (icône
d'avertissement discrète).

Le même picker est réutilisé en mode édition de tournée (route
`/tours/:id/edit`, déjà livré) en passant la sélection courante extraite du
`TourStop.plannedPrestations`.

### `PrestationPickerSheet({clientId, initialSelection})`

```
┌─────────────────────────────────────────┐
│  Prestations pour [nom du client]       │
├─────────────────────────────────────────┤
│                                         │
│  Suggérées                              │
│   (categoryId ∈ client.animals          │
│    avec count > 0)                      │
│                                         │
│   [✓] Tonte (Mouton/Petit)              │
│       qty: [12]   8 €/u · 8 min/u       │
│                                         │
│   [✓] Tonte (Mouton/Grand)              │
│       qty: [4]    12 €/u · 15 min/u     │
│                                         │
│  Autres                                 │
│   (categoryId absent du client,         │
│    ou libres)                           │
│                                         │
│   [ ] Vermifuge (Mouton/Petit)          │
│       qty: [_]    5 €/u · 2 min/u       │
│                                         │
│   [ ] Visite déplacement (Libre)        │
│       qty: [_]    20 €/u · — min/u      │
│                                         │
├─────────────────────────────────────────┤
│             [Annuler]   [Valider]       │
└─────────────────────────────────────────┘
```

**Comportement** :
- Section « Suggérées » : prestations dont `categoryId` ∈ `client.animals`
  avec `count > 0`. Cochées par défaut. `qty` pré-remplie à
  `client.animals[categoryId].count`. Le user peut décocher ou ajuster.
- Section « Autres » : reste des prestations actives (catégorie non
  présente chez ce client, ou libres). Décochées par défaut. `qty` vide.
  Cocher impose de saisir une qty > 0 (sinon décoche au blur).
- Sections masquées si vides.
- Prestations archivées exclues du picker (par construction).
- Prestations sans prix ni durée renseignés : toujours affichées, le calcul
  utilisera 0 pour les snapshots manquants. Un helper text discret
  « Prix/durée non renseignés » s'affiche sous la ligne pour inciter à
  compléter.

**Validation** : tap sur « Valider » → callback retourne
`List<TourStopPrestation>` (avec snapshots) au draft.

### Snapshots à la sélection

Au moment où le user valide le picker, on construit chaque
`TourStopPrestation` en figeant :
- `nameSnapshot` = `prestation.name` à cet instant.
- `priceCentsSnapshot` = `prestation.priceCents ?? 0`.
- `minutesSnapshot` = `prestation.minutes ?? 0`.
- `categoryIdSnapshot`, `categoryNameSnapshot`, `speciesNameSnapshot` =
  lookup au moment du snapshot, ou `null` si la prestation est libre.

Renommer/archiver une prestation après coup ne casse pas l'historique.
Pattern identique à `TourStopAnimal` aujourd'hui.

### Re-édition

Tap sur la ligne d'un arrêt déjà rempli → ré-ouvre le picker avec
`initialSelection` égale à la sélection courante.

### Hors scope (picker)

- Création d'une nouvelle prestation à la volée.
- Recherche / filtre.
- Notes par prestation (la note vit au niveau de l'arrêt, champ
  `interventionNote` déjà présent).

## Tour draft et calculs

### `BuildTourDraft` — refonte

Nouvelle signature :

```dart
TourDraftResult build({
  required List<int> candidateIds,
  required List<Client> candidates,
  required List<DistanceMatrixEntry> matrix,
  required Settings settings,
  required Map<int, List<TourStopPrestation>> prestationsPerClient,
  required int startTimeMinutes,
  List<int>? presetOrder,
});
```

Le contrôleur (`tour_draft_controller`) gère désormais une
`Map<int, List<TourStopPrestation>>` (clientId → prestations sélectionnées
dans le picker). Au moment où le user valide le draft :
- Pour chaque candidat sans entrée dans la map → liste vide.
- `BuildTourDraft` assemble les listes par stop dans l'ordre optimisé/préset.

Le `categoryLookup` actuel disparaît : les snapshots étant figés dans les
`TourStopPrestation` au moment du picker, `BuildTourDraft` n'a plus à les
regénérer.

### `TourDurationEstimator` — nouvelle formule

```
duration_per_stop = Σ (prestation.qty × prestation.minutesSnapshot)
total_intervention_minutes = Σ duration_per_stop
total_drive_seconds = inchangé
end_time_minutes = start + total_intervention_minutes + total_drive_seconds/60
```

Si `minutesSnapshot == 0`, contribution nulle.

### Revenu par stop, total tournée

Nouveaux champs sur `TourDraftResult` :

```dart
class TourDraftResult {
  // … champs existants
  final List<int> revenueCentsPerStop;
  final int totalRevenueCents;
  final int totalNetCents;     // = totalRevenueCents - totalFeeCents
}
```

**Convention** :
- `totalRevenueCents` = somme **HT** des prestations (TVA hors scope, #7).
- `totalFeeCents` = frais de déplacement répartis (déjà existant).
- `totalNetCents` = revenu - frais de déplacement, à titre **indicatif**
  (pas un net comptable).

### Persistance

`TourRepository.insert` et `update` (déjà refactorisé pour l'édition)
écrivent les `plannedPrestations` dans la nouvelle colonne
`tour_stops.planned_prestations`. Pas de `actualPrestations` à l'insert /
update — vide jusqu'au bilan.

Pas de dénormalisation `totalRevenueCents` au niveau `Tour` pour le MVP.
Recalcul à la lecture (rapide, comme `tourByIdProvider` aujourd'hui).

### Affichage dans `TourDraftScreen`

Résumé étendu au-dessus du CTA « Confirmer » :

```
Tournée du DD/MM
  Distance        : X km
  Conduite        : X h Y min
  Intervention    : X h Y min
  Revenu          : X €      ← nouveau
  Frais déplac.   : X €
  Net (indicatif) : X €      ← nouveau
```

Les lignes Revenu/Net sont masquées si `totalRevenueCents == 0`.

Chaque ligne d'arrêt :
```
[N° ordre] · [nom client]
[ville] · [arrivée HH:mm]
[N prestation(s)] · [N min] · [N €]   ← clic → picker
```

Si aucune prestation sélectionnée :
```
[N° ordre] · [nom client]
[ville] · [arrivée HH:mm]
⚠ Aucune prestation                   ← clic → picker
```

Le badge `AnimalCountsBadges` actuel disparaît des arrêts dans le draft (les
prestations font foi). Il reste sur la fiche client et la liste de clients.

## Bilan / écran de complétion

### `TourCompletionScreen` — refonte

Pour chaque stop, une carte :

```
[N° ordre] · [nom client]
─────────────────────────
Prestations effectuées :

  [✓] Tonte (Mouton/Petit)
      qty: [12]   8 €/u

  [✓] Tonte (Mouton/Grand)
      qty: [3]    12 €/u    ← ajusté de 4 → 3

  [+ Ajouter une prestation hors plan]
─────────────────────────
Note : ___________________
```

**Comportement** :
- Liste pré-remplie avec les `plannedPrestations` du stop (cochées, qty
  initiale = qty planifiée).
- Le user peut ajuster qty (numeric input).
- Décocher → exclue du `actualPrestations` (équivalent qty=0).
- Bouton « + Ajouter une prestation hors plan » ouvre un picker secondaire
  qui liste **toutes les prestations actives non déjà sélectionnées** sur
  ce stop (groupées par espèce + groupe Libres). Tap → ajout d'une ligne
  avec qty à saisir.
- Champ « Note » par stop = `interventionNote`, déjà présent en base.

À la sauvegarde, chaque `TourStop.actualPrestations` est figé avec les
snapshots du moment de validation (le snapshot peut différer du planned
snapshot si la prestation a été renommée/reprixée entre la création de la
tournée et le bilan — comportement voulu pour refléter ce qui a réellement
été facturé).

### Totaux du bilan

Récapitulatif similaire à celui du draft mais basé sur `actual` :

```
Bilan de la tournée
  Intervention réelle : X h Y min
  Revenu réalisé      : X €
  Frais déplacement   : X €  (figé depuis le draft, non recalculé)
  Net (indicatif)     : X €
```

Les frais de déplacement **ne sont pas recalculés** au bilan (la tournée a
été parcourue, les distances sont actées).

### Cascade sur le client

Helper :

```dart
List<AnimalCount> animalCountsFromPrestations(List<TourStopPrestation> ps) {
  final byCategory = <int, int>{};
  for (final p in ps) {
    if (p.categoryIdSnapshot == null) continue;  // libre = ignoré
    byCategory.update(
      p.categoryIdSnapshot!,
      (v) => v > p.qty ? v : p.qty,        // règle MAX
      ifAbsent: () => p.qty,
    );
  }
  return byCategory.entries
      .map((e) => AnimalCount(categoryId: e.key, count: e.value))
      .toList();
}
```

**Sémantique** :
- Une prestation **liée** à une catégorie contribue à `client.animals` (ex.
  « Tonte Mouton/Petit × 12 » → 12 Petit dans le compte du client à cette
  date).
- Une prestation **libre** ne contribue à aucun compteur d'animaux.
- Si plusieurs prestations bound à la **même catégorie** sont effectuées
  (« Tonte » + « Vermifuge » sur Petit), la **règle MAX** s'applique (12
  Petit, pas 24) — pour ne pas surcompter le cheptel d'un client juste
  parce qu'on lui fait deux prestations le même jour.

### `applyManualEntryToClient` / `recomputeClientFromHistory`

Inchangés dans leur principe (appliquer l'entrée la plus récente au client,
recalculer depuis l'union des sources), mais opèrent sur des
`List<AnimalCount>` dérivées via `animalCountsFromPrestations` :
- `lastInterventionDate` ← date de l'entrée si plus récente (inchangé).
- `client.animals` ← merge avec les compteurs dérivés.
- `recomputeClientFromHistory` recalcule depuis l'union (tournées
  complétées + entrées manuelles), avec MAX par catégorie sur **chaque
  source** mais en gardant l'**état de la source la plus récente** par
  catégorie (pas un merge cross-sources, comme aujourd'hui).

### `ManualHistoryEntrySheet`

Refonte parallèle : la sheet de saisie manuelle d'historique liste
désormais les prestations effectuées (avec qty). Mêmes pickers, mêmes
snapshots, même règle de dérivation des compteurs.

### `client_history_screen.dart`

La ligne d'historique d'une intervention devient :
```
🗓 12/04/2026
   3 prestations · 32 € · 1 h 15 min
   ▸ Tonte Petit × 12 · Tonte Grand × 4 · Vermifuge × 12
```

Le détail texte est tronqué si > 3 prestations (« … et 2 autres »). Tap sur
la ligne → tour → page tournée ; manuelle → sheet d'édition.

## l10n

Maintenir `app_fr.arb` et `app_en.arb` synchronisés. La liste exhaustive
sera produite à l'implémentation. Échantillon :

```
prestationCatalogTitle             = "Catalogue de prestations"
prestationCatalogCountFmt          = "{n} prestation(s) active(s)"
prestationCatalogAddCta            = "+ Ajouter une prestation"
prestationCatalogArchivedSection   = "Archivées"
prestationCatalogFreeGroup         = "Libres"

prestationFormName                 = "Nom"
prestationFormBindToCategory       = "Liée à une catégorie ?"
prestationFormSpecies              = "Espèce"
prestationFormCategory             = "Catégorie"
prestationFormPrice                = "Prix HT (€)"
prestationFormPriceHelper          = "Sera utilisé pour la facturation (#7)"
prestationFormMinutes              = "Durée (min)"
prestationFormMinutesHelper        = "Utilisée pour estimer la durée d'une tournée"
prestationFormSave                 = "Enregistrer"
prestationFormArchive              = "Archiver"
prestationFormUnarchive            = "Désarchiver"

prestationPickerTitleFmt           = "Prestations pour {client}"
prestationPickerSuggested          = "Suggérées"
prestationPickerOther              = "Autres"
prestationPickerEmptyValues        = "Prix/durée non renseignés"
prestationPickerCancel             = "Annuler"
prestationPickerValidate           = "Valider"

tourDraftStopNoPrestation          = "Aucune prestation"
tourDraftSummaryRevenue            = "Revenu : {amount}"
tourDraftSummaryNet                = "Net (indicatif) : {amount}"

tourCompletionAddOffPlan           = "+ Ajouter une prestation hors plan"
tourCompletionRevenueRealized      = "Revenu réalisé"

clientHistoryPrestationCountFmt    = "{n} prestation(s) · {amount} · {duration}"
```

Aucune clé existante supprimée. Le vocabulaire « intervention » est déjà
neutralisé (#5).

## Reset & migration

`schemaVersion: 11 → 12`. Pas de migration upgrade-path.

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 12) {
      for (final table in allTables.reversed) {
        await m.deleteTable(table.actualTableName);
      }
      await m.createAll();
    }
  },
);
```

Au prochain lancement post-bump, `Settings` est vide → le router redirige
vers `/onboarding`. L'utilisateur retraverse l'onboarding, et les
prestations seedées (selon les espèces qu'il active) sont insérées avec
prix/durée vides.

Note pour le commit qui bumpe le schéma : préciser explicitement « Reset
complet — drop+recreate toutes les tables, pas d'utilisateurs en prod ».

## Tests

Cible : ~140 → ~165 tests verts.

**Use cases purs** (priorité absolue) :
- `BuildTourDraft` — nouvelle signature, snapshots de prestation, calculs
  revenu + net.
- `TourDurationEstimator` — formule `Σ qty × minutesSnapshot`, contribution
  nulle si snapshot=0.
- `animalCountsFromPrestations` — règle MAX, exclusion des prestations
  libres, somme cross-stops.
- `normalizeTourStopPrestations` — drop qty<=0, tri stable.

**Repositories** :
- `PrestationRepository` (CRUD, archivage, listActive, listByCategory).
- `TourRepository.update` étendu : roundtrip plannedPrestations +
  actualPrestations.
- `ClientRepository.applyManualEntryToClient` &
  `recomputeClientFromHistory` (mis à jour pour opérer sur prestations
  dérivées).
- `ManualHistoryRepository` (roundtrip prestations).

**Converters** :
- `TourStopPrestationListConverter` — round-trip JSON, normalize.

**Widget** : au moins un test smoke sur `PrestationPickerSheet` (reproduit
suggested/other, qty pré-remplie).

## Acceptance criteria

- L'utilisateur peut créer/éditer/archiver des prestations dans
  Settings → Catalogue de prestations. Une prestation peut être liée à une
  catégorie ou libre.
- À l'activation d'une espèce seedée, les prestations par défaut
  (« Tonte » / « Parage » / « Onglons » selon l'espèce) sont créées avec
  prix/durée vides.
- À la création d'un draft de tournée, le user ouvre un picker par stop.
  Les prestations dont la catégorie matche les compteurs du client sont
  suggérées et cochées par défaut, qty pré-remplie. Les autres sont
  décochées et accessibles dans la même sheet.
- Un stop sans prestation reste valide (avertissement visuel) ; durée 0,
  revenu 0 sur ce stop.
- Le résumé du draft affiche durée d'intervention totale, revenu HT total,
  frais de déplacement, net indicatif. Lignes revenu/net masquées si
  revenu = 0.
- Au bilan, le user ajuste les qty des prestations planifiées, peut
  décocher (qty=0), et ajouter des prestations hors plan.
- Les compteurs d'animaux du client sont mis à jour selon la règle MAX par
  catégorie sur les prestations bound effectuées.
- L'historique d'un client (intervention en tournée ou saisie manuelle)
  affiche les prestations effectuées avec leurs snapshots.
- Renommer ou archiver une prestation ne casse pas l'historique.
- Schéma drift bumpé (11 → 12), drop+recreate au boot.
- Tous les tests existants migrés + nouveaux ajoutés au vert.

## Follow-ups (à inscrire au TODO)

- **#7 Facturation** débloquée par cette feature. Le `priceCentsSnapshot`
  sur `TourStopPrestation` est la source de la facturation. La TVA sera
  ajoutée comme attribut de prestation à ce moment-là.
- **Recherche dans le picker** si retour utilisateur en ce sens.
- **Stats / reporting revenu** comme ticket dédié.
- **Création de prestation à la volée** depuis le picker, si friction
  observée à l'usage.
