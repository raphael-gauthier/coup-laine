import 'package:drift/drift.dart';

import '../../domain/models/client.dart';
import '../../domain/models/coordinates.dart';
import '../../domain/models/intervention.dart';
import '../../domain/use_cases/client_status.dart';
import '../../infra/db/app_database.dart';
import 'manual_history_repository.dart';

class ClientRepository {
  final AppDatabase _db;
  final ManualHistoryRepository _manualHistory;
  ClientRepository(
    this._db, {
    required ManualHistoryRepository manualHistory,
  }) : _manualHistory = manualHistory;

  Future<int> insert(Client c) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.into(_db.clientsTable).insert(
          ClientsTableCompanion.insert(
            name: c.name,
            phone: Value(c.phone),
            addressLabel: c.addressLabel,
            postcode: c.postcode,
            city: c.city,
            lat: c.coordinates.lat,
            lon: c.coordinates.lon,
            sheepCountSmall: Value(c.sheepCountSmall),
            sheepCountLarge: Value(c.sheepCountLarge),
            isWaiting: Value(c.isWaiting),
            isBanned: Value(c.isBanned),
            lastShearingDate: Value(
              c.lastShearingDate?.millisecondsSinceEpoch,
            ),
            markerColorHex: Value(c.markerColorHex),
            needsDistanceRecompute:
                const Value(true), // new clients always need matrix sync
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<Client?> findById(int id) async {
    final row = await (_db.select(_db.clientsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<Client>> listAll() async {
    final rows = await (_db.select(_db.clientsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Client>> listWaitingReady() async {
    final rows = await (_db.select(_db.clientsTable)
          ..where((t) =>
              t.isWaiting.equals(true) &
              t.needsDistanceRecompute.equals(false)))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Client>> listNeedingRecompute() async {
    final rows = await (_db.select(_db.clientsTable)
          ..where((t) => t.needsDistanceRecompute.equals(true)))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<void> setWaiting({required int id, required bool isWaiting}) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      ClientsTableCompanion(
        isWaiting: Value(isWaiting),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setBanned(int id, bool isBanned) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      ClientsTableCompanion(
        isBanned: Value(isBanned),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> resetAllWaiting() async {
    await _db.update(_db.clientsTable).write(
      ClientsTableCompanion(
        isWaiting: const Value(false),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateAddress({
    required int id,
    required String addressLabel,
    required String postcode,
    required String city,
    required Coordinates coordinates,
  }) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      ClientsTableCompanion(
        addressLabel: Value(addressLabel),
        postcode: Value(postcode),
        city: Value(city),
        lat: Value(coordinates.lat),
        lon: Value(coordinates.lon),
        needsDistanceRecompute: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateBasics({
    required int id,
    required String name,
    String? phone,
    required int sheepCountSmall,
    required int sheepCountLarge,
  }) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      ClientsTableCompanion(
        name: Value(name),
        phone: Value(phone),
        sheepCountSmall: Value(sheepCountSmall),
        sheepCountLarge: Value(sheepCountLarge),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setRecomputeDone(int id) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      const ClientsTableCompanion(
        needsDistanceRecompute: Value(false),
      ),
    );
  }

  Future<void> setRecomputePending(int id) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      const ClientsTableCompanion(
        needsDistanceRecompute: Value(true),
      ),
    );
  }

  Future<List<(Client, ClientStatus)>> listAllWithStatus(
    DateTime seasonStartedAt,
  ) async {
    final clientRows = await (_db.select(_db.clientsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();

    final seasonEpochDays = seasonStartedAt.millisecondsSinceEpoch ~/ 86400000;
    final stopRows = await (_db.select(_db.tourStopsTable).join([
      innerJoin(
        _db.toursTable,
        _db.toursTable.id.equalsExp(_db.tourStopsTable.tourId),
      ),
    ])
          ..where(
            _db.tourStopsTable.clientId.isNotNull() &
                _db.toursTable.plannedDate.isBiggerOrEqualValue(seasonEpochDays),
          ))
        .get();

    final hasPlanned = <int>{};
    final hasCompleted = <int>{};
    for (final r in stopRows) {
      final stop = r.readTable(_db.tourStopsTable);
      final tour = r.readTable(_db.toursTable);
      final cid = stop.clientId;
      if (cid == null) continue;
      if (tour.status == 'completed') {
        hasCompleted.add(cid);
      } else if (tour.status == 'planned') {
        hasPlanned.add(cid);
      }
    }

    // Manual history entries inside the season also count as "done".
    final manualHits =
        await _manualHistory.listClientDatesSinceEpochDays(seasonEpochDays);
    for (final h in manualHits) {
      hasCompleted.add(h.clientId);
    }

    return [
      for (final row in clientRows)
        (() {
          final c = _toDomain(row);
          return (
            c,
            deriveStatus(
              c,
              hasCompletedTourThisSeason: hasCompleted.contains(row.id),
              hasPlannedTourThisSeason: hasPlanned.contains(row.id),
            ),
          );
        })(),
    ];
  }

  Future<(Client, ClientStatus)?> findByIdWithStatus(
    int id,
    DateTime seasonStartedAt,
  ) async {
    final c = await findById(id);
    if (c == null) return null;
    final seasonEpochDays = seasonStartedAt.millisecondsSinceEpoch ~/ 86400000;
    final stopRows = await (_db.select(_db.tourStopsTable).join([
      innerJoin(
        _db.toursTable,
        _db.toursTable.id.equalsExp(_db.tourStopsTable.tourId),
      ),
    ])
          ..where(
            _db.tourStopsTable.clientId.equals(id) &
                _db.toursTable.plannedDate.isBiggerOrEqualValue(seasonEpochDays),
          ))
        .get();

    var hasPlanned = false;
    var hasCompleted = false;
    for (final r in stopRows) {
      final tour = r.readTable(_db.toursTable);
      if (tour.status == 'completed') hasCompleted = true;
      if (tour.status == 'planned') hasPlanned = true;
    }

    // Manual history entries inside the season also count as "done".
    final manualHits =
        await _manualHistory.listClientDatesSinceEpochDays(seasonEpochDays);
    if (manualHits.any((h) => h.clientId == id)) {
      hasCompleted = true;
    }

    return (
      c,
      deriveStatus(
        c,
        hasCompletedTourThisSeason: hasCompleted,
        hasPlannedTourThisSeason: hasPlanned,
      ),
    );
  }

  /// Returns the client's intervention history — completed tour stops merged
  /// with manual history entries — sorted by date desc.
  Future<List<Intervention>> listInterventionsForClient(int clientId) async {
    // Source 1 — tour stops on completed tours.
    final stopRows = await (_db.select(_db.tourStopsTable).join([
      innerJoin(
        _db.toursTable,
        _db.toursTable.id.equalsExp(_db.tourStopsTable.tourId),
      ),
    ])
          ..where(
            _db.tourStopsTable.clientId.equals(clientId) &
                _db.toursTable.status.equals('completed'),
          ))
        .get();

    final tourInterventions = <Intervention>[
      for (final r in stopRows)
        () {
          final stop = r.readTable(_db.tourStopsTable);
          final tour = r.readTable(_db.toursTable);
          final hasBilan =
              stop.actualSmall != null && stop.actualLarge != null;
          final utc = DateTime.fromMillisecondsSinceEpoch(
            tour.plannedDate * 86400000,
            isUtc: true,
          );
          return Intervention(
            kind: InterventionKind.tour,
            tourId: tour.id,
            stopId: stop.id,
            date: DateTime(utc.year, utc.month, utc.day),
            small: stop.actualSmall ?? stop.plannedSmall,
            large: stop.actualLarge ?? stop.plannedLarge,
            note: stop.interventionNote,
            hasBilan: hasBilan,
          );
        }(),
    ];

    // Source 2 — manual entries.
    final manualEntries = await _manualHistory.listForClient(clientId);
    final manualInterventions = <Intervention>[
      for (final e in manualEntries)
        Intervention(
          kind: InterventionKind.manual,
          manualEntryId: e.id,
          date: e.date,
          small: e.small,
          large: e.large,
          note: e.note,
          hasBilan: true,
        ),
    ];

    final merged = [...tourInterventions, ...manualInterventions]
      ..sort((a, b) => b.date.compareTo(a.date));
    return merged;
  }

  /// Persists the actual sheep counts captured during a tour completion onto
  /// the client's stored counts, and bumps `lastShearingDate` to the tour's
  /// planned date. Does not mutate `isWaiting` (status now derives from
  /// completed tour membership).
  Future<void> applyInterventionActuals(
    int clientId, {
    required int small,
    required int large,
    required DateTime tourDate,
  }) async {
    await (_db.update(_db.clientsTable)
          ..where((t) => t.id.equals(clientId)))
        .write(
      ClientsTableCompanion(
        sheepCountSmall: Value(small),
        sheepCountLarge: Value(large),
        lastShearingDate: Value(tourDate.millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Applies a manual history entry's effects to the client's denormalized
  /// state, BUT only if the entry's date is strictly more recent than the
  /// current `lastShearingDate` (or the client has never been shorn).
  ///
  /// Strict `>` is intentional: an entry on the same day as an existing
  /// `lastShearingDate` is treated as a no-op to keep behavior idempotent.
  Future<void> applyManualEntryToClient(
    int clientId, {
    required DateTime date,
    required int small,
    required int large,
  }) async {
    final c = await findById(clientId);
    if (c == null) return;
    final entryMs = DateTime(date.year, date.month, date.day)
        .millisecondsSinceEpoch;
    final currentMs = c.lastShearingDate?.millisecondsSinceEpoch;
    if (currentMs != null && entryMs <= currentMs) return;

    await (_db.update(_db.clientsTable)
          ..where((t) => t.id.equals(clientId)))
        .write(
      ClientsTableCompanion(
        sheepCountSmall: Value(small),
        sheepCountLarge: Value(large),
        lastShearingDate: Value(entryMs),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Recomputes the client's denormalized state from the union of
  /// {tour-stops on completed tours, manual history entries}, picking the
  /// most recent date and applying its `(small, large, date)`. If no source
  /// exists, sets `lastShearingDate` to null and leaves the counts as-is
  /// (we don't snapshot earlier counts to revert to).
  Future<void> recomputeClientFromHistory(int clientId) async {
    final list = await listInterventionsForClient(clientId);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (list.isEmpty) {
      await (_db.update(_db.clientsTable)
            ..where((t) => t.id.equals(clientId)))
          .write(
        ClientsTableCompanion(
          lastShearingDate: const Value(null),
          updatedAt: Value(now),
        ),
      );
      return;
    }

    // listInterventionsForClient is already sorted desc by date.
    final newest = list.first;
    final newestMs = DateTime(
      newest.date.year,
      newest.date.month,
      newest.date.day,
    ).millisecondsSinceEpoch;

    await (_db.update(_db.clientsTable)
          ..where((t) => t.id.equals(clientId)))
        .write(
      ClientsTableCompanion(
        sheepCountSmall: Value(newest.small),
        sheepCountLarge: Value(newest.large),
        lastShearingDate: Value(newestMs),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.clientsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setMarkerColor(int id, String? hex) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id)))
        .write(ClientsTableCompanion(markerColorHex: Value(hex)));
  }

  Client _toDomain(ClientRow row) => Client(
        id: row.id,
        name: row.name,
        phone: row.phone,
        addressLabel: row.addressLabel,
        postcode: row.postcode,
        city: row.city,
        coordinates: Coordinates(lat: row.lat, lon: row.lon),
        sheepCountSmall: row.sheepCountSmall,
        sheepCountLarge: row.sheepCountLarge,
        markerColorHex: row.markerColorHex,
        isWaiting: row.isWaiting,
        isBanned: row.isBanned,
        lastShearingDate: row.lastShearingDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.lastShearingDate!),
        needsDistanceRecompute: row.needsDistanceRecompute,
      );
}
