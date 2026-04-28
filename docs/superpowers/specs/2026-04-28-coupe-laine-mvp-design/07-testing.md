# 7. Testing strategy

Pragmatic coverage for a solo MVP: **test calculations and persistence; do not exhaustively test the UI**.

## Unit tests (pure Dart, fast)

Top priority — business logic must be 100% covered.

| Module | Cases |
|---|---|
| `CostSplitCalculator` | 1, 2, 5-stop tours; round-up-bracket on exact multiples (10 km → 1 bracket, 11 km → 2); cent-level rounding (40,01 € / 3 → splits sum exactly to 40,01); zero inter-stops (single stop). |
| `TourOrderOptimizer` | Nearest-neighbour + 2-opt on fixed matrices (3, 5, 10 stops); verifies improvement vs random order; degenerate cases (collinear stops, identical distances). |
| `TourDurationEstimator` | Total = Σ drive + Σ shearing; per-stop arrival/departure from start time; handles non-default `minutes_per_sheep_override`. |
| `DistanceMatrixConsistencyCheck` | Detects clients with missing rows. |
| `BracketCounter` | `ceil(distance_meters / (bracket_km × 1000))` corner cases (0 m, 1 m, exactly 10 000 m, 10 001 m). |

These classes have no Flutter or I/O dependency → run with `dart test` in seconds.

## Repository / persistence tests

Drift supports an **in-memory database** (`NativeDatabase.memory()`) — used for repository tests:

| Repository | Cases |
|---|---|
| `ClientRepository` | Insert + read; cascade delete also clears matrix rows; `needs_distance_recompute` filter applied to "available for tours" query. |
| `TourRepository` | Plan + complete; completion updates `last_shearing_date` and clears `is_waiting`; soft-FK preservation when client deleted post-completion. |
| `DistanceMatrixRepository` | Bulk insert is idempotent (same `(from, to)` upsert); deletion by client id; consistency-check query returns expected ids. |
| `SettingsRepository` | Initial defaults inserted; updates persist. |

## Service tests (mocked HTTP)

| Service | Cases |
|---|---|
| `BanGeocodingService` | Fixture JSON parsing for typical responses; empty results; 4xx/5xx errors map to typed exceptions; query encoding (special chars, accents). |
| `OrsRoutingService` | Matrix response parsing for varied source/destination shapes; 403 (auth/quota), 429 (rate), 5xx, network timeout each map to typed exceptions. |

Use `package:http`'s `Client` mocked with `package:mockito` or hand-rolled fakes. No real network calls in CI.

## Widget tests (selective)

Only screens with a real risk of business regression:

- **New client**: BAN autocomplete flow; save disabled until coordinates obtained; save triggers matrix call (via mocked service).
- **Tour planning**: order display; drag-and-drop reorder recomputes totals; fee split table reflects current order.
- **Proximity**: radius slider change refilters list/map.

Skip pixel-perfect snapshots; those churn on every UI tweak.

## Manual smoke checklist

Run on a real Android device before each release build:

1. Set base address.
2. Add 3 clients at different distances.
3. Inspect `distance_matrix` (debug screen or DB browser) — expect `2 × (n+1) × n` rows for n clients (excluding self-pairs).
4. Toggle 2 clients waiting, run proximity around the third, compose a tour.
5. Verify suggested order, arrival times, fee split.
6. Mark tour completed → verify each client's `last_shearing_date` and `is_waiting`.
7. Toggle airplane mode mid-flow; verify graceful degradation.
8. Export → reinstall app → import → verify integrity.

## Out of MVP

- No CI/CD configured. `flutter test` is run locally before releases.
- No end-to-end tests (Maestro/Patrol). Overkill for solo use.
- No performance/load testing. Volumes are small (200 clients, ~10 tours/month).
