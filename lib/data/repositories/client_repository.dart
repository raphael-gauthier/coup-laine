import 'package:drift/drift.dart';

import '../../domain/models/client.dart';
import '../../domain/models/coordinates.dart';
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
            sheepCount: Value(c.sheepCount),
            minutesPerSheepOverride: Value(c.minutesPerSheepOverride),
            notes: Value(c.notes),
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
    required int sheepCount,
    int? minutesPerSheepOverride,
    String? notes,
  }) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      ClientsTableCompanion(
        name: Value(name),
        phone: Value(phone),
        sheepCount: Value(sheepCount),
        minutesPerSheepOverride: Value(minutesPerSheepOverride),
        notes: Value(notes),
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
        sheepCount: row.sheepCount,
        minutesPerSheepOverride: row.minutesPerSheepOverride,
        notes: row.notes,
        markerColorHex: row.markerColorHex,
        isWaiting: row.isWaiting,
        isBanned: row.isBanned,
        lastShearingDate: row.lastShearingDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.lastShearingDate!),
        needsDistanceRecompute: row.needsDistanceRecompute,
      );
}
