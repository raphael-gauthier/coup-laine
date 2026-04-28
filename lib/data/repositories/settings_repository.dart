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
