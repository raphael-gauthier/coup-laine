import 'package:drift/drift.dart';

import '../../core/animal_counts_normalizer.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/tour.dart';
import '../../domain/models/tour_stop.dart';
import '../../domain/models/tour_stop_animal.dart';
import '../../infra/db/app_database.dart';

class TourStopDraft {
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final List<TourStopAnimal> planned;
  final int feeShareCents;

  const TourStopDraft({
    required this.clientNameSnapshot,
    required this.orderIndex,
    required this.estimatedArrivalMinutes,
    required this.estimatedDepartureMinutes,
    required this.planned,
    required this.feeShareCents,
    this.clientId,
  });
}

class TourDraft {
  final DateTime plannedDate;
  final int startTimeMinutes;
  final int totalDistanceMeters;
  final int totalDriveSeconds;
  final int totalTravelFeeCents;
  final String? notes;
  final List<TourStopDraft> stops;

  const TourDraft({
    required this.plannedDate,
    required this.startTimeMinutes,
    required this.totalDistanceMeters,
    required this.totalDriveSeconds,
    required this.totalTravelFeeCents,
    required this.stops,
    this.notes,
  });
}

class TourWithStops {
  final Tour tour;
  final List<TourStop> stops;
  const TourWithStops({required this.tour, required this.stops});
}

class TourRepository {
  final AppDatabase _db;
  TourRepository(this._db);

  Future<int> plan(TourDraft draft) async {
    return _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final tourId = await _db.into(_db.toursTable).insert(
            ToursTableCompanion.insert(
              plannedDate: _toEpochDay(draft.plannedDate),
              startTimeMinutes: draft.startTimeMinutes,
              status: 'planned',
              totalDistanceMeters: draft.totalDistanceMeters,
              totalDriveSeconds: draft.totalDriveSeconds,
              totalTravelFeeCents: draft.totalTravelFeeCents,
              notes: Value(draft.notes),
              createdAt: now,
            ),
          );
      for (final s in draft.stops) {
        await _db.into(_db.tourStopsTable).insert(
              TourStopsTableCompanion.insert(
                tourId: tourId,
                clientId: Value(s.clientId),
                clientNameSnapshot: s.clientNameSnapshot,
                orderIndex: s.orderIndex,
                estimatedArrivalMinutes: s.estimatedArrivalMinutes,
                estimatedDepartureMinutes: s.estimatedDepartureMinutes,
                plannedAnimals: Value(normalizeTourStopAnimals(s.planned)),
                feeShareCents: s.feeShareCents,
              ),
            );
      }
      return tourId;
    });
  }

  Future<TourWithStops?> findById(int id) async {
    final tourRow = await (_db.select(_db.toursTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (tourRow == null) return null;
    final stopRows = await (_db.select(_db.tourStopsTable)
          ..where((s) => s.tourId.equals(id))
          ..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]))
        .get();
    return TourWithStops(
      tour: _tourFromRow(tourRow),
      stops: stopRows.map(_stopFromRow).toList(),
    );
  }

  Future<List<Tour>> listAll() async {
    final rows = await (_db.select(_db.toursTable)
          ..orderBy([(t) => OrderingTerm.desc(t.plannedDate)]))
        .get();
    return rows.map(_tourFromRow).toList();
  }

  /// Mark a tour as completed. The caller passes a map keyed by `stop.id`
  /// containing the actual animal counts and an optional note. For each stop
  /// with a non-null `clientId`, the corresponding client's stored animals
  /// are merged per `categoryId` (actuals overwrite per-category, other
  /// categories untouched) and `lastShearingDate` is bumped to the tour's
  /// planned date.
  Future<void> markCompleted(
    int id,
    Map<int, ({List<TourStopAnimal> actuals, String? note})> actuals,
  ) async {
    await _db.transaction(() async {
      final tour = await (_db.select(_db.toursTable)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      final now = DateTime.now().millisecondsSinceEpoch;
      final tourDateUtc = DateTime.fromMillisecondsSinceEpoch(
          tour.plannedDate * 86400000,
          isUtc: true);
      final tourDate =
          DateTime(tourDateUtc.year, tourDateUtc.month, tourDateUtc.day);

      // 1. Status flip.
      await (_db.update(_db.toursTable)..where((t) => t.id.equals(id))).write(
        ToursTableCompanion(
          status: const Value('completed'),
          completedAt: Value(now),
        ),
      );

      // 2. For each stop: persist actuals + note, then sync the linked client.
      final stopRows = await (_db.select(_db.tourStopsTable)
            ..where((s) => s.tourId.equals(id)))
          .get();

      for (final s in stopRows) {
        final entry = actuals[s.id];
        if (entry == null) continue;
        final normalized = normalizeTourStopAnimals(entry.actuals);

        await (_db.update(_db.tourStopsTable)
              ..where((t) => t.id.equals(s.id)))
            .write(
          TourStopsTableCompanion(
            actualAnimals: Value(normalized),
            interventionNote: Value(entry.note),
          ),
        );

        final cid = s.clientId;
        if (cid != null) {
          // Sync the client's stored animals: merge actuals into client.animals
          // by categoryId (actuals overwrite per-category, others untouched).
          final clientRow = await (_db.select(_db.clientsTable)
                ..where((c) => c.id.equals(cid)))
              .getSingleOrNull();
          if (clientRow != null) {
            final byId = <int, int>{
              for (final a in clientRow.animals) a.categoryId: a.count,
            };
            for (final a in normalized) {
              byId[a.categoryId] = a.count;
            }
            final mergedAnimals = normalizeAnimalCounts([
              for (final entry in byId.entries)
                AnimalCount(categoryId: entry.key, count: entry.value),
            ]);
            await (_db.update(_db.clientsTable)
                  ..where((c) => c.id.equals(cid)))
                .write(
              ClientsTableCompanion(
                animals: Value(mergedAnimals),
                lastShearingDate: Value(tourDate.millisecondsSinceEpoch),
                updatedAt: Value(now),
              ),
            );
          }
        }
      }
    });
  }

  /// Replace the contents of a planned tour: tour totals, date, start time,
  /// notes, and the entire stops list. Stop ids are not preserved (we delete
  /// then reinsert) — there is no consumer that holds onto them.
  ///
  /// Status, completedAt, id and createdAt are intentionally left untouched.
  /// The caller (UI) must only invoke this for tours with status `planned`.
  Future<void> update(int id, TourDraft draft) async {
    await _db.transaction(() async {
      await (_db.update(_db.toursTable)..where((t) => t.id.equals(id))).write(
        ToursTableCompanion(
          plannedDate: Value(_toEpochDay(draft.plannedDate)),
          startTimeMinutes: Value(draft.startTimeMinutes),
          totalDistanceMeters: Value(draft.totalDistanceMeters),
          totalDriveSeconds: Value(draft.totalDriveSeconds),
          totalTravelFeeCents: Value(draft.totalTravelFeeCents),
          notes: Value(draft.notes),
        ),
      );

      await (_db.delete(_db.tourStopsTable)
            ..where((s) => s.tourId.equals(id)))
          .go();

      for (final s in draft.stops) {
        await _db.into(_db.tourStopsTable).insert(
              TourStopsTableCompanion.insert(
                tourId: id,
                clientId: Value(s.clientId),
                clientNameSnapshot: s.clientNameSnapshot,
                orderIndex: s.orderIndex,
                estimatedArrivalMinutes: s.estimatedArrivalMinutes,
                estimatedDepartureMinutes: s.estimatedDepartureMinutes,
                plannedAnimals: Value(normalizeTourStopAnimals(s.planned)),
                feeShareCents: s.feeShareCents,
              ),
            );
      }
    });
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.toursTable)..where((t) => t.id.equals(id))).go();
  }

  int _toEpochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
          86400000;

  Tour _tourFromRow(TourRow row) => Tour(
        id: row.id,
        plannedDate: () {
          final utc = DateTime.fromMillisecondsSinceEpoch(
              row.plannedDate * 86400000,
              isUtc: true);
          return DateTime(utc.year, utc.month, utc.day);
        }(),
        startTimeMinutes: row.startTimeMinutes,
        status: row.status == 'completed'
            ? TourStatus.completed
            : TourStatus.planned,
        totalDistanceMeters: row.totalDistanceMeters,
        totalDriveSeconds: row.totalDriveSeconds,
        totalTravelFeeCents: row.totalTravelFeeCents,
        notes: row.notes,
        completedAt: row.completedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.completedAt!),
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );

  TourStop _stopFromRow(TourStopRow row) => TourStop(
        id: row.id,
        tourId: row.tourId,
        clientId: row.clientId,
        clientNameSnapshot: row.clientNameSnapshot,
        orderIndex: row.orderIndex,
        estimatedArrivalMinutes: row.estimatedArrivalMinutes,
        estimatedDepartureMinutes: row.estimatedDepartureMinutes,
        planned: row.plannedAnimals,
        actual: row.actualAnimals,
        interventionNote: row.interventionNote,
        feeShareCents: row.feeShareCents,
      );
}
