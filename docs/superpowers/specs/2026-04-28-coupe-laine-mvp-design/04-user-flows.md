# 4. User flows

Seven core flows. Each is described as steps + key behaviours, not screen-by-screen wireframes (UI iteration happens during implementation).

---

## 1. First launch — set up the base

1. App detects empty `settings` table.
2. Onboarding screen prompts for the home address.
3. User types address; BAN autocomplete shows up to 5 suggestions.
4. User picks one → `base_lat`, `base_lon`, `base_address_label` saved to `settings`.
5. Defaults inserted: `default_radius_km = 15`, `default_minutes_per_sheep = 20`, `travel_fee_euros_per_bracket = 8`, `bracket_km = 10`.

User reaches the empty client list afterwards.

---

## 2. Add a client

1. **New client** screen: name, phone, sheep count, minutes-per-sheep override (placeholder shows the default), notes, address.
2. Address field uses **BAN autocomplete** with 300 ms debounce. Each keystroke (≥ 3 chars) calls `GET https://api-adresse.data.gouv.fr/search?q={query}&limit=5&autocomplete=1`.
3. User picks a suggestion → `lat`, `lon`, `address_label`, `postcode`, `city` populated and shown read-only.
4. On **Save**:
   1. `INSERT INTO clients (...)` with `is_waiting = 0`, `needs_distance_recompute = 1`.
   2. **Matrix calls**: ORS's matrix endpoint returns all `sources × destinations` pairs in one response. We need both directions involving X, but not existing↔existing pairs (already in DB). So **two requests**:
      - Request A: `sources = [X]`, `destinations = [base, c1, ..., cN]` → `N+1` outbound cells (X → all).
      - Request B: `sources = [base, c1, ..., cN]`, `destinations = [X]` → `N+1` inbound cells (all → X).
      - Both requests are far under the 3500-cell-per-request limit (max 201 cells each at 200 clients).
   3. Insert each returned cell into `distance_matrix`.
   4. `UPDATE clients SET needs_distance_recompute = 0 WHERE id = X`.
5. On matrix call failure (network, quota, 5xx): client is **kept** with `needs_distance_recompute = 1`. Banner on the client screen: "Distances not computed — tap to retry." Until cleared, the client is excluded from proximity search and tour planning (filtered at SQL level).

---

## 3. Mark a client "waiting"

Toggle on the client detail screen flips `is_waiting` to 1. Client now appears in:

- The "Waiting clients" list (default home screen tab).
- Proximity search results around any pivot.
- Eligible-pivot list (only waiting clients can be pivots).

The toggle is fully reversible; un-toggling removes the client from those lists.

---

## 4. Search nearby waiting clients

1. From the **Waiting clients** list, user taps a client → "See nearby clients" button.
2. **Proximity** screen opens with:
   - Pivot client name + base distance shown at top.
   - Radius selector (slider with snap points: 5 / 10 / 15 / 20 / 30 km; defaults to `settings.default_radius_km`).
   - Tab switcher: **List** / **Map**.
3. Query (instantaneous, all from local DB):
   ```sql
   SELECT c.*, dm.distance_meters, dm.duration_seconds
   FROM clients c
   JOIN distance_matrix dm ON dm.to_id = c.id
   WHERE dm.from_id = :pivot_id
     AND c.is_waiting = 1
     AND c.needs_distance_recompute = 0
     AND c.id != :pivot_id
     AND dm.distance_meters <= :radius_km * 1000
   ORDER BY dm.distance_meters ASC;
   ```
4. **List view**: rows with name, city, road distance (km, 1 decimal), drive time, sheep count, last shearing (or "never"), badge if `last_shearing_date > 13 months` ago.
5. **Map view**: `flutter_map` centred on the pivot, pin for pivot (distinct colour), pins for results, tap a pin → bottom sheet with the same row details.
6. Each row/pin has a **selection checkbox**. Selected clients accumulate into a draft tour shown as a sticky bottom bar: "3 clients selected — Plan tour".

---

## 5. Confirm a tour

User taps **Plan tour** from the bottom bar.

1. **Draft tour** screen lists pivot + selected clients in selection order.
2. User taps **Optimise order**:
   - Build the sub-matrix from `distance_matrix`: rows for `[base, pivot, ...selected]`.
   - Run **nearest-neighbour** to seed an order, then **2-opt** improvement until no swap improves total drive time. For 5–15 stops this is sub-millisecond.
   - Tour starts and ends at base.
3. UI shows the proposed order with per-stop:
   - Drive time from previous stop.
   - Estimated arrival time (= start time + cumulative drive + cumulative shearing).
   - Estimated departure time (= arrival + `sheep_count × minutes_per_sheep`).
4. Drag-and-drop reorder is allowed; totals recompute live.
5. User picks **planned date** (date picker, default = tomorrow) and **start time** (time picker, default 08:00).
6. **Travel-fee split** computation:
   - Let `S = [stop_0, stop_1, ..., stop_{n-1}]` in visit order (excluding base).
   - `farthest = argmax(distance_matrix[base, stop_i])` for `i in 0..n-1`.
   - `feeFarthest_cents = ceil(distance_matrix[base, farthest] / (bracket_km × 1000)) × travel_fee_euros_per_bracket × 100`.
   - `kmInter_meters = sum(distance_matrix[stop_i, stop_{i+1}]) for i in 0..n-2`.
   - `feeInter_cents = ceil(kmInter_meters / (bracket_km × 1000)) × travel_fee_euros_per_bracket × 100`.
   - `totalFee_cents = feeFarthest_cents + feeInter_cents`.
   - `baseShare_cents = totalFee_cents / n` (integer division). `remainder = totalFee_cents % n`. Each stop's `fee_share_cents` is `baseShare_cents`; the first `remainder` stops in visit order get `+1` cent. Σ shares == totalFee_cents exactly.
7. Save:
   - `INSERT INTO tours (...)` with `status = 'planned'`, frozen totals.
   - `INSERT INTO tour_stops (...)` with `order_index`, snapshots (incl. `client_name_snapshot`), `fee_share_cents`, computed arrival/departure minutes.

---

## 6. Mark a tour completed

1. From the **Tour** screen, user taps **Mark as completed**.
2. Confirmation dialog ("This will update the last-shearing date of N clients").
3. On confirm, in a single transaction:
   ```sql
   UPDATE tours SET status = 'completed', completed_at = :now WHERE id = :tour_id;
   UPDATE clients
     SET last_shearing_date = (SELECT planned_date FROM tours WHERE id = :tour_id),
         is_waiting = 0
     WHERE id IN (SELECT client_id FROM tour_stops WHERE tour_id = :tour_id AND client_id IS NOT NULL);
   ```
4. Completed tour becomes read-only.

---

## 7. View the cost split

On any tour screen (planned or completed), a **Travel-fee split** section shows:

| Client | Distance from base | Share to bill |
|---|---|---|
| Le Gall | 18 km | 13,33 € |
| Tanguy | 12 km | 13,34 € |
| Riou | 25 km | 13,33 € |

Bottom row: total travel fee, kilometre breakdown (farthest-leg km + inter-stop km).

**Share** button copies a plain-text summary to the clipboard / Android Share intent:

```
Tournée du 12/05/2026
- Le Gall : 13,33 €
- Tanguy : 13,34 €
- Riou : 13,33 €
Total : 40,00 €
```
