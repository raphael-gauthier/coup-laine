# TODO

Index des fonctionnalités. Le brief détaillé (périmètre, critères d'acceptation, points ouverts) est produit lors du brainstorming au moment de la spec — cette liste reste un index : titre, contexte court, et les rares choses importantes à ne pas perdre entre deux sessions.

---

## À venir

### 1. Synchronisation cloud — priorité haute
Sauvegarde + restauration sur un nouveau device, à terme multi-device. Prérequis : choix du backend (Firebase / Supabase / custom), push-only vs bidirectionnel, auth, mode offline avec sync différée. À articuler avec la migration `ORS_API_KEY` côté backend (cf. memory).

### 3. Personnalisation des statuts client — priorité moyenne
Les statuts (`waiting`, `scheduled`, `done`, `noSheep`, `banned`) ont libellés et couleurs en dur. À l'onboarding + dans Réglages, l'utilisateur doit pouvoir les nommer et choisir leurs couleurs. Les couleurs sont déjà persistées (`Settings.markerXxxColor`) ; il faut ajouter les libellés en base et brancher l'UI dessus partout (badges, légende carte, filtres, fiche).

### 4. Tarification par animal — priorité moyenne
Aujourd'hui une tournée n'affiche que les frais de déplacement. Ajouter prix par catégorie d'animal (`defaultPriceSmallCents` / `LargeCents`), snapshot dans `tour_stops`, et un calcul revenu / net dans `BuildTourDraft`. **Sera probablement absorbé par #6** si on y va direct — utile uniquement comme phase 1 minimale si #5/#6 sont repoussés.

### 5. Pivot multi-praticien (espèces à l'onboarding) — priorité haute (prérequis à #6 et #7)
L'app est mono-vertical : tonte de moutons (`sheepCountSmall/Large`, libellés, mascotte, l10n — tout est en dur). Élargir à tout praticien animalier itinérant (dentistes équins, ostéopathes animaliers, vétérinaires de campagne, maréchaux-ferrants, parage…). À l'onboarding, l'utilisateur choisit ses espèces ; les compteurs adaptés se débloquent. **Refactor lourd** côté domaine, l10n, branding (`Coup'Laine` est explicitement orienté tonte — rebrand à discuter). À trancher au brainstorming : compteurs par espèce, par catégorie générique, ou hybride.

### 6. Catalogue de prestations et tarifs — priorité haute (dépend de #5, supersede #4)
Une fois multi-praticien, l'utilisateur définit son catalogue de prestations (label, prix, durée estimée, espèces applicables). À la planification, sélection par arrêt avec quantité — un arrêt peut combiner plusieurs prestations. Snapshot dans `tour_stops` pour figer les valeurs. Base nécessaire à #7. Catalogues préconfigurés selon les espèces actives au gain de temps initial.

### 7. Génération de facture + envoi client — priorité haute (dépend de #6)
PDF facture par client par tournée, conforme légalement : numérotation continue (`FAC-2026-0001`), mentions, identité praticien saisie dans Settings, totaux HT/TVA/TTC, facture immuable une fois émise. Envoi via email natif + partage `share_plus`. **Vigilance** : conformité anti-fraude TVA française (loi 2018, logiciels de facturation certifiés), spécificités micro-entrepreneur. Phase 1 : template figé, pas de mode paiement, pas de SMS.

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
