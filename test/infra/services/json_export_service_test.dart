import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/distance_matrix_repository.dart';
import 'package:coup_laine/data/repositories/manual_history_repository.dart';
import 'package:coup_laine/data/repositories/settings_repository.dart';
import 'package:coup_laine/data/repositories/tour_repository.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/settings.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:coup_laine/infra/services/json_export_service.dart';
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
    clients = ClientRepository(db, manualHistory: ManualHistoryRepository(db));
    svc = JsonExportService(
      database: db,
      settings: settings,
      clients: clients,
      matrix: DistanceMatrixRepository(db),
      tours: TourRepository(db),
    );
    await settings.save(Settings(
      baseCoordinates: const Coordinates(lat: 48.5, lon: -2.7),
      baseAddressLabel: 'base',
      seasonStartedAt: DateTime.fromMillisecondsSinceEpoch(0),
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
      sheepCountSmall: 12,
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
