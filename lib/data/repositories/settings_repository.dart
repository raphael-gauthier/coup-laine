import 'package:drift/drift.dart';

import '../../domain/models/coordinates.dart';
import '../../domain/models/settings.dart';
import '../../domain/use_cases/client_status.dart';
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
      travelFeeEurosPerBracket: row.travelFeeEurosPerBracket,
      bracketKm: row.bracketKm,
      themeMode: _parseMode(row.themeMode),
      markerDefaultColor: row.markerDefaultColor,
      markerWaitingColor: row.markerWaitingColor,
      markerScheduledColor: row.markerScheduledColor,
      markerDoneColor: row.markerDoneColor,
      markerNoAnimalsColor: row.markerNoAnimalsColor,
      markerBannedColor: row.markerBannedColor,
      seasonStartedAt: DateTime.fromMillisecondsSinceEpoch(row.seasonStartedAt),
      appAvatarKey: row.appAvatarKey,
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
            travelFeeEurosPerBracket: Value(settings.travelFeeEurosPerBracket),
            bracketKm: Value(settings.bracketKm),
            themeMode: Value(_serializeMode(settings.themeMode)),
            markerDefaultColor: Value(settings.markerDefaultColor),
            markerWaitingColor: Value(settings.markerWaitingColor),
            markerScheduledColor: Value(settings.markerScheduledColor),
            markerDoneColor: Value(settings.markerDoneColor),
            markerNoAnimalsColor: Value(settings.markerNoAnimalsColor),
            markerBannedColor: Value(settings.markerBannedColor),
            appAvatarKey: Value(settings.appAvatarKey),
            seasonStartedAt: Value(
              settings.seasonStartedAt.millisecondsSinceEpoch,
            ),
          ),
        );
  }

  Future<void> updateMarkerColor(ClientStatus status, String hex) async {
    final companion = switch (status) {
      ClientStatus.defaultStatus =>
        SettingsTableCompanion(markerDefaultColor: Value(hex)),
      ClientStatus.waiting =>
        SettingsTableCompanion(markerWaitingColor: Value(hex)),
      ClientStatus.scheduled =>
        SettingsTableCompanion(markerScheduledColor: Value(hex)),
      ClientStatus.done =>
        SettingsTableCompanion(markerDoneColor: Value(hex)),
      ClientStatus.noAnimals =>
        SettingsTableCompanion(markerNoAnimalsColor: Value(hex)),
      ClientStatus.banned =>
        SettingsTableCompanion(markerBannedColor: Value(hex)),
    };
    await (_db.update(_db.settingsTable)
          ..where((t) => t.id.equals(1)))
        .write(companion);
  }

  Future<void> bumpSeasonStartedAt(DateTime now) async {
    await (_db.update(_db.settingsTable)..where((t) => t.id.equals(1))).write(
      SettingsTableCompanion(
        seasonStartedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setThemeMode(ThemeModePreference mode) async {
    final current = await read();
    if (current == null) return;
    await save(current.copyWith(themeMode: mode));
  }

  ThemeModePreference _parseMode(String? raw) {
    return switch (raw) {
      'light' => ThemeModePreference.light,
      'dark' => ThemeModePreference.dark,
      _ => ThemeModePreference.system,
    };
  }

  String _serializeMode(ThemeModePreference m) => m.name;
}
