# Clients Map Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 4th "Carte" bottom-nav tab showing every client as a status-colored pin, with global color customization in Settings and per-client overrides on the form.

**Architecture:** A new screen reuses `flutter_map` (already in deps from the proximity feature), backed by a derived `ClientStatus` enum (computed from existing client fields). Schema v3 migration adds 4 hex-color columns on `settings` and 1 on `clients`. A reusable `ColorSwatchGrid` widget (16 fixed swatches, 4×4 grid) powers both the Settings dialog and the per-client form section. A mini-popup anchored to a tapped pin offers Appeler/SMS quick actions and tap-through to the full detail.

**Tech Stack:** Flutter 3.41, Forui 0.21, Riverpod 3.3, drift 2.32, flutter_map ≥ 8 (already installed), url_launcher (already installed).

**Spec:** [`../specs/2026-04-28-clients-map-tab-design.md`](../specs/2026-04-28-clients-map-tab-design.md)

---

## File structure

```
lib/
  domain/
    models/
      client.dart                            (M1) MODIFY: add markerColorHex
      settings.dart                          (M1) MODIFY: add 4 marker color fields
    use_cases/
      client_status.dart                     (M1) NEW: ClientStatus enum + extensions
  infra/db/
    tables.dart                              (M1) MODIFY: add columns
    app_database.dart                        (M1) MODIFY: schemaVersion 3 + migration
    app_database.g.dart                      (M1) REGENERATED
  data/repositories/
    settings_repository.dart                 (M1, M3) MODIFY: marker color round-trip + updateMarkerColor()
    client_repository.dart                   (M1, M5) MODIFY: markerColorHex round-trip + setMarkerColor()
  state/
    map_controller.dart                      (M4) NEW: 3 providers
  core/
    routing/
      app_router.dart                        (M4) MODIFY: add /map branch
  presentation/
    widgets/
      color_swatch_picker.dart               (M2) NEW: ColorSwatchGrid + showColorSwatchPicker
    settings/
      settings_screen.dart                   (M3) MODIFY: add color section
    clients/
      client_actions.dart                    (M4) NEW: extracted callPhone/sendSms
      client_detail_screen.dart              (M4) MODIFY: import helpers from client_actions
      client_form_screen.dart                (M5) MODIFY: add color override section
    map/
      map_screen.dart                        (M4) NEW: main screen
      client_pin_popup.dart                  (M5) NEW: anchored popup
test/
  domain/
    client_status_test.dart                  (M1) NEW: status priority unit tests
  data/
    settings_repository_test.dart            (M1, M3) MODIFY: cover marker color round-trip
    client_repository_test.dart              (M1, M5) MODIFY: cover markerColorHex round-trip
```

---

## Conventions

Same as previous plans:
- TDD where it pays off: domain logic + repositories. UI screens get a manual smoke test on device.
- Commit cadence: one commit per task (or per logical sub-step within a task).
- Run command for tests: `flutter test test/path/to/file.dart`.
- Codegen: `dart run build_runner build --delete-conflicting-outputs` after touching drift tables.
- Forui access: `context.theme.{colors,typography}`, `FIcons.<name>`.
- Riverpod 3 legacy: any `StateProvider`/`StateNotifierProvider` needs `import 'package:flutter_riverpod/legacy.dart';`.

---

# Phase M1 — Domain + DB

**Goal at end of phase:** `ClientStatus` enum + extensions exist and are tested. The drift schema is at v3 with 4 marker color columns on `settings` (defaults seeded) and a nullable `marker_color_hex` on `clients`. Both repositories round-trip these values. Existing 54 tests stay green; ~3 new tests pass.

## Task M1.1: ClientStatus enum + extensions + unit tests

**Files:**
- Create: `lib/domain/use_cases/client_status.dart`
- Create: `test/domain/client_status_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/client_status_test.dart
import 'package:coupe_laine/domain/models/client.dart';
import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:coupe_laine/domain/use_cases/client_status.dart';
import 'package:flutter_test/flutter_test.dart';

Client _client({
  bool isWaiting = false,
  bool needsDistanceRecompute = false,
  DateTime? lastShearingDate,
}) {
  return Client(
    id: 1,
    name: 'X',
    addressLabel: '1 rue X',
    postcode: '22000',
    city: 'Saint-Brieuc',
    coordinates: const Coordinates(lat: 48, lon: -3),
    isWaiting: isWaiting,
    needsDistanceRecompute: needsDistanceRecompute,
    lastShearingDate: lastShearingDate,
  );
}

void main() {
  group('ClientStatus', () {
    test('default when nothing special', () {
      expect(_client().status, ClientStatus.defaultStatus);
    });

    test('recompute beats everything', () {
      final c = _client(
        needsDistanceRecompute: true,
        isWaiting: true,
        lastShearingDate: DateTime.now().subtract(const Duration(days: 500)),
      );
      expect(c.status, ClientStatus.recompute);
    });

    test('waiting beats overdue', () {
      final c = _client(
        isWaiting: true,
        lastShearingDate: DateTime.now().subtract(const Duration(days: 500)),
      );
      expect(c.status, ClientStatus.waiting);
    });

    test('overdue when last shearing > 395 days ago and not waiting', () {
      final c = _client(
        lastShearingDate: DateTime.now().subtract(const Duration(days: 500)),
      );
      expect(c.status, ClientStatus.overdue);
    });

    test('default when last shearing recent', () {
      final c = _client(
        lastShearingDate: DateTime.now().subtract(const Duration(days: 200)),
      );
      expect(c.status, ClientStatus.defaultStatus);
    });

    test('default when last shearing is null and no flags', () {
      expect(_client().status, ClientStatus.defaultStatus);
    });
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/domain/client_status_test.dart
```

Expected: compile error (file not found).

- [ ] **Step 3: Implement**

```dart
// lib/domain/use_cases/client_status.dart
import '../models/client.dart';

/// A derived status used to color the client on the map and to drive
/// status-aware UI (badges, filters).
enum ClientStatus { defaultStatus, waiting, overdue, recompute }

/// 13-month rule: a client whose last shearing was more than this many
/// days ago is "overdue".
const int kOverdueThresholdDays = 395;

extension ClientStatusX on Client {
  ClientStatus get status {
    if (needsDistanceRecompute) return ClientStatus.recompute;
    if (isWaiting) return ClientStatus.waiting;
    final last = lastShearingDate;
    if (last != null &&
        DateTime.now().difference(last).inDays > kOverdueThresholdDays) {
      return ClientStatus.overdue;
    }
    return ClientStatus.defaultStatus;
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/domain/client_status_test.dart
```

Expected: 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/use_cases/client_status.dart test/domain/client_status_test.dart
git commit -m "$(cat <<'EOF'
feat(domain): ClientStatus enum + status extension on Client

Derives default/waiting/overdue/recompute from existing fields with
recompute > waiting > overdue > default priority. Hardcoded 13-month
overdue threshold.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M1.2: Add `markerColorHex` to Client model + 4 marker color fields to Settings

**Files:**
- Modify: `lib/domain/models/client.dart`
- Modify: `lib/domain/models/settings.dart`

- [ ] **Step 1: Read both files** to see current shape.

```bash
cat lib/domain/models/client.dart lib/domain/models/settings.dart
```

- [ ] **Step 2: Add `markerColorHex` to Client**

In `lib/domain/models/client.dart`, add `final String? markerColorHex;` next to the other final fields, with default `null` in the constructor and a `copyWith` clause for it. The `Client` class already has `copyWith`-style usage elsewhere — find it and add the new param.

If `Client` doesn't have a `copyWith`, just add the field + `null` default. The repository constructs `Client` directly via the constructor.

Resulting addition (insert next to `notes`):

```dart
  final String? markerColorHex;
```

And in the constructor:

```dart
    this.markerColorHex,
```

- [ ] **Step 3: Add 4 marker color fields to Settings**

In `lib/domain/models/settings.dart`, add:

```dart
  final String markerDefaultColor;
  final String markerWaitingColor;
  final String markerOverdueColor;
  final String markerRecomputeColor;
```

In the constructor (with defaults matching the spec):

```dart
    this.markerDefaultColor = '#4A6B52',
    this.markerWaitingColor = '#C77B5C',
    this.markerOverdueColor = '#B33A3A',
    this.markerRecomputeColor = '#A89F92',
```

If `Settings` has a `copyWith`, add the four fields there too.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/domain/models/
```

Expected: 0 errors. The repositories will not yet read/write these — that comes in M1.4.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/models/client.dart lib/domain/models/settings.dart
git commit -m "$(cat <<'EOF'
feat(domain): markerColorHex on Client, 4 marker colors on Settings

Defaults seeded: sage / terracotta / brick red / muted gray for
default / waiting / overdue / recompute respectively.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M1.3: Drift tables + schema v3 migration + codegen

**Files:**
- Modify: `lib/infra/db/tables.dart`
- Modify: `lib/infra/db/app_database.dart`
- Regenerate: `lib/infra/db/app_database.g.dart`

- [ ] **Step 1: Add columns to drift tables**

In `lib/infra/db/tables.dart`, find `SettingsTable` and add the four columns:

```dart
  TextColumn get markerDefaultColor =>
      text().withDefault(const Constant('#4A6B52'))();
  TextColumn get markerWaitingColor =>
      text().withDefault(const Constant('#C77B5C'))();
  TextColumn get markerOverdueColor =>
      text().withDefault(const Constant('#B33A3A'))();
  TextColumn get markerRecomputeColor =>
      text().withDefault(const Constant('#A89F92'))();
```

In `ClientsTable` add the override:

```dart
  TextColumn get markerColorHex => text().nullable()();
```

- [ ] **Step 2: Bump `schemaVersion` to 3 + write migration**

In `lib/infra/db/app_database.dart`, find `schemaVersion` and `MigrationStrategy`. Update:

```dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(settingsTable, settingsTable.themeMode);
    }
    if (from < 3) {
      await m.addColumn(settingsTable, settingsTable.markerDefaultColor);
      await m.addColumn(settingsTable, settingsTable.markerWaitingColor);
      await m.addColumn(settingsTable, settingsTable.markerOverdueColor);
      await m.addColumn(settingsTable, settingsTable.markerRecomputeColor);
      await m.addColumn(clientsTable, clientsTable.markerColorHex);
    }
  },
  beforeOpen: (details) async {
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

If the existing migration uses different syntax (e.g., a single `onUpgrade` body without nested ifs), keep the same style and just append the v3 branch.

- [ ] **Step 3: Run codegen**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: regenerates `app_database.g.dart`. May take 30-60s.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/infra/db/
flutter test
```

Expected: 0 errors. Existing tests still pass — repositories that haven't been updated yet just don't read the new columns.

- [ ] **Step 5: Commit**

```bash
git add lib/infra/db/
git commit -m "$(cat <<'EOF'
feat(db): schema v3 — marker color columns

Adds marker_default_color / marker_waiting_color / marker_overdue_color
/ marker_recompute_color to the settings table (with hex defaults), and
marker_color_hex (nullable) to the clients table. Migration v2→v3 is
purely additive.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M1.4: Update SettingsRepository to round-trip marker colors + add updateMarkerColor

**Files:**
- Modify: `lib/data/repositories/settings_repository.dart`
- Modify: `test/data/settings_repository_test.dart`

- [ ] **Step 1: Read the current file** to see how `read` and `save` map the row.

```bash
cat lib/data/repositories/settings_repository.dart
```

- [ ] **Step 2: Update `_toDomain` (or whatever the read mapping helper is) and `save`**

Find where `Settings(...)` is constructed in `read()` and add the four new fields:

```dart
return Settings(
  // ... existing fields ...
  markerDefaultColor: row.markerDefaultColor,
  markerWaitingColor: row.markerWaitingColor,
  markerOverdueColor: row.markerOverdueColor,
  markerRecomputeColor: row.markerRecomputeColor,
);
```

In `save()`, find the `SettingsTableCompanion.insert(...)` (or update) and add:

```dart
markerDefaultColor: Value(settings.markerDefaultColor),
markerWaitingColor: Value(settings.markerWaitingColor),
markerOverdueColor: Value(settings.markerOverdueColor),
markerRecomputeColor: Value(settings.markerRecomputeColor),
```

- [ ] **Step 3: Add the `updateMarkerColor` method**

```dart
import '../../domain/use_cases/client_status.dart';

// ... inside class SettingsRepository:

Future<void> updateMarkerColor(ClientStatus status, String hex) async {
  final companion = switch (status) {
    ClientStatus.defaultStatus =>
      SettingsTableCompanion(markerDefaultColor: Value(hex)),
    ClientStatus.waiting =>
      SettingsTableCompanion(markerWaitingColor: Value(hex)),
    ClientStatus.overdue =>
      SettingsTableCompanion(markerOverdueColor: Value(hex)),
    ClientStatus.recompute =>
      SettingsTableCompanion(markerRecomputeColor: Value(hex)),
  };
  await (_db.update(_db.settingsTable)
        ..where((t) => t.id.equals(1)))
      .write(companion);
}
```

- [ ] **Step 4: Add a round-trip test**

In `test/data/settings_repository_test.dart`, add a new test inside the existing `group('SettingsRepository', ...)`:

```dart
test('marker colors round-trip + updateMarkerColor', () async {
  await repo.save(const Settings(
    baseCoordinates: Coordinates(lat: 48.0, lon: -3.0),
    baseAddressLabel: 'base',
  ));
  // Fresh save uses the model defaults — verify them.
  var read = await repo.read();
  expect(read!.markerDefaultColor, '#4A6B52');
  expect(read.markerWaitingColor, '#C77B5C');
  expect(read.markerOverdueColor, '#B33A3A');
  expect(read.markerRecomputeColor, '#A89F92');

  await repo.updateMarkerColor(ClientStatus.waiting, '#FF00FF');
  read = await repo.read();
  expect(read!.markerWaitingColor, '#FF00FF');
  // Other colors unchanged.
  expect(read.markerDefaultColor, '#4A6B52');
});
```

Add the import at the top:

```dart
import 'package:coupe_laine/domain/use_cases/client_status.dart';
```

- [ ] **Step 5: Run**

```bash
flutter test test/data/settings_repository_test.dart
```

Expected: all tests pass (4 prior + 1 new = 5).

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/settings_repository.dart test/data/settings_repository_test.dart
git commit -m "$(cat <<'EOF'
feat(data): SettingsRepository round-trips marker colors + updateMarkerColor

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M1.5: Update ClientRepository to round-trip markerColorHex + add setMarkerColor

**Files:**
- Modify: `lib/data/repositories/client_repository.dart`
- Modify: `test/data/client_repository_test.dart`

- [ ] **Step 1: Read the current file**

```bash
cat lib/data/repositories/client_repository.dart
```

- [ ] **Step 2: Update `_toDomain` (read mapping)**

Find where `Client(...)` is constructed and add:

```dart
markerColorHex: row.markerColorHex,
```

- [ ] **Step 3: Update `insert(...)` to persist the new field**

In the `ClientsTableCompanion.insert(...)` call inside `insert(Client c)`, add:

```dart
markerColorHex: Value(c.markerColorHex),
```

- [ ] **Step 4: Add `setMarkerColor` method**

```dart
Future<void> setMarkerColor(int id, String? hex) async {
  await (_db.update(_db.clientsTable)
        ..where((t) => t.id.equals(id)))
      .write(ClientsTableCompanion(markerColorHex: Value(hex)));
}
```

- [ ] **Step 5: Add a test for round-trip and override**

In `test/data/client_repository_test.dart`, add:

```dart
test('markerColorHex round-trip + setMarkerColor', () async {
  final id = await repo.insert(_newClient());
  expect((await repo.findById(id))!.markerColorHex, isNull);

  await repo.setMarkerColor(id, '#ABCDEF');
  expect((await repo.findById(id))!.markerColorHex, '#ABCDEF');

  await repo.setMarkerColor(id, null);
  expect((await repo.findById(id))!.markerColorHex, isNull);
});
```

Reuse the existing `_newClient()` helper at the top of the test file.

- [ ] **Step 6: Run**

```bash
flutter test test/data/client_repository_test.dart
```

Expected: all tests pass (existing + 1 new).

- [ ] **Step 7: Commit**

```bash
git add lib/data/repositories/client_repository.dart test/data/client_repository_test.dart
git commit -m "$(cat <<'EOF'
feat(data): ClientRepository round-trips markerColorHex + setMarkerColor

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M1.6: Phase M1 sweep

- [ ] **Step 1: Full test + analyze + build**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected:
- 2 pre-existing info-level lints (drift codegen + recursive getters), no new errors.
- All tests green: 54 (pre-existing) + 6 (status) + 1 (settings round-trip) + 1 (client round-trip) = **62 tests**.
- APK builds.

- [ ] **Step 2: No commit** — phase checkpoint only.

---

# Phase M2 — Color swatch picker widget

**Goal at end of phase:** A reusable `ColorSwatchGrid` widget plus a `showColorSwatchPicker` modal exists. Both can be exercised in Settings (M3) and the client form (M5). 16 swatches in a 4×4 grid using the predefined palette.

## Task M2.1: Implement ColorSwatchGrid + showColorSwatchPicker + palette

**Files:**
- Create: `lib/presentation/widgets/color_swatch_picker.dart`

- [ ] **Step 1: Write the file**

```dart
// lib/presentation/widgets/color_swatch_picker.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';

/// 16 predefined color swatches used everywhere a marker color is picked.
const List<Color> kColorSwatchPalette = <Color>[
  Color(0xFF4A6B52), // sage primary
  Color(0xFF7C9C7E), // sage light
  Color(0xFFC77B5C), // terracotta primary
  Color(0xFFE0926D), // terracotta light
  Color(0xFFB33A3A), // brick red
  Color(0xFFD45A5A), // red light
  Color(0xFF8B6F47), // brown
  Color(0xFFC9A66B), // ochre
  Color(0xFF6B6359), // muted warm gray
  Color(0xFFA89F92), // muted light
  Color(0xFF1F1B16), // anthracite
  Color(0xFF456D8C), // slate blue
  Color(0xFF7B96B0), // sky
  Color(0xFF8E6FA1), // muted purple
  Color(0xFFE8C547), // warm yellow
  Color(0xFFE07856), // coral
];

/// An inline grid of swatches. Tap a swatch → [onPicked] fires.
///
/// Used inline in the client form (per-client override) and inside the
/// dialog produced by [showColorSwatchPicker].
class ColorSwatchGrid extends StatelessWidget {
  final Color current;
  final ValueChanged<Color> onPicked;
  const ColorSwatchGrid({
    super.key,
    required this.current,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        for (final color in kColorSwatchPalette)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onPicked(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: color.value == current.value
                    ? Border.all(color: theme.colors.foreground, width: 3)
                    : Border.all(color: theme.colors.border, width: 1),
              ),
            ),
          ),
      ],
    );
  }
}

/// A dialog wrapping [ColorSwatchGrid] with a title and a "Réinitialiser"
/// ghost button that returns [defaultColor].
///
/// Returns the picked color, or `null` if the user dismissed the dialog.
Future<Color?> showColorSwatchPicker({
  required BuildContext context,
  required Color current,
  required Color defaultColor,
  String title = 'Choisir une couleur',
}) {
  return showFDialog<Color>(
    context: context,
    builder: (ctx, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(title),
      body: SizedBox(
        width: 280,
        child: ColorSwatchGrid(
          current: current,
          onPicked: (c) => Navigator.of(ctx).pop(c),
        ),
      ),
      actions: [
        FButton(
          variant: FButtonVariant.ghost,
          onPress: () => Navigator.of(ctx).pop(defaultColor),
          child: const Text('Réinitialiser'),
        ),
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(ctx).pop(),
          child: const Text('Annuler'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Verify compile**

```bash
flutter analyze lib/presentation/widgets/color_swatch_picker.dart
```

Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/color_swatch_picker.dart
git commit -m "$(cat <<'EOF'
feat(widget): ColorSwatchGrid + showColorSwatchPicker

16-swatch predefined palette in a 4×4 grid. Two entry points: the
inline grid (for the per-client form) and the dialog wrapper with
Réinitialiser/Annuler actions (for Settings).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M2.2: Phase M2 sweep

- [ ] **Step 1: Full sweep**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 62 tests still pass, APK builds.

- [ ] **Step 2: No commit** — phase checkpoint.

---

# Phase M3 — Settings color section

**Goal at end of phase:** The Settings screen has a 5th `AppSectionCard` titled "Couleurs des marqueurs" with 4 rows. Tapping a row opens the color picker; saving the color invalidates `_settingsAsyncProvider` so the row's swatch updates.

## Task M3.1: Add color editing section to Settings + helpers

**Files:**
- Modify: `lib/presentation/settings/settings_screen.dart`

- [ ] **Step 1: Read the current settings screen**

```bash
cat lib/presentation/settings/settings_screen.dart
```

Note where the existing 4 sections (Apparence, Adresse, Valeurs par défaut, Données) are inserted. We add the new "Couleurs des marqueurs" section between Valeurs par défaut and Données.

- [ ] **Step 2: Add hex helpers**

At the top-level of `settings_screen.dart` (above the `SettingsScreen` class), add:

```dart
Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
}

String _colorToHex(Color c) {
  // Drop the alpha channel — we only persist RGB.
  final hex = (c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  return '#$hex';
}
```

- [ ] **Step 3: Add the new section in the form**

Below the "Valeurs par défaut" `AppSectionCard` (and the SizedBox(height: AppSpacing.md) following it), insert:

```dart
// --- Couleurs des marqueurs ---
AppSectionCard(
  icon: FIcons.palette,
  title: 'Couleurs des marqueurs',
  child: Column(
    children: [
      _MarkerColorRow(
        label: 'Par défaut',
        currentHex: _draft.markerDefaultColor,
        defaultHex: '#4A6B52',
        status: ClientStatus.defaultStatus,
        onPicked: (hex) => _persistMarkerColor(ClientStatus.defaultStatus, hex),
      ),
      const SizedBox(height: AppSpacing.sm),
      _MarkerColorRow(
        label: 'En attente',
        currentHex: _draft.markerWaitingColor,
        defaultHex: '#C77B5C',
        status: ClientStatus.waiting,
        onPicked: (hex) => _persistMarkerColor(ClientStatus.waiting, hex),
      ),
      const SizedBox(height: AppSpacing.sm),
      _MarkerColorRow(
        label: 'En retard',
        currentHex: _draft.markerOverdueColor,
        defaultHex: '#B33A3A',
        status: ClientStatus.overdue,
        onPicked: (hex) => _persistMarkerColor(ClientStatus.overdue, hex),
      ),
      const SizedBox(height: AppSpacing.sm),
      _MarkerColorRow(
        label: 'À recalculer',
        currentHex: _draft.markerRecomputeColor,
        defaultHex: '#A89F92',
        status: ClientStatus.recompute,
        onPicked: (hex) => _persistMarkerColor(ClientStatus.recompute, hex),
      ),
    ],
  ),
),
const SizedBox(height: AppSpacing.md),
```

- [ ] **Step 4: Add `_persistMarkerColor` to the form state**

Inside `_SettingsFormState`, add:

```dart
Future<void> _persistMarkerColor(ClientStatus status, String hex) async {
  await ref.read(settingsRepositoryProvider).updateMarkerColor(status, hex);
  ref.invalidate(_settingsAsyncProvider);
  ref.invalidate(clientsAsyncProvider);
  // Update local draft so the swatch refreshes immediately.
  setState(() {
    _draft = switch (status) {
      ClientStatus.defaultStatus =>
        _draft.copyWith(markerDefaultColor: hex),
      ClientStatus.waiting =>
        _draft.copyWith(markerWaitingColor: hex),
      ClientStatus.overdue =>
        _draft.copyWith(markerOverdueColor: hex),
      ClientStatus.recompute =>
        _draft.copyWith(markerRecomputeColor: hex),
    };
  });
}
```

> If `Settings` doesn't have a `copyWith`, use a manual rebuild via the constructor with all fields, or add a small `copyWith` to the model first.

- [ ] **Step 5: Add the `_MarkerColorRow` widget**

Append at the bottom of the file:

```dart
class _MarkerColorRow extends ConsumerWidget {
  final String label;
  final String currentHex;
  final String defaultHex;
  final ClientStatus status;
  final ValueChanged<String> onPicked;

  const _MarkerColorRow({
    required this.label,
    required this.currentHex,
    required this.defaultHex,
    required this.status,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    return AppListTile(
      prefix: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _hexToColor(currentHex),
          shape: BoxShape.circle,
          border: Border.all(color: theme.colors.border),
        ),
      ),
      title: label,
      subtitle: currentHex.toUpperCase(),
      suffix: const Icon(FIcons.chevronRight),
      onPress: () async {
        final picked = await showColorSwatchPicker(
          context: context,
          current: _hexToColor(currentHex),
          defaultColor: _hexToColor(defaultHex),
          title: 'Couleur — $label',
        );
        if (picked != null) onPicked(_colorToHex(picked));
      },
    );
  }
}
```

- [ ] **Step 6: Add the imports**

At the top of `settings_screen.dart`, add (alongside existing imports):

```dart
import '../../domain/use_cases/client_status.dart';
import '../widgets/color_swatch_picker.dart';
```

- [ ] **Step 7: Verify**

```bash
flutter analyze lib/presentation/settings/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, 62 tests pass, APK builds.

- [ ] **Step 8: Commit**

```bash
git add lib/presentation/settings/settings_screen.dart
git commit -m "$(cat <<'EOF'
feat(settings): marker color editing section

Adds a 5th AppSectionCard "Couleurs des marqueurs" with 4 AppListTile
rows (one per status). Tapping opens showColorSwatchPicker; choosing
a swatch persists immediately and invalidates settings + clients
providers so the rest of the app rerenders with the new palette.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M3.2: Phase M3 sweep + manual smoke

- [ ] **Step 1: Sweep**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

- [ ] **Step 2: Manual smoke on device** (optional but recommended)

1. Open Settings → see the new "Couleurs des marqueurs" section with 4 rows.
2. Tap "En attente" → see the dialog with the 4×4 grid + Réinitialiser + Annuler.
3. Tap a different swatch → dialog closes → row's swatch + hex update immediately.
4. Tap "Réinitialiser" on another row → row's color resets to its hardcoded default.

- [ ] **Step 3: No commit** — checkpoint only.

---

# Phase M4 — Map screen + bottom nav

**Goal at end of phase:** A new "Carte" tab is reachable from the bottom nav. The screen renders a full-screen `flutter_map` with all clients as colored pins (no popup yet — coming in M5). Search bar finds clients by name; layers panel toggles statuses; recenter button fits the camera to visible clients. The `_callPhone` / `_sendSms` helpers from `client_detail_screen.dart` are extracted for reuse.

## Task M4.1: Extract callPhone / sendSms to client_actions.dart

**Files:**
- Create: `lib/presentation/clients/client_actions.dart`
- Modify: `lib/presentation/clients/client_detail_screen.dart`

- [ ] **Step 1: Create `client_actions.dart`**

```dart
// lib/presentation/clients/client_actions.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> callPhone(BuildContext context, String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'\s'), '');
  final uri = Uri(scheme: 'tel', path: cleaned);
  if (!await launchUrl(uri) && context.mounted) {
    showFToast(
      context: context,
      title: const Text("Impossible de lancer l'appel"),
    );
  }
}

Future<void> sendSms(BuildContext context, String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'\s'), '');
  final uri = Uri(scheme: 'sms', path: cleaned);
  if (!await launchUrl(uri) && context.mounted) {
    showFToast(
      context: context,
      title: const Text("Impossible de lancer l'app SMS"),
    );
  }
}
```

- [ ] **Step 2: Update `client_detail_screen.dart`**

Remove the existing `_callPhone` and `_sendSms` top-level functions from this file. Update the call sites:

- `() => _callPhone(context, client.phone!)` → `() => callPhone(context, client.phone!)`
- `() => _sendSms(context, client.phone!)` → `() => sendSms(context, client.phone!)`

Add the import at the top:

```dart
import 'client_actions.dart';
```

Remove the `url_launcher` import from this file (it's now only used in `client_actions.dart`).

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, all tests pass, APK builds.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/clients/
git commit -m "$(cat <<'EOF'
refactor(clients): extract call/sms helpers into client_actions.dart

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M4.2: Map state providers

**Files:**
- Create: `lib/state/map_controller.dart`

- [ ] **Step 1: Write the file**

```dart
// lib/state/map_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../domain/use_cases/client_status.dart';

/// Statuses currently visible on the map. Default: all four.
final mapVisibleStatusesProvider = StateProvider<Set<ClientStatus>>(
  (_) => ClientStatus.values.toSet(),
);

/// Live search query for the map's search bar (debounced upstream).
final mapSearchQueryProvider = StateProvider<String>((_) => '');

/// id of the client whose pin popup is currently open. `null` = no popup.
final mapSelectedClientIdProvider = StateProvider<int?>((_) => null);
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/state/map_controller.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/state/map_controller.dart
git commit -m "$(cat <<'EOF'
feat(state): map controller providers (visible statuses, search, selected client)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M4.3: Skeleton MapScreen + wire route + 4th tab

> Bundled together: the route + bottom-nav tab can't compile without
> the `MapScreen` class existing, and the screen alone has no entry
> point without the route. So one commit for the lot.

**Files:**
- Create: `lib/presentation/map/map_screen.dart`
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`

- [ ] **Step 1: Add ARB strings**

In `lib/l10n/app_fr.arb` add `"tabMap": "Carte"`. In `app_en.arb` add `"tabMap": "Map"`. Run:

```bash
flutter gen-l10n
```

- [ ] **Step 2: Write the skeleton MapScreen**

```dart
// lib/presentation/map/map_screen.dart
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/client.dart';
import '../../domain/models/settings.dart';
import '../../domain/use_cases/client_status.dart';
import '../../state/map_controller.dart';
import '../../state/providers.dart';
import '../clients/clients_list_screen.dart' show clientsAsyncProvider;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  bool _initialFitDone = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
  }

  void _maybeFitToBounds(List<Client> clients, Settings settings) {
    if (_initialFitDone) return;
    if (clients.isEmpty) return;
    final points = [
      LatLng(settings.baseCoordinates.lat, settings.baseCoordinates.lon),
      for (final c in clients) LatLng(c.coordinates.lat, c.coordinates.lon),
    ];
    if (points.length < 2) return;
    final bounds = LatLngBounds.fromPoints(points);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
        ),
      );
      _initialFitDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsAsyncProvider);
    final settingsAsync = ref.watch(_settingsForMapProvider);
    final visibleStatuses = ref.watch(mapVisibleStatusesProvider);

    return FScaffold(
      child: Material(
        type: MaterialType.transparency,
        child: clientsAsync.when(
          loading: () => const Center(child: FCircularProgress()),
          error: (e, _) => Center(child: Text('$e')),
          data: (clients) {
            return settingsAsync.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (e, _) => Center(child: Text('$e')),
              data: (settings) {
                if (settings == null) {
                  return const Center(child: Text('Settings introuvables'));
                }
                _maybeFitToBounds(clients, settings);
                final visibleClients = clients
                    .where((c) => visibleStatuses.contains(c.status))
                    .toList();
                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      settings.baseCoordinates.lat,
                      settings.baseCoordinates.lon,
                    ),
                    initialZoom: 11,
                    minZoom: 6,
                    maxZoom: 17,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'fr.coupelaine',
                    ),
                    MarkerLayer(
                      markers: [
                        // Base
                        Marker(
                          point: LatLng(
                            settings.baseCoordinates.lat,
                            settings.baseCoordinates.lon,
                          ),
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Icon(
                            FIcons.star,
                            color: _hexToColor(settings.markerDefaultColor),
                            size: 36,
                          ),
                        ),
                        // Clients
                        for (final c in visibleClients)
                          Marker(
                            point: LatLng(
                              c.coordinates.lat,
                              c.coordinates.lon,
                            ),
                            width: 32,
                            height: 40,
                            alignment: Alignment.bottomCenter,
                            child: Icon(
                              FIcons.mapPin,
                              color: _resolveColor(c, settings),
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _resolveColor(Client c, Settings s) {
    if (c.markerColorHex != null) return _hexToColor(c.markerColorHex!);
    return switch (c.status) {
      ClientStatus.recompute => _hexToColor(s.markerRecomputeColor),
      ClientStatus.waiting => _hexToColor(s.markerWaitingColor),
      ClientStatus.overdue => _hexToColor(s.markerOverdueColor),
      ClientStatus.defaultStatus => _hexToColor(s.markerDefaultColor),
    };
  }
}

/// Local provider — reads Settings as an AsyncValue, used only by MapScreen.
final _settingsForMapProvider = FutureProvider<Settings?>(
  (ref) => ref.watch(settingsRepositoryProvider).read(),
);
```

- [ ] **Step 3: Wire the route in `app_router.dart`**

Read the file:

```bash
cat lib/core/routing/app_router.dart
```

In the `branches:` list of the `StatefulShellRoute.indexedStack`, insert between the Tournées branch and the Paramètres branch:

```dart
StatefulShellBranch(routes: [
  GoRoute(
    path: '/map',
    builder: (_, __) => const MapScreen(),
  ),
]),
```

In the `_ShellScaffold` (or wherever the `FBottomNavigationBar` is built), add a 3rd destination between Tournées and Paramètres:

```dart
FBottomNavigationBarItem(
  icon: const Icon(FIcons.mapPin),
  label: Text(l.tabMap),
),
```

Add the imports:

```dart
import '../../presentation/map/map_screen.dart';
```

> If `FIcons.mapPin` clashes visually with the use we have in detail screens, use `FIcons.compass` here instead. Document the choice.

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, 62 tests still pass, APK builds.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/map/ lib/core/routing/app_router.dart lib/l10n/
git commit -m "$(cat <<'EOF'
feat(map): scaffold MapScreen + 4th "Carte" bottom-nav tab

Renders all clients as colored pins (status-driven, with per-client
override when set) on flutter_map / OSM tiles. Initial fit-to-bounds
on first build. Status visibility provider is wired but not yet
exposed in the UI — coming in M4.6.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M4.4: Search bar overlay (renumbered from M4.5)

**Files:**
- Modify: `lib/presentation/map/map_screen.dart`

- [ ] **Step 1: Add a `_removeAccents` helper at the top of `map_screen.dart`** (above `_MapScreenState`):

```dart
String _removeAccents(String s) {
  const tr = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ÿ': 'y',
    'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
    'Ç': 'C',
    'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E',
    'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
    'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Ö': 'O',
    'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U',
  };
  final buf = StringBuffer();
  for (final ch in s.runes) {
    final c = String.fromCharCode(ch);
    buf.write(tr[c] ?? c);
  }
  return buf.toString();
}
```

- [ ] **Step 2: Add a search controller and debounce timer to `_MapScreenState`**

```dart
import 'dart:async';
// ... existing imports

class _MapScreenState extends ConsumerState<MapScreen> {
  // ... existing fields
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      ref.read(mapSearchQueryProvider.notifier).state = q;
    });
  }

  void _flyTo(Client c) {
    _mapController.move(
      LatLng(c.coordinates.lat, c.coordinates.lon),
      14,
    );
    ref.read(mapSelectedClientIdProvider.notifier).state = c.id;
    _searchCtrl.clear();
    ref.read(mapSearchQueryProvider.notifier).state = '';
    FocusManager.instance.primaryFocus?.unfocus();
  }
  // ...
}
```

- [ ] **Step 3: Wrap the FlutterMap in a `Stack` and add the overlay**

Replace the `return FlutterMap(...)` in the success branch with:

```dart
return Stack(
  children: [
    FlutterMap(
      mapController: _mapController,
      options: MapOptions(/* unchanged */),
      children: [/* unchanged */],
    ),
    // Search bar overlay
    Positioned(
      top: AppSpacing.md,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: _SearchOverlay(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        clients: clients,
        onPicked: _flyTo,
      ),
    ),
  ],
);
```

Wrap the entire above `Stack` in `SafeArea(child: ...)` so the overlay sits below the status bar.

- [ ] **Step 4: Implement the `_SearchOverlay` widget**

Append at the bottom of the file (outside `_MapScreenState`):

```dart
class _SearchOverlay extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<Client> clients;
  final ValueChanged<Client> onPicked;

  const _SearchOverlay({
    required this.controller,
    required this.onChanged,
    required this.clients,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final query = ref.watch(mapSearchQueryProvider);

    final results = query.trim().isEmpty
        ? const <Client>[]
        : () {
            final q = _removeAccents(query.toLowerCase());
            return clients
                .where((c) =>
                    _removeAccents(c.name.toLowerCase()).contains(q))
                .take(5)
                .toList();
          }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FCard.raw(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: controller,
                onChange: (v) => onChanged(v.text),
              ),
              hint: 'Rechercher un client…',
            ),
          ),
        ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: 4),
          FCard.raw(
            child: Column(
              children: [
                for (final c in results)
                  FTile(
                    title: Text(c.name),
                    subtitle: Text(c.city),
                    onPress: () => onPicked(c),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, tests pass, APK builds.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/map/map_screen.dart
git commit -m "$(cat <<'EOF'
feat(map): search bar overlay with accent-insensitive matching

Floating FCard with FTextField at the top of the map. Debounced 200ms.
Up to 5 results shown below as FTiles. Tap a result → camera flies
to that client (zoom 14) and the selected-client provider is set
(popup will react in M5).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M4.5: Layers panel + recenter button (renumbered from M4.6)

**Files:**
- Modify: `lib/presentation/map/map_screen.dart`

- [ ] **Step 1: Add the buttons and panel logic**

Below the search overlay positioning (still in the `Stack`'s children), add a row of two icon buttons:

```dart
// Layers + Recenter buttons (top-right)
Positioned(
  top: AppSpacing.md,
  right: AppSpacing.md,
  child: Column(
    children: [
      _MapIconButton(
        icon: FIcons.layers,
        onPress: () => _openLayersPanel(context, settings),
      ),
      const SizedBox(height: AppSpacing.sm),
      _MapIconButton(
        icon: FIcons.locate,
        onPress: () => _recenterOnVisible(visibleClients, settings),
      ),
    ],
  ),
),
```

> The `Positioned(top: AppSpacing.md, ...)` collides with the search overlay's `right: AppSpacing.md`. Adjust by giving the search overlay a `right: 88` padding (so it doesn't run under the buttons). Or — simpler — turn the search overlay into a wrapped `Row` with the two buttons on the right:

Reorganize the overlay structure:

```dart
Positioned(
  top: AppSpacing.md,
  left: AppSpacing.md,
  right: AppSpacing.md,
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _SearchOverlay(/* ... */),
      ),
      const SizedBox(width: AppSpacing.sm),
      Column(
        children: [
          _MapIconButton(
            icon: FIcons.layers,
            onPress: () => _openLayersPanel(context, settings),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MapIconButton(
            icon: FIcons.locate,
            onPress: () => _recenterOnVisible(visibleClients, settings),
          ),
        ],
      ),
    ],
  ),
),
```

- [ ] **Step 2: Implement `_MapIconButton` widget**

Append at the bottom of the file:

```dart
class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPress;

  const _MapIconButton({required this.icon, required this.onPress});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: onPress,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colors.card,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: theme.colors.foreground, size: 20),
      ),
    );
  }
}
```

- [ ] **Step 3: Implement `_openLayersPanel` on `_MapScreenState`**

```dart
Future<void> _openLayersPanel(BuildContext context, Settings settings) async {
  await showFDialog<void>(
    context: context,
    builder: (ctx, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: const Text('Afficher les marqueurs'),
      body: SizedBox(
        width: 280,
        child: Consumer(
          builder: (context, ref, _) {
            final visible = ref.watch(mapVisibleStatusesProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in const [
                  (ClientStatus.defaultStatus, 'Par défaut'),
                  (ClientStatus.waiting, 'En attente'),
                  (ClientStatus.overdue, 'En retard'),
                  (ClientStatus.recompute, 'À recalculer'),
                ])
                  _LayerToggleRow(
                    status: entry.$1,
                    label: entry.$2,
                    settings: settings,
                    isOn: visible.contains(entry.$1),
                    onChanged: (on) {
                      final next = {...visible};
                      if (on) {
                        next.add(entry.$1);
                      } else {
                        next.remove(entry.$1);
                      }
                      ref
                          .read(mapVisibleStatusesProvider.notifier)
                          .state = next;
                    },
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(ctx).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Implement `_LayerToggleRow` widget**

```dart
class _LayerToggleRow extends StatelessWidget {
  final ClientStatus status;
  final String label;
  final Settings settings;
  final bool isOn;
  final ValueChanged<bool> onChanged;

  const _LayerToggleRow({
    required this.status,
    required this.label,
    required this.settings,
    required this.isOn,
    required this.onChanged,
  });

  Color _hex(String h) {
    final cleaned = h.replaceAll('#', '');
    return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = switch (status) {
      ClientStatus.defaultStatus => _hex(settings.markerDefaultColor),
      ClientStatus.waiting => _hex(settings.markerWaitingColor),
      ClientStatus.overdue => _hex(settings.markerOverdueColor),
      ClientStatus.recompute => _hex(settings.markerRecomputeColor),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: theme.typography.md),
          ),
          FSwitch(value: isOn, onChange: onChanged),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Implement `_recenterOnVisible`**

```dart
void _recenterOnVisible(List<Client> visibleClients, Settings settings) {
  final points = <LatLng>[
    LatLng(settings.baseCoordinates.lat, settings.baseCoordinates.lon),
    for (final c in visibleClients) LatLng(c.coordinates.lat, c.coordinates.lon),
  ];
  if (points.length < 2) return;
  final bounds = LatLngBounds.fromPoints(points);
  _mapController.fitCamera(
    CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(40),
    ),
  );
}
```

- [ ] **Step 6: Verify**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, tests pass, APK builds.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/map/map_screen.dart
git commit -m "$(cat <<'EOF'
feat(map): layers panel + recenter button

Two floating circular buttons stacked top-right of the map. Layers
opens an FDialog with 4 toggles + colored dots showing the current
swatches. Recenter fits the camera to the bounding box of currently
visible clients + base.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M4.6: Phase M4 sweep + manual smoke (renumbered from M4.7)

- [ ] **Step 1: Sweep**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, 62 tests pass, APK builds.

- [ ] **Step 2: Manual smoke on device**

Pre-requisite: have at least 3 clients in different communes.

1. Open app → bottom nav now has 4 tabs.
2. Tap "Carte" → see all clients as colored pins, base as a sage star, camera fits to bounds on first load.
3. Type a client's name in the search bar → see up to 5 matches → tap one → map flies to that client, zoom 14.
4. Tap "Layers" icon → panel opens → toggle "En attente" off → see all `waiting` pins disappear → close panel.
5. Tap "Recenter" → map fits back to all visible clients.

Note: tapping a pin does **nothing** yet (popup wired in M5).

- [ ] **Step 3: No commit** — checkpoint only.

---

# Phase M5 — Mini-popup + per-client override

**Goal at end of phase:** Tap a client pin → popup appears anchored above the pin with name, city, sheep count, and Appeler/SMS buttons. Re-tap or tap the body navigates to `/clients/$id`. Per-client color override section is on the form, persists, and renders on the map.

## Task M5.1: ClientPinPopup widget

**Files:**
- Create: `lib/presentation/map/client_pin_popup.dart`

- [ ] **Step 1: Write the widget**

```dart
// lib/presentation/map/client_pin_popup.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../domain/models/client.dart';
import '../clients/client_actions.dart';

class ClientPinPopup extends StatelessWidget {
  final Client client;
  final VoidCallback onOpenDetail;

  const ClientPinPopup({
    super.key,
    required this.client,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hasPhone = client.phone != null && client.phone!.trim().isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenDetail,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260, minWidth: 200),
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: theme.colors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0x33000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    client.name,
                    style: theme.typography.md.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  FIcons.chevronRight,
                  size: 18,
                  color: theme.colors.mutedForeground,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${client.city} · ${client.sheepCount} moutons',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    prefix: const Icon(FIcons.phone),
                    onPress:
                        hasPhone ? () => callPhone(context, client.phone!) : null,
                    child: const Text('Appeler'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    prefix: const Icon(FIcons.messageCircle),
                    onPress:
                        hasPhone ? () => sendSms(context, client.phone!) : null,
                    child: const Text('SMS'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/presentation/map/client_pin_popup.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/map/client_pin_popup.dart
git commit -m "$(cat <<'EOF'
feat(map): ClientPinPopup widget

Floating card with name + city/sheep + Appeler/SMS outline buttons.
Tap on the card body → onOpenDetail. Buttons disabled if phone is
absent.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M5.2: Wire popup into MapScreen state and tap behavior

**Files:**
- Modify: `lib/presentation/map/map_screen.dart`

- [ ] **Step 1: Make pins tappable**

Replace each client `Marker` in the `MarkerLayer` with a tappable version. In the existing `for (final c in visibleClients)` loop, wrap the `Icon` with a `GestureDetector`:

```dart
for (final c in visibleClients)
  Marker(
    point: LatLng(c.coordinates.lat, c.coordinates.lon),
    width: 32,
    height: 40,
    alignment: Alignment.bottomCenter,
    child: GestureDetector(
      onTap: () {
        final selectedId = ref.read(mapSelectedClientIdProvider);
        if (selectedId == c.id) {
          // Re-tap on selected → open detail
          context.push('/clients/${c.id}');
        } else {
          ref.read(mapSelectedClientIdProvider.notifier).state = c.id;
        }
      },
      child: Icon(
        FIcons.mapPin,
        color: _resolveColor(c, settings),
        size: 32,
      ),
    ),
  ),
```

Add the import for `go_router`:

```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 2: Add a popup MarkerLayer above the pins**

After the `MarkerLayer(markers: [base + clients])`, add another layer that conditionally shows the popup at the selected client's coords:

```dart
if (selectedClient != null)
  MarkerLayer(
    markers: [
      Marker(
        point: LatLng(
          selectedClient.coordinates.lat,
          selectedClient.coordinates.lon,
        ),
        width: 280,
        height: 140,
        alignment: const Alignment(0, -1.6),
        child: ClientPinPopup(
          client: selectedClient,
          onOpenDetail: () {
            ref.read(mapSelectedClientIdProvider.notifier).state = null;
            context.push('/clients/${selectedClient.id}');
          },
        ),
      ),
    ],
  ),
```

Compute `selectedClient` at the top of the `data:` builder:

```dart
final selectedId = ref.watch(mapSelectedClientIdProvider);
final selectedClient = selectedId == null
    ? null
    : visibleClients.firstWhereOrNull((c) => c.id == selectedId);
```

Add `import 'package:collection/collection.dart';` for `firstWhereOrNull`.

- [ ] **Step 3: Dismiss popup on map tap (blank area)**

In `MapOptions`, add an `onTap` callback:

```dart
options: MapOptions(
  initialCenter: LatLng(/*…*/),
  initialZoom: 11,
  minZoom: 6,
  maxZoom: 17,
  onTap: (_, __) {
    if (ref.read(mapSelectedClientIdProvider) != null) {
      ref.read(mapSelectedClientIdProvider.notifier).state = null;
    }
  },
),
```

- [ ] **Step 4: Add the popup import**

```dart
import 'client_pin_popup.dart';
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, 62 tests pass, APK builds.

- [ ] **Step 6: Manual smoke on device**

1. Open Carte → tap a pin → popup appears above the pin with name + actions.
2. Tap "Appeler" → dialer opens; popup stays.
3. Tap somewhere on blank map → popup closes.
4. Tap a different pin → popup switches to that one.
5. Re-tap the same pin (popup already open) → navigates to client detail.
6. Tap on the popup body itself → navigates to client detail.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/map/map_screen.dart
git commit -m "$(cat <<'EOF'
feat(map): pin tap → popup, re-tap → detail, blank-tap → dismiss

Popup is rendered as its own MarkerLayer anchored above the selected
client's pin. The progressive interaction model (tap → popup, re-tap
or popup body → detail, blank → dismiss) is wired via the
mapSelectedClientIdProvider.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M5.3: Per-client color override on the form

**Files:**
- Modify: `lib/presentation/clients/client_form_screen.dart`

- [ ] **Step 1: Read the current form**

```bash
cat lib/presentation/clients/client_form_screen.dart
```

Locate where the 3 existing `AppSectionCard`s are (Identité, Adresse, Tonte) and the `_submit` method.

- [ ] **Step 2: Add state fields for the marker color override**

In `_ClientFormScreenState`, add:

```dart
String? _markerColorHex; // null = automatic
```

In `_load()` (the edit-mode loader), set it from the client:

```dart
_markerColorHex = c.markerColorHex;
```

For new clients, it stays `null` (automatic).

- [ ] **Step 3: Add the new section to the form's `Column`**

After the Tonte `AppSectionCard` and its `SizedBox(height: AppSpacing.md)`, insert:

```dart
AppSectionCard(
  icon: FIcons.palette,
  title: 'Couleur sur la carte',
  child: _MarkerColorEditor(
    currentHex: _markerColorHex,
    onChanged: (hex) => setState(() => _markerColorHex = hex),
  ),
),
const SizedBox(height: AppSpacing.md),
```

- [ ] **Step 4: Implement `_MarkerColorEditor`**

Append at the bottom of the file (outside the State class):

```dart
class _MarkerColorEditor extends StatelessWidget {
  final String? currentHex;
  final ValueChanged<String?> onChanged;
  const _MarkerColorEditor({required this.currentHex, required this.onChanged});

  Color _hex(String h) {
    final cleaned = h.replaceAll('#', '');
    return Color(int.parse(cleaned, radix: 16) | 0xFF000000);
  }

  String _toHex(Color c) {
    final hex = (c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    return '#$hex';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isAuto = currentHex == null;
    return Column(
      children: [
        AppListTile(
          prefix: Icon(
            isAuto ? FIcons.circleCheck : FIcons.circle,
            color: isAuto
                ? theme.colors.primary
                : theme.colors.mutedForeground,
          ),
          title: 'Automatique (selon statut)',
          subtitle:
              'Suit la couleur de la palette selon le statut du client.',
          onPress: () => onChanged(null),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppListTile(
          prefix: Icon(
            !isAuto ? FIcons.circleCheck : FIcons.circle,
            color: !isAuto
                ? theme.colors.primary
                : theme.colors.mutedForeground,
          ),
          title: 'Personnalisée',
          subtitle: !isAuto ? currentHex! : null,
          onPress: () {
            // Switch to personalised mode using the first palette swatch.
            if (isAuto) onChanged(_toHex(kColorSwatchPalette.first));
          },
        ),
        if (!isAuto) ...[
          const SizedBox(height: AppSpacing.md),
          ColorSwatchGrid(
            current: _hex(currentHex!),
            onPicked: (c) => onChanged(_toHex(c)),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 5: Add the imports** at the top of `client_form_screen.dart`:

```dart
import '../widgets/color_swatch_picker.dart';
```

(`AppListTile` and `AppSectionCard` should already be imported from the existing form.)

- [ ] **Step 6: Persist `_markerColorHex` in `_submit`**

After the existing `repo.insert(...)` / `repo.updateBasics + repo.updateAddress` block, add:

```dart
await repo.setMarkerColor(id, _markerColorHex);
```

(`id` is the freshly inserted/updated client id. Check that the existing flow uses a variable named `id` — adapt if it's named differently.)

If `repo.insert(Client c)` already persists `markerColorHex` (the field is on the Client model now from M1), you can pass it via the constructor for inserts. For updates, you need the explicit `setMarkerColor` call.

To keep things simple and explicit: always call `setMarkerColor` after insert/update, regardless of whether it changed. It's a single small SQL UPDATE — no perf concern.

- [ ] **Step 7: Verify**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, 62 tests pass, APK builds.

- [ ] **Step 8: Manual smoke on device**

1. Open a client form (edit) → see the new "Couleur sur la carte" section.
2. "Automatique" is selected by default → tap "Personnalisée" → grid appears.
3. Tap a swatch → swatch becomes the active one (thicker border). Save.
4. Open Carte → that client's pin is now in the chosen color.
5. Edit the client again → tap "Automatique" → save → pin reverts to status color.

- [ ] **Step 9: Commit**

```bash
git add lib/presentation/clients/client_form_screen.dart
git commit -m "$(cat <<'EOF'
feat(clients): per-client marker color override on the form

Adds an "Automatique / Personnalisée" toggle. When personalised, the
ColorSwatchGrid is shown inline. The picked hex is persisted via
ClientRepository.setMarkerColor() in the submit flow.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task M5.4: Final phase sweep + manual full-feature smoke

- [ ] **Step 1: Sweep**

```bash
flutter analyze lib/
flutter test
flutter build apk --debug 2>&1 | tail -3
```

Expected: 0 errors, 62 tests pass, APK builds.

- [ ] **Step 2: Full manual walkthrough on device**

Fresh install (`adb shell pm clear fr.coupelaine.coupe_laine`).

1. Onboarding → set base.
2. Add 3 clients with phone numbers, in different communes.
3. Open Carte → see 3 sage pins + base star.
4. Mark one client as waiting → pin should turn terracotta.
5. Tap that pin → popup appears with Appeler/SMS.
6. Tap Appeler → dialer opens.
7. Open Settings → Couleurs des marqueurs → change "En attente" to a different color → return to Carte → that client's pin is now the new color.
8. Edit the client → Couleur sur la carte → Personnalisée → pick a swatch → save → return to Carte → that client's pin is now the per-client color (overrides Settings).
9. Use the Layers panel to hide "Par défaut" → only the customized client remains.
10. Recenter → map fits to the visible client.
11. Search by name → find the client → camera flies + popup opens.

- [ ] **Step 3: Tag**

```bash
git tag -a v0.4.0-map-tab -m "Carte tab + customizable marker colors"
```

---

# Done

Future enhancements (out of scope, can be tackled in follow-up specs):
- Marker clustering for high-density areas (`flutter_map_marker_cluster`).
- Heatmap layer toggle.
- Persisting the layers panel state between sessions.
- Drawing a planned tour's route on the map.
- Starting a tour from the map (the deferred Q1.C — popup gets a "Composer une tournée" action that uses this client as pivot).
- Sharing the marker color customization with the AppBadge styling on the rest of the app.
