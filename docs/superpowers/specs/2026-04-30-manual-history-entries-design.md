# Manual History Entries — Design

**Date :** 2026-04-30
**Auteur :** Raphaël Gauthier (with Claude)

## Contexte

Aujourd'hui, l'historique d'un client (`ClientHistoryScreen`) est une vue **dérivée** des `tour_stops` appartenant à des `tours` au statut `completed` (cf. `ClientRepository.listInterventionsForClient`). Conséquence : impossible de saisir une tonte qui n'est pas passée par une tournée créée dans l'app.

Cas d'usage cible : **backfill** — l'utilisateur arrive avec des années de tontes passées (avant l'app) et veut les saisir rétroactivement pour conserver l'historique de chaque client.

Cette feature ajoute une seconde source d'historique — des **entrées manuelles** — fusionnée avec l'historique dérivé des tournées.

## Règles métier

- Une entrée manuelle porte : `clientId`, `date` (jour), `small` (petits moutons), `large` (grands moutons), `note?` (texte libre).
- Les entrées manuelles sont **CRUD complet** (créer / éditer / supprimer). Les lignes d'historique issues de tournées restent **immuables** comme aujourd'hui.
- Quand on **crée** une entrée manuelle :
  - Si `entry.date > client.lastShearingDate` (ou `lastShearingDate == null`) → on met à jour `client.lastShearingDate`, `client.sheepCountSmall`, `client.sheepCountLarge`.
  - Sinon → on ne touche pas à l'état du client.
- Une entrée manuelle dont la `date >= seasonStartedAt` doit faire compter le client comme **« tondu cette saison »** (statut `done`), au même titre qu'un `tour_stop` issu d'une tournée `completed`.
- Quand on **édite** ou **supprime** une entrée manuelle, on **recalcule** l'état dénormalisé du client (voir « Recalcul » plus bas) — pour préserver l'invariant « lastShearingDate = max(date) sur l'union manual + tour-stops completed ».

## Architecture

**Stockage** : nouvelle table Drift `manual_history_entries` séparée. Pas de tour synthétique.

**Lecture** : `ClientRepository.listInterventionsForClient` charge les deux sources (tour_stops `completed` + manual_entries) et les fusionne en mémoire, triées par date desc.

**Modèle domaine** : `Intervention` étendu avec un discriminant `kind`. Les champs spécifiques au tour (`tourId`, `stopId`) deviennent nullable ; un nouveau champ `manualEntryId` est rempli pour les entrées manuelles.

## Schéma de base de données

**Migration `schemaVersion: 6 → 7`** dans `lib/infra/db/app_database.dart`.

### Nouvelle table `manual_history_entries`

```dart
@DataClassName('ManualHistoryEntryRow')
class ManualHistoryEntriesTable extends Table {
  @override
  String get tableName => 'manual_history_entries';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get clientId => integer()
      .references(ClientsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get date => integer()();          // epoch days (cohérent avec tours.plannedDate)
  IntColumn get small => integer().withDefault(const Constant(0))();
  IntColumn get large => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();     // epoch ms
  IntColumn get updatedAt => integer()();     // epoch ms
}
```

Index sur `client_id` (créé en SQL brut dans la migration).

### Enregistrement et migration

Ajouter `ManualHistoryEntriesTable` dans l'annotation `@DriftDatabase(tables: [...])` de `AppDatabase`.

Le projet utilise le pattern manuel `onUpgrade(m, from, to)` avec des blocs `if (from < N)` (cf. `app_database.dart`). On ajoute un bloc :

```dart
if (from < 7) {
  await m.createTable(manualHistoryEntriesTable);
  await customStatement(
    'CREATE INDEX idx_manual_history_client '
    'ON manual_history_entries(client_id)',
  );
}
```

Les FK cascade fonctionnent grâce au `PRAGMA foreign_keys = ON` déjà posé dans `beforeOpen`.

## Modèle domaine

### `Intervention` (modifié)

```dart
enum InterventionKind { tour, manual }

class Intervention {
  final InterventionKind kind;
  final int? tourId;          // non-null si kind == tour
  final int? stopId;          // non-null si kind == tour
  final int? manualEntryId;   // non-null si kind == manual
  final DateTime date;
  final int small;
  final int large;
  final String? note;
  final bool hasBilan;        // true pour kind == manual ; déjà calculé pour kind == tour
  ...
}
```

### Nouveau modèle `ManualHistoryEntry`

```dart
class ManualHistoryEntry {
  final int id;
  final int clientId;
  final DateTime date;
  final int small;
  final int large;
  final String? note;
}
```

## Repositories

### Nouveau `ManualHistoryRepository`

Fichier `lib/data/repositories/manual_history_repository.dart`.

- `Future<int> insert({clientId, DateTime date, int small, int large, String? note})`
- `Future<void> update(int id, {DateTime date, int small, int large, String? note})`
- `Future<void> delete(int id)`
- `Future<List<ManualHistoryEntry>> listForClient(int clientId)` — trié par `date` desc
- `Future<List<({int clientId, int dateEpochDays})>> listClientDatesSinceEpochDays(int seasonEpochDays)` — alimente `listAllWithStatus`

### `ClientRepository` (modifs)

**`listInterventionsForClient(int clientId)`** : requête tour_stops `completed` (existant) **+** appel à `manualHistoryRepository.listForClient`. Merge en mémoire → tri par `date` desc. Construit chaque `Intervention` avec son `kind`.

**`listAllWithStatus(DateTime seasonStartedAt)`** : en plus du scan actuel, charge `manualHistoryRepository.listClientDatesSinceEpochDays(seasonEpochDays)` et ajoute chaque `clientId` à `hasCompleted`. Idem pour `findByIdWithStatus`.

**Nouveau `applyManualEntryToClient(int clientId, {DateTime date, int small, int large})`** :
1. Lit le client.
2. Si `client.lastShearingDate == null || date.millisecondsSinceEpoch > client.lastShearingDate.millisecondsSinceEpoch` → écrit `lastShearingDate`, `sheepCountSmall`, `sheepCountLarge`, `updatedAt`.
3. Sinon → no-op.

**Nouveau `recomputeClientFromHistory(int clientId)`** :
1. Charge **toutes** les sources d'historique du client : tour_stops `completed` (avec `actual_*` ou planned snapshots, comme dans `listInterventionsForClient`) + manual_entries.
2. Prend la source à la `date` la plus grande.
3. Si elle existe → met à jour `lastShearingDate`, `sheepCountSmall`, `sheepCountLarge`, `updatedAt` à partir d'elle.
4. Si aucune source → `lastShearingDate = null`, **on laisse les compteurs `sheepCountSmall/Large` tels quels** (pas de "valeur d'origine" à restaurer).

### Orchestration

Le **sheet** de saisie n'appelle pas directement `applyManualEntryToClient` / `recomputeClientFromHistory` — c'est le rôle d'un orchestrateur dans le sheet (côté présentation) ou, mieux, d'un wrapper côté repository :

- Après `ManualHistoryRepository.insert(...)` → appel `ClientRepository.applyManualEntryToClient(...)`.
- Après `ManualHistoryRepository.update(...)` → appel `ClientRepository.recomputeClientFromHistory(...)`.
- Après `ManualHistoryRepository.delete(...)` → appel `ClientRepository.recomputeClientFromHistory(...)`.

Ces appels enchaînés vivent dans le contrôleur Riverpod du sheet (pas de transaction Drift cross-repos pour l'instant — les deux repos partagent la même `AppDatabase`, on garde la simplicité).

## UI

### `ClientHistoryScreen` (modifs)

- **Header** : action `+` (FButton.icon dans `FHeader.nested.actions`) → ouvre `ManualHistoryEntrySheet` en mode création.
- **Liste** : pour chaque ligne `kind == manual`, affiche un `FBadge` discret « saisie manuelle » à côté de la date.
- **Tap** :
  - `kind == tour` → `context.push('/tours/${tourId}')` (inchangé).
  - `kind == manual` → ouvre `ManualHistoryEntrySheet` en mode édition, préremplie.

### `ClientDetailScreen` (modifs)

- Ajout d'un bouton/lien « Ajouter une tonte » sous le raccourci « Voir l'historique » → ouvre le même sheet en mode création.

### Nouveau `ManualHistoryEntrySheet`

Fichier `lib/presentation/clients/manual_history_entry_sheet.dart`.

- Présenté via `showFSheet` (bottom sheet).
- Modes :
  - `create({clientId})` → titre « Ajouter une tonte », bouton « Enregistrer ».
  - `edit({entry})` → titre « Modifier la tonte », champs préremplis, boutons « Enregistrer » + « Supprimer ».
- Champs :
  - **Date** — bouton qui ouvre un date picker. Pas de valeur par défaut. Validation : requise.
  - **Petits moutons** — FTextField numérique, default `0`, min 0.
  - **Grands moutons** — FTextField numérique, default `0`, min 0.
  - **Note** — FTextField multiligne, optionnel.
- Bouton « Supprimer » → FDialog de confirmation avant l'appel `delete`.
- Après save/delete : ferme le sheet, invalide les providers concernés (cf. ci-dessous), affiche un toast/snack de confirmation (réutiliser le pattern existant — sinon le supprimer du scope).

### Localisation

Nouvelles clés dans `lib/l10n/app_localizations_fr.dart` et `_en.dart` :

- `clientHistoryAddAction` — « Ajouter une tonte » / « Add a shearing »
- `clientHistoryManualBadge` — « saisie manuelle » / « manual entry »
- `manualEntrySheetTitleCreate` — « Ajouter une tonte » / « Add a shearing »
- `manualEntrySheetTitleEdit` — « Modifier la tonte » / « Edit shearing »
- `manualEntryDateLabel` — « Date »
- `manualEntrySmallLabel` — « Petits moutons » / « Small sheep »
- `manualEntryLargeLabel` — « Grands moutons » / « Large sheep »
- `manualEntryNoteLabel` — « Note »
- `manualEntrySave` — « Enregistrer » / « Save »
- `manualEntryDelete` — « Supprimer » / « Delete »
- `manualEntryDeleteConfirm` — « Supprimer cette entrée ? Cette action est irréversible. » / equivalent EN

## État / providers

Modifs dans `lib/state/providers.dart` :

- Nouveau `manualHistoryRepositoryProvider` exposant `ManualHistoryRepository(_db)`.
- Le provider `_historyForClientProvider` (privé dans `client_history_screen.dart`) **est déplacé** dans `providers.dart` et rendu public, pour que le sheet puisse l'invalider.

Après save/delete dans le sheet, invalider :

- `historyForClientProvider(clientId)` — pour rafraîchir la liste d'historique.
- Le provider de la fiche client (`clientByIdProvider` ou équivalent — à vérifier au moment de l'implémentation) — car les compteurs et `lastShearingDate` peuvent avoir changé.
- Le provider de la liste clients avec statut (`clientsListWithStatusProvider` ou équivalent) — car le statut peut basculer à `done`.

## Tests

### `test/data/manual_history_repository_test.dart` (nouveau)

- `insert` puis `listForClient` → renvoie la ligne, triée par date desc.
- `update` modifie les champs.
- `delete` supprime.
- Cascade : supprimer un client supprime ses entrées manuelles.
- `listClientDatesSinceEpochDays` filtre correctement par seuil.

### `test/data/client_repository_test.dart` (extensions)

- `listInterventionsForClient` :
  - fusionne tour_stops + manual_entries
  - tri par date desc respecté quand les sources s'entrelacent
  - pour une ligne manuelle : `kind == manual`, `tourId == null`, `manualEntryId != null`, `hasBilan == true`
- `listAllWithStatus` :
  - client avec uniquement une entrée manuelle dans la saison → status = `done`
  - client avec entrée manuelle hors saison → pas `done` à cause de l'entrée manuelle (peut l'être via un tour, sinon pas `done`)
- `applyManualEntryToClient` :
  - `lastShearingDate == null` → applique
  - `entry.date > lastShearingDate` → applique
  - `entry.date == lastShearingDate` → no-op (strict `>`)
  - `entry.date < lastShearingDate` → no-op
- `recomputeClientFromHistory` :
  - delete de l'entrée manuelle la plus récente, alors qu'un tour-stop existe → `lastShearingDate` retombe sur le tour-stop, compteurs viennent du tour-stop
  - delete de la seule source → `lastShearingDate = null`, compteurs inchangés
  - update qui rend l'entrée plus ancienne qu'une autre source → `lastShearingDate` reflète la nouvelle plus récente

### Tests widget

Pas de nouveau test widget pour `ManualHistoryEntrySheet` — on s'aligne sur la couverture actuelle (tests data + domain seulement, à l'exception de `address_autocomplete_field_test.dart`).

### Tests migration

Si la pratique du repo couvre les migrations (à vérifier sur `m5to6`) : tester que `m6to7` crée la table proprement et que les données existantes restent intactes. Sinon, s'aligner sur la pratique du repo.

## Hors scope

- Pas de bulk import (CSV / formulaire répétitif). Si le besoin arrive, c'est un add-on séparé.
- Pas de modification des entrées issues de tournées (immuables, comme aujourd'hui).
- Pas de transaction Drift cross-repos pour les écritures couplées (insert manual + update client) — gardé simple, à introduire si une incohérence est observée.
