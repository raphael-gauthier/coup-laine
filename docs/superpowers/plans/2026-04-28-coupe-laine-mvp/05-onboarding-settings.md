# Phase 5 — Onboarding + Settings

**Goal:** First-launch onboarding asks for the home base address (BAN autocomplete) and writes Settings. The Settings tab lets the user view/edit base address, defaults (radius, min/sheep), and reach Data export/import (placeholder for Phase 10).

**Verification at end of phase:** Fresh install routes to onboarding; after submitting an address, the app navigates to the Clients tab and Settings shows the saved values.

---

## Task 5.1: AddressAutocompleteField widget

This is reused by onboarding and the Client form (Phase 6).

**Files:**
- Create: `lib/presentation/widgets/address_autocomplete_field.dart`
- Create: `test/widget/address_autocomplete_field_test.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/widgets/address_autocomplete_field.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/services/ban_geocoding_service.dart';
import '../../state/providers.dart';

typedef GeocodingPickedCallback = void Function(GeocodingResult result);

class AddressAutocompleteField extends ConsumerStatefulWidget {
  final String? initialLabel;
  final GeocodingPickedCallback onPicked;
  final String labelText;

  const AddressAutocompleteField({
    super.key,
    required this.onPicked,
    this.initialLabel,
    this.labelText = 'Adresse',
  });

  @override
  ConsumerState<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState
    extends ConsumerState<AddressAutocompleteField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<GeocodingResult> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  Future<void> _search(String q) async {
    final svc = ref.read(banGeocodingServiceProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await svc.search(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    } on GeocodingException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _results = const [];
      });
    }
  }

  void _pick(GeocodingResult r) {
    _controller.text = r.label;
    setState(() {
      _results = const [];
    });
    widget.onPicked(r);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            errorText: _error,
          ),
          onChanged: _onChanged,
        ),
        if (_results.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              children: _results
                  .map((r) => ListTile(
                        title: Text(r.label),
                        subtitle: Text('${r.postcode} ${r.city}'),
                        onTap: () => _pick(r),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: Write a widget test (basic smoke)**

```dart
// test/widget/address_autocomplete_field_test.dart
import 'package:coupe_laine/infra/services/ban_geocoding_service.dart';
import 'package:coupe_laine/presentation/widgets/address_autocomplete_field.dart';
import 'package:coupe_laine/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('shows suggestions and emits picked result', (tester) async {
    final mockHttp = MockClient((_) async => http.Response(
        '{"type":"FeatureCollection","features":[{"geometry":{"type":"Point","coordinates":[-3.0,48.5]},"properties":{"label":"1 Rue Test 22000 Saint-Brieuc","postcode":"22000","city":"Saint-Brieuc"}}]}',
        200));

    GeocodingResult? picked;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          httpClientProvider.overrideWithValue(mockHttp),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AddressAutocompleteField(
              onPicked: (r) => picked = r,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '1 rue test');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saint-Brieuc'), findsOneWidget);
    await tester.tap(find.textContaining('Saint-Brieuc'));
    await tester.pumpAndSettle();
    expect(picked, isNotNull);
    expect(picked!.postcode, '22000');
  });
}
```

- [ ] **Step 3: Run, expect PASS**

```bash
flutter test test/widget/address_autocomplete_field_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/address_autocomplete_field.dart \
        test/widget/address_autocomplete_field_test.dart
git commit -m "feat(widget): address autocomplete using BAN service"
```

---

## Task 5.2: Onboarding screen

**Files:**
- Create: `lib/presentation/onboarding/onboarding_screen.dart`
- Modify: `lib/core/routing/app_router.dart` (add redirect)

The onboarding decision is: if `settings.read()` returns null, redirect to `/onboarding`.

- [ ] **Step 1: Write the onboarding screen**

```dart
// lib/presentation/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/coordinates.dart';
import '../../domain/models/settings.dart';
import '../../infra/services/ban_geocoding_service.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  GeocodingResult? _picked;
  bool _saving = false;

  Future<void> _confirm() async {
    final picked = _picked;
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).save(
            Settings(
              baseCoordinates: picked.coordinates,
              baseAddressLabel: picked.label,
            ),
          );
      if (!mounted) return;
      context.go('/clients');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Pour commencer, indiquez l'adresse d'où vous partez chaque matin. "
              'Toutes les distances seront calculées depuis ce point.',
            ),
            const SizedBox(height: 16),
            AddressAutocompleteField(
              onPicked: (r) => setState(() => _picked = r),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _picked == null || _saving ? null : _confirm,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Enregistrer l'adresse"),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add route + redirect to `app_router.dart`**

Replace the `routes` list inside `AppRouter.config` with:

```dart
routes: [
  GoRoute(
    path: '/onboarding',
    builder: (_, __) => const OnboardingScreen(),
  ),
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => _ShellScaffold(shell: shell),
    branches: [ /* ... unchanged ... */ ],
  ),
],
redirect: (context, state) async {
  // Only redirect if not already on onboarding
  if (state.matchedLocation == '/onboarding') return null;
  // We don't have a Ref here, so use a top-level helper.
  final hasSettings = await _settingsExist();
  if (!hasSettings) return '/onboarding';
  return null;
},
```

Add the helper at the top of `app_router.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers.dart';
import '../../presentation/onboarding/onboarding_screen.dart';

final _container = ProviderContainer();
Future<bool> _settingsExist() async {
  final s = await _container.read(settingsRepositoryProvider).read();
  return s != null;
}
```

> Caveat: a separate `ProviderContainer` here would create a second database. Better: pass the `ref` via go_router's `refreshListenable`. Refactor the router to take a `Ref`:

```dart
class AppRouter {
  static GoRouter forRef(Ref ref) {
    return GoRouter(
      initialLocation: '/clients',
      redirect: (context, state) async {
        if (state.matchedLocation == '/onboarding') return null;
        final s = await ref.read(settingsRepositoryProvider).read();
        return s == null ? '/onboarding' : null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const OnboardingScreen(),
        ),
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
}

final goRouterProvider = Provider<GoRouter>((ref) => AppRouter.forRef(ref));
```

Update `app.dart` to read the provider:

```dart
class CoupeLaineApp extends ConsumerWidget {
  const CoupeLaineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      // ... unchanged ...
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 3: Run on Android**

```bash
flutter run -d android
```
Expected: fresh install lands on the onboarding screen; entering an address and tapping the button navigates to the empty Clients tab.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/onboarding/ lib/core/routing/app_router.dart lib/app.dart
git commit -m "feat(onboarding): first-launch base address setup"
```

---

## Task 5.3: Settings screen

**Files:**
- Create: `lib/presentation/settings/settings_screen.dart`
- Modify: `lib/core/routing/app_router.dart` (replace placeholder)
- Modify: `lib/l10n/app_fr.arb`, `app_en.arb` (add labels)

- [ ] **Step 1: Add strings**

In `app_fr.arb` add:

```json
{
  "settingsBaseAddressEdit": "Modifier l'adresse",
  "settingsRadiusLabel": "Rayon par défaut (km)",
  "settingsMinPerSheepLabel": "Minutes par mouton (par défaut)",
  "settingsTariffLabel": "Tarif déplacement (€ / 10 km)",
  "settingsExportData": "Exporter les données",
  "settingsImportData": "Importer les données",
  "settingsSave": "Enregistrer"
}
```

Mirror in `app_en.arb`. Run `flutter gen-l10n`.

- [ ] **Step 2: Write the screen**

```dart
// lib/presentation/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/settings.dart';
import '../../state/providers.dart';
import '../widgets/address_autocomplete_field.dart';

final _settingsAsyncProvider = FutureProvider<Settings?>((ref) {
  return ref.watch(settingsRepositoryProvider).read();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(_settingsAsyncProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.tabSettings)),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) => s == null
            ? const SizedBox.shrink()
            : _SettingsForm(initial: s),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  final Settings initial;
  const _SettingsForm({required this.initial});

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late Settings _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  Future<void> _save() async {
    await ref.read(settingsRepositoryProvider).save(_draft);
    ref.invalidate(_settingsAsyncProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Enregistré')));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.settingsBaseAddressTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(_draft.baseAddressLabel),
        const SizedBox(height: 8),
        AddressAutocompleteField(
          labelText: l.settingsBaseAddressEdit,
          onPicked: (r) => setState(() {
            _draft = Settings(
              baseAddressLabel: r.label,
              baseCoordinates: r.coordinates,
              defaultRadiusKm: _draft.defaultRadiusKm,
              defaultMinutesPerSheep: _draft.defaultMinutesPerSheep,
              travelFeeEurosPerBracket: _draft.travelFeeEurosPerBracket,
              bracketKm: _draft.bracketKm,
            );
          }),
        ),
        const Divider(height: 32),
        Text(l.settingsDefaultsTitle,
            style: Theme.of(context).textTheme.titleMedium),
        _IntField(
          label: l.settingsRadiusLabel,
          value: _draft.defaultRadiusKm,
          onChanged: (v) => setState(() => _draft = _copyWith(radiusKm: v)),
        ),
        _IntField(
          label: l.settingsMinPerSheepLabel,
          value: _draft.defaultMinutesPerSheep,
          onChanged: (v) =>
              setState(() => _draft = _copyWith(minPerSheep: v)),
        ),
        _IntField(
          label: l.settingsTariffLabel,
          value: _draft.travelFeeEurosPerBracket,
          onChanged: (v) => setState(() => _draft = _copyWith(tariff: v)),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _save, child: Text(l.settingsSave)),
        const Divider(height: 32),
        Text(l.settingsDataTitle,
            style: Theme.of(context).textTheme.titleMedium),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: Text(l.settingsExportData),
          enabled: false, // wired in Phase 10
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: Text(l.settingsImportData),
          enabled: false, // wired in Phase 10
        ),
      ],
    );
  }

  Settings _copyWith({int? radiusKm, int? minPerSheep, int? tariff}) =>
      Settings(
        baseAddressLabel: _draft.baseAddressLabel,
        baseCoordinates: _draft.baseCoordinates,
        defaultRadiusKm: radiusKm ?? _draft.defaultRadiusKm,
        defaultMinutesPerSheep: minPerSheep ?? _draft.defaultMinutesPerSheep,
        travelFeeEurosPerBracket: tariff ?? _draft.travelFeeEurosPerBracket,
        bracketKm: _draft.bracketKm,
      );
}

class _IntField extends StatefulWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;
  const _IntField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<_IntField> {
  late final TextEditingController _c;
  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: widget.label),
        onChanged: (s) {
          final v = int.tryParse(s);
          if (v != null && v > 0) widget.onChanged(v);
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Replace the settings placeholder route with `SettingsScreen()`**

In `app_router.dart`:

```dart
import '../../presentation/settings/settings_screen.dart';
// ...
GoRoute(
  path: '/settings',
  builder: (_, __) => const SettingsScreen(),
),
```

- [ ] **Step 4: Run on Android**, verify:
- Settings tab loads with current values.
- Editing base address via autocomplete + tapping Save persists.
- Reopening Settings shows updated address.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/settings/ lib/core/routing/app_router.dart lib/l10n/
git commit -m "feat(settings): full settings screen with base + defaults"
```

---

**Phase 5 done.** Onboarding gates the app on first launch; settings are editable.
