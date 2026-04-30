import 'package:drift/drift.dart';

import '../../domain/models/manual_history_entry.dart';
import '../../infra/db/app_database.dart';

class ManualHistoryRepository {
  final AppDatabase _db;
  ManualHistoryRepository(this._db);

  Future<int> insert({
    required int clientId,
    required DateTime date,
    required int small,
    required int large,
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.into(_db.manualHistoryEntriesTable).insert(
          ManualHistoryEntriesTableCompanion.insert(
            clientId: clientId,
            date: _toEpochDays(date),
            sheepCountSmall: Value(small),
            sheepCountLarge: Value(large),
            note: Value(note),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> update(
    int id, {
    required DateTime date,
    required int small,
    required int large,
    String? note,
  }) async {
    await (_db.update(_db.manualHistoryEntriesTable)
          ..where((t) => t.id.equals(id)))
        .write(
      ManualHistoryEntriesTableCompanion(
        date: Value(_toEpochDays(date)),
        sheepCountSmall: Value(small),
        sheepCountLarge: Value(large),
        note: Value(note),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.manualHistoryEntriesTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<List<ManualHistoryEntry>> listForClient(int clientId) async {
    final rows = await (_db.select(_db.manualHistoryEntriesTable)
          ..where((t) => t.clientId.equals(clientId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  /// Returns `(clientId, dateEpochDays)` pairs for every manual entry whose
  /// date is `>= seasonEpochDays`. Used by `ClientRepository.listAllWithStatus`
  /// to mark clients as "done this season" when they only have a manual entry.
  Future<List<({int clientId, int dateEpochDays})>>
      listClientDatesSinceEpochDays(int seasonEpochDays) async {
    final rows = await (_db.select(_db.manualHistoryEntriesTable)
          ..where((t) => t.date.isBiggerOrEqualValue(seasonEpochDays)))
        .get();
    return [
      for (final r in rows)
        (clientId: r.clientId, dateEpochDays: r.date),
    ];
  }

  static int _toEpochDays(DateTime d) {
    final utc = DateTime.utc(d.year, d.month, d.day);
    return utc.millisecondsSinceEpoch ~/ 86400000;
  }

  ManualHistoryEntry _toDomain(ManualHistoryEntryRow r) {
    final utc = DateTime.fromMillisecondsSinceEpoch(
      r.date * 86400000,
      isUtc: true,
    );
    return ManualHistoryEntry(
      id: r.id,
      clientId: r.clientId,
      date: DateTime(utc.year, utc.month, utc.day),
      small: r.sheepCountSmall,
      large: r.sheepCountLarge,
      note: r.note,
    );
  }
}
