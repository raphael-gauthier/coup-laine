# Phase 4 — App shell

**Goal:** Theme, routing, Riverpod providers wired to the database/services, bottom-nav scaffold with three empty tabs (Clients, Tours, Settings).

**Verification at end of phase:** `flutter run` shows the bottom-nav app, switching tabs works, providers can read from an empty database without crashing.

---

## Task 4.1: Riverpod providers for db, repositories, services, http

**Files:**
- Create: `lib/state/providers.dart`

- [ ] **Step 1: Write providers**

```dart
// lib/state/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config/env.dart';
import '../data/repositories/client_repository.dart';
import '../data/repositories/distance_matrix_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/tour_repository.dart';
import '../infra/db/app_database.dart';
import '../infra/services/ban_geocoding_service.dart';
import '../infra/services/ors_routing_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(appDatabaseProvider));
});

final distanceMatrixRepositoryProvider =
    Provider<DistanceMatrixRepository>((ref) {
  return DistanceMatrixRepository(ref.watch(appDatabaseProvider));
});

final tourRepositoryProvider = Provider<TourRepository>((ref) {
  return TourRepository(ref.watch(appDatabaseProvider));
});

final banGeocodingServiceProvider = Provider<BanGeocodingService>((ref) {
  return BanGeocodingService(httpClient: ref.watch(httpClientProvider));
});

final orsRoutingServiceProvider = Provider<OrsRoutingService>((ref) {
  return OrsRoutingService(
    apiKey: Env.orsApiKey,
    httpClient: ref.watch(httpClientProvider),
  );
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/state/providers.dart
git commit -m "feat(state): riverpod providers for db, repos, services"
```

---

## Task 4.2: French strings for the shell

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Replace `app_fr.arb`**

```json
{
  "@@locale": "fr",
  "appTitle": "Coupe-Laine",
  "tabClients": "Clients",
  "tabTours": "Tournées",
  "tabSettings": "Paramètres",
  "emptyClientsTitle": "Aucun client",
  "emptyClientsBody": "Ajoutez votre premier client avec le bouton ci-dessous.",
  "emptyToursTitle": "Aucune tournée",
  "emptyToursBody": "Composez votre première tournée depuis l'onglet Clients.",
  "settingsBaseAddressTitle": "Adresse de base",
  "settingsDefaultsTitle": "Valeurs par défaut",
  "settingsDataTitle": "Données"
}
```

- [ ] **Step 2: Replace `app_en.arb` with parallel keys (placeholder)**

```json
{
  "@@locale": "en",
  "appTitle": "Coupe-Laine",
  "tabClients": "Clients",
  "tabTours": "Tours",
  "tabSettings": "Settings",
  "emptyClientsTitle": "No clients",
  "emptyClientsBody": "Add your first client with the button below.",
  "emptyToursTitle": "No tours",
  "emptyToursBody": "Plan your first tour from the Clients tab.",
  "settingsBaseAddressTitle": "Home base",
  "settingsDefaultsTitle": "Defaults",
  "settingsDataTitle": "Data"
}
```

- [ ] **Step 3: Regenerate**

```bash
flutter gen-l10n
```

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "feat(l10n): add shell strings"
```

---

## Task 4.3: Routing with go_router

**Files:**
- Create: `lib/core/routing/app_router.dart`

- [ ] **Step 1: Write the router**

The router has a stateful shell with three branches (clients/tours/settings) plus modal routes for client form, client detail, proximity, tour draft, tour detail.

```dart
// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder(this.label);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(label)),
        body: Center(child: Text(label)),
      );
}

class AppRouter {
  AppRouter._();

  static final config = GoRouter(
    initialLocation: '/clients',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/clients',
              builder: (_, __) => const _Placeholder('Clients'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tours',
              builder: (_, __) => const _Placeholder('Tournées'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const _Placeholder('Paramètres'),
            ),
          ]),
        ],
      ),
    ],
  );
}

class _ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _ShellScaffold({required this.shell});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l.tabClients,
          ),
          NavigationDestination(
            icon: const Icon(Icons.alt_route_outlined),
            selectedIcon: const Icon(Icons.alt_route),
            label: l.tabTours,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.tabSettings,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/routing/app_router.dart
git commit -m "feat(routing): bottom-nav shell with three empty tabs"
```

---

## Task 4.4: Wire router + Forui theme into `app.dart`

**Files:**
- Modify: `lib/app.dart`

> Forui 0.19+ pattern: set Material theme with `FThemes.X.light.toApproximateMaterialTheme()` and wrap children in `FTheme + FToaster` via the `builder:`. Available palettes include `neutral`, `zinc`, `slate`, `blue`, `violet`, etc. We use `neutral`.

- [ ] **Step 1: Replace `app.dart`**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:coupe_laine/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';

import 'core/routing/app_router.dart';

class CoupeLaineApp extends StatelessWidget {
  const CoupeLaineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...FLocalizations.localizationsDelegates,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      theme: FThemes.neutral.light.toApproximateMaterialTheme(),
      builder: (context, child) => FTheme(
        data: FThemes.neutral.light,
        child: FToaster(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      routerConfig: AppRouter.config,
    );
  }
}
```

- [ ] **Step 2: Run on Android**

```bash
flutter run -d android
```
Expected: bottom navigation bar shows three labels in French; tapping cycles through three placeholder screens.

- [ ] **Step 3: Commit**

```bash
git add lib/app.dart
git commit -m "feat: wire go_router + Forui theme into MaterialApp"
```

---

## Task 4.5: Phase 4 sweep

- [ ] **Step 1: Run all tests**

```bash
flutter test
```
Expected: still green (the smoke test in `test/widget_test.dart` still uses MaterialApp directly so the router refactor doesn't break it).

---

**Phase 4 done.** Skeleton app runs, French navigation, Riverpod available throughout.
