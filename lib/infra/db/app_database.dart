import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'phone_list_converter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SettingsTable,
    ClientsTable,
    DistanceMatrixTable,
    ToursTable,
    TourStopsTable,
    ManualHistoryEntriesTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 8;

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
      if (from < 5) {
        // Drop the per-client notes column. Notes have been removed from the
        // domain — any text saved here is intentionally lost.
        await customStatement('ALTER TABLE clients DROP COLUMN notes');
      }
      if (from < 6) {
        // ── clients : split sheep_count, drop minutes_per_sheep_override ──
        await m.addColumn(clientsTable, clientsTable.sheepCountSmall);
        await m.addColumn(clientsTable, clientsTable.sheepCountLarge);
        await customStatement(
          'UPDATE clients SET sheep_count_small = sheep_count',
        );
        await customStatement('ALTER TABLE clients DROP COLUMN sheep_count');
        await customStatement(
          'ALTER TABLE clients DROP COLUMN minutes_per_sheep_override',
        );

        // ── settings : split minutes-per-sheep ──
        await m.addColumn(
            settingsTable, settingsTable.defaultMinutesPerSmall);
        await m.addColumn(
            settingsTable, settingsTable.defaultMinutesPerLarge);
        await customStatement(
          'UPDATE settings '
          'SET default_minutes_per_small = default_minutes_per_sheep, '
          '    default_minutes_per_large = MAX(default_minutes_per_sheep, 25) '
          'WHERE id = 1',
        );
        await customStatement(
          'ALTER TABLE settings DROP COLUMN default_minutes_per_sheep',
        );

        // ── tour_stops : breed-aware snapshots + intervention actuals ──
        await m.addColumn(tourStopsTable, tourStopsTable.plannedSmall);
        await m.addColumn(tourStopsTable, tourStopsTable.plannedLarge);
        await m.addColumn(
            tourStopsTable, tourStopsTable.minutesPerSmallSnapshot);
        await m.addColumn(
            tourStopsTable, tourStopsTable.minutesPerLargeSnapshot);
        await m.addColumn(tourStopsTable, tourStopsTable.actualSmall);
        await m.addColumn(tourStopsTable, tourStopsTable.actualLarge);
        await m.addColumn(
            tourStopsTable, tourStopsTable.interventionNote);
        await customStatement(
          'UPDATE tour_stops '
          'SET planned_small = sheep_count_snapshot, '
          '    minutes_per_small_snapshot = minutes_per_sheep_snapshot',
        );
        await customStatement(
          'ALTER TABLE tour_stops DROP COLUMN sheep_count_snapshot',
        );
        await customStatement(
          'ALTER TABLE tour_stops DROP COLUMN minutes_per_sheep_snapshot',
        );
      }
      if (from < 7) {
        await m.createTable(manualHistoryEntriesTable);
        await customStatement(
          'CREATE INDEX idx_manual_history_client '
          'ON manual_history_entries(client_id)',
        );
      }
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
