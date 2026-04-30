# Pivot multi-praticien — design

**Date:** 2026-04-30
**Scope:** Pivoter l'app d'un produit mono-vertical (tonte ovine) vers un produit
générique de praticien animalier itinérant. Choix d'espèces à l'onboarding,
catégories d'animaux personnalisables, vocabulaire neutralisé, logo de l'app
au choix.

## Goal

Tout praticien animalier itinérant — tondeur ovin, dentiste équin, ostéo,
maréchal-ferrant, vétérinaire de campagne, parage caprin… — doit pouvoir
utiliser l'app pour gérer ses clients et ses tournées, sans que le vocabulaire
ou les compteurs présupposent une activité ovine.

## Scope

**In scope :**
- Modèle de domaine `Species` / `AnimalCategory` / compteurs d'animaux par
  catégorie sur `Client`, `TourStop`, `ManualHistoryEntry`.
- Refonte de l'onboarding en wizard 2 étapes (adresse / espèces+avatar).
- Nouvel écran Settings « Espèces & catégories » avec CRUD complet (ajouter,
  renommer, archiver, désarchiver) sur espèces et catégories.
- Logo de l'app personnalisable (set curated d'icônes `FIcons`, modifiable à
  l'onboarding et dans Settings).
- Neutralisation du vocabulaire : « tonte » → « intervention », « moutons » →
  « animaux » dans la l10n et le code (fr + en synchronisés).
- Reset complet des données via `schemaVersion: 8 → 9` (drop+recreate, pas
  d'utilisateurs en prod).

**Out of scope :**
- Migration des données existantes : aucun chemin de remap, on assume zéro user.
- Rebrand `Coup'Laine` → autre nom : ticket dédié à inscrire au TODO (#8).
- Catalogue de prestations / facturation : c'est #6 et #7. Les colonnes
  `defaultMinutes` / `defaultPriceCents` sur `AnimalCategory` sont préparées
  mais leur sémantique finale (par catégorie vs par couple
  `interventionType × catégorie`) sera tranchée en #6.
- Tutoriel post-onboarding pour inviter à remplir les durées/prix : follow-up.
- Filtre par espèce dans les pickers de tournée : follow-up.
- Saisie d'avatars custom (upload d'image) : non prévue, on reste sur
  `FIcons` curated.
- Étape onboarding pour saisir durées et prix par catégorie : volontairement
  pas demandée. Les seeds n'ont pas de valeurs ; le user les remplit plus
  tard.

## Approach

Pivot dur, green-field. Le concept ovin disparaît du code, du schéma et de
la l10n sauf quand le user a explicitement activé l'espèce « Mouton » à
l'onboarding. La hiérarchie est `Species → AnimalCategory`, avec compteurs
d'animaux stockés en JSON (cohérence avec le pattern `phones` déjà en place).
Snapshots des noms et minutes embarqués dans les JSON de `tour_stops` et
`manual_history_entries` pour préserver l'historique en cas de
renommage/archivage.

## Architecture & modèle de domaine

### Nouvelles entités

```dart
// lib/domain/models/species.dart
class Species {
  final int id;
  final String name;
  final String? iconKey;       // optionnel, pour future iconographie
  final DateTime? archivedAt;  // soft-delete
}

// lib/domain/models/animal_category.dart
class AnimalCategory {
  final int id;
  final int speciesId;
  final String name;
  final int? defaultMinutes;
  final int? defaultPriceCents;
  final DateTime? archivedAt;
}

// lib/domain/models/animal_count.dart
class AnimalCount {
  final int categoryId;
  final int count;
}

// lib/domain/models/tour_stop_animal.dart
class TourStopAnimal {
  final int categoryId;
  final int count;
  final String categoryNameSnapshot;
  final String speciesNameSnapshot;
  final int minutesSnapshot;     // 0 si non renseigné au moment du snapshot
}
```

### Mutations sur les entités existantes

`Client` perd `sheepCountSmall`, `sheepCountLarge`, `sheepCountTotal`. Gagne
`final List<AnimalCount> animals`.

`TourStop` perd `plannedSmall`, `plannedLarge`, `actualSmall`, `actualLarge`,
`minutesPerSmallSnapshot`, `minutesPerLargeSnapshot`. Gagne :
- `final List<TourStopAnimal> planned`
- `final List<TourStopAnimal>? actual` (nullable, rempli au bilan)

`ManualHistoryEntry` perd `sheepCountSmall`, `sheepCountLarge`. Gagne
`final List<TourStopAnimal> animals` (réutilise le même type que `TourStop`
pour bénéficier des snapshots).

`Settings` perd `defaultMinutesPerSmall`, `defaultMinutesPerLarge` (vivent
désormais sur `AnimalCategory`). Renomme `markerNoSheepColor` →
`markerNoAnimalsColor`. Ajoute `appAvatarKey: String?` (clé d'avatar choisie
par le user).

### Catégories archivées

- En **saisie** : les catégories archivées sont masquées des pickers, des
  formulaires de compteurs, des écrans de bilan.
- En **lecture** : les snapshots dans `tour_stops` / `manual_history_entries`
  affichent les noms snapshotés (par construction). Sur `Client.animals`, les
  comptes attachés à une catégorie archivée sont regroupés dans une section
  « Catégories archivées » en lecture seule, avec un bouton « Effacer ».

### Espèce par défaut interdite à supprimer

Une espèce ne peut pas être archivée si elle est la seule active. Bouton
désactivé + tooltip. Sinon les pickers seraient vides et l'app non
fonctionnelle.

## Schéma Drift

`schemaVersion: 8 → 9`. Drop+recreate via `onUpgrade` (voir section
« Reset & migration »).

### Nouvelles tables

```dart
@DataClassName('SpeciesRow')
class SpeciesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get iconKey => text().nullable()();
  IntColumn get archivedAt => integer().nullable()();  // epoch ms
  IntColumn get createdAt => integer()();
}

@DataClassName('AnimalCategoryRow')
class AnimalCategoriesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get speciesId => integer()
      .references(SpeciesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get defaultMinutes => integer().nullable()();
  IntColumn get defaultPriceCents => integer().nullable()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}
```

### Tables modifiées

`ClientsTable` :
- Supprimées : `sheepCountSmall`, `sheepCountLarge`.
- Ajoutée : `TextColumn animals` (JSON via `AnimalCountListConverter`,
  défaut `'[]'`).

`TourStopsTable` :
- Supprimées : `plannedSmall`, `plannedLarge`, `actualSmall`, `actualLarge`,
  `minutesPerSmallSnapshot`, `minutesPerLargeSnapshot`.
- Ajoutées :
  - `TextColumn plannedAnimals` (JSON via `TourStopAnimalListConverter`,
    défaut `'[]'`).
  - `TextColumn actualAnimals` (JSON via `TourStopAnimalListConverter`,
    nullable).

`ManualHistoryEntriesTable` :
- Supprimées : `sheepCountSmall`, `sheepCountLarge`.
- Ajoutée : `TextColumn animals` (JSON via `TourStopAnimalListConverter`,
  défaut `'[]'`).

`SettingsTable` :
- Supprimées : `defaultMinutesPerSmall`, `defaultMinutesPerLarge`.
- Renommée : `markerNoSheepColor` → `markerNoAnimalsColor`.
- Ajoutée : `TextColumn appAvatarKey` (nullable).

### Format JSON des converters

```jsonc
// AnimalCountListConverter — utilisé sur clients.animals
[
  {"categoryId": 1, "count": 5},
  {"categoryId": 4, "count": 12}
]

// TourStopAnimalListConverter — utilisé sur tour_stops et manual_history_entries
[
  {
    "categoryId": 1,
    "count": 5,
    "categoryNameSnapshot": "Petit",
    "speciesNameSnapshot": "Mouton",
    "minutesSnapshot": 8
  }
]
```

### Helpers de normalisation

`normalizeAnimalCounts(List<AnimalCount>)` (analogue à `normalizePhones`) :
- Supprime les entrées avec `count <= 0`.
- Dédupe par `categoryId` (somme des doublons).
- Tri stable par `categoryId`.

`normalizeTourStopAnimals(List<TourStopAnimal>)` : même logique sur le
champ `categoryId`.

Tous les writes passent par ces helpers.

## Onboarding (wizard 2 étapes)

Refonte d'`OnboardingScreen` en `StatefulWidget` qui gère le wizard
en interne (pas de routes additionnelles, `IndexedStack` sur `_step`).

### Étape 1 — Adresse de base

Quasi identique à l'écran actuel :
- Hero illustration : remplacer `assets/illustrations/sheep-mascot.png` par
  un visuel neutre temporaire (à choisir : icône `FIcons.compass` à grande
  taille, ou ne rien afficher, ou un placeholder à dessiner — à trancher
  pendant l'implémentation, faible enjeu).
- `AppSectionCard` « Bienvenue » (texte de bienvenue).
- `AppSectionCard` « Adresse de départ » avec `AddressAutocompleteField`.
- CTA principal « Suivant » (l10n `onboardingStep1Cta`), actif si une
  adresse a été sélectionnée.

### Étape 2 — Espèces & avatar

Trois blocs :

1. **`AppSectionCard` « Vos espèces »**
   - Liste des 4 espèces seedées (Mouton, Cheval, Bovin, Caprin) sous forme
     de tuiles cochables. Sous chaque tuile, un sous-texte listant les
     catégories par défaut (ex. « Petit, Grand »).
   - Bouton discret en bas : « + Ajouter une espèce personnalisée ». Ouvre
     un sheet `CustomSpeciesFormSheet` qui demande :
     - Nom de l'espèce (obligatoire).
     - Liste des catégories : au moins une obligatoire pour valider. Chaque
       catégorie n'a qu'un nom à ce stade (durées/prix vides, à remplir
       plus tard dans Settings).
   - Validation du sheet → ajoute l'espèce custom à la liste, case déjà
     cochée.

2. **`AppSectionCard` « Logo de l'app »**
   - Bandeau scrollable horizontal de chips d'icônes. Six choix curated :
     `FIcons.compass`, `FIcons.map`, `FIcons.scissors`, `FIcons.stethoscope`,
     `FIcons.hammer`, `FIcons.heart`.
   - Sélection unique. Sélection par défaut : `FIcons.compass` (clé
     `'compass'`).

3. **CTA principal « Terminer »** — actif si **au moins une espèce activée**
   (cochée parmi les seeds **ou** ajoutée en custom). Bloqué si aucune.

### Persistance à la confirmation

Dans une `transaction` :

1. Pour chaque espèce cochée parmi les seeds : insérer le `SpeciesRow` puis
   ses `AnimalCategoryRow` correspondantes.
2. Pour chaque espèce custom : insérer le `SpeciesRow` puis ses catégories
   custom.
3. Persister `Settings` : `baseCoordinates`, `baseAddressLabel`,
   `seasonStartedAt: DateTime.now()`, `appAvatarKey`.
4. `context.go('/clients')`.

### Navigation arrière

Bouton « Précédent » en haut à gauche de l'étape 2 → retour à l'étape 1.
Tout l'état (espèces cochées, espèces custom, avatar, adresse) est
préservé en mémoire. Pas de reset.

### Espèces seedées (constantes côté code)

`lib/data/seeds/species_seeds.dart` :

```dart
class SpeciesSeed {
  final String name;
  final List<CategorySeed> categories;
  const SpeciesSeed({required this.name, required this.categories});
}

class CategorySeed {
  final String name;
  const CategorySeed({required this.name});
}

const kSpeciesSeeds = <SpeciesSeed>[
  SpeciesSeed(name: 'Mouton', categories: [
    CategorySeed(name: 'Petit'),
    CategorySeed(name: 'Grand'),
  ]),
  SpeciesSeed(name: 'Cheval', categories: [
    CategorySeed(name: 'Poulain'),
    CategorySeed(name: 'Adulte'),
  ]),
  SpeciesSeed(name: 'Bovin', categories: [
    CategorySeed(name: 'Veau'),
    CategorySeed(name: 'Adulte'),
  ]),
  SpeciesSeed(name: 'Caprin', categories: [
    CategorySeed(name: 'Chèvre'),
  ]),
];
```

Aucune valeur de durée ni de prix dans le seed. Le user les renseigne plus
tard (dans Settings, ou via un futur tuto post-onboarding inscrit comme
follow-up).

## Settings : gestion des espèces & catégories

### Restructuration de `SettingsScreen`

Nouvel ordre vertical des sections :
1. Apparence (avec ajout d'un bloc « Logo de l'app »).
2. **Espèces & catégories** *(nouveau)*.
3. Adresse de base.
4. Valeurs par défaut *(épuré)*.
5. Marqueurs *(libellé `markerNoSheep` → `markerNoAnimals`)*.
6. Saison.
7. Données.

#### Bloc « Logo de l'app » (dans Apparence)

Bandeau scrollable horizontal identique à celui de l'onboarding. Sélection
courante mise en évidence. Tap → met à jour `Settings.appAvatarKey`
immédiatement.

#### Bloc « Espèces & catégories »

Carte cliquable :
- Titre : « Espèces & catégories ».
- Sous-texte : « X espèce(s) · Y catégorie(s) actives »
  (l10n `speciesManagementCountFmt`).
- Tap → `context.push('/settings/species')`.

#### Restructuration de « Valeurs par défaut »

Avant :
- Rayon par défaut (km)
- Minutes par Ouessant/Lande *(supprimé)*
- Minutes par Grande Race *(supprimé)*
- Tarif déplacement (€ / 10 km)

Après :
- Rayon par défaut (km)
- Tarif déplacement (€ / 10 km)
- Tranche kilométrique (km) *(exposition de `bracketKm` qui existait déjà)*

### `SpeciesManagementScreen` (route `/settings/species`)

Liste verticale :
- Section « Actives » : carte par espèce active. Chaque carte affiche le
  nom, le compte de catégories actives, et un menu contextuel `⋮`
  (Renommer, Archiver, Désarchiver).
- Section « Archivées » : repliable, affiche les espèces archivées avec
  l'option Désarchiver.

Tap sur une carte → push vers `SpeciesEditScreen(speciesId)`.

En bas :
- Bouton primaire « + Ajouter une espèce » (sheet identique à l'onboarding).
- Lien discret « Restaurer un template » : ouvre un sheet listant les
  espèces de `kSpeciesSeeds` qui ne sont pas déjà présentes (par nom). Tap
  sur une → insertion immédiate de l'espèce et de ses catégories par défaut.

### `SpeciesEditScreen` (route `/settings/species/:id`)

Trois zones :

1. **Identité espèce** : `TextField` nom (édition inline), bouton
   « Archiver l'espèce » (désactivé avec tooltip si c'est la seule espèce
   active).
2. **Catégories** : liste des catégories de l'espèce. Pour chacune :
   - Nom (édition inline).
   - Durée par défaut en minutes (numeric input, vide autorisé).
   - Prix indicatif HT en euros (numeric input, vide autorisé). Helper
     text : « Sera utilisé pour la facturation à venir. »
   - Bouton « Archiver ».
3. **Bouton « + Ajouter une catégorie »** → sheet `AnimalCategoryFormSheet`
   avec les trois champs (nom obligatoire, minutes/prix optionnels).

### Règles de validation

- Au moins une espèce active à tout moment.
- Une catégorie peut être archivée même si elle est la dernière de son
  espèce.
- Renommer ne casse pas l'historique (snapshots).
- Pas de hard-delete dans cette spec, partout. Pas de fusion. Pas de
  déplacement entre espèces.

## Refactor des consommateurs

### `client_form_screen.dart`

- Section `clientFormSectionShearing` (« Tonte ») renommée
  `clientFormSectionAnimals` (« Animaux »).
- Les deux `TextField` numériques fixes remplacés par un widget
  `AnimalCountsEditor` :
  - Liste les espèces actives (non archivées).
  - Sous chaque espèce, ses catégories actives sous forme d'une ligne
    label + numeric input.
  - Repli par espèce (accordéon, première ouverte par défaut).
  - Section « Catégories archivées » en lecture seule pour les counts > 0
    sur des catégories archivées, avec bouton « Effacer ».
- À la sauvegarde, `client.animals` est normalisé via
  `normalizeAnimalCounts` (drop des `count == 0`).

### `client_detail_screen.dart`, `clients_list_screen.dart`, `client_pin_popup.dart`

- Suppression de `clientDetailSheepCountFmt`, `clientsListSheepCountFmt`.
- Nouveau widget `AnimalCountsBadges` avec deux modes :
  - `compact` : somme par espèce (ex. « 17 Mouton, 4 Cheval ») — utilisé
    en liste clients et dans le pin popup.
  - `detailed` : par catégorie regroupée par espèce (ex. « Mouton —
    5 Petit + 12 Grand ») — utilisé sur la fiche détail.
- Cas zéro animal : affichage vide (pas de « 0 moutons »).

### `tour_manual_picker_screen.dart`, `waiting_clients_multi_picker.dart`

- Affichage par client via `AnimalCountsBadges` en mode `compact`.
- Pas de filtre par espèce dans cette release (follow-up).

### `tour_draft_screen.dart`, `tour_draft_controller.dart`, `BuildTourDraft`

- `BuildTourDraft` construit `tourStop.planned` à partir de `client.animals` :
  pour chaque `AnimalCount` du client, un `TourStopAnimal` avec :
  - `categoryId` du compteur
  - `count` du compteur
  - `categoryNameSnapshot` = nom courant de la catégorie (lookup)
  - `speciesNameSnapshot` = nom courant de l'espèce parente
  - `minutesSnapshot` = `category.defaultMinutes ?? 0`
- Résumé `tourDraftSummaryTotal` : remplacer le mot « Tonte » par
  « Intervention » dans le pattern. Le calcul `{shear}` reste la somme des
  minutes intervention sur tous les stops.

### `tour_duration_estimator.dart`

Nouvelle formule :
```
Σ stops ( Σ animals (animal.count × animal.minutesSnapshot) ) + drive_time
```
Si `minutesSnapshot == 0` (catégorie non renseignée), contribution nulle.
Tour estimé = pure `drive_time` jusqu'à ce que le user remplisse les
minutes.

### `tour_completion_screen.dart`

- Les deux `TextField` `actualSmall` / `actualLarge` remplacés par un
  éditeur miroir basé sur `AnimalCountsEditor` :
  - Itère sur les **catégories du planned** (pas toutes les catégories
    actives) — pré-rempli avec les valeurs planned.
  - Le user ajuste les counts réels.
- Bouton « + Autre catégorie » sous l'éditeur pour gérer le cas où une
  catégorie non planifiée a été traitée. Ouvre un sheet pour choisir une
  catégorie active et saisir un count. À la confirmation, ajoute une ligne
  à l'éditeur.
- À la sauvegarde, `tourStop.actual = [...]` est persisté avec les mêmes
  snapshots que `planned`.

### `manual_history_entry_sheet.dart`

- Refonte : les deux `TextField` numériques remplacés par
  `AnimalCountsEditor` (mode saisie sans pré-rempli).
- À la sauvegarde, `entry.animals: List<TourStopAnimal>` est persisté avec
  les snapshots.

### `client_repository.dart` — `applyManualEntryToClient`, `recomputeClientFromHistory`

Logique inchangée dans son principe (appliquer l'entrée la plus récente au
client, recalculer depuis l'union des sources), mais opère sur
`List<AnimalCount>` au lieu de deux entiers. Le merge se fait par
`categoryId` (la valeur la plus récente l'emporte par catégorie ; les
catégories absentes de l'entrée ne sont pas touchées si on est en mode
« apply latest », recalculées entièrement si on est en mode
« recompute from history »).

### `client_history_screen.dart`

- Ligne d'historique : `AnimalCountsBadges` en mode `detailed`.
- Suppression de `clientDetailHistoryItemFmt`.

### `client_status.dart`

- Statut `noSheep` → `noAnimals` (renommer la valeur de l'enum côté code).
- Logique : `client.animals.isEmpty || client.animals.every((a) => a.count == 0)`.

### Tests

- Helper de fixture `seedTestSpeciesAndCategories(db)` à créer pour poser
  un set canonique en début de test (2 espèces, 4 catégories typiques).
- Tous les tests qui construisent `Client` / `TourStop` /
  `ManualHistoryEntry` doivent migrer vers la nouvelle API. Estimation
  ~15-20 fichiers existants à mettre à jour.
- Nouveaux tests :
  - `AnimalCountListConverter` (round-trip JSON, normalize).
  - `TourStopAnimalListConverter` (idem).
  - `normalizeAnimalCounts` (dedup, sort, drop zero).
  - `AnimalCountsEditor` (widget — au moins un test smoke vu la base
    actuelle quasi vide en widget tests).
  - `BuildTourDraft` : snapshots `categoryName`, `speciesName`,
    `minutesSnapshot`.
  - `TourDurationEstimator` : sum sur N catégories ; comportement avec
    `minutesSnapshot == 0`.
  - `recomputeClientFromHistory` : merge par `categoryId`.

## l10n & vocabulaire

Maintenir `app_fr.arb` et `app_en.arb` synchronisés.

### Clés supprimées

- `helloDebug` (résiduel de la genèse).
- `clientFormSheepCountSmall`, `clientFormSheepCountLarge` (les libellés
  vivent désormais en data, dans les noms de catégorie).
- `clientDetailSheepCountFmt`, `clientsListSheepCountFmt` (remplacées par
  `AnimalCountsBadges`).
- `clientDetailHistoryItemFmt` (remplacée par `AnimalCountsBadges`).
- `manualEntrySmallLabel`, `manualEntryLargeLabel` (catégories en data).
- `settingsMinPerSmallLabel`, `settingsMinPerLargeLabel` (vivent sur
  `AnimalCategory`).

### Clés renommées

- `clientFormSectionShearing` → `clientFormSectionAnimals` (« Animaux »).
- `clientStatusNoSheep` → `clientStatusNoAnimals` (« Sans animaux »).
- `settingsMarkerNoSheep` → `settingsMarkerNoAnimals` (« Sans animaux »).
- `clientHistoryAddAction` : « Ajouter une tonte » → « Ajouter une
  intervention ».
- `manualEntrySheetTitleCreate` : « Ajouter une tonte » → « Ajouter une
  intervention ».
- `manualEntrySheetTitleEdit` : « Modifier la tonte » → « Modifier
  l'intervention ».
- `tourDraftSummaryTotal` : remplacer « Tonte : {shear} » par
  « Intervention : {shear} ».

### Clés inchangées

- `appTitle = "Coup'Laine"` (rebrand reporté à #8).
- `tourCompletionTitle = "Bilan d'intervention"` (déjà neutre).
- `clientDetailSectionHistory = "Historique des interventions"` (déjà
  neutre).

### Nouvelles clés (échantillon ; la liste exhaustive sera produite
durant l'implémentation)

```
onboardingStep1Title
onboardingStep1Cta                 = "Suivant"
onboardingStep2Title               = "Vos espèces"
onboardingStep2Subtitle            = "Sélectionnez les espèces que vous traitez"
onboardingAvatarTitle              = "Logo de l'app"
onboardingAvatarSubtitle           = "Choisissez votre identité visuelle"
onboardingAddCustomSpecies         = "+ Ajouter une espèce personnalisée"
onboardingCtaFinish                = "Terminer"
onboardingErrorNoSpecies           = "Sélectionnez au moins une espèce"

speciesManagementTitle             = "Espèces & catégories"
speciesManagementCountFmt          = "{species} espèce(s) · {categories} catégorie(s) actives"
speciesManagementAddSpecies        = "+ Ajouter une espèce"
speciesManagementRestoreTemplate   = "Restaurer un template"
speciesManagementArchivedSection   = "Archivées"

speciesEditTitleFmt                = "Modifier {name}"
speciesEditCategoriesTitle         = "Catégories"
speciesEditAddCategory             = "+ Ajouter une catégorie"
speciesEditArchive                 = "Archiver l'espèce"
speciesEditUnarchive               = "Désarchiver l'espèce"
speciesEditArchiveBlocked          = "Au moins une espèce active est requise"

categoryFormName                   = "Nom"
categoryFormDefaultMinutes         = "Durée par défaut (min)"
categoryFormDefaultPrice           = "Prix indicatif HT (€)"
categoryFormPriceHelper            = "Sera utilisé pour la facturation à venir"
categoryFormSave                   = "Enregistrer"
categoryFormArchive                = "Archiver"

animalCountsEditorEmpty            = "Aucune espèce active"
animalCountsArchivedSection        = "Catégories archivées"
animalCountsClear                  = "Effacer"

clientsListAnimalCountFmt          = "{n} {species}"
clientDetailAnimalCategoryFmt      = "{count} {category}"
```

### Avatars de l'app

`appAvatarKey` est une chaîne mappée à un `IconData` via une fonction pure
`iconForAvatarKey(String? key)` dans `lib/core/avatar_icons.dart`. Six clés :
`compass`, `map`, `scissors`, `stethoscope`, `hammer`, `heart`. Défaut :
`compass`.

## Reset & migration

`schemaVersion: 8 → 9`. Pas de migration upgrade-path.

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 9) {
      // Reset complet — pas d'utilisateurs en prod.
      for (final table in allTables.reversed) {
        await m.deleteTable(table.actualTableName);
      }
      await m.createAll();
    }
  },
);
```

Au prochain lancement post-bump, `Settings` est vide → le router redirige
vers `/onboarding`. L'utilisateur retraverse l'onboarding (étape 1 + 2).
Les espèces seedées vivent comme constantes côté code
(`kSpeciesSeeds`) ; rien n'est inséré en base tant que l'utilisateur n'a
rien coché.

Note pour le commit qui bumpe le schéma : préciser explicitement « Reset
complet — drop+recreate toutes les tables, pas d'utilisateurs en prod ».

## Acceptance criteria

- À l'install fraîche, l'utilisateur arrive sur l'onboarding étape 1
  (adresse).
- À l'étape 2, il peut cocher Mouton, Cheval, Bovin, Caprin, et/ou ajouter
  une espèce custom avec au moins une catégorie. Il peut choisir un
  avatar parmi six. Le CTA est inactif tant qu'aucune espèce n'est
  activée.
- Après onboarding, le user peut créer un client, lui assigner des
  compteurs par catégorie pour les espèces qu'il a activées. Les
  catégories archivées n'apparaissent pas en saisie.
- Le user peut composer une tournée, voir les compteurs corrects sur
  chaque stop, marquer la tournée comme réalisée et ajuster les counts
  réels par catégorie (y compris ajouter une catégorie hors-planning).
- Le user peut ajouter une saisie manuelle d'historique avec compteurs
  par catégorie. Les règles métier existantes (`applyManualEntryToClient`,
  recomputeClientFromHistory, statut `done` saison) continuent à
  fonctionner sur les nouvelles structures.
- Le user peut renommer / archiver / désarchiver une espèce ou une
  catégorie depuis Settings → Espèces & catégories. Une espèce ne peut
  pas être archivée si elle est la dernière active.
- L'historique d'un client (intervention en tournée ou saisie manuelle)
  affiche les noms snapshotés au moment de l'écriture, même après
  renommage d'une catégorie.
- Le statut `noAnimals` se déclenche quand `client.animals` est vide ou
  ne contient que des comptes nuls.
- Aucune occurrence de « tonte » ou « mouton » dans la l10n hors le
  `appTitle` et hors les noms de catégorie/espèce que le user a saisis.
- Tests verts : tous les tests existants migrés + les nouveaux ajoutés.

## Follow-ups (à inscrire au TODO)

- **#8 Rebrand `Coup'Laine`** : nouveau nom, mascotte, splash, icônes
  natives. Brainstorm dédié.
- **Tutoriel post-onboarding** invitant le user à renseigner les
  durées/prix par catégorie.
- **Filtre par espèce** dans les pickers de tournée.
- **Avatars custom** (upload d'image) si demande user.
