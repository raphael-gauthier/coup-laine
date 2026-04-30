import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/data/repositories/species_repository.dart';
import 'package:coup_laine/infra/db/app_database.dart';

void main() {
  late AppDatabase db;
  late SpeciesRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SpeciesRepository(db);
  });

  tearDown(() async => db.close());

  test('insert and list active', () async {
    final id = await repo.insert(name: 'Mouton');
    final active = await repo.listActive();
    expect(active, hasLength(1));
    expect(active.first.id, id);
    expect(active.first.name, 'Mouton');
    expect(active.first.archivedAt, isNull);
  });

  test('rename updates name', () async {
    final id = await repo.insert(name: 'Mouton');
    await repo.rename(id: id, name: 'Ovin');
    final s = (await repo.listActive()).single;
    expect(s.name, 'Ovin');
  });

  test('archive sets archivedAt; listActive excludes; listArchived includes',
      () async {
    final id = await repo.insert(name: 'Mouton');
    await repo.archive(id);
    expect(await repo.listActive(), isEmpty);
    final archived = await repo.listArchived();
    expect(archived, hasLength(1));
    expect(archived.first.archivedAt, isNotNull);
  });

  test('unarchive clears archivedAt', () async {
    final id = await repo.insert(name: 'Mouton');
    await repo.archive(id);
    await repo.unarchive(id);
    expect(await repo.listActive(), hasLength(1));
    expect(await repo.listArchived(), isEmpty);
  });

  test('countActive', () async {
    expect(await repo.countActive(), 0);
    final a = await repo.insert(name: 'Mouton');
    await repo.insert(name: 'Cheval');
    expect(await repo.countActive(), 2);
    await repo.archive(a);
    expect(await repo.countActive(), 1);
  });
}
