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

  test('themeMode round-trips non-default values', () async {
    for (final mode in ThemeModePreference.values) {
      await repo.save(Settings(
        baseCoordinates: const Coordinates(lat: 48.0, lon: -3.0),
        baseAddressLabel: 'Test',
        themeMode: mode,
      ));
      final read = await repo.read();
      expect(read!.themeMode, mode, reason: 'expected $mode to round-trip');
    }
  });
}
