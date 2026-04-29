# Interventions & Breed Split — Design

**Date :** 2026-04-29
**Auteur :** Raphaël Gauthier (with Claude)

## Contexte

Aujourd'hui, un client porte un seul `sheepCount` (entier total) et l'estimateur de tournée applique un taux unique `defaultMinutesPerSheep`. Il n'y a pas d'historique d'interventions : la complétion d'une tournée se contente de poser `lastShearingDate` sur chaque client, sans capturer les comptes effectifs ni les éventuelles notes du tondeur.

Deux limites pratiques :
1. Le cheptel comporte deux catégories aux temps de tonte très différents — Ouessants/Landes (petits, ~8 min/bête) vs Grandes Races (~25 min/bête). Un taux unique fausse les estimations.
2. Aucun moyen de revoir ce qui a été fait chez un client la saison précédente : combien on a tondu, dans quelle proportion, et toute observation utile pour la prochaine fois.

Cette refonte introduit la distinction de race comme dimension de premier ordre du domaine, et fait des `tour_stops` complétés l'historique d'interventions de chaque client.

## Statuts cibles & règles

- Une intervention = un `tour_stop` dont la tournée parente est passée en `completed`. Pas d'entité séparée. Pas d'intervention hors-tournée.
- Deux compteurs sur la fiche client : `sheepCountSmall` (Ouessants/Landes) + `sheepCountLarge` (Grandes Races). Le total = somme.
- Deux taux globaux dans Settings : `defaultMinutesPerSmall` + `defaultMinutesPerLarge`. Pas d'override par-client (le `minutesPerSheepOverride` actuel disparaît).
- Le statut dérivé `noSheep` se déclenche quand `sheepCountSmall == 0 && sheepCountLarge == 0`.
- L'estimateur de tournée calcule chaque stop : `small × minutesSmall + large × minutesLarge`.
- À la complétion d'une tournée, l'utilisateur saisit pour chaque stop les comptes effectifs (`actualSmall` + `actualLarge`) et une note optionnelle. Ces valeurs :
  1. Sont persistées sur le `tour_stop`.
  2. Remplacent (auto-sync) `client.sheepCountSmall` et `sheepCountLarge` du client correspondant.
  3. Bumpent `client.lastShearingDate = tour.plannedDate` (denormalisation conservée).

## Architecture : intervention dérivée du `tour_stop`

Pas de table `interventions`. Chaque tournée complétée capture sur ses stops les actuals + note. La fiche client affiche un historique en lisant `tour_stops` joint à `tours` filtrés par `tour.status = 'completed'` et `tour_stop.client_id = ?`, ordonné par date desc.

Cette approche :
- Évite la duplication d'une seconde table.
- Réutilise la cascade FK existante (`tour_stops.client_id setNull` à la suppression du client).
- Garde un seul chemin pour "fin de tournée" — pas de "j'ajoute une intervention manuelle". Si ce besoin arrive un jour, on bascule vers une table `manual_interventions` + un `listInterventionsForClient` qui agrège les deux sources, sans casser l'existant.

## Schéma de base de données

**Migration `schemaVersion: 5 → 6`** dans `lib/infra/db/app_database.dart`.

### `clients`

- **Ajout** `sheep_count_small INTEGER NOT NULL DEFAULT 0`.
- **Ajout** `sheep_count_large INTEGER NOT NULL DEFAULT 0`.
- **Suppression** `sheep_count` (colonne unique).
- **Suppression** `minutes_per_sheep_override` (override par-client retiré).
- **Conservé** `last_shearing_date` — dénormalisé, mis à jour à la complétion. Évite une jointure pour l'affichage "Dernière tonte" sur la fiche.

### `settings`

- **Ajout** `default_minutes_per_small INTEGER NOT NULL DEFAULT 8`.
- **Ajout** `default_minutes_per_large INTEGER NOT NULL DEFAULT 25`.
- **Suppression** `default_minutes_per_sheep`.

### `tour_stops`

- **Ajout** `planned_small INTEGER NOT NULL DEFAULT 0`.
- **Ajout** `planned_large INTEGER NOT NULL DEFAULT 0`.
- **Ajout** `minutes_per_small_snapshot INTEGER NOT NULL DEFAULT 0`.
- **Ajout** `minutes_per_large_snapshot INTEGER NOT NULL DEFAULT 0`.
- **Ajout** `actual_small INTEGER` (nullable — rempli à la complétion).
- **Ajout** `actual_large INTEGER` (nullable).
- **Ajout** `intervention_note TEXT` (nullable).
- **Suppression** `sheep_count_snapshot`.
- **Suppression** `minutes_per_sheep_snapshot`.

## Domaine

### `Client`

```dart
class Client {
  // ... champs inchangés (id, name, phone, addressLabel, postcode, city,
  //     coordinates, markerColorHex, isWaiting, isBanned,
  //     lastShearingDate, needsDistanceRecompute) ...
  final int sheepCountSmall;
  final int sheepCountLarge;
  // … sheepCount et minutesPerSheepOverride supprimés
  // helper :
  int get sheepCountTotal => sheepCountSmall + sheepCountLarge;
}
```

Le helper `minutesPerSheep(Settings)` est supprimé (les taux sont en Settings, plus d'override).

### `Settings`

Suppression de `defaultMinutesPerSheep`. Ajouts :

```dart
final int defaultMinutesPerSmall; // default 8
final int defaultMinutesPerLarge; // default 25
```

`copyWith` ajusté en conséquence. La signature constructeur change ; tous les call-sites (form, settings, tests) passeront les deux nouveaux champs.

### `TourStop`, `TourStopDraft`

Remplacent `sheepCountSnapshot` et `minutesPerSheepSnapshot` par :

```dart
final int plannedSmall;
final int plannedLarge;
final int minutesPerSmallSnapshot;
final int minutesPerLargeSnapshot;
final int? actualSmall;
final int? actualLarge;
final String? interventionNote;
```

`TourStopDraft` n'inclut pas les `actual_*` ni la note (ils n'existent qu'à la complétion).

### Nouveau DTO `Intervention` (présentation)

```dart
class Intervention {
  final int tourId;
  final int stopId;
  final DateTime date; // = tour.plannedDate
  final int small;     // actualSmall, ou plannedSmall en fallback v6-prior
  final int large;     // actualLarge, ou plannedLarge en fallback
  final String? note;
  final bool hasBilan; // false si actualSmall/Large étaient null (tournée pré-v6)
}
```

Construit côté repository à partir de la jointure `tour_stops ⨝ tours`. Pour les tournées complétées avant la v6 (donc avec `actual_*` à NULL), `small`/`large` retournent les `planned_*` et `hasBilan = false`. L'UI utilise `hasBilan` pour appliquer la mention discrète "(planifié, pas de bilan)" sur ces lignes.

## Repository

### `ClientRepository`

**Méthodes existantes ajustées :**
- `insert(Client c)` : utilise les nouveaux champs `sheepCountSmall` / `sheepCountLarge`.
- `updateBasics({...})` : remplace `int sheepCount` par `int sheepCountSmall` + `int sheepCountLarge`. `int? minutesPerSheepOverride` supprimé.
- `_toDomain(ClientRow row)` : mappe les nouveaux champs.
- `listAllWithStatus`, `findByIdWithStatus` : signatures inchangées ; `deriveStatus` adapté pour le nouveau test `noSheep`.

**Nouvelles méthodes :**
- `Future<void> applyInterventionActuals(int clientId, {required int small, required int large, required DateTime tourDate})` — utilisée à l'intérieur de la transaction `markCompleted` pour synchroniser le client. Met à jour `sheep_count_small`, `sheep_count_large`, `last_shearing_date`, `updated_at`. Pourrait aussi être inlinée dans `tour_repository.markCompleted` ; la garder ici en helper rend `markCompleted` plus lisible.
- `Future<List<Intervention>> listInterventionsForClient(int clientId)` — retourne l'historique trié desc. Jointure `tour_stops ⨝ tours` sur `client_id = ?` AND `tour.status = 'completed'`. Pour chaque ligne, retourne un `Intervention` (avec fallback `planned_*` si `actual_*` est null).

### `SettingsRepository`

`read()` et `save()` adaptés aux deux taux. Les méthodes existantes (`bumpSeasonStartedAt`, `updateMarkerColor`) restent inchangées.

### `TourRepository`

**`markCompleted(int tourId, Map<int stopId, ({int actualSmall, int actualLarge, String? note})> actuals)`** :
- Signature étendue : la map des actuals/notes est passée par l'appelant (l'écran de bilan).
- Dans une transaction :
  1. `tours.status = 'completed'`, `completed_at = now`.
  2. Pour chaque entrée de `actuals` : update `tour_stops.actual_small`, `actual_large`, `intervention_note`.
  3. Pour chaque stop avec `clientId != null` : appel `clients.applyInterventionActuals(...)`.
- L'écran de bilan transmet la map même pour les stops dont l'utilisateur a laissé les valeurs par défaut — les valeurs persistées seront alors égales aux `planned_*`, ce qui est correct (= "j'ai tondu exactement ce qui était prévu").
- Ne met plus à jour `lastShearingDate` directement (c'est `applyInterventionActuals` qui le fait — un seul chemin d'écriture).

**`plan(TourDraft)`** : utilise les nouveaux snapshots breed-aware.

**`_stopFromRow`** : mappe les nouveaux champs.

## Use cases

### `TourDurationEstimator`

Signature actuelle :
```dart
TourDurationResult estimate({
  required int startTimeMinutes,
  required List<int> driveSecondsToStops,
  required int driveSecondsBackToBase,
  required List<int> sheepCountPerStop,
  required List<int> minutesPerSheepPerStop,
});
```

Nouvelle signature :
```dart
TourDurationResult estimate({
  required int startTimeMinutes,
  required List<int> driveSecondsToStops,
  required int driveSecondsBackToBase,
  required List<({int small, int large, int minutesSmall, int minutesLarge})> stops,
});
```

Le calcul de `shearMin` par stop devient `small * minutesSmall + large * minutesLarge`. Les arrays de tailles incohérentes ne sont plus possibles (un seul argument structuré).

### `BuildTourDraft`

À l'intérieur du build, pour chaque stop sélectionné :
- `plannedSmall = client.sheepCountSmall`
- `plannedLarge = client.sheepCountLarge`
- `minutesPerSmallSnapshot = settings.defaultMinutesPerSmall`
- `minutesPerLargeSnapshot = settings.defaultMinutesPerLarge`

L'estimateur reçoit la liste typée. Les snapshots sont figés à ce moment et ne bougent plus jusqu'à la complétion.

### `ClientStatus.deriveStatus`

`if (c.sheepCount == 0)` devient `if (c.sheepCountSmall == 0 && c.sheepCountLarge == 0)`. Reste de la priorité inchangé.

### `find_nearby_clients`

Pas de changement.

## UI

### Fiche client (`client_detail_screen.dart`)

- **Hero card** : `bigNumber: '${client.sheepCountTotal}'` (somme), `label: 'moutons'`. `subtitle` détaillé : `'X Ouessants/Landes · Y Grandes Races'`. Le badge statut reste à gauche.
- **Section "Historique des interventions"** insérée entre la card statut et "Voir clients à proximité". `AppSectionCard(icon: FIcons.history, title: l.clientDetailSectionHistory)`. Lit `_interventionsForClientProvider(clientId)` (`FutureProvider.family.autoDispose<List<Intervention>, int>`).
  - Si vide → texte muted `l.clientDetailHistoryEmpty`.
  - Sinon → liste verticale des 5 plus récentes (ligne formatée : `'JJ/MM/YYYY · X Ouessants/Landes + Y Grandes Races'`, et si `note != null`, second sous-texte tronqué à ~80 chars). Les interventions pré-v6 (sans `actual_*` réels) affichent le format avec mention discrète "(planifié, pas de bilan)" et utilisent les `planned_*` comme fallback.
  - Si plus de 5 → bouton `l.clientDetailHistoryViewAll` qui pousse `/clients/:id/history` (écran ListView plein écran). Si exactement ≤ 5, bouton absent.
- **Suppression** de la card "Notes" résiduelle (déjà retirée commit précédent — confirmer absence).
- La logique du toggle "En attente RDV", boutons Bannir / Reset, garde tournée planifiée — inchangée.

### Nouvel écran historique complet (`client_history_screen.dart`)

- Routé `/clients/:id/history`.
- Header `FHeader.nested(title: client.name)`.
- ListView de toutes les interventions, même format que la mini-liste sur la fiche.
- Pas d'action — lecture seule. Tap sur une ligne push `/tours/:tourId` pour voir le détail de la tournée parente.

### Formulaire client (`client_form_screen.dart`)

Section "Tonte" :
- Remplacer le `FTextField` "Nombre de moutons" par deux champs :
  - Label `l.clientFormSheepCountSmall` (Ouessants / Landes), digits-only, default `'0'`.
  - Label `l.clientFormSheepCountLarge` (Grandes Races), digits-only, default `'0'`.
- Validation : chaque compte ≥ 0 (la valeur 0 est acceptée pour les deux).
- Suppression du champ "Minutes par mouton (laisser vide pour défaut)".

### Settings (`settings_screen.dart`)

Section "Valeurs par défaut" :
- Remplacer "Minutes par mouton" par deux champs :
  - `l.settingsMinPerSmallLabel` (default 8).
  - `l.settingsMinPerLargeLabel` (default 25).
- Le rayon par défaut et le tarif déplacement restent.

### Nouvel écran de bilan de tournée (`tour_completion_screen.dart`)

- Routé `/tours/:id/complete`. Push depuis `tour_detail_screen.dart` quand on clique le bouton "Marquer comme réalisée" (au lieu d'appeler `markCompleted` directement comme aujourd'hui).
- `FScaffold` Category B (avec `SafeArea` + `resizeToAvoidBottomInset: true` + `FHeader.nested(title: l.tourCompletionTitle)`).
- Body : `ListView.builder` qui rend une `AppSectionCard` par stop (tous les stops avec `clientId != null` ; les stops dont le client a été supprimé entre-temps sont skippés). Chaque card :
  - `title` = nom du client (snapshot).
  - Deux `FTextField` pré-remplis avec les `planned_*` du stop (digits-only).
  - Un `FTextField` multiligne `l.tourCompletionNoteHint` (3 lignes).
- Footer fixe `Padding + AppPrimaryButton(label: l.tourCompletionConfirm)` au tap :
  1. Construit la `Map<int stopId, ({actualSmall, actualLarge, note})>`.
  2. Appelle `tour_repository.markCompleted(tourId, actuals)`.
  3. Invalidate trois providers : `clientsAsyncProvider` (rafraîchit liste/carte/comptes), le provider de fiche tournée (`_tourByIdProvider(tourId)` exposé par `tour_detail_screen.dart`), et — pour chaque `clientId` touché par les actuals — `_interventionsForClientProvider(clientId)` (rafraîchit l'historique sur la fiche client si elle est ouverte). Pas besoin d'invalider les providers de status par-client (`_clientByIdProvider`) explicitement : la liste les recalcule au prochain rebuild via `clientsAsyncProvider`.
  4. Toast de confirmation, `context.pop()` (retour sur la fiche tournée qui montre maintenant le statut "Réalisée" + les actuals).
- Si l'utilisateur quitte par back sans confirmer → la tournée reste `planned`, pas d'écriture. Pas de prompt "êtes-vous sûr ?" pour rester léger.

### Fiche tournée (`tour_detail_screen.dart`)

- Le bouton "Marquer comme réalisée" devient un `context.push('/tours/$id/complete')`.
- Pour les tournées déjà `completed` : pour chaque stop, deux lignes secondaires sous le nom du client. Ligne 1 : `'Planifié : X Ouessants/Landes + Y Grandes Races'`. Ligne 2 (seulement si `actualSmall != null`) : `'Effectif : A Ouessants/Landes + B Grandes Races'`. Si `interventionNote != null`, troisième ligne en italique avec le texte. Une tournée pré-v6 (actuals NULL) n'affiche pas la ligne "Effectif" — seulement le planifié.

### Carte (`map_screen.dart`)

- `client_pin_popup.dart` affiche actuellement `'${client.city} · ${client.sheepCount} moutons'`. Remplace par `'${client.city} · ${client.sheepCountTotal} moutons'`. Pas de changement structurel.
- L'écran map en lui-même : pas de changement.

### Liste clients (`clients_list_screen.dart`)

- Le tile affiche `'${client.city} · ${l.clientsListSheepCountFmt(client.sheepCountTotal)}'`. Le format ICU pluriel existant est conservé tel quel (basé sur le total).

### Composition de tournée (`tour_draft_screen.dart`, `proximity_list_view.dart`)

- L'affichage des stops candidats utilise le total. Pas d'UI nouvelle pour les races à ce stade.

## Localisation

**Nouvelles clés (FR + EN) :**

```
clientFormSheepCountSmall: "Ouessants / Landes" / "Ouessant / Lande sheep"
clientFormSheepCountLarge: "Grandes Races" / "Large breeds"
settingsMinPerSmallLabel: "Minutes par Ouessant/Lande" / "Minutes per Ouessant/Lande sheep"
settingsMinPerLargeLabel: "Minutes par Grande Race" / "Minutes per large-breed sheep"
clientDetailSectionHistory: "Historique des interventions" / "Intervention history"
clientDetailHistoryEmpty: "Aucune intervention enregistrée." / "No intervention recorded yet."
clientDetailHistoryItemFmt: "{date} · {small} Ouessants/Landes + {large} Grandes Races"
                          / "{date} · {small} Ouessant/Lande + {large} large breeds"
clientDetailHistoryViewAll: "Voir l'historique complet" / "See full history"
clientHistoryTitle: "Historique" / "History"
tourCompletionTitle: "Bilan d'intervention" / "Intervention summary"
tourCompletionConfirm: "Confirmer la tournée" / "Confirm tour"
tourCompletionNoteHint: "Note (optionnelle)" / "Note (optional)"
```

**Clés supprimées :**
- `clientFormSheepCount`
- `clientFormMinPerSheepHint`
- `settingsMinPerSheepLabel`

`clientDetailSheepCountFmt` (déjà non utilisée dans le code) peut être nettoyée à l'occasion.

## Migration des données existantes

Étapes en SQL (dans l'ordre du `if (from < 6)`) :

```sql
-- 1. clients : ajout small/large, copie depuis sheep_count, drop des colonnes
ALTER TABLE clients ADD COLUMN sheep_count_small INTEGER NOT NULL DEFAULT 0;
ALTER TABLE clients ADD COLUMN sheep_count_large INTEGER NOT NULL DEFAULT 0;
UPDATE clients SET sheep_count_small = sheep_count;
ALTER TABLE clients DROP COLUMN sheep_count;
ALTER TABLE clients DROP COLUMN minutes_per_sheep_override;

-- 2. settings : ajout, copie, drop
ALTER TABLE settings ADD COLUMN default_minutes_per_small INTEGER NOT NULL DEFAULT 8;
ALTER TABLE settings ADD COLUMN default_minutes_per_large INTEGER NOT NULL DEFAULT 25;
UPDATE settings
   SET default_minutes_per_small = default_minutes_per_sheep,
       default_minutes_per_large = MAX(default_minutes_per_sheep, 25)
 WHERE id = 1;
ALTER TABLE settings DROP COLUMN default_minutes_per_sheep;

-- 3. tour_stops : ajout des breed-aware snapshots + actuals + note
ALTER TABLE tour_stops ADD COLUMN planned_small INTEGER NOT NULL DEFAULT 0;
ALTER TABLE tour_stops ADD COLUMN planned_large INTEGER NOT NULL DEFAULT 0;
ALTER TABLE tour_stops ADD COLUMN minutes_per_small_snapshot INTEGER NOT NULL DEFAULT 0;
ALTER TABLE tour_stops ADD COLUMN minutes_per_large_snapshot INTEGER NOT NULL DEFAULT 0;
ALTER TABLE tour_stops ADD COLUMN actual_small INTEGER;
ALTER TABLE tour_stops ADD COLUMN actual_large INTEGER;
ALTER TABLE tour_stops ADD COLUMN intervention_note TEXT;
UPDATE tour_stops
   SET planned_small = sheep_count_snapshot,
       minutes_per_small_snapshot = minutes_per_sheep_snapshot;
ALTER TABLE tour_stops DROP COLUMN sheep_count_snapshot;
ALTER TABLE tour_stops DROP COLUMN minutes_per_sheep_snapshot;
```

**État résultant :**
- Clients : tout le cheptel existant migre côté `sheepCountSmall`. Les clients à 0 passent en statut `noSheep` (déjà le cas avec l'ancien `sheepCount = 0`).
- Settings : taux Ouessants = ancien taux ; taux Grandes Races = max(ancien, 25) (si l'utilisateur avait 20 par défaut, on monte à 25 pour les gros ; s'il avait 30, on garde 30).
- Tournées passées : snapshots migrés côté small. Aucun bilan d'intervention rétroactif (les `actual_*` restent NULL).

## Edge cases

1. **Tournée pré-v6, déjà complétée.** L'historique sur la fiche affiche cette ligne avec fallback `planned_*`, mention "(planifié, pas de bilan)". Pas de saisie possible (la tournée est déjà `completed`).
2. **Tournée pré-v6, planifiée mais pas encore complétée.** Lors de l'ouverture de l'écran "Bilan", `planned_large = 0` (côté migration). L'utilisateur ajuste les valeurs si besoin. Flow normal.
3. **Compte effectif différent du planifié.** Aucune erreur. L'estimation passée n'est pas recalculée — ce qui était estimé reste estimé. Les comptes du client sont mis à jour avec les actuals.
4. **`actualSmall = 0 && actualLarge = 0` après bilan.** Le client passe en statut `noSheep` (noir). L'utilisateur a probablement vu le cheptel vide ; s'il s'est trompé, il édite la fiche.
5. **Suppression d'un client après une intervention.** FK `setNull` existante. Le `tour_stops` garde `client_name_snapshot`, `actual_*`, `intervention_note`. L'historique du client devient inaccessible (la fiche n'existe plus) ; les tournées passées restent cohérentes pour leur propre fiche.
6. **Note > 80 chars.** Pas de limite stockée, juste tronquée à l'affichage condensé sur la fiche. L'écran "Historique complet" affiche en entier.

## Tests

### À mettre à jour

- `test/domain/client_status_test.dart` — helper `_client(...)` accepte `sheepCountSmall` / `Large`. Cas existants couverts ; ajouter un cas "small > 0 && large == 0 → pas noSheep" pour figer la règle.
- `test/data/client_repository_test.dart` — `_newClient` adapté ; cas C4 du test `listAllWithStatus` passe `sheepCountSmall: 0, sheepCountLarge: 0`.
- `test/data/settings_repository_test.dart` — tous les `Settings(...)` literals passent les deux nouveaux taux ; le test "round-trip + updateMarkerColor" continue de fonctionner.
- `test/data/tour_repository_test.dart` — `_addClient` adapté. Le test `markCompleted writes lastShearingDate but does not touch isWaiting` est étendu : passe une `actuals` map, vérifie que `tour_stops.actual_small`/`actual_large`/`intervention_note` sont persistés ET que les compteurs du client sont synchronisés depuis les actuals.
- `test/domain/build_tour_draft_test.dart` — adapter à la nouvelle signature de l'estimateur.
- `test/domain/tour_duration_estimator_test.dart` — si existant, refondre : un cas avec mix Ouessants + Grandes Races qui vérifie `total = small × minSmall + large × minLarge` correctement.

### Nouveaux

- `test/data/intervention_history_test.dart` — couvre `listInterventionsForClient` :
  - Aucune intervention → liste vide.
  - Plusieurs tournées dans plusieurs ordres → tri desc respecté.
  - Tournée pré-v6 (actuals NULL) → fallback sur planned_*, mention "no-bilan" via flag ou champ ad hoc dans `Intervention`.
  - Suppression d'un client → ne fait pas crash la requête (FK setNull).

## Hors scope

- **Pas d'interventions hors-tournée** (manuel sans Tour). Si besoin un jour : nouvelle table + agrégation à la lecture, sans casser le contrat actuel.
- **Pas de breed metadata** (couleur, icône, libellés configurables). Deux libellés textuels en l'air, c'est tout.
- **Pas de re-calcul de l'estimation post-complétion** quand les `actual_*` divergent du planifié.
- **Pas de migration d'historique** : les tournées pré-v6 n'ont pas d'`actual_*` réels — affichage clairement marqué "planifié".
- **Pas de support de plus de 2 races** : l'API et le schéma sont strictement bi-races. Ajouter une 3e race demande un autre refacto.
- **Pas de compteur "non classé" temporaire** (option D rejetée).
