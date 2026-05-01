import 'package:drift/drift.dart';

import '../../core/animal_counts_normalizer.dart';
import '../../core/phone_normalizer.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/client.dart';
import '../../domain/models/coordinates.dart';
import '../../domain/models/intervention.dart';
import '../../domain/models/tour_stop_animal.dart';
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
            phones: Value(normalizePhones(c.phones)),
            addressLabel: c.addressLabel,
            postcode: c.postcode,
            city: c.city,
            lat: c.coordinates.lat,
            lon: c.coordinates.lon,
            animals: Value(normalizeAnimalCounts(c.animals)),
            isWaiting: Value(c.isWaiting),
            isBanned: Value(c.isBanned),
            lastInterventionDate: Value(
              c.lastInterventionDate?.millisecondsSinceEpoch,
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
    required List<String> phones,
    required List<AnimalCount> animals,
  }) async {
    await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id))).write(
      ClientsTableCompanion(
        name: Value(name),
        phones: Value(normalizePhones(phones)),
        animals: Value(normalizeAnimalCounts(animals)),
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
          final hasBilan = stop.actualAnimals != null;
          final utc = DateTime.fromMillisecondsSinceEpoch(
            tour.plannedDate * 86400000,
            isUtc: true,
          );
          return Intervention(
            kind: InterventionKind.tour,
            tourId: tour.id,
            stopId: stop.id,
            date: DateTime(utc.year, utc.month, utc.day),
            animals: stop.actualAnimals ?? stop.plannedAnimals,
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
          animals: e.animals,
          note: e.note,
          hasBilan: true,
        ),
    ];

    final merged = [...tourInterventions, ...manualInterventions]
      ..sort((a, b) => b.date.compareTo(a.date));
    return merged;
  }

  /// Returns a `clientId → notes` map that aggregates non-empty intervention
  /// notes from BOTH sources (completed tour stops + manual history entries),
  /// for every client at once. Used by the client-list search to match
  /// against historical notes.
  Future<Map<int, List<String>>> loadClientNotesMap() async {
    final result = <int, List<String>>{};

    final stopRows = await (_db.select(_db.tourStopsTable).join([
      innerJoin(
        _db.toursTable,
        _db.toursTable.id.equalsExp(_db.tourStopsTable.tourId),
      ),
    ])
          ..where(
            _db.tourStopsTable.clientId.isNotNull() &
                _db.tourStopsTable.interventionNote.isNotNull() &
                _db.toursTable.status.equals('completed'),
          ))
        .get();
    for (final r in stopRows) {
      final stop = r.readTable(_db.tourStopsTable);
      final cid = stop.clientId;
      final note = stop.interventionNote;
      if (cid == null || note == null || note.isEmpty) continue;
      (result[cid] ??= <String>[]).add(note);
    }

    final manualRows = await (_db.select(_db.manualHistoryEntriesTable)
          ..where((t) => t.note.isNotNull()))
        .get();
    for (final r in manualRows) {
      final note = r.note;
      if (note == null || note.isEmpty) continue;
      (result[r.clientId] ??= <String>[]).add(note);
    }

    return result;
  }

  /// Persists the actuals captured during a tour completion onto the client's
  /// stored animal counts, merging per `categoryId` (entries in [actuals]
  /// overwrite the matching category, others untouched). Bumps
  /// `lastInterventionDate` to [tourDate]. Does not mutate `isWaiting` (status now
  /// derives from completed tour membership).
  Future<void> applyInterventionActuals(
    int clientId, {
    required List<TourStopAnimal> actuals,
    required DateTime tourDate,
  }) async {
    final c = await findById(clientId);
    if (c == null) return;
    final merged = _mergePerCategory(c.animals, actuals);
    await (_db.update(_db.clientsTable)
          ..where((t) => t.id.equals(clientId)))
        .write(
      ClientsTableCompanion(
        animals: Value(merged),
        lastInterventionDate: Value(tourDate.millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Applies a manual history entry's effects to the client's denormalized
  /// state, BUT only if the entry's date is strictly more recent than the
  /// current `lastInterventionDate` (or the client has no prior intervention).
  ///
  /// Strict `>` is intentional: an entry on the same day as an existing
  /// `lastInterventionDate` is treated as a no-op to keep behavior idempotent.
  Future<void> applyManualEntryToClient(
    int clientId, {
    required DateTime date,
    required List<TourStopAnimal> animals,
  }) async {
    final c = await findById(clientId);
    if (c == null) return;
    final entryMs = DateTime(date.year, date.month, date.day)
        .millisecondsSinceEpoch;
    final currentMs = c.lastInterventionDate?.millisecondsSinceEpoch;
    if (currentMs != null && entryMs <= currentMs) return;

    final merged = _mergePerCategory(c.animals, animals);
    await (_db.update(_db.clientsTable)
          ..where((t) => t.id.equals(clientId)))
        .write(
      ClientsTableCompanion(
        animals: Value(merged),
        lastInterventionDate: Value(entryMs),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Recomputes the client's denormalized state from the union of
  /// {tour-stops on completed tours, manual history entries}. For each
  /// `categoryId` involved, picks the count from the most recent intervention
  /// that mentions it. `lastInterventionDate` is set to the newest date. If no
  /// source exists, animals become empty and `lastInterventionDate` is null.
  Future<void> recomputeClientFromHistory(int clientId) async {
    final list = await listInterventionsForClient(clientId);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (list.isEmpty) {
      await (_db.update(_db.clientsTable)
            ..where((t) => t.id.equals(clientId)))
          .write(
        ClientsTableCompanion(
          animals: const Value([]),
          lastInterventionDate: const Value(null),
          updatedAt: Value(now),
        ),
      );
      return;
    }

    // listInterventionsForClient is sorted desc by date — for each categoryId,
    // the first occurrence wins (= most recent).
    final byId = <int, int>{};
    for (final iv in list) {
      for (final a in iv.animals) {
        byId.putIfAbsent(a.categoryId, () => a.count);
      }
    }
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
        animals: Value(normalizeAnimalCounts([
          for (final e in byId.entries)
            AnimalCount(categoryId: e.key, count: e.value),
        ])),
        lastInterventionDate: Value(newestMs),
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
        phones: row.phones,
        addressLabel: row.addressLabel,
        postcode: row.postcode,
        city: row.city,
        coordinates: Coordinates(lat: row.lat, lon: row.lon),
        animals: row.animals,
        markerColorHex: row.markerColorHex,
        isWaiting: row.isWaiting,
        isBanned: row.isBanned,
        lastInterventionDate: row.lastInterventionDate == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.lastInterventionDate!),
        needsDistanceRecompute: row.needsDistanceRecompute,
      );

  /// Merges [incoming] into [existing] per `categoryId`. Entries in [incoming]
  /// overwrite the count for matching ids; other categories remain untouched.
  /// Result is normalized (sorted, zeros dropped, dedup-summed).
  List<AnimalCount> _mergePerCategory(
    List<AnimalCount> existing,
    List<TourStopAnimal> incoming,
  ) {
    final byId = <int, int>{
      for (final a in existing) a.categoryId: a.count,
    };
    for (final a in incoming) {
      byId[a.categoryId] = a.count;
    }
    return normalizeAnimalCounts([
      for (final entry in byId.entries)
        AnimalCount(categoryId: entry.key, count: entry.value),
    ]);
  }
}
