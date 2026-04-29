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
  int get schemaVersion => 4;

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
        // These two columns were later removed in v4; use raw SQL so the
        // generated table accessor (which no longer has these getters) still
        // compiles.
        await customStatement(
          "ALTER TABLE settings ADD COLUMN marker_overdue_color TEXT NOT NULL DEFAULT '#B33A3A'",
        );
        await customStatement(
          "ALTER TABLE settings ADD COLUMN marker_recompute_color TEXT NOT NULL DEFAULT '#A89F92'",
        );
        // (using double quotes here so single quotes inside the SQL hex literal
        // don't need escaping; the v4 block below uses single quotes since
        // it has no embedded literals.)
        await m.addColumn(clientsTable, clientsTable.markerColorHex);
      }
      if (from < 4) {
        // Add new client column.
        await m.addColumn(clientsTable, clientsTable.isBanned);
        // Add new settings columns (4 new colors + season epoch).
        await m.addColumn(settingsTable, settingsTable.markerScheduledColor);
        await m.addColumn(settingsTable, settingsTable.markerDoneColor);
        await m.addColumn(settingsTable, settingsTable.markerNoSheepColor);
        await m.addColumn(settingsTable, settingsTable.markerBannedColor);
        await m.addColumn(settingsTable, settingsTable.seasonStartedAt);
        // Drop obsolete settings columns (SQLite >= 3.35 supports DROP COLUMN;
        // sqlite3_flutter_libs bundles a recent enough version).
        await customStatement(
          'ALTER TABLE settings DROP COLUMN marker_overdue_color',
        );
        await customStatement(
          'ALTER TABLE settings DROP COLUMN marker_recompute_color',
        );
        // Initialize season epoch on the existing settings row to "now".
        await customStatement(
          'UPDATE settings SET season_started_at = ? WHERE id = 1',
          [DateTime.now().millisecondsSinceEpoch],
        );
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
