import 'package:drift/drift.dart';

import '../../domain/models/species.dart';
import '../../infra/db/app_database.dart';
import '../../infra/db/tables.dart';

class SpeciesRepository {
  final AppDatabase _db;
  SpeciesRepository(this._db);

  Future<int> insert({required String name, String? iconKey}) async {
    return _db.into(_db.speciesTable).insert(
          SpeciesTableCompanion.insert(
            name: name,
            iconKey: Value(iconKey),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> rename({required int id, required String name}) async {
    await (_db.update(_db.speciesTable)..where((s) => s.id.equals(id)))
        .write(SpeciesTableCompanion(name: Value(name)));
  }

  Future<void> archive(int id) async {
    await (_db.update(_db.speciesTable)..where((s) => s.id.equals(id))).write(
      SpeciesTableCompanion(
        archivedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> unarchive(int id) async {
    await (_db.update(_db.speciesTable)..where((s) => s.id.equals(id)))
        .write(const SpeciesTableCompanion(archivedAt: Value(null)));
  }

  Future<List<Species>> listActive() async {
    final rows = await (_db.select(_db.speciesTable)
          ..where((s) => s.archivedAt.isNull())
          ..orderBy([(s) => OrderingTerm(expression: s.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Species>> listArchived() async {
    final rows = await (_db.select(_db.speciesTable)
          ..where((s) => s.archivedAt.isNotNull())
          ..orderBy([(s) => OrderingTerm(expression: s.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Species>> listAll() async {
    final rows = await (_db.select(_db.speciesTable)
          ..orderBy([(s) => OrderingTerm(expression: s.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<int> countActive() async {
    final rows = await (_db.select(_db.speciesTable)
          ..where((s) => s.archivedAt.isNull()))
        .get();
    return rows.length;
  }

  Species _toDomain(SpeciesRow row) => Species(
        id: row.id,
        name: row.name,
        iconKey: row.iconKey,
        archivedAt: row.archivedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!),
      );
}
