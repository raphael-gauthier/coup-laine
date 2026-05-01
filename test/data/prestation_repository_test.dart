import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/data/repositories/animal_category_repository.dart';
import 'package:coup_laine/data/repositories/prestation_repository.dart';
import 'package:coup_laine/data/repositories/species_repository.dart';
import 'package:coup_laine/infra/db/app_database.dart';

void main() {
  late AppDatabase db;
  late PrestationRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PrestationRepository(db);
  });

  tearDown(() async => db.close());

  test('insert libre prestation and list active', () async {
    final id = await repo.insert(
      name: 'Visite',
      priceCents: 2000,
      minutes: 0,
      categoryId: null,
    );
    final list = await repo.listActive();
    expect(list, hasLength(1));
    expect(list.first.id, id);
    expect(list.first.name, 'Visite');
    expect(list.first.priceCents, 2000);
    expect(list.first.minutes, 0);
    expect(list.first.categoryId, isNull);
    expect(list.first.archivedAt, isNull);
  });

  test('insert bound prestation', () async {
    final speciesRepo = SpeciesRepository(db);
    final catsRepo = AnimalCategoryRepository(db);
    final speciesId = await speciesRepo.insert(name: 'Mouton');
    final catId = await catsRepo.insert(speciesId: speciesId, name: 'Petit');

    final id = await repo.insert(
        name: 'Tonte', priceCents: 800, minutes: 8, categoryId: catId);
    final list = await repo.listActive();
    expect(list.single.id, id);
    expect(list.single.categoryId, catId);
  });

  test('insert with null price/minutes', () async {
    await repo.insert(name: 'À compléter', categoryId: null);
    final list = await repo.listActive();
    expect(list.single.priceCents, isNull);
    expect(list.single.minutes, isNull);
  });

  test('rename updates name', () async {
    final id = await repo.insert(name: 'Tonte', categoryId: null);
    await repo.rename(id: id, name: 'Tonte ovine');
    expect((await repo.listActive()).single.name, 'Tonte ovine');
  });

  test('updateValues sets price and minutes', () async {
    final id = await repo.insert(name: 'Tonte', categoryId: null);
    await repo.updateValues(id: id, priceCents: 1500, minutes: 12);
    final p = (await repo.listActive()).single;
    expect(p.priceCents, 1500);
    expect(p.minutes, 12);
  });

  test('updateValues can clear price/minutes back to null', () async {
    final id = await repo.insert(
        name: 'Tonte', priceCents: 800, minutes: 8, categoryId: null);
    await repo.updateValues(id: id, priceCents: null, minutes: null);
    final p = (await repo.listActive()).single;
    expect(p.priceCents, isNull);
    expect(p.minutes, isNull);
  });

  test('archive sets archivedAt; listActive excludes; listArchived includes',
      () async {
    final id = await repo.insert(name: 'Tonte', categoryId: null);
    await repo.archive(id);
    expect(await repo.listActive(), isEmpty);
    final archived = await repo.listArchived();
    expect(archived, hasLength(1));
    expect(archived.first.archivedAt, isNotNull);
  });

  test('unarchive clears archivedAt', () async {
    final id = await repo.insert(name: 'Tonte', categoryId: null);
    await repo.archive(id);
    await repo.unarchive(id);
    expect(await repo.listActive(), hasLength(1));
    expect(await repo.listArchived(), isEmpty);
  });

  test('countActive', () async {
    expect(await repo.countActive(), 0);
    final a = await repo.insert(name: 'A', categoryId: null);
    await repo.insert(name: 'B', categoryId: null);
    expect(await repo.countActive(), 2);
    await repo.archive(a);
    expect(await repo.countActive(), 1);
  });

  test('listByCategory returns active prestations bound to that category',
      () async {
    final speciesRepo = SpeciesRepository(db);
    final catsRepo = AnimalCategoryRepository(db);
    final sId = await speciesRepo.insert(name: 'Mouton');
    final cPetit = await catsRepo.insert(speciesId: sId, name: 'Petit');
    final cGrand = await catsRepo.insert(speciesId: sId, name: 'Grand');
    await repo.insert(name: 'Tonte petit', categoryId: cPetit);
    await repo.insert(name: 'Tonte grand', categoryId: cGrand);
    await repo.insert(name: 'Visite', categoryId: null);

    final list = await repo.listByCategory(cPetit);
    expect(list, hasLength(1));
    expect(list.first.name, 'Tonte petit');
  });
}
