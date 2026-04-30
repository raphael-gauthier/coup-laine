import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/manual_history_repository.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/tour_stop_animal.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_helpers/animal_fixtures.dart';

Client _newClient({String name = 'Le Gall'}) => Client(
      id: 0,
      name: name,
      addressLabel: '1 rue, 29000 Quimper',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48.0, lon: -4.1),
    );

void main() {
  late AppDatabase db;
  late ManualHistoryRepository repo;
  late ClientRepository clients;
  late AnimalFixtures fix;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ManualHistoryRepository(db);
    clients = ClientRepository(db, manualHistory: repo);
    fix = await seedTestSpeciesAndCategories(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert + listForClient sorts by date desc', () async {
    final cId = await clients.insert(_newClient());
    await repo.insert(
      clientId: cId,
      date: DateTime(2024, 5, 1),
      animals: [
        TourStopAnimal(
          categoryId: fix.catPetit,
          count: 4,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
        TourStopAnimal(
          categoryId: fix.catGrand,
          count: 1,
          categoryNameSnapshot: 'Grand',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 25,
        ),
      ],
      note: 'older',
    );
    await repo.insert(
      clientId: cId,
      date: DateTime(2025, 5, 1),
      animals: [
        TourStopAnimal(
          categoryId: fix.catPetit,
          count: 5,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
      ],
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
      animals: [
        TourStopAnimal(
          categoryId: fix.catPetit,
          count: 4,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
        TourStopAnimal(
          categoryId: fix.catGrand,
          count: 1,
          categoryNameSnapshot: 'Grand',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 25,
        ),
      ],
      note: 'old',
    );
    await repo.update(
      id,
      date: DateTime(2024, 6, 1),
      animals: [
        TourStopAnimal(
          categoryId: fix.catGrand,
          count: 7,
          categoryNameSnapshot: 'Grand',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 25,
        ),
        TourStopAnimal(
          categoryId: fix.catAdulte,
          count: 2,
          categoryNameSnapshot: 'Adulte',
          speciesNameSnapshot: 'Cheval',
          minutesSnapshot: 45,
        ),
      ],
      note: 'new',
    );
    final entry = (await repo.listForClient(cId)).single;
    expect(entry.date, DateTime(2024, 6, 1));
    expect(entry.animalsTotal, 9);
    expect(entry.animals.length, 2);
    expect(entry.animals[0].categoryId, fix.catGrand);
    expect(entry.animals[0].count, 7);
    expect(entry.animals[1].categoryId, fix.catAdulte);
    expect(entry.animals[1].count, 2);
    expect(entry.note, 'new');
  });

  test('delete removes the entry', () async {
    final cId = await clients.insert(_newClient());
    final id = await repo.insert(
      clientId: cId,
      date: DateTime(2024, 5, 1),
      animals: [
        TourStopAnimal(
          categoryId: fix.catPetit,
          count: 4,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
      ],
    );
    await repo.delete(id);
    expect(await repo.listForClient(cId), isEmpty);
  });

  test('client deletion cascades to manual entries', () async {
    final cId = await clients.insert(_newClient());
    await repo.insert(
      clientId: cId,
      date: DateTime(2024, 5, 1),
      animals: [
        TourStopAnimal(
          categoryId: fix.catPetit,
          count: 4,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
      ],
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
      animals: [
        TourStopAnimal(
          categoryId: fix.catPetit,
          count: 1,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
      ],
    );
    await repo.insert(
      clientId: cId,
      date: afterSeason,
      animals: [
        TourStopAnimal(
          categoryId: fix.catPetit,
          count: 1,
          categoryNameSnapshot: 'Petit',
          speciesNameSnapshot: 'Mouton',
          minutesSnapshot: 8,
        ),
      ],
    );

    final seasonStart = DateTime(2025, 4, 1);
    final seasonEpochDays = seasonStart.millisecondsSinceEpoch ~/ 86400000;
    final hits = await repo.listClientDatesSinceEpochDays(seasonEpochDays);
    expect(hits.length, 1);
    expect(hits.single.clientId, cId);
  });
}
