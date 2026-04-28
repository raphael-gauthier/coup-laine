# Phase 2 — Persistence (drift)

**Goal:** SQLite schema via drift, with four repositories (Settings, Client, DistanceMatrix, Tour) all integration-tested against an in-memory database.

**Verification at end of phase:** `flutter test test/data/` is green; the four repositories cover the cases in [spec §07-testing](../../specs/2026-04-28-coupe-laine-mvp-design/07-testing.md#repository-tests).

---

## Task 2.1: Drift table definitions

**Files:**
- Create: `lib/infra/db/tables.dart`

- [ ] **Step 1: Write the table definitions**

```dart
// lib/infra/db/tables.dart
import 'package:drift/drift.dart';

@DataClassName('SettingsRow')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  IntColumn get id => integer().check(id.equals(1))();
  TextColumn get baseAddressLabel => text()();
  RealColumn get baseLat => real()();
  RealColumn get baseLon => real()();
  IntColumn get defaultRadiusKm => integer().withDefault(const Constant(15))();
  IntColumn get defaultMinutesPerSheep =>
      integer().withDefault(const Constant(20))();
  IntColumn get travelFeeEurosPerBracket =>
      integer().withDefault(const Constant(8))();
  IntColumn get bracketKm => integer().withDefault(const Constant(10))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ClientRow')
class ClientsTable extends Table {
  @override
  String get tableName => 'clients';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get addressLabel => text()();
  TextColumn get postcode => text()();
  TextColumn get city => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  IntColumn get sheepCount => integer().withDefault(const Constant(0))();
  IntColumn get minutesPerSheepOverride => integer().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isWaiting => boolean().withDefault(const Constant(false))();
  IntColumn get lastShearingDate => integer().nullable()();
  BoolColumn get needsDistanceRecompute =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('DistanceMatrixRow')
class DistanceMatrixTable extends Table {
  @override
  String get tableName => 'distance_matrix';

  /// 0 = base, otherwise client.id
  IntColumn get fromId => integer()();
  IntColumn get toId => integer()();
  IntColumn get distanceMeters => integer()();
  IntColumn get durationSeconds => integer()();
  IntColumn get computedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {fromId, toId};
}

@DataClassName('TourRow')
class ToursTable extends Table {
  @override
  String get tableName => 'tours';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get plannedDate => integer()();
  IntColumn get startTimeMinutes => integer()();
  TextColumn get status => text()(); // 'planned' | 'completed'
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
  IntColumn get sheepCountSnapshot => integer()();
  IntColumn get minutesPerSheepSnapshot => integer()();
  IntColumn get feeShareCents => integer()();
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/infra/db/tables.dart
git commit -m "feat(db): drift table definitions"
```

---

## Task 2.2: Drift database class + codegen

**Files:**
- Create: `lib/infra/db/app_database.dart`

- [ ] **Step 1: Write the database class**

```dart
// lib/infra/db/app_database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SettingsTable,
    ClientsTable,
    DistanceMatrixTable,
    ToursTable,
    TourStopsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'coupe_laine.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
```

- [ ] **Step 2: Run drift codegen**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/infra/db/app_database.g.dart` is generated, no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/infra/db/app_database.dart lib/infra/db/app_database.g.dart
git commit -m "feat(db): app database with codegen"
```

---

## Task 2.3: SettingsRepository

**Files:**
- Create: `lib/data/repositories/settings_repository.dart`
- Create: `test/data/settings_repository_test.dart`

The repository wraps drift access and exposes domain `Settings` objects.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/settings_repository_test.dart
import 'package:coupe_laine/data/repositories/settings_repository.dart';
import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:coupe_laine/domain/models/settings.dart';
import 'package:coupe_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('returns null when no settings row exists', () async {
    expect(await repo.read(), isNull);
  });

  test('saves and reads settings round-trip', () async {
    const settings = Settings(
      baseCoordinates: Coordinates(lat: 48.1, lon: -3.0),
      baseAddressLabel: '1 rue de la Lande, 22000 Saint-Brieuc',
    );
    await repo.save(settings);
    final read = await repo.read();
    expect(read, isNotNull);
    expect(read!.baseAddressLabel, settings.baseAddressLabel);
    expect(read.baseCoordinates, settings.baseCoordinates);
    expect(read.defaultRadiusKm, 15);
  });

  test('overwrites existing settings', () async {
    await repo.save(const Settings(
      baseCoordinates: Coordinates(lat: 48.0, lon: -3.0),
      baseAddressLabel: 'Old',
    ));
    await repo.save(const Settings(
      baseCoordinates: Coordinates(lat: 48.5, lon: -2.5),
      baseAddressLabel: 'New',
      defaultRadiusKm: 20,
    ));
    final read = await repo.read();
    expect(read!.baseAddressLabel, 'New');
    expect(read.defaultRadiusKm, 20);
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/data/settings_repository_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/data/repositories/settings_repository.dart
import 'package:drift/drift.dart';

import '../../domain/models/coordinates.dart';
import '../../domain/models/settings.dart';
import '../../infra/db/app_database.dart';

class SettingsRepository {
  final AppDatabase _db;
  SettingsRepository(this._db);

  Future<Settings?> read() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row == null) return null;
    return Settings(
      baseCoordinates: Coordinates(lat: row.baseLat, lon: row.baseLon),
      baseAddressLabel: row.baseAddressLabel,
      defaultRadiusKm: row.defaultRadiusKm,
      defaultMinutesPerSheep: row.defaultMinutesPerSheep,
      travelFeeEurosPerBracket: row.travelFeeEurosPerBracket,
      bracketKm: row.bracketKm,
    );
  }

  Future<void> save(Settings settings) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            id: const Value(1),
            baseAddressLabel: settings.baseAddressLabel,
            baseLat: settings.baseCoordinates.lat,
            baseLon: settings.baseCoordinates.lon,
            defaultRadiusKm: Value(settings.defaultRadiusKm),
            defaultMinutesPerSheep: Value(settings.defaultMinutesPerSheep),
            travelFeeEurosPerBracket: Value(settings.travelFeeEurosPerBracket),
            bracketKm: Value(settings.bracketKm),
          ),
        );
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/data/settings_repository_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/settings_repository.dart test/data/settings_repository_test.dart
git commit -m "feat(data): settings repository"
```

---

## Task 2.4: ClientRepository

**Files:**
- Create: `lib/data/repositories/client_repository.dart`
- Create: `test/data/client_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/client_repository_test.dart
import 'package:coupe_laine/data/repositories/client_repository.dart';
import 'package:coupe_laine/domain/models/client.dart';
import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:coupe_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Client _newClient({
  String name = 'Le Gall',
  bool isWaiting = false,
  bool needsDistanceRecompute = false,
}) {
  return Client(
    id: 0, // ignored on insert
    name: name,
    addressLabel: '1 rue, 29000 Quimper',
    postcode: '29000',
    city: 'Quimper',
    coordinates: const Coordinates(lat: 48.0, lon: -4.1),
    sheepCount: 12,
    isWaiting: isWaiting,
    needsDistanceRecompute: needsDistanceRecompute,
  );
}

void main() {
  late AppDatabase db;
  late ClientRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ClientRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert assigns id and reads back', () async {
    final id = await repo.insert(_newClient());
    expect(id, greaterThan(0));
    final read = await repo.findById(id);
    expect(read, isNotNull);
    expect(read!.name, 'Le Gall');
  });

  test('listWaiting returns only waiting clients without recompute flag',
      () async {
    await repo.insert(_newClient(name: 'A', isWaiting: true));
    await repo.insert(_newClient(name: 'B', isWaiting: false));
    await repo.insert(_newClient(
      name: 'C',
      isWaiting: true,
      needsDistanceRecompute: true,
    ));
    final waiting = await repo.listWaitingReady();
    expect(waiting.map((c) => c.name), unorderedEquals(['A']));
  });

  test('toggleWaiting flips the flag', () async {
    final id = await repo.insert(_newClient(isWaiting: false));
    await repo.setWaiting(id: id, isWaiting: true);
    expect((await repo.findById(id))!.isWaiting, isTrue);
    await repo.setWaiting(id: id, isWaiting: false);
    expect((await repo.findById(id))!.isWaiting, isFalse);
  });

  test('delete removes the client', () async {
    final id = await repo.insert(_newClient());
    await repo.delete(id);
    expect(await repo.findById(id), isNull);
  });

  test('updateLocation marks needsDistanceRecompute', () async {
    final id = await repo.insert(_newClient());
    await repo.updateAddress(
      id: id,
      addressLabel: '2 rue, 29000 Quimper',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48.05, lon: -4.05),
    );
    final read = await repo.findById(id);
    expect(read!.needsDistanceRecompute, isTrue);
    expect(read.coordinates.lat, 48.05);
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/data/client_repository_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/data/repositories/client_repository.dart
import 'package:drift/drift.dart';

import '../../domain/models/client.dart';
import '../../domain/models/coordinates.dart';
import '../../infra/db/app_database.dart';

class ClientRepository {
  final AppDatabase _db;
  ClientRepository(this._db);

  Future<int> insert(Client c) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.into(_db.clientsTable).insert(
          ClientsTableCompanion.insert(
            name: c.name,
            phone: Value(c.phone),
            addressLabel: c.addressLabel,
            postcode: c.postcode,
            city: c.city,
            lat: c.coordinates.lat,
            lon: c.coordinates.lon,
            sheepCount: Value(c.sheepCount),
            minutesPerSheepOverride: Value(c.minutesPerSheepOverride),
            notes: Value(c.notes),
            isWaiting: Value(c.isWaiting),
            lastShearingDate: Value(
              c.lastShearingDate?.millisecondsSinceEpoch,
            ),
            needsDistanceRecompute:
                const Value(true), // new clients always need matrix sync
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<Client?> findById(int id) async {
    final row = await (_db.select(_db.clientsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<Client>> listAll() async {
    final rows = await (_db.select(_db.clientsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Client>> listWaitingReady() async {
    final rows = await (_db.select(_db.clientsTable)
          ..where((t) =>
              t.isWaiting.equals(true) &
              t.needsDistanceRecompute.equals(false)))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Client>> listNeedingRecompute() async {
    final rows = await (_db.select(_db.clientsTable)
          ..where((t) => t.needsDistanceRecompute.equals(true)))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<void> setWaiting({required int id, required bool isWaiting}) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      ClientsTableCompanion(
        isWaiting: Value(isWaiting),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateAddress({
    required int id,
    required String addressLabel,
    required String postcode,
    required String city,
    required Coordinates coordinates,
  }) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      ClientsTableCompanion(
        addressLabel: Value(addressLabel),
        postcode: Value(postcode),
        city: Value(city),
        lat: Value(coordinates.lat),
        lon: Value(coordinates.lon),
        needsDistanceRecompute: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateBasics({
    required int id,
    required String name,
    String? phone,
    required int sheepCount,
    int? minutesPerSheepOverride,
    String? notes,
  }) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      ClientsTableCompanion(
        name: Value(name),
        phone: Value(phone),
        sheepCount: Value(sheepCount),
        minutesPerSheepOverride: Value(minutesPerSheepOverride),
        notes: Value(notes),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setRecomputeDone(int id) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      const ClientsTableCompanion(
        needsDistanceRecompute: Value(false),
      ),
    );
  }

  Future<void> setRecomputePending(int id) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      const ClientsTableCompanion(
        needsDistanceRecompute: Value(true),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.clientsTable)..where((t) => t.id.equals(id))).go();
  }

  Client _toDomain(ClientRow row) => Client(
        id: row.id,
        name: row.name,
        phone: row.phone,
        addressLabel: row.addressLabel,
        postcode: row.postcode,
        city: row.city,
        coordinates: Coordinates(lat: row.lat, lon: row.lon),
        sheepCount: row.sheepCount,
        minutesPerSheepOverride: row.minutesPerSheepOverride,
        notes: row.notes,
        isWaiting: row.isWaiting,
        lastShearingDate: row.lastShearingDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.lastShearingDate!),
        needsDistanceRecompute: row.needsDistanceRecompute,
      );
}
```

> Note: the `insert` always sets `needsDistanceRecompute = true` regardless of the input. Newly created clients always need their matrix rows computed. The test fixture's `needsDistanceRecompute: false` is therefore ignored on insert; the test for `listWaitingReady` accounts for this by inserting clients then expecting the recompute-flagged ones to be excluded.

> Adjust the test for `listWaitingReady`: insert A, B, C as above, then **manually clear** the recompute flag on A and B with `repo.setRecomputeDone(...)`. Re-run the assertion: only A is listed.

Update the test (replacing the body of the `listWaitingReady` test):

```dart
test('listWaitingReady excludes recompute-pending and non-waiting',
    () async {
  final aId = await repo.insert(_newClient(name: 'A', isWaiting: true));
  final bId = await repo.insert(_newClient(name: 'B', isWaiting: false));
  await repo.insert(_newClient(name: 'C', isWaiting: true)); // stays pending

  await repo.setRecomputeDone(aId);
  await repo.setRecomputeDone(bId);

  final waiting = await repo.listWaitingReady();
  expect(waiting.map((c) => c.name), ['A']);
});
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/data/client_repository_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/client_repository.dart test/data/client_repository_test.dart
git commit -m "feat(data): client repository"
```

---

## Task 2.5: DistanceMatrixRepository

**Files:**
- Create: `lib/data/repositories/distance_matrix_repository.dart`
- Create: `test/data/distance_matrix_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/distance_matrix_repository_test.dart
import 'package:coupe_laine/data/repositories/distance_matrix_repository.dart';
import 'package:coupe_laine/domain/models/distance_matrix_entry.dart';
import 'package:coupe_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DistanceMatrixEntry _entry(int from, int to, int dist) =>
    DistanceMatrixEntry(
      fromId: from,
      toId: to,
      distanceMeters: dist,
      durationSeconds: dist ~/ 14, // ~50 km/h
      computedAt: DateTime(2026, 4, 1),
    );

void main() {
  late AppDatabase db;
  late DistanceMatrixRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DistanceMatrixRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('bulk insert and read distance', () async {
    await repo.upsertMany([
      _entry(0, 1, 5000),
      _entry(1, 0, 5100),
      _entry(0, 2, 12000),
    ]);
    expect(await repo.distanceMeters(from: 0, to: 1), 5000);
    expect(await repo.distanceMeters(from: 1, to: 0), 5100);
    expect(await repo.distanceMeters(from: 0, to: 99), isNull);
  });

  test('upsert overwrites existing rows', () async {
    await repo.upsertMany([_entry(0, 1, 5000)]);
    await repo.upsertMany([_entry(0, 1, 6000)]);
    expect(await repo.distanceMeters(from: 0, to: 1), 6000);
  });

  test('deleteForClient removes both directions', () async {
    await repo.upsertMany([
      _entry(0, 1, 5000),
      _entry(1, 0, 5000),
      _entry(1, 2, 3000),
      _entry(2, 1, 3000),
      _entry(0, 2, 8000),
    ]);
    await repo.deleteForClient(1);
    expect(await repo.distanceMeters(from: 0, to: 1), isNull);
    expect(await repo.distanceMeters(from: 1, to: 2), isNull);
    expect(await repo.distanceMeters(from: 0, to: 2), 8000);
  });

  test('proximity query filters by waiting status (joined externally)',
      () async {
    // proximity is a SQL with JOIN; we test the helper that returns
    // the matrix rows below a radius for a given pivot.
    await repo.upsertMany([
      _entry(0, 1, 4000),
      _entry(1, 0, 4000),
      _entry(0, 2, 11000),
      _entry(2, 0, 11000),
      _entry(1, 2, 7000),
      _entry(2, 1, 7000),
    ]);
    final near = await repo.distancesFromPivot(
      pivotId: 1,
      maxDistanceMeters: 8000,
    );
    expect(near.length, 1);
    expect(near.first.toId, 2);
    expect(near.first.distanceMeters, 7000);
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/data/distance_matrix_repository_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/data/repositories/distance_matrix_repository.dart
import 'package:drift/drift.dart';

import '../../domain/models/distance_matrix_entry.dart';
import '../../infra/db/app_database.dart';

class DistanceMatrixRepository {
  final AppDatabase _db;
  DistanceMatrixRepository(this._db);

  Future<void> upsertMany(List<DistanceMatrixEntry> entries) async {
    await _db.batch((batch) {
      for (final e in entries) {
        batch.insert(
          _db.distanceMatrixTable,
          DistanceMatrixTableCompanion.insert(
            fromId: e.fromId,
            toId: e.toId,
            distanceMeters: e.distanceMeters,
            durationSeconds: e.durationSeconds,
            computedAt: e.computedAt.millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<int?> distanceMeters({required int from, required int to}) async {
    final row = await (_db.select(_db.distanceMatrixTable)
          ..where((t) => t.fromId.equals(from) & t.toId.equals(to)))
        .getSingleOrNull();
    return row?.distanceMeters;
  }

  Future<int?> durationSeconds({required int from, required int to}) async {
    final row = await (_db.select(_db.distanceMatrixTable)
          ..where((t) => t.fromId.equals(from) & t.toId.equals(to)))
        .getSingleOrNull();
    return row?.durationSeconds;
  }

  Future<List<DistanceMatrixEntry>> distancesFromPivot({
    required int pivotId,
    required int maxDistanceMeters,
  }) async {
    final rows = await (_db.select(_db.distanceMatrixTable)
          ..where((t) =>
              t.fromId.equals(pivotId) &
              t.distanceMeters.isSmallerOrEqualValue(maxDistanceMeters) &
              t.toId.equals(pivotId).not()))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<void> deleteForClient(int clientId) async {
    await (_db.delete(_db.distanceMatrixTable)
          ..where((t) =>
              t.fromId.equals(clientId) | t.toId.equals(clientId)))
        .go();
  }

  Future<void> deleteAll() async {
    await _db.delete(_db.distanceMatrixTable).go();
  }

  Future<int> countForNode(int id) async {
    final c = countAll(filter: (t) =>
        t.fromId.equals(id) | t.toId.equals(id));
    final row = await (_db.selectOnly(_db.distanceMatrixTable)
          ..addColumns([c])
          ..where(_db.distanceMatrixTable.fromId.equals(id) |
              _db.distanceMatrixTable.toId.equals(id)))
        .getSingle();
    return row.read(c) ?? 0;
  }

  Expression<int> countAll({
    required Expression<bool> Function(DistanceMatrixTable) filter,
  }) {
    return _db.distanceMatrixTable.id.count();
  }

  DistanceMatrixEntry _toDomain(DistanceMatrixRow row) => DistanceMatrixEntry(
        fromId: row.fromId,
        toId: row.toId,
        distanceMeters: row.distanceMeters,
        durationSeconds: row.durationSeconds,
        computedAt:
            DateTime.fromMillisecondsSinceEpoch(row.computedAt),
      );
}
```

> Drift's `DistanceMatrixTable` doesn't have an auto `id` column (composite PK), so `id.count()` is invalid. Replace `countForNode` and `countAll` with a simpler `Future<int> countForNode(int id)` using `customSelect`:

```dart
Future<int> countForNode(int id) async {
  final result = await _db.customSelect(
    'SELECT COUNT(*) AS c FROM distance_matrix '
    'WHERE from_id = ? OR to_id = ?',
    variables: [Variable.withInt(id), Variable.withInt(id)],
    readsFrom: {_db.distanceMatrixTable},
  ).getSingle();
  return result.data['c'] as int;
}
```

Remove the broken `Expression<int> countAll` helper entirely.

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/data/distance_matrix_repository_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/distance_matrix_repository.dart test/data/distance_matrix_repository_test.dart
git commit -m "feat(data): distance matrix repository"
```

---

## Task 2.6: TourRepository

**Files:**
- Create: `lib/data/repositories/tour_repository.dart`
- Create: `test/data/tour_repository_test.dart`

The repository needs to: insert a planned tour with stops in a single transaction, mark a tour completed (which updates `last_shearing_date` and clears `is_waiting` for all stops' clients in the same transaction), list tours, and read a tour with its stops.

- [ ] **Step 1: Write the failing test**

```dart
// test/data/tour_repository_test.dart
import 'package:coupe_laine/data/repositories/client_repository.dart';
import 'package:coupe_laine/data/repositories/tour_repository.dart';
import 'package:coupe_laine/domain/models/client.dart';
import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:coupe_laine/domain/models/tour.dart';
import 'package:coupe_laine/domain/models/tour_stop.dart';
import 'package:coupe_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TourRepository tours;
  late ClientRepository clients;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tours = TourRepository(db);
    clients = ClientRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> _addClient(String name, {bool waiting = true}) {
    return clients.insert(Client(
      id: 0,
      name: name,
      addressLabel: 'addr',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48, lon: -4),
      sheepCount: 5,
      isWaiting: waiting,
    ));
  }

  test('plan + read round-trip', () async {
    final c1 = await _addClient('A');
    final c2 = await _addClient('B');
    final draft = TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 30000,
      totalDriveSeconds: 3600,
      totalTravelFeeCents: 4000,
      stops: [
        TourStopDraft(
          clientId: c1,
          clientNameSnapshot: 'A',
          orderIndex: 0,
          estimatedArrivalMinutes: 8 * 60 + 20,
          estimatedDepartureMinutes: 8 * 60 + 80,
          sheepCountSnapshot: 5,
          minutesPerSheepSnapshot: 20,
          feeShareCents: 2000,
        ),
        TourStopDraft(
          clientId: c2,
          clientNameSnapshot: 'B',
          orderIndex: 1,
          estimatedArrivalMinutes: 9 * 60 + 30,
          estimatedDepartureMinutes: 10 * 60 + 30,
          sheepCountSnapshot: 5,
          minutesPerSheepSnapshot: 20,
          feeShareCents: 2000,
        ),
      ],
    );
    final tourId = await tours.plan(draft);
    final read = await tours.findById(tourId);
    expect(read, isNotNull);
    expect(read!.tour.status, TourStatus.planned);
    expect(read.stops.length, 2);
    expect(read.stops.map((s) => s.clientNameSnapshot), ['A', 'B']);
  });

  test('completing a tour updates clients', () async {
    final c1 = await _addClient('A', waiting: true);
    final tourId = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: c1,
          clientNameSnapshot: 'A',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          sheepCountSnapshot: 5,
          minutesPerSheepSnapshot: 20,
          feeShareCents: 0,
        ),
      ],
    ));
    await tours.markCompleted(tourId);
    final read = await tours.findById(tourId);
    expect(read!.tour.status, TourStatus.completed);
    final c = await clients.findById(c1);
    expect(c!.isWaiting, isFalse);
    expect(c.lastShearingDate, isNotNull);
  });

  test('soft FK preserves stop after client delete', () async {
    final c1 = await _addClient('A');
    final tourId = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: c1,
          clientNameSnapshot: 'A',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          sheepCountSnapshot: 5,
          minutesPerSheepSnapshot: 20,
          feeShareCents: 0,
        ),
      ],
    ));
    await clients.delete(c1);
    final read = await tours.findById(tourId);
    expect(read!.stops.length, 1);
    expect(read.stops.first.clientId, isNull);
    expect(read.stops.first.clientNameSnapshot, 'A');
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/data/tour_repository_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/data/repositories/tour_repository.dart
import 'package:drift/drift.dart';

import '../../domain/models/tour.dart';
import '../../domain/models/tour_stop.dart';
import '../../infra/db/app_database.dart';

class TourStopDraft {
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final int sheepCountSnapshot;
  final int minutesPerSheepSnapshot;
  final int feeShareCents;

  const TourStopDraft({
    required this.clientNameSnapshot,
    required this.orderIndex,
    required this.estimatedArrivalMinutes,
    required this.estimatedDepartureMinutes,
    required this.sheepCountSnapshot,
    required this.minutesPerSheepSnapshot,
    required this.feeShareCents,
    this.clientId,
  });
}

class TourDraft {
  final DateTime plannedDate;
  final int startTimeMinutes;
  final int totalDistanceMeters;
  final int totalDriveSeconds;
  final int totalTravelFeeCents;
  final String? notes;
  final List<TourStopDraft> stops;

  const TourDraft({
    required this.plannedDate,
    required this.startTimeMinutes,
    required this.totalDistanceMeters,
    required this.totalDriveSeconds,
    required this.totalTravelFeeCents,
    required this.stops,
    this.notes,
  });
}

class TourWithStops {
  final Tour tour;
  final List<TourStop> stops;
  const TourWithStops({required this.tour, required this.stops});
}

class TourRepository {
  final AppDatabase _db;
  TourRepository(this._db);

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
                sheepCountSnapshot: s.sheepCountSnapshot,
                minutesPerSheepSnapshot: s.minutesPerSheepSnapshot,
                feeShareCents: s.feeShareCents,
              ),
            );
      }
      return tourId;
    });
  }

  Future<TourWithStops?> findById(int id) async {
    final tourRow = await (_db.select(_db.toursTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (tourRow == null) return null;
    final stopRows = await (_db.select(_db.tourStopsTable)
          ..where((s) => s.tourId.equals(id))
          ..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]))
        .get();
    return TourWithStops(
      tour: _tourFromRow(tourRow),
      stops: stopRows.map(_stopFromRow).toList(),
    );
  }

  Future<List<Tour>> listAll() async {
    final rows = await (_db.select(_db.toursTable)
          ..orderBy([(t) => OrderingTerm.desc(t.plannedDate)]))
        .get();
    return rows.map(_tourFromRow).toList();
  }

  Future<void> markCompleted(int id) async {
    await _db.transaction(() async {
      final tour = await (_db.select(_db.toursTable)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      final now = DateTime.now().millisecondsSinceEpoch;
      await (_db.update(_db.toursTable)..where((t) => t.id.equals(id))).write(
        ToursTableCompanion(
          status: const Value('completed'),
          completedAt: Value(now),
        ),
      );
      final stopRows = await (_db.select(_db.tourStopsTable)
            ..where((s) =>
                s.tourId.equals(id) & s.clientId.isNotNull()))
          .get();
      for (final s in stopRows) {
        await (_db.update(_db.clientsTable)
              ..where((c) => c.id.equals(s.clientId!)))
            .write(
          ClientsTableCompanion(
            isWaiting: const Value(false),
            lastShearingDate: Value(tour.plannedDate * 86400000),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.toursTable)..where((t) => t.id.equals(id))).go();
  }

  int _toEpochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
          86400000;

  Tour _tourFromRow(TourRow row) => Tour(
        id: row.id,
        plannedDate:
            DateTime.fromMillisecondsSinceEpoch(row.plannedDate * 86400000),
        startTimeMinutes: row.startTimeMinutes,
        status: row.status == 'completed'
            ? TourStatus.completed
            : TourStatus.planned,
        totalDistanceMeters: row.totalDistanceMeters,
        totalDriveSeconds: row.totalDriveSeconds,
        totalTravelFeeCents: row.totalTravelFeeCents,
        notes: row.notes,
        completedAt: row.completedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.completedAt!),
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );

  TourStop _stopFromRow(TourStopRow row) => TourStop(
        id: row.id,
        tourId: row.tourId,
        clientId: row.clientId,
        clientNameSnapshot: row.clientNameSnapshot,
        orderIndex: row.orderIndex,
        estimatedArrivalMinutes: row.estimatedArrivalMinutes,
        estimatedDepartureMinutes: row.estimatedDepartureMinutes,
        sheepCountSnapshot: row.sheepCountSnapshot,
        minutesPerSheepSnapshot: row.minutesPerSheepSnapshot,
        feeShareCents: row.feeShareCents,
      );
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/data/tour_repository_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/tour_repository.dart test/data/tour_repository_test.dart
git commit -m "feat(data): tour repository with completion side-effects"
```

---

## Task 2.7: Phase 2 sweep

- [ ] **Step 1: Run all data tests**

```bash
flutter test test/data/
```
Expected: all green.

- [ ] **Step 2: Run all tests so far**

```bash
flutter test
```
Expected: domain + data + smoke widget all green.

---

**Phase 2 done.** Persistence layer in place; the rest of the app will only ever talk to repositories.
