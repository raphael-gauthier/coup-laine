import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/manual_history_repository.dart';
import 'package:coup_laine/data/repositories/tour_repository.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/intervention.dart';
import 'package:coup_laine/domain/use_cases/client_status.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Client _newClient({
  String name = 'Le Gall',
  bool isWaiting = false,
  bool needsDistanceRecompute = false,
  int sheepCountSmall = 12,
  int sheepCountLarge = 0,
}) {
  return Client(
    id: 0,
    name: name,
    addressLabel: '1 rue, 29000 Quimper',
    postcode: '29000',
    city: 'Quimper',
    coordinates: const Coordinates(lat: 48.0, lon: -4.1),
    sheepCountSmall: sheepCountSmall,
    sheepCountLarge: sheepCountLarge,
    isWaiting: isWaiting,
    needsDistanceRecompute: needsDistanceRecompute,
  );
}

void main() {
  late AppDatabase db;
  late ClientRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final manual = ManualHistoryRepository(db);
    repo = ClientRepository(db, manualHistory: manual);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert assigns id and reads back', () async {
    final id = await repo.insert(_newClient());
    expect(id, greaterThan(0));
    final read = await repo.findById(id);
    expect(read, isNotNull);
    expect(read!.name, 'Le Gall');
  });

  test('listWaitingReady excludes recompute-pending and non-waiting',
      () async {
    final aId = await repo.insert(_newClient(name: 'A', isWaiting: true));
    final bId = await repo.insert(_newClient(name: 'B', isWaiting: false));
    await repo.insert(_newClient(name: 'C', isWaiting: true)); // stays pending

    await repo.setRecomputeDone(aId);
    await repo.setRecomputeDone(bId);

    final waiting = await repo.listWaitingReady();
    expect(waiting.map((c) => c.name), ['A']);
  });

  test('toggleWaiting flips the flag', () async {
    final id = await repo.insert(_newClient(isWaiting: false));
    await repo.setWaiting(id: id, isWaiting: true);
    expect((await repo.findById(id))!.isWaiting, isTrue);
    await repo.setWaiting(id: id, isWaiting: false);
    expect((await repo.findById(id))!.isWaiting, isFalse);
  });

  test('delete removes the client', () async {
    final id = await repo.insert(_newClient());
    await repo.delete(id);
    expect(await repo.findById(id), isNull);
  });

  test('updateLocation marks needsDistanceRecompute', () async {
    final id = await repo.insert(_newClient());
    await repo.updateAddress(
      id: id,
      addressLabel: '2 rue, 29000 Quimper',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48.05, lon: -4.05),
    );
    final read = await repo.findById(id);
    expect(read!.needsDistanceRecompute, isTrue);
    expect(read.coordinates.lat, 48.05);
  });

  test('markerColorHex round-trip + setMarkerColor', () async {
    final id = await repo.insert(_newClient());
    expect((await repo.findById(id))!.markerColorHex, isNull);

    await repo.setMarkerColor(id, '#ABCDEF');
    expect((await repo.findById(id))!.markerColorHex, '#ABCDEF');

    await repo.setMarkerColor(id, null);
    expect((await repo.findById(id))!.markerColorHex, isNull);
  });

  test('setBanned flips the flag', () async {
    final id = await repo.insert(_newClient());
    expect((await repo.findById(id))!.isBanned, isFalse);
    await repo.setBanned(id, true);
    expect((await repo.findById(id))!.isBanned, isTrue);
    await repo.setBanned(id, false);
    expect((await repo.findById(id))!.isBanned, isFalse);
  });

  test('resetAllWaiting clears every isWaiting=true row', () async {
    final a = await repo.insert(_newClient(name: 'A', isWaiting: true));
    final b = await repo.insert(_newClient(name: 'B', isWaiting: true));
    final c = await repo.insert(_newClient(name: 'C', isWaiting: false));
    await repo.resetAllWaiting();
    expect((await repo.findById(a))!.isWaiting, isFalse);
    expect((await repo.findById(b))!.isWaiting, isFalse);
    expect((await repo.findById(c))!.isWaiting, isFalse);
  });

  test('listAllWithStatus derives status from flags + season tours', () async {
    final tours = TourRepository(db);

    // C1: default
    await repo.insert(_newClient(name: 'C1'));
    // C2: waiting flag
    await repo.insert(_newClient(name: 'C2', isWaiting: true));
    // C3: banned flag
    final c3 = await repo.insert(_newClient(name: 'C3', isWaiting: true));
    await repo.setBanned(c3, true);
    // C4: sheepCount = 0 (override _newClient default of 12)
    await db.into(db.clientsTable).insert(
      ClientsTableCompanion.insert(
        name: 'C4',
        addressLabel: 'a',
        postcode: '0',
        city: 'X',
        lat: 48,
        lon: -4,
        sheepCountSmall: const Value(0),
        sheepCountLarge: const Value(0),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    // C5: in a planned tour this season (planned date AFTER season start)
    final c5 = await repo.insert(_newClient(name: 'C5'));
    final season = DateTime(2026, 4, 1);
    await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 480,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: c5,
          clientNameSnapshot: 'C5',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          plannedSmall: 5,
          plannedLarge: 0,
          minutesPerSmallSnapshot: 8,
          minutesPerLargeSnapshot: 25,
          feeShareCents: 0,
        ),
      ],
    ));
    // C6: in a completed tour this season
    final c6 = await repo.insert(_newClient(name: 'C6'));
    final tourId = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 14),
      startTimeMinutes: 480,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: c6,
          clientNameSnapshot: 'C6',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          plannedSmall: 5,
          plannedLarge: 0,
          minutesPerSmallSnapshot: 8,
          minutesPerLargeSnapshot: 25,
          feeShareCents: 0,
        ),
      ],
    ));
    await tours.markCompleted(tourId, {
      (await tours.findById(tourId))!.stops.first.id: (
        actualSmall: 5,
        actualLarge: 0,
        note: null,
      ),
    });
    // C7: tour BEFORE season start → must NOT make C7 done/scheduled
    final c7 = await repo.insert(_newClient(name: 'C7'));
    await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 1, 15), // before season start (2026-04-01)
      startTimeMinutes: 480,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: c7,
          clientNameSnapshot: 'C7',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          plannedSmall: 5,
          plannedLarge: 0,
          minutesPerSmallSnapshot: 8,
          minutesPerLargeSnapshot: 25,
          feeShareCents: 0,
        ),
      ],
    ));

    final all = await repo.listAllWithStatus(season);
    final byName = {for (final r in all) r.$1.name: r.$2};

    expect(byName['C1'], ClientStatus.defaultStatus);
    expect(byName['C2'], ClientStatus.waiting);
    expect(byName['C3'], ClientStatus.banned);
    expect(byName['C4'], ClientStatus.noSheep);
    expect(byName['C5'], ClientStatus.scheduled);
    expect(byName['C6'], ClientStatus.done);
    expect(byName['C7'], ClientStatus.defaultStatus);
  });

  test('applyInterventionActuals updates breed counts and lastShearingDate',
      () async {
    final id = await repo.insert(
      _newClient(sheepCountSmall: 8, sheepCountLarge: 0),
    );
    await repo.applyInterventionActuals(
      id,
      small: 6,
      large: 3,
      tourDate: DateTime(2026, 5, 12),
    );
    final c = (await repo.findById(id))!;
    expect(c.sheepCountSmall, 6);
    expect(c.sheepCountLarge, 3);
    expect(c.lastShearingDate, DateTime(2026, 5, 12));
  });

  test(
    'listInterventionsForClient returns completed stops only, sorted desc, '
    'with hasBilan reflecting actual_* presence',
    () async {
      final tours = TourRepository(db);
      final cId = await repo.insert(_newClient(name: 'C'));

      // Tour 1 — completed with actuals (most recent in date)
      final t1 = await tours.plan(TourDraft(
        plannedDate: DateTime(2026, 5, 14),
        startTimeMinutes: 480,
        totalDistanceMeters: 0,
        totalDriveSeconds: 0,
        totalTravelFeeCents: 0,
        stops: [
          TourStopDraft(
            clientId: cId,
            clientNameSnapshot: 'C',
            orderIndex: 0,
            estimatedArrivalMinutes: 480,
            estimatedDepartureMinutes: 580,
            plannedSmall: 5,
            plannedLarge: 1,
            minutesPerSmallSnapshot: 8,
            minutesPerLargeSnapshot: 25,
            feeShareCents: 0,
          ),
        ],
      ));
      await tours.markCompleted(t1, {
        (await tours.findById(t1))!.stops.first.id: (
          actualSmall: 4,
          actualLarge: 1,
          note: 'RAS',
        ),
      });

      // Tour 2 — older but still completed
      final t2 = await tours.plan(TourDraft(
        plannedDate: DateTime(2026, 4, 1),
        startTimeMinutes: 480,
        totalDistanceMeters: 0,
        totalDriveSeconds: 0,
        totalTravelFeeCents: 0,
        stops: [
          TourStopDraft(
            clientId: cId,
            clientNameSnapshot: 'C',
            orderIndex: 0,
            estimatedArrivalMinutes: 480,
            estimatedDepartureMinutes: 580,
            plannedSmall: 6,
            plannedLarge: 0,
            minutesPerSmallSnapshot: 8,
            minutesPerLargeSnapshot: 25,
            feeShareCents: 0,
          ),
        ],
      ));
      await tours.markCompleted(t2, {
        (await tours.findById(t2))!.stops.first.id: (
          actualSmall: 6,
          actualLarge: 0,
          note: null,
        ),
      });

      // Tour 3 — planned but not completed -> must NOT appear
      await tours.plan(TourDraft(
        plannedDate: DateTime(2026, 6, 1),
        startTimeMinutes: 480,
        totalDistanceMeters: 0,
        totalDriveSeconds: 0,
        totalTravelFeeCents: 0,
        stops: [
          TourStopDraft(
            clientId: cId,
            clientNameSnapshot: 'C',
            orderIndex: 0,
            estimatedArrivalMinutes: 480,
            estimatedDepartureMinutes: 580,
            plannedSmall: 4,
            plannedLarge: 0,
            minutesPerSmallSnapshot: 8,
            minutesPerLargeSnapshot: 25,
            feeShareCents: 0,
          ),
        ],
      ));

      final history = await repo.listInterventionsForClient(cId);
      expect(history.length, 2);
      expect(history[0].date, DateTime(2026, 5, 14));
      expect(history[0].small, 4);
      expect(history[0].large, 1);
      expect(history[0].note, 'RAS');
      expect(history[0].hasBilan, isTrue);
      expect(history[1].date, DateTime(2026, 4, 1));
      expect(history[1].small, 6);
      expect(history[1].large, 0);
      expect(history[1].hasBilan, isTrue);
    },
  );

  test('listAllWithStatus marks client done when only a manual entry exists',
      () async {
    final manual = ManualHistoryRepository(db);
    final cId = await repo.insert(_newClient(name: 'M'));
    final season = DateTime(2026, 4, 1);

    // No tour at all — only a manual entry inside the season.
    await manual.insert(
      clientId: cId,
      date: DateTime(2026, 5, 1),
      small: 4,
      large: 0,
    );

    final all = await repo.listAllWithStatus(season);
    final byName = {for (final r in all) r.$1.name: r.$2};
    expect(byName['M'], ClientStatus.done);
  });

  test(
    'listAllWithStatus does NOT mark client done when manual entry is before season',
    () async {
      final manual = ManualHistoryRepository(db);
      final cId = await repo.insert(_newClient(name: 'OLD'));
      final season = DateTime(2026, 4, 1);

      await manual.insert(
        clientId: cId,
        date: DateTime(2025, 9, 1), // before season
        small: 4,
        large: 0,
      );

      final all = await repo.listAllWithStatus(season);
      final byName = {for (final r in all) r.$1.name: r.$2};
      expect(byName['OLD'], isNot(ClientStatus.done));
    },
  );

  test('listInterventionsForClient merges tour-stops + manual entries desc',
      () async {
    final tours = TourRepository(db);
    final manual = ManualHistoryRepository(db);
    final cId = await repo.insert(_newClient(name: 'C'));

    // Tour completed on 2026-05-14
    final tourId = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 14),
      startTimeMinutes: 480,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: cId,
          clientNameSnapshot: 'C',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          plannedSmall: 5,
          plannedLarge: 0,
          minutesPerSmallSnapshot: 8,
          minutesPerLargeSnapshot: 25,
          feeShareCents: 0,
        ),
      ],
    ));
    await tours.markCompleted(tourId, {
      (await tours.findById(tourId))!.stops.first.id: (
        actualSmall: 5,
        actualLarge: 0,
        note: null,
      ),
    });

    // Manual entry on 2025-09-10 (older)
    await manual.insert(
      clientId: cId,
      date: DateTime(2025, 9, 10),
      small: 3,
      large: 1,
      note: 'manual older',
    );
    // Manual entry on 2026-06-01 (newest)
    final newestId = await manual.insert(
      clientId: cId,
      date: DateTime(2026, 6, 1),
      small: 4,
      large: 0,
      note: 'manual newer',
    );

    final list = await repo.listInterventionsForClient(cId);
    expect(list.length, 3);

    // Sort: 2026-06-01 (manual), 2026-05-14 (tour), 2025-09-10 (manual)
    expect(list[0].kind, InterventionKind.manual);
    expect(list[0].manualEntryId, newestId);
    expect(list[0].tourId, isNull);
    expect(list[0].hasBilan, isTrue);
    expect(list[0].note, 'manual newer');

    expect(list[1].kind, InterventionKind.tour);
    expect(list[1].tourId, isNotNull);
    expect(list[1].manualEntryId, isNull);

    expect(list[2].kind, InterventionKind.manual);
    expect(list[2].note, 'manual older');
  });
}
