import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/animal_count.dart';
import '../../domain/models/tour_stop_prestation.dart';
import 'animal_count_list_converter.dart';
import 'phone_list_converter.dart';
import 'tables.dart';
import 'tour_stop_prestation_list_converter.dart';

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
    PrestationsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 13) {
        // Branche legacy pré-prod : wipe-and-recreate. Conservée pour
        // gérer les éventuels installs de dev encore en v < 13.
        for (final table in allTables.toList().reversed) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
        return;
      }
      if (from < 14) {
        // v13 → v14 : ajout de Settings.lastBackupAt.
        // Migration incrémentale — préserve les données utilisateur.
        await m.addColumn(settingsTable, settingsTable.lastBackupAt);
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
