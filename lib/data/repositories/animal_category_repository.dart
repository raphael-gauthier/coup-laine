import 'package:drift/drift.dart';

import '../../domain/models/animal_category.dart';
import '../../infra/db/app_database.dart';

class AnimalCategoryRepository {
  final AppDatabase _db;
  AnimalCategoryRepository(this._db);

  Future<int> insert({
    required int speciesId,
    required String name,
    int? defaultMinutes,
    int? defaultPriceCents,
  }) {
    return _db.into(_db.animalCategoriesTable).insert(
          AnimalCategoriesTableCompanion.insert(
            speciesId: speciesId,
            name: name,
            defaultMinutes: Value(defaultMinutes),
            defaultPriceCents: Value(defaultPriceCents),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> rename({required int id, required String name}) async {
    await (_db.update(_db.animalCategoriesTable)
          ..where((c) => c.id.equals(id)))
        .write(AnimalCategoriesTableCompanion(name: Value(name)));
  }

  Future<void> updateDefaults({
    required int id,
    int? defaultMinutes,
    int? defaultPriceCents,
  }) async {
    await (_db.update(_db.animalCategoriesTable)
          ..where((c) => c.id.equals(id)))
        .write(AnimalCategoriesTableCompanion(
      defaultMinutes: Value(defaultMinutes),
      defaultPriceCents: Value(defaultPriceCents),
    ));
  }

  Future<void> archive(int id) async {
    await (_db.update(_db.animalCategoriesTable)
          ..where((c) => c.id.equals(id)))
        .write(AnimalCategoriesTableCompanion(
      archivedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> unarchive(int id) async {
    await (_db.update(_db.animalCategoriesTable)
          ..where((c) => c.id.equals(id)))
        .write(const AnimalCategoriesTableCompanion(archivedAt: Value(null)));
  }

  Future<List<AnimalCategory>> listAll() async {
    final rows = await (_db.select(_db.animalCategoriesTable)
          ..orderBy([(c) => OrderingTerm(expression: c.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<AnimalCategory>> listAllActive() async {
    final rows = await (_db.select(_db.animalCategoriesTable)
          ..where((c) => c.archivedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<AnimalCategory>> listActiveBySpecies(int speciesId) async {
    final rows = await (_db.select(_db.animalCategoriesTable)
          ..where((c) => c.speciesId.equals(speciesId) & c.archivedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<AnimalCategory>> listAllBySpecies(int speciesId) async {
    final rows = await (_db.select(_db.animalCategoriesTable)
          ..where((c) => c.speciesId.equals(speciesId))
          ..orderBy([(c) => OrderingTerm(expression: c.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  AnimalCategory _toDomain(AnimalCategoryRow row) => AnimalCategory(
        id: row.id,
        speciesId: row.speciesId,
        name: row.name,
        defaultMinutes: row.defaultMinutes,
        defaultPriceCents: row.defaultPriceCents,
        archivedAt: row.archivedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!),
      );
}
