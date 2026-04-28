# 3. Data model

All persistence is local SQLite, managed by drift. Coordinates use WGS84 (EPSG:4326), same as BAN and ORS — no projection conversion needed.

## Conventions

- Timestamps: `INTEGER` epoch milliseconds (UTC).
- Dates without time-of-day: `INTEGER` epoch days (UTC midnight).
- Money: `INTEGER` euro cents to avoid floating-point rounding.
- Booleans: `INTEGER` 0/1.
- **`client_id = 0` is reserved** to represent the home base in the distance matrix. Real clients use `id >= 1`.

## Tables

### `settings` (singleton row, `id = 1`)

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK | Always 1, enforced by check |
| `base_address_label` | TEXT | Formatted address from BAN |
| `base_lat` | REAL | |
| `base_lon` | REAL | |
| `default_radius_km` | INTEGER | Default 15 |
| `default_minutes_per_sheep` | INTEGER | Default 20 |
| `travel_fee_euros_per_bracket` | INTEGER | Default 8 |
| `bracket_km` | INTEGER | Default 10 |

### `clients`

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | Starts at 1 (0 reserved for base) |
| `name` | TEXT NOT NULL | |
| `phone` | TEXT | Nullable |
| `address_label` | TEXT NOT NULL | Formatted by BAN |
| `postcode` | TEXT NOT NULL | |
| `city` | TEXT NOT NULL | |
| `lat` | REAL NOT NULL | |
| `lon` | REAL NOT NULL | |
| `sheep_count` | INTEGER NOT NULL | Default 0 |
| `minutes_per_sheep_override` | INTEGER | Nullable; if null, fall back to `settings.default_minutes_per_sheep` |
| `notes` | TEXT | Nullable, free text |
| `is_waiting` | INTEGER NOT NULL | 0/1 |
| `last_shearing_date` | INTEGER | Nullable, derived from completed tours |
| `needs_distance_recompute` | INTEGER NOT NULL | 0/1; flagged when matrix entries are stale or failed |
| `created_at` | INTEGER NOT NULL | |
| `updated_at` | INTEGER NOT NULL | |

Indexes:
- `idx_clients_is_waiting` on `is_waiting`
- `idx_clients_name` on `name` (for search)

### `distance_matrix`

| Column | Type | Notes |
|---|---|---|
| `from_id` | INTEGER NOT NULL | 0 = base, else `clients.id` |
| `to_id` | INTEGER NOT NULL | 0 = base, else `clients.id` |
| `distance_meters` | INTEGER NOT NULL | Road distance from ORS |
| `duration_seconds` | INTEGER NOT NULL | Driving duration from ORS |
| `computed_at` | INTEGER NOT NULL | epoch ms |
| **PK** | (`from_id`, `to_id`) | |

- Stored **directionally** (both `A→B` and `B→A` rows). Road distances are not always perfectly symmetric (one-way streets), and storage cost is trivial (~40k rows max).
- A row where `from_id = to_id` is never stored.
- On client delete: cascade-delete all rows where `from_id = X OR to_id = X`.

### `tours`

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | |
| `planned_date` | INTEGER NOT NULL | epoch days |
| `start_time_minutes` | INTEGER NOT NULL | Minutes since midnight (e.g. 480 = 08:00) |
| `status` | TEXT NOT NULL | `'planned'` or `'completed'` |
| `total_distance_meters` | INTEGER | Frozen when order is confirmed |
| `total_drive_seconds` | INTEGER | Frozen when order is confirmed |
| `total_travel_fee_cents` | INTEGER | In euro cents — sum of `tour_stops.fee_share_cents` |
| `notes` | TEXT | |
| `completed_at` | INTEGER | Nullable |
| `created_at` | INTEGER NOT NULL | |

### `tour_stops`

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PK AUTOINCREMENT | |
| `tour_id` | INTEGER NOT NULL FK → tours.id ON DELETE CASCADE | |
| `client_id` | INTEGER FK → clients.id ON DELETE SET NULL | Nullable — soft FK; if client is deleted later, stop remains historical with snapshot data |
| `client_name_snapshot` | TEXT NOT NULL | Frozen for historical display when client is later deleted |
| `order_index` | INTEGER NOT NULL | 0 = first visit |
| `estimated_arrival_minutes` | INTEGER NOT NULL | Minutes since midnight |
| `estimated_departure_minutes` | INTEGER NOT NULL | |
| `sheep_count_snapshot` | INTEGER NOT NULL | Frozen at planning time |
| `minutes_per_sheep_snapshot` | INTEGER NOT NULL | Frozen at planning time |
| `fee_share_cents` | INTEGER NOT NULL | This stop's share of `tours.total_travel_fee_cents` (see flows for remainder distribution) |

Index:
- `idx_tour_stops_tour_order` on (`tour_id`, `order_index`)
- `idx_tour_stops_client` on (`client_id`) — for "tours for a given client" queries

## Why snapshots on `tour_stops`?

A tour completed last month must remain consistent even if the user later updates a client's `sheep_count` or `minutes_per_sheep_override`. Snapshots make completed tours immutable historical records.

## Migrations

Drift's migration system is used from day one. Initial schema is version 1. Future changes ship a new version with explicit migration steps.
