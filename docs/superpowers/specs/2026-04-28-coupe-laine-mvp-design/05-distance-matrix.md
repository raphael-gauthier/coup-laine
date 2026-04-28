# 5. Distance matrix lifecycle

The pre-computed road-distance matrix is the keystone of the app. Proximity search reads from it (instant, no network), so all writes need to be careful.

## Volumetrics

- 200 clients + 1 base = 201 nodes max.
- Directional storage = up to 201 × 200 = 40 200 rows. Trivial for SQLite.
- ORS free tier: matrix endpoint allows up to 3500 cells per request, 500 requests/day. All real operations fit easily within this.

## Operations

### Add a client X

Two matrix requests, no more:

1. `sources = [X]`, `destinations = [base, all existing clients]` → `N+1` outbound rows.
2. `sources = [base, all existing clients]`, `destinations = [X]` → `N+1` inbound rows.

Both requests fit far under the 3500-cell limit (max 201 cells each at the limit of 200 clients).

Bulk-insert all rows in a single transaction. Then clear `needs_distance_recompute` on X.

### Update a client's address

When a client picks a different BAN suggestion (or edits and re-validates the address):

1. `DELETE FROM distance_matrix WHERE from_id = X OR to_id = X;`
2. Set `needs_distance_recompute = 1` on the client.
3. Re-run the "Add a client" flow's matrix calls (now with X already in the DB but matrix-less).

### Update the base address

Rarer — happens on a real move. Explicit user action: **Settings → Change base → Recompute distances**.

1. Update `settings` row.
2. `DELETE FROM distance_matrix WHERE from_id = 0 OR to_id = 0;`
3. Single matrix call: `sources = [base, all clients]`, `destinations = [base, all clients]` (or two narrower calls touching only base ↔ all clients to halve the work). Bulk-insert.
4. Recommend reviewing planned (not completed) tours, since their stored `total_distance_meters` and travel fees referenced the old base. Show a banner on each affected planned tour: "Base changed — re-confirm to refresh distances and fees."

### Delete a client

Cascade `DELETE FROM distance_matrix WHERE from_id = X OR to_id = X;`. No API call.

If the client has tour_stops in **completed** tours, those keep `client_id` (soft FK with `ON DELETE SET NULL`) so the historical record is preserved with a "Client deleted" label.

## Failure handling

Any matrix call can fail (network, ORS quota exceeded, 5xx). Strategy:

- The **client record itself is preserved** (creation/edit isn't blocked by network failure — the user might be on a poor signal at the farm).
- `needs_distance_recompute = 1` flags the affected client.
- A banner on the client detail screen: **"Distances not computed — tap to retry"**.
- A banner on the home screen if any client has `needs_distance_recompute = 1`: **"N clients have missing distances — tap to retry all"**.
- Until the flag is cleared, the client is filtered out of proximity search results and cannot be added to a tour. This prevents a tour from being planned with unknown distances.

## Consistency check at startup

Cheap sanity check on app launch (executed asynchronously, not blocking UI):

```sql
-- Find clients with fewer than 2*N matrix rows (where N = total clients + 1 base)
SELECT c.id
FROM clients c
LEFT JOIN distance_matrix dm ON dm.from_id = c.id OR dm.to_id = c.id
WHERE c.needs_distance_recompute = 0
GROUP BY c.id
HAVING COUNT(dm.rowid) < 2 * (SELECT COUNT(*) FROM clients);
```

For each result: set `needs_distance_recompute = 1`. The retry banner will surface them. This guards against rare crashes mid-bulk-insert.

## Why not Haversine fallback for proximity?

The user explicitly chose pre-computed road distances over straight-line. Haversine can mislead in rural Brittany where rivers, estuaries, and twisty roads make road distance significantly larger than great-circle distance. Sticking to road distance keeps the proximity feature trustworthy.
