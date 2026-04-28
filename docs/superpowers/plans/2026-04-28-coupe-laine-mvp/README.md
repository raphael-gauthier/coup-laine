# Coupe-Laine MVP — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship an Android Flutter app that lets a Brittany sheep shearer manage ~200 clients, find waiting clients near a pivot using a pre-computed road-distance matrix, plan tours with an optimised visit order, and compute the per-client travel-fee split.

**Architecture:** Layered (presentation → state → domain → data → infra). Domain layer is pure Dart and 100% unit-tested. Persistence via drift (SQLite). External APIs: BAN (free, no key) for address autocomplete + geocoding; OpenRouteService (key in `.env`) for road distances. Distance matrix is pre-computed at client-add time and cached in SQLite for instant proximity queries. State managed with Riverpod, UI built with Forui.

**Tech Stack:** Flutter (stable), Dart, Forui, Riverpod, drift, flutter_map, flutter_dotenv, package:http, go_router.

**Spec:** [`../../specs/2026-04-28-coupe-laine-mvp-design/`](../../specs/2026-04-28-coupe-laine-mvp-design/README.md)

---

## Phases

The plan is split per phase for readability. Tackle in order — each phase produces something verifiable on its own.

| # | Phase | Focus | File |
|---|---|---|---|
| 0 | Bootstrap | Flutter project, deps, `.env`, FR i18n, runs on Android | [00-bootstrap.md](./00-bootstrap.md) |
| 1 | Domain layer | Pure-Dart models + use cases (cost split, TSP, duration, brackets) | [01-domain.md](./01-domain.md) |
| 2 | Persistence | drift schema + repositories, in-memory tested | [02-persistence.md](./02-persistence.md) |
| 3 | External services | BAN + ORS clients with mocked HTTP tests | [03-services.md](./03-services.md) |
| 4 | App shell | Theme, routing, Riverpod wiring, bottom nav | [04-app-shell.md](./04-app-shell.md) |
| 5 | Onboarding + Settings | First-launch base setup, settings screen | [05-onboarding-settings.md](./05-onboarding-settings.md) |
| 6 | Clients | List, form, detail, matrix integration | [06-clients.md](./06-clients.md) |
| 7 | Proximity | Pivot search with list + map views | [07-proximity.md](./07-proximity.md) |
| 8 | Tour planning | Compose, optimise, fee split, save | [08-tour-planning.md](./08-tour-planning.md) |
| 9 | Tour lifecycle | List, detail, complete, share | [09-tour-lifecycle.md](./09-tour-lifecycle.md) |
| 10 | Backup + edge cases | Export/import, banners, consistency check | [10-backup-edges.md](./10-backup-edges.md) |
| 11 | Polish + release | Strings audit, smoke checklist, release APK | [11-release.md](./11-release.md) |

---

## File-structure plan

This is the target shape for `lib/` and `test/`. Phases create files into this structure.

```
lib/
  main.dart                                   # bootstraps dotenv + ProviderScope + App
  app.dart                                    # MaterialApp.router with theme + l10n
  core/
    config/
      env.dart                                # dotenv accessors (ORS_API_KEY)
    routing/
      app_router.dart                         # go_router config
  domain/
    models/
      client.dart
      tour.dart
      tour_stop.dart
      settings.dart
      distance_matrix_entry.dart
      coordinates.dart
    use_cases/
      bracket_counter.dart
      cost_split_calculator.dart
      tour_order_optimizer.dart
      tour_duration_estimator.dart
  data/
    repositories/
      client_repository.dart
      tour_repository.dart
      distance_matrix_repository.dart
      settings_repository.dart
  infra/
    db/
      app_database.dart                       # drift database class
      tables.dart                             # drift table definitions
      app_database.g.dart                     # generated
    services/
      ban_geocoding_service.dart
      ors_routing_service.dart
      json_export_service.dart
  state/
    providers.dart                            # repository + service providers
    settings_controller.dart
    clients_controller.dart
    proximity_controller.dart
    tour_draft_controller.dart
    tour_controller.dart
  presentation/
    onboarding/
      onboarding_screen.dart
    settings/
      settings_screen.dart
    clients/
      clients_list_screen.dart
      client_form_screen.dart
      client_detail_screen.dart
    proximity/
      proximity_screen.dart
      proximity_list_view.dart
      proximity_map_view.dart
    tours/
      tour_draft_screen.dart
      tour_detail_screen.dart
      tours_list_screen.dart
    widgets/
      address_autocomplete_field.dart
      recompute_banner.dart
      offline_banner.dart
  l10n/
    app_fr.arb
    app_en.arb                                # placeholder for future iOS/EN
test/
  domain/
    bracket_counter_test.dart
    cost_split_calculator_test.dart
    tour_order_optimizer_test.dart
    tour_duration_estimator_test.dart
  data/
    client_repository_test.dart
    tour_repository_test.dart
    distance_matrix_repository_test.dart
    settings_repository_test.dart
  infra/
    services/
      ban_geocoding_service_test.dart
      ors_routing_service_test.dart
    fixtures/
      ban_search_response.json
      ors_matrix_response.json
      ors_directions_response.json
  widget/
    address_autocomplete_field_test.dart
    client_form_screen_test.dart
    proximity_screen_test.dart
    tour_draft_screen_test.dart
```

---

## Conventions used in every phase

- **TDD where it pays off.** Domain logic, repositories, services: write the test first, watch it fail, implement, watch it pass, commit. UI screens get one or two widget tests at most, exercised after the screen is built.
- **Commit cadence.** One commit per task (or sometimes one per step for tasks with multiple sub-changes). Conventional commits (`feat:`, `test:`, `refactor:`, `chore:`).
- **Run command for tests.** `flutter test test/path/to/file.dart` or `dart test test/path/...` for pure-Dart packages. Both are equivalent inside a Flutter project.
- **Code generation.** `dart run build_runner build --delete-conflicting-outputs` after editing drift tables or freezed models.
- **Forui.** Phases 5+ assume Forui's components are familiar (`FButton`, `FTextField`, `FCard`, `FTabs`, `FDialog`, `FBadge`, etc.). When unsure, fall back to Material widgets — Forui interoperates.
- **Riverpod 3.0 legacy.** `StateProvider`, `StateNotifierProvider`, and `ChangeNotifierProvider` moved out of the main `flutter_riverpod` import in 3.0. Files that use them must add: `import 'package:flutter_riverpod/legacy.dart';` alongside the regular import. Affected files in this plan: `lib/state/proximity_controller.dart`, `lib/state/tour_draft_controller.dart`, `lib/presentation/clients/clients_list_screen.dart`. Plain `Provider`, `FutureProvider`, `StreamProvider`, and the new `Notifier`/`AsyncNotifier` API stay in the main import.

---

## Self-pacing for the user

Phase ETA (rough, solo evenings): 0 → 0.5 day, 1 → 1 day, 2 → 1 day, 3 → 0.5 day, 4 → 0.5 day, 5 → 1 day, 6 → 1.5 days, 7 → 1.5 days, 8 → 1.5 days, 9 → 1 day, 10 → 1 day, 11 → 0.5 day. Total ≈ 11 days of focused work.
