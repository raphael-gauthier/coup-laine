# 2. Architecture

## Stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter (latest stable) | Android-only build for MVP, code portable to iOS |
| UI components | [Forui](https://forui.dev) | As requested by user |
| Localisation | `flutter_localizations` + `intl` + ARB files | All UI strings in French |
| State management | [Riverpod](https://riverpod.dev) | Confirmed by user |
| Local database | [drift](https://drift.simonbinder.eu) | Typed SQLite, codegen, supports migrations |
| Map display | [`flutter_map`](https://pub.dev/packages/flutter_map) | OpenStreetMap tiles, no API key |
| HTTP | `package:http` | Standard, simple, mockable |
| Secret config | `flutter_dotenv` + `.env` (gitignored) | Confirmed by user |

## External services

| Service | Endpoint | Use | Auth |
|---|---|---|---|
| API Adresse (BAN) | `https://api-adresse.data.gouv.fr/search` | Address autocomplete + geocoding | None (free, public) |
| OpenRouteService | `/v2/matrix/driving-car`, `/v2/directions/driving-car` | Road-distance matrix, route geometries | API key in `.env` |

## Layered design

```
┌──────────────────────────────────────────────────────┐
│  presentation/                                       │
│    Flutter screens, Forui widgets, Riverpod consumers│
├──────────────────────────────────────────────────────┤
│  state/                                              │
│    Riverpod providers (notifiers, async providers)   │
├──────────────────────────────────────────────────────┤
│  domain/                                             │
│    Pure-Dart use cases & business rules:             │
│      - PlanTourUseCase                               │
│      - ComputeCostSplitUseCase                       │
│      - FindNearbyClientsUseCase                      │
│      - EstimateTourDurationUseCase                   │
│    No Flutter, no I/O. 100% testable in `dart test`. │
├──────────────────────────────────────────────────────┤
│  data/                                               │
│    Repositories (interfaces + impls):                │
│      - ClientRepository                              │
│      - TourRepository                                │
│      - DistanceMatrixRepository                      │
│      - SettingsRepository                            │
├──────────────────────────────────────────────────────┤
│  infra/                                              │
│    - drift database (SQLite)                         │
│    - BanGeocodingService (HTTP)                      │
│    - OrsRoutingService (HTTP)                        │
└──────────────────────────────────────────────────────┘
```

**Boundary rules:**

- `domain/` depends on nothing (no Flutter, no `package:http`, no SQL).
- `data/` depends on `domain/` (returns domain models).
- `state/` depends on `domain/` and `data/`.
- `presentation/` depends on `state/`. Never on `data/` or `infra/` directly.

## Configuration

`.env` (gitignored, copied from `.env.example`):

```
ORS_API_KEY=...
```

`flutter_dotenv` loads it at app startup. The key is read once and injected into `OrsRoutingService` via Riverpod provider.

`.env.example` is committed with placeholder values, so a fresh checkout knows what to fill in.

## Project layout

```
lib/
  main.dart
  app.dart                    # MaterialApp + theme + routes
  presentation/
    screens/
      clients/
      tour/
      proximity/
      settings/
    widgets/
  state/
    providers/
  domain/
    models/
    use_cases/
  data/
    repositories/
  infra/
    db/                       # drift schema + DAOs
    services/
    config/                   # dotenv loader
  l10n/                       # ARB files
test/
  domain/                     # pure-Dart tests
  data/                       # in-memory drift tests
  infra/                      # service tests with mocked http.Client
  widget/                     # selective widget tests
```
