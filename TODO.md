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

## 2. Ajout manuel d'un historique de tonte

**Statut :** à spécifier
**Priorité :** moyenne

### Contexte
Lors de la prise en charge d'un nouveau client, l'utilisateur connaît souvent l'historique des tontes des années précédentes (effectuées par lui hors de l'app, ou par un prédécesseur). Aujourd'hui seules les tontes saisies dans l'app sont enregistrées ; il n'existe pas de moyen de saisir rétroactivement une tonte passée pour enrichir la fiche client.

### Périmètre
- [ ] Depuis la fiche client, ajouter une action « Ajouter une tonte passée » / « Ajouter à l'historique ».
- [ ] Formulaire dédié avec au minimum :
  - date de la tonte (sélecteur de date, antérieure à aujourd'hui),
  - durée ou prix (optionnel),
  - notes libres (optionnel).
- [ ] Marquer ces entrées comme « historiques » (saisies a posteriori) pour les distinguer des tontes réalisées via l'app — flag en base ou table dédiée.
- [ ] Affichage dans la timeline / liste des tontes du client, avec un visuel différencié (icône, libellé « historique »).
- [ ] Édition et suppression possibles d'une entrée historique.
- [ ] Prise en compte (ou exclusion explicite) de ces entrées dans les statistiques et la planification.

### Critères d'acceptation
- L'utilisateur peut, en ≤ 3 taps depuis la fiche client, ajouter une tonte datée d'une année précédente.
- L'entrée apparaît dans l'historique du client, triée chronologiquement avec les autres tontes.
- Une entrée historique est visuellement distincte d'une tonte réelle.
- Les entrées historiques ne déclenchent aucune logique métier liée au présent (pas de notification, pas de relance).

### Points ouverts
- Champs minimums vraiment requis (date seule suffisante ?).
- Faut-il permettre la saisie en lot (import CSV / multi-dates) ou uniquement une à une ?
- Impact sur la stat « dernière tonte » : on prend la plus récente toutes sources confondues, ou on distingue ?
