# Catalogue de prestations — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implémenter le catalogue de prestations (#6 du TODO) défini dans `docs/superpowers/specs/2026-05-01-prestation-catalog-design.md`. Une prestation = `(label, prix, durée, categoryId?)`. Picker explicite par stop à la planification. Refonte du modèle `TourStop` (animaux → prestations), du bilan, de la saisie manuelle d'historique. Schema 11 → 12.

**Architecture:** Approche bottom-up. Phase A (T1-T6) : ajout additif des nouveaux types/helpers/converters/repo. Phase B (T7-T9) : « slices verticales » qui pivotent les types existants (TourStop, ManualHistoryEntry) et leurs consumers backend de TourStopAnimal vers TourStopPrestation. Phase C (T10-T12) : nettoyage des champs morts (AnimalCategory.defaultMinutes/defaultPriceCents) et seeding. Phase D (T13-T17) : UI catalogue, picker, draft. Phase E (T18-T20) : bilan et historique. Phase F (T21-T24) : seeding wiring, l10n, suppression du code mort, sweep final.

**Tech Stack:** Flutter 3.x, Riverpod, Drift (SQLite), `forui` UI library. Tests : `flutter_test` avec `drift/native` in-memory pour les repos, tests purs pour les use cases. Convention de commit projet : type(scope): message (ex. `feat(domain): ...`, `refactor(repo): ...`).

**Conventions du codebase à respecter :**
- Models : pure dataclasses (pas de freezed), constructeurs `const`, `==`/`hashCode` manuels seulement quand utilisé en équivalence (ex. `TourStopPrestation`).
- Repos : signature `Future<T> method(...)`, retour `_toDomain(row)`. Inserts via Companion. Transactions via `_db.transaction`.
- Tests repos : `setUp` ouvre `AppDatabase.forTesting(NativeDatabase.memory())`, `tearDown` close.
- Tests use cases : pas de DB, instanciation directe. Voir `test/domain/build_tour_draft_test.dart`.
- l10n : fichiers `lib/l10n/app_fr.arb` + `app_en.arb` synchronisés. Régénération via `flutter gen-l10n` (déclenché automatiquement par `pubspec.yaml.flutter.generate: true`).
- Drift codegen : `dart run build_runner build --delete-conflicting-outputs`.

---

## Task 1: Add `Prestation` domain model

**Files:**
- Create: `lib/domain/models/prestation.dart`
- Test: `test/domain/prestation_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/prestation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/prestation.dart';

void main() {
  test('isArchived returns false when archivedAt is null', () {
    const p = Prestation(id: 1, name: 'Tonte');
    expect(p.isArchived, isFalse);
  });

  test('isArchived returns true when archivedAt is set', () {
    final p = Prestation(
      id: 1,
      name: 'Tonte',
      archivedAt: DateTime(2026, 1, 1),
    );
    expect(p.isArchived, isTrue);
  });

  test('all fields are accessible', () {
    final p = Prestation(
      id: 7,
      name: 'Parage',
      priceCents: 5000,
      minutes: 25,
      categoryId: 3,
      archivedAt: DateTime(2026, 5, 1),
    );
    expect(p.id, 7);
    expect(p.name, 'Parage');
    expect(p.priceCents, 5000);
    expect(p.minutes, 25);
    expect(p.categoryId, 3);
    expect(p.archivedAt, DateTime(2026, 5, 1));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/prestation_test.dart`
Expected: compilation failure — `prestation.dart` doesn't exist.

- [ ] **Step 3: Implement**

```dart
// lib/domain/models/prestation.dart
class Prestation {
  final int id;
  final String name;
  final int? priceCents;
  final int? minutes;
  final int? categoryId;
  final DateTime? archivedAt;

  const Prestation({
    required this.id,
    required this.name,
    this.priceCents,
    this.minutes,
    this.categoryId,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/prestation_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/models/prestation.dart test/domain/prestation_test.dart
git commit -m "feat(domain): add Prestation model"
```

---

## Task 2: Add `TourStopPrestation` domain model

**Files:**
- Create: `lib/domain/models/tour_stop_prestation.dart`
- Test: `test/domain/tour_stop_prestation_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/tour_stop_prestation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';

void main() {
  const a = TourStopPrestation(
    prestationId: 1,
    qty: 12,
    nameSnapshot: 'Tonte',
    priceCentsSnapshot: 800,
    minutesSnapshot: 8,
    categoryIdSnapshot: 3,
    categoryNameSnapshot: 'Petit',
    speciesNameSnapshot: 'Mouton',
  );

  test('equality on identical fields', () {
    const b = TourStopPrestation(
      prestationId: 1,
      qty: 12,
      nameSnapshot: 'Tonte',
      priceCentsSnapshot: 800,
      minutesSnapshot: 8,
      categoryIdSnapshot: 3,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
    );
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });

  test('inequality when qty differs', () {
    const b = TourStopPrestation(
      prestationId: 1,
      qty: 11,
      nameSnapshot: 'Tonte',
      priceCentsSnapshot: 800,
      minutesSnapshot: 8,
      categoryIdSnapshot: 3,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
    );
    expect(a, isNot(equals(b)));
  });

  test('libre prestation: category snapshots are null', () {
    const free = TourStopPrestation(
      prestationId: 9,
      qty: 1,
      nameSnapshot: 'Visite',
      priceCentsSnapshot: 2000,
      minutesSnapshot: 0,
    );
    expect(free.categoryIdSnapshot, isNull);
    expect(free.categoryNameSnapshot, isNull);
    expect(free.speciesNameSnapshot, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/tour_stop_prestation_test.dart`
Expected: compilation failure.

- [ ] **Step 3: Implement**

```dart
// lib/domain/models/tour_stop_prestation.dart
class TourStopPrestation {
  final int prestationId;
  final int qty;
  final String nameSnapshot;
  final int priceCentsSnapshot;
  final int minutesSnapshot;
  final int? categoryIdSnapshot;
  final String? categoryNameSnapshot;
  final String? speciesNameSnapshot;

  const TourStopPrestation({
    required this.prestationId,
    required this.qty,
    required this.nameSnapshot,
    required this.priceCentsSnapshot,
    required this.minutesSnapshot,
    this.categoryIdSnapshot,
    this.categoryNameSnapshot,
    this.speciesNameSnapshot,
  });

  @override
  bool operator ==(Object other) =>
      other is TourStopPrestation &&
      other.prestationId == prestationId &&
      other.qty == qty &&
      other.nameSnapshot == nameSnapshot &&
      other.priceCentsSnapshot == priceCentsSnapshot &&
      other.minutesSnapshot == minutesSnapshot &&
      other.categoryIdSnapshot == categoryIdSnapshot &&
      other.categoryNameSnapshot == categoryNameSnapshot &&
      other.speciesNameSnapshot == speciesNameSnapshot;

  @override
  int get hashCode => Object.hash(
        prestationId,
        qty,
        nameSnapshot,
        priceCentsSnapshot,
        minutesSnapshot,
        categoryIdSnapshot,
        categoryNameSnapshot,
        speciesNameSnapshot,
      );
}
```

- [ ] **Step 4: Run test**

Run: `flutter test test/domain/tour_stop_prestation_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/models/tour_stop_prestation.dart test/domain/tour_stop_prestation_test.dart
git commit -m "feat(domain): add TourStopPrestation model with snapshots"
```

---

## Task 3: Add `normalizeTourStopPrestations` helper

**Files:**
- Create: `lib/core/tour_stop_prestations_normalizer.dart`
- Test: `test/core/tour_stop_prestations_normalizer_test.dart`

Behavior (from spec, section "Helper de normalisation") :
- Drop entries with `qty <= 0`.
- **No dedup** — two distinct rows of the same prestation are allowed.
- Tri stable par `prestationId` puis ordre d'insertion.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/tour_stop_prestations_normalizer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/tour_stop_prestations_normalizer.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';

TourStopPrestation _p(int id, int qty) => TourStopPrestation(
      prestationId: id,
      qty: qty,
      nameSnapshot: 'P$id',
      priceCentsSnapshot: 0,
      minutesSnapshot: 0,
    );

void main() {
  test('drops qty <= 0', () {
    final out = normalizeTourStopPrestations([_p(1, 5), _p(2, 0), _p(3, -1)]);
    expect(out.map((e) => e.prestationId), [1]);
  });

  test('does not dedup same prestationId', () {
    final out = normalizeTourStopPrestations([_p(1, 5), _p(1, 3)]);
    expect(out, hasLength(2));
    expect(out.every((e) => e.prestationId == 1), isTrue);
  });

  test('sorts by prestationId ascending then preserves insertion order', () {
    final out = normalizeTourStopPrestations(
        [_p(3, 1), _p(1, 5), _p(1, 3), _p(2, 2)]);
    expect(out.map((e) => (e.prestationId, e.qty)).toList(),
        [(1, 5), (1, 3), (2, 2), (3, 1)]);
  });

  test('empty input', () {
    expect(normalizeTourStopPrestations(const []), isEmpty);
  });
}
```

- [ ] **Step 2: Verify it fails**

Run: `flutter test test/core/tour_stop_prestations_normalizer_test.dart`
Expected: compilation failure.

- [ ] **Step 3: Implement**

```dart
// lib/core/tour_stop_prestations_normalizer.dart
import '../domain/models/tour_stop_prestation.dart';

/// Canonicalizes a list of [TourStopPrestation] before persistence:
///   - drops `qty <= 0`,
///   - DOES NOT dedup by `prestationId` (multiple distinct rows are allowed),
///   - stable sort by `prestationId` ascending; insertion order preserved
///     for ties.
List<TourStopPrestation> normalizeTourStopPrestations(
    List<TourStopPrestation> input) {
  final filtered = [
    for (final p in input)
      if (p.qty > 0) p,
  ];
  // Stable sort: List.sort is mergesort in Dart 2 / TimSort in Dart 3 — both stable.
  filtered.sort((a, b) => a.prestationId.compareTo(b.prestationId));
  return filtered;
}
```

- [ ] **Step 4: Verify it passes**

Run: `flutter test test/core/tour_stop_prestations_normalizer_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/tour_stop_prestations_normalizer.dart test/core/tour_stop_prestations_normalizer_test.dart
git commit -m "feat(core): add normalizeTourStopPrestations helper"
```

---

## Task 4: Add `animalCountsFromPrestations` helper

**Files:**
- Create: `lib/core/animal_counts_from_prestations.dart`
- Test: `test/core/animal_counts_from_prestations_test.dart`

Rule from spec : MAX par catégorie sur les prestations bound. Prestations libres ignorées.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/animal_counts_from_prestations_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/animal_counts_from_prestations.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';

TourStopPrestation _bound(int prestId, int qty, int catId) =>
    TourStopPrestation(
      prestationId: prestId,
      qty: qty,
      nameSnapshot: 'P$prestId',
      priceCentsSnapshot: 0,
      minutesSnapshot: 0,
      categoryIdSnapshot: catId,
      categoryNameSnapshot: 'Cat$catId',
      speciesNameSnapshot: 'S',
    );

TourStopPrestation _free(int prestId, int qty) => TourStopPrestation(
      prestationId: prestId,
      qty: qty,
      nameSnapshot: 'Free',
      priceCentsSnapshot: 0,
      minutesSnapshot: 0,
    );

void main() {
  test('empty input → empty output', () {
    expect(animalCountsFromPrestations(const []), isEmpty);
  });

  test('libre prestation → ignored', () {
    final out = animalCountsFromPrestations([_free(1, 5)]);
    expect(out, isEmpty);
  });

  test('one bound prestation → one count', () {
    final out = animalCountsFromPrestations([_bound(1, 12, 3)]);
    expect(out, hasLength(1));
    expect(out.first.categoryId, 3);
    expect(out.first.count, 12);
  });

  test('two bound on same category → MAX rule (not sum)', () {
    final out = animalCountsFromPrestations([
      _bound(1, 12, 3), // Tonte × 12 sur Petit
      _bound(2, 12, 3), // Vermifuge × 12 sur Petit
    ]);
    expect(out, hasLength(1));
    expect(out.first.categoryId, 3);
    expect(out.first.count, 12, reason: 'MAX, not 24');
  });

  test('two bound on same category, different qty → MAX', () {
    final out = animalCountsFromPrestations([
      _bound(1, 5, 3),
      _bound(2, 12, 3),
    ]);
    expect(out.first.count, 12);
  });

  test('mixed bound + libre → libre ignored, bound aggregated', () {
    final out = animalCountsFromPrestations([
      _bound(1, 12, 3),
      _free(9, 100),
      _bound(2, 4, 5),
    ]);
    expect(out, hasLength(2));
    expect(out.firstWhere((e) => e.categoryId == 3).count, 12);
    expect(out.firstWhere((e) => e.categoryId == 5).count, 4);
  });

  test('result is sorted by categoryId ascending', () {
    final out = animalCountsFromPrestations([
      _bound(1, 1, 5),
      _bound(2, 2, 1),
      _bound(3, 3, 3),
    ]);
    expect(out.map((e) => e.categoryId).toList(), [1, 3, 5]);
  });
}
```

- [ ] **Step 2: Verify it fails**

Run: `flutter test test/core/animal_counts_from_prestations_test.dart`
Expected: compilation failure.

- [ ] **Step 3: Implement**

```dart
// lib/core/animal_counts_from_prestations.dart
import '../domain/models/animal_count.dart';
import '../domain/models/tour_stop_prestation.dart';

/// Derives `AnimalCount` per category from a list of completed prestations.
///
/// Rules :
/// - Prestations with `categoryIdSnapshot == null` (libres) are ignored.
/// - For multiple prestations bound to the same category, the **MAX qty**
///   wins (not the sum). Rationale (from spec): doing two prestations on the
///   same animal in one day shouldn't double-count the herd.
/// - Result is sorted ascending by `categoryId`.
List<AnimalCount> animalCountsFromPrestations(
    List<TourStopPrestation> prestations) {
  final byCategory = <int, int>{};
  for (final p in prestations) {
    final cid = p.categoryIdSnapshot;
    if (cid == null) continue;
    final existing = byCategory[cid];
    if (existing == null || p.qty > existing) {
      byCategory[cid] = p.qty;
    }
  }
  final ids = byCategory.keys.toList()..sort();
  return [
    for (final id in ids) AnimalCount(categoryId: id, count: byCategory[id]!),
  ];
}
```

- [ ] **Step 4: Verify it passes**

Run: `flutter test test/core/animal_counts_from_prestations_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/animal_counts_from_prestations.dart test/core/animal_counts_from_prestations_test.dart
git commit -m "feat(core): add animalCountsFromPrestations (MAX rule)"
```

---

## Task 5: Add `TourStopPrestationListConverter`

**Files:**
- Create: `lib/infra/db/tour_stop_prestation_list_converter.dart`
- Test: `test/infra/db/tour_stop_prestation_list_converter_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/infra/db/tour_stop_prestation_list_converter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';
import 'package:coup_laine/infra/db/tour_stop_prestation_list_converter.dart';

void main() {
  const c = TourStopPrestationListConverter();

  test('empty list round-trips', () {
    expect(c.toSql(const []), '[]');
    expect(c.fromSql('[]'), const <TourStopPrestation>[]);
  });

  test('round-trips bound prestation', () {
    const list = [
      TourStopPrestation(
        prestationId: 1,
        qty: 12,
        nameSnapshot: 'Tonte',
        priceCentsSnapshot: 800,
        minutesSnapshot: 8,
        categoryIdSnapshot: 3,
        categoryNameSnapshot: 'Petit',
        speciesNameSnapshot: 'Mouton',
      ),
    ];
    expect(c.fromSql(c.toSql(list)), list);
  });

  test('round-trips libre prestation (null category fields)', () {
    const list = [
      TourStopPrestation(
        prestationId: 9,
        qty: 1,
        nameSnapshot: 'Visite',
        priceCentsSnapshot: 2000,
        minutesSnapshot: 0,
      ),
    ];
    expect(c.fromSql(c.toSql(list)), list);
  });

  test('round-trips mixed list', () {
    const list = [
      TourStopPrestation(
        prestationId: 1,
        qty: 12,
        nameSnapshot: 'Tonte',
        priceCentsSnapshot: 800,
        minutesSnapshot: 8,
        categoryIdSnapshot: 3,
        categoryNameSnapshot: 'Petit',
        speciesNameSnapshot: 'Mouton',
      ),
      TourStopPrestation(
        prestationId: 9,
        qty: 1,
        nameSnapshot: 'Visite',
        priceCentsSnapshot: 2000,
        minutesSnapshot: 0,
      ),
    ];
    expect(c.fromSql(c.toSql(list)), list);
  });
}
```

- [ ] **Step 2: Verify it fails**

Run: `flutter test test/infra/db/tour_stop_prestation_list_converter_test.dart`
Expected: compilation failure.

- [ ] **Step 3: Implement**

```dart
// lib/infra/db/tour_stop_prestation_list_converter.dart
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/tour_stop_prestation.dart';

class TourStopPrestationListConverter
    extends TypeConverter<List<TourStopPrestation>, String> {
  const TourStopPrestationListConverter();

  @override
  List<TourStopPrestation> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return [
      for (final raw in decoded)
        TourStopPrestation(
          prestationId: (raw as Map<String, dynamic>)['prestationId'] as int,
          qty: raw['qty'] as int,
          nameSnapshot: raw['nameSnapshot'] as String,
          priceCentsSnapshot: raw['priceCentsSnapshot'] as int,
          minutesSnapshot: raw['minutesSnapshot'] as int,
          categoryIdSnapshot: raw['categoryIdSnapshot'] as int?,
          categoryNameSnapshot: raw['categoryNameSnapshot'] as String?,
          speciesNameSnapshot: raw['speciesNameSnapshot'] as String?,
        ),
    ];
  }

  @override
  String toSql(List<TourStopPrestation> value) => jsonEncode([
        for (final p in value)
          {
            'prestationId': p.prestationId,
            'qty': p.qty,
            'nameSnapshot': p.nameSnapshot,
            'priceCentsSnapshot': p.priceCentsSnapshot,
            'minutesSnapshot': p.minutesSnapshot,
            'categoryIdSnapshot': p.categoryIdSnapshot,
            'categoryNameSnapshot': p.categoryNameSnapshot,
            'speciesNameSnapshot': p.speciesNameSnapshot,
          },
      ]);
}
```

- [ ] **Step 4: Verify it passes**

Run: `flutter test test/infra/db/tour_stop_prestation_list_converter_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/infra/db/tour_stop_prestation_list_converter.dart test/infra/db/tour_stop_prestation_list_converter_test.dart
git commit -m "feat(infra): add TourStopPrestationListConverter"
```

---

## Task 6: Schema bump 11→12 + `PrestationsTable` + new columns + `PrestationRepository`

**Files:**
- Modify: `lib/infra/db/tables.dart`
- Modify: `lib/infra/db/app_database.dart`
- Auto-generated: `lib/infra/db/app_database.g.dart`
- Create: `lib/data/repositories/prestation_repository.dart`
- Test: `test/data/prestation_repository_test.dart`

This task is the inflection point. It :
- Adds the new `PrestationsTable` (only new table).
- Adds new columns `plannedPrestations`, `actualPrestations` to `TourStopsTable` AND `prestations` to `ManualHistoryEntriesTable`. **Old columns** (`plannedAnimals`, `actualAnimals`, `animals` on manual_history) stay in place — they will be dropped in T23 once all consumers have migrated.
- Bumps `schemaVersion: 11 → 12`. The migration drops+recreates everything (consistent with #5 pattern).
- Runs drift codegen.
- Adds `PrestationRepository` with insert / rename / archive / unarchive / listActive / listArchived / listAll / countActive.

- [ ] **Step 1: Modify `lib/infra/db/tables.dart`**

Add the `PrestationsTable` class at the end of the file. Add the import for the new converter at the top, alongside the existing converter imports :

```dart
import 'tour_stop_prestation_list_converter.dart';
```

Then **add** new columns to `TourStopsTable` (do NOT remove `plannedAnimals` / `actualAnimals` yet) :

```dart
TextColumn get plannedPrestations => text()
    .map(const TourStopPrestationListConverter())
    .withDefault(const Constant('[]'))();
TextColumn get actualPrestations => text()
    .map(const TourStopPrestationListConverter())
    .nullable()();
```

Add the new column to `ManualHistoryEntriesTable` (do NOT remove `animals`) :

```dart
TextColumn get prestations => text()
    .map(const TourStopPrestationListConverter())
    .withDefault(const Constant('[]'))();
```

Append the new table at the end of the file :

```dart
@DataClassName('PrestationRow')
class PrestationsTable extends Table {
  @override
  String get tableName => 'prestations';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get priceCents => integer().nullable()();
  IntColumn get minutes => integer().nullable()();
  IntColumn get categoryId => integer().nullable()
      .references(AnimalCategoriesTable, #id, onDelete: KeyAction.setNull)();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}
```

- [ ] **Step 2: Modify `lib/infra/db/app_database.dart`**

Register the new table in `@DriftDatabase(tables: [...])` (add `PrestationsTable` to the list). Bump `schemaVersion` from 11 to 12. Update the `onUpgrade` guard from `if (from < 11)` to `if (from < 12)`.

```dart
@DriftDatabase(
  tables: [
    SettingsTable,
    ClientsTable,
    DistanceMatrixTable,
    SpeciesTable,
    AnimalCategoriesTable,
    ToursTable,
    TourStopsTable,
    ManualHistoryEntriesTable,
    PrestationsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  // ...
  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 12) {
        for (final table in allTables.toList().reversed) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
  // ...
}
```

- [ ] **Step 3: Run drift codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `app_database.g.dart` is regenerated. No errors. Look for `PrestationsTableCompanion` in the output.

- [ ] **Step 4: Write the failing test for `PrestationRepository`**

```dart
// test/data/prestation_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/data/repositories/animal_category_repository.dart';
import 'package:coup_laine/data/repositories/prestation_repository.dart';
import 'package:coup_laine/data/repositories/species_repository.dart';
import 'package:coup_laine/infra/db/app_database.dart';

void main() {
  late AppDatabase db;
  late PrestationRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PrestationRepository(db);
  });

  tearDown(() async => db.close());

  test('insert libre prestation and list active', () async {
    final id = await repo.insert(
      name: 'Visite',
      priceCents: 2000,
      minutes: 0,
      categoryId: null,
    );
    final list = await repo.listActive();
    expect(list, hasLength(1));
    expect(list.first.id, id);
    expect(list.first.name, 'Visite');
    expect(list.first.priceCents, 2000);
    expect(list.first.minutes, 0);
    expect(list.first.categoryId, isNull);
    expect(list.first.archivedAt, isNull);
  });

  test('insert bound prestation', () async {
    final speciesRepo = SpeciesRepository(db);
    final catsRepo = AnimalCategoryRepository(db);
    final speciesId = await speciesRepo.insert(name: 'Mouton');
    final catId = await catsRepo.insert(speciesId: speciesId, name: 'Petit');

    final id =
        await repo.insert(name: 'Tonte', priceCents: 800, minutes: 8, categoryId: catId);
    final list = await repo.listActive();
    expect(list.single.id, id);
    expect(list.single.categoryId, catId);
  });

  test('insert with null price/minutes', () async {
    await repo.insert(name: 'À compléter', categoryId: null);
    final list = await repo.listActive();
    expect(list.single.priceCents, isNull);
    expect(list.single.minutes, isNull);
  });

  test('rename updates name', () async {
    final id = await repo.insert(name: 'Tonte', categoryId: null);
    await repo.rename(id: id, name: 'Tonte ovine');
    expect((await repo.listActive()).single.name, 'Tonte ovine');
  });

  test('update prix and minutes', () async {
    final id = await repo.insert(name: 'Tonte', categoryId: null);
    await repo.updateValues(id: id, priceCents: 1500, minutes: 12);
    final p = (await repo.listActive()).single;
    expect(p.priceCents, 1500);
    expect(p.minutes, 12);
  });

  test('updateValues can clear price/minutes back to null', () async {
    final id =
        await repo.insert(name: 'Tonte', priceCents: 800, minutes: 8, categoryId: null);
    await repo.updateValues(id: id, priceCents: null, minutes: null);
    final p = (await repo.listActive()).single;
    expect(p.priceCents, isNull);
    expect(p.minutes, isNull);
  });

  test('archive sets archivedAt; listActive excludes; listArchived includes',
      () async {
    final id = await repo.insert(name: 'Tonte', categoryId: null);
    await repo.archive(id);
    expect(await repo.listActive(), isEmpty);
    final archived = await repo.listArchived();
    expect(archived, hasLength(1));
    expect(archived.first.archivedAt, isNotNull);
  });

  test('unarchive clears archivedAt', () async {
    final id = await repo.insert(name: 'Tonte', categoryId: null);
    await repo.archive(id);
    await repo.unarchive(id);
    expect(await repo.listActive(), hasLength(1));
    expect(await repo.listArchived(), isEmpty);
  });

  test('countActive', () async {
    expect(await repo.countActive(), 0);
    final a = await repo.insert(name: 'A', categoryId: null);
    await repo.insert(name: 'B', categoryId: null);
    expect(await repo.countActive(), 2);
    await repo.archive(a);
    expect(await repo.countActive(), 1);
  });

  test('listByCategory returns active prestations bound to that category', () async {
    final speciesRepo = SpeciesRepository(db);
    final catsRepo = AnimalCategoryRepository(db);
    final sId = await speciesRepo.insert(name: 'Mouton');
    final cPetit = await catsRepo.insert(speciesId: sId, name: 'Petit');
    final cGrand = await catsRepo.insert(speciesId: sId, name: 'Grand');
    await repo.insert(name: 'Tonte petit', categoryId: cPetit);
    await repo.insert(name: 'Tonte grand', categoryId: cGrand);
    await repo.insert(name: 'Visite', categoryId: null);

    final list = await repo.listByCategory(cPetit);
    expect(list, hasLength(1));
    expect(list.first.name, 'Tonte petit');
  });
}
```

- [ ] **Step 5: Verify it fails**

Run: `flutter test test/data/prestation_repository_test.dart`
Expected: compilation failure.

- [ ] **Step 6: Implement `PrestationRepository`**

```dart
// lib/data/repositories/prestation_repository.dart
import 'package:drift/drift.dart';

import '../../domain/models/prestation.dart';
import '../../infra/db/app_database.dart';

class PrestationRepository {
  final AppDatabase _db;
  PrestationRepository(this._db);

  Future<int> insert({
    required String name,
    int? priceCents,
    int? minutes,
    required int? categoryId,
  }) {
    return _db.into(_db.prestationsTable).insert(
          PrestationsTableCompanion.insert(
            name: name,
            priceCents: Value(priceCents),
            minutes: Value(minutes),
            categoryId: Value(categoryId),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> rename({required int id, required String name}) async {
    await (_db.update(_db.prestationsTable)..where((p) => p.id.equals(id)))
        .write(PrestationsTableCompanion(name: Value(name)));
  }

  Future<void> updateValues({
    required int id,
    int? priceCents,
    int? minutes,
  }) async {
    await (_db.update(_db.prestationsTable)..where((p) => p.id.equals(id)))
        .write(PrestationsTableCompanion(
      priceCents: Value(priceCents),
      minutes: Value(minutes),
    ));
  }

  Future<void> updateBinding({
    required int id,
    required int? categoryId,
  }) async {
    await (_db.update(_db.prestationsTable)..where((p) => p.id.equals(id)))
        .write(PrestationsTableCompanion(categoryId: Value(categoryId)));
  }

  Future<void> archive(int id) async {
    await (_db.update(_db.prestationsTable)..where((p) => p.id.equals(id)))
        .write(PrestationsTableCompanion(
      archivedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> unarchive(int id) async {
    await (_db.update(_db.prestationsTable)..where((p) => p.id.equals(id)))
        .write(const PrestationsTableCompanion(archivedAt: Value(null)));
  }

  Future<List<Prestation>> listActive() async {
    final rows = await (_db.select(_db.prestationsTable)
          ..where((p) => p.archivedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Prestation>> listArchived() async {
    final rows = await (_db.select(_db.prestationsTable)
          ..where((p) => p.archivedAt.isNotNull())
          ..orderBy([(p) => OrderingTerm(expression: p.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Prestation>> listAll() async {
    final rows = await (_db.select(_db.prestationsTable)
          ..orderBy([(p) => OrderingTerm(expression: p.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Prestation>> listByCategory(int categoryId) async {
    final rows = await (_db.select(_db.prestationsTable)
          ..where((p) =>
              p.categoryId.equals(categoryId) & p.archivedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<int> countActive() async {
    final rows = await (_db.select(_db.prestationsTable)
          ..where((p) => p.archivedAt.isNull()))
        .get();
    return rows.length;
  }

  Prestation _toDomain(PrestationRow row) => Prestation(
        id: row.id,
        name: row.name,
        priceCents: row.priceCents,
        minutes: row.minutes,
        categoryId: row.categoryId,
        archivedAt: row.archivedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!),
      );
}
```

- [ ] **Step 7: Verify all tests pass**

Run: `flutter test test/data/prestation_repository_test.dart`
Expected: PASS (10 tests).

Run the full suite to make sure the schema bump didn't break existing tests :
Run: `flutter test`
Expected: all green (existing tests should still pass — old columns are still there, only added). If a test fails because in-memory `forTesting` DB is rebuilt fresh, it shouldn't depend on migration logic.

- [ ] **Step 8: Commit**

```bash
git add lib/infra/db/tables.dart lib/infra/db/app_database.dart lib/infra/db/app_database.g.dart lib/data/repositories/prestation_repository.dart test/data/prestation_repository_test.dart
git commit -m "feat(db): add PrestationsTable + repo, schema 11 → 12"
```

---

## Task 7: Vertical refactor — `TourStop` model + `Intervention` model + `TourRepository` + `ClientRepository` cascade methods

**Files:**
- Modify: `lib/domain/models/tour_stop.dart`
- Modify: `lib/domain/models/intervention.dart`
- Modify: `lib/data/repositories/tour_repository.dart`
- Modify: `lib/data/repositories/client_repository.dart`
- Modify: `test/data/tour_repository_test.dart`
- Modify: `test/data/client_repository_test.dart`

This task is a **vertical slice**. The build won't be green between steps; only at the end. The change pivots `TourStop.planned`/`actual` from `List<TourStopAnimal>` to `List<TourStopPrestation>`, propagates to `TourStopDraft`, `TourRepository.plan`/`update`/`markCompleted`, and `ClientRepository.applyInterventionActuals`/`applyManualEntryToClient`/`recomputeClientFromHistory`/`listInterventionsForClient`.

The MAX-rule helper `animalCountsFromPrestations` (T4) replaces the per-category overwrite logic in `_mergePerCategory`.

- [ ] **Step 1: Update `lib/domain/models/tour_stop.dart`**

```dart
// lib/domain/models/tour_stop.dart
import 'tour_stop_prestation.dart';

class TourStop {
  final int id;
  final int tourId;
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final List<TourStopPrestation> plannedPrestations;
  final List<TourStopPrestation>? actualPrestations;
  final String? interventionNote;
  final int feeShareCents;

  const TourStop({
    required this.id,
    required this.tourId,
    required this.clientId,
    required this.clientNameSnapshot,
    required this.orderIndex,
    required this.estimatedArrivalMinutes,
    required this.estimatedDepartureMinutes,
    required this.plannedPrestations,
    this.actualPrestations,
    this.interventionNote,
    required this.feeShareCents,
  });
}
```

- [ ] **Step 2: Update `lib/domain/models/intervention.dart`**

Replace `animals` with `prestations` (and update the `animalsTotal` getter). Keep the rest intact.

```dart
// lib/domain/models/intervention.dart
import 'tour_stop_prestation.dart';

enum InterventionKind { tour, manual }

class Intervention {
  final InterventionKind kind;
  final int? tourId;
  final int? stopId;
  final int? manualEntryId;
  final DateTime date;
  final List<TourStopPrestation> prestations;
  final String? note;
  final bool hasBilan;

  const Intervention({
    required this.kind,
    required this.date,
    required this.prestations,
    required this.hasBilan,
    this.tourId,
    this.stopId,
    this.manualEntryId,
    this.note,
  });

  /// Sum of qty over all prestations (used for compact display only).
  int get prestationsQtyTotal {
    var total = 0;
    for (final p in prestations) {
      total += p.qty;
    }
    return total;
  }

  /// Sum of priceCentsSnapshot × qty (for compact "total revenu" display).
  int get totalRevenueCents {
    var total = 0;
    for (final p in prestations) {
      total += p.priceCentsSnapshot * p.qty;
    }
    return total;
  }

  /// Sum of minutesSnapshot × qty.
  int get totalMinutes {
    var total = 0;
    for (final p in prestations) {
      total += p.minutesSnapshot * p.qty;
    }
    return total;
  }
}
```

- [ ] **Step 3: Update `lib/data/repositories/tour_repository.dart`**

Replace `TourStopAnimal` references with `TourStopPrestation`. Replace `normalizeTourStopAnimals` with `normalizeTourStopPrestations`. Replace `plannedAnimals`/`actualAnimals` columns with `plannedPrestations`/`actualPrestations`. Replace `_mergePerCategory` invocations with `animalCountsFromPrestations`.

Imports at top of file (replace existing) :

```dart
import 'package:drift/drift.dart';

import '../../core/animal_counts_from_prestations.dart';
import '../../core/animal_counts_normalizer.dart';
import '../../core/tour_stop_prestations_normalizer.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/tour.dart';
import '../../domain/models/tour_stop.dart';
import '../../domain/models/tour_stop_prestation.dart';
import '../../infra/db/app_database.dart';
```

`TourStopDraft` (top of file) now carries `plannedPrestations` :

```dart
class TourStopDraft {
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final List<TourStopPrestation> plannedPrestations;
  final int feeShareCents;

  const TourStopDraft({
    required this.clientNameSnapshot,
    required this.orderIndex,
    required this.estimatedArrivalMinutes,
    required this.estimatedDepartureMinutes,
    required this.plannedPrestations,
    required this.feeShareCents,
    this.clientId,
  });
}
```

`TourRepository.plan` writes the new column :

```dart
Future<int> plan(TourDraft draft) async {
  return _db.transaction(() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final tourId = await _db.into(_db.toursTable).insert(
          ToursTableCompanion.insert(
            plannedDate: _toEpochDay(draft.plannedDate),
            startTimeMinutes: draft.startTimeMinutes,
            status: 'planned',
            totalDistanceMeters: draft.totalDistanceMeters,
            totalDriveSeconds: draft.totalDriveSeconds,
            totalTravelFeeCents: draft.totalTravelFeeCents,
            notes: Value(draft.notes),
            createdAt: now,
          ),
        );
    for (final s in draft.stops) {
      await _db.into(_db.tourStopsTable).insert(
            TourStopsTableCompanion.insert(
              tourId: tourId,
              clientId: Value(s.clientId),
              clientNameSnapshot: s.clientNameSnapshot,
              orderIndex: s.orderIndex,
              estimatedArrivalMinutes: s.estimatedArrivalMinutes,
              estimatedDepartureMinutes: s.estimatedDepartureMinutes,
              plannedPrestations: Value(
                  normalizeTourStopPrestations(s.plannedPrestations)),
              feeShareCents: s.feeShareCents,
            ),
          );
    }
    return tourId;
  });
}
```

`TourRepository.update` uses the same approach (replace `plannedAnimals` → `plannedPrestations`, swap normalizer).

`TourRepository.markCompleted` :

```dart
Future<void> markCompleted(
  int id,
  Map<int, ({List<TourStopPrestation> actuals, String? note})> actuals,
) async {
  await _db.transaction(() async {
    final tour = await (_db.select(_db.toursTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    final now = DateTime.now().millisecondsSinceEpoch;
    final tourDateUtc = DateTime.fromMillisecondsSinceEpoch(
        tour.plannedDate * 86400000,
        isUtc: true);
    final tourDate =
        DateTime(tourDateUtc.year, tourDateUtc.month, tourDateUtc.day);

    await (_db.update(_db.toursTable)..where((t) => t.id.equals(id))).write(
      ToursTableCompanion(
        status: const Value('completed'),
        completedAt: Value(now),
      ),
    );

    final stopRows = await (_db.select(_db.tourStopsTable)
          ..where((s) => s.tourId.equals(id)))
        .get();

    for (final s in stopRows) {
      final entry = actuals[s.id];
      if (entry == null) continue;
      final normalized = normalizeTourStopPrestations(entry.actuals);

      await (_db.update(_db.tourStopsTable)
            ..where((t) => t.id.equals(s.id)))
          .write(
        TourStopsTableCompanion(
          actualPrestations: Value(normalized),
          interventionNote: Value(entry.note),
        ),
      );

      final cid = s.clientId;
      if (cid != null) {
        // Derive per-category counts from the actual prestations (MAX rule,
        // libres ignored) and merge them into the client's stored animals.
        final derived = animalCountsFromPrestations(normalized);
        final clientRow = await (_db.select(_db.clientsTable)
              ..where((c) => c.id.equals(cid)))
            .getSingleOrNull();
        if (clientRow != null) {
          final byId = <int, int>{
            for (final a in clientRow.animals) a.categoryId: a.count,
          };
          for (final a in derived) {
            byId[a.categoryId] = a.count;
          }
          final mergedAnimals = normalizeAnimalCounts([
            for (final entry in byId.entries)
              AnimalCount(categoryId: entry.key, count: entry.value),
          ]);
          await (_db.update(_db.clientsTable)
                ..where((c) => c.id.equals(cid)))
              .write(
            ClientsTableCompanion(
              animals: Value(mergedAnimals),
              lastInterventionDate: Value(tourDate.millisecondsSinceEpoch),
              updatedAt: Value(now),
            ),
          );
        }
      }
    }
  });
}
```

`_stopFromRow` reads from the new columns :

```dart
TourStop _stopFromRow(TourStopRow row) => TourStop(
      id: row.id,
      tourId: row.tourId,
      clientId: row.clientId,
      clientNameSnapshot: row.clientNameSnapshot,
      orderIndex: row.orderIndex,
      estimatedArrivalMinutes: row.estimatedArrivalMinutes,
      estimatedDepartureMinutes: row.estimatedDepartureMinutes,
      plannedPrestations: row.plannedPrestations,
      actualPrestations: row.actualPrestations,
      interventionNote: row.interventionNote,
      feeShareCents: row.feeShareCents,
    );
```

- [ ] **Step 4: Update `lib/data/repositories/client_repository.dart`**

Update imports : drop `tour_stop_animal.dart` import, add `tour_stop_prestation.dart` import and `animal_counts_from_prestations.dart` import.

`applyInterventionActuals` and `applyManualEntryToClient` accept `List<TourStopPrestation>` and use `animalCountsFromPrestations` for the derivation :

```dart
Future<void> applyInterventionActuals(
  int clientId, {
  required List<TourStopPrestation> actuals,
  required DateTime tourDate,
}) async {
  final c = await findById(clientId);
  if (c == null) return;
  final derived = animalCountsFromPrestations(actuals);
  final merged = _mergePerCategory(c.animals, derived);
  await (_db.update(_db.clientsTable)
        ..where((t) => t.id.equals(clientId)))
      .write(
    ClientsTableCompanion(
      animals: Value(merged),
      lastInterventionDate: Value(tourDate.millisecondsSinceEpoch),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ),
  );
}

Future<void> applyManualEntryToClient(
  int clientId, {
  required DateTime date,
  required List<TourStopPrestation> prestations,
}) async {
  final c = await findById(clientId);
  if (c == null) return;
  final entryMs = DateTime(date.year, date.month, date.day)
      .millisecondsSinceEpoch;
  final currentMs = c.lastInterventionDate?.millisecondsSinceEpoch;
  if (currentMs != null && entryMs <= currentMs) return;

  final derived = animalCountsFromPrestations(prestations);
  final merged = _mergePerCategory(c.animals, derived);
  await (_db.update(_db.clientsTable)
        ..where((t) => t.id.equals(clientId)))
      .write(
    ClientsTableCompanion(
      animals: Value(merged),
      lastInterventionDate: Value(entryMs),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ),
  );
}
```

`_mergePerCategory` now takes `List<AnimalCount>` (not `List<TourStopAnimal>`) on the right-hand side :

```dart
List<AnimalCount> _mergePerCategory(
  List<AnimalCount> existing,
  List<AnimalCount> incoming,
) {
  final byId = <int, int>{
    for (final a in existing) a.categoryId: a.count,
  };
  for (final a in incoming) {
    byId[a.categoryId] = a.count;
  }
  return normalizeAnimalCounts([
    for (final entry in byId.entries)
      AnimalCount(categoryId: entry.key, count: entry.value),
  ]);
}
```

`recomputeClientFromHistory` walks `Intervention.prestations` (a `List<TourStopPrestation>`), derives the bound-category counts via `animalCountsFromPrestations`, and picks the **first occurrence by date desc** (same logic as today, just on derived counts). Note: `listInterventionsForClient` already returns sorted desc.

```dart
Future<void> recomputeClientFromHistory(int clientId) async {
  final list = await listInterventionsForClient(clientId);
  final now = DateTime.now().millisecondsSinceEpoch;

  if (list.isEmpty) {
    await (_db.update(_db.clientsTable)
          ..where((t) => t.id.equals(clientId)))
        .write(
      ClientsTableCompanion(
        animals: const Value([]),
        lastInterventionDate: const Value(null),
        updatedAt: Value(now),
      ),
    );
    return;
  }

  // For each categoryId, the most recent intervention that mentions it wins.
  final byId = <int, int>{};
  for (final iv in list) {
    final derived = animalCountsFromPrestations(iv.prestations);
    for (final a in derived) {
      byId.putIfAbsent(a.categoryId, () => a.count);
    }
  }
  final newest = list.first;
  final newestMs = DateTime(
    newest.date.year,
    newest.date.month,
    newest.date.day,
  ).millisecondsSinceEpoch;

  await (_db.update(_db.clientsTable)
        ..where((t) => t.id.equals(clientId)))
      .write(
    ClientsTableCompanion(
      animals: Value(normalizeAnimalCounts([
        for (final e in byId.entries)
          AnimalCount(categoryId: e.key, count: e.value),
      ])),
      lastInterventionDate: Value(newestMs),
      updatedAt: Value(now),
    ),
  );
}
```

`listInterventionsForClient` builds tour interventions from `actualPrestations` (or `plannedPrestations` if no bilan yet) :

```dart
final tourInterventions = <Intervention>[
  for (final r in stopRows)
    () {
      final stop = r.readTable(_db.tourStopsTable);
      final tour = r.readTable(_db.toursTable);
      final hasBilan = stop.actualPrestations != null;
      final utc = DateTime.fromMillisecondsSinceEpoch(
        tour.plannedDate * 86400000,
        isUtc: true,
      );
      return Intervention(
        kind: InterventionKind.tour,
        tourId: tour.id,
        stopId: stop.id,
        date: DateTime(utc.year, utc.month, utc.day),
        prestations: stop.actualPrestations ?? stop.plannedPrestations,
        note: stop.interventionNote,
        hasBilan: hasBilan,
      );
    }(),
];
```

The manual entries branch uses `e.prestations` (the field is renamed in T9; use `e.animals` here for now and revisit when T9 lands — see Step 6 below).

NOTE on the chicken-and-egg with T9: `ManualHistoryEntry.animals` (currently `List<TourStopAnimal>`) is renamed to `prestations` (`List<TourStopPrestation>`) in T9. To keep T7 self-contained, **defer T9's full migration** : in this step, the manual branch of `listInterventionsForClient` uses an empty list temporarily :

```dart
// TEMP for T7: T9 will replace e.animals with e.prestations.
final manualEntries = await _manualHistory.listForClient(clientId);
final manualInterventions = <Intervention>[
  for (final e in manualEntries)
    Intervention(
      kind: InterventionKind.manual,
      manualEntryId: e.id,
      date: e.date,
      prestations: const [], // FIXME(T9): use e.prestations once renamed
      note: e.note,
      hasBilan: true,
    ),
];
```

Manual-entry coverage is restored fully in T9. The repo tests for manual history (which still use `e.animals`) are migrated in T9 in the same task.

- [ ] **Step 5: Update `test/data/tour_repository_test.dart`**

Replace every reference to `TourStopAnimal` with `TourStopPrestation`, every `planned: [...]` with `plannedPrestations: [...]`, every `normalizeTourStopAnimals` with `normalizeTourStopPrestations`. Existing tests cover : `plan` round-trip, `update` replaces stops, `markCompleted` updates client.animals.

The test's `markCompleted` test should now build a `TourStopPrestation` with a `categoryIdSnapshot` so the derived count cascades to `client.animals`. Example:

```dart
test('markCompleted derives client.animals via MAX rule from bound prestations',
    () async {
  // ... setup species/cat fixtures, insert client with animals empty,
  //     plan a tour with one stop, then markCompleted with two
  //     prestations bound to the same category
  await repo.markCompleted(tourId, {
    stopId: (
      actuals: [
        TourStopPrestation(
          prestationId: 1,
          qty: 12,
          nameSnapshot: 'Tonte',
          priceCentsSnapshot: 800,
          minutesSnapshot: 8,
          categoryIdSnapshot: catPetit,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
        ),
        TourStopPrestation(
          prestationId: 2,
          qty: 12,
          nameSnapshot: 'Vermifuge',
          priceCentsSnapshot: 500,
          minutesSnapshot: 2,
          categoryIdSnapshot: catPetit,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
        ),
      ],
      note: null,
    ),
  });
  final client = await clientRepo.findById(clientId);
  // MAX rule: only 12, not 24
  expect(client!.animals.single.count, 12);
});
```

- [ ] **Step 6: Update `test/data/client_repository_test.dart`**

Existing tests for `applyManualEntryToClient` / `recomputeClientFromHistory` use `List<TourStopAnimal>`. Migrate them to use `List<TourStopPrestation>` with `categoryIdSnapshot` set, so the derivation produces the expected counts.

Add a new test that verifies the MAX rule on `recomputeClientFromHistory` (two interventions on different dates with overlapping categories — the most recent wins per category, intra-intervention MAX applies).

- [ ] **Step 7: Run all repo tests**

Run: `flutter test test/data/tour_repository_test.dart test/data/client_repository_test.dart`
Expected: PASS. If anything else in the codebase imports `TourStop.planned` or `Intervention.animals`, the run-time error in those callers is OK for now — those are touched in T8 (use cases) and T18-T20 (UI). They don't affect these test files.

- [ ] **Step 8: Run full build**

Run: `flutter analyze`
Expected: errors only in files we'll touch in T8-T20 (BuildTourDraft, tour_draft_controller, tour_draft_screen, tour_completion_screen, manual_history_entry_sheet, client_history_screen, animal_counts_badges if it consumes Intervention, json_export_service). Take note of the failing files — they're the targets of subsequent tasks.

- [ ] **Step 9: Commit**

```bash
git add lib/domain/models/tour_stop.dart lib/domain/models/intervention.dart lib/data/repositories/tour_repository.dart lib/data/repositories/client_repository.dart test/data/tour_repository_test.dart test/data/client_repository_test.dart
git commit -m "refactor(domain,repo): pivot TourStop & Intervention to prestations"
```

---

## Task 8: Vertical refactor — `BuildTourDraft` + `TourDurationEstimator` + `BuildOptimizedTourProposal` + `tour_draft_controller`

**Files:**
- Modify: `lib/domain/use_cases/build_tour_draft.dart`
- Modify: `lib/domain/use_cases/tour_duration_estimator.dart`
- Modify: `lib/domain/use_cases/build_optimized_tour_proposal.dart`
- Modify: `lib/state/tour_draft_controller.dart`
- Modify: `test/domain/build_tour_draft_test.dart`
- Modify: `test/domain/tour_duration_estimator_test.dart`
- Modify: `test/domain/build_optimized_tour_proposal_test.dart`

This task pivots the use cases from operating on `List<TourStopAnimal>` to `List<TourStopPrestation>`. New `TourDraftResult` carries `revenueCentsPerStop`, `totalRevenueCents`, `totalNetCents`. The `tour_draft_controller` is updated to manage a `Map<int, List<TourStopPrestation>>` (clientId → selected prestations) and feed it to `BuildTourDraft.build`.

- [ ] **Step 1: Update `tour_duration_estimator.dart`**

```dart
// lib/domain/use_cases/tour_duration_estimator.dart
import '../models/tour_stop_prestation.dart';

class TourDurationResult {
  final List<int> stopArrivalMinutes;
  final List<int> stopDepartureMinutes;
  final int endTimeMinutes;
  final int totalDriveSeconds;
  final int totalInterventionMinutes;

  const TourDurationResult({
    required this.stopArrivalMinutes,
    required this.stopDepartureMinutes,
    required this.endTimeMinutes,
    required this.totalDriveSeconds,
    required this.totalInterventionMinutes,
  });
}

class TourDurationEstimator {
  const TourDurationEstimator();

  /// Per-stop time = `Σ prestation.qty × prestation.minutesSnapshot`.
  /// `minutesSnapshot == 0` (prestation without a duration set) contributes 0.
  TourDurationResult estimate({
    required int startTimeMinutes,
    required List<int> driveSecondsToStops,
    required int driveSecondsBackToBase,
    required List<List<TourStopPrestation>> stops,
  }) {
    final n = driveSecondsToStops.length;
    if (stops.length != n) {
      throw ArgumentError(
        'stops and driveSecondsToStops must have length n '
        '(got ${stops.length} and $n)',
      );
    }

    final arrivals = <int>[];
    final departures = <int>[];
    var clock = startTimeMinutes;
    var totalDrive = 0;
    var totalIntervention = 0;

    for (var i = 0; i < n; i++) {
      final driveMin = (driveSecondsToStops[i] / 60).round();
      clock += driveMin;
      totalDrive += driveSecondsToStops[i];
      arrivals.add(clock);

      var stopMin = 0;
      for (final p in stops[i]) {
        stopMin += p.qty * p.minutesSnapshot;
      }
      clock += stopMin;
      totalIntervention += stopMin;
      departures.add(clock);
    }

    final returnDriveMin = (driveSecondsBackToBase / 60).round();
    clock += returnDriveMin;
    totalDrive += driveSecondsBackToBase;

    return TourDurationResult(
      stopArrivalMinutes: arrivals,
      stopDepartureMinutes: departures,
      endTimeMinutes: clock,
      totalDriveSeconds: totalDrive,
      totalInterventionMinutes: totalIntervention,
    );
  }
}
```

- [ ] **Step 2: Update `tour_duration_estimator_test.dart`**

Replace `TourStopAnimal` with `TourStopPrestation`, `count` with `qty`. Add a test that verifies a libre prestation (categoryIdSnapshot null) still contributes its `qty × minutesSnapshot`.

- [ ] **Step 3: Update `build_tour_draft.dart`**

New signature : `prestationsPerClient` instead of `categoryLookup`. New result fields : `revenueCentsPerStop`, `totalRevenueCents`, `totalNetCents`.

```dart
// lib/domain/use_cases/build_tour_draft.dart
import '../models/client.dart';
import '../models/distance_matrix_entry.dart';
import '../models/settings.dart';
import '../models/tour_stop_prestation.dart';
import 'bracket_counter.dart';
import 'cost_split_calculator.dart';
import 'tour_duration_estimator.dart';
import 'tour_order_optimizer.dart';

class TourDraftResult {
  final List<int> orderedClientIds;
  final List<int> arrivalMinutes;
  final List<int> departureMinutes;
  final int endTimeMinutes;
  final int totalDistanceMeters;
  final int totalDriveSeconds;
  final int totalInterventionMinutes;
  final int totalFeeCents;
  final List<int> feeShareCents;
  final List<List<TourStopPrestation>> plannedPrestationsPerStop;
  final int feeFarthestCents;
  final int feeInterCents;
  // NEW :
  final List<int> revenueCentsPerStop;
  final int totalRevenueCents;
  final int totalNetCents;

  const TourDraftResult({
    required this.orderedClientIds,
    required this.arrivalMinutes,
    required this.departureMinutes,
    required this.endTimeMinutes,
    required this.totalDistanceMeters,
    required this.totalDriveSeconds,
    required this.totalInterventionMinutes,
    required this.totalFeeCents,
    required this.feeShareCents,
    required this.plannedPrestationsPerStop,
    required this.feeFarthestCents,
    required this.feeInterCents,
    required this.revenueCentsPerStop,
    required this.totalRevenueCents,
    required this.totalNetCents,
  });
}

class BuildTourDraft {
  const BuildTourDraft();

  TourDraftResult build({
    required List<int> candidateIds,
    required List<Client> candidates,
    required List<DistanceMatrixEntry> matrix,
    required Settings settings,
    required Map<int, List<TourStopPrestation>> prestationsPerClient,
    required int startTimeMinutes,
    List<int>? presetOrder,
  }) {
    if (candidateIds.isEmpty) {
      throw ArgumentError('Cannot build a draft with zero candidates');
    }
    final byId = {for (final c in candidates) c.id: c};
    for (final id in candidateIds) {
      if (!byId.containsKey(id)) {
        throw ArgumentError('Missing client id=$id');
      }
    }

    final nodeIds = <int>[0, ...candidateIds];
    final n = nodeIds.length;
    final dm = List.generate(n, (_) => List<int>.filled(n, 0));
    final tm = List.generate(n, (_) => List<int>.filled(n, 0));
    final lookup = <int, int>{};
    for (final e in matrix) {
      lookup[e.fromId * 1000000 + e.toId] = e.distanceMeters;
    }
    final lookupT = <int, int>{};
    for (final e in matrix) {
      lookupT[e.fromId * 1000000 + e.toId] = e.durationSeconds;
    }
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        final key = nodeIds[i] * 1000000 + nodeIds[j];
        dm[i][j] = lookup[key] ??
            (throw StateError(
                'Missing matrix entry ${nodeIds[i]} -> ${nodeIds[j]}'));
        tm[i][j] = lookupT[key] ?? 0;
      }
    }

    final visitIndices = presetOrder != null
        ? presetOrder.map((id) => nodeIds.indexOf(id)).toList()
        : const TourOrderOptimizer().optimise(distanceMatrix: dm);
    final orderedIds = visitIndices.map((i) => nodeIds[i]).toList();

    final driveToStops = <int>[
      for (var k = 0; k < visitIndices.length; k++)
        tm[k == 0 ? 0 : visitIndices[k - 1]][visitIndices[k]]
    ];
    final driveBack = tm[visitIndices.last][0];

    // Per-stop prestations come straight from the controller's map.
    // Missing entries (client without picker selection) → empty list.
    final plannedPerStop = <List<TourStopPrestation>>[
      for (final id in orderedIds) prestationsPerClient[id] ?? const [],
    ];

    final duration = const TourDurationEstimator().estimate(
      startTimeMinutes: startTimeMinutes,
      driveSecondsToStops: driveToStops,
      driveSecondsBackToBase: driveBack,
      stops: plannedPerStop,
    );

    final baseToStopMeters = <int>[
      for (final id in orderedIds) dm[0][nodeIds.indexOf(id)]
    ];
    final interStopMeters = <int>[
      for (var k = 0; k < orderedIds.length - 1; k++)
        dm[nodeIds.indexOf(orderedIds[k])]
            [nodeIds.indexOf(orderedIds[k + 1])]
    ];
    final returnMeters = dm[nodeIds.indexOf(orderedIds.last)][0];

    final brackets = BracketCounter(
      bracketKm: settings.bracketKm,
      feeEurosPerBracket: settings.travelFeeEurosPerBracket,
    );
    final split = CostSplitCalculator(brackets: brackets).split(
      baseToStopMeters: baseToStopMeters,
      interStopMeters: interStopMeters,
    );

    final totalDistance = baseToStopMeters.first +
        interStopMeters.fold<int>(0, (a, b) => a + b) +
        returnMeters;

    // Revenue per stop = Σ priceCentsSnapshot × qty.
    final revenuePerStop = <int>[
      for (final list in plannedPerStop)
        list.fold<int>(0, (sum, p) => sum + p.priceCentsSnapshot * p.qty),
    ];
    final totalRevenue = revenuePerStop.fold<int>(0, (a, b) => a + b);

    return TourDraftResult(
      orderedClientIds: orderedIds,
      arrivalMinutes: duration.stopArrivalMinutes,
      departureMinutes: duration.stopDepartureMinutes,
      endTimeMinutes: duration.endTimeMinutes,
      totalDistanceMeters: totalDistance,
      totalDriveSeconds: duration.totalDriveSeconds,
      totalInterventionMinutes: duration.totalInterventionMinutes,
      totalFeeCents: split.totalFeeCents,
      feeShareCents: split.shareCents,
      plannedPrestationsPerStop: plannedPerStop,
      feeFarthestCents: split.feeFarthestCents,
      feeInterCents: split.feeInterCents,
      revenueCentsPerStop: revenuePerStop,
      totalRevenueCents: totalRevenue,
      totalNetCents: totalRevenue - split.totalFeeCents,
    );
  }
}
```

- [ ] **Step 4: Update `build_tour_draft_test.dart`**

Replace the `categoryLookup` arg with `prestationsPerClient`. Add tests :
- `revenue and net are computed from prestation snapshots`
- `revenue is 0 when no prestation provided`
- `intervention duration is 0 when prestationsPerClient lacks an entry for a candidate`

- [ ] **Step 5: Update `build_optimized_tour_proposal.dart`**

`BuildOptimizedTourProposal` likely has a similar `categoryLookup` parameter. Refactor mirror : it now accepts `prestationsPerClient` (a `Map<int, List<TourStopPrestation>>`). For the optimizer use case, since the proposal screen pre-selects clients without per-stop user choice, the proposal is built with `const []` per client (zero prestation duration assumed) — the user fills in prestations in the draft screen later.

Actually, since `BuildOptimizedTourProposal` builds a proposal **before** the user picks prestations, treat the input as `prestationsPerClient: const {}` (empty map) → all stops have empty plannedPrestations → intervention duration is 0 in the proposal. This is acceptable: the user sees the **drive-time** estimate and refines after.

Trim the use case's interface : drop `categoryLookup`, treat per-stop prestations as empty unless callers pass otherwise.

- [ ] **Step 6: Update `state/tour_draft_controller.dart`**

The controller now manages the picker selections. Inspect the existing controller to find :
- The list of selected client ids.
- The call site for `BuildTourDraft.build`.

Add a `Map<int, List<TourStopPrestation>>` field to the controller's state (`prestationsByClientId`). Add a method `setPrestationsForClient(int clientId, List<TourStopPrestation> p)`. When the user removes a client from the tour, remove their key from the map.

Pass the map to `BuildTourDraft.build(..., prestationsPerClient: state.prestationsByClientId, ...)`.

When the controller persists the tour via `TourRepository.plan`, build each `TourStopDraft.plannedPrestations` from `result.plannedPrestationsPerStop[i]`.

- [ ] **Step 7: Run all use case + state tests**

Run: `flutter test test/domain/build_tour_draft_test.dart test/domain/tour_duration_estimator_test.dart test/domain/build_optimized_tour_proposal_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/domain/use_cases/build_tour_draft.dart lib/domain/use_cases/tour_duration_estimator.dart lib/domain/use_cases/build_optimized_tour_proposal.dart lib/state/tour_draft_controller.dart test/domain/build_tour_draft_test.dart test/domain/tour_duration_estimator_test.dart test/domain/build_optimized_tour_proposal_test.dart
git commit -m "refactor(use-case): pivot tour draft & duration & optimizer to prestations"
```

---

## Task 9: Refactor `ManualHistoryEntry` + `ManualHistoryRepository` + restore `listInterventionsForClient` manual branch

**Files:**
- Modify: `lib/domain/models/manual_history_entry.dart`
- Modify: `lib/data/repositories/manual_history_repository.dart`
- Modify: `lib/data/repositories/client_repository.dart` (replace TEMP from T7)
- Modify: `test/data/manual_history_repository_test.dart`
- Modify: `test/data/client_repository_test.dart`

- [ ] **Step 1: Update `lib/domain/models/manual_history_entry.dart`**

```dart
// lib/domain/models/manual_history_entry.dart
import 'tour_stop_prestation.dart';

class ManualHistoryEntry {
  final int id;
  final int clientId;
  final DateTime date;
  final List<TourStopPrestation> prestations;
  final String? note;

  const ManualHistoryEntry({
    required this.id,
    required this.clientId,
    required this.date,
    required this.prestations,
    this.note,
  });

  int get prestationsQtyTotal {
    var total = 0;
    for (final p in prestations) {
      total += p.qty;
    }
    return total;
  }
}
```

- [ ] **Step 2: Update `lib/data/repositories/manual_history_repository.dart`**

Read the current implementation, then mirror the pattern of `tour_repository.dart` :
- Insert / update / delete : write to the new `prestations` column instead of `animals`. Use `normalizeTourStopPrestations`.
- `_toDomain` reads from `row.prestations`.
- The `listClientDatesSinceEpochDays` query is unchanged (depends only on date and clientId).
- Drop the import of `TourStopAnimal` and the converter import; add imports for `TourStopPrestation` and `normalizeTourStopPrestations`.

The signatures of `insert`, `update`, `delete` take `prestations: List<TourStopPrestation>` (rename `animals` → `prestations`).

- [ ] **Step 3: Update `client_repository.dart` — restore manual branch**

Replace the TEMP block from T7 :

```dart
final manualEntries = await _manualHistory.listForClient(clientId);
final manualInterventions = <Intervention>[
  for (final e in manualEntries)
    Intervention(
      kind: InterventionKind.manual,
      manualEntryId: e.id,
      date: e.date,
      prestations: e.prestations,
      note: e.note,
      hasBilan: true,
    ),
];
```

- [ ] **Step 4: Update tests**

In `manual_history_repository_test.dart`, replace `animals: [...TourStopAnimal(...)]` with `prestations: [...TourStopPrestation(...)]`. Re-check round-trip and CRUD coverage.

In `client_repository_test.dart`, ensure the manual-history coverage tests use `TourStopPrestation` and pass `categoryIdSnapshot` so derivation works.

- [ ] **Step 5: Run tests**

Run: `flutter test test/data/manual_history_repository_test.dart test/data/client_repository_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/models/manual_history_entry.dart lib/data/repositories/manual_history_repository.dart lib/data/repositories/client_repository.dart test/data/manual_history_repository_test.dart test/data/client_repository_test.dart
git commit -m "refactor(repo): pivot ManualHistoryEntry to prestations"
```

---

## Task 10: Drop `AnimalCategory.defaultMinutes` and `defaultPriceCents`

**Files:**
- Modify: `lib/domain/models/animal_category.dart`
- Modify: `lib/data/repositories/animal_category_repository.dart`
- Modify: `lib/infra/db/tables.dart`
- Auto-generated: `lib/infra/db/app_database.g.dart`
- Modify: `lib/presentation/settings/animal_category_form_sheet.dart`
- Modify: `lib/presentation/settings/species_edit_screen.dart`
- Modify: `test/_helpers/animal_fixtures.dart`
- Modify: `test/domain/animal_category_test.dart`
- Modify: `test/data/animal_category_repository_test.dart`
- Modify: `test/data/species_seeds_test.dart`

These columns/fields were prepared in #5 but never read in prod. They are now redundant with `Prestation.priceCents` / `Prestation.minutes`. Removing them simplifies the catalog UI flow.

- [ ] **Step 1: Update `lib/domain/models/animal_category.dart`**

```dart
class AnimalCategory {
  final int id;
  final int speciesId;
  final String name;
  final DateTime? archivedAt;

  const AnimalCategory({
    required this.id,
    required this.speciesId,
    required this.name,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}
```

- [ ] **Step 2: Update `lib/data/repositories/animal_category_repository.dart`**

Drop the `defaultMinutes` / `defaultPriceCents` parameters from `insert`. Drop the `updateDefaults` method entirely. Drop those fields from the `_toDomain` mapping.

- [ ] **Step 3: Update `lib/infra/db/tables.dart`**

Remove these two lines from `AnimalCategoriesTable` :

```dart
IntColumn get defaultMinutes => integer().nullable()();
IntColumn get defaultPriceCents => integer().nullable()();
```

- [ ] **Step 4: Run drift codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: success.

- [ ] **Step 5: Update UI consumers**

In `lib/presentation/settings/animal_category_form_sheet.dart`, remove the two `TextField`s for default minutes and price. The sheet now only collects the category name.

In `lib/presentation/settings/species_edit_screen.dart`, remove the columns/displays that show category default minutes and price. The screen now only shows category names + archive controls.

- [ ] **Step 6: Update tests and fixtures**

`test/_helpers/animal_fixtures.dart` :

```dart
final petit = await cats.insert(speciesId: mouton, name: 'Petit');
final grand = await cats.insert(speciesId: mouton, name: 'Grand');
final poulain = await cats.insert(speciesId: cheval, name: 'Poulain');
final adulte = await cats.insert(speciesId: cheval, name: 'Adulte');
```

`test/domain/animal_category_test.dart` and `test/data/animal_category_repository_test.dart` : drop assertions on `defaultMinutes` / `defaultPriceCents`. Drop tests that exercised `updateDefaults`.

`test/data/species_seeds_test.dart` : update if it asserted on minutes / price.

- [ ] **Step 7: Run tests**

Run: `flutter test`
Expected: PASS for the touched files. Other failures (use cases, UI) should already be addressed by T7-T9.

- [ ] **Step 8: Commit**

```bash
git add lib/domain/models/animal_category.dart lib/data/repositories/animal_category_repository.dart lib/infra/db/tables.dart lib/infra/db/app_database.g.dart lib/presentation/settings/animal_category_form_sheet.dart lib/presentation/settings/species_edit_screen.dart test/_helpers/animal_fixtures.dart test/domain/animal_category_test.dart test/data/animal_category_repository_test.dart test/data/species_seeds_test.dart
git commit -m "refactor(domain): drop AnimalCategory.defaultMinutes/defaultPriceCents"
```

---

## Task 11: Extend `kSpeciesSeeds` with `defaultPrestationName`

**Files:**
- Modify: `lib/data/seeds/species_seeds.dart`
- Modify: `test/data/species_seeds_test.dart`

- [ ] **Step 1: Write/update the test**

```dart
// test/data/species_seeds_test.dart  (add or update)
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/data/seeds/species_seeds.dart';

void main() {
  test('Mouton categories seed Tonte', () {
    final mouton = kSpeciesSeeds.firstWhere((s) => s.name == 'Mouton');
    expect(mouton.categories.every((c) => c.defaultPrestationName == 'Tonte'),
        isTrue);
  });

  test('Cheval & Bovin seed Parage', () {
    final cheval = kSpeciesSeeds.firstWhere((s) => s.name == 'Cheval');
    expect(cheval.categories.every((c) => c.defaultPrestationName == 'Parage'),
        isTrue);
    final bovin = kSpeciesSeeds.firstWhere((s) => s.name == 'Bovin');
    expect(bovin.categories.every((c) => c.defaultPrestationName == 'Parage'),
        isTrue);
  });

  test('Caprin/Chèvre seeds Onglons', () {
    final caprin = kSpeciesSeeds.firstWhere((s) => s.name == 'Caprin');
    final chevre =
        caprin.categories.firstWhere((c) => c.name == 'Chèvre');
    expect(chevre.defaultPrestationName, 'Onglons');
  });
}
```

- [ ] **Step 2: Verify failure**

Run: `flutter test test/data/species_seeds_test.dart`
Expected: failure (`defaultPrestationName` field doesn't exist).

- [ ] **Step 3: Implement**

```dart
// lib/data/seeds/species_seeds.dart
class SpeciesSeed {
  final String name;
  final List<CategorySeed> categories;
  const SpeciesSeed({required this.name, required this.categories});
}

class CategorySeed {
  final String name;
  final String? defaultPrestationName;
  const CategorySeed({required this.name, this.defaultPrestationName});
}

const kSpeciesSeeds = <SpeciesSeed>[
  SpeciesSeed(name: 'Mouton', categories: [
    CategorySeed(name: 'Petit', defaultPrestationName: 'Tonte'),
    CategorySeed(name: 'Grand', defaultPrestationName: 'Tonte'),
  ]),
  SpeciesSeed(name: 'Cheval', categories: [
    CategorySeed(name: 'Poulain', defaultPrestationName: 'Parage'),
    CategorySeed(name: 'Adulte', defaultPrestationName: 'Parage'),
  ]),
  SpeciesSeed(name: 'Bovin', categories: [
    CategorySeed(name: 'Veau', defaultPrestationName: 'Parage'),
    CategorySeed(name: 'Adulte', defaultPrestationName: 'Parage'),
  ]),
  SpeciesSeed(name: 'Caprin', categories: [
    CategorySeed(name: 'Chèvre', defaultPrestationName: 'Onglons'),
  ]),
];
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/data/species_seeds_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/seeds/species_seeds.dart test/data/species_seeds_test.dart
git commit -m "feat(seeds): tag species seeds with defaultPrestationName"
```

---

## Task 12: Add prestation providers; drop `categoryLookupProvider`

**Files:**
- Modify: `lib/state/providers.dart`

- [ ] **Step 1: Drop `categoryLookupProvider`**

Remove the entire `categoryLookupProvider` definition (lines around 99-115 in current code). Anywhere it was watched (e.g., `optimizedProposalProvider`) drop the watch and the corresponding parameter from the use case call. With T8 done, `BuildOptimizedTourProposal` no longer needs it.

- [ ] **Step 2: Add prestation providers**

Append at a sensible location (near species/category providers) :

```dart
final prestationRepositoryProvider = Provider<PrestationRepository>((ref) {
  return PrestationRepository(ref.watch(appDatabaseProvider));
});

/// Active prestations ordered by id. Used by the catalog screen and the
/// stop picker.
final activePrestationsProvider = FutureProvider<List<Prestation>>((ref) {
  return ref.watch(prestationRepositoryProvider).listActive();
});

/// Archived prestations.
final archivedPrestationsProvider = FutureProvider<List<Prestation>>((ref) {
  return ref.watch(prestationRepositoryProvider).listArchived();
});

/// Active prestations grouped : `categoryId` (or `null` for libres) → list.
/// Convenient for the catalog screen's grouped layout.
final activePrestationsByCategoryProvider =
    FutureProvider<Map<int?, List<Prestation>>>((ref) async {
  final list = await ref.watch(activePrestationsProvider.future);
  final out = <int?, List<Prestation>>{};
  for (final p in list) {
    out.putIfAbsent(p.categoryId, () => []).add(p);
  }
  return out;
});

/// Count of active prestations. Cheap; surfaced in Settings.
final prestationCountActiveProvider = FutureProvider<int>((ref) {
  return ref.watch(prestationRepositoryProvider).countActive();
});
```

Also add the imports `import '../data/repositories/prestation_repository.dart';` and `import '../domain/models/prestation.dart';` at the top.

- [ ] **Step 3: Verify analyse passes**

Run: `flutter analyze lib/state/providers.dart`
Expected: no errors. If `optimizedProposalProvider` had a stale `categoryLookup` reference, it should now be removed (T8 took care of the use case signature).

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: green for the covered files. UI screens still broken — addressed in subsequent tasks.

- [ ] **Step 5: Commit**

```bash
git add lib/state/providers.dart
git commit -m "feat(state): add prestation providers, drop categoryLookupProvider"
```

---

## Task 13: Add catalog routes + Settings entry-point bloc

**Files:**
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/presentation/settings/settings_screen.dart`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`

The screens pushed by these routes (`PrestationCatalogScreen`, `PrestationEditScreen`) are added in T14 / T15 — register the routes here using stub builders that throw (`UnimplementedError('see T14')`) so the build is green. Update them in T14/T15.

- [ ] **Step 1: Add routes in `app_router.dart`**

Find the existing route registration for `/settings/species` and add two siblings for prestations. Stub bodies throw so we know they're wired correctly.

```dart
GoRoute(
  path: '/settings/prestations',
  builder: (context, state) =>
      throw UnimplementedError('PrestationCatalogScreen — T14'),
),
GoRoute(
  path: '/settings/prestations/new',
  builder: (context, state) =>
      throw UnimplementedError('PrestationEditScreen — T15'),
),
GoRoute(
  path: '/settings/prestations/:id',
  builder: (context, state) =>
      throw UnimplementedError('PrestationEditScreen — T15'),
),
```

- [ ] **Step 2: Add Settings entry bloc**

Insert a new card in `settings_screen.dart` directly **below** the existing « Espèces & catégories » card. Use the same `AppSectionCard` pattern.

Skeleton :

```dart
Consumer(builder: (context, ref, _) {
  final count = ref.watch(prestationCountActiveProvider);
  return AppSectionCard(
    title: AppLocalizations.of(context)!.prestationCatalogTitle,
    onTap: () => context.push('/settings/prestations'),
    subtitle: count.when(
      data: (n) => AppLocalizations.of(context)!
          .prestationCatalogCountFmt(n),
      loading: () => '…',
      error: (_, __) => '',
    ),
  );
});
```

- [ ] **Step 3: Add the two l10n keys (FR + EN)**

`lib/l10n/app_fr.arb` :

```json
"prestationCatalogTitle": "Catalogue de prestations",
"@prestationCatalogTitle": {},
"prestationCatalogCountFmt": "{n} prestation(s) active(s)",
"@prestationCatalogCountFmt": {
  "placeholders": {"n": {"type": "int"}}
}
```

`lib/l10n/app_en.arb` :

```json
"prestationCatalogTitle": "Service catalog",
"@prestationCatalogTitle": {},
"prestationCatalogCountFmt": "{n} active service(s)",
"@prestationCatalogCountFmt": {
  "placeholders": {"n": {"type": "int"}}
}
```

(Other l10n keys come in T22.)

- [ ] **Step 4: Run l10n + build**

Run: `flutter pub get && flutter analyze lib/core/routing/app_router.dart lib/presentation/settings/settings_screen.dart`
Expected: no errors.

Run the app manually (`flutter run -d chrome` or any device) and tap the new Settings tile : it should push and crash on the stub. ✓ Wired.

- [ ] **Step 5: Commit**

```bash
git add lib/core/routing/app_router.dart lib/presentation/settings/settings_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(settings): add catalog entry tile + routes (stubs)"
```

---

## Task 14: `PrestationCatalogScreen`

**Files:**
- Create: `lib/presentation/settings/prestation_catalog_screen.dart`
- Modify: `lib/core/routing/app_router.dart` (replace stub builder)
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

Calque le pattern de `species_management_screen.dart`. Sections : « Actives » groupées par espèce + groupe « Libres »; « Archivées » repliable. Bouton CTA bas d'écran « + Ajouter une prestation ».

- [ ] **Step 1: Add l10n keys**

```
prestationCatalogAddCta            = "+ Ajouter une prestation"
prestationCatalogArchivedSection   = "Archivées"
prestationCatalogFreeGroup         = "Libres"
```

EN equivalents : `"+ Add a service"`, `"Archived"`, `"Standalone"`.

- [ ] **Step 2: Implement `PrestationCatalogScreen`**

Skeleton (consult `species_management_screen.dart` for the exact `forui` widget patterns) :

```dart
// lib/presentation/settings/prestation_catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/prestation.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';

class PrestationCatalogScreen extends ConsumerWidget {
  const PrestationCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeAsync = ref.watch(activePrestationsProvider);
    final archivedAsync = ref.watch(archivedPrestationsProvider);
    final speciesByIdAsync = ref.watch(activeSpeciesProvider);
    final allCatsAsync = ref.watch(allCategoriesByIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.prestationCatalogTitle)),
      body: activeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (active) {
          // Group by categoryId; null bucket = "Libres".
          final byCat = <int?, List<Prestation>>{};
          for (final p in active) {
            byCat.putIfAbsent(p.categoryId, () => []).add(p);
          }
          // ... build a list of sections, one per species (using
          //     speciesByIdAsync + allCatsAsync to resolve categoryId →
          //     species), plus a "Libres" section.
          // ... render the archived section in a collapsible.
          return Column(
            // sections
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/settings/prestations/new'),
        label: Text(l10n.prestationCatalogAddCta),
      ),
    );
  }
}
```

The list-item card per prestation shows `name` on line 1 and (if bound) `categoryName · priceFmt · minutesFmt` on line 2 (with `—` for null values). Tap pushes `/settings/prestations/<id>`. A trailing `⋮` menu offers `Modifier` and `Archiver` (or `Désarchiver` in the archived section).

For the menu actions, call into the repository directly via `ref.read(prestationRepositoryProvider).archive(p.id)` then `ref.invalidate(activePrestationsProvider); ref.invalidate(archivedPrestationsProvider); ref.invalidate(prestationCountActiveProvider);`.

- [ ] **Step 3: Wire the route**

In `app_router.dart`, replace the stub for `/settings/prestations` with the real builder :

```dart
GoRoute(
  path: '/settings/prestations',
  builder: (context, state) => const PrestationCatalogScreen(),
),
```

- [ ] **Step 4: Manual smoke test**

Run the app. From Settings → tap "Catalogue de prestations". Expected : empty state on a fresh DB. Tap the FAB → crashes on the T15 stub → that's normal. Add a prestation manually via `dart run build_runner ...` → not required; will be tested end-to-end in T15.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/settings/prestation_catalog_screen.dart lib/core/routing/app_router.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(settings): PrestationCatalogScreen"
```

---

## Task 15: `PrestationEditScreen`

**Files:**
- Create: `lib/presentation/settings/prestation_edit_screen.dart`
- Modify: `lib/core/routing/app_router.dart` (replace 2 stubs)
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

- [ ] **Step 1: Add l10n keys**

```
prestationFormName                 = "Nom"
prestationFormBindToCategory       = "Liée à une catégorie ?"
prestationFormSpecies              = "Espèce"
prestationFormCategory             = "Catégorie"
prestationFormPrice                = "Prix HT (€)"
prestationFormPriceHelper          = "Sera utilisé pour la facturation (#7)"
prestationFormMinutes              = "Durée (min)"
prestationFormMinutesHelper        = "Utilisée pour estimer la durée d'une tournée"
prestationFormSave                 = "Enregistrer"
prestationFormArchive              = "Archiver"
prestationFormUnarchive            = "Désarchiver"
prestationFormCreateTitle          = "Nouvelle prestation"
prestationFormEditTitle            = "Modifier la prestation"
```

EN equivalents (concise, same shape).

- [ ] **Step 2: Implement the screen**

The screen accepts a nullable `int? id`. If null → create mode. Else → load via `ref.watch(prestationRepositoryProvider).listAll()` and find by id, populate.

Form fields :
- `name` — `TextField`, validator non-empty.
- `bindToCategory` — `Switch` initially off (libre) for create, set from existing prestation in edit.
- When ON : show `Espèce` chips (from `activeSpeciesProvider`) → on selection, show `Catégorie` chips (from `activeCategoriesBySpeciesProvider` filtered for the selected species). Selected category id is the field value. When OFF : both selectors are hidden, categoryId is `null`.
- `priceCents` — numeric `TextField` accepting decimal (parse `"12,50"` → `1250` cents). Empty allowed.
- `minutes` — numeric `TextField` integer. Empty allowed.

Save handler :
- Validate name not empty.
- If switch is ON, validate categoryId is set (otherwise show error « Choisissez une catégorie »).
- Call `repo.insert(...)` (create) or `repo.rename` + `updateValues` + `updateBinding` (edit). Invalidate the providers (`activePrestationsProvider`, `archivedPrestationsProvider`, `prestationCountActiveProvider`).
- Pop with `context.pop()`.

Archive button (edit mode only) : call `repo.archive(id)` or `repo.unarchive(id)`, invalidate providers, pop.

- [ ] **Step 3: Wire the routes**

In `app_router.dart` :

```dart
GoRoute(
  path: '/settings/prestations/new',
  builder: (context, state) => const PrestationEditScreen(),
),
GoRoute(
  path: '/settings/prestations/:id',
  builder: (context, state) {
    final id = int.parse(state.pathParameters['id']!);
    return PrestationEditScreen(id: id);
  },
),
```

- [ ] **Step 4: Manual smoke test**

End-to-end : Settings → Catalogue → FAB → fill name "Tonte", switch ON, pick Mouton/Petit, prix 8, min 8, save → returns to catalog with one row. Edit it, change prix to 10, save → updated. Archive it → moves to archived section. Unarchive → back to active.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/settings/prestation_edit_screen.dart lib/core/routing/app_router.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(settings): PrestationEditScreen"
```

---

## Task 16: `PrestationPickerSheet`

**Files:**
- Create: `lib/presentation/tours/prestation_picker_sheet.dart`
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

The picker is a modal sheet that returns a `List<TourStopPrestation>` via `Navigator.pop(result)`. It is consumed by `TourDraftScreen` (T17) and `TourCompletionScreen` (T18, for the "+ ajouter hors plan" picker variant).

- [ ] **Step 1: Add l10n keys**

```
prestationPickerTitleFmt           = "Prestations pour {client}"
prestationPickerSuggested          = "Suggérées"
prestationPickerOther              = "Autres"
prestationPickerEmptyValues        = "Prix/durée non renseignés"
prestationPickerCancel             = "Annuler"
prestationPickerValidate           = "Valider"
```

- [ ] **Step 2: Implement the sheet widget**

```dart
// lib/presentation/tours/prestation_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/animal_count.dart';
import '../../domain/models/prestation.dart';
import '../../domain/models/tour_stop_prestation.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';

class PrestationPickerSheet extends ConsumerStatefulWidget {
  final String clientName;
  final List<AnimalCount> clientAnimals;
  final List<TourStopPrestation> initialSelection;

  const PrestationPickerSheet({
    super.key,
    required this.clientName,
    required this.clientAnimals,
    this.initialSelection = const [],
  });

  static Future<List<TourStopPrestation>?> show(
    BuildContext context, {
    required String clientName,
    required List<AnimalCount> clientAnimals,
    List<TourStopPrestation> initialSelection = const [],
  }) {
    return showModalBottomSheet<List<TourStopPrestation>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PrestationPickerSheet(
        clientName: clientName,
        clientAnimals: clientAnimals,
        initialSelection: initialSelection,
      ),
    );
  }

  @override
  ConsumerState<PrestationPickerSheet> createState() =>
      _PrestationPickerSheetState();
}

class _PrestationPickerSheetState extends ConsumerState<PrestationPickerSheet> {
  // State per prestationId : { selected: bool, qty: int }
  final _selected = <int, bool>{};
  final _qty = <int, int>{};

  @override
  void initState() {
    super.initState();
    for (final s in widget.initialSelection) {
      _selected[s.prestationId] = true;
      _qty[s.prestationId] = s.qty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeAsync = ref.watch(activePrestationsProvider);
    final allCatsAsync = ref.watch(allCategoriesByIdProvider);
    final speciesAsync = ref.watch(activeSpeciesProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: activeAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
              height: 200, child: Center(child: Text('Erreur: $e'))),
          data: (active) {
            // Resolve species for each prestation via the cat lookup.
            // Build the two lists.
            final clientCats = {
              for (final a in widget.clientAnimals)
                if (a.count > 0) a.categoryId,
            };

            final suggested = <Prestation>[];
            final other = <Prestation>[];
            for (final p in active) {
              final cid = p.categoryId;
              if (cid != null && clientCats.contains(cid)) {
                suggested.add(p);
              } else {
                other.add(p);
              }
            }

            // Initial selection / qty for "Suggérées" :
            //   selected by default, qty = clientAnimals[catId].count
            for (final p in suggested) {
              _selected.putIfAbsent(p.id, () => true);
              if (!_qty.containsKey(p.id)) {
                final cnt = widget.clientAnimals
                    .firstWhere((a) => a.categoryId == p.categoryId,
                        orElse: () => const AnimalCount(categoryId: 0, count: 0))
                    .count;
                _qty[p.id] = cnt;
              }
            }

            return _buildBody(
              context: context,
              l10n: l10n,
              suggested: suggested,
              other: other,
              speciesById: {
                for (final s in (speciesAsync.value ?? [])) s.id: s,
              },
              catsById: allCatsAsync.value ?? const {},
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required AppLocalizations l10n,
    required List<Prestation> suggested,
    required List<Prestation> other,
    required Map<int, dynamic> speciesById,
    required Map<int, dynamic> catsById,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.prestationPickerTitleFmt(widget.clientName),
              style: Theme.of(context).textTheme.titleLarge),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (suggested.isNotEmpty)
                _section(l10n.prestationPickerSuggested, suggested,
                    speciesById: speciesById, catsById: catsById),
              if (other.isNotEmpty)
                _section(l10n.prestationPickerOther, other,
                    speciesById: speciesById, catsById: catsById),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n.prestationPickerCancel),
            ),
            FilledButton(
              onPressed: _onValidate,
              child: Text(l10n.prestationPickerValidate),
            ),
          ],
        ),
      ],
    );
  }

  Widget _section(
    String title,
    List<Prestation> list, {
    required Map<int, dynamic> speciesById,
    required Map<int, dynamic> catsById,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        for (final p in list) _row(p, speciesById, catsById),
      ],
    );
  }

  Widget _row(Prestation p, Map<int, dynamic> speciesById,
      Map<int, dynamic> catsById) {
    final cat = p.categoryId == null ? null : catsById[p.categoryId];
    final spec = cat == null ? null : speciesById[cat.speciesId];
    final subtitleParts = <String>[];
    if (cat != null) {
      subtitleParts.add('${spec?.name ?? '?'}/${cat.name}');
    }
    final isSelected = _selected[p.id] ?? false;

    return CheckboxListTile(
      value: isSelected,
      onChanged: (v) => setState(() => _selected[p.id] = v ?? false),
      title: Text(p.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitleParts.join(' · ')),
          if (isSelected)
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Qty'),
              controller: TextEditingController(
                text: '${_qty[p.id] ?? 0}',
              ),
              onChanged: (v) => _qty[p.id] = int.tryParse(v) ?? 0,
            ),
          if (p.priceCents == null && p.minutes == null)
            Text(AppLocalizations.of(context)!.prestationPickerEmptyValues,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _onValidate() async {
    // Build the result list. For each (selected && qty>0) prestation, fetch
    // the actual Prestation + cat + species (lookup) and snapshot.
    final active = ref.read(activePrestationsProvider).value ?? [];
    final cats = ref.read(allCategoriesByIdProvider).value ?? const {};
    final speciesList = ref.read(activeSpeciesProvider).value ?? [];
    final speciesById = {for (final s in speciesList) s.id: s};
    final result = <TourStopPrestation>[];
    for (final p in active) {
      final sel = _selected[p.id] ?? false;
      if (!sel) continue;
      final q = _qty[p.id] ?? 0;
      if (q <= 0) continue;
      final cat = p.categoryId == null ? null : cats[p.categoryId];
      final spec = cat == null ? null : speciesById[cat.speciesId];
      result.add(TourStopPrestation(
        prestationId: p.id,
        qty: q,
        nameSnapshot: p.name,
        priceCentsSnapshot: p.priceCents ?? 0,
        minutesSnapshot: p.minutes ?? 0,
        categoryIdSnapshot: cat?.id,
        categoryNameSnapshot: cat?.name,
        speciesNameSnapshot: spec?.name,
      ));
    }
    if (mounted) Navigator.of(context).pop(result);
  }
}
```

NOTE : the actual visual treatment (forui chips, colors, etc.) follows the codebase convention; the snippet above uses Material widgets for clarity. Adjust to match `manual_history_entry_sheet.dart`'s styling.

- [ ] **Step 3: Manual smoke test**

There's no caller of the sheet yet (T17 wires it). Skip the smoke test for now; it'll be exercised in T17.

Just compile:
Run: `flutter analyze lib/presentation/tours/prestation_picker_sheet.dart`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/tours/prestation_picker_sheet.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(tours): PrestationPickerSheet"
```

---

## Task 17: `TourDraftScreen` integration

**Files:**
- Modify: `lib/presentation/tours/tour_draft_screen.dart`
- Modify: `lib/state/tour_draft_controller.dart` (already touched in T8 for state — finalize the picker integration)
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

The draft screen is where the user composes a tour. After T8, `tour_draft_controller` carries `prestationsByClientId`. This task wires the UI to the picker and to the new `TourDraftResult` fields (revenue, net).

- [ ] **Step 1: Add l10n keys**

```
tourDraftStopNoPrestation          = "Aucune prestation"
tourDraftStopNPrestationsFmt       = "{n} prestation(s) · {minutes} min · {amount}"
tourDraftSummaryRevenue            = "Revenu : {amount}"
tourDraftSummaryNet                = "Net (indicatif) : {amount}"
```

- [ ] **Step 2: Per-stop tile : tap → open picker**

In the section where stops are rendered (find the existing per-stop tile rendering in `tour_draft_screen.dart`), make the tile tappable :

```dart
onTap: () async {
  final client = clientById[stop.clientId];
  if (client == null) return;
  final current = ref.read(tourDraftControllerProvider).prestationsByClientId[stop.clientId] ?? const [];
  final result = await PrestationPickerSheet.show(
    context,
    clientName: client.name,
    clientAnimals: client.animals,
    initialSelection: current,
  );
  if (result != null) {
    ref.read(tourDraftControllerProvider.notifier)
        .setPrestationsForClient(client.id, result);
  }
},
```

The tile's subtitle line shows :
- When prestations exist : `tourDraftStopNPrestationsFmt(n: list.length, minutes: ..., amount: ...)`
- Otherwise : warning icon + `tourDraftStopNoPrestation`.

- [ ] **Step 3: Update the bottom summary**

Render two new lines (« Revenu » and « Net indicatif ») below the existing « Frais déplac. » line. Both are conditionally shown only if `totalRevenueCents > 0`.

- [ ] **Step 4: Manual smoke test**

End-to-end :
1. Create a client with 12 Petit + 4 Grand (Mouton). Set isWaiting = true. (UI flow already exists.)
2. Create prestations « Tonte » bound to Petit (8€/8min) and to Grand (12€/15min).
3. Start a new tour, pick the client, validate.
4. On the draft screen, tap the stop → picker opens with two suggestions cochées (qty 12 et 4 pré-remplies). Validate.
5. The summary shows : Intervention `~ 8×12 + 15×4 = 156 min`, Revenu `12×8 + 4×12 = 144€`.
6. Confirm the tour. Tour detail screen opens — shows the planned prestations.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/tours/tour_draft_screen.dart lib/state/tour_draft_controller.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(tours): per-stop picker + revenue/net in draft screen"
```

---

## Task 18: `TourCompletionScreen` refonte

**Files:**
- Modify: `lib/presentation/tours/tour_completion_screen.dart`
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

- [ ] **Step 1: Add l10n keys**

```
tourCompletionAddOffPlan           = "+ Ajouter une prestation hors plan"
tourCompletionRevenueRealized      = "Revenu réalisé"
tourCompletionInterventionReal     = "Intervention réelle"
```

- [ ] **Step 2: Replace the per-stop animal editor with a prestation editor**

For each stop, render a card. The list of editable rows is initialized from `stop.plannedPrestations`. Each row :
- Checkbox (initially checked).
- Read-only label : prestation name + (if bound) `species/category` snapshot.
- Numeric `TextField` for qty (initial = planned qty). On change, update local state.

Below the list : a button « + Ajouter une prestation hors plan ». On tap, open a secondary picker that shows **all active prestations not currently in this stop's editor** (grouped by species + libres). Selecting one adds a row with qty `1` (user adjusts).

- [ ] **Step 3: Build the actuals on save**

When the user taps the screen's save button (likely "Confirmer" or "Valider la tournée"), build a `Map<int, ({List<TourStopPrestation> actuals, String? note})>` keyed by `stop.id`. For each row that's checked and `qty > 0`, snapshot it (re-read from `activePrestationsProvider` to get the **current** name/price/minutes — this is intentional, the snapshot can differ from planned if the prestation was edited between draft and bilan).

For unchecked rows or rows with qty = 0, skip them.

Call `tourRepository.markCompleted(tourId, actualsMap)`.

- [ ] **Step 4: Update the totals display**

Top-of-screen summary (if not already present) :
- Intervention réelle (sum of `qty × minutesSnapshot` across all stops' actuals)
- Revenu réalisé (sum of `qty × priceCentsSnapshot`)
- Frais déplacement (read from `tour.totalTravelFeeCents`, NOT recomputed)
- Net indicatif (revenue − fees)

- [ ] **Step 5: Manual smoke test**

Continue the flow from T17:
6. From the tour detail, tap "Compléter".
7. The completion screen shows the two prestations cochées with planned qty.
8. Adjust « Tonte Grand » qty 4 → 3. Confirm.
9. The tour is now status: completed. The client's `animals` reflects the MAX rule (12 Petit, 3 Grand).

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/tours/tour_completion_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(tours): TourCompletionScreen refonte for prestations"
```

---

## Task 19: `ManualHistoryEntrySheet` refonte

**Files:**
- Modify: `lib/presentation/clients/manual_history_entry_sheet.dart`
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

The manual history entry sheet replaces its `AnimalCountsEditor` with a prestation list in the same shape as the bilan editor. It is opened with a `clientId` (so we know `client.animals` for the « + Ajouter une prestation » picker initial qty).

- [ ] **Step 1: Implement the new editor**

Mirror the bilan editor :
- Empty initial state for a fresh entry.
- A button « + Ajouter une prestation » opens the same picker as in T16, scoped to all active prestations (no « Suggérées » / « Autres » distinction is necessary here — the user is recording past activity, the suggestions would be misleading; show one flat list grouped by species + libres).

When saving, build a `List<TourStopPrestation>` (snapshots taken at save time) and persist via `manualHistoryRepository.insert(...)` or `update(...)`. Note the parameter is now `prestations` (renamed in T9).

After save, call `clientRepository.applyManualEntryToClient` (for create) or `recomputeClientFromHistory` (for edit/delete).

- [ ] **Step 2: Manual smoke test**

On a client's history screen, tap « + Ajouter une intervention ». Pick a date in the past. Add « Tonte Petit × 8 ». Save. Verify :
- Entry appears in history.
- Client's `animals` is updated if the entry's date is more recent than `lastInterventionDate`.
- Edit the entry → change qty to 10 → save → MAX rule applies.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/clients/manual_history_entry_sheet.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(clients): ManualHistoryEntrySheet uses prestations"
```

---

## Task 20: `ClientHistoryScreen` display

**Files:**
- Modify: `lib/presentation/clients/client_history_screen.dart`
- Modify: `lib/l10n/app_fr.arb` + `app_en.arb`

The history line currently shows `AnimalCountsBadges` derived from `Intervention.animals`. We replace with prestation-based display.

- [ ] **Step 1: Add l10n keys**

```
clientHistoryPrestationCountFmt    = "{n} prestation(s) · {amount} · {duration}"
clientHistoryAndOthersFmt          = "… et {n} autre(s)"
```

- [ ] **Step 2: Update the row builder**

Each row now shows :
- Date (top, prominent).
- Summary line : `Intervention.prestations.length prestations · totalRevenueCents formatted · totalMinutes formatted`.
- Detail line : up to 3 prestations of form `{nameSnapshot} {categoryNameSnapshot ?? '(libre)'} × {qty}` joined by ` · `. If more than 3, append « … et N autres ».

Tap behaviour unchanged : tour → pushes tour detail; manual → opens edit sheet.

- [ ] **Step 3: Manual smoke test**

After T18 + T19, navigate to a client with both a completed tour stop and a manual entry → both rows display in the new format.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/clients/client_history_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb
git commit -m "feat(clients): client history shows prestations"
```

---

## Task 21: Wire prestation seeding to onboarding + species_management restore-template

**Files:**
- Modify: `lib/presentation/onboarding/onboarding_screen.dart`
- Modify: `lib/presentation/settings/species_management_screen.dart`

When the user activates a species (onboarding step 2 OR « Restaurer un template »), insert prestations alongside categories.

- [ ] **Step 1: Onboarding step 2 — confirm transaction**

Find the existing transaction in `onboarding_screen.dart` that inserts SpeciesRow + AnimalCategoryRow. Right after each category insert, if its seed has `defaultPrestationName != null`, also insert a prestation :

```dart
for (final speciesSeed in selectedSpeciesSeeds) {
  final sId = await speciesRepo.insert(name: speciesSeed.name);
  for (final catSeed in speciesSeed.categories) {
    final catId = await categoryRepo.insert(speciesId: sId, name: catSeed.name);
    if (catSeed.defaultPrestationName != null) {
      await prestationRepo.insert(
        name: catSeed.defaultPrestationName!,
        priceCents: null,
        minutes: null,
        categoryId: catId,
      );
    }
  }
}
```

For **custom species** (created via the `CustomSpeciesFormSheet`), the spec dictates **no seeding** — just insert the species and categories as today.

- [ ] **Step 2: SpeciesManagementScreen — Restaurer un template**

Same logic in the existing « Restaurer un template » handler.

- [ ] **Step 3: Manual smoke test**

Wipe the DB (drop+recreate happens automatically due to T6's schema bump on first launch — or use the existing « Reset » action in Settings if any). Onboard with all species → after onboarding, open Settings → Catalogue : the seven prestations should be present (Tonte Petit, Tonte Grand, Parage Poulain, Parage Adulte, Parage Veau, Parage Adulte, Onglons Chèvre).

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/onboarding/onboarding_screen.dart lib/presentation/settings/species_management_screen.dart
git commit -m "feat(seeds): seed default prestations on species activation"
```

---

## Task 22: Finalize l10n keys

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`
- Auto-generated: `lib/l10n/app_localizations*.dart`

Keys were added incrementally in T13/T14/T15/T16/T17/T18/T20. This task is a **sweep** to verify FR + EN sync, ensure correct ICU placeholder syntax, and regenerate.

- [ ] **Step 1: Audit FR keys present in T13-T20**

Open `lib/l10n/app_fr.arb` and verify the following keys exist :

```
prestationCatalogTitle, prestationCatalogCountFmt, prestationCatalogAddCta,
prestationCatalogArchivedSection, prestationCatalogFreeGroup,
prestationFormName, prestationFormBindToCategory, prestationFormSpecies,
prestationFormCategory, prestationFormPrice, prestationFormPriceHelper,
prestationFormMinutes, prestationFormMinutesHelper, prestationFormSave,
prestationFormArchive, prestationFormUnarchive,
prestationFormCreateTitle, prestationFormEditTitle,
prestationPickerTitleFmt, prestationPickerSuggested, prestationPickerOther,
prestationPickerEmptyValues, prestationPickerCancel, prestationPickerValidate,
tourDraftStopNoPrestation, tourDraftStopNPrestationsFmt,
tourDraftSummaryRevenue, tourDraftSummaryNet,
tourCompletionAddOffPlan, tourCompletionRevenueRealized,
tourCompletionInterventionReal,
clientHistoryPrestationCountFmt, clientHistoryAndOthersFmt
```

Add any missing.

- [ ] **Step 2: Verify EN parity**

Each FR key must have an EN counterpart. Edit `app_en.arb` to fill any gaps.

- [ ] **Step 3: Regenerate**

Run: `flutter gen-l10n`
Expected: `lib/l10n/app_localizations_fr.dart` and `app_localizations_en.dart` regenerate without errors.

- [ ] **Step 4: Verify the app compiles**

Run: `flutter analyze`
Expected: zero errors.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart
git commit -m "i18n: finalize prestation catalog keys"
```

---

## Task 23: Cleanup — delete `TourStopAnimal` + dead column refs + `json_export_service`

**Files:**
- Delete: `lib/domain/models/tour_stop_animal.dart`
- Delete: `lib/infra/db/tour_stop_animal_list_converter.dart`
- Delete: `test/domain/tour_stop_animal_test.dart`
- Delete: `test/infra/db/tour_stop_animal_list_converter_test.dart`
- Modify: `lib/core/animal_counts_normalizer.dart` (drop `normalizeTourStopAnimals`)
- Modify: `test/core/animal_counts_normalizer_test.dart` (drop tests on the dropped helper)
- Modify: `lib/infra/db/tables.dart` (drop dead columns)
- Auto-generated: `lib/infra/db/app_database.g.dart`
- Modify: `lib/infra/services/json_export_service.dart` (handle prestations)
- Modify: `lib/presentation/widgets/animal_counts_badges.dart` (only if it imports TourStopAnimal — usually it operates on AnimalCount which stays)

- [ ] **Step 1: Drop dead columns from `tables.dart`**

Remove from `TourStopsTable` :

```dart
TextColumn get plannedAnimals => text()
    .map(const TourStopAnimalListConverter())
    .withDefault(const Constant('[]'))();
TextColumn get actualAnimals => text()
    .map(const TourStopAnimalListConverter())
    .nullable()();
```

Remove the `import 'tour_stop_animal_list_converter.dart';` import.

Remove from `ManualHistoryEntriesTable` :

```dart
TextColumn get animals => text()
    .map(const TourStopAnimalListConverter())
    .withDefault(const Constant('[]'))();
```

- [ ] **Step 2: Run drift codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: success. The dead columns are gone from `app_database.g.dart`.

- [ ] **Step 3: Verify no remaining consumer**

Run: `grep -rn "plannedAnimals\|actualAnimals\|TourStopAnimal\|normalizeTourStopAnimals" lib test`
Expected: only references in the files about to be deleted (or `animal_counts_normalizer.dart` for the helper we're dropping).

- [ ] **Step 4: Drop `normalizeTourStopAnimals`**

In `lib/core/animal_counts_normalizer.dart`, delete the `normalizeTourStopAnimals` function and the import of `tour_stop_animal.dart`. Keep `normalizeAnimalCounts` (still used).

In `test/core/animal_counts_normalizer_test.dart`, delete the test cases that exercised `normalizeTourStopAnimals`.

- [ ] **Step 5: Update `json_export_service.dart`**

Find the JSON export logic. Replace `tourStop.planned` / `tourStop.actual` references with `plannedPrestations` / `actualPrestations`. Same for manual entries (`animals` → `prestations`). The exported JSON's keys can be renamed accordingly.

- [ ] **Step 6: Delete the dead model + converter files**

```bash
rm lib/domain/models/tour_stop_animal.dart
rm lib/infra/db/tour_stop_animal_list_converter.dart
rm test/domain/tour_stop_animal_test.dart
rm test/infra/db/tour_stop_animal_list_converter_test.dart
```

- [ ] **Step 7: Run full analyse + test**

Run: `flutter analyze`
Expected: zero errors.

Run: `flutter test`
Expected: all green.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore: drop TourStopAnimal and dead column refs"
```

---

## Task 24: Final integration check + lint sweep + TODO update

**Files:**
- Modify: `TODO.md`

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: all green. Note the count (target ~165 tests).

- [ ] **Step 2: Manual smoke test — full flow**

Test the entire feature loop on a real device or emulator :

1. Wipe app data (or fresh install) → onboarding starts.
2. Set address; choose Mouton + Caprin; finish onboarding.
3. Settings → Catalogue : verify three prestations seeded (Tonte Petit, Tonte Grand, Onglons Chèvre).
4. Edit each prestation → set price + minutes (e.g., Tonte 8€/8min, Onglons 5€/3min).
5. Add a libre prestation : « Visite » 20€/0min.
6. Create 2 clients : one with 12 Petit + 4 Grand (Mouton), one with 6 Chèvre (Caprin). Mark both `isWaiting`.
7. Start a tour → pick both clients → reach the draft screen.
8. Tap stop 1 (the Mouton client) : picker opens, Tonte Petit cochée qty 12, Tonte Grand cochée qty 4. « Visite » non cochée. Cocher « Visite » qty 1. Validate.
9. Tap stop 2 (Caprin client) : Onglons coché qty 6. Validate.
10. Summary line shows revenu = `12×8 + 4×12 + 1×20 + 6×5 = 194€`. Confirm.
11. From tours list → tap the new tour → detail shows planned prestations, totals.
12. Tap « Compléter ». Adjust « Tonte Grand » qty 4 → 3. Save.
13. Open the Mouton client's history → see the intervention with `5 prestations · 191€ · ...` + detail line.
14. Open the Mouton client's detail → animals = `[12 Petit, 3 Grand]` (MAX rule applied).
15. Add a manual history entry on Mouton, date 1 month ago, qty 12 Petit + 4 Grand → entry appears in history. Client's animals UNCHANGED (older date).
16. Edit the manual entry → change date to today + 1 day → save → client's animals re-derive.
17. Archive the « Visite » prestation → it disappears from the catalog active list and from new pickers.
18. Open the existing tour's detail → « Visite » still shown (snapshots preserved). ✓

- [ ] **Step 3: Update TODO.md**

Move #6 from « À venir » to « Livrées ». Add the spec / plan paths and a short « Ce qui a été livré » subsection mirroring the existing entries' format.

- [ ] **Step 4: Run final lint pass**

Run: `flutter analyze --fatal-infos --fatal-warnings`
Expected: zero issues.

- [ ] **Step 5: Commit**

```bash
git add TODO.md
git commit -m "docs(todo): mark #6 prestation catalog as delivered"
```

- [ ] **Step 6: Verify branch is ready to merge**

Run: `git log --oneline main..HEAD | wc -l`
Expected: ~24 commits.

The feature is complete. Open a PR for human review or merge directly per workflow.

---

## Self-review checklist

Run this checklist after the plan is written, before handing off to execution :

- **Spec coverage** : every section of `2026-05-01-prestation-catalog-design.md` has a corresponding task.
  - Modèle de domaine → T1, T2, T7, T9
  - Schema → T6, T10, T23
  - Catalog UI → T13, T14, T15
  - Picker → T16, T17
  - Tour draft + calculs → T8, T17
  - Bilan → T18
  - Saisie manuelle → T19
  - Historique → T20
  - Seeding → T11, T21
  - l10n → T13-T22
  - Reset & migration → T6, T23
  - Tests → distributed, with summary in T24
  - Acceptance criteria → covered by T24's manual smoke test
- **No placeholders** : every step has actual code or an exact instruction. UI screens (T14/T15/T17/T18/T19/T20) intentionally show **shape + interactions** rather than pixel-perfect widget trees, because matching the codebase's `forui` styling is judgment work — but the data flow and providers are exact.
- **Type consistency** : `TourStopPrestation` field names (`prestationId`, `qty`, `nameSnapshot`, `priceCentsSnapshot`, `minutesSnapshot`, `categoryIdSnapshot?`, `categoryNameSnapshot?`, `speciesNameSnapshot?`) match across all tasks. `Prestation` fields (`id`, `name`, `priceCents?`, `minutes?`, `categoryId?`, `archivedAt?`) are consistent. The repo method names (`insert`, `rename`, `updateValues`, `updateBinding`, `archive`, `unarchive`, `listActive`, `listArchived`, `listAll`, `listByCategory`, `countActive`) are referenced consistently in T6's tests and T15's edit screen.
