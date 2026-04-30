import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/manual_history_repository.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Client _newClient({String name = 'Le Gall'}) => Client(
      id: 0,
      name: name,
      addressLabel: '1 rue, 29000 Quimper',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48.0, lon: -4.1),
      sheepCountSmall: 12,
    );

void main() {
  late AppDatabase db;
  late ManualHistoryRepository repo;
  late ClientRepository clients;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ManualHistoryRepository(db);
    clients = ClientRepository(db, manualHistory: repo);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert + listForClient sorts by date desc', () async {
    final cId = await clients.insert(_newClient());
    await repo.insert(
      clientId: cId,
      date: DateTime(2024, 5, 1),
      small: 4,
      large: 1,
      note: 'older',
    );
    await repo.insert(
      clientId: cId,
      date: DateTime(2025, 5, 1),
      small: 5,
      large: 0,
      note: 'newer',
    );
    final list = await repo.listForClient(cId);
    expect(list.length, 2);
    expect(list[0].note, 'newer');
    expect(list[1].note, 'older');
  });

  test('update modifies fields', () async {
    final cId = await clients.insert(_newClient());
    final id = await repo.insert(
      clientId: cId,
      date: DateTime(2024, 5, 1),
      small: 4,
      large: 1,
      note: 'old',
    );
    await repo.update(
      id,
      date: DateTime(2024, 6, 1),
      small: 7,
      large: 2,
      note: 'new',
    );
    final list = await repo.listForClient(cId);
    expect(list.single.date, DateTime(2024, 6, 1));
    expect(list.single.small, 7);
    expect(list.single.large, 2);
    expect(list.single.note, 'new');
  });

  test('delete removes the entry', () async {
    final cId = await clients.insert(_newClient());
    final id = await repo.insert(
      clientId: cId,
      date: DateTime(2024, 5, 1),
      small: 4,
      large: 1,
    );
    await repo.delete(id);
    expect(await repo.listForClient(cId), isEmpty);
  });

  test('client deletion cascades to manual entries', () async {
    final cId = await clients.insert(_newClient());
    await repo.insert(
      clientId: cId,
      date: DateTime(2024, 5, 1),
      small: 4,
      large: 1,
    );
    await clients.delete(cId);
    expect(await repo.listForClient(cId), isEmpty);
  });

  test('listClientDatesSinceEpochDays filters by threshold', () async {
    final cId = await clients.insert(_newClient());
    final beforeSeason = DateTime(2025, 3, 1);
    final afterSeason = DateTime(2025, 6, 1);
    await repo.insert(
      clientId: cId,
      date: beforeSeason,
      small: 1,
      large: 0,
    );
    await repo.insert(
      clientId: cId,
      date: afterSeason,
      small: 1,
      large: 0,
    );

    final seasonStart = DateTime(2025, 4, 1);
    final seasonEpochDays = seasonStart.millisecondsSinceEpoch ~/ 86400000;
    final hits = await repo.listClientDatesSinceEpochDays(seasonEpochDays);
    expect(hits.length, 1);
    expect(hits.single.clientId, cId);
  });
}
