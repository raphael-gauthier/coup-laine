# Phase 10 — Backup + edge cases

**Goal:** JSON export/import, startup consistency check that flags clients with missing matrix rows, and a base-changed banner that prompts to recompute distances.

**Verification at end of phase:** A user can export the database, reinstall the app, import the file, and recover all clients/tours/matrix. Corrupted state (manually deleted matrix rows) is detected at startup.

---

## Task 10.1: JSON export/import service

**Files:**
- Create: `lib/infra/services/json_export_service.dart`
- Create: `test/infra/services/json_export_service_test.dart`

The format is a versioned dump of all tables. Schema version 1.

- [ ] **Step 1: Write the failing test**

```dart
// test/infra/services/json_export_service_test.dart
import 'package:coupe_laine/data/repositories/client_repository.dart';
import 'package:coupe_laine/data/repositories/distance_matrix_repository.dart';
import 'package:coupe_laine/data/repositories/settings_repository.dart';
import 'package:coupe_laine/data/repositories/tour_repository.dart';
import 'package:coupe_laine/domain/models/client.dart';
import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:coupe_laine/domain/models/settings.dart';
import 'package:coupe_laine/infra/db/app_database.dart';
import 'package:coupe_laine/infra/services/json_export_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late JsonExportService svc;
  late ClientRepository clients;
  late SettingsRepository settings;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = SettingsRepository(db);
    clients = ClientRepository(db);
    svc = JsonExportService(
      database: db,
      settings: settings,
      clients: clients,
      matrix: DistanceMatrixRepository(db),
      tours: TourRepository(db),
    );
    await settings.save(const Settings(
      baseCoordinates: Coordinates(lat: 48.5, lon: -2.7),
      baseAddressLabel: 'base',
    ));
  });

  tearDown(() async {
    await db.close();
  });

  test('export then import round-trips clients', () async {
    await clients.insert(Client(
      id: 0,
      name: 'A',
      addressLabel: 'addr',
      postcode: '22000',
      city: 'Saint-Brieuc',
      coordinates: const Coordinates(lat: 48.5, lon: -2.8),
      sheepCount: 12,
    ));
    final json = await svc.exportToJsonString();

    // wipe
    await db.delete(db.clientsTable).go();
    expect(await clients.listAll(), isEmpty);

    await svc.importFromJsonString(json);
    final list = await clients.listAll();
    expect(list.length, 1);
    expect(list.first.name, 'A');
    expect(list.first.city, 'Saint-Brieuc');
  });

  test('rejects unknown schema version', () async {
    expect(
      svc.importFromJsonString('{"schema":99,"settings":null,"clients":[],"distanceMatrix":[],"tours":[],"tourStops":[]}'),
      throwsA(isA<JsonImportException>()),
    );
  });
}
```

- [ ] **Step 2: Run, expect FAIL**

```bash
flutter test test/infra/services/json_export_service_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/infra/services/json_export_service.dart
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/repositories/client_repository.dart';
import '../../data/repositories/distance_matrix_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/tour_repository.dart';
import '../db/app_database.dart';

class JsonImportException implements Exception {
  final String message;
  JsonImportException(this.message);
  @override
  String toString() => 'JsonImportException: $message';
}

class JsonExportService {
  static const int schemaVersion = 1;

  final AppDatabase database;
  final SettingsRepository settings;
  final ClientRepository clients;
  final DistanceMatrixRepository matrix;
  final TourRepository tours;

  JsonExportService({
    required this.database,
    required this.settings,
    required this.clients,
    required this.matrix,
    required this.tours,
  });

  Future<String> exportToJsonString() async {
    final s = await database.select(database.settingsTable).getSingleOrNull();
    final cs = await database.select(database.clientsTable).get();
    final dm = await database.select(database.distanceMatrixTable).get();
    final ts = await database.select(database.toursTable).get();
    final stops = await database.select(database.tourStopsTable).get();
    return jsonEncode({
      'schema': schemaVersion,
      'settings': s?.toJson(),
      'clients': cs.map((r) => r.toJson()).toList(),
      'distanceMatrix': dm.map((r) => r.toJson()).toList(),
      'tours': ts.map((r) => r.toJson()).toList(),
      'tourStops': stops.map((r) => r.toJson()).toList(),
    });
  }

  Future<void> importFromJsonString(String body) async {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final schema = json['schema'];
    if (schema != schemaVersion) {
      throw JsonImportException('Unsupported schema $schema');
    }
    await database.transaction(() async {
      // wipe
      await database.delete(database.tourStopsTable).go();
      await database.delete(database.toursTable).go();
      await database.delete(database.distanceMatrixTable).go();
      await database.delete(database.clientsTable).go();
      await database.delete(database.settingsTable).go();

      final s = json['settings'] as Map<String, dynamic>?;
      if (s != null) {
        await database.into(database.settingsTable).insert(
              SettingsRow.fromJson(s),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final c in (json['clients'] as List)) {
        await database.into(database.clientsTable).insert(
              ClientRow.fromJson(c as Map<String, dynamic>),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final d in (json['distanceMatrix'] as List)) {
        await database.into(database.distanceMatrixTable).insert(
              DistanceMatrixRow.fromJson(d as Map<String, dynamic>),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final t in (json['tours'] as List)) {
        await database.into(database.toursTable).insert(
              TourRow.fromJson(t as Map<String, dynamic>),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final st in (json['tourStops'] as List)) {
        await database.into(database.tourStopsTable).insert(
              TourStopRow.fromJson(st as Map<String, dynamic>),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }
}
```

- [ ] **Step 4: Run, expect PASS**

```bash
flutter test test/infra/services/json_export_service_test.dart
```

- [ ] **Step 5: Add provider**

In `lib/state/providers.dart`:

```dart
import '../infra/services/json_export_service.dart';

final jsonExportServiceProvider = Provider<JsonExportService>((ref) {
  return JsonExportService(
    database: ref.watch(appDatabaseProvider),
    settings: ref.watch(settingsRepositoryProvider),
    clients: ref.watch(clientRepositoryProvider),
    matrix: ref.watch(distanceMatrixRepositoryProvider),
    tours: ref.watch(tourRepositoryProvider),
  );
});
```

- [ ] **Step 6: Commit**

```bash
git add lib/infra/services/json_export_service.dart \
        lib/state/providers.dart \
        test/infra/services/json_export_service_test.dart
git commit -m "feat(infra): json export/import service"
```

---

## Task 10.2: Wire export/import into Settings screen

**Files:**
- Modify: `lib/presentation/settings/settings_screen.dart`

- [ ] **Step 1: Replace the disabled Data ListTiles**

```dart
import 'package:file_picker/file_picker.dart'; // add to pubspec.yaml: file_picker: ^8.1.2
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// ...
ListTile(
  leading: const Icon(Icons.upload_file),
  title: Text(l.settingsExportData),
  onTap: () async {
    final svc = ref.read(jsonExportServiceProvider);
    final body = await svc.exportToJsonString();
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path,
        'coupe-laine-${DateTime.now().millisecondsSinceEpoch}.json'));
    await file.writeAsString(body);
    await Share.shareXFiles([XFile(file.path)]);
  },
),
ListTile(
  leading: const Icon(Icons.download),
  title: Text(l.settingsImportData),
  onTap: () async {
    final pick = await FilePicker.platform.pickFiles(type: FileType.any);
    if (pick == null) return;
    final body = await File(pick.files.single.path!).readAsString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text(
            'Cette action remplace toutes les données actuelles. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(jsonExportServiceProvider).importFromJsonString(body);
      ref.invalidate(_settingsAsyncProvider);
    }
  },
),
```

- [ ] **Step 2: Add `file_picker` to `pubspec.yaml`**

Under `dependencies:`:
```yaml
file_picker: ^8.1.2
```

```bash
flutter pub get
```

- [ ] **Step 3: Run on Android**:
1. Settings → Exporter → save the JSON file via Android Share.
2. Reinstall app or wipe app data.
3. Re-onboard with a placeholder address.
4. Settings → Importer → select the JSON → confirm.
5. Verify clients/tours/matrix all reappear.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/settings/settings_screen.dart pubspec.yaml pubspec.lock
git commit -m "feat(settings): wire json export and import"
```

---

## Task 10.3: Startup consistency check

**Files:**
- Create: `lib/data/consistency_check.dart`
- Modify: `lib/main.dart` (run after env load)

- [ ] **Step 1: Implement**

```dart
// lib/data/consistency_check.dart
import 'repositories/client_repository.dart';
import '../infra/db/app_database.dart';

class ConsistencyCheck {
  final AppDatabase db;
  final ClientRepository clients;
  ConsistencyCheck({required this.db, required this.clients});

  Future<int> run() async {
    final allClients = await clients.listAll();
    final n = allClients.length;
    if (n == 0) return 0;
    var fixed = 0;
    for (final c in allClients) {
      if (c.needsDistanceRecompute) continue;
      final result = await db.customSelect(
        'SELECT COUNT(*) AS c FROM distance_matrix '
        'WHERE from_id = ? OR to_id = ?',
        variables: [Variable.withInt(c.id), Variable.withInt(c.id)],
        readsFrom: {db.distanceMatrixTable},
      ).getSingle();
      final rows = result.data['c'] as int;
      // Each client should have 2 * n rows (out + in for base + n-1 others).
      // Off-by-one tolerated: simply require >= 2*(n-1).
      if (rows < 2 * (n - 1)) {
        await clients.setRecomputePending(c.id);
        fixed++;
      }
    }
    return fixed;
  }
}
```

- [ ] **Step 2: Add provider**

In `lib/state/providers.dart`:
```dart
import '../data/consistency_check.dart';

final consistencyCheckProvider = Provider<ConsistencyCheck>((ref) {
  return ConsistencyCheck(
    db: ref.watch(appDatabaseProvider),
    clients: ref.watch(clientRepositoryProvider),
  );
});
```

- [ ] **Step 3: Run check at startup**

In `lib/main.dart`, replace the body:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  final container = ProviderContainer();
  // Fire-and-forget; UI banner will show pending recomputes.
  unawaited(container.read(consistencyCheckProvider).run());
  runApp(UncontrolledProviderScope(
    container: container,
    child: const CoupeLaineApp(),
  ));
}
```

> Add `import 'dart:async';` for `unawaited` if needed.

- [ ] **Step 4: Commit**

```bash
git add lib/data/consistency_check.dart lib/main.dart lib/state/providers.dart
git commit -m "feat(data): startup consistency check for missing matrix rows"
```

---

## Task 10.4: Base-changed banner

**Files:**
- Modify: `lib/presentation/settings/settings_screen.dart`

When the user picks a new base address, after saving offer to recompute the whole matrix.

- [ ] **Step 1: Detect base change in `_save()`**

In `_SettingsFormState._save()`:

```dart
Future<void> _save() async {
  final didBaseChange =
      _draft.baseAddressLabel != widget.initial.baseAddressLabel ||
          _draft.baseCoordinates != widget.initial.baseCoordinates;
  await ref.read(settingsRepositoryProvider).save(_draft);
  ref.invalidate(_settingsAsyncProvider);
  if (!mounted) return;
  if (didBaseChange) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text(
          "L'adresse de base a changé. Recalculer toutes les distances "
          'depuis la nouvelle base ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Recalculer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(distanceMatrixSyncProvider).recomputeAllForBase();
    }
  }
  if (!mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Enregistré')));
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/settings/settings_screen.dart
git commit -m "feat(settings): prompt to recompute matrix when base changes"
```

---

## Task 10.5: Phase 10 sweep

- [ ] **Step 1: Run all tests**

```bash
flutter test
```

- [ ] **Step 2: Manual smoke**

1. Export → import → verify integrity.
2. Manually break the matrix (delete a row via a debug tool), restart app, verify a recompute banner appears.
3. Change base address, accept the recompute dialog, verify banners clear.

---

**Phase 10 done.** Operational edges are covered. Polish + release in Phase 11.
