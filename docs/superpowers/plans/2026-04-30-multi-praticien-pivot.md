# Multi-praticien pivot — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pivot the app from sheep-shearing-only to a generic itinerant animal practitioner tool. Add a `Species → AnimalCategory` hierarchy with full CRUD, replace `sheepCountSmall/Large` with per-category JSON counts (snapshotted in tour stops and manual history entries), neutralize vocabulary (tonte → intervention), introduce a 2-step onboarding wizard with custom species + customizable app avatar, and reset the schema cleanly (v8 → v9, no data migration).

**Architecture:** Bottom-up. Build the new domain types, normalizers and JSON converters first. Bump the schema with a drop-and-recreate migration. Walk up through repositories, use cases, providers, l10n, shared widgets, then screens. Tests are written TDD-style for domain logic (normalizers, converters, repositories, use cases). Widget tests are kept minimal since the project's widget-test base is essentially empty.

**Tech Stack:** Flutter 3.41, Drift 2.32, Riverpod 3, go_router, ForUI, flutter_localizations (ARB).

**Spec:** `docs/superpowers/specs/2026-04-30-multi-praticien-pivot-design.md`

**Branch:** Continue on `spec/multi-praticien-pivot` for the plan; switch to `feat/multi-praticien-pivot` for implementation (instruction included in Task 1).

**Out-of-scope reminder (do NOT implement):** rebrand of `Coup'Laine`, post-onboarding tutorial for filling minutes/prices, species filter in tour pickers, custom avatar uploads, exposing prices in tour-related UI beyond the category form.

---

## Task 1 — Branch and pre-flight

**Files:** none.

- [ ] **Step 1: Create the implementation branch**

```bash
git checkout -b feat/multi-praticien-pivot spec/multi-praticien-pivot
```

- [ ] **Step 2: Verify clean working tree and a green baseline**

```bash
git status
flutter pub get
flutter analyze
flutter test
```

Expected: working tree clean, analyze with no errors, all tests green (the spec branch only added a markdown file).

- [ ] **Step 3: No commit at this stage** (just verification).

---

## Task 2 — Pure domain types: `AnimalCount`, `TourStopAnimal`

**Files:**
- Create: `lib/domain/models/animal_count.dart`
- Create: `lib/domain/models/tour_stop_animal.dart`
- Create: `test/domain/animal_count_test.dart`
- Create: `test/domain/tour_stop_animal_test.dart`

- [ ] **Step 1: Write failing tests for `AnimalCount`**

```dart
// test/domain/animal_count_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/animal_count.dart';

void main() {
  test('AnimalCount stores categoryId and count', () {
    const a = AnimalCount(categoryId: 7, count: 12);
    expect(a.categoryId, 7);
    expect(a.count, 12);
  });

  test('two AnimalCount with the same fields are equal', () {
    expect(
      const AnimalCount(categoryId: 1, count: 5),
      const AnimalCount(categoryId: 1, count: 5),
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/animal_count_test.dart`
Expected: FAIL — `animal_count.dart` does not exist.

- [ ] **Step 3: Implement `AnimalCount`**

```dart
// lib/domain/models/animal_count.dart
import 'package:meta/meta.dart';

@immutable
class AnimalCount {
  final int categoryId;
  final int count;
  const AnimalCount({required this.categoryId, required this.count});

  @override
  bool operator ==(Object other) =>
      other is AnimalCount &&
      other.categoryId == categoryId &&
      other.count == count;

  @override
  int get hashCode => Object.hash(categoryId, count);
}
```

- [ ] **Step 4: Write failing tests for `TourStopAnimal`**

```dart
// test/domain/tour_stop_animal_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/tour_stop_animal.dart';

void main() {
  test('TourStopAnimal carries snapshots', () {
    const a = TourStopAnimal(
      categoryId: 3,
      count: 5,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
      minutesSnapshot: 8,
    );
    expect(a.categoryId, 3);
    expect(a.count, 5);
    expect(a.categoryNameSnapshot, 'Petit');
    expect(a.speciesNameSnapshot, 'Mouton');
    expect(a.minutesSnapshot, 8);
  });

  test('TourStopAnimal equality compares all fields', () {
    const a = TourStopAnimal(
      categoryId: 3,
      count: 5,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
      minutesSnapshot: 8,
    );
    const b = TourStopAnimal(
      categoryId: 3,
      count: 5,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
      minutesSnapshot: 8,
    );
    expect(a, b);
  });
}
```

- [ ] **Step 5: Run the tests to verify they fail**

Run: `flutter test test/domain/tour_stop_animal_test.dart`
Expected: FAIL — file missing.

- [ ] **Step 6: Implement `TourStopAnimal`**

```dart
// lib/domain/models/tour_stop_animal.dart
import 'package:meta/meta.dart';

@immutable
class TourStopAnimal {
  final int categoryId;
  final int count;
  final String categoryNameSnapshot;
  final String speciesNameSnapshot;
  final int minutesSnapshot;

  const TourStopAnimal({
    required this.categoryId,
    required this.count,
    required this.categoryNameSnapshot,
    required this.speciesNameSnapshot,
    required this.minutesSnapshot,
  });

  @override
  bool operator ==(Object other) =>
      other is TourStopAnimal &&
      other.categoryId == categoryId &&
      other.count == count &&
      other.categoryNameSnapshot == categoryNameSnapshot &&
      other.speciesNameSnapshot == speciesNameSnapshot &&
      other.minutesSnapshot == minutesSnapshot;

  @override
  int get hashCode => Object.hash(
        categoryId,
        count,
        categoryNameSnapshot,
        speciesNameSnapshot,
        minutesSnapshot,
      );
}
```

- [ ] **Step 7: Run the tests, expect green**

Run: `flutter test test/domain/animal_count_test.dart test/domain/tour_stop_animal_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/domain/models/animal_count.dart lib/domain/models/tour_stop_animal.dart \
        test/domain/animal_count_test.dart test/domain/tour_stop_animal_test.dart
git commit -m "feat(domain): add AnimalCount and TourStopAnimal value types"
```

---

## Task 3 — Pure domain types: `Species`, `AnimalCategory`

**Files:**
- Create: `lib/domain/models/species.dart`
- Create: `lib/domain/models/animal_category.dart`
- Create: `test/domain/species_test.dart`
- Create: `test/domain/animal_category_test.dart`

- [ ] **Step 1: Write failing tests for `Species`**

```dart
// test/domain/species_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/species.dart';

void main() {
  test('Species defaults: archivedAt and iconKey are null', () {
    const s = Species(id: 1, name: 'Mouton');
    expect(s.archivedAt, isNull);
    expect(s.iconKey, isNull);
    expect(s.isArchived, isFalse);
  });

  test('Species.isArchived is true when archivedAt is set', () {
    final s = Species(id: 1, name: 'Mouton', archivedAt: DateTime(2026));
    expect(s.isArchived, isTrue);
  });
}
```

- [ ] **Step 2: Run tests, expect FAIL** (`flutter test test/domain/species_test.dart`)

- [ ] **Step 3: Implement `Species`**

```dart
// lib/domain/models/species.dart
import 'package:meta/meta.dart';

@immutable
class Species {
  final int id;
  final String name;
  final String? iconKey;
  final DateTime? archivedAt;

  const Species({
    required this.id,
    required this.name,
    this.iconKey,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}
```

- [ ] **Step 4: Write failing tests for `AnimalCategory`**

```dart
// test/domain/animal_category_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/animal_category.dart';

void main() {
  test('defaults: minutes/price/archivedAt are null', () {
    const c = AnimalCategory(id: 1, speciesId: 1, name: 'Petit');
    expect(c.defaultMinutes, isNull);
    expect(c.defaultPriceCents, isNull);
    expect(c.archivedAt, isNull);
    expect(c.isArchived, isFalse);
  });

  test('isArchived true when archivedAt set', () {
    final c = AnimalCategory(
      id: 1,
      speciesId: 1,
      name: 'Petit',
      archivedAt: DateTime(2026),
    );
    expect(c.isArchived, isTrue);
  });
}
```

- [ ] **Step 5: Run tests, expect FAIL.**

- [ ] **Step 6: Implement `AnimalCategory`**

```dart
// lib/domain/models/animal_category.dart
import 'package:meta/meta.dart';

@immutable
class AnimalCategory {
  final int id;
  final int speciesId;
  final String name;
  final int? defaultMinutes;
  final int? defaultPriceCents;
  final DateTime? archivedAt;

  const AnimalCategory({
    required this.id,
    required this.speciesId,
    required this.name,
    this.defaultMinutes,
    this.defaultPriceCents,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}
```

- [ ] **Step 7: Run all four test files, expect PASS.**

```bash
flutter test test/domain/species_test.dart test/domain/animal_category_test.dart
```

- [ ] **Step 8: Commit**

```bash
git add lib/domain/models/species.dart lib/domain/models/animal_category.dart \
        test/domain/species_test.dart test/domain/animal_category_test.dart
git commit -m "feat(domain): add Species and AnimalCategory value types"
```

---

## Task 4 — Animal counts normalizers (pure functions)

**Files:**
- Create: `lib/core/animal_counts_normalizer.dart`
- Create: `test/core/animal_counts_normalizer_test.dart`

The normalizer enforces canonical form on every write: drop entries with `count <= 0`, dedup by `categoryId` (sum the counts of duplicates), sort stable by `categoryId`. Two functions: one for `AnimalCount`, one for `TourStopAnimal` (snapshots are kept from the **first** occurrence on dedup — write order wins).

- [ ] **Step 1: Write failing tests**

```dart
// test/core/animal_counts_normalizer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/animal_counts_normalizer.dart';
import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/tour_stop_animal.dart';

void main() {
  group('normalizeAnimalCounts', () {
    test('drops entries with count <= 0', () {
      final out = normalizeAnimalCounts(const [
        AnimalCount(categoryId: 1, count: 5),
        AnimalCount(categoryId: 2, count: 0),
        AnimalCount(categoryId: 3, count: -2),
      ]);
      expect(out, const [AnimalCount(categoryId: 1, count: 5)]);
    });

    test('dedups by categoryId (sums counts) and sorts by categoryId', () {
      final out = normalizeAnimalCounts(const [
        AnimalCount(categoryId: 3, count: 1),
        AnimalCount(categoryId: 1, count: 4),
        AnimalCount(categoryId: 3, count: 2),
      ]);
      expect(out, const [
        AnimalCount(categoryId: 1, count: 4),
        AnimalCount(categoryId: 3, count: 3),
      ]);
    });

    test('returns empty list when input is empty', () {
      expect(normalizeAnimalCounts(const []), isEmpty);
    });
  });

  group('normalizeTourStopAnimals', () {
    test('keeps first occurrence snapshot when deduping; sums counts', () {
      final out = normalizeTourStopAnimals(const [
        TourStopAnimal(
          categoryId: 1,
          count: 2,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
        TourStopAnimal(
          categoryId: 1,
          count: 3,
          categoryNameSnapshot: 'Petit (renommé)',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 9,
        ),
      ]);
      expect(out, const [
        TourStopAnimal(
          categoryId: 1,
          count: 5,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
      ]);
    });

    test('drops zero / negative counts and sorts by categoryId', () {
      final out = normalizeTourStopAnimals(const [
        TourStopAnimal(
          categoryId: 5,
          count: 1,
          categoryNameSnapshot: 'Adulte',
          speciesNameSnapshot: 'Cheval',
          minutesSnapshot: 45,
        ),
        TourStopAnimal(
          categoryId: 2,
          count: 0,
          categoryNameSnapshot: 'Grand',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 25,
        ),
        TourStopAnimal(
          categoryId: 1,
          count: 3,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
      ]);
      expect(out.map((e) => e.categoryId), [1, 5]);
    });
  });
}
```

- [ ] **Step 2: Run tests, expect FAIL** (file does not exist).

- [ ] **Step 3: Implement the normalizers**

```dart
// lib/core/animal_counts_normalizer.dart
import '../domain/models/animal_count.dart';
import '../domain/models/tour_stop_animal.dart';

/// Canonicalizes a list of [AnimalCount] before persistence:
///   - drops entries with `count <= 0`,
///   - dedups by `categoryId` (sums counts of duplicates),
///   - sorts by `categoryId` ascending (stable for equal keys).
List<AnimalCount> normalizeAnimalCounts(List<AnimalCount> input) {
  final byCategory = <int, int>{};
  for (final a in input) {
    if (a.count <= 0) continue;
    byCategory[a.categoryId] = (byCategory[a.categoryId] ?? 0) + a.count;
  }
  final ids = byCategory.keys.toList()..sort();
  return [
    for (final id in ids) AnimalCount(categoryId: id, count: byCategory[id]!),
  ];
}

/// Canonicalizes a list of [TourStopAnimal]:
///   - drops `count <= 0`,
///   - dedups by `categoryId` keeping the **first** snapshot encountered,
///   - sums counts of duplicates,
///   - sorts by `categoryId` ascending.
List<TourStopAnimal> normalizeTourStopAnimals(List<TourStopAnimal> input) {
  final firstSnapshot = <int, TourStopAnimal>{};
  final summedCount = <int, int>{};
  for (final a in input) {
    if (a.count <= 0) continue;
    firstSnapshot.putIfAbsent(a.categoryId, () => a);
    summedCount[a.categoryId] = (summedCount[a.categoryId] ?? 0) + a.count;
  }
  final ids = summedCount.keys.toList()..sort();
  return [
    for (final id in ids)
      TourStopAnimal(
        categoryId: id,
        count: summedCount[id]!,
        categoryNameSnapshot: firstSnapshot[id]!.categoryNameSnapshot,
        speciesNameSnapshot: firstSnapshot[id]!.speciesNameSnapshot,
        minutesSnapshot: firstSnapshot[id]!.minutesSnapshot,
      ),
  ];
}
```

- [ ] **Step 4: Run tests, expect PASS.**

- [ ] **Step 5: Commit**

```bash
git add lib/core/animal_counts_normalizer.dart test/core/animal_counts_normalizer_test.dart
git commit -m "feat(core): add animal counts normalizers"
```

---

## Task 5 — JSON converters: `AnimalCountListConverter`, `TourStopAnimalListConverter`

**Files:**
- Create: `lib/infra/db/animal_count_list_converter.dart`
- Create: `lib/infra/db/tour_stop_animal_list_converter.dart`
- Create: `test/infra/db/animal_count_list_converter_test.dart`
- Create: `test/infra/db/tour_stop_animal_list_converter_test.dart`

Mirror the existing `PhoneListConverter` pattern. The converters do NOT normalize — that's the repository's job. They are strict round-trip serializers.

- [ ] **Step 1: Write failing tests for `AnimalCountListConverter`**

```dart
// test/infra/db/animal_count_list_converter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/infra/db/animal_count_list_converter.dart';

void main() {
  const c = AnimalCountListConverter();

  test('empty list round-trips through "[]"', () {
    expect(c.toSql(const []), '[]');
    expect(c.fromSql('[]'), const <AnimalCount>[]);
  });

  test('round-trips a populated list', () {
    final list = const [
      AnimalCount(categoryId: 1, count: 5),
      AnimalCount(categoryId: 4, count: 12),
    ];
    final sql = c.toSql(list);
    expect(c.fromSql(sql), list);
  });
}
```

- [ ] **Step 2: Run, expect FAIL.**

- [ ] **Step 3: Implement `AnimalCountListConverter`**

```dart
// lib/infra/db/animal_count_list_converter.dart
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/animal_count.dart';

class AnimalCountListConverter
    extends TypeConverter<List<AnimalCount>, String> {
  const AnimalCountListConverter();

  @override
  List<AnimalCount> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return [
      for (final raw in decoded)
        AnimalCount(
          categoryId: (raw as Map<String, dynamic>)['categoryId'] as int,
          count: raw['count'] as int,
        ),
    ];
  }

  @override
  String toSql(List<AnimalCount> value) => jsonEncode([
        for (final a in value) {'categoryId': a.categoryId, 'count': a.count},
      ]);
}
```

- [ ] **Step 4: Write failing tests for `TourStopAnimalListConverter`**

```dart
// test/infra/db/tour_stop_animal_list_converter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/domain/models/tour_stop_animal.dart';
import 'package:coup_laine/infra/db/tour_stop_animal_list_converter.dart';

void main() {
  const c = TourStopAnimalListConverter();

  test('empty list round-trips', () {
    expect(c.toSql(const []), '[]');
    expect(c.fromSql('[]'), const <TourStopAnimal>[]);
  });

  test('round-trips with snapshots', () {
    final list = const [
      TourStopAnimal(
        categoryId: 1,
        count: 5,
        categoryNameSnapshot: 'Petit',
        speciesNameSnapshot: 'Mouton',
        minutesSnapshot: 8,
      ),
    ];
    expect(c.fromSql(c.toSql(list)), list);
  });
}
```

- [ ] **Step 5: Run, expect FAIL.**

- [ ] **Step 6: Implement `TourStopAnimalListConverter`**

```dart
// lib/infra/db/tour_stop_animal_list_converter.dart
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/tour_stop_animal.dart';

class TourStopAnimalListConverter
    extends TypeConverter<List<TourStopAnimal>, String> {
  const TourStopAnimalListConverter();

  @override
  List<TourStopAnimal> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return [
      for (final raw in decoded)
        TourStopAnimal(
          categoryId: (raw as Map<String, dynamic>)['categoryId'] as int,
          count: raw['count'] as int,
          categoryNameSnapshot: raw['categoryNameSnapshot'] as String,
          speciesNameSnapshot: raw['speciesNameSnapshot'] as String,
          minutesSnapshot: raw['minutesSnapshot'] as int,
        ),
    ];
  }

  @override
  String toSql(List<TourStopAnimal> value) => jsonEncode([
        for (final a in value)
          {
            'categoryId': a.categoryId,
            'count': a.count,
            'categoryNameSnapshot': a.categoryNameSnapshot,
            'speciesNameSnapshot': a.speciesNameSnapshot,
            'minutesSnapshot': a.minutesSnapshot,
          },
      ]);
}
```

- [ ] **Step 7: Run all converter tests, expect PASS.**

- [ ] **Step 8: Commit**

```bash
git add lib/infra/db/animal_count_list_converter.dart \
        lib/infra/db/tour_stop_animal_list_converter.dart \
        test/infra/db/animal_count_list_converter_test.dart \
        test/infra/db/tour_stop_animal_list_converter_test.dart
git commit -m "feat(infra): add JSON converters for animal counts and tour-stop animals"
```

---

## Task 6 — Avatar icons mapping

**Files:**
- Create: `lib/core/avatar_icons.dart`
- Create: `test/core/avatar_icons_test.dart`

Pure mapping `String? key → IconData`. Six curated keys: `compass`, `map`, `scissors`, `stethoscope`, `hammer`, `heart`. Default: `compass`. Unknown keys also fall back to `compass`.

- [ ] **Step 1: Write failing tests**

```dart
// test/core/avatar_icons_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/core/avatar_icons.dart';
import 'package:forui/forui.dart';

void main() {
  test('default key (null) returns compass icon', () {
    expect(iconForAvatarKey(null), FIcons.compass);
  });

  test('unknown key falls back to compass', () {
    expect(iconForAvatarKey('not-a-real-key'), FIcons.compass);
  });

  test('all six curated keys resolve', () {
    expect(iconForAvatarKey('compass'), FIcons.compass);
    expect(iconForAvatarKey('map'), FIcons.map);
    expect(iconForAvatarKey('scissors'), FIcons.scissors);
    expect(iconForAvatarKey('stethoscope'), FIcons.stethoscope);
    expect(iconForAvatarKey('hammer'), FIcons.hammer);
    expect(iconForAvatarKey('heart'), FIcons.heart);
  });

  test('kAvatarKeys lists all six', () {
    expect(kAvatarKeys, hasLength(6));
    expect(kAvatarKeys.first, 'compass');
  });
}
```

- [ ] **Step 2: Run tests, expect FAIL.**

- [ ] **Step 3: Implement**

```dart
// lib/core/avatar_icons.dart
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

const List<String> kAvatarKeys = [
  'compass',
  'map',
  'scissors',
  'stethoscope',
  'hammer',
  'heart',
];

const String kDefaultAvatarKey = 'compass';

IconData iconForAvatarKey(String? key) {
  switch (key) {
    case 'map':
      return FIcons.map;
    case 'scissors':
      return FIcons.scissors;
    case 'stethoscope':
      return FIcons.stethoscope;
    case 'hammer':
      return FIcons.hammer;
    case 'heart':
      return FIcons.heart;
    case 'compass':
    default:
      return FIcons.compass;
  }
}
```

- [ ] **Step 4: Run tests, expect PASS.**

- [ ] **Step 5: Commit**

```bash
git add lib/core/avatar_icons.dart test/core/avatar_icons_test.dart
git commit -m "feat(core): add avatar icon mapping"
```

---

## Task 7 — Species seeds (constants)

**Files:**
- Create: `lib/data/seeds/species_seeds.dart`
- Create: `test/data/species_seeds_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/data/species_seeds_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/data/seeds/species_seeds.dart';

void main() {
  test('kSpeciesSeeds contains the 4 expected species', () {
    expect(
      kSpeciesSeeds.map((s) => s.name).toList(),
      ['Mouton', 'Cheval', 'Bovin', 'Caprin'],
    );
  });

  test('Mouton has Petit and Grand categories', () {
    final mouton = kSpeciesSeeds.firstWhere((s) => s.name == 'Mouton');
    expect(mouton.categories.map((c) => c.name).toList(), ['Petit', 'Grand']);
  });

  test('Caprin has a single Chèvre category', () {
    final caprin = kSpeciesSeeds.firstWhere((s) => s.name == 'Caprin');
    expect(caprin.categories.map((c) => c.name).toList(), ['Chèvre']);
  });

  test('seeds carry no minutes nor price (filled later by user)', () {
    for (final s in kSpeciesSeeds) {
      for (final c in s.categories) {
        // Implementation-level note: CategorySeed only carries a name.
        expect(c.name, isNotEmpty);
      }
    }
  });
}
```

- [ ] **Step 2: Run, expect FAIL.**

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
  const CategorySeed({required this.name});
}

const kSpeciesSeeds = <SpeciesSeed>[
  SpeciesSeed(name: 'Mouton', categories: [
    CategorySeed(name: 'Petit'),
    CategorySeed(name: 'Grand'),
  ]),
  SpeciesSeed(name: 'Cheval', categories: [
    CategorySeed(name: 'Poulain'),
    CategorySeed(name: 'Adulte'),
  ]),
  SpeciesSeed(name: 'Bovin', categories: [
    CategorySeed(name: 'Veau'),
    CategorySeed(name: 'Adulte'),
  ]),
  SpeciesSeed(name: 'Caprin', categories: [
    CategorySeed(name: 'Chèvre'),
  ]),
];
```

- [ ] **Step 4: Run, expect PASS.**

- [ ] **Step 5: Commit**

```bash
git add lib/data/seeds/species_seeds.dart test/data/species_seeds_test.dart
git commit -m "feat(data): add seeded species and category templates"
```

---

## Task 8 — Schema bump: tables.dart + reset migration

**Files:**
- Modify: `lib/infra/db/tables.dart`
- Modify: `lib/infra/db/app_database.dart`

This is the breaking change. After this task, the project will not compile until repositories and downstream code are updated. That's fine — subsequent tasks fix it incrementally. Tests will be broken too.

- [ ] **Step 1: Replace `tables.dart`**

```dart
// lib/infra/db/tables.dart
import 'package:drift/drift.dart';
import 'animal_count_list_converter.dart';
import 'phone_list_converter.dart';
import 'tour_stop_animal_list_converter.dart';

@DataClassName('SettingsRow')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  IntColumn get id => integer().check(id.equals(1))();
  TextColumn get baseAddressLabel => text()();
  RealColumn get baseLat => real()();
  RealColumn get baseLon => real()();
  IntColumn get defaultRadiusKm => integer().withDefault(const Constant(15))();
  IntColumn get travelFeeEurosPerBracket =>
      integer().withDefault(const Constant(8))();
  IntColumn get bracketKm => integer().withDefault(const Constant(10))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  TextColumn get markerDefaultColor =>
      text().withDefault(const Constant('#9CA3AF'))();
  TextColumn get markerWaitingColor =>
      text().withDefault(const Constant('#EAB308'))();
  TextColumn get markerScheduledColor =>
      text().withDefault(const Constant('#65A30D'))();
  TextColumn get markerDoneColor =>
      text().withDefault(const Constant('#166534'))();
  TextColumn get markerNoAnimalsColor =>
      text().withDefault(const Constant('#1F2937'))();
  TextColumn get markerBannedColor =>
      text().withDefault(const Constant('#B91C1C'))();
  IntColumn get seasonStartedAt => integer().withDefault(const Constant(0))();
  TextColumn get appAvatarKey => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ClientRow')
class ClientsTable extends Table {
  @override
  String get tableName => 'clients';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phones => text()
      .map(const PhoneListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get addressLabel => text()();
  TextColumn get postcode => text()();
  TextColumn get city => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get animals => text()
      .map(const AnimalCountListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get markerColorHex => text().nullable()();
  BoolColumn get isWaiting => boolean().withDefault(const Constant(false))();
  IntColumn get lastShearingDate => integer().nullable()();
  BoolColumn get needsDistanceRecompute =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isBanned => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('DistanceMatrixRow')
class DistanceMatrixTable extends Table {
  @override
  String get tableName => 'distance_matrix';

  IntColumn get fromId => integer()();
  IntColumn get toId => integer()();
  IntColumn get distanceMeters => integer()();
  IntColumn get durationSeconds => integer()();
  IntColumn get computedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {fromId, toId};
}

@DataClassName('SpeciesRow')
class SpeciesTable extends Table {
  @override
  String get tableName => 'species';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get iconKey => text().nullable()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}

@DataClassName('AnimalCategoryRow')
class AnimalCategoriesTable extends Table {
  @override
  String get tableName => 'animal_categories';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get speciesId => integer()
      .references(SpeciesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get defaultMinutes => integer().nullable()();
  IntColumn get defaultPriceCents => integer().nullable()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}

@DataClassName('TourRow')
class ToursTable extends Table {
  @override
  String get tableName => 'tours';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get plannedDate => integer()();
  IntColumn get startTimeMinutes => integer()();
  TextColumn get status => text()();
  IntColumn get totalDistanceMeters => integer()();
  IntColumn get totalDriveSeconds => integer()();
  IntColumn get totalTravelFeeCents => integer()();
  TextColumn get notes => text().nullable()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
}

@DataClassName('TourStopRow')
class TourStopsTable extends Table {
  @override
  String get tableName => 'tour_stops';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get tourId =>
      integer().references(ToursTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get clientId => integer()
      .nullable()
      .references(ClientsTable, #id, onDelete: KeyAction.setNull)();
  TextColumn get clientNameSnapshot => text()();
  IntColumn get orderIndex => integer()();
  IntColumn get estimatedArrivalMinutes => integer()();
  IntColumn get estimatedDepartureMinutes => integer()();
  TextColumn get plannedAnimals => text()
      .map(const TourStopAnimalListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get actualAnimals => text()
      .map(const TourStopAnimalListConverter())
      .nullable()();
  TextColumn get interventionNote => text().nullable()();
  IntColumn get feeShareCents => integer()();
}

@DataClassName('ManualHistoryEntryRow')
class ManualHistoryEntriesTable extends Table {
  @override
  String get tableName => 'manual_history_entries';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get clientId => integer()
      .references(ClientsTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get date => integer()();
  TextColumn get animals => text()
      .map(const TourStopAnimalListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
```

- [ ] **Step 2: Update `app_database.dart`**

Replace the entire file with:

```dart
// lib/infra/db/app_database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'animal_count_list_converter.dart';
import 'phone_list_converter.dart';
import 'tables.dart';
import 'tour_stop_animal_list_converter.dart';

part 'app_database.g.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 9) {
        // Reset complet — pas d'utilisateurs en prod, pas de migration data.
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

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'coup_laine.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
```

- [ ] **Step 3: Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: regenerates `app_database.g.dart`. May produce warnings — ignore as long as the generation completes.

- [ ] **Step 4: Verify codegen sanity** (analyze will fail elsewhere; just check the .g.dart file regenerated)

```bash
git status -- lib/infra/db/app_database.g.dart
```

Expected: file modified.

- [ ] **Step 5: Commit (compile is broken — explicitly noted in message)**

```bash
git add lib/infra/db/tables.dart lib/infra/db/app_database.dart \
        lib/infra/db/app_database.g.dart
git commit -m "refactor(db): bump schema to v9 with reset migration; species + animal-counts tables

WIP — compile is broken until repositories and screens are updated in
subsequent commits. Schema reset is intentional (no prod users)."
```

---

## Task 9 — Update domain `Client`

**Files:**
- Modify: `lib/domain/models/client.dart`

- [ ] **Step 1: Replace contents**

```dart
// lib/domain/models/client.dart
import 'animal_count.dart';
import 'coordinates.dart';

class Client {
  final int id;
  final String name;
  final List<String> phones;
  final String addressLabel;
  final String postcode;
  final String city;
  final Coordinates coordinates;
  final List<AnimalCount> animals;
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
    this.animals = const [],
    this.phones = const [],
    this.markerColorHex,
    this.isWaiting = false,
    this.isBanned = false,
    this.lastShearingDate,
    this.needsDistanceRecompute = false,
  });

  /// Total animal count across all categories. Used for the "no animals"
  /// status derivation and for compact list display.
  int get animalsTotal {
    var total = 0;
    for (final a in animals) {
      total += a.count;
    }
    return total;
  }

  String? get principalPhone => phones.isNotEmpty ? phones.first : null;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/domain/models/client.dart
git commit -m "refactor(domain): Client uses List<AnimalCount> instead of sheep counters"
```

---

## Task 10 — Update domain `TourStop`

**Files:**
- Modify: `lib/domain/models/tour_stop.dart`

- [ ] **Step 1: Read the existing file** (`lib/domain/models/tour_stop.dart`) to get the current shape — it currently exposes `plannedSmall`, `plannedLarge`, `actualSmall?`, `actualLarge?`, `minutesPerSmallSnapshot`, `minutesPerLargeSnapshot`. Also note the existing draft type if any.

- [ ] **Step 2: Replace `TourStop` with the new shape**

```dart
// lib/domain/models/tour_stop.dart
import 'tour_stop_animal.dart';

class TourStop {
  final int id;
  final int tourId;
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final List<TourStopAnimal> planned;
  final List<TourStopAnimal>? actual;
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
    required this.planned,
    this.actual,
    this.interventionNote,
    required this.feeShareCents,
  });
}

class TourStopDraft {
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final List<TourStopAnimal> planned;
  final int feeShareCents;

  const TourStopDraft({
    required this.clientId,
    required this.clientNameSnapshot,
    required this.orderIndex,
    required this.estimatedArrivalMinutes,
    required this.estimatedDepartureMinutes,
    required this.planned,
    required this.feeShareCents,
  });
}
```

If the existing file declares a `TourDraft` type alongside, preserve it: only the stop-related types change in this task. (Inspect the existing file — it carries the tour-level draft fields; copy them through unchanged in your edit.)

- [ ] **Step 3: Commit**

```bash
git add lib/domain/models/tour_stop.dart
git commit -m "refactor(domain): TourStop uses List<TourStopAnimal> snapshots"
```

---

## Task 11 — Update domain `ManualHistoryEntry`

**Files:**
- Modify: `lib/domain/models/manual_history_entry.dart`

- [ ] **Step 1: Replace contents**

```dart
// lib/domain/models/manual_history_entry.dart
import 'tour_stop_animal.dart';

class ManualHistoryEntry {
  final int id;
  final int clientId;
  final DateTime date;
  final List<TourStopAnimal> animals;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ManualHistoryEntry({
    required this.id,
    required this.clientId,
    required this.date,
    required this.animals,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/domain/models/manual_history_entry.dart
git commit -m "refactor(domain): ManualHistoryEntry carries List<TourStopAnimal>"
```

---

## Task 12 — Update domain `Settings`

**Files:**
- Modify: `lib/domain/models/settings.dart`

Drop `defaultMinutesPerSmall`, `defaultMinutesPerLarge`. Rename `markerNoSheepColor` → `markerNoAnimalsColor`. Add `appAvatarKey: String?`.

- [ ] **Step 1: Replace contents**

```dart
// lib/domain/models/settings.dart
import 'coordinates.dart';

enum ThemeModePreference { system, light, dark }

class Settings {
  final Coordinates baseCoordinates;
  final String baseAddressLabel;
  final int defaultRadiusKm;
  final int travelFeeEurosPerBracket;
  final int bracketKm;
  final ThemeModePreference themeMode;
  final String markerDefaultColor;
  final String markerWaitingColor;
  final String markerScheduledColor;
  final String markerDoneColor;
  final String markerNoAnimalsColor;
  final String markerBannedColor;
  final DateTime seasonStartedAt;
  final String? appAvatarKey;

  const Settings({
    required this.baseCoordinates,
    required this.baseAddressLabel,
    required this.seasonStartedAt,
    this.defaultRadiusKm = 15,
    this.travelFeeEurosPerBracket = 8,
    this.bracketKm = 10,
    this.themeMode = ThemeModePreference.system,
    this.markerDefaultColor = '#9CA3AF',
    this.markerWaitingColor = '#EAB308',
    this.markerScheduledColor = '#65A30D',
    this.markerDoneColor = '#166534',
    this.markerNoAnimalsColor = '#1F2937',
    this.markerBannedColor = '#B91C1C',
    this.appAvatarKey,
  });

  Settings copyWith({
    Coordinates? baseCoordinates,
    String? baseAddressLabel,
    int? defaultRadiusKm,
    int? travelFeeEurosPerBracket,
    int? bracketKm,
    ThemeModePreference? themeMode,
    String? markerDefaultColor,
    String? markerWaitingColor,
    String? markerScheduledColor,
    String? markerDoneColor,
    String? markerNoAnimalsColor,
    String? markerBannedColor,
    DateTime? seasonStartedAt,
    String? appAvatarKey,
  }) =>
      Settings(
        baseCoordinates: baseCoordinates ?? this.baseCoordinates,
        baseAddressLabel: baseAddressLabel ?? this.baseAddressLabel,
        defaultRadiusKm: defaultRadiusKm ?? this.defaultRadiusKm,
        travelFeeEurosPerBracket:
            travelFeeEurosPerBracket ?? this.travelFeeEurosPerBracket,
        bracketKm: bracketKm ?? this.bracketKm,
        themeMode: themeMode ?? this.themeMode,
        markerDefaultColor: markerDefaultColor ?? this.markerDefaultColor,
        markerWaitingColor: markerWaitingColor ?? this.markerWaitingColor,
        markerScheduledColor:
            markerScheduledColor ?? this.markerScheduledColor,
        markerDoneColor: markerDoneColor ?? this.markerDoneColor,
        markerNoAnimalsColor:
            markerNoAnimalsColor ?? this.markerNoAnimalsColor,
        markerBannedColor: markerBannedColor ?? this.markerBannedColor,
        seasonStartedAt: seasonStartedAt ?? this.seasonStartedAt,
        appAvatarKey: appAvatarKey ?? this.appAvatarKey,
      );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/domain/models/settings.dart
git commit -m "refactor(domain): Settings drops minutes-per-sheep, adds appAvatarKey, renames markerNoAnimals"
```

---

## Task 13 — `SpeciesRepository`

**Files:**
- Create: `lib/data/repositories/species_repository.dart`
- Create: `test/data/species_repository_test.dart`

CRUD with archive. List active / list archived / list all. Insert / rename / archive / unarchive. The repository takes the `AppDatabase` and exposes domain `Species` types.

- [ ] **Step 1: Write failing tests**

```dart
// test/data/species_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/data/repositories/species_repository.dart';
import 'package:coup_laine/infra/db/app_database.dart';

void main() {
  late AppDatabase db;
  late SpeciesRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SpeciesRepository(db);
  });

  tearDown(() async => db.close());

  test('insert and list active', () async {
    final id = await repo.insert(name: 'Mouton');
    final active = await repo.listActive();
    expect(active, hasLength(1));
    expect(active.first.id, id);
    expect(active.first.name, 'Mouton');
    expect(active.first.archivedAt, isNull);
  });

  test('rename updates name', () async {
    final id = await repo.insert(name: 'Mouton');
    await repo.rename(id: id, name: 'Ovin');
    final s = (await repo.listActive()).single;
    expect(s.name, 'Ovin');
  });

  test('archive sets archivedAt; listActive excludes; listArchived includes',
      () async {
    final id = await repo.insert(name: 'Mouton');
    await repo.archive(id);
    expect(await repo.listActive(), isEmpty);
    final archived = await repo.listArchived();
    expect(archived, hasLength(1));
    expect(archived.first.archivedAt, isNotNull);
  });

  test('unarchive clears archivedAt', () async {
    final id = await repo.insert(name: 'Mouton');
    await repo.archive(id);
    await repo.unarchive(id);
    expect(await repo.listActive(), hasLength(1));
    expect(await repo.listArchived(), isEmpty);
  });

  test('countActive', () async {
    expect(await repo.countActive(), 0);
    final a = await repo.insert(name: 'Mouton');
    await repo.insert(name: 'Cheval');
    expect(await repo.countActive(), 2);
    await repo.archive(a);
    expect(await repo.countActive(), 1);
  });
}
```

- [ ] **Step 2: Run, expect FAIL.**

- [ ] **Step 3: Implement**

```dart
// lib/data/repositories/species_repository.dart
import 'package:drift/drift.dart';

import '../../domain/models/species.dart';
import '../../infra/db/app_database.dart';
import '../../infra/db/tables.dart';

class SpeciesRepository {
  final AppDatabase _db;
  SpeciesRepository(this._db);

  Future<int> insert({required String name, String? iconKey}) async {
    return _db.into(_db.speciesTable).insert(
          SpeciesTableCompanion.insert(
            name: name,
            iconKey: Value(iconKey),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> rename({required int id, required String name}) async {
    await (_db.update(_db.speciesTable)..where((s) => s.id.equals(id)))
        .write(SpeciesTableCompanion(name: Value(name)));
  }

  Future<void> archive(int id) async {
    await (_db.update(_db.speciesTable)..where((s) => s.id.equals(id))).write(
      SpeciesTableCompanion(
        archivedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> unarchive(int id) async {
    await (_db.update(_db.speciesTable)..where((s) => s.id.equals(id)))
        .write(const SpeciesTableCompanion(archivedAt: Value(null)));
  }

  Future<List<Species>> listActive() async {
    final rows = await (_db.select(_db.speciesTable)
          ..where((s) => s.archivedAt.isNull())
          ..orderBy([(s) => OrderingTerm(expression: s.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Species>> listArchived() async {
    final rows = await (_db.select(_db.speciesTable)
          ..where((s) => s.archivedAt.isNotNull())
          ..orderBy([(s) => OrderingTerm(expression: s.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Species>> listAll() async {
    final rows = await (_db.select(_db.speciesTable)
          ..orderBy([(s) => OrderingTerm(expression: s.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<int> countActive() async {
    final count = countAll(filter: (_) => CustomExpression('archived_at IS NULL'));
    final query = _db.selectOnly(_db.speciesTable)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Species _toDomain(SpeciesRow row) => Species(
        id: row.id,
        name: row.name,
        iconKey: row.iconKey,
        archivedAt: row.archivedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!),
      );
}
```

- [ ] **Step 4: Run tests, expect PASS.** If `countActive` query syntax fails to compile, replace with a `.get().then((rows) => rows.length)` workaround:

```dart
Future<int> countActive() async {
  final rows = await (_db.select(_db.speciesTable)
        ..where((s) => s.archivedAt.isNull()))
      .get();
  return rows.length;
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/species_repository.dart \
        test/data/species_repository_test.dart
git commit -m "feat(data): add SpeciesRepository with CRUD and archive"
```

---

## Task 14 — `AnimalCategoryRepository`

**Files:**
- Create: `lib/data/repositories/animal_category_repository.dart`
- Create: `test/data/animal_category_repository_test.dart`

CRUD on categories. List by species (active), list by species (all), list all active across species, set defaults (minutes/price), archive/unarchive, rename.

- [ ] **Step 1: Write failing tests**

```dart
// test/data/animal_category_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/data/repositories/animal_category_repository.dart';
import 'package:coup_laine/data/repositories/species_repository.dart';
import 'package:coup_laine/infra/db/app_database.dart';

void main() {
  late AppDatabase db;
  late SpeciesRepository species;
  late AnimalCategoryRepository repo;
  late int speciesId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    species = SpeciesRepository(db);
    repo = AnimalCategoryRepository(db);
    speciesId = await species.insert(name: 'Mouton');
  });

  tearDown(() async => db.close());

  test('insert with no defaults; listActiveBySpecies returns it', () async {
    final id = await repo.insert(speciesId: speciesId, name: 'Petit');
    final list = await repo.listActiveBySpecies(speciesId);
    expect(list, hasLength(1));
    expect(list.first.id, id);
    expect(list.first.defaultMinutes, isNull);
    expect(list.first.defaultPriceCents, isNull);
  });

  test('updateDefaults changes minutes and price', () async {
    final id = await repo.insert(speciesId: speciesId, name: 'Petit');
    await repo.updateDefaults(
      id: id,
      defaultMinutes: 8,
      defaultPriceCents: 800,
    );
    final c = (await repo.listActiveBySpecies(speciesId)).single;
    expect(c.defaultMinutes, 8);
    expect(c.defaultPriceCents, 800);
  });

  test('archive excludes from listActiveBySpecies', () async {
    final id = await repo.insert(speciesId: speciesId, name: 'Petit');
    await repo.archive(id);
    expect(await repo.listActiveBySpecies(speciesId), isEmpty);
  });

  test('listAllActive merges across species', () async {
    final spId2 = await species.insert(name: 'Cheval');
    await repo.insert(speciesId: speciesId, name: 'Petit');
    await repo.insert(speciesId: spId2, name: 'Adulte');
    final all = await repo.listAllActive();
    expect(all, hasLength(2));
  });

  test('archived species cascades — categories deleted on species delete '
      '(but archive does not delete)', () async {
    // The spec uses soft-archive on species. Categories remain; UI hides
    // them via the species archive flag.
    final cId = await repo.insert(speciesId: speciesId, name: 'Petit');
    await species.archive(speciesId);
    // Category still exists in DB (no cascade on archive).
    final all = await repo.listAllActive();
    expect(all.any((c) => c.id == cId), isTrue);
  });
}
```

- [ ] **Step 2: Run, expect FAIL.**

- [ ] **Step 3: Implement**

```dart
// lib/data/repositories/animal_category_repository.dart
import 'package:drift/drift.dart';

import '../../domain/models/animal_category.dart';
import '../../infra/db/app_database.dart';
import '../../infra/db/tables.dart';

class AnimalCategoryRepository {
  final AppDatabase _db;
  AnimalCategoryRepository(this._db);

  Future<int> insert({
    required int speciesId,
    required String name,
    int? defaultMinutes,
    int? defaultPriceCents,
  }) {
    return _db.into(_db.animalCategoriesTable).insert(
          AnimalCategoriesTableCompanion.insert(
            speciesId: speciesId,
            name: name,
            defaultMinutes: Value(defaultMinutes),
            defaultPriceCents: Value(defaultPriceCents),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> rename({required int id, required String name}) async {
    await (_db.update(_db.animalCategoriesTable)
          ..where((c) => c.id.equals(id)))
        .write(AnimalCategoriesTableCompanion(name: Value(name)));
  }

  Future<void> updateDefaults({
    required int id,
    int? defaultMinutes,
    int? defaultPriceCents,
  }) async {
    await (_db.update(_db.animalCategoriesTable)
          ..where((c) => c.id.equals(id)))
        .write(AnimalCategoriesTableCompanion(
      defaultMinutes: Value(defaultMinutes),
      defaultPriceCents: Value(defaultPriceCents),
    ));
  }

  Future<void> archive(int id) async {
    await (_db.update(_db.animalCategoriesTable)
          ..where((c) => c.id.equals(id)))
        .write(AnimalCategoriesTableCompanion(
      archivedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> unarchive(int id) async {
    await (_db.update(_db.animalCategoriesTable)
          ..where((c) => c.id.equals(id)))
        .write(const AnimalCategoriesTableCompanion(archivedAt: Value(null)));
  }

  Future<List<AnimalCategory>> listAll() async {
    final rows = await (_db.select(_db.animalCategoriesTable)
          ..orderBy([(c) => OrderingTerm(expression: c.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<AnimalCategory>> listAllActive() async {
    final rows = await (_db.select(_db.animalCategoriesTable)
          ..where((c) => c.archivedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<AnimalCategory>> listActiveBySpecies(int speciesId) async {
    final rows = await (_db.select(_db.animalCategoriesTable)
          ..where((c) => c.speciesId.equals(speciesId) & c.archivedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<AnimalCategory>> listAllBySpecies(int speciesId) async {
    final rows = await (_db.select(_db.animalCategoriesTable)
          ..where((c) => c.speciesId.equals(speciesId))
          ..orderBy([(c) => OrderingTerm(expression: c.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  AnimalCategory _toDomain(AnimalCategoryRow row) => AnimalCategory(
        id: row.id,
        speciesId: row.speciesId,
        name: row.name,
        defaultMinutes: row.defaultMinutes,
        defaultPriceCents: row.defaultPriceCents,
        archivedAt: row.archivedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!),
      );
}
```

- [ ] **Step 4: Run tests, expect PASS.**

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/animal_category_repository.dart \
        test/data/animal_category_repository_test.dart
git commit -m "feat(data): add AnimalCategoryRepository with CRUD, defaults and archive"
```

---

## Task 15 — Update `SettingsRepository`

**Files:**
- Modify: `lib/data/repositories/settings_repository.dart`
- Modify: `test/data/settings_repository_test.dart`

The repo currently maps the row to `Settings` and back. Update mapping to:
- Drop `defaultMinutesPerSmall`, `defaultMinutesPerLarge`.
- Use `markerNoAnimalsColor` instead of `markerNoSheepColor` (column was renamed in Task 8).
- Map `appAvatarKey` (nullable string) on read and write.

- [ ] **Step 1: Read the existing file** to see the precise mapping shape.

- [ ] **Step 2: Update read/save mappings**

In the `read()` method, drop the two `defaultMinutesPer*` accesses. Replace `markerNoSheepColor: row.markerNoSheepColor` with `markerNoAnimalsColor: row.markerNoAnimalsColor`. Add `appAvatarKey: row.appAvatarKey`.

In the `save()` method, replace the corresponding `Companion` field assignments. Drop the two minutes-per fields. Use `markerNoAnimalsColor: Value(s.markerNoAnimalsColor)`. Add `appAvatarKey: Value(s.appAvatarKey)`.

- [ ] **Step 3: Update tests in `test/data/settings_repository_test.dart`** — replace any `defaultMinutesPerSmall/Large` assertions and `markerNoSheepColor` references. Add a test for `appAvatarKey` round-trip:

```dart
test('appAvatarKey round-trips', () async {
  await repo.save(Settings(
    baseCoordinates: const Coordinates(48.0, 2.0),
    baseAddressLabel: 'Foo',
    seasonStartedAt: DateTime(2026),
    appAvatarKey: 'scissors',
  ));
  final s = await repo.read();
  expect(s!.appAvatarKey, 'scissors');
});
```

- [ ] **Step 4: Run settings tests**

```bash
flutter test test/data/settings_repository_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/settings_repository.dart \
        test/data/settings_repository_test.dart
git commit -m "refactor(data): SettingsRepository drops minutesPerSmall/Large, adds appAvatarKey, renames markerNoAnimals"
```

---

## Task 16 — Update `ClientRepository` (mapping)

**Files:**
- Modify: `lib/data/repositories/client_repository.dart`

Focus of this task: row↔domain mapping only. The two business methods
(`applyManualEntryToClient` and `recomputeClientFromHistory`) are
updated in Task 17 to keep this commit small.

- [ ] **Step 1: Adjust mapping**

In `_toDomain` (or equivalent), replace `sheepCountSmall`/`sheepCountLarge` with `animals: row.animals`.
In writes (`insert`, `update`, `replace`), serialize `client.animals` via
`normalizeAnimalCounts` before persistence:

```dart
import '../../core/animal_counts_normalizer.dart';
// ...

ClientsTableCompanion _toCompanion(Client c) => ClientsTableCompanion(
      // ... unchanged fields
      animals: Value(normalizeAnimalCounts(c.animals)),
      // ...
    );
```

If the existing repo computes / writes `sheepCountTotal` somewhere, switch to `c.animalsTotal`.

- [ ] **Step 2: Run** `flutter analyze lib/data/repositories/client_repository.dart` and fix any compile errors locally.

- [ ] **Step 3: Run the existing client repository tests** to surface remaining issues.

```bash
flutter test test/data/client_repository_test.dart
```

Expect failures — they will be addressed in Task 17 and Task 18.

- [ ] **Step 4: Commit (still WIP — explicit message)**

```bash
git add lib/data/repositories/client_repository.dart
git commit -m "refactor(data): ClientRepository row↔domain mapping uses animals JSON

WIP — applyManualEntryToClient and recomputeClientFromHistory are
updated in the next commits."
```

---

## Task 17 — Update `applyManualEntryToClient` + `recomputeClientFromHistory`

**Files:**
- Modify: `lib/data/repositories/client_repository.dart`
- Modify: `test/data/client_repository_test.dart`

Two business operations:

- **`applyManualEntryToClient(client, entry)`** : if `entry.date` is strictly more recent than `client.lastShearingDate`, merge `entry.animals` (a `List<TourStopAnimal>`) into `client.animals` per category — entry counts overwrite the count for matching `categoryId`s, other categories are untouched. Update `lastShearingDate`.
- **`recomputeClientFromHistory(clientId)`** : rebuild `client.animals` and `lastShearingDate` from the union of (tour stops with status `completed` `actual` lists, manual history entries). Strategy: for each `categoryId` involved, pick the count from the most recent entry/stop. `lastShearingDate` = max date across all sources.

- [ ] **Step 1: Update the existing test file** to use the new model shapes. Read `test/data/client_repository_test.dart`. Replace fixtures using `sheepCountSmall/Large` with `animals: [AnimalCount(...)]`, and any `entry.sheepCountSmall/Large` with `entry.animals: [TourStopAnimal(...)]`. Update assertions accordingly.

- [ ] **Step 2: Add (or adjust) tests for the new merge semantics**

```dart
test('applyManualEntryToClient merges animals per categoryId, '
    'leaving other categories untouched', () async {
  // Setup: client has {cat 1: 5, cat 2: 12}.
  final clientId = await repo.insert(Client(
    id: 0,
    name: 'A',
    addressLabel: '...',
    postcode: '...',
    city: '...',
    coordinates: const Coordinates(0, 0),
    animals: [
      const AnimalCount(categoryId: 1, count: 5),
      const AnimalCount(categoryId: 2, count: 12),
    ],
  ));
  // Entry covers only category 1 with count 3, dated 2026-04-15.
  await repo.applyManualEntryToClient(
    clientId: clientId,
    entryDate: DateTime(2026, 4, 15),
    entryAnimals: const [
      TourStopAnimal(
        categoryId: 1,
        count: 3,
        categoryNameSnapshot: 'Petit',
        speciesNameSnapshot: 'Mouton',
        minutesSnapshot: 8,
      ),
    ],
  );
  final c = await repo.findById(clientId);
  expect(c!.animals, [
    const AnimalCount(categoryId: 1, count: 3),
    const AnimalCount(categoryId: 2, count: 12),
  ]);
});

test('recomputeClientFromHistory takes the most recent count '
    'per category across sources', () async {
  // ... setup two manual entries, one tour stop completed, varied dates ...
});
```

- [ ] **Step 3: Implement merge logic**

```dart
List<AnimalCount> _mergeAnimals(
  List<AnimalCount> existing,
  List<TourStopAnimal> incoming,
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

Use this in `applyManualEntryToClient`. For `recomputeClientFromHistory`:

```dart
Future<void> recomputeClientFromHistory(int clientId) async {
  // Pull all manual entries (newest first) and all completed tour stops
  // (newest first) for this client. For each categoryId, the first
  // occurrence wins (the most recent count).
  final manualNewestFirst =
      await _manualHistory.listForClient(clientId, newestFirst: true);
  final completedStops =
      await _listCompletedStopsForClient(clientId, newestFirst: true);

  final byId = <int, int>{};
  DateTime? mostRecent;
  for (final e in manualNewestFirst) {
    mostRecent ??= e.date;
    for (final a in e.animals) {
      byId.putIfAbsent(a.categoryId, () => a.count);
    }
  }
  for (final s in completedStops) {
    final stopDate = s.completedAt ?? s.plannedDate;
    if (mostRecent == null || stopDate.isAfter(mostRecent)) {
      mostRecent = stopDate;
    }
    for (final a in (s.actual ?? const <TourStopAnimal>[])) {
      byId.putIfAbsent(a.categoryId, () => a.count);
    }
  }

  await (_db.update(_db.clientsTable)
        ..where((c) => c.id.equals(clientId)))
      .write(ClientsTableCompanion(
    animals: Value(normalizeAnimalCounts([
      for (final e in byId.entries)
        AnimalCount(categoryId: e.key, count: e.value),
    ])),
    lastShearingDate:
        Value(mostRecent?.toUtc().millisecondsSinceEpoch),
  ));
}
```

If the existing repo already declares helpers like `_listCompletedStopsForClient` keep them; otherwise add a private helper that joins `tour_stops` to `tours` filtered by `status = 'completed'` and yields the stop with parent fields needed (note the date stored as epoch days for `tours.plannedDate`).

- [ ] **Step 4: Run client repository tests, expect PASS.**

```bash
flutter test test/data/client_repository_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/client_repository.dart \
        test/data/client_repository_test.dart
git commit -m "feat(data): per-category merge in applyManualEntryToClient and recomputeClientFromHistory"
```

---

## Task 18 — Update `TourRepository`

**Files:**
- Modify: `lib/data/repositories/tour_repository.dart`
- Modify: `test/data/tour_repository_test.dart`

Update row↔domain mappers and writes to use `plannedAnimals` / `actualAnimals` JSON columns. All existing tests must be migrated to the new fixture shape (no more `plannedSmall/Large`, `actualSmall/Large`, `minutesPerSmallSnapshot/LargeSnapshot`).

- [ ] **Step 1: Add a fixture helper `seedTestSpeciesAndCategories(db)`**

Create `test/_helpers/animal_fixtures.dart`:

```dart
// test/_helpers/animal_fixtures.dart
import 'package:coup_laine/data/repositories/animal_category_repository.dart';
import 'package:coup_laine/data/repositories/species_repository.dart';
import 'package:coup_laine/infra/db/app_database.dart';

class AnimalFixtures {
  final int moutonId;
  final int chevalId;
  final int catPetit;
  final int catGrand;
  final int catPoulain;
  final int catAdulte;

  const AnimalFixtures({
    required this.moutonId,
    required this.chevalId,
    required this.catPetit,
    required this.catGrand,
    required this.catPoulain,
    required this.catAdulte,
  });
}

Future<AnimalFixtures> seedTestSpeciesAndCategories(AppDatabase db) async {
  final species = SpeciesRepository(db);
  final cats = AnimalCategoryRepository(db);
  final mouton = await species.insert(name: 'Mouton');
  final cheval = await species.insert(name: 'Cheval');
  final petit = await cats.insert(speciesId: mouton, name: 'Petit', defaultMinutes: 8);
  final grand = await cats.insert(speciesId: mouton, name: 'Grand', defaultMinutes: 25);
  final poulain = await cats.insert(speciesId: cheval, name: 'Poulain', defaultMinutes: 30);
  final adulte = await cats.insert(speciesId: cheval, name: 'Adulte', defaultMinutes: 45);
  return AnimalFixtures(
    moutonId: mouton, chevalId: cheval,
    catPetit: petit, catGrand: grand,
    catPoulain: poulain, catAdulte: adulte,
  );
}
```

- [ ] **Step 2: Migrate `test/data/tour_repository_test.dart`**

Replace every `TourStopDraft(plannedSmall: ..., plannedLarge: ..., minutesPerSmallSnapshot: ..., minutesPerLargeSnapshot: ...)` with `TourStopDraft(planned: [TourStopAnimal(...)])`, where the snapshots use the fixture category ids and the seeded names.

Use `seedTestSpeciesAndCategories(db)` in `setUp` and reference `fix.catPetit`, etc.

- [ ] **Step 3: Update `TourRepository.plan` / `update` / `findById` mappings**

In write paths, persist `planned` via `TourStopAnimalListConverter`-backed companion field `plannedAnimals: Value(normalizeTourStopAnimals(draft.planned))`. Drop all references to the four old columns.

In `findById`, map the row's `plannedAnimals` and `actualAnimals` directly to the domain `planned` / `actual` fields.

In `markCompleted` (or wherever `actualSmall/Large` was set), accept a `List<TourStopAnimal>` per stop and persist it via `actualAnimals: Value(normalizeTourStopAnimals(...))`.

- [ ] **Step 4: Run** `flutter test test/data/tour_repository_test.dart` and iterate until green.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/tour_repository.dart \
        test/data/tour_repository_test.dart \
        test/_helpers/animal_fixtures.dart
git commit -m "refactor(data): TourRepository persists planned/actual as JSON snapshots"
```

---

## Task 19 — Update `ManualHistoryRepository`

**Files:**
- Modify: `lib/data/repositories/manual_history_repository.dart`
- Modify: `test/data/manual_history_repository_test.dart`

Same shape as before, but the row exposes a JSON `animals` column replacing `sheepCountSmall/Large`.

- [ ] **Step 1: Update the row→domain mapper** to use `row.animals` (already a `List<TourStopAnimal>` thanks to the converter) and drop the old fields.

- [ ] **Step 2: Update writes (`insert`, `update`)** to persist `entry.animals` via `normalizeTourStopAnimals` before the companion.

- [ ] **Step 3: Update tests** — replace fixtures, use `seedTestSpeciesAndCategories`, assert on the new shape.

- [ ] **Step 4: Run** `flutter test test/data/manual_history_repository_test.dart` until green.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/manual_history_repository.dart \
        test/data/manual_history_repository_test.dart
git commit -m "refactor(data): ManualHistoryRepository persists animals as JSON snapshots"
```

---

## Task 20 — Update `BuildTourDraft`

**Files:**
- Modify: `lib/domain/use_cases/build_tour_draft.dart`
- Modify: `test/domain/build_tour_draft_test.dart`

`BuildTourDraft` constructs `TourStopDraft.planned` for each selected client. New signature accepts an in-memory map `Map<int, AnimalCategory>` (active categories indexed by id) for snapshot lookup.

- [ ] **Step 1: Update the use case signature**

```dart
class BuildTourDraft {
  TourDraft call({
    required DateTime plannedDate,
    required int startTimeMinutes,
    required List<Client> selectedClients,
    required Map<int, ({String speciesName, AnimalCategory category})> categoryLookup,
    required List<DistanceMatrixEntry> matrix,
    required Settings settings,
  }) {
    // For each client → TourStopDraft. For each AnimalCount on the client,
    // resolve the category in `categoryLookup`. If missing (archived or
    // deleted), skip the line.
    // Build TourStopAnimal:
    //   categoryId: ac.categoryId,
    //   count: ac.count,
    //   categoryNameSnapshot: lookup.category.name,
    //   speciesNameSnapshot: lookup.speciesName,
    //   minutesSnapshot: lookup.category.defaultMinutes ?? 0,
    // ... distance/eta logic unchanged ...
  }
}
```

- [ ] **Step 2: Migrate the existing tests** — replace any `sheepCountSmall/Large` references on `Client` fixtures with `animals: [...]`, and pass a `categoryLookup` argument. Assert that snapshots are populated.

- [ ] **Step 3: Implement** the lookup logic. Use the spec exactly (see "5.4 — Build / édition de tournée").

- [ ] **Step 4: Run** `flutter test test/domain/build_tour_draft_test.dart` until green.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/use_cases/build_tour_draft.dart \
        test/domain/build_tour_draft_test.dart
git commit -m "refactor(domain): BuildTourDraft snapshots category and species names per stop"
```

---

## Task 21 — Update `TourDurationEstimator`

**Files:**
- Modify: `lib/domain/use_cases/tour_duration_estimator.dart`
- Modify: `test/domain/tour_duration_estimator_test.dart`

New formula: `Σ stops (Σ animals (count × minutesSnapshot)) + drive_time`. When `minutesSnapshot == 0`, the stop contributes 0 minutes of intervention time.

- [ ] **Step 1: Adjust the use case** — replace `count_small × min_small + count_large × min_large` with a fold over `stop.planned` (or whatever the stop type exposes here).

- [ ] **Step 2: Update tests** — replace fixtures. Add a test asserting that `minutesSnapshot == 0` produces only drive time.

```dart
test('stops with all minutesSnapshot=0 estimate to drive time only', () {
  final stops = [
    TourStop(
      // ...,
      planned: const [
        TourStopAnimal(
          categoryId: 1,
          count: 5,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 0,
        ),
      ],
    ),
  ];
  final out = const TourDurationEstimator().estimate(
    stops: stops,
    driveSeconds: 600,
  );
  expect(out.totalMinutes, 600 ~/ 60);
});
```

- [ ] **Step 3: Run, expect PASS.**

- [ ] **Step 4: Commit**

```bash
git add lib/domain/use_cases/tour_duration_estimator.dart \
        test/domain/tour_duration_estimator_test.dart
git commit -m "refactor(domain): TourDurationEstimator sums minutesSnapshot across N categories"
```

---

## Task 22 — Update `ClientStatus` (rename `noSheep` → `noAnimals`)

**Files:**
- Modify: `lib/domain/use_cases/client_status.dart`
- Modify: `test/domain/client_status_test.dart`
- Modify: every consumer of `ClientStatus.noSheep` (use `flutter analyze` to find them).

- [ ] **Step 1: Rename the enum value `noSheep` → `noAnimals`** in `client_status.dart`. Update the derivation logic to use `client.animalsTotal == 0` instead of `sheepCountTotal == 0`.

- [ ] **Step 2: Update the test file** — rename references and assertions.

- [ ] **Step 3: Hunt down compile errors**

```bash
flutter analyze
```

Expect references in: `clients_list_screen.dart`, `client_detail_screen.dart`, `client_pin_popup.dart`, `map_screen.dart`, l10n consumers (`clientStatusNoSheep`), and possibly `settings_screen.dart` (markers section). For now, only fix the enum-name references — l10n + UI are tackled in later tasks. Use `// TODO migrate l10n key` comments only if absolutely needed; prefer to update the references inline if they're trivial.

- [ ] **Step 4: Run domain tests**

```bash
flutter test test/domain/client_status_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/use_cases/client_status.dart test/domain/client_status_test.dart
# Plus any minimal call-site fixups required for analyze to clear past this rename:
git add <other files touched only to swap the enum name>
git commit -m "refactor(domain): rename ClientStatus.noSheep → noAnimals"
```

---

## Task 23 — Wire new providers in `state/providers.dart`

**Files:**
- Modify: `lib/state/providers.dart`

Expose `SpeciesRepository`, `AnimalCategoryRepository`, plus convenience providers used by widgets.

- [ ] **Step 1: Add repository providers**

```dart
import '../data/repositories/animal_category_repository.dart';
import '../data/repositories/species_repository.dart';
import '../domain/models/animal_category.dart';
import '../domain/models/species.dart';

final speciesRepositoryProvider = Provider<SpeciesRepository>((ref) {
  return SpeciesRepository(ref.watch(appDatabaseProvider));
});

final animalCategoryRepositoryProvider =
    Provider<AnimalCategoryRepository>((ref) {
  return AnimalCategoryRepository(ref.watch(appDatabaseProvider));
});

/// Active species (excludes archived). Watched by the species management
/// screen and the AnimalCountsEditor widget.
final activeSpeciesProvider = FutureProvider<List<Species>>((ref) {
  return ref.watch(speciesRepositoryProvider).listActive();
});

/// All categories (active + archived) keyed by id. Used by repositories
/// and by displays that need to look up snapshot context.
final allCategoriesByIdProvider =
    FutureProvider<Map<int, AnimalCategory>>((ref) async {
  final list = await ref.watch(animalCategoryRepositoryProvider).listAll();
  return {for (final c in list) c.id: c};
});

/// Active categories grouped by speciesId. Used by AnimalCountsEditor.
final activeCategoriesBySpeciesProvider =
    FutureProvider<Map<int, List<AnimalCategory>>>((ref) async {
  final list = await ref.watch(animalCategoryRepositoryProvider).listAllActive();
  final out = <int, List<AnimalCategory>>{};
  for (final c in list) {
    out.putIfAbsent(c.speciesId, () => []).add(c);
  }
  return out;
});

/// Convenience: the species + categories info needed to build TourStopAnimal
/// snapshots. Built once per provider read.
final categoryLookupProvider = FutureProvider<
    Map<int, ({String speciesName, AnimalCategory category})>>((ref) async {
  final speciesById = {
    for (final s in await ref.watch(speciesRepositoryProvider).listAll())
      s.id: s,
  };
  final cats = await ref.watch(animalCategoryRepositoryProvider).listAll();
  return {
    for (final c in cats)
      c.id: (
        speciesName: speciesById[c.speciesId]?.name ?? '',
        category: c,
      ),
  };
});
```

- [ ] **Step 2: Run analyze + tests, expect green within these files**

- [ ] **Step 3: Commit**

```bash
git add lib/state/providers.dart
git commit -m "feat(state): add species/category providers and category-lookup helper"
```

---

## Task 24 — l10n: rename, delete, add keys (fr + en)

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`

Apply ALL spec-section-6 changes in one commit (l10n is naturally bundled).

- [ ] **Step 1: Delete keys**

In both `.arb`:
- `helloDebug`
- `clientFormSheepCountSmall`
- `clientFormSheepCountLarge`
- `clientDetailSheepCountFmt` (and its placeholder annotation)
- `clientsListSheepCountFmt` (and its placeholder annotation)
- `clientDetailHistoryItemFmt` (and its placeholder annotation)
- `manualEntrySmallLabel`
- `manualEntryLargeLabel`
- `settingsMinPerSmallLabel`
- `settingsMinPerLargeLabel`

- [ ] **Step 2: Rename keys (key + value updates)**

| Old key | New key | New fr value | New en value |
|---|---|---|---|
| `clientFormSectionShearing` | `clientFormSectionAnimals` | `Animaux` | `Animals` |
| `clientStatusNoSheep` | `clientStatusNoAnimals` | `Sans animaux` | `No animals` |
| `settingsMarkerNoSheep` | `settingsMarkerNoAnimals` | `Sans animaux` | `No animals` |

Update existing values:
- `clientHistoryAddAction` (fr) `Ajouter une tonte` → `Ajouter une intervention`. (en) `Add intervention`.
- `manualEntrySheetTitleCreate` (fr) `Ajouter une tonte` → `Ajouter une intervention`. (en) `Add intervention`.
- `manualEntrySheetTitleEdit` (fr) `Modifier la tonte` → `Modifier l'intervention`. (en) `Edit intervention`.
- `tourDraftSummaryTotal` (fr) replace `Tonte : {shear}` with `Intervention : {shear}`. (en) replace `Shearing: {shear}` with `Intervention: {shear}`.

- [ ] **Step 3: Add new keys**

Add (in both ARB; en-translated equivalents in en.arb):

```json
"onboardingStep1Title": "Adresse de départ",
"onboardingStep1Cta": "Suivant",
"onboardingStep2Title": "Vos espèces",
"onboardingStep2Subtitle": "Sélectionnez les espèces que vous traitez",
"onboardingAvatarTitle": "Logo de l'app",
"onboardingAvatarSubtitle": "Choisissez votre identité visuelle",
"onboardingAddCustomSpecies": "+ Ajouter une espèce personnalisée",
"onboardingCtaFinish": "Terminer",
"onboardingErrorNoSpecies": "Sélectionnez au moins une espèce",
"onboardingPrevious": "Précédent",
"onboardingCustomSpeciesSheetTitle": "Nouvelle espèce",
"onboardingCustomSpeciesNameLabel": "Nom de l'espèce",
"onboardingCustomSpeciesCategoriesLabel": "Catégories (au moins une)",
"onboardingCustomSpeciesAddCategory": "+ Ajouter une catégorie",

"speciesManagementTitle": "Espèces & catégories",
"speciesManagementCountFmt": "{species} espèce(s) · {categories} catégorie(s) actives",
"@speciesManagementCountFmt": {"placeholders": {"species": {"type": "int"}, "categories": {"type": "int"}}},
"speciesManagementAddSpecies": "+ Ajouter une espèce",
"speciesManagementRestoreTemplate": "Restaurer un template",
"speciesManagementRestoreTemplateSheetTitle": "Templates disponibles",
"speciesManagementRestoreTemplateEmpty": "Tous les templates sont déjà ajoutés.",
"speciesManagementArchivedSection": "Archivées",
"speciesManagementUnarchive": "Désarchiver",
"speciesManagementRename": "Renommer",
"speciesManagementArchive": "Archiver",
"speciesEditTitleFmt": "Modifier {name}",
"@speciesEditTitleFmt": {"placeholders": {"name": {"type": "String"}}},
"speciesEditCategoriesTitle": "Catégories",
"speciesEditAddCategory": "+ Ajouter une catégorie",
"speciesEditArchive": "Archiver l'espèce",
"speciesEditUnarchive": "Désarchiver l'espèce",
"speciesEditArchiveBlocked": "Au moins une espèce active est requise",
"categoryFormName": "Nom",
"categoryFormDefaultMinutes": "Durée par défaut (min)",
"categoryFormDefaultPrice": "Prix indicatif HT (€)",
"categoryFormPriceHelper": "Sera utilisé pour la facturation à venir",
"categoryFormSave": "Enregistrer",
"categoryFormArchive": "Archiver",
"categoryFormUnarchive": "Désarchiver",

"animalCountsEditorEmpty": "Aucune espèce active",
"animalCountsArchivedSection": "Catégories archivées",
"animalCountsClear": "Effacer",

"clientsListAnimalCountFmt": "{n} {species}",
"@clientsListAnimalCountFmt": {"placeholders": {"n": {"type": "int"}, "species": {"type": "String"}}},
"clientDetailAnimalCategoryFmt": "{count} {category}",
"@clientDetailAnimalCategoryFmt": {"placeholders": {"count": {"type": "int"}, "category": {"type": "String"}}},

"settingsAppAvatarTitle": "Logo de l'app",
"settingsAppAvatarSubtitle": "Affiché à l'accueil et dans les Paramètres",
"settingsBracketKmLabel": "Tranche kilométrique (km)"
```

- [ ] **Step 4: Regenerate l10n**

```bash
flutter gen-l10n
```

Expected: `lib/l10n/app_localizations*.dart` regenerated. Compile errors will appear elsewhere — fixed in later tasks.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/
git commit -m "i18n: neutralize vocabulary, add species/category/onboarding keys, update fr+en"
```

---

## Task 25 — `AnimalCountsBadges` widget (compact + detailed)

**Files:**
- Create: `lib/presentation/widgets/animal_counts_badges.dart`

Two display modes. Stateless.

- [ ] **Step 1: Implement**

```dart
// lib/presentation/widgets/animal_counts_badges.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/animal_count.dart';
import '../../state/providers.dart';

enum AnimalCountsBadgesMode { compact, detailed }

/// Renders a list of [AnimalCount] (or pre-snapshotted entries) keyed by
/// `categoryId`. In [AnimalCountsBadgesMode.compact], counts are summed by
/// species: e.g. "17 Mouton, 4 Cheval". In [AnimalCountsBadgesMode.detailed],
/// each species is followed by its category breakdown:
/// "Mouton — 5 Petit + 12 Grand".
///
/// Resolves category and species names from the in-memory
/// [allCategoriesByIdProvider] / [activeSpeciesProvider]. Counts whose
/// `categoryId` no longer resolves (truly deleted) are skipped silently.
class AnimalCountsBadges extends ConsumerWidget {
  final List<AnimalCount> counts;
  final AnimalCountsBadgesMode mode;
  final TextStyle? style;

  const AnimalCountsBadges({
    super.key,
    required this.counts,
    required this.mode,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (counts.isEmpty) return const SizedBox.shrink();
    final catLookup = ref.watch(categoryLookupProvider);
    return catLookup.when(
      data: (lookup) {
        final perSpecies = <String, _Bucket>{};
        for (final ac in counts) {
          if (ac.count == 0) continue;
          final entry = lookup[ac.categoryId];
          if (entry == null) continue;
          perSpecies
              .putIfAbsent(entry.speciesName, () => _Bucket())
              .add(entry.category.name, ac.count);
        }
        if (perSpecies.isEmpty) return const SizedBox.shrink();

        return Text(
          mode == AnimalCountsBadgesMode.compact
              ? perSpecies.entries
                  .map((e) => '${e.value.total} ${e.key}')
                  .join(', ')
              : perSpecies.entries
                  .map((e) =>
                      '${e.key} — ${e.value.formatBreakdown()}')
                  .join('  ·  '),
          style: style,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Bucket {
  int total = 0;
  final List<({String name, int count})> parts = [];
  void add(String name, int count) {
    total += count;
    parts.add((name: name, count: count));
  }

  String formatBreakdown() =>
      parts.map((p) => '${p.count} ${p.name}').join(' + ');
}
```

- [ ] **Step 2: Add a smoke widget test** (one test only — the codebase keeps widget tests minimal):

```dart
// test/widget/animal_counts_badges_test.dart
// (Create the file. Pump the widget with a ProviderScope that overrides
// categoryLookupProvider to return a fixed map. Assert the rendered text.)
```

Sample test:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/animal_category.dart';
import 'package:coup_laine/presentation/widgets/animal_counts_badges.dart';
import 'package:coup_laine/state/providers.dart';

void main() {
  testWidgets('compact mode sums per species', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryLookupProvider.overrideWith((ref) async => {
                1: (
                  speciesName: 'Mouton',
                  category: const AnimalCategory(
                    id: 1, speciesId: 1, name: 'Petit'),
                ),
                2: (
                  speciesName: 'Mouton',
                  category: const AnimalCategory(
                    id: 2, speciesId: 1, name: 'Grand'),
                ),
              }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AnimalCountsBadges(
              counts: [
                AnimalCount(categoryId: 1, count: 5),
                AnimalCount(categoryId: 2, count: 12),
              ],
              mode: AnimalCountsBadgesMode.compact,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('17 Mouton'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run**

```bash
flutter test test/widget/animal_counts_badges_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/animal_counts_badges.dart \
        test/widget/animal_counts_badges_test.dart
git commit -m "feat(widgets): AnimalCountsBadges compact and detailed modes"
```

---

## Task 26 — `AnimalCountsEditor` widget

**Files:**
- Create: `lib/presentation/widgets/animal_counts_editor.dart`

Stateful, value-based controlled widget. Renders one accordion section per active species; under each species, one numeric input per active category. Shows a separate read-only "archived categories" section for counts attached to categories that became archived after the user filled them — with a per-row "Effacer" action.

The widget is a controlled input: parent passes `value: List<AnimalCount>` and `onChanged: (List<AnimalCount> next) {}`. It does not own its own canonical state across rebuilds.

- [ ] **Step 1: Implement**

The implementation is straightforward but tedious. Skeleton:

```dart
// lib/presentation/widgets/animal_counts_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/animal_category.dart';
import '../../domain/models/animal_count.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';

class AnimalCountsEditor extends ConsumerWidget {
  final List<AnimalCount> value;
  final ValueChanged<List<AnimalCount>> onChanged;

  const AnimalCountsEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final speciesAsync = ref.watch(activeSpeciesProvider);
    final catsBySpeciesAsync = ref.watch(activeCategoriesBySpeciesProvider);
    final allCatsAsync = ref.watch(allCategoriesByIdProvider);

    return speciesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (speciesList) {
        if (speciesList.isEmpty) {
          return Text(l.animalCountsEditorEmpty);
        }
        // ... render per-species accordions, with onChanged emitting a fresh list ...
        // For each (species, category): a numeric TextField initialized to the
        // count from `value` (defaulting to 0 if absent). Editing emits a new
        // list with that categoryId set.
        //
        // After active sections, render an "archivées" section listing
        // counts whose categoryId resolves to an archived category. Each
        // row has a "Effacer" button that removes the entry from `value`.
        //
        // (Full implementation — ~150 lines — left to the engineer; the
        // contract is the value/onChanged shape and the visual layout
        // described in the spec section 5.1.)
        return const Placeholder();
      },
    );
  }
}
```

Replace the `Placeholder` with the full UI per spec section 5.1. Key invariants:

- `onChanged` always emits a normalized list (call `normalizeAnimalCounts` before emit) — no zero counts in the output, no duplicates.
- TextFields use `keyboardType: TextInputType.number`, `inputFormatters: [FilteringTextInputFormatter.digitsOnly]`.
- Empty input parses as `0` (i.e. removes the entry).
- Negative numbers are not accepted.
- The "archived categories" header only shows if at least one entry has an archived category.

- [ ] **Step 2: Smoke widget test**

```dart
// test/widget/animal_counts_editor_test.dart
// One test: pump with two seeded categories, type "5" in one input, verify
// onChanged was called with [AnimalCount(categoryId, 5)].
```

- [ ] **Step 3: Run** `flutter test test/widget/animal_counts_editor_test.dart`. Iterate until green.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/animal_counts_editor.dart \
        test/widget/animal_counts_editor_test.dart
git commit -m "feat(widgets): AnimalCountsEditor with archived-categories section"
```

---

## Task 27 — `AvatarPicker` widget

**Files:**
- Create: `lib/presentation/widgets/avatar_picker.dart`

Horizontal scrollable list of chips, one per `kAvatarKeys` entry. Selected chip is visually highlighted. Tap → emits the new key.

- [ ] **Step 1: Implement**

```dart
// lib/presentation/widgets/avatar_picker.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../core/avatar_icons.dart';

class AvatarPicker extends StatelessWidget {
  final String? selectedKey;
  final ValueChanged<String> onSelect;

  const AvatarPicker({
    super.key,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final current = selectedKey ?? kDefaultAvatarKey;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kAvatarKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final key = kAvatarKeys[i];
          final isSelected = key == current;
          return GestureDetector(
            onTap: () => onSelect(key),
            child: Container(
              width: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colors.primary.withOpacity(0.15)
                    : theme.colors.muted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colors.primary
                      : theme.colors.border,
                ),
              ),
              child: Icon(
                iconForAvatarKey(key),
                size: 28,
                color: isSelected
                    ? theme.colors.primary
                    : theme.colors.foreground,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Commit** (no test — pure layout)

```bash
git add lib/presentation/widgets/avatar_picker.dart
git commit -m "feat(widgets): AvatarPicker horizontal chip selector"
```

---

## Task 28 — `AnimalCategoryFormSheet` and `CustomSpeciesFormSheet`

**Files:**
- Create: `lib/presentation/settings/animal_category_form_sheet.dart`
- Create: `lib/presentation/onboarding/custom_species_form_sheet.dart`

Both are bottom sheets used in onboarding and Settings. Stateless façades around stateful editors.

- [ ] **Step 1: `AnimalCategoryFormSheet`**

```dart
// lib/presentation/settings/animal_category_form_sheet.dart
//
// Form fields:
//   - Name (required)
//   - Default minutes (numeric, optional)
//   - Default price in € (numeric, optional; helper text shown)
// Returns: ({String name, int? defaultMinutes, int? defaultPriceCents})
//
// Used both for "+ Add category" and "Edit category" — caller passes
// initialValues (or null for create).
```

Implementation: a `StatefulWidget` with three controllers, validate on save, pop with a record value. Use `FButton.primary` for Save and a secondary destructive Archive button if `initial != null`.

- [ ] **Step 2: `CustomSpeciesFormSheet`**

```dart
// lib/presentation/onboarding/custom_species_form_sheet.dart
//
// Form fields:
//   - Species name (required)
//   - At least one category (each a name; minutes/price optional and editable
//     later in Settings)
// Returns: ({String name, List<String> categoryNames})
//
// UI: a single TextField for name, then a dynamic list of category-name
// inputs (add / remove). The Save button is disabled until name and
// at least one non-empty category name are entered.
```

- [ ] **Step 3: No tests** (mechanical UI — covered later by smoke through onboarding flow).

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/settings/animal_category_form_sheet.dart \
        lib/presentation/onboarding/custom_species_form_sheet.dart
git commit -m "feat(widgets): category and custom-species form sheets"
```

---

## Task 29 — Rewrite `OnboardingScreen` as 2-step wizard

**Files:**
- Modify: `lib/presentation/onboarding/onboarding_screen.dart`

The screen becomes a `ConsumerStatefulWidget` holding:
- `int _step` (0 or 1)
- `GeocodingResult? _picked`
- `Set<int> _seedSpeciesActive` — indices into `kSpeciesSeeds`
- `List<({String name, List<String> categoryNames})> _customSpecies`
- `String _avatarKey` (default `kDefaultAvatarKey`)

- [ ] **Step 1: Replace the file with the wizard**

Top-level structure:

```dart
class OnboardingScreen extends ConsumerStatefulWidget { ... }
class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  GeocodingResult? _picked;
  final Set<int> _seedSpeciesActive = {};
  final List<_CustomSpeciesDraft> _customSpecies = [];
  String _avatarKey = kDefaultAvatarKey;
  bool _saving = false;

  bool get _step1Ready => _picked != null;
  bool get _step2Ready =>
      _seedSpeciesActive.isNotEmpty || _customSpecies.isNotEmpty;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider);
    final speciesRepo = ref.read(speciesRepositoryProvider);
    final catsRepo = ref.read(animalCategoryRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);
    try {
      await db.transaction(() async {
        // 1. Insert checked seed species + their categories.
        for (final i in _seedSpeciesActive) {
          final seed = kSpeciesSeeds[i];
          final speciesId = await speciesRepo.insert(name: seed.name);
          for (final cat in seed.categories) {
            await catsRepo.insert(speciesId: speciesId, name: cat.name);
          }
        }
        // 2. Insert custom species + their categories.
        for (final cs in _customSpecies) {
          final speciesId = await speciesRepo.insert(name: cs.name);
          for (final catName in cs.categoryNames) {
            await catsRepo.insert(speciesId: speciesId, name: catName);
          }
        }
        // 3. Save Settings.
        await settingsRepo.save(Settings(
          baseCoordinates: _picked!.coordinates,
          baseAddressLabel: _picked!.label,
          seasonStartedAt: DateTime.now(),
          appAvatarKey: _avatarKey,
        ));
      });
      if (!mounted) return;
      context.go('/clients');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  // ... build = IndexedStack(_step), with two children _buildStep1, _buildStep2 ...
}

class _CustomSpeciesDraft {
  final String name;
  final List<String> categoryNames;
  const _CustomSpeciesDraft({required this.name, required this.categoryNames});
}
```

`_buildStep1` mirrors the current screen's body but:
- replace `sheep-mascot.png` `Image.asset(...)` with a centered `Icon(FIcons.compass, size: 96, ...)` (placeholder neutral visual; the spec accepts this);
- swap `l.onboardingCta` → `l.onboardingStep1Cta`;
- the CTA invokes `setState(() => _step = 1)` instead of `_confirm`.

`_buildStep2` shows three blocks:
1. `AppSectionCard` "Vos espèces" with the seed list (each row = a tile with name and a sub-text listing seed category names; checkbox to toggle); plus "+ Ajouter une espèce personnalisée" → opens `CustomSpeciesFormSheet`, on save adds a `_CustomSpeciesDraft` to `_customSpecies`.
2. `AppSectionCard` "Logo de l'app" → `AvatarPicker` with `selectedKey: _avatarKey`.
3. CTA "Terminer" (loading=`_saving`, disabled if `!_step2Ready`) → `_confirm`.

Plus a "Précédent" button at the top-left of step 2 to set `_step = 0`.

- [ ] **Step 2: Run** `flutter analyze lib/presentation/onboarding/`. Fix imports.

- [ ] **Step 3: Manual smoke test** (no widget test for the full flow — too heavy):
  - Run `flutter run` on a fresh app data directory.
  - Verify the wizard, address selection, species selection, custom species creation, avatar selection, and "Terminer" → land on `/clients`.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/onboarding/onboarding_screen.dart
git commit -m "feat(onboarding): 2-step wizard — address then species & avatar"
```

---

## Task 30 — `SpeciesManagementScreen` + route

**Files:**
- Create: `lib/presentation/settings/species_management_screen.dart`
- Modify: `lib/core/routing/app_router.dart`
- Modify: `lib/l10n/app_fr.arb` and `lib/l10n/app_en.arb` if a key is missing (added in Task 24, double-check).

- [ ] **Step 1: Implement `SpeciesManagementScreen`**

`ConsumerStatefulWidget` (or `ConsumerWidget` if no local state). Pulls
`activeSpeciesProvider` and a similar `archivedSpeciesProvider` (add it
in `state/providers.dart` if missing — pattern: `FutureProvider` calling
`speciesRepositoryProvider.listArchived()`). Layout per spec section 4:

- Header: "Espèces & catégories" (`l.speciesManagementTitle`).
- Section "Actives": `ListView` of cards. Each card: species name, sub-text "X catégories — name1, name2", trailing `⋮` menu (Renommer / Archiver / Désarchiver — only the relevant items). Tap → push `/settings/species/$id`.
- Bottom button: "+ Ajouter une espèce" → `CustomSpeciesFormSheet`, on save inserts via repo (transactional: species + categories).
- Discreet text button: "Restaurer un template" → bottom sheet listing `kSpeciesSeeds` filtered to those whose name is not yet present in active+archived species. Tap on a template inserts the species and its categories transactionally.
- Section "Archivées" (collapsible, default closed if non-empty): one row per archived species with "Désarchiver".

Invalidate `activeSpeciesProvider` (and the archived one) after each mutation.

- [ ] **Step 2: Add the route** in `app_router.dart`

```dart
GoRoute(
  path: 'species',
  builder: (_, __) => const SpeciesManagementScreen(),
  routes: [
    GoRoute(
      path: ':id',
      builder: (_, state) => SpeciesEditScreen(
        speciesId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
),
```

(Place it under the existing `/settings` branch, mirroring the project's existing nested-route style.)

- [ ] **Step 3: Run** `flutter analyze`. Fix.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/settings/species_management_screen.dart \
        lib/core/routing/app_router.dart
git commit -m "feat(settings): SpeciesManagementScreen at /settings/species"
```

---

## Task 31 — `SpeciesEditScreen`

**Files:**
- Create: `lib/presentation/settings/species_edit_screen.dart`

`ConsumerStatefulWidget` taking `speciesId`. Reads the species and its categories. Renders three zones per spec section 4:

1. Identity zone — `TextField` for the name (saves on blur or via Save button); "Archiver l'espèce" / "Désarchiver l'espèce" button. The Archive button is disabled and tooltip-explained when this is the only active species (check via `speciesRepository.countActive()`).
2. Categories list — one row per category (active + archived inline, or two sub-sections "Actives" / "Archivées"). Each active row shows: editable name (inline), minutes input, price input, archive icon button. Archived rows show name + "Désarchiver".
3. Bottom button "+ Ajouter une catégorie" → `AnimalCategoryFormSheet` create-mode → on save inserts via repo.

Invalidate `activeCategoriesBySpeciesProvider`, `allCategoriesByIdProvider`, and `categoryLookupProvider` after each mutation.

- [ ] **Step 1: Implement** the screen.

- [ ] **Step 2: Run** `flutter analyze`. Fix.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/settings/species_edit_screen.dart
git commit -m "feat(settings): SpeciesEditScreen — species identity + category CRUD"
```

---

## Task 32 — Restructure `SettingsScreen`

**Files:**
- Modify: `lib/presentation/settings/settings_screen.dart`

Apply spec section 4 changes:
- Add an "App avatar" sub-block inside the existing "Apparence" section, using `AvatarPicker`. Bind to `Settings.appAvatarKey`. Save via `settingsRepositoryProvider.save(...)` on change.
- Add a clickable card "Espèces & catégories" with the count fmt, navigating to `/settings/species`.
- Remove the two minutes-per inputs from "Valeurs par défaut". Keep `defaultRadiusKm`, `travelFeeEurosPerBracket`, and add `bracketKm` as a numeric input (`l.settingsBracketKmLabel`).
- In the "Marqueurs" section, rename the "Sans moutons" entry: use `l.settingsMarkerNoAnimals` and bind to `markerNoAnimalsColor`.

- [ ] **Step 1: Apply edits.**

- [ ] **Step 2: Run** `flutter analyze`. Fix.

- [ ] **Step 3: Manual smoke**: open Settings on a freshly-onboarded app, verify each section renders, the avatar picker reflects the choice made at onboarding, and the species link navigates correctly.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/settings/settings_screen.dart
git commit -m "feat(settings): avatar picker, species link, restructured defaults, markerNoAnimals rename"
```

---

## Task 33 — Update `client_form_screen`

**Files:**
- Modify: `lib/presentation/clients/client_form_screen.dart`

Replace the two numeric inputs with `AnimalCountsEditor`. Track local state in the form's stateful widget; on save, persist `client.animals` as the editor's last emitted value.

- [ ] **Step 1: Edits**:
  - Remove `_smallController`, `_largeController` (if names match).
  - Add `List<AnimalCount> _animals = client?.animals ?? const [];`.
  - In the form's section card with title `l.clientFormSectionAnimals` (renamed in Task 24), drop the two `TextField`s and place an `AnimalCountsEditor(value: _animals, onChanged: (next) => setState(() => _animals = next))`.
  - On save, pass `animals: _animals` to the `Client(...)` constructor.

- [ ] **Step 2: Run** `flutter analyze`. Fix.

- [ ] **Step 3: Manual smoke**: create + edit a client, verify counts persist, verify archived categories with prior counts show in the read-only section.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/clients/client_form_screen.dart
git commit -m "feat(clients): client form uses AnimalCountsEditor"
```

---

## Task 34 — Update display screens: detail / list / pin popup / history

**Files:**
- Modify: `lib/presentation/clients/client_detail_screen.dart`
- Modify: `lib/presentation/clients/clients_list_screen.dart`
- Modify: `lib/presentation/map/client_pin_popup.dart`
- Modify: `lib/presentation/clients/client_history_screen.dart`

All four screens currently render sheep-specific text. Replace with `AnimalCountsBadges`:
- `clients_list_screen.dart` row: `AnimalCountsBadges(counts: client.animals, mode: AnimalCountsBadgesMode.compact)`.
- `client_pin_popup.dart`: same compact mode.
- `client_detail_screen.dart` "Animaux" / status block: detailed mode.
- `client_history_screen.dart` per-row breakdown: detailed mode (operating on `entry.animals` for manual entries or `stop.actual ?? stop.planned` for tour stops, transformed to `List<AnimalCount>` via `entry.animals.map((a) => AnimalCount(categoryId: a.categoryId, count: a.count))`).

- [ ] **Step 1: Update each file** by removing the old format strings (`clientDetailSheepCountFmt`, `clientsListSheepCountFmt`, `clientDetailHistoryItemFmt`) and inserting the badge widget.

- [ ] **Step 2: Run** `flutter analyze`. Fix any remaining l10n key references.

- [ ] **Step 3: Manual smoke** of each screen.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/clients/client_detail_screen.dart \
        lib/presentation/clients/clients_list_screen.dart \
        lib/presentation/map/client_pin_popup.dart \
        lib/presentation/clients/client_history_screen.dart
git commit -m "feat(clients): use AnimalCountsBadges across detail, list, pin popup, history"
```

---

## Task 35 — Update `manual_history_entry_sheet`

**Files:**
- Modify: `lib/presentation/clients/manual_history_entry_sheet.dart`

Replace the two numeric inputs with `AnimalCountsEditor`. On save, transform `List<AnimalCount>` to `List<TourStopAnimal>` by looking up snapshots in `categoryLookupProvider` (read-once via `ref.read`).

- [ ] **Step 1: Wire `AnimalCountsEditor`** into the sheet.

- [ ] **Step 2: On save**, transform:

```dart
final lookup = await ref.read(categoryLookupProvider.future);
final animals = [
  for (final ac in _animals)
    if (lookup[ac.categoryId] != null)
      TourStopAnimal(
        categoryId: ac.categoryId,
        count: ac.count,
        categoryNameSnapshot: lookup[ac.categoryId]!.category.name,
        speciesNameSnapshot: lookup[ac.categoryId]!.speciesName,
        minutesSnapshot: lookup[ac.categoryId]!.category.defaultMinutes ?? 0,
      ),
];
```

Pass `animals` to the `ManualHistoryEntry` constructor.

- [ ] **Step 3: Run** `flutter analyze`. Fix.

- [ ] **Step 4: Manual smoke**: create + edit + delete a manual entry, verify history shows correct breakdown.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/clients/manual_history_entry_sheet.dart
git commit -m "feat(history): manual entry sheet uses AnimalCountsEditor with snapshots"
```

---

## Task 36 — Update tour screens: draft, completion, detail, picker

**Files:**
- Modify: `lib/presentation/tours/tour_draft_screen.dart`
- Modify: `lib/state/tour_draft_controller.dart`
- Modify: `lib/presentation/tours/tour_completion_screen.dart`
- Modify: `lib/presentation/tours/tour_detail_screen.dart`
- Modify: `lib/presentation/widgets/waiting_clients_multi_picker.dart`

- [ ] **Step 1: `tour_draft_controller`** — when calling `BuildTourDraft`, pass the `categoryLookup` map via `ref.read(categoryLookupProvider.future)`. Update any places where the controller surfaces planned counts to consumers — they now expose `List<TourStopAnimal>` instead of the old pair.

- [ ] **Step 2: `tour_draft_screen`** — replace any `plannedSmall/Large` display with `AnimalCountsBadges` (compact) over the stop's planned list (as `List<AnimalCount>` derived from `TourStopAnimal`). Update the summary line (`tourDraftSummaryTotal`): `{shear}` minutes is computed by the duration estimator (already updated in Task 21); the wording change is in l10n only (Task 24).

- [ ] **Step 3: `tour_completion_screen`** — replace the two numeric inputs with an editor that:
  - iterates the stop's planned list (rendering one numeric input per entry, prefilled with `planned[i].count`),
  - includes a "+ Autre catégorie" button below to add an off-plan entry: opens a sheet to pick an active category (any species) and a count,
  - emits a `List<TourStopAnimal>` with `actual` snapshots reusing the same name/species/minutes as the matched planned entry (for off-plan additions, look up via `categoryLookupProvider`).

  On confirm, persist `actual: List<TourStopAnimal>` per stop via `TourRepository.markCompleted` (signature update — pass actuals as a `Map<int stopId, List<TourStopAnimal>>` or the existing parameter shape with the new type).

- [ ] **Step 4: `tour_detail_screen`** — display per-stop animals via `AnimalCountsBadges` (compact under each stop card; detailed in the per-stop sheet if any). Use `stop.actual ?? stop.planned` to choose the visible list.

- [ ] **Step 5: `waiting_clients_multi_picker`** — on each row, render `AnimalCountsBadges(counts: client.animals, mode: compact)` next to the client name. No filter logic — out of scope.

- [ ] **Step 6: Run** `flutter analyze`. Fix imports and stragglers.

- [ ] **Step 7: Manual smoke**: build a tour, run it through completion, view the detail. Verify totals are sane and the planning summary uses "Intervention".

- [ ] **Step 8: Commit**

```bash
git add lib/presentation/tours/ lib/state/tour_draft_controller.dart \
        lib/presentation/widgets/waiting_clients_multi_picker.dart
git commit -m "feat(tours): per-category counts in draft, completion, detail and picker"
```

---

## Task 37 — Update `intervention.dart` and any remaining glue

**Files:**
- Modify: `lib/domain/models/intervention.dart`
- Modify: any consumer of intervention (`client_history_screen.dart`, providers, etc.)

`Intervention` likely exposes a unified shape across tour-stops and manual entries, with sheep counters. Update its fields to expose `List<TourStopAnimal>` (or `List<AnimalCount>`, depending on existing shape).

- [ ] **Step 1: Read** `lib/domain/models/intervention.dart`.

- [ ] **Step 2: Update** the fields and any factories that construct it from rows. Keep the union shape (`kind: tour | manual`) — only the counters change.

- [ ] **Step 3: Update consumers** if any read `.sheepCountSmall` etc.

- [ ] **Step 4: Run** `flutter analyze`. Fix.

- [ ] **Step 5: Run all tests**

```bash
flutter test
```

Address remaining failures. They should be limited to assertion strings, fixture shapes, and a handful of l10n key renames in tests.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/models/intervention.dart <other files touched>
git commit -m "refactor(domain): Intervention exposes per-category animal lists"
```

---

## Task 38 — Final sweep: tests + analyze + smoke

**Files:** any.

- [ ] **Step 1: Run analyze**

```bash
flutter analyze
```

Expected: 0 errors, warnings allowed.

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: 100% green. If any test still references `sheepCountSmall`, `sheepCountLarge`, `markerNoSheepColor`, `clientStatusNoSheep`, `clientFormSectionShearing`, etc., fix it.

- [ ] **Step 3: Manual smoke checklist**

Run on a fresh app data dir (delete the SQLite file). Verify:

1. Onboarding step 1 collects the address.
2. Onboarding step 2 lists Mouton/Cheval/Bovin/Caprin with their categories. Cocher Mouton + une espèce custom "Lapin" avec catégorie "Lapin nain". Choisir un avatar.
3. Land on `/clients`. Empty list.
4. Create a client. The Animaux section shows two sections (Mouton, Lapin) with category inputs. Enter `5 Petit, 12 Grand, 2 Lapin nain`. Save.
5. Client list shows "17 Mouton, 2 Lapin" (or similar compact).
6. Create a tour with this client. Verify the tour draft summary uses "Intervention". Save the tour.
7. Mark the tour as completed: actuals editor pre-fills 5/12/2 in the right rows. Adjust "Lapin nain" to 3, add a "+ Autre catégorie" → "Petit" with count 1. Confirm.
8. Open client detail → history. Latest line shows the breakdown including the off-plan addition.
9. Open Settings → Espèces & catégories. Rename "Lapin nain" → "Lapin nain modifié". Verify the client detail / history still shows the original snapshot in past entries, and the new name in the editor.
10. Archive "Cheval" species (if you didn't activate it, skip). Verify it disappears from new editors but the management screen lists it under "Archivées".
11. Open Settings → Apparence → change avatar. Verify it persists.

- [ ] **Step 4: Commit a final note** if anything was tweaked during smoke

```bash
git status
# If clean, no commit. If something was fixed:
git commit -m "fix: <concise>"
```

- [ ] **Step 5: Open PR**

```bash
git push -u origin feat/multi-praticien-pivot
gh pr create --title "feat: multi-praticien pivot" --body "$(cat <<'EOF'
## Summary
- Pivot from sheep-shearing-only to generic itinerant animal practitioner.
- Species → AnimalCategory hierarchy with full CRUD (rename, archive, custom).
- 2-step onboarding wizard (address, species + avatar).
- Customizable app avatar (curated FIcons set).
- Vocabulary neutralized: tonte → intervention, mouton → animal.
- Schema reset v8 → v9 with drop+recreate (no prod users).

## Spec
`docs/superpowers/specs/2026-04-30-multi-praticien-pivot-design.md`

## Test plan
- [ ] flutter analyze passes
- [ ] flutter test 100% green
- [ ] Onboarding wizard smoke (steps 1 + 2, custom species, avatar)
- [ ] Client CRUD with multi-species counts
- [ ] Tour draft → completion with off-plan additions
- [ ] Settings species/category CRUD (rename, archive, restore template)
- [ ] Snapshots preserved after rename/archive

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Spec coverage check (self-review)

| Spec section | Covered by task(s) |
|---|---|
| Architecture & domain (Species, AnimalCategory, AnimalCount, TourStopAnimal) | 2, 3 |
| Updated Client / TourStop / ManualHistoryEntry / Settings | 9, 10, 11, 12 |
| Catégories archivées (masquage en saisie, lecture conservée) | 26 (editor), 25 (badges) |
| Espèce active obligatoire | 31 (archive guard) |
| Schéma Drift (Species, AnimalCategories tables; clients/tour_stops/manual modified; Settings updated) | 8 |
| JSON converters | 5 |
| Helpers de normalisation | 4 |
| Onboarding wizard 2 étapes | 29 |
| Espèces seedées (constantes) | 7 |
| `kSpeciesSeeds` Mouton/Cheval/Bovin/Caprin | 7 |
| Settings restructure (avatar, species link, default values cleaned, marker rename) | 32 |
| `SpeciesManagementScreen` | 30 |
| `SpeciesEditScreen` | 31 |
| `client_form` | 33 |
| Display (detail / list / popup / history) | 34 |
| `manual_history_entry_sheet` | 35 |
| Tour screens (draft / completion / detail / picker) | 36 |
| `BuildTourDraft` snapshots | 20 |
| `TourDurationEstimator` | 21 |
| `ClientStatus` rename | 22 |
| Repositories (Species, AnimalCategory, Client, Tour, ManualHistory, Settings) | 13, 14, 15, 16, 17, 18, 19 |
| `Intervention` glue | 37 |
| Avatar icons + AvatarPicker | 6, 27 |
| l10n delete / rename / add | 24 |
| Reset v8→v9 migration | 8 |
| `species_seeds.dart` constants | 7 |
| Test fixture helper | 18 (introduces `seedTestSpeciesAndCategories`) |
| Final smoke + PR | 38 |

All spec sections map to at least one task.
