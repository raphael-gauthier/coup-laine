# Multiple phones per client — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single nullable `clients.phone` with an ordered list of phone numbers stored as a JSON array. The first element is the principal number, used by default for call/SMS actions on the map popup. The client detail surface lists every number with its own Appeler/SMS buttons. The form lets the user add, remove, and reorder numbers.

**Architecture:** Drift `TextColumn` with a `TypeConverter<List<String>, String>` that JSON-encodes the list. Domain `Client` exposes `List<String> phones` and a `principalPhone` getter. A pure helper `normalizePhones` (trim + drop-empty + stable dedupe) gates every write through the repository. The single `phone` column is dropped via SQLite `ALTER TABLE … DROP COLUMN` (already used at v4) inside a v7 → v8 migration.

**Tech Stack:** Flutter 3.41, Drift 2.32, Riverpod 3, ForUI, SQLite ≥ 3.35.

**Spec:** `docs/superpowers/specs/2026-04-30-multiple-phones-per-client-design.md`

---

## Task 1 — `normalizePhones` helper (pure, fully tested)

**Files:**
- Create: `lib/core/phone_normalizer.dart`
- Test: `test/core/phone_normalizer_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/core/phone_normalizer_test.dart`:

```dart
import 'package:coup_laine/core/phone_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizePhones', () {
    test('trims each entry', () {
      expect(normalizePhones(['  06 12  ', '0145']), ['06 12', '0145']);
    });

    test('drops empty and whitespace-only entries', () {
      expect(normalizePhones(['', '   ', '0612', '\t']), ['0612']);
    });

    test('drops duplicates, keeping the first occurrence (stable)', () {
      expect(
        normalizePhones(['0612', '0145', '0612', '0788']),
        ['0612', '0145', '0788'],
      );
    });

    test('treats post-trim duplicates as duplicates', () {
      expect(normalizePhones(['  0612  ', '0612']), ['0612']);
    });

    test('preserves order of distinct entries', () {
      expect(
        normalizePhones(['C', 'A', 'B']),
        ['C', 'A', 'B'],
      );
    });

    test('returns empty for an empty input', () {
      expect(normalizePhones(<String>[]), <String>[]);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/phone_normalizer_test.dart`
Expected: FAIL with "Target of URI doesn't exist: 'package:coup_laine/core/phone_normalizer.dart'".

- [ ] **Step 3: Implement**

Create `lib/core/phone_normalizer.dart`:

```dart
/// Cleans up a list of phone numbers before persistence:
///   - trims each entry,
///   - drops entries that are empty after trimming,
///   - removes duplicates while preserving the order of first occurrences.
///
/// Used by [ClientRepository] on every write so the stored list stays
/// canonical (no leading/trailing whitespace, no blanks, no dupes).
List<String> normalizePhones(List<String> input) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in input) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    if (seen.add(trimmed)) out.add(trimmed);
  }
  return out;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/phone_normalizer_test.dart`
Expected: PASS — 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/core/phone_normalizer.dart test/core/phone_normalizer_test.dart
git commit -m "feat(core): add normalizePhones helper"
```

---

## Task 2 — `PhoneListConverter` (Drift `TypeConverter`, fully tested)

**Files:**
- Create: `lib/infra/db/phone_list_converter.dart`
- Test: `test/infra/db/phone_list_converter_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/infra/db/phone_list_converter_test.dart`:

```dart
import 'package:coup_laine/infra/db/phone_list_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const c = PhoneListConverter();

  group('PhoneListConverter.fromSql', () {
    test('decodes "[]" to empty list', () {
      expect(c.fromSql('[]'), <String>[]);
    });

    test('decodes a JSON array of strings preserving order', () {
      expect(c.fromSql('["0612","0145"]'), ['0612', '0145']);
    });
  });

  group('PhoneListConverter.toSql', () {
    test('encodes empty list as "[]"', () {
      expect(c.toSql(const []), '[]');
    });

    test('encodes a list of strings as a JSON array', () {
      expect(c.toSql(const ['0612', '0145']), '["0612","0145"]');
    });
  });

  test('round-trips a non-trivial list unchanged', () {
    final original = ['06 12 34 56 78', '+33 1 45 67 89 00', 'mobile-épouse'];
    expect(c.fromSql(c.toSql(original)), original);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/infra/db/phone_list_converter_test.dart`
Expected: FAIL with missing import.

- [ ] **Step 3: Implement**

Create `lib/infra/db/phone_list_converter.dart`:

```dart
import 'dart:convert';

import 'package:drift/drift.dart';

/// Drift [TypeConverter] that stores `List<String>` as a JSON array in a
/// `TEXT` column. Empty list ↔ `'[]'`. Used by [ClientsTable.phones].
class PhoneListConverter extends TypeConverter<List<String>, String> {
  const PhoneListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return decoded.cast<String>();
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/infra/db/phone_list_converter_test.dart`
Expected: PASS — 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/infra/db/phone_list_converter.dart test/infra/db/phone_list_converter_test.dart
git commit -m "feat(db): add PhoneListConverter for List<String> JSON storage"
```

---

## Task 3 — Domain model: `Client.phones` + `principalPhone`

**Files:**
- Modify: `lib/domain/models/client.dart`

This step intentionally breaks compilation of every `client.phone` call-site. The next tasks fix them in sequence (data layer first, then UI). After this task, only `flutter analyze` is expected to surface errors — no runtime test runs cleanly until Task 5 is done.

- [ ] **Step 1: Update the model**

Replace the entire contents of `lib/domain/models/client.dart` with:

```dart
import 'coordinates.dart';

class Client {
  final int id;
  final String name;
  final List<String> phones;
  final String addressLabel;
  final String postcode;
  final String city;
  final Coordinates coordinates;
  final int sheepCountSmall;
  final int sheepCountLarge;
  final String? markerColorHex;
  final bool isWaiting;
  final bool isBanned;
  final DateTime? lastShearingDate;
  final bool needsDistanceRecompute;

  const Client({
    required this.id,
    required this.name,
    required this.addressLabel,
    required this.postcode,
    required this.city,
    required this.coordinates,
    this.sheepCountSmall = 0,
    this.sheepCountLarge = 0,
    this.phones = const [],
    this.markerColorHex,
    this.isWaiting = false,
    this.isBanned = false,
    this.lastShearingDate,
    this.needsDistanceRecompute = false,
  });

  int get sheepCountTotal => sheepCountSmall + sheepCountLarge;

  /// First entry of [phones], or null if the list is empty. Used as the
  /// default phone for call/SMS actions on surfaces that show a single
  /// action button (e.g. the map popup).
  String? get principalPhone => phones.isNotEmpty ? phones.first : null;
}
```

- [ ] **Step 2: Run analyzer to confirm the breakage scope**

Run: `flutter analyze`
Expected: errors in
- `lib/data/repositories/client_repository.dart` (3 sites: `phone:` in companions + mapper)
- `lib/core/text_search.dart`
- `lib/presentation/clients/client_form_screen.dart`
- `lib/presentation/clients/client_detail_screen.dart`
- `lib/presentation/map/client_pin_popup.dart`
- `test/data/client_repository_test.dart` (the test helper passes a now-removed default)

These are repaired by Tasks 4–8. Do not commit yet.

---

## Task 4 — Drift schema: replace `phone` column with `phones`

**Files:**
- Modify: `lib/infra/db/tables.dart` (line 47 — the `phone` column)
- Regenerate: `lib/infra/db/app_database.g.dart` (via build_runner)

- [ ] **Step 1: Replace the column declaration**

In `lib/infra/db/tables.dart`, **delete** line 47:

```dart
TextColumn get phone => text().nullable()();
```

**Insert** in its place:

```dart
TextColumn get phones => text()
    .map(const PhoneListConverter())
    .withDefault(const Constant('[]'))();
```

Add the matching import at the top of the file (after the existing `import 'package:drift/drift.dart';`):

```dart
import 'phone_list_converter.dart';
```

- [ ] **Step 2: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: success, `lib/infra/db/app_database.g.dart` is rewritten with `phones` (typed `List<String>`) on `ClientRow` and `ClientsTableCompanion`.

If build_runner emits warnings about the converter, re-read the converter file path — Drift expects the converter import to be reachable from the generated file.

- [ ] **Step 3: Verify the regenerated code mentions `phones`**

Run: `flutter analyze lib/infra/db/app_database.g.dart`
Expected: no errors. The file should contain `final List<String> phones;` on `ClientRow` and a `Value<List<String>> phones` on the companion.

Do not commit yet — the repository still references the removed column.

---

## Task 5 — Repository: write/read `phones`, normalize on every write

**Files:**
- Modify: `lib/data/repositories/client_repository.dart`
- Modify: `test/data/client_repository_test.dart`

- [ ] **Step 1: Add failing tests**

Open `test/data/client_repository_test.dart`. Insert these tests inside the existing `void main() { … }` block, anywhere after the `delete removes the client` test:

```dart
test('insert persists phones list and reads it back in order', () async {
  final id = await repo.insert(Client(
    id: 0,
    name: 'Le Gall',
    addressLabel: '1 rue, 29000 Quimper',
    postcode: '29000',
    city: 'Quimper',
    coordinates: const Coordinates(lat: 48.0, lon: -4.1),
    phones: const ['0612', '0145', '0788'],
  ));
  final read = await repo.findById(id);
  expect(read!.phones, ['0612', '0145', '0788']);
  expect(read.principalPhone, '0612');
});

test('insert normalizes phones (trim, drop empty, dedupe)', () async {
  final id = await repo.insert(Client(
    id: 0,
    name: 'Le Gall',
    addressLabel: '1 rue, 29000 Quimper',
    postcode: '29000',
    city: 'Quimper',
    coordinates: const Coordinates(lat: 48.0, lon: -4.1),
    phones: const ['  06 12  ', '', '0612', '0145'],
  ));
  final read = await repo.findById(id);
  expect(read!.phones, ['06 12', '0145']);
});

test('updateBasics replaces phones list and preserves new order', () async {
  final id = await repo.insert(Client(
    id: 0,
    name: 'Le Gall',
    addressLabel: '1 rue, 29000 Quimper',
    postcode: '29000',
    city: 'Quimper',
    coordinates: const Coordinates(lat: 48.0, lon: -4.1),
    phones: const ['0612'],
  ));
  await repo.updateBasics(
    id: id,
    name: 'Le Gall',
    phones: const ['0788', '0612'],
    sheepCountSmall: 12,
    sheepCountLarge: 0,
  );
  final read = await repo.findById(id);
  expect(read!.phones, ['0788', '0612']);
  expect(read.principalPhone, '0788');
});

test('a client with no phones reads back as empty list', () async {
  final id = await repo.insert(_newClient());
  final read = await repo.findById(id);
  expect(read!.phones, <String>[]);
  expect(read.principalPhone, isNull);
});
```

- [ ] **Step 2: Run tests to verify they fail to compile**

Run: `flutter test test/data/client_repository_test.dart`
Expected: compile errors — `updateBasics` named param `phones` does not exist, mapper still returns the old shape.

- [ ] **Step 3: Update `insert`**

In `lib/data/repositories/client_repository.dart`, locate the `insert` method (around line 18). Replace the line:

```dart
phone: Value(c.phone),
```

with:

```dart
phones: Value(normalizePhones(c.phones)),
```

- [ ] **Step 4: Update `updateBasics`**

Replace the entire `updateBasics` method (around lines 122–138) with:

```dart
Future<void> updateBasics({
  required int id,
  required String name,
  required List<String> phones,
  required int sheepCountSmall,
  required int sheepCountLarge,
}) async {
  await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
    ClientsTableCompanion(
      name: Value(name),
      phones: Value(normalizePhones(phones)),
      sheepCountSmall: Value(sheepCountSmall),
      sheepCountLarge: Value(sheepCountLarge),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ),
  );
}
```

- [ ] **Step 5: Update the mapper `_toDomain`**

Replace the line (around line 462):

```dart
phone: row.phone,
```

with:

```dart
phones: row.phones,
```

- [ ] **Step 6: Add the import**

At the top of `lib/data/repositories/client_repository.dart`, add:

```dart
import '../../core/phone_normalizer.dart';
```

- [ ] **Step 7: Run repository tests**

Run: `flutter test test/data/client_repository_test.dart`
Expected: all tests pass, including the four new ones. Existing tests still pass (none were touching `phone`).

- [ ] **Step 8: Commit**

```bash
git add lib/domain/models/client.dart lib/infra/db/tables.dart lib/infra/db/app_database.g.dart lib/data/repositories/client_repository.dart test/data/client_repository_test.dart
git commit -m "feat(client): switch to phones list (data layer)"
```

(UI call-sites are still broken at this point — fixed in Tasks 6 and 7. We commit the data layer separately so the repo round-trip is anchored.)

---

## Task 6 — Surgical compile-fix of UI call-sites (single principal phone)

This task only fixes the type errors so the app compiles. The richer multi-phone UI in the form and the detail screen comes in Tasks 9 and 10.

**Files:**
- Modify: `lib/core/text_search.dart`
- Modify: `lib/presentation/map/client_pin_popup.dart`
- Modify: `lib/presentation/clients/client_form_screen.dart`
- Modify: `lib/presentation/clients/client_detail_screen.dart`

- [ ] **Step 1: `text_search.dart` — match all phones**

In `lib/core/text_search.dart`, replace line 41:

```dart
c.phone ?? '',
```

with:

```dart
c.phones.join(' '),
```

Also update the doc comment on line 28 — replace `name, phone, city,` with `name, phones, city,` (single character change to keep documentation honest).

- [ ] **Step 2: `client_pin_popup.dart` — use `principalPhone`**

In `lib/presentation/map/client_pin_popup.dart`, replace line 22:

```dart
final hasPhone = client.phone != null && client.phone!.trim().isNotEmpty;
```

with:

```dart
final principalPhone = client.principalPhone;
final hasPhone = principalPhone != null;
```

Then on line 79 replace:

```dart
hasPhone ? () => callPhone(context, client.phone!) : null,
```

with:

```dart
hasPhone ? () => callPhone(context, principalPhone) : null,
```

And on line 90 replace:

```dart
hasPhone ? () => sendSms(context, client.phone!) : null,
```

with:

```dart
hasPhone ? () => sendSms(context, principalPhone) : null,
```

- [ ] **Step 3: `client_form_screen.dart` — minimal binding**

In `lib/presentation/clients/client_form_screen.dart`:

(a) Line 69 — replace:

```dart
_phoneCtrl.text = c.phone ?? '';
```

with:

```dart
_phoneCtrl.text = c.principalPhone ?? '';
```

(b) Lines 122–128 — the `updateBasics` call. Replace the existing call with:

```dart
await repo.updateBasics(
  id: id,
  name: _nameCtrl.text.trim(),
  phones: _phoneCtrl.text.trim().isEmpty
      ? const []
      : [_phoneCtrl.text.trim()],
  sheepCountSmall: int.parse(_sheepSmallCtrl.text),
  sheepCountLarge: int.parse(_sheepLargeCtrl.text),
);
```

(c) Lines 137–147 — the `repo.insert(Client(...))` call. Replace `phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),` with:

```dart
phones: _phoneCtrl.text.trim().isEmpty
    ? const []
    : [_phoneCtrl.text.trim()],
```

(The form is still single-input here; Task 9 turns it into a reorderable list.)

- [ ] **Step 4: `client_detail_screen.dart` — minimal binding**

In `lib/presentation/clients/client_detail_screen.dart`, around lines 191–226 (the Contact card block). Replace:

```dart
if (client.phone != null) ...[
  AppSectionCard(
    icon: FIcons.phone,
    title: l.clientDetailSectionContact,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(client.phone!, style: theme.typography.md),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                prefix: const Icon(FIcons.phone),
                onPress: () => callPhone(context, client.phone!),
                child: const Text('Appeler'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                prefix: const Icon(FIcons.messageCircle),
                onPress: () => sendSms(context, client.phone!),
                child: const Text('SMS'),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  const SizedBox(height: AppSpacing.md),
],
```

with this principal-only equivalent (Task 10 will turn it into a per-phone list):

```dart
if (client.principalPhone != null) ...[
  AppSectionCard(
    icon: FIcons.phone,
    title: l.clientDetailSectionContact,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(client.principalPhone!, style: theme.typography.md),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                prefix: const Icon(FIcons.phone),
                onPress: () => callPhone(context, client.principalPhone!),
                child: const Text('Appeler'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                prefix: const Icon(FIcons.messageCircle),
                onPress: () => sendSms(context, client.principalPhone!),
                child: const Text('SMS'),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  const SizedBox(height: AppSpacing.md),
],
```

- [ ] **Step 5: Run full analyzer + test suite**

Run: `flutter analyze`
Expected: no errors.

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/core/text_search.dart lib/presentation/map/client_pin_popup.dart lib/presentation/clients/client_form_screen.dart lib/presentation/clients/client_detail_screen.dart
git commit -m "refactor(clients): adapt UI/search to phones list (principal-only)"
```

---

## Task 7 — Search test: phones list matches in client list

**Files:**
- Create: `test/core/text_search_test.dart`

- [ ] **Step 1: Write the test**

Create `test/core/text_search_test.dart`:

```dart
import 'package:coup_laine/core/text_search.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:flutter_test/flutter_test.dart';

Client _client({
  String name = 'Le Gall',
  List<String> phones = const [],
  String city = 'Quimper',
  String postcode = '29000',
  String addressLabel = '1 rue Test, 29000 Quimper',
}) {
  return Client(
    id: 1,
    name: name,
    addressLabel: addressLabel,
    postcode: postcode,
    city: city,
    coordinates: const Coordinates(lat: 48.0, lon: -4.1),
    phones: phones,
  );
}

void main() {
  group('matchesClient — phones list', () {
    test('matches the principal number', () {
      final c = _client(phones: const ['0612', '0145']);
      expect(matchesClient(c, normalize('0612')), isTrue);
    });

    test('matches a non-principal number', () {
      final c = _client(phones: const ['0612', '0145']);
      expect(matchesClient(c, normalize('0145')), isTrue);
    });

    test('does not match a number that is not in the list', () {
      final c = _client(phones: const ['0612']);
      expect(matchesClient(c, normalize('0788')), isFalse);
    });

    test('a client with empty phones still matches by name', () {
      final c = _client(name: 'Le Gall', phones: const []);
      expect(matchesClient(c, normalize('gall')), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/core/text_search_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 3: Commit**

```bash
git add test/core/text_search_test.dart
git commit -m "test(search): cover multi-phone matching"
```

---

## Task 8 — Migration v7 → v8

**Files:**
- Modify: `lib/infra/db/app_database.dart` (line 28 + the `onUpgrade` block)

There is no precedent in the repo for unit-testing migrations end-to-end (no `drift_dev schema steps` setup). The data-layer round-trip in Task 5 already validates that the v8 schema is correct end-to-end. The migration itself is small and read-by-eye verifiable; it ships untested at the unit level — the engineer should run the app once on a device with v7 data after this task lands.

- [ ] **Step 1: Bump `schemaVersion`**

On line 28 of `lib/infra/db/app_database.dart`, replace:

```dart
int get schemaVersion => 7;
```

with:

```dart
int get schemaVersion => 8;
```

- [ ] **Step 2: Add the `from < 8` migration block**

Inside `onUpgrade`, immediately after the `if (from < 7) { … }` block (around line 138, just before the closing `}` of `onUpgrade`), insert:

```dart
if (from < 8) {
  // Add the new JSON-array column. SQL-level default is the JSON literal
  // "[]" so existing rows materialize as an empty list when read back.
  await customStatement(
    "ALTER TABLE clients ADD COLUMN phones TEXT NOT NULL DEFAULT '[]'",
  );
  // Backfill: each existing non-empty `phone` becomes the sole element
  // (and therefore the principal) of the new list.
  await customStatement(
    "UPDATE clients "
    "SET phones = json_array(phone) "
    "WHERE phone IS NOT NULL AND trim(phone) <> ''",
  );
  // Drop the legacy column. SQLite >= 3.35 supports DROP COLUMN;
  // sqlite3_flutter_libs bundles a recent enough version (already
  // relied upon by the v4 migration above).
  await customStatement('ALTER TABLE clients DROP COLUMN phone');
}
```

- [ ] **Step 3: Sanity-check the analyzer**

Run: `flutter analyze`
Expected: no errors.

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: all tests pass. (Tests use `AppDatabase.forTesting(NativeDatabase.memory())` which goes through `onCreate`, not `onUpgrade`, so they're unaffected by this change.)

- [ ] **Step 5: Commit**

```bash
git add lib/infra/db/app_database.dart
git commit -m "feat(db): migrate clients.phone to phones JSON array (v7→v8)"
```

---

## Task 9 — i18n: rename + new keys for the multi-phone form

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations*.dart`
- Modify: `lib/presentation/clients/client_form_screen.dart` (line 209 — referenced key)

- [ ] **Step 1: Update `app_fr.arb`**

In `lib/l10n/app_fr.arb`, find line 58:

```json
"clientFormPhone": "Téléphone",
```

Replace with:

```json
"clientFormPhones": "Téléphones",
"clientFormAddPhone": "Ajouter un numéro",
"clientFormRemovePhone": "Retirer ce numéro",
```

- [ ] **Step 2: Update `app_en.arb`**

In `lib/l10n/app_en.arb`, find line 58:

```json
"clientFormPhone": "Phone",
```

Replace with:

```json
"clientFormPhones": "Phones",
"clientFormAddPhone": "Add a number",
"clientFormRemovePhone": "Remove this number",
```

- [ ] **Step 3: Regenerate localization Dart**

Run: `flutter gen-l10n`
Expected: `lib/l10n/app_localizations.dart`, `app_localizations_fr.dart`, `app_localizations_en.dart` are rewritten with the three new getters and without `clientFormPhone`.

- [ ] **Step 4: Update the temporary form binding to use the new key**

In `lib/presentation/clients/client_form_screen.dart`, line 209:

```dart
label: Text(l.clientFormPhone),
```

Replace with:

```dart
label: Text(l.clientFormPhones),
```

(The full multi-phone widget replaces this `FTextField` in Task 10. We update the key now so the build stays green between tasks.)

- [ ] **Step 5: Verify build**

Run: `flutter analyze`
Expected: no errors.

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_fr.dart lib/l10n/app_localizations_en.dart lib/presentation/clients/client_form_screen.dart
git commit -m "i18n: rename clientFormPhone → clientFormPhones, add Add/Remove keys"
```

---

## Task 10 — Form: reorderable list of phones

**Files:**
- Modify: `lib/presentation/clients/client_form_screen.dart`

This task replaces the single `_phoneCtrl` with a list of controllers and renders the phones section as a `ReorderableListView` with per-row delete + an `+ Add a number` button.

- [ ] **Step 1: Replace controller declaration**

In `lib/presentation/clients/client_form_screen.dart`:

(a) Around line 32, delete:

```dart
final _phoneCtrl = TextEditingController();
```

Insert in its place:

```dart
final List<TextEditingController> _phoneCtrls = [];
```

(b) In `dispose()` (around lines 56–62), replace `_phoneCtrl.dispose();` with:

```dart
for (final c in _phoneCtrls) {
  c.dispose();
}
```

(c) In `initState()` (around lines 49–53), the create path needs to seed one empty row so the form shows a usable input on first open. Replace:

```dart
@override
void initState() {
  super.initState();
  if (widget.isEdit) _load();
}
```

with:

```dart
@override
void initState() {
  super.initState();
  if (widget.isEdit) {
    _load();
  } else {
    _phoneCtrls.add(TextEditingController());
  }
}
```

- [ ] **Step 2: Replace single-phone seeding in `_load()`**

Around line 69, replace:

```dart
_phoneCtrl.text = c.principalPhone ?? '';
```

with:

```dart
_phoneCtrls
  ..clear()
  ..addAll(c.phones.map((p) => TextEditingController(text: p)));
```

- [ ] **Step 3: Replace single-phone reads in `_submit()`**

(a) Around lines 122–128 — the `updateBasics` call. Replace the `phones:` arg you wrote in Task 6 with:

```dart
phones: _phoneCtrls.map((c) => c.text).toList(),
```

(b) Around lines 137–147 — the `repo.insert(Client(...))` call. Replace the `phones:` arg you wrote in Task 6 with:

```dart
phones: _phoneCtrls.map((c) => c.text).toList(),
```

(Repository's `_normalizePhones` does the trimming/dedupe — the form just passes raw text.)

- [ ] **Step 4: Replace the single `FTextField` in the Identité section with the multi-phone widget**

Locate the block (around lines 207–211):

```dart
const SizedBox(height: AppSpacing.md),
FTextField(
  control: FTextFieldControl.managed(controller: _phoneCtrl),
  label: Text(l.clientFormPhones),
  keyboardType: TextInputType.phone,
),
```

Replace it with:

```dart
const SizedBox(height: AppSpacing.md),
_PhoneListEditor(
  controllers: _phoneCtrls,
  label: l.clientFormPhones,
  addLabel: l.clientFormAddPhone,
  removeTooltip: l.clientFormRemovePhone,
  onAdd: () {
    setState(() {
      _phoneCtrls.add(TextEditingController());
    });
  },
  onRemove: (index) {
    setState(() {
      _phoneCtrls.removeAt(index).dispose();
    });
  },
  onReorder: (oldIndex, newIndex) {
    setState(() {
      // ReorderableListView convention: when moving down, newIndex is one
      // past the destination, so adjust before the removeAt.
      final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final ctrl = _phoneCtrls.removeAt(oldIndex);
      _phoneCtrls.insert(adjustedNew, ctrl);
    });
  },
),
```

- [ ] **Step 5: Add the `_PhoneListEditor` widget at the bottom of the file**

After the existing `_MarkerColorEditor` class (at the end of `client_form_screen.dart`), append:

```dart
class _PhoneListEditor extends StatelessWidget {
  final List<TextEditingController> controllers;
  final String label;
  final String addLabel;
  final String removeTooltip;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _PhoneListEditor({
    required this.controllers,
    required this.label,
    required this.addLabel,
    required this.removeTooltip,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            label,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        if (controllers.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: controllers.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              return Padding(
                key: ValueKey(controllers[index]),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Icon(
                          FIcons.gripVertical,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                    Expanded(
                      child: FTextField(
                        control: FTextFieldControl.managed(
                          controller: controllers[index],
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    IconButton(
                      tooltip: removeTooltip,
                      icon: Icon(
                        FIcons.x,
                        color: theme.colors.mutedForeground,
                      ),
                      onPressed: () => onRemove(index),
                    ),
                  ],
                ),
              );
            },
          ),
        FButton(
          variant: FButtonVariant.outline,
          prefix: const Icon(FIcons.plus),
          onPress: onAdd,
          child: Text(addLabel),
        ),
      ],
    );
  }
}
```

Add the import at the top of the file (if not already present) — `IconButton` requires Material:

```dart
import 'package:flutter/material.dart' show IconButton;
```

- [ ] **Step 6: Verify build + tests**

Run: `flutter analyze`
Expected: no errors.

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 7: Manual UI smoke check**

The test suite cannot validate the new widget interactively. Run:

```bash
flutter run -d <device>
```

Then on a real or virtual device:
1. Open the client form (new client). Confirm the Identité section shows the « Téléphones » label, no rows, and an « Ajouter un numéro » button.
2. Tap « Ajouter un numéro » three times. Type three different numbers.
3. Drag the third row to position 1 using the grip icon. Confirm the order changes.
4. Tap the `×` on the middle row. Confirm it disappears.
5. Save the client. Reopen — confirm the two saved numbers come back in order.

If any of these fail, fix the issue and re-run before committing.

- [ ] **Step 8: Commit**

```bash
git add lib/presentation/clients/client_form_screen.dart
git commit -m "feat(client-form): reorderable multi-phone editor"
```

---

## Task 11 — Detail screen: per-phone Appeler/SMS row

**Files:**
- Modify: `lib/presentation/clients/client_detail_screen.dart`

- [ ] **Step 1: Replace the Contact card**

In `lib/presentation/clients/client_detail_screen.dart`, find the Contact card block (the one you edited in Task 6, around lines 191–226). Replace the whole block with:

```dart
if (client.phones.isNotEmpty) ...[
  AppSectionCard(
    icon: FIcons.phone,
    title: l.clientDetailSectionContact,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < client.phones.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(FIcons.phone, color: theme.colors.mutedForeground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  client.phones[i],
                  style: theme.typography.md,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FButton(
                variant: FButtonVariant.outline,
                prefix: const Icon(FIcons.phone),
                onPress: () => callPhone(context, client.phones[i]),
                child: const Text('Appeler'),
              ),
              const SizedBox(width: AppSpacing.xs),
              FButton(
                variant: FButtonVariant.outline,
                prefix: const Icon(FIcons.messageCircle),
                onPress: () => sendSms(context, client.phones[i]),
                child: const Text('SMS'),
              ),
            ],
          ),
        ],
      ],
    ),
  ),
  const SizedBox(height: AppSpacing.md),
],
```

(No labels — the order alone signals the principal, per spec.)

- [ ] **Step 2: Verify build + tests**

Run: `flutter analyze`
Expected: no errors.

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 3: Manual UI smoke check**

```bash
flutter run -d <device>
```

1. Open a client that has 2 phones. Confirm two rows are rendered, each with its own Appeler/SMS pair.
2. Tap Appeler on the second row. The native dialer should open with the second number.
3. Tap SMS on the first row. The SMS app should open with the first number.
4. Open a client with no phones. Confirm the Contact card is not rendered.
5. On the map, tap a pin for a client with multiple phones. Confirm the popup's Appeler/SMS use the first number only (the principal).

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/clients/client_detail_screen.dart
git commit -m "feat(client-detail): list every phone with its own actions"
```

---

## Closing checklist

- [ ] `flutter analyze` clean.
- [ ] `flutter test` green.
- [ ] App runs on a real or virtual device with pre-existing v7 data; the migration upgrades silently and the existing single phone shows up as the principal.
- [ ] All eleven tasks committed.
- [ ] No `client.phone` references remain in the codebase: `grep -rn "client.phone\b\|c.phone\b\|\.phone\s*=" lib/ test/` returns nothing pointing at `Client`.

If everything is green, the spec at `docs/superpowers/specs/2026-04-30-multiple-phones-per-client-design.md` is fully delivered.
