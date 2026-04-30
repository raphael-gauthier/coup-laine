import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/data/repositories/animal_category_repository.dart';
import 'package:coup_laine/data/repositories/species_repository.dart';
import 'package:coup_laine/infra/db/app_database.dart';

void main() {
  late AppDatabase db;
  late SpeciesRepository species;
  late AnimalCategoryRepository repo;
  late int speciesId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    species = SpeciesRepository(db);
    repo = AnimalCategoryRepository(db);
    speciesId = await species.insert(name: 'Mouton');
  });

  tearDown(() async => db.close());

  test('insert with no defaults; listActiveBySpecies returns it', () async {
    final id = await repo.insert(speciesId: speciesId, name: 'Petit');
    final list = await repo.listActiveBySpecies(speciesId);
    expect(list, hasLength(1));
    expect(list.first.id, id);
    expect(list.first.defaultMinutes, isNull);
    expect(list.first.defaultPriceCents, isNull);
  });

  test('updateDefaults changes minutes and price', () async {
    final id = await repo.insert(speciesId: speciesId, name: 'Petit');
    await repo.updateDefaults(
      id: id,
      defaultMinutes: 8,
      defaultPriceCents: 800,
    );
    final c = (await repo.listActiveBySpecies(speciesId)).single;
    expect(c.defaultMinutes, 8);
    expect(c.defaultPriceCents, 800);
  });

  test('archive excludes from listActiveBySpecies', () async {
    final id = await repo.insert(speciesId: speciesId, name: 'Petit');
    await repo.archive(id);
    expect(await repo.listActiveBySpecies(speciesId), isEmpty);
  });

  test('listAllActive merges across species', () async {
    final spId2 = await species.insert(name: 'Cheval');
    await repo.insert(speciesId: speciesId, name: 'Petit');
    await repo.insert(speciesId: spId2, name: 'Adulte');
    final all = await repo.listAllActive();
    expect(all, hasLength(2));
  });

  test('archive on species does not delete categories (soft archive)', () async {
    final cId = await repo.insert(speciesId: speciesId, name: 'Petit');
    await species.archive(speciesId);
    // Category still exists in DB (no cascade on archive — only hard delete cascades).
    final all = await repo.listAllActive();
    expect(all.any((c) => c.id == cId), isTrue);
  });
}
