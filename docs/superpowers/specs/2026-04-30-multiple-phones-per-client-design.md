# Plusieurs numéros de téléphone par client

**Date :** 2026-04-30
**Statut :** spec validée, prêt pour plan d'implémentation

## Contexte

Aujourd'hui, un client a au plus un numéro (`clients.phone TEXT NULLABLE`). Le besoin : pouvoir en stocker plusieurs (typiquement fixe + mobile, ou plusieurs interlocuteurs au sein du foyer) et les utiliser depuis la fiche client / le popup carte.

## Décisions de cadrage

- **Pas d'étiquettes / rôles** sur les numéros. Une simple liste ordonnée.
- **Le premier numéro de la liste est le « principal »** : il est utilisé par défaut pour les actions « Appeler » / « SMS » sur le popup carte. L'ordre est porteur de sens et éditable.
- **Formulaire client** : liste de champs empilés, bouton « + Ajouter un numéro », bouton `×` par ligne, drag-to-reorder.
- **Fiche client** : une ligne par numéro, chaque ligne offre Appeler + SMS individuellement.
- **Popup carte** : inchangé visuellement. Les boutons Appeler / SMS utilisent uniquement le principal. Pour utiliser un autre numéro, l'utilisateur ouvre la fiche client.
- **Recherche** : matche tous les numéros de la liste.
- **Pas de cap explicite** sur le nombre de numéros (libre, comme aujourd'hui pour la longueur du champ).

## Architecture retenue : colonne JSON sur `clients`

`clients.phone TEXT NULLABLE` est remplacé par `clients.phones TEXT NOT NULL DEFAULT '[]'` qui stocke un JSON array de strings via un `TypeConverter` Drift.

Justification : la liste est toujours lue avec le client (jamais requêtée seule), max ~3 entrées en pratique, l'ordre est porté nativement par l'array. Une table relationnelle séparée (`client_phones`) serait du sur-engineering : pas de jointure, pas de repo dédié, pas de migration plus lourde.

## Données

### Schéma Drift (`lib/infra/db/tables.dart`)

```dart
TextColumn get phones => text()
    .map(const PhoneListConverter())
    .withDefault(const Constant('[]'))();
// L'ancienne colonne `phone` est supprimée.
```

`PhoneListConverter` : `TypeConverter<List<String>, String>` qui (dé)sérialise via `jsonEncode` / `jsonDecode`. Liste vide ↔ `'[]'`.

### Migration v7 → v8 (`lib/infra/db/app_database.dart`)

`schemaVersion: 7 → 8`. Étapes :

1. `ALTER TABLE clients ADD COLUMN phones TEXT NOT NULL DEFAULT '[]';`
2. `UPDATE clients SET phones = json_array(phone) WHERE phone IS NOT NULL AND trim(phone) <> '';`
3. `ALTER TABLE clients DROP COLUMN phone;` (SQLite ≥ 3.35, fourni par `sqlite3_flutter_libs`)

Chaque `phone` non vide existant devient l'unique élément (donc le principal) de la nouvelle liste. Les `phone NULL` ou vides → liste vide.

### Modèle domaine (`lib/domain/models/client.dart`)

```dart
final List<String> phones; // ordonnée; index 0 = principal

String? get principalPhone =>
    phones.isNotEmpty ? phones.first : null;
```

Le champ `phone` est supprimé. Tous les call-sites passent par `phones` ou `principalPhone`.

### Normalisation à l'écriture

Un helper privé `_normalizePhones(List<String>) → List<String>` dans `ClientRepository` :
- trim de chaque entrée,
- drop des chaînes vides après trim,
- dédoublonnage stable (préserve l'ordre, garde la première occurrence).

Pas de validation de format (saisie libre, comme aujourd'hui).

## Repository (`lib/data/repositories/client_repository.dart`)

- `insertClient` / `updateClient` : `phone: Value(c.phone)` → `phones: Value(_normalizePhones(c.phones))`. Le converter Drift gère la sérialisation.
- La variante `updateClient(... String? phone ...)` (~ ligne 125) : signature élargie en `List<String> phones`. Tous les appelants sont mis à jour (formulaire client à ma connaissance — à confirmer pendant l'implémentation).
- Le mapper `ClientRow → Client` (~ ligne 462) : `phones: row.phones` (déjà décodée par le converter).

Pas de nouveau repository, pas de nouvelle table.

## UI

### Formulaire (`lib/presentation/clients/client_form_screen.dart`)

`_phoneCtrl` (unique) → `List<TextEditingController> _phoneCtrls`. La liste reflète l'ordre courant (index 0 = principal).

Widget : section « Téléphones » contenant une `ReorderableListView` (shrinkWrap, physics non-scrollable). Chaque ligne :
- poignée de drag à gauche (`FIcons.gripVertical`),
- `TextField` du numéro, `keyboardType: TextInputType.phone`,
- bouton `×` (`FIcons.x`) à droite — supprime la ligne (et dispose le controller).

Sous la liste, un bouton tertiaire **+ Ajouter un numéro** qui append un controller vide et lui donne le focus.

Au submit : `phones = _phoneCtrls.map((c) => c.text).toList()`. Le repo normalise.

À l'init :
- création → un controller vide,
- édition → un controller par numéro existant.

Disposal correct des controllers (sur remove individuel et sur `dispose()` de l'écran).

### Fiche client (`lib/presentation/clients/client_detail_screen.dart`)

Carte « Contact » affichée si `client.phones.isNotEmpty`. À l'intérieur, **une ligne par numéro**. Chaque ligne :
- icône `FIcons.phone`,
- numéro,
- deux boutons à droite : « Appeler » (`callPhone`) + « SMS » (`sendSms`).

Pas d'étiquette « principal » visible — l'ordre suffit.

### Popup carte (`lib/presentation/map/client_pin_popup.dart`)

Forme inchangée. Les trois références à `client.phone` (lignes 22, 79, 90) deviennent `client.principalPhone`. `hasPhone` devient `client.principalPhone != null`.

## Recherche (`lib/core/text_search.dart`)

Ligne 41 : `c.phone ?? ''` → `c.phones.join(' ')`. Tous les numéros sont indexés dans le texte plein-recherche du client. Pas d'autre changement (la recherche reste in-memory).

## Localisation (`lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`)

- Renommer `clientFormPhone` → `clientFormPhones` (« Téléphones » / « Phones ») — label de la section.
- Ajouter `clientFormAddPhone` (« Ajouter un numéro » / « Add a number »).
- Ajouter `clientFormRemovePhone` (« Retirer ce numéro » / « Remove this number ») — tooltip / semantics du bouton `×`.

Régénération via `flutter gen-l10n` (configuration `l10n.yaml` déjà en place).

## Tests

### Data

Extension de `test/data/client_repository_test.dart` (ou fichier dédié si plus simple) :

- `insertClient` persiste `["0612", "0145", "0788"]` et la relit dans le même ordre.
- `updateClient` avec une liste réordonnée écrase et préserve le nouvel ordre.
- Normalisation : `["  06 12  ", "", "0612", "0145"]` → `["06 12", "0145"]` (trim + drop empty + dedupe stable).
- Mapper : un client avec `phones = '[]'` en base ressort `phones: []` et `principalPhone == null`.

### Migration

Test dédié (pattern déjà utilisé pour les migrations précédentes) :

- DB v7 fictive avec un client `phone = "0612"` et un autre `phone = NULL`.
- Migrer vers v8.
- Vérifier : `phones: ["0612"]` et `phones: []` respectivement.

### Recherche

Extension de `test/core/text_search_test.dart` (ou ajout si absent) :

- Un client avec `phones: ["0612", "0145"]` matche une requête sur `"0145"`.

Pas de tests UI — cohérent avec la base existante (tests focalisés data/domain).

## Hors scope

- Étiquettes / rôles par numéro (« principal », « berger », etc.).
- Validation de format des numéros.
- Cap explicite sur le nombre de numéros.
- Affichage des numéros secondaires dans le popup carte.
- Sélection inline du numéro à appeler / texter (le popup utilise le principal, la fiche affiche tout).
