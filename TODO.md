# TODO

Index des fonctionnalités. Le brief détaillé (périmètre, critères d'acceptation, points ouverts) est produit lors du brainstorming au moment de la spec — cette liste reste un index : titre, contexte court, et les rares choses importantes à ne pas perdre entre deux sessions.

---

## À venir

### 1. Synchronisation cloud — priorité haute
Sauvegarde + restauration sur un nouveau device, à terme multi-device. Prérequis : choix du backend (Firebase / Supabase / custom), push-only vs bidirectionnel, auth, mode offline avec sync différée. À articuler avec la migration `ORS_API_KEY` côté backend (cf. memory).

### 2. Gestion du RGPD — priorité haute
Mise en conformité RGPD pour les données clients stockées (coordonnées, téléphones, historique de tonte, notes). À couvrir : politique de confidentialité, mentions de collecte, consentement, droit d'accès / rectification / suppression / portabilité (export JSON déjà en place — à compléter par une suppression totale), durée de conservation, mentions légales. À articuler avec la sync cloud (#1) qui change la nature du traitement (du local-only au cloud).

### 3. Personnalisation des statuts client — priorité moyenne
Les statuts (`waiting`, `scheduled`, `done`, `noSheep`, `banned`) ont libellés et couleurs en dur. À l'onboarding + dans Réglages, l'utilisateur doit pouvoir les nommer et choisir leurs couleurs. Les couleurs sont déjà persistées (`Settings.markerXxxColor`) ; il faut ajouter les libellés en base et brancher l'UI dessus partout (badges, légende carte, filtres, fiche).

### 4. Création du business model — priorité moyenne
Définir le modèle économique de l'app : gratuit / freemium / abonnement / one-shot, segmentation par features (sync cloud, multi-device, catalogue avancé…), pricing, canaux de distribution. Travail produit + business, pas un sujet code. À cadrer avant d'ouvrir l'app au public et de basculer la clé ORS côté backend (coût serveur).

### 7. Génération de facture + envoi client — long terme (non prioritaire)
PDF facture par client par tournée. Reportée : pas de plan court terme.
Le `priceCentsSnapshot` sur `TourStopPrestation` (livré en #6) servira de
source quand le sujet sera repris.

---

## Livrées

### Édition d'une tournée planifiée + suggestions à proximité
**Mergé sur `main`** — 2026-04-30 (commit de merge `6b59e4a`)
**Spec :** `docs/superpowers/specs/2026-04-30-edit-tour-stops-design.md`
**Plan :** `docs/superpowers/plans/2026-04-30-edit-tour-stops.md`

#### Ce qui a été livré

**Édition de tournée**
- Bouton « Modifier » sur le détail d'une tournée `planned` (icône crayon dans le header). Aucun bouton sur les tournées `completed`.
- Nouvelle route `/tours/:id/edit` qui réutilise `TourDraftScreen` en mode édition (paramètre `editingTourId`). Préchargement complet : date, heure, ordre des arrêts existants comme `presetOrder`.
- À la confirmation : `TourRepository.update` (nouvelle méthode, replace-in-place transactionnel — totals + stops réécrits, `id`/`createdAt`/`status` préservés).
- Gestion des stops orphelins (`clientId == null`, client supprimé entre-temps) : exclus du préremplissage, disparaissent silencieusement à la sauvegarde.
- Cas marginal `findById` retournant `null` (tournée supprimée concurremment) : pop avec retour à l'écran précédent.

**Picker — clients déjà sur la tournée**
- `WaitingClientsMultiPicker` étendu avec `alwaysIncludeIds` : les clients de la tournée en cours d'édition restent visibles (et donc décochables) même s'ils ne satisfont plus le filtre « waiting ».
- Loader interne `_clientsByIdsProvider` keyé par string sortée pour éviter les re-fetchs à chaque rebuild (Set/List ont une égalité d'identité en Dart).

**Picker — suggestions par proximité**
- Nouveau use case `FindClientsNearAnchors` (pure, 6 tests). Pour chaque candidat, distance routière min vers un anchor ; inclus si ≤ `radiusMeters`. Anchors toujours inclus (distance 0).
- Provider `nearbyToAnchorsProvider` qui agrège les entrées matrice depuis chaque arrêt de la tournée et applique le use case avec `Settings.defaultRadiusKm`.
- Le picker affiche deux sections : « Suggérés à proximité » et « Autres clients en attente », masquées si vides après filtre. Map-tab inchangé.

**Refactors et fixes collatéraux**
- `tourByIdProvider` promu de privé (dans `tour_detail_screen.dart`) à public dans `state/providers.dart` — l'édition l'invalide après save pour rafraîchir le détail.
- `tour_completion_screen` invalide aussi `tourByIdProvider` (bug pré-existant : le détail montrait « planifiée » après complétion).
- Bug timezone latent dans `_tourFromRow` corrigé (epoch-day décodé en UTC puis reconstruit en local, pattern déjà utilisé dans `markCompleted`).
- Fix UI global : la zone `SafeArea` du status bar sur les routes top-level (en dehors du `StatefulShellRoute`) montrait le noir système. Wrap au niveau de `MaterialApp.router.builder` avec `ColoredBox(theme.colors.background)` — couvre draft/edit/manual picker/optimized config/completion/onboarding/proximity en un seul fix.
- Fix UI : sheet « Nouvelle tournée » (`tours_list_screen`) sans fond — wrap `ColoredBox`. Audit complet des 3 `showFSheet` de l'app, tous OK désormais.
- Sync `tourSelectionProvider` après validation de la sheet « Modifier la sélection » (bug pré-existant : la sélection éditée se perdait au prochain `_refresh`).

**Tests**
- 3 tests `TourRepository.update` (replace stops, isolation entre tournées, atomicité sur FK violation).
- 6 tests `FindClientsNearAnchors`.
- Total branche : 140 tests verts.

#### Écarts vs périmètre initial
- Pas de tests widget pour le flow d'édition. La base de tests widget est quasi inexistante (un seul, `skip: true`) — disproportionné de monter le harness pour ce flow. Smoke test manuel en remplacement.
- Hors scope : suppression de tournée depuis l'écran d'édition (autre feature) ; édition des tournées `completed` (cascade compteurs clients trop complexe à dérouler).

---

### Multi-phones par client
**Mergé sur `main`** — 2026-04-30 (commit de merge `31ad994`)
**Spec :** `docs/superpowers/specs/2026-04-30-multiple-phones-per-client-design.md`
**Plan :** `docs/superpowers/plans/2026-04-30-multiple-phones-per-client.md`

#### Ce qui a été livré
- Migration Drift v7→v8 : `clients.phone` (TEXT nullable) remplacé par `clients.phones` (JSON array via `PhoneListConverter`).
- Helper pur `normalizePhones` (trim + drop-empty + dedup stable) appelé sur tous les writes.
- Domaine `Client` expose `List<String> phones` + getter `principalPhone` (premier élément ou null).
- Formulaire client : éditeur multi-phones reorderable, ajout/suppression, formatter d'input (`PhoneInputFormatter` — FR domestique 10 chiffres, international 11).
- Détail client : chaque numéro affiché sur deux lignes (icône + numéro, puis ligne Appeler/SMS).
- Map popup : actions sur le `principalPhone` uniquement (un seul bouton appel + un seul SMS).
- Recherche client : matching whitespace-insensitive sur tous les numéros.

---

### Ajout manuel d'un historique de tonte
**Mergé sur `main`** — 2026-04-30 (commit `f888b15`)
**Spec :** `docs/superpowers/specs/2026-04-30-manual-history-entries-design.md`
**Plan :** `docs/superpowers/plans/2026-04-30-manual-history-entries.md`

#### Ce qui a été livré

**Données**
- Nouvelle table Drift `manual_history_entries` (FK cascade vers `clients`), `schemaVersion: 6 → 7`. Colonnes : `client_id`, `date` (epoch days), `sheep_count_small`, `sheep_count_large`, `note`, `created_at`, `updated_at`.
- Modèle domaine `ManualHistoryEntry` + `Intervention` étendu d'un discriminant `kind` (`tour | manual`) avec `manualEntryId` nullable.
- Repository `ManualHistoryRepository` (CRUD + filtre saison `listClientDatesSinceEpochDays`).
- `ClientRepository.listInterventionsForClient` fusionne maintenant tour-stops + entrées manuelles, triés par date desc.

**Règles métier**
- À la création d'une entrée manuelle : si la date est strictement plus récente que `lastShearingDate`, on met à jour `lastShearingDate` + `sheepCountSmall/Large` du client (`applyManualEntryToClient`). Sinon no-op.
- À l'édition / suppression : recalcul intégral de l'état dénormalisé du client à partir de l'union des sources (`recomputeClientFromHistory`).
- Une entrée manuelle dans la saison fait basculer le client en statut `done` (sauf s'il a un rdv planifié).

**Statut**
- Priorité inversée : `scheduled > done` (au lieu de `done > scheduled`). Un client avec un rdv planifié ET une tonte passée dans la saison reste affiché comme planifié, pour ne pas masquer le travail à venir.

**UI**
- Bottom sheet `ManualHistoryEntrySheet` (création + édition + suppression avec confirmation), scrollable, fond opaque.
- Bouton `+` dans `ClientHistoryScreen` ; bouton « Ajouter une tonte » sur la fiche client (toujours visible, même historique vide).
- Refonte des lignes d'historique : icône (`scissors` pour tournée, `pencil` pour saisie manuelle) + date prominente + détail muté + total à droite.
- Tap cohérent : ligne tournée → page tournée ; ligne manuelle → sheet d'édition.

**Recherche**
- La recherche client matche aussi le contenu des notes d'historique (manuelles + tournées complétées). `loadClientNotesMap` agrège les deux sources, exposé via `clientNotesMapProvider`.

**Tests**
- 21 tests couche data sur `ClientRepository` (merge, statut, applyManualEntryToClient, recomputeClientFromHistory, loadClientNotesMap).
- 5 tests sur `ManualHistoryRepository` (CRUD + cascade + filtre saison).

#### Écarts vs périmètre initial
- Champs livrés : date, petits moutons, grands moutons, note. Durée et prix non livrés (pas de besoin formulé).
- Saisie en lot : volontairement hors scope.
- Critère « les entrées historiques ne déclenchent aucune logique métier » : non respecté à dessein — choix produit explicite. Une entrée manuelle plus récente écrase `lastShearingDate` + compteurs et compte pour la saison. Sinon le backfill rétroactif n'aurait servi à rien.

---

### Pivot multi-praticien (espèces & catégories)
**Mergé sur `main`** — 2026-05-01 (commit de merge `9a7c687` ; 47 commits)
**Spec :** `docs/superpowers/specs/2026-04-30-multi-praticien-pivot-design.md`
**Plan :** `docs/superpowers/plans/2026-04-30-multi-praticien-pivot.md`

#### Ce qui a été livré

**Domaine — taxonomie à deux niveaux**
- Nouveaux value types : `Species` (id, name, iconKey, archivedAt), `AnimalCategory` (id, speciesId, name, defaultMinutes, defaultPriceCents, archivedAt). Archive plutôt que delete pour préserver les FK historiques.
- `AnimalCount` (categoryId + count) pour l'état courant client.
- `TourStopAnimal` snapshot riche (categoryId + count + categoryNameSnapshot + speciesNameSnapshot + minutesSnapshot) côté tournée et historique manuel — préserve l'affichage si une catégorie est renommée plus tard.
- `Client.animals: List<AnimalCount>` remplace `sheepCountSmall/Large`.
- `ClientStatus.noSheep` → `noAnimals` ; `markerNoSheepColor` → `markerNoAnimalsColor`.
- `Settings` drops `defaultMinutesPerSmall/Large` (la durée vit désormais sur `AnimalCategory.defaultMinutes`).

**Data — Drift schema reset v9 → v11**
- Nouvelles tables `species` + `animal_categories` (FK cascade `onDelete`).
- `clients.animals` (TEXT JSON via `AnimalCountListConverter`).
- `tour_stops.plannedAnimals` / `actualAnimals` (TEXT JSON via `TourStopAnimalListConverter`).
- `manual_history_entries.animals` (TEXT JSON via `TourStopAnimalListConverter`).
- Repos `SpeciesRepository` et `AnimalCategoryRepository` (CRUD + archive).
- Templates seed (`Mouton`, `Cheval`, `Bovin`, `Caprin`) dans `species_seeds.dart`.
- Reset migration `if (from < 11)` (pas d'utilisateurs en prod).

**Use cases & state**
- `BuildTourDraft` + `TourDurationEstimator` consomment des `List<TourStopAnimal>` snapshots.
- `TourDurationResult.totalShearingMinutes` → `totalInterventionMinutes` (vestige mono-vertical neutralisé).
- Providers `activeSpeciesProvider`, `activeCategoriesBySpeciesProvider`, `allCategoriesByIdProvider`, `categoryLookup` câblés dans `state/providers.dart`.

**UI — onboarding & paramètres**
- Onboarding 2-étapes : adresse → sélection des espèces (templates seed + ajout perso via `CustomSpeciesFormSheet`).
- `SpeciesManagementScreen` + `SpeciesEditScreen` : CRUD espèces et catégories, archive/désarchive, restauration de templates.

**UI — widgets signature**
- `AnimalCountsEditor` : input numérique par catégorie, regroupé par espèce (accordéon), section "archivées" si l'utilisateur a des compteurs sur des catégories désormais archivées.
- `AnimalCountsBadges` : modes compact (`"5 Moutons, 4 Chevaux"`) et detailed (breakdown par espèce + catégorie).
- Branchement transversal : fiche client, liste, fiche détail, fiche historique, popup carte, sheet historique manuel, draft de tournée, picker, écran de complétion.

**Helpers & infra**
- `pluralizeFr(word, count)` : pluralisation FR (régulière `+s`, `-al/-aux`, `-au/-eau/-eu/+x`, mots invariables, composés).
- `normalizeAnimalCounts` (drop zeros, dedup par categoryId, sort) appliqué à tous les writes — même pattern que `normalizePhones`.
- `JsonExportService` round-trip pour `animals` (export/import).

**Cleanup post-pivot**
- Neutralisation lexicale exhaustive : `lastShearingDate` → `lastInterventionDate` (DB + domaine + repos + UI), clés l10n `clientsLastShearing*` → `clientsLastIntervention*`, placeholder `{shear}` → `{intervention}` dans `tourDraftSummaryTotal`, `_StatusPin.sheepCount` → `animalCount`, EN string "shearing tour companion" → "tour companion", FR/EN "sans-moutons"/"no-sheep" → "sans animaux"/"no-animals".
- Drop de la feature "Logo de l'app" (`appAvatarKey` + `AvatarPicker` + 4 clés l10n + 3 fichiers + tests) — feature dormante : sélectionnable mais le choix n'était jamais affiché. Surface absente, à reprendre proprement le jour où on aura besoin d'un vrai logo custom (image picker + vraie surface splash/header).
- Refonte du marqueur de l'adresse de départ : drop-pin 48×56 en `theme.colors.primary` avec icône `home`, `_PinPainter` rendu size-aware. Avant : étoile grise 36×36 quasi-invisible.

**Tests**
- 90+ tests ajoutés couvrant les nouveaux types domain, converters, repos species/category, widgets `AnimalCountsEditor` et `AnimalCountsBadges`.
- 186/186 verts à la fin (vs 140 avant le pivot).

#### Écarts vs périmètre initial

- **Branding `Coup'Laine` non touché** : volontairement hors scope. Le rebrand impacte le package Dart (`coup_laine`), `userAgentPackageName`, l'asset `sheep-mascot.png`, le filename `coup_laine.sqlite`, l'asset launcher — autre chantier. Mascotte mouton conservée à l'étape 1 de l'onboarding en attendant.
- **Avatar/Logo de l'app** : initialement prévu dans la spec (`appAvatarKey` + `AvatarPicker` à 6 icônes forui), implémenté **puis retiré** post-merge. Sélectionnable à l'onboarding et aux Settings, mais le choix n'était lu nulle part. Picker incomplet → décision de drop pour ne pas laisser de dette ouverte. Si besoin d'un vrai logo custom plus tard, refonte propre (image picker + vraie surface au démarrage).
- **`AnimalCategory.defaultPriceCents`** : champ en place mais dormant — sera consommé par #6 (catalogue de prestations).
- **Tarification par animal (#4)** : absorbé par #6 — livré.

---

### Catalogue de prestations et tarifs
**Mergé sur `main`** — 2026-05-01 (commit TBD)
**Spec :** `docs/superpowers/specs/2026-05-01-prestation-catalog-design.md`
**Plan :** `docs/superpowers/plans/2026-05-01-prestation-catalog.md`

#### Ce qui a été livré

**Données**
- Nouvelle entité `Prestation` (id, name, priceCents?, minutes?, categoryId?, archivedAt). Nouvelle table `prestations` (soft-delete via `archivedAt`).
- Nouvelle entité `TourStopPrestation` (prestationId, qty, snapshots : nameSnapshot, priceCentsSnapshot, minutesSnapshot, categoryIdSnapshot, categoryNameSnapshot, speciesNameSnapshot). Remplace intégralement `TourStopAnimal`.
- `TourStop.plannedPrestations` / `actualPrestations` (JSON via `TourStopPrestationListConverter`), `manual_history_entries.prestations`.
- `AnimalCategory.defaultMinutes` et `defaultPriceCents` supprimés (remplacés par Prestation).
- Schema 11 → 12 (drop+recreate, pas d'utilisateurs en prod).
- Repository `PrestationRepository` (CRUD + archive/unarchive).

**Catalogue**
- Nouvel écran Settings → « Catalogue de prestations » avec sections par espèce, section « Libres » (categoryId nul), et section « Archivées » (collapsible).
- Formulaire d'édition : choix bind-to-category (dropdown espèce + catégorie, ou libre), helper text prix/durée, boutons archive/unarchive.
- Import/export : prestations incluses dans `JsonExportService` round-trip.

**Picker**
- `PrestationPickerSheet` à la planification d'une tournée (création + édition). Deux sections : « Suggérées » (matching `client.animals` categories) et « Autres ».
- Pré-remplissage des qty depuis `client.animals` snapshots au premier affichage. Snapshots re-capturés à la validation (gelé pour la tournée).
- Libre : qty saisie manuellement, visible dans les deux sections selon contexte.

**Tour draft**
- Intégration picker par stop. Nouveau `tourDraftPrestationsProvider` (StateNotifier) qui gère les prestations pour chaque stop et réinitialise à chaque re-snapshot.
- Ligne résumé « Revenu : N,NNe | Net indicatif : N,NNe » (masquée si revenu == 0).
- `BuildTourDraft` + `TourDurationEstimator` adaptés pour consommer `List<TourStopPrestation>` et `TourStopAnimal` supprimé.

**Bilan**
- Refonte `TourCompletionScreen` : tableau d'ajustement par prestation (qty ±), bouton « + Ajouter une prestation hors plan ».
- Re-capture des snapshots au save. Frais déplacement figés (non recalculés post-snapshot).

**Saisie manuelle**
- Refonte `ManualHistoryEntrySheet` : lignes de prestations (une par prestation, qty), date, note.
- Appel à `applyManualEntryToClient` / `recomputeClientFromHistory` (règle MAX déjà en place).

**Historique**
- `ClientHistoryScreen` affiche prestations avec résumé (« 5 Tontes Petit, 2 Parage ») + détail tronqué (max 3 + « et N autres »).

**Compteurs en cascade**
- `animalCountsFromPrestations` helper : dérive `client.animals` à partir des prestations effectuées via règle MAX (libres ignorées).
- Intégré à `TourRepository.markCompleted`, `ClientRepository.recomputeClientFromHistory`.

**Seeding**
- `kSpeciesSeeds` étendu avec `defaultPrestationName` (ex. « Tonte », « Parage », « Onglons »).
- Onboarding + restauration template auto-créent prestations par catégorie seedée.
- Espèces custom : pas de seeding.

**Tests**
- ~225 verts. Use cases (`BuildTourDraft` avec revenu/net, `TourDurationEstimator` avec prestations, `animalCountsFromPrestations` MAX rule).
- Repos (`PrestationRepository`, `TourRepository.markCompleted` MAX rule, `ClientRepository.recomputeClientFromHistory` cross-source, `ManualHistoryRepository`).

**l10n**
- 33 nouvelles clés (FR + EN) : catalogue, formulaire édition, picker, résumé tour draft, bilan complétion, historique client.

**Cleanup**
- `categoryLookupProvider` remplacé par `categoryDisplayInfoProvider` (sans le champ `minutes` inutilisé).
- Aucun code mort supprimé (AnimalCategory.defaultMinutes/defaultPriceCents restent en place en cas de rollback, seront removés post-validation).
