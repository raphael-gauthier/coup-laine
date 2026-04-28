# 6. Error handling & edge cases

## Network / API

| Case | Behaviour |
|---|---|
| BAN unreachable (autocomplete) | Address field falls back to **free text** with banner "Suggestions unavailable". Save is **blocked** until coordinates are obtained — without `lat`/`lon` we cannot compute the matrix. |
| BAN returns 0 results | Inline message "Address not found, try a different wording". |
| ORS unreachable / 5xx / 429 / 403 | Client save still succeeds; `needs_distance_recompute = 1`; retry banners as described in [§5](./05-distance-matrix.md#failure-handling). |
| ORS quota exceeded | Same as above, with explicit message: "OpenRouteService daily quota reached — try again later." |
| Device offline | Subtle global banner "Offline — some features disabled". Read-only consultation, planning from existing matrix, and tour completion all work normally. |

## Data integrity

| Case | Behaviour |
|---|---|
| Client save attempted without coordinates | Save button stays disabled until a BAN suggestion is selected. |
| Tour with 0 or 1 stop | **Optimise** is disabled. Single-stop tour is allowed; split puts the entire fee on the one client. |
| Client referenced by `tour_stops` but deleted | Soft FK (`ON DELETE SET NULL`) keeps the historical row. UI displays the `client_name_snapshot` with a "Deleted client" badge; sheep count and fee share remain readable. |
| Editing a client present in a **planned** tour | On save, dialog: "This client is in the planned tour of {date}. Refresh order and fees?" with options **Refresh now** / **Keep as-is**. Completed tours are immutable, so the question doesn't arise. |
| Base address changed with planned tours pending | Banner on each planned tour: "Base changed — re-confirm to refresh distances and fees." |
| Concurrent matrix recompute attempts | Repository serialises matrix-write operations with a single `Mutex` to avoid interleaved partial inserts. |

## Business edge cases

| Case | Behaviour |
|---|---|
| 0 waiting clients | Empty state on the Waiting list with illustration: "No waiting clients — toggle a client when they call". |
| Pivot's radius contains no waiting clients | "No waiting clients within {radius} km of {pivot}." Direct affordance to bump the radius. |
| Tour estimated end time after 20:00 | Orange "Long day" badge on the planning screen. Not a blocker. |
| `last_shearing_date` older than 13 months | Orange "Overdue" badge in client lists. |
| `last_shearing_date` never set (new client) | Shown as "Never shorn" until first completed tour. |
| Tour planned in the past (date < today) | Allowed (user might be back-filling). No special treatment. |
| Two tours planned on the same day with overlapping clients | Allowed. Warning banner: "Client {name} is also in tour {other tour}." |

## Backup

- Database file lives in the app's private storage. Android backs up app private data only if `android:allowBackup="true"`; we leave Android's default.
- **Settings → Data**:
  - **Export**: writes a single JSON file containing all tables (clients, settings, tours, tour_stops, distance_matrix), shared via Android Share intent. User can save to Drive/email/etc.
  - **Import**: reads a JSON file produced by Export, validates schema version, replaces local data after a confirmation dialog ("This will overwrite all current data").
- **30-day reminder**: a passive badge on the Settings entry — not a system notification. Cleared whenever Export runs successfully.

## Crash recovery

- Drift transactions ensure either the full multi-row write succeeds or none of it does. Mid-transaction crashes leave the DB consistent.
- The startup consistency check ([§5](./05-distance-matrix.md#consistency-check-at-startup)) catches the rare case where a non-transactional bulk operation was interrupted.
