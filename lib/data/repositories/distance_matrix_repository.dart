import 'package:drift/drift.dart';

import '../../domain/models/distance_matrix_entry.dart';
import '../../infra/db/app_database.dart';

class DistanceMatrixRepository {
  final AppDatabase _db;
  DistanceMatrixRepository(this._db);

  Future<void> upsertMany(List<DistanceMatrixEntry> entries) async {
    await _db.batch((batch) {
      for (final e in entries) {
        batch.insert(
          _db.distanceMatrixTable,
          DistanceMatrixTableCompanion.insert(
            fromId: e.fromId,
            toId: e.toId,
            distanceMeters: e.distanceMeters,
            durationSeconds: e.durationSeconds,
            computedAt: e.computedAt.millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<int?> distanceMeters({required int from, required int to}) async {
    final row = await (_db.select(_db.distanceMatrixTable)
          ..where((t) => t.fromId.equals(from) & t.toId.equals(to)))
        .getSingleOrNull();
    return row?.distanceMeters;
  }

  Future<int?> durationSeconds({required int from, required int to}) async {
    final row = await (_db.select(_db.distanceMatrixTable)
          ..where((t) => t.fromId.equals(from) & t.toId.equals(to)))
        .getSingleOrNull();
    return row?.durationSeconds;
  }

  Future<List<DistanceMatrixEntry>> distancesFromPivot({
    required int pivotId,
    required int maxDistanceMeters,
  }) async {
    final rows = await (_db.select(_db.distanceMatrixTable)
          ..where((t) =>
              t.fromId.equals(pivotId) &
              t.distanceMeters.isSmallerOrEqualValue(maxDistanceMeters) &
              t.toId.equals(pivotId).not() &
              t.toId.equals(DistanceMatrixEntry.baseId).not()))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<void> deleteForClient(int clientId) async {
    await (_db.delete(_db.distanceMatrixTable)
          ..where((t) =>
              t.fromId.equals(clientId) | t.toId.equals(clientId)))
        .go();
  }

  Future<void> deleteAll() async {
    await _db.delete(_db.distanceMatrixTable).go();
  }

  Future<int> countForNode(int id) async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS c FROM distance_matrix '
      'WHERE from_id = ? OR to_id = ?',
      variables: [Variable.withInt(id), Variable.withInt(id)],
      readsFrom: {_db.distanceMatrixTable},
    ).getSingle();
    return result.data['c'] as int;
  }

  DistanceMatrixEntry _toDomain(DistanceMatrixRow row) => DistanceMatrixEntry(
        fromId: row.fromId,
        toId: row.toId,
        distanceMeters: row.distanceMeters,
        durationSeconds: row.durationSeconds,
        computedAt:
            DateTime.fromMillisecondsSinceEpoch(row.computedAt),
      );
}
