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

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'coup_laine.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
