# Client Status Refactor — Design

**Date :** 2026-04-29
**Auteur :** Raphaël Gauthier (with Claude)

## Contexte

Le système actuel dérive `ClientStatus` à 4 valeurs (`defaultStatus`, `waiting`, `overdue`, `recompute`) depuis trois flags : `isWaiting`, `lastShearingDate` (avec un seuil de 395 jours pour `overdue`), `needsDistanceRecompute`. Les couleurs des marqueurs sont configurables dans Settings (4 couleurs) avec un override par-client (`markerColorHex`). La logique métier est éclatée : `tour_repository.markCompleted` clear `isWaiting` et set `lastShearingDate` ; `find_nearby_clients` filtre par `isWaiting` brut ; le filtre liste est un binaire "Tous / En attente".

Ce système ne capture pas le cycle de vie réel d'une saison de tonte. L'utilisateur veut 6 statuts qui reflètent la progression : pas commencé → contact pris → RDV calé → tonte effectuée, plus deux statuts "marginaux" (sans moutons, banni). Et un bouton "Réinitialiser la saison" pour recommencer le cycle chaque année.

## Statuts cibles & couleurs par défaut

| Statut | Sémantique | Couleur |
|---|---|---|
| `defaultStatus` (gris) | Saison en cours, rien fait avec ce client encore | `#9CA3AF` |
| `waiting` (jaune) | En attente de prise de RDV | `#EAB308` |
| `scheduled` (vert) | RDV calé (le client est dans une tournée planifiée de la saison) | `#65A30D` |
| `done` (vert foncé) | On y est passé (le client est dans une tournée réalisée de la saison) | `#166534` |
| `noSheep` (noir) | Sans moutons (`sheepCount == 0`) | `#1F2937` |
| `banned` (rouge) | Banni — éleveur problématique, ne pas prospecter | `#B91C1C` |

Les couleurs sont configurables dans Settings.

## Priorité de dérivation

Quand plusieurs conditions s'appliquent, le statut effectif suit cet ordre (du plus prioritaire au moins) :

1. **Banni** > 2. **Sans moutons** > 3. **Passé** > 4. **RDV calé** > 5. **En attente** > 6. **Par défaut**

Justification : rouge = signal d'alerte fort (priorité absolue) ; sans moutons = pas la peine de planifier ; passé > calé puisqu'une tournée réalisée écrase une planification ; en attente est le statut "actif" en l'absence d'autre engagement.

## Architecture : statut dérivé

Pas de colonne `status` stockée. Le statut est calculé à chaque lecture à partir de :

- `client.isBanned` *(nouveau flag)*
- `client.sheepCount` *(existant)*
- `client.isWaiting` *(existant, sémantique = "en attente de RDV")*
- Présence du client dans un `tour_stop` lié à un `tour` avec `plannedDate >= settings.seasonStartedAt`, en distinguant `tour.status == 'planned'` vs `'completed'`

Algorithme de dérivation :

```dart
ClientStatus deriveStatus(
  Client c, {
  required bool hasCompletedTourThisSeason,
  required bool hasPlannedTourThisSeason,
}) {
  if (c.isBanned) return ClientStatus.banned;
  if (c.sheepCount == 0) return ClientStatus.noSheep;
  if (hasCompletedTourThisSeason) return ClientStatus.done;
  if (hasPlannedTourThisSeason) return ClientStatus.scheduled;
  if (c.isWaiting) return ClientStatus.waiting;
  return ClientStatus.defaultStatus;
}
```

Cette approche élimine tout risque de désync (ex : annuler une tournée → le client repasse automatiquement à jaune ou gris). À l'échelle de l'app (centaines de clients), une jointure SQL pour la liste/carte est triviale.

## Schéma de base de données

**Migration `schemaVersion: 3 → 4`** dans `lib/infra/db/app_database.dart` :

### `clients` table

- **Ajout :** `is_banned BOOLEAN NOT NULL DEFAULT false`
- **Conservé :** `is_waiting`, `last_shearing_date`, `marker_color_hex`, `needs_distance_recompute`, `sheep_count`. `last_shearing_date` reste pour l'affichage "Dernière tonte" sur la fiche, n'intervient plus dans le statut.

### `settings` table

- **Ajout :** `season_started_at INTEGER` (epoch ms). Initialisé à `now` au moment de la migration.
- **Ajout :** `marker_scheduled_color TEXT NOT NULL DEFAULT '#65A30D'`
- **Ajout :** `marker_done_color TEXT NOT NULL DEFAULT '#166534'`
- **Ajout :** `marker_no_sheep_color TEXT NOT NULL DEFAULT '#1F2937'`
- **Ajout :** `marker_banned_color TEXT NOT NULL DEFAULT '#B91C1C'`
- **Suppression :** `marker_overdue_color`, `marker_recompute_color` (statuts retirés). Mise en œuvre via `m.alterTable(TableMigration(...))` qui omet les colonnes obsolètes — SQLite ne supporte pas `DROP COLUMN` natif sur la version embarquée par Drift selon les cas.
- **Conservé :** `marker_default_color`, `marker_waiting_color` (couleurs par défaut mises à jour vers les nouvelles valeurs cibles).

### `tours` / `tour_stops`

Pas de changement structurel. La logique de `tour.markCompleted` est simplifiée (voir plus bas).

## Domaine

### Enum

```dart
enum ClientStatus {
  defaultStatus,
  waiting,
  scheduled,
  done,
  noSheep,
  banned,
}
```

L'ancienne enum à 4 valeurs (`overdue`, `recompute` inclus) est remplacée. La constante `kOverdueThresholdDays` est supprimée (plus utilisée nulle part).

### `Client`

Ajout d'un champ `final bool isBanned` (default `false`).

### `Settings`

Ajout :
- `final DateTime seasonStartedAt`
- `final String markerScheduledColor`
- `final String markerDoneColor`
- `final String markerNoSheepColor`
- `final String markerBannedColor`

Suppression :
- `markerOverdueColor`
- `markerRecomputeColor`

Le `copyWith` est mis à jour en conséquence.

### Dérivation

Le helper de dérivation prend les deux booléens de tournée en arguments. La récupération de ces booléens est faite par le repository (voir ci-dessous), pas dans le modèle.

## Repository

### `ClientRepository`

**Nouvelles méthodes :**

```dart
Future<void> setBanned(int id, bool isBanned);
Future<void> resetAllWaiting(); // UPDATE clients SET is_waiting = false WHERE is_waiting = true
Future<List<(Client, ClientStatus)>> listAllWithStatus(DateTime seasonStartedAt);
Future<(Client, ClientStatus)?> findByIdWithStatus(int id, DateTime seasonStartedAt);
```

`listAllWithStatus` exécute une requête Drift unique avec jointure sur `tour_stops` ⨝ `tours` filtrée par `plannedDate >= seasonStartedAt`, agrégée par `client.id` pour produire `hasPlannedTourThisSeason` et `hasCompletedTourThisSeason`. Le calcul de `ClientStatus` final est appliqué côté Dart via `deriveStatus`.

**Méthodes ajustées :**

- `setMarkerColor` : inchangée.
- L'ancienne `setWaiting` est conservée (utilisée par le toggle de la fiche).

### `SettingsRepository`

- `updateMarkerColor(ClientStatus status, String hex)` : étendu pour les 4 nouvelles valeurs ; les cas `overdue` / `recompute` retirés du `switch`.
- Nouvelle méthode `bumpSeasonStartedAt()` : `UPDATE settings SET season_started_at = ? WHERE id = 1`.

### `TourRepository.markCompleted`

Aujourd'hui : marque la tournée `completed` + clear `isWaiting` + set `lastShearingDate` pour chaque client de la tournée.

**Modification :** ne touche plus à `isWaiting` (le statut bascule naturellement de `scheduled` à `done` via dérivation, puisque la même tournée passe de `planned` à `completed`). On conserve l'écriture de `lastShearingDate = tour.plannedDate` pour l'affichage historique sur la fiche ("Dernière tonte : JJ/MM/YYYY").

## `find_nearby_clients`

Le filtre actuel `if (c == null || !c.isWaiting) continue` devient un filtre par statut effectif `waiting`. En pratique, ça revient à exclure les bannis, les sans-moutons, et les clients déjà engagés dans une tournée de la saison. La signature de `FindNearbyClients.call` est étendue pour accepter une `Map<int, ClientStatus> statusByClientId` calculée par l'appelant via `listAllWithStatus`.

## UI

### Fiche client (`client_detail_screen.dart`)

Refonte de la section "Statut" :

- **Badge en haut de la hero card :** un `FBadge` à la couleur du statut effectif + libellé localisé. Remplace le badge actuel "En attente".
- **Toggle FSwitch "En attente de RDV" :** bascule `client.isWaiting`. Désactivé visuellement (et sans effet) quand le statut effectif est `banned`, `noSheep`, `scheduled` ou `done`. Texte d'aide quand désactivé : *"Le statut actuel ({label}) prend le dessus."*
- **Bouton "Bannir" / "Lever le bannissement" :** `FButton` `variant: destructive` quand `!isBanned`, `variant: outline` sinon. Appelle `setBanned(id, !isBanned)`.
- **Bouton "Remettre par défaut" :** `FButton` `variant: outline`. Désactivé si le client a une tournée `planned` dans la saison ; texte d'aide affiché en dessous : *"Ce client est dans la tournée du JJ/MM. Retire-le de la tournée pour pouvoir le réinitialiser."* Sinon : clear `isWaiting` et clear `isBanned` en une seule action.
- **"Voir clients à proximité" :** enabled uniquement si `status == waiting` (avec la nouvelle dérivation).
- **Bandeau "distances à recalculer" :** conservé tel quel (concern orthogonal au statut).

### Liste clients (`clients_list_screen.dart`)

- **Remplacement du SegmentedButton "Tous / En attente"** par une rangée de 6 chips colorées multi-sélection. Provider `_visibleStatusesProvider` (`StateProvider<Set<ClientStatus>>`), tous actifs par défaut. Chaque chip affiche la couleur du statut + le libellé. Cliquer désactive ce statut.
- Quand l'ensemble visible est vide : empty state "Aucun statut sélectionné" (au lieu du fallback générique "Aucun client").
- **Tile :** un dot 8px de la couleur du statut, placé en préfixe du titre (juste avant le nom du client, séparé par 6px). L'avatar circulaire à initiales est conservé en `prefix` du `AppListTile`. Les badges actuels (`waiting`, `overdue`, `recompute`) sont retirés à l'exception de "distances à recalculer" qui reste comme `FBadge` orange à droite (slot `suffix`).
- **Recherche, tri, header :** conservés sans changement.

### Carte (`map_screen.dart`)

- `mapVisibleStatusesProvider` étendu aux 6 valeurs (au lieu de 4). État initial : tous activés.
- Dialog "Afficher les marqueurs" : 6 lignes au lieu de 4.
- `_resolveColor(c, settings)` : utilise les 6 couleurs Settings ; l'override `client.markerColorHex` reste prioritaire si non null.
- Pin popup : pas de changement.

### Settings (`settings_screen.dart`)

- **Section "Couleurs des marqueurs" :** 6 lignes. Drop "En retard" et "À recalculer", ajout "RDV calé", "Passé", "Sans moutons", "Banni". Chaque ligne reste un `_MarkerColorRow` avec son `defaultHex` correspondant.
- **Nouvelle section "Saison" :** un `FButton` `variant: destructive` "Réinitialiser la saison". Au clic, dialog de confirmation : *"Tous les clients en attente, RDV calé ou Passé repasseront en gris. Les bannis et sans-moutons sont conservés. Continuer ?"*. Action : `bumpSeasonStartedAt()` + `resetAllWaiting()`. Sous le bouton : indication de la date courante de saison ("Saison en cours depuis le JJ/MM/YYYY").

### Localisation

Nouvelles clés ARB (FR + EN) :
- `clientStatusDefault`, `clientStatusWaiting`, `clientStatusScheduled`, `clientStatusDone`, `clientStatusNoSheep`, `clientStatusBanned` (libellés)
- `clientDetailWaitingDisabledHint` (texte d'aide quand toggle désactivé)
- `clientDetailBan`, `clientDetailUnban`
- `clientDetailResetToDefault`
- `clientDetailResetDisabledFmt` (texte d'aide avec date de tournée bloquante)
- `settingsSeasonTitle`, `settingsSeasonResetButton`, `settingsSeasonResetConfirmTitle`, `settingsSeasonResetConfirmBody`, `settingsSeasonStartedFmt`
- Libellés couleurs marqueurs mis à jour (suppression "En retard", "À recalculer" ; ajout des 4 nouveaux).

Les clés obsolètes sont retirées : `clientsBadgeOverdue`. Conservées : `clientsLastShearingFmt` et `clientsLastShearingNever` (toujours utilisées pour l'affichage "Dernière tonte" sur la fiche client).

## Migration des données existantes

Au moment de l'`onUpgrade` de Drift (3 → 4) :

1. Add columns : `clients.is_banned` (default `false`), `settings.season_started_at`, 4 nouvelles colonnes couleur dans `settings`.
2. Drop columns obsolètes : `settings.marker_overdue_color`, `settings.marker_recompute_color` (via `alterTable` Drift).
3. Initialiser `season_started_at = now()` sur la ligne settings unique : `UPDATE settings SET season_started_at = ? WHERE id = 1`.

**État résultant pour les clients existants :**
- `isBanned = false` partout.
- Les flags conservés (`isWaiting`, `sheepCount`) gardent leur valeur.
- Toutes les tournées passées ayant `plannedDate < seasonStartedAt`, aucun client n'est immédiatement en `scheduled` ou `done` — ils dépendent de `isWaiting` ou `sheepCount`. Cohérent avec un "début de saison neuve".

## Tests

- **`test/domain/client_status_test.dart` :** réécrit. Couvre la priorité (banni > sans moutons > done > scheduled > waiting > default), les transitions, et les combinaisons de flags + tournées.
- **`test/data/client_repository_test.dart` :** nouveaux cas pour `setBanned`, `resetAllWaiting`, `listAllWithStatus` (avec setup de tournées planifiées et complétées).
- **`test/data/tour_repository_test.dart` :** ajuster `markCompleted` — vérifie que `isWaiting` n'est *plus* modifié, mais que `lastShearingDate` est toujours écrit.
- **`test/domain/find_nearby_clients_test.dart` :** adapter au filtre par statut (entrée nouvelle `Map<int, ClientStatus>`).
- Nouveau test : `bumpSeasonStartedAt` met à jour le timestamp et la dérivation des clients change en conséquence.

## Ordre d'implémentation suggéré

1. Schema DB + migration + nouvelles colonnes Settings/Client.
2. Modèles (`Client.isBanned`, `Settings.seasonStartedAt` + couleurs, enum `ClientStatus`, fonction `deriveStatus`).
3. Repositories (`setBanned`, `resetAllWaiting`, `listAllWithStatus`, `findByIdWithStatus`, `bumpSeasonStartedAt`, ajustement `markCompleted`, `updateMarkerColor` étendu).
4. `find_nearby_clients` adapté.
5. Settings UI (couleurs étendues + bouton reset saison).
6. Fiche client (toggles, boutons, badge statut).
7. Liste clients (chips multi-sélect, dot statut).
8. Carte (6 layers, couleurs).
9. Localisation FR/EN.
10. Tests (mise à jour + nouveaux).

## Hors scope

- Aucun écran "Historique des saisons" (pas demandé).
- Pas d'export/import de l'état de saison (le flux Settings actuel d'export/import couvre déjà toute la base).
- Pas de notifications "fin de saison approche" ou similaire.
- `lastShearingDate` reste affiché sur la fiche pour le contexte historique mais n'est plus utilisé pour calculer le statut.
