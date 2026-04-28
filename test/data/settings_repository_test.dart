import 'package:coup_laine/data/repositories/settings_repository.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/settings.dart';
import 'package:coup_laine/domain/use_cases/client_status.dart';
import 'package:coup_laine/infra/db/app_database.dart';
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

  test('marker colors round-trip + updateMarkerColor', () async {
    await repo.save(const Settings(
      baseCoordinates: Coordinates(lat: 48.0, lon: -3.0),
      baseAddressLabel: 'base',
    ));
    // Fresh save uses the model defaults — verify them.
    var read = await repo.read();
    expect(read!.markerDefaultColor, '#4A6B52');
    expect(read.markerWaitingColor, '#C77B5C');
    expect(read.markerOverdueColor, '#B33A3A');
    expect(read.markerRecomputeColor, '#A89F92');

    await repo.updateMarkerColor(ClientStatus.waiting, '#FF00FF');
    read = await repo.read();
    expect(read!.markerWaitingColor, '#FF00FF');
    // Other colors unchanged.
    expect(read.markerDefaultColor, '#4A6B52');
  });
}
