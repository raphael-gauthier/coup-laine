# Travel fees rework — design

**Date:** 2026-05-06
**Scope:** Refonte des frais de déplacement (calcul par client, saisie au bilan de tournée, champ optionnel sur entrées manuelles, intégration au CA partout).

## 1. Goals

- Calculer les frais de déplacement **par client**, basés sur la distance entre l'adresse de base et le client (plus de division ou de "part" partagée entre stops).
- Permettre à l'utilisateur de **saisir/ajuster** le montant facturé à chaque client lors de la **clôture** de la tournée (valeur calculée comme valeur par défaut).
- Ajouter un champ **`travelFeeCents`** optionnel sur les entrées manuelles d'historique.
- Inclure les frais de déplacement dans le **CA** du client **partout** (KPIs, outstanding, historique).

## 2. Non-goals

- Versioning du schéma backup cloud pour la compatibilité ascendante avec les anciens backups (à traiter dans un suivi dédié).
- Modèle de tranches multi-paliers (ex : grille `0–10/10–20/...`) : on garde le modèle simple `bracketKm × feePerBracket`.
- Distinction "frais payés / frais impayés" séparée du paiement des services : un seul `isPaid` couvre l'ensemble.

## 3. Formule de calcul

```
brackets   = ceil(distance_base_to_client_km / bracketKm)
travelFee € = brackets × feePerBracket
```

- `bracketKm` = setting `tour_bracket_km` (défaut 10).
- `feePerBracket` = setting `tour_fee_eur_per_bracket` (défaut 8).
- Un client à moins de `bracketKm` paie 1 tranche minimum (jamais 0).

**Distance base→client** : on lit en priorité le cache `distance_matrix` (distance routière), avec **haversine** en fallback si la paire n'a pas encore été calculée.

## 4. Modèle de données

### 4.1 Schéma DB (Drizzle / SQLite)

Migration `00XX_travel_fees_rework.sql` :

- `tour_stops` : rename `fee_share_cents` → `travel_fee_cents` (rename de colonne, valeurs préservées).
- `tours` : drop `total_travel_fee_cents`. Total tournée toujours dérivé.
- `manual_history_entries` : add `travel_fee_cents INTEGER` (nullable).

### 4.2 Modèles Zod

- `TourStop.feeShareCents` → `TourStop.travelFeeCents` (rename).
- `Tour.totalTravelFeeCents` : supprimé.
- `ManualHistoryEntry` : ajout `travelFeeCents: z.number().nullable()`.

### 4.3 Backfill

- Aucune transformation des données existantes.
- Les anciennes valeurs de `fee_share_cents` sur tournées clôturées deviennent telles quelles `travel_fee_cents` (= ce qui a été facturé). Conséquence assumée : le CA des clients ayant participé à des tournées passées augmente rétroactivement de la somme de leurs anciennes parts.
- Pour les tournées planifiées non encore clôturées, la valeur reste mais sera écrasée à la clôture.

### 4.4 Backup schema

`src/infra/cloud/backup-schema.ts` : reflète les renames et le nouveau champ. **Compatibilité ascendante** avec backups pré-refonte : point ouvert, à traiter séparément.

## 5. Logique métier

### 5.1 Nouveau use case

`src/domain/use-cases/compute-client-travel-fee.ts`

```ts
interface Input {
  distanceKm: number;       // base → client
  bracketKm: number;        // tour_bracket_km
  feePerBracket: number;    // tour_fee_eur_per_bracket (€)
}
// Returns cents (integer).
export function computeClientTravelFee(input: Input): number {
  const brackets = countBrackets(input.distanceKm, input.bracketKm);
  return Math.round(brackets * input.feePerBracket * 100);
}
```

Réutilise `bracket-counter.ts` (`ceil`) tel quel.

### 5.2 Helper distance

Helper qui résout la distance base→client en interrogeant le cache `distance_matrix` puis en fallback sur `haversineDistanceKm`. Localisation exacte (use case dédié vs helper `lib/`) à décider dans le plan d'implémentation.

### 5.3 Suppressions

- `src/domain/use-cases/cost-split-calculator.ts` : supprimé.
- `tests/domain/use-cases/cost-split-calculator.test.ts` : supprimé.

### 5.4 KPIs et outstanding

**`compute-client-kpis.ts`** : `totalRevenueCents` agrège services + travel fees.

```
totalRevenueCents = sum(services price) + sum(travelFeeCents ?? 0)
```

**`compute-client-outstanding.ts`** : un stop/entrée non-payé(e) ajoute `services + travelFeeCents` à `unpaidCents`.

**`compute-tour-kpis.ts`** : `totalTravelFeeCents` n'est plus passé en input (la colonne disparaît). Calculé en interne via `sum(stops.travelFeeCents)`. `revenueCents` du tour inclut désormais les frais (cohérence "CA partout") ; `travelFeeCents` reste exposé séparément pour affichage.

**`compute-service-kpis.ts`** : non touché.

## 6. Flux applicatif

### 6.1 Planification (`tour-draft-editor.tsx`)

- Suppression de `splitTravelCost`.
- Pour chaque stop : calcul live `computeClientTravelFee({ distanceKm: distanceFromBase(client), bracketKm, feePerBracket })`.
- Affichage **indicatif** par stop (montant attendu pour ce client).
- Header : `total = sum(perStop)`.
- Le draft submit ne porte plus de frais (ni `feeShareCentsByClient`, ni `totalTravelFeeCents`).

### 6.2 Clôture / bilan (`complete.tsx` + `stop-completion-editor.tsx`)

- `stop-completion-editor.tsx` reçoit deux nouvelles props :
  ```ts
  travelFeeCents: number;
  onChangeTravelFee: (cents: number) => void;
  ```
- Champ number € **inline**, sous les services / au-dessus du paiement.
- Pré-rempli avec `computeClientTravelFee(...)` calculé au montage du bilan, **modifiable** par le user.
- `complete.tsx` détient `perStopTravelFees: Record<stopId, number>` et l'envoie dans la mutation `useCompleteWithBilan`. Le repo persiste dans `tour_stops.travel_fee_cents`.
- KPI "Revenu réel" du bilan : `actualRevenueCents = services + sum(perStopTravelFees)`.

### 6.3 Entrée manuelle (`manual-history-form.tsx`)

- Nouveau champ number € **optionnel** "Frais de déplacement", sous les services, avant `PaymentEditor`.
- Bloc total : ligne services + ligne frais + total combiné en bas (parité avec le bilan tournée).
- `UpsertManualHistoryInput` ajoute `travelFeeCents: number | null`.

### 6.4 Lecture historique

- `history-row.tsx` (liste) : un seul montant à droite, `services + travelFee`.
- `[entryId].tsx` (détail) : trois lignes "Services / Frais / Total" quand `travelFeeCents > 0`. Sinon, affichage services seul.

### 6.5 Paiement / outstanding

Un seul `isPaid` par stop / entrée couvre services + frais. Le montant dû d'un stop non payé = `services + travelFeeCents`.

## 7. Settings (`tour-rate.tsx`)

- Clés DB inchangées : `tour_bracket_km`, `tour_fee_eur_per_bracket`.
- Libellés FR adaptés pour refléter le nouveau modèle ("frais facturés à chaque client selon sa distance depuis l'adresse de base", au lieu de "frais répartis sur la tournée").

## 8. i18n

Toutes les nouvelles strings via `t('...')`. Clés en english, valeurs en FR. Exemples :

- `tours.bilan_travel_fee_label` → "Frais de déplacement"
- `history.manual.travel_fee_label` → "Frais de déplacement"
- `history.detail.services`, `history.detail.travel_fee`, `history.detail.total`
- Réécriture de `settings.tour_rate.*`.

## 9. Tests

### Domaine
- **Nouveau** : `compute-client-travel-fee.test.ts` (cases 0 km, < bracket, multi-brackets, valeurs frontières).
- **Supprimé** : `cost-split-calculator.test.ts`.
- **Adapté** : `compute-client-kpis.test.ts`, `compute-client-outstanding.test.ts`, `compute-tour-kpis.test.ts`.

### Data
- **Adapté** : `manual-history-repository.test.ts` (nouveau champ), `client-repository.test.ts` si nécessaire.

### UI
- Pas d'ajout de tests UI (pattern actuel du repo).

## 10. Risques & points ouverts

- **Backup cloud antérieurs** : pas de stratégie de compatibilité ascendante définie ici. À traiter dans un suivi dédié.
- **Augmentation rétroactive du CA client** : conséquence assumée du backfill (Q9 = A). Aucune communication user prévue dans ce scope.
- **Distance haversine en fallback** : précision suffisante pour des tranches de 10 km, mais peut donner des montants différents de la distance routière sur les premières tournées d'une paire client/base avant que le cache soit peuplé.
