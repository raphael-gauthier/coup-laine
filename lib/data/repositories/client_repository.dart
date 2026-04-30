import 'package:drift/drift.dart';

import '../../domain/models/client.dart';
import '../../domain/models/coordinates.dart';
import '../../domain/models/intervention.dart';
import '../../domain/use_cases/client_status.dart';
import '../../infra/db/app_database.dart';

class ClientRepository {
  final AppDatabase _db;
  ClientRepository(this._db);

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
    return (
      c,
      deriveStatus(
        c,
        hasCompletedTourThisSeason: hasCompleted,
        hasPlannedTourThisSeason: hasPlanned,
      ),
    );
  }

  /// Returns the client's intervention history — i.e. every `tour_stop`
  /// belonging to a `tour` whose status is `'completed'`, sorted by tour
  /// date desc. For pre-v6 stops (without `actual_*`), falls back to the
  /// planned snapshots and flags the row with `hasBilan: false`.
  Future<List<Intervention>> listInterventionsForClient(int clientId) async {
    final rows = await (_db.select(_db.tourStopsTable).join([
      innerJoin(
        _db.toursTable,
        _db.toursTable.id.equalsExp(_db.tourStopsTable.tourId),
      ),
    ])
          ..where(
            _db.tourStopsTable.clientId.equals(clientId) &
                _db.toursTable.status.equals('completed'),
          )
          ..orderBy([
            OrderingTerm.desc(_db.toursTable.plannedDate),
          ]))
        .get();

    return [
      for (final r in rows)
        () {
          final stop = r.readTable(_db.tourStopsTable);
          final tour = r.readTable(_db.toursTable);
          final hasBilan = stop.actualSmall != null && stop.actualLarge != null;
          return Intervention(
            kind: InterventionKind.tour,
            tourId: tour.id,
            stopId: stop.id,
            date: () {
              final utc = DateTime.fromMillisecondsSinceEpoch(
                tour.plannedDate * 86400000,
                isUtc: true,
              );
              return DateTime(utc.year, utc.month, utc.day);
            }(),
            small: stop.actualSmall ?? stop.plannedSmall,
            large: stop.actualLarge ?? stop.plannedLarge,
            note: stop.interventionNote,
            hasBilan: hasBilan,
          );
        }(),
    ];
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
