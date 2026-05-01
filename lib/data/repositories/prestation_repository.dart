import 'package:drift/drift.dart';

import '../../domain/models/prestation.dart';
import '../../infra/db/app_database.dart';

class PrestationRepository {
  final AppDatabase _db;
  PrestationRepository(this._db);

  Future<int> insert({
    required String name,
    int? priceCents,
    int? minutes,
    required int? categoryId,
  }) {
    return _db.into(_db.prestationsTable).insert(
          PrestationsTableCompanion.insert(
            name: name,
            priceCents: Value(priceCents),
            minutes: Value(minutes),
            categoryId: Value(categoryId),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> rename({required int id, required String name}) async {
    await (_db.update(_db.prestationsTable)..where((p) => p.id.equals(id)))
        .write(PrestationsTableCompanion(name: Value(name)));
  }

  Future<void> updateValues({
    required int id,
    int? priceCents,
    int? minutes,
  }) async {
    await (_db.update(_db.prestationsTable)..where((p) => p.id.equals(id)))
        .write(PrestationsTableCompanion(
      priceCents: Value(priceCents),
      minutes: Value(minutes),
    ));
  }

  Future<void> updateBinding({
    required int id,
    required int? categoryId,
  }) async {
    await (_db.update(_db.prestationsTable)..where((p) => p.id.equals(id)))
        .write(PrestationsTableCompanion(categoryId: Value(categoryId)));
  }

  Future<void> archive(int id) async {
    await (_db.update(_db.prestationsTable)..where((p) => p.id.equals(id)))
        .write(PrestationsTableCompanion(
      archivedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> unarchive(int id) async {
    await (_db.update(_db.prestationsTable)..where((p) => p.id.equals(id)))
        .write(const PrestationsTableCompanion(archivedAt: Value(null)));
  }

  Future<List<Prestation>> listActive() async {
    final rows = await (_db.select(_db.prestationsTable)
          ..where((p) => p.archivedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Prestation>> listArchived() async {
    final rows = await (_db.select(_db.prestationsTable)
          ..where((p) => p.archivedAt.isNotNull())
          ..orderBy([(p) => OrderingTerm(expression: p.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Prestation>> listAll() async {
    final rows = await (_db.select(_db.prestationsTable)
          ..orderBy([(p) => OrderingTerm(expression: p.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Prestation>> listByCategory(int categoryId) async {
    final rows = await (_db.select(_db.prestationsTable)
          ..where((p) =>
              p.categoryId.equals(categoryId) & p.archivedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.id)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<int> countActive() async {
    final rows = await (_db.select(_db.prestationsTable)
          ..where((p) => p.archivedAt.isNull()))
        .get();
    return rows.length;
  }

  Prestation _toDomain(PrestationRow row) => Prestation(
        id: row.id,
        name: row.name,
        priceCents: row.priceCents,
        minutes: row.minutes,
        categoryId: row.categoryId,
        archivedAt: row.archivedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!),
      );
}
