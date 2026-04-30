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

---

## 3. Personnalisation des statuts client (libellés + couleurs) à l'onboarding

**Statut :** à spécifier
**Priorité :** moyenne

### Contexte
Les statuts client (`default`, `waiting`, `scheduled`, `done`, `noSheep`, `banned`) ont aujourd'hui des libellés et couleurs codés en dur (cf. `Settings.markerXxxColor` qui sont déjà persistés mais non éditables côté UI à l'onboarding, et l'écran Réglages qui les expose partiellement). Chaque éleveur a son propre vocabulaire et ses propres préférences visuelles — ce qui est « En attente de RDV » pour l'un est « À voir » pour l'autre.

### Périmètre
- [ ] À la première ouverture (onboarding), proposer une étape supplémentaire « Personnaliser vos statuts ».
- [ ] Pour chaque statut : champ libellé (texte) + sélecteur de couleur (réutiliser `ColorSwatchPicker` déjà en place).
- [ ] Stocker les libellés en base — actuellement seuls les `markerXxxColor` sont persistés ; ajouter `markerXxxLabel` côté `SettingsTable`.
- [ ] Migration Drift `schemaVersion: 7 → 8` (ou la version courante + 1).
- [ ] Réglages : la même surface d'édition reste accessible plus tard via Réglages → Statuts pour modifier ces choix.
- [ ] L'utilisateur peut toujours revenir aux valeurs par défaut (bouton « Réinitialiser »).
- [ ] Les libellés affichés partout (filtres, badges, légendes carte, fiche client) doivent passer par les valeurs de Settings, pas par les clés l10n actuelles `clientStatusXxx`.

### Critères d'acceptation
- À la première ouverture, l'utilisateur peut nommer ses statuts et choisir leurs couleurs avant d'arriver sur la liste clients.
- Les choix sont persistés et survivent au redémarrage.
- Les couleurs et libellés sont reflétés cohéremment sur tous les écrans (carte, liste, fiche, filtres).
- L'utilisateur peut éditer ces choix après-coup depuis Réglages.
- L10n : pour la version EN, les libellés saisis en FR ne sont pas traduits — c'est de la donnée utilisateur, pas du contenu localisable. Documenter ce choix.

### Points ouverts
- Faut-il limiter la longueur du libellé (10/15 caractères) pour éviter de casser les badges ?
- Que se passe-t-il pour `default` et `noSheep` qui sont aujourd'hui des cas particuliers (gris, presque jamais montrés) ? Toujours éditables ou en lecture seule ?
- Le statut `banned` est aussi un toggle métier (`isBanned`) — la perso porte uniquement sur libellé/couleur, pas sur la sémantique.
- Couplage avec la fonctionnalité « Réinitialiser la saison » (cf. clés `settingsSeasonResetXxx`) qui mentionne les statuts par leurs libellés actuels — re-vérifier ce texte.

---

## 4. Tarification par prestation : prix de tonte par animal en plus du forfait kilométrique

**Statut :** à spécifier
**Priorité :** moyenne

### Contexte
Aujourd'hui le calcul de coût d'une tournée se limite aux frais de déplacement (`travelFeeEurosPerBracket` × tranches de `bracketKm`, partagé entre les arrêts via `CostSplitCalculator`). Le revenu réel d'une tournée vient surtout de la tonte elle-même (X € par mouton tondu). Sans intégrer ça, l'éleveur n'a pas de vue globale du chiffre d'affaires d'une tournée — uniquement des frais de route.

### Périmètre
- [ ] Ajouter dans `Settings` un prix par défaut par catégorie d'animal :
  - `defaultPriceSmallCents` (petit mouton)
  - `defaultPriceLargeCents` (grand mouton / bélier)
- [ ] (Optionnel — point ouvert) Permettre un override par client : `Client.priceSmallCents` / `priceLargeCents` nullables — fallback sur les défauts si null.
- [ ] Snapshot des prix dans `tour_stops` au moment de la planification (comme `minutesPerSmallSnapshot` aujourd'hui), pour figer les valeurs même si Settings change après.
- [ ] Calcul dans `BuildTourDraft` :
  - revenu de tonte par arrêt = `actualOrPlannedSmall × priceSmall + actualOrPlannedLarge × priceLarge` (snapshot)
  - revenu total tournée = somme des arrêts
  - frais de déplacement (existant)
  - **net** = revenu - frais (ou revenu brut + frais à part, selon présentation choisie)
- [ ] UI tournée :
  - Sur le détail tournée et le brouillon : afficher en plus du « km au total » un « € prévus » (revenu) et le « € de frais » existant.
  - Sur la complétion : recalculer avec les `actualSmall`/`actualLarge` pour le revenu réel, afficher net réel.
  - Sur le partage texte (`SharePlus`) : ajouter le revenu prévu / réel.
- [ ] Onboarding / Réglages : champs pour saisir les prix par défaut. À l'onboarding ce n'est pas bloquant (peut être laissé à 0 et configuré plus tard).
- [ ] Migration Drift pour ajouter les colonnes (Settings + TourStops, et éventuellement Clients si override).

### Critères d'acceptation
- L'éleveur voit le chiffre d'affaires prévu d'une tournée avant de la confirmer.
- Après complétion, la tournée affiche le revenu réel (basé sur les comptages effectifs) en plus des frais.
- Les prix appliqués à une tournée déjà planifiée ne changent pas si l'éleveur modifie ses prix par défaut après-coup.
- Si les prix valent 0 (cas migration / pas encore configurés), l'app se comporte comme aujourd'hui (pas de revenu affiché, pas de crash).

### Points ouverts
- Un seul prix global ou un override par client ? Cas d'usage : un éleveur peut faire un prix de groupe pour un gros client. À trancher au brainstorming.
- Faut-il distinguer prix de la prestation (par animal) et frais fixes (déplacement de minimum X€) ? Aujourd'hui les frais kilométriques sont déjà découpés en deux (le plus loin + l'inter-stop) — éviter d'empiler une troisième composante sans bonne raison.
- Affichage du « net » (revenu − frais) ou des deux séparément ? Le forfait déplacement est aujourd'hui partagé entre clients, donc le « net par client » a une lecture particulière.
- TVA : hors scope sauf demande explicite.
