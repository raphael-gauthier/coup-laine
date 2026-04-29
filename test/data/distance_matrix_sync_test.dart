import 'package:coup_laine/data/distance_matrix_sync.dart';
import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/distance_matrix_repository.dart';
import 'package:coup_laine/data/repositories/settings_repository.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/settings.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:coup_laine/infra/services/ors_routing_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrs extends Mock implements OrsRoutingService {}

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late ClientRepository clients;
  late DistanceMatrixRepository matrix;
  late _MockOrs ors;
  late DistanceMatrixSync sync;

  setUpAll(() {
    registerFallbackValue(const Coordinates(lat: 0, lon: 0));
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = SettingsRepository(db);
    clients = ClientRepository(db);
    matrix = DistanceMatrixRepository(db);
    ors = _MockOrs();
    sync = DistanceMatrixSync(
      clients: clients,
      matrix: matrix,
      settings: settings,
      ors: ors,
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

  Future<int> _addClient(double lat, double lon, {String name = 'C'}) {
    return clients.insert(Client(
      id: 0,
      name: name,
      addressLabel: 'a',
      postcode: '00000',
      city: 'X',
      coordinates: Coordinates(lat: lat, lon: lon),
    ));
  }

  test('after insert: outbound + inbound rows present, flag cleared',
      () async {
    final aId = await _addClient(48.4, -2.8, name: 'A');
    when(() => ors.matrix(
          locations: any(named: 'locations'),
          sources: any(named: 'sources'),
          destinations: any(named: 'destinations'),
        )).thenAnswer((inv) async {
      final src = inv.namedArguments[#sources] as List<int>;
      final dst = inv.namedArguments[#destinations] as List<int>;
      return OrsMatrixResult(
        distances: List.generate(
          src.length,
          (_) => List.generate(dst.length, (_) => 5000),
        ),
        durations: List.generate(
          src.length,
          (_) => List.generate(dst.length, (_) => 600),
        ),
      );
    });

    await sync.recomputeForClient(aId);

    expect(await matrix.distanceMeters(from: 0, to: aId), 5000);
    expect(await matrix.distanceMeters(from: aId, to: 0), 5000);
    final c = await clients.findById(aId);
    expect(c!.needsDistanceRecompute, isFalse);
  });

  test('on ORS failure: flag stays set, throws', () async {
    final aId = await _addClient(48.4, -2.8);
    when(() => ors.matrix(
          locations: any(named: 'locations'),
          sources: any(named: 'sources'),
          destinations: any(named: 'destinations'),
        )).thenThrow(OrsException('boom'));

    expect(
      () => sync.recomputeForClient(aId),
      throwsA(isA<OrsException>()),
    );
    final c = await clients.findById(aId);
    expect(c!.needsDistanceRecompute, isTrue);
  });
}
