# TODO

Liste des fonctionnalités à venir. Chaque entrée décrit le besoin, le périmètre et les critères d'acceptation.

---

## 1. Synchronisation cloud

**Statut :** à spécifier
**Priorité :** haute

### Contexte
Les données (clients, tontes, historique, matrices de distances) sont aujourd'hui stockées localement via la base SQLite de l'application. Une perte ou un changement d'appareil entraîne la perte de l'ensemble des données. Une synchro cloud permettrait :
- la sauvegarde automatique,
- la restauration sur un nouvel appareil,
- à terme, le multi-appareil (consultation depuis plusieurs téléphones / tablettes).

### Périmètre
- [ ] Choisir le backend (Firebase / Supabase / backend custom). Décision à documenter.
- [ ] Définir le modèle de synchro : push-only (sauvegarde) vs bidirectionnelle (multi-device).
- [ ] Authentification utilisateur (compte unique propriétaire des données).
- [ ] Stratégie de résolution de conflits si bidirectionnelle (last-write-wins, vector clocks, CRDT...).
- [ ] Schéma cloud aligné sur les tables locales (`clients`, `tontes`, `historique`, `distance_matrix`, etc.).
- [ ] Synchro incrémentale (timestamp `updated_at` ou journal d'opérations) — pas de full dump à chaque fois.
- [ ] Mode hors-ligne : l'app reste utilisable sans réseau, sync différée à la reconnexion.
- [ ] Indicateur d'état de sync dans l'UI (dernière sync, en cours, erreur).

### Critères d'acceptation
- Un utilisateur peut se connecter et retrouver ses données sur un nouvel appareil.
- Une modification effectuée hors-ligne est synchronisée à la reconnexion sans perte.
- Aucun blocage de l'UI pendant la sync.
- Les données sensibles (adresses clients) sont chiffrées en transit (HTTPS) et au repos côté backend.

### Points ouverts
- Coût du backend selon le volume.
- RGPD : localisation des données, consentement, droit à l'effacement.
- Articulation avec la migration `ORS_API_KEY` côté backend (cf. memory) — éventuellement même backend ?

---

## 2. Ajout manuel d'un historique de tonte ✅

**Statut :** fait — mergé sur `main` (2026-04-30, commit `f888b15`)
**Spec :** `docs/superpowers/specs/2026-04-30-manual-history-entries-design.md`
**Plan :** `docs/superpowers/plans/2026-04-30-manual-history-entries.md`

### Ce qui a été livré

**Données**
- Nouvelle table Drift `manual_history_entries` (FK cascade vers `clients`), `schemaVersion: 6 → 7`. Colonnes : `client_id`, `date` (epoch days), `sheep_count_small`, `sheep_count_large`, `note`, `created_at`, `updated_at`.
- Modèle domaine `ManualHistoryEntry` + `Intervention` étendu d'un discriminant `kind` (`tour | manual`) avec `manualEntryId` nullable.
- Repository `ManualHistoryRepository` (CRUD + filtre saison `listClientDatesSinceEpochDays`).
- `ClientRepository.listInterventionsForClient` fusionne maintenant tour-stops + entrées manuelles, triés par date desc.

**Règles métier**
- À la création d'une entrée manuelle : si la date est strictement plus récente que `lastShearingDate`, on met à jour `lastShearingDate` + `sheepCountSmall/Large` du client (`applyManualEntryToClient`). Sinon no-op.
- À l'édition / suppression : recalcul intégral de l'état dénormalisé du client à partir de l'union des sources (`recomputeClientFromHistory`).
- Une entrée manuelle dans la saison fait basculer le client en statut `done` (sauf s'il a un rdv planifié — voir ci-dessous).

**Statut**
- Priorité inversée : `scheduled > done` (au lieu de `done > scheduled`). Un client avec un rdv planifié ET une tonte passée dans la saison reste affiché comme planifié, pour ne pas masquer le travail à venir.

**UI**
- Bottom sheet `ManualHistoryEntrySheet` (création + édition + suppression avec confirmation), scrollable, fond opaque.
- Bouton `+` dans `ClientHistoryScreen` ; bouton « Ajouter une tonte » sur la fiche client (toujours visible, même historique vide).
- Refonte des lignes d'historique sur les deux surfaces : icône (`scissors` pour tournée, `pencil` pour saisie manuelle) + date prominente (`12 mai 2026`) + détail muté + total à droite. Plus de phrase dense.
- Tap cohérent partout : ligne tournée → page tournée ; ligne manuelle → sheet d'édition. Même comportement sur la fiche client et sur l'écran plein historique.

**Recherche**
- La recherche client matche maintenant aussi le contenu des notes d'historique (manuelles + tournées complétées). `loadClientNotesMap` agrège les deux sources, exposé via `clientNotesMapProvider`, branché dans `matchesClient`.

**Localisation**
- 15 nouvelles clés FR/EN (titres du sheet, libellés des champs, confirmations).

**Tests**
- 21 tests couche data sur `ClientRepository` (merge, statut, applyManualEntryToClient avec ses 4 cas, recomputeClientFromHistory, loadClientNotesMap).
- 5 tests sur `ManualHistoryRepository` (CRUD + cascade + filtre saison).
- Test du nouveau ordre de priorité du statut.

### Écarts vs périmètre initial

- **Champs livrés** : date, petits moutons, grands moutons, note. Durée et prix non livrés (pas de besoin formulé).
- **Saisie en lot** : volontairement hors scope. Si le besoin réapparaît, c'est un add-on séparé.
- **Critère « les entrées historiques ne déclenchent aucune logique métier »** : non respecté à dessein — choix produit explicite. Une entrée manuelle plus récente écrase `lastShearingDate` + compteurs et compte pour la saison. Sinon le backfill rétroactif n'aurait servi à rien.
