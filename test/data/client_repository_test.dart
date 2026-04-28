import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Client _newClient({
  String name = 'Le Gall',
  bool isWaiting = false,
  bool needsDistanceRecompute = false,
}) {
  return Client(
    id: 0, // ignored on insert
    name: name,
    addressLabel: '1 rue, 29000 Quimper',
    postcode: '29000',
    city: 'Quimper',
    coordinates: const Coordinates(lat: 48.0, lon: -4.1),
    sheepCount: 12,
    isWaiting: isWaiting,
    needsDistanceRecompute: needsDistanceRecompute,
  );
}

void main() {
  late AppDatabase db;
  late ClientRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ClientRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert assigns id and reads back', () async {
    final id = await repo.insert(_newClient());
    expect(id, greaterThan(0));
    final read = await repo.findById(id);
    expect(read, isNotNull);
    expect(read!.name, 'Le Gall');
  });

  test('listWaitingReady excludes recompute-pending and non-waiting',
      () async {
    final aId = await repo.insert(_newClient(name: 'A', isWaiting: true));
    final bId = await repo.insert(_newClient(name: 'B', isWaiting: false));
    await repo.insert(_newClient(name: 'C', isWaiting: true)); // stays pending

    await repo.setRecomputeDone(aId);
    await repo.setRecomputeDone(bId);

    final waiting = await repo.listWaitingReady();
    expect(waiting.map((c) => c.name), ['A']);
  });

  test('toggleWaiting flips the flag', () async {
    final id = await repo.insert(_newClient(isWaiting: false));
    await repo.setWaiting(id: id, isWaiting: true);
    expect((await repo.findById(id))!.isWaiting, isTrue);
    await repo.setWaiting(id: id, isWaiting: false);
    expect((await repo.findById(id))!.isWaiting, isFalse);
  });

  test('delete removes the client', () async {
    final id = await repo.insert(_newClient());
    await repo.delete(id);
    expect(await repo.findById(id), isNull);
  });

  test('updateLocation marks needsDistanceRecompute', () async {
    final id = await repo.insert(_newClient());
    await repo.updateAddress(
      id: id,
      addressLabel: '2 rue, 29000 Quimper',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48.05, lon: -4.05),
    );
    final read = await repo.findById(id);
    expect(read!.needsDistanceRecompute, isTrue);
    expect(read.coordinates.lat, 48.05);
  });

  test('markerColorHex round-trip + setMarkerColor', () async {
    final id = await repo.insert(_newClient());
    expect((await repo.findById(id))!.markerColorHex, isNull);

    await repo.setMarkerColor(id, '#ABCDEF');
    expect((await repo.findById(id))!.markerColorHex, '#ABCDEF');

    await repo.setMarkerColor(id, null);
    expect((await repo.findById(id))!.markerColorHex, isNull);
  });
}
