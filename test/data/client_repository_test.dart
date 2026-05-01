import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/manual_history_repository.dart';
import 'package:coup_laine/data/repositories/tour_repository.dart';
import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/intervention.dart';
import 'package:coup_laine/domain/models/tour_stop_animal.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';
import 'package:coup_laine/domain/use_cases/client_status.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// Stable test convention:
//   - categoryId 1 stands for "small / Petit Mouton"
//   - categoryId 2 stands for "large / Gros Mouton"
TourStopPrestation _small(int n, {int prestationId = 11}) =>
    TourStopPrestation(
      prestationId: prestationId,
      qty: n,
      nameSnapshot: 'Tonte petit',
      priceCentsSnapshot: 800,
      minutesSnapshot: 8,
      categoryIdSnapshot: 1,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
    );

TourStopPrestation _large(int n, {int prestationId = 12}) =>
    TourStopPrestation(
      prestationId: prestationId,
      qty: n,
      nameSnapshot: 'Tonte gros',
      priceCentsSnapshot: 2500,
      minutesSnapshot: 25,
      categoryIdSnapshot: 2,
      categoryNameSnapshot: 'Gros',
      speciesNameSnapshot: 'Mouton',
    );

// Manual-history insert still operates on TourStopAnimal (T9 will migrate).
TourStopAnimal _smallAnimal(int n) => TourStopAnimal(
      categoryId: 1,
      count: n,
      categoryNameSnapshot: 'Petit',
      speciesNameSnapshot: 'Mouton',
      minutesSnapshot: 8,
    );

TourStopAnimal _largeAnimal(int n) => TourStopAnimal(
      categoryId: 2,
      count: n,
      categoryNameSnapshot: 'Gros',
      speciesNameSnapshot: 'Mouton',
      minutesSnapshot: 25,
    );

Client _newClient({
  String name = 'Le Gall',
  bool isWaiting = false,
  bool needsDistanceRecompute = false,
  List<AnimalCount> animals = const [AnimalCount(categoryId: 1, count: 12)],
}) {
  return Client(
    id: 0,
    name: name,
    addressLabel: '1 rue, 29000 Quimper',
    postcode: '29000',
    city: 'Quimper',
    coordinates: const Coordinates(lat: 48.0, lon: -4.1),
    animals: animals,
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

  test('insert persists phones list and reads it back in order', () async {
    final id = await repo.insert(Client(
      id: 0,
      name: 'Le Gall',
      addressLabel: '1 rue, 29000 Quimper',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48.0, lon: -4.1),
      phones: const ['0612', '0145', '0788'],
    ));
    final read = await repo.findById(id);
    expect(read!.phones, ['0612', '0145', '0788']);
    expect(read.principalPhone, '0612');
  });

  test('insert normalizes phones (trim, drop empty, dedupe)', () async {
    final id = await repo.insert(Client(
      id: 0,
      name: 'Le Gall',
      addressLabel: '1 rue, 29000 Quimper',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48.0, lon: -4.1),
      phones: const ['  06 12  ', '', '0612', '0145'],
    ));
    final read = await repo.findById(id);
    expect(read!.phones, ['06 12', '0145']);
  });

  test('updateBasics replaces phones list and preserves new order', () async {
    final id = await repo.insert(Client(
      id: 0,
      name: 'Le Gall',
      addressLabel: '1 rue, 29000 Quimper',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48.0, lon: -4.1),
      phones: const ['0612'],
    ));
    await repo.updateBasics(
      id: id,
      name: 'Le Gall',
      phones: const ['0788', '0612'],
      animals: const [AnimalCount(categoryId: 1, count: 12)],
    );
    final read = await repo.findById(id);
    expect(read!.phones, ['0788', '0612']);
    expect(read.principalPhone, '0788');
  });

  test('a client with no phones reads back as empty list', () async {
    final id = await repo.insert(_newClient());
    final read = await repo.findById(id);
    expect(read!.phones, <String>[]);
    expect(read.principalPhone, isNull);
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
    // C4: no animals (override _newClient default of 12)
    await db.into(db.clientsTable).insert(
      ClientsTableCompanion.insert(
        name: 'C4',
        addressLabel: 'a',
        postcode: '0',
        city: 'X',
        lat: 48,
        lon: -4,
        animals: const Value([]),
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
          plannedPrestations: [_small(5)],
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
          plannedPrestations: [_small(5)],
          feeShareCents: 0,
        ),
      ],
    ));
    await tours.markCompleted(tourId, {
      (await tours.findById(tourId))!.stops.first.id: (
        actuals: [_small(5)],
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
          plannedPrestations: [_small(5)],
          feeShareCents: 0,
        ),
      ],
    ));

    final all = await repo.listAllWithStatus(season);
    final byName = {for (final r in all) r.$1.name: r.$2};

    expect(byName['C1'], ClientStatus.defaultStatus);
    expect(byName['C2'], ClientStatus.waiting);
    expect(byName['C3'], ClientStatus.banned);
    expect(byName['C4'], ClientStatus.noAnimals);
    expect(byName['C5'], ClientStatus.scheduled);
    expect(byName['C6'], ClientStatus.done);
    expect(byName['C7'], ClientStatus.defaultStatus);
  });

  test('applyInterventionActuals updates animal counts and lastInterventionDate',
      () async {
    final id = await repo.insert(
      _newClient(animals: const [AnimalCount(categoryId: 1, count: 8)]),
    );
    await repo.applyInterventionActuals(
      id,
      actuals: [_small(6), _large(3)],
      tourDate: DateTime(2026, 5, 12),
    );
    final c = (await repo.findById(id))!;
    expect(c.animals, const [
      AnimalCount(categoryId: 1, count: 6),
      AnimalCount(categoryId: 2, count: 3),
    ]);
    expect(c.lastInterventionDate, DateTime(2026, 5, 12));
  });

  test(
    'listInterventionsForClient returns completed stops only, sorted desc, '
    'with hasBilan reflecting actual presence',
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
            plannedPrestations: [_small(5), _large(1)],
            feeShareCents: 0,
          ),
        ],
      ));
      await tours.markCompleted(t1, {
        (await tours.findById(t1))!.stops.first.id: (
          actuals: [_small(4), _large(1)],
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
            plannedPrestations: [_small(6)],
            feeShareCents: 0,
          ),
        ],
      ));
      await tours.markCompleted(t2, {
        (await tours.findById(t2))!.stops.first.id: (
          actuals: [_small(6)],
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
            plannedPrestations: [_small(4)],
            feeShareCents: 0,
          ),
        ],
      ));

      final history = await repo.listInterventionsForClient(cId);
      expect(history.length, 2);
      expect(history[0].date, DateTime(2026, 5, 14));
      expect(history[0].prestationsQtyTotal, 5);
      expect(history[0].note, 'RAS');
      expect(history[0].hasBilan, isTrue);
      expect(history[1].date, DateTime(2026, 4, 1));
      expect(history[1].prestationsQtyTotal, 6);
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
      animals: [_smallAnimal(4)],
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
        animals: [_smallAnimal(4)],
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
          plannedPrestations: [_small(5)],
          feeShareCents: 0,
        ),
      ],
    ));
    await tours.markCompleted(tourId, {
      (await tours.findById(tourId))!.stops.first.id: (
        actuals: [_small(5)],
        note: null,
      ),
    });

    // Manual entry on 2025-09-10 (older)
    await manual.insert(
      clientId: cId,
      date: DateTime(2025, 9, 10),
      animals: [_smallAnimal(3), _largeAnimal(1)],
      note: 'manual older',
    );
    // Manual entry on 2026-06-01 (newest)
    final newestId = await manual.insert(
      clientId: cId,
      date: DateTime(2026, 6, 1),
      animals: [_smallAnimal(4)],
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

  test('loadClientNotesMap aggregates notes from both sources', () async {
    final tours = TourRepository(db);
    final manual = ManualHistoryRepository(db);
    final a = await repo.insert(_newClient(name: 'A'));
    final b = await repo.insert(_newClient(name: 'B'));

    // A — completed tour with a note + a manual entry with a note.
    final tourId = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 14),
      startTimeMinutes: 480,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: a,
          clientNameSnapshot: 'A',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          plannedPrestations: [_small(5)],
          feeShareCents: 0,
        ),
      ],
    ));
    await tours.markCompleted(tourId, {
      (await tours.findById(tourId))!.stops.first.id: (
        actuals: [_small(5)],
        note: 'tour-note-A',
      ),
    });
    await manual.insert(
      clientId: a,
      date: DateTime(2024, 6, 1),
      animals: [_smallAnimal(3), _largeAnimal(1)],
      note: 'manual-note-A',
    );

    // B — only a manual entry with a note.
    await manual.insert(
      clientId: b,
      date: DateTime(2024, 6, 1),
      animals: [_smallAnimal(3), _largeAnimal(1)],
      note: 'manual-note-B',
    );

    // C — no notes at all (a noteless manual entry should not produce a key).
    final c = await repo.insert(_newClient(name: 'C'));
    await manual.insert(
      clientId: c,
      date: DateTime(2024, 6, 1),
      animals: [_smallAnimal(3), _largeAnimal(1)],
    );

    final map = await repo.loadClientNotesMap();
    expect(map[a], containsAll(['tour-note-A', 'manual-note-A']));
    expect(map[a]!.length, 2);
    expect(map[b], ['manual-note-B']);
    expect(map.containsKey(c), isFalse);
  });

  group('applyManualEntryToClient', () {
    test('lastInterventionDate null → applies', () async {
      final cId = await repo.insert(
        _newClient(animals: const [AnimalCount(categoryId: 1, count: 8)]),
      );
      // Sanity: lastInterventionDate is null on a fresh client.
      expect((await repo.findById(cId))!.lastInterventionDate, isNull);

      await repo.applyManualEntryToClient(
        cId,
        date: DateTime(2025, 5, 1),
        prestations: [_small(6), _large(2)],
      );
      final c = (await repo.findById(cId))!;
      expect(c.lastInterventionDate, DateTime(2025, 5, 1));
      expect(c.animals, const [
        AnimalCount(categoryId: 1, count: 6),
        AnimalCount(categoryId: 2, count: 2),
      ]);
    });

    test('entry.date > lastInterventionDate → applies', () async {
      final cId = await repo.insert(
        _newClient(animals: const [AnimalCount(categoryId: 1, count: 8)]),
      );
      await repo.applyInterventionActuals(
        cId,
        actuals: [_small(5)],
        tourDate: DateTime(2025, 5, 1),
      );
      await repo.applyManualEntryToClient(
        cId,
        date: DateTime(2025, 6, 1), // later
        prestations: [_small(7), _large(1)],
      );
      final c = (await repo.findById(cId))!;
      expect(c.lastInterventionDate, DateTime(2025, 6, 1));
      expect(c.animals, const [
        AnimalCount(categoryId: 1, count: 7),
        AnimalCount(categoryId: 2, count: 1),
      ]);
    });

    test('entry.date == lastInterventionDate → no-op (strict greater-than)',
        () async {
      final cId = await repo.insert(
        _newClient(animals: const [AnimalCount(categoryId: 1, count: 8)]),
      );
      await repo.applyInterventionActuals(
        cId,
        actuals: [_small(5)],
        tourDate: DateTime(2025, 5, 1),
      );
      await repo.applyManualEntryToClient(
        cId,
        date: DateTime(2025, 5, 1), // equal
        prestations: [_small(99), _large(99)],
      );
      final c = (await repo.findById(cId))!;
      // animals untouched: small=5 from the intervention, no large entry.
      expect(c.animals, const [AnimalCount(categoryId: 1, count: 5)]);
    });

    test('entry.date < lastInterventionDate → no-op', () async {
      final cId = await repo.insert(
        _newClient(animals: const [AnimalCount(categoryId: 1, count: 8)]),
      );
      await repo.applyInterventionActuals(
        cId,
        actuals: [_small(5)],
        tourDate: DateTime(2025, 5, 1),
      );
      await repo.applyManualEntryToClient(
        cId,
        date: DateTime(2024, 1, 1), // earlier
        prestations: [_small(99), _large(99)],
      );
      final c = (await repo.findById(cId))!;
      expect(c.lastInterventionDate, DateTime(2025, 5, 1));
      expect(c.animals, const [AnimalCount(categoryId: 1, count: 5)]);
    });
  });

  group('recomputeClientFromHistory', () {
    test('falls back to a tour-stop after deleting the newest manual entry',
        () async {
      final tours = TourRepository(db);
      final manual = ManualHistoryRepository(db);
      final cId = await repo.insert(_newClient(animals: const []));

      // Tour completed on 2025-05-01 with actuals (small=5).
      final tourId = await tours.plan(TourDraft(
        plannedDate: DateTime(2025, 5, 1),
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
            plannedPrestations: [_small(5)],
            feeShareCents: 0,
          ),
        ],
      ));
      await tours.markCompleted(tourId, {
        (await tours.findById(tourId))!.stops.first.id: (
          actuals: [_small(5)],
          note: null,
        ),
      });
      // Sanity: client now has the tour's actuals.
      expect(
        (await repo.findById(cId))!.animals,
        const [AnimalCount(categoryId: 1, count: 5)],
      );

      // Newer manual entry: 2026-05-01, small=8, large=2.
      final manualId = await manual.insert(
        clientId: cId,
        date: DateTime(2026, 5, 1),
        animals: [_smallAnimal(8), _largeAnimal(2)],
      );
      await repo.applyManualEntryToClient(
        cId,
        date: DateTime(2026, 5, 1),
        prestations: [_small(8), _large(2)],
      );
      expect((await repo.findById(cId))!.animals, const [
        AnimalCount(categoryId: 1, count: 8),
        AnimalCount(categoryId: 2, count: 2),
      ]);

      // Delete the manual entry, then recompute → falls back to the tour.
      await manual.delete(manualId);
      await repo.recomputeClientFromHistory(cId);
      final c = (await repo.findById(cId))!;
      expect(c.lastInterventionDate, DateTime(2025, 5, 1));
      expect(c.animals, const [AnimalCount(categoryId: 1, count: 5)]);
    });

    test('no source → lastInterventionDate becomes null, animals empty',
        () async {
      final manual = ManualHistoryRepository(db);
      final cId = await repo.insert(_newClient(
        animals: const [
          AnimalCount(categoryId: 1, count: 8),
          AnimalCount(categoryId: 2, count: 1),
        ],
      ));
      final id = await manual.insert(
        clientId: cId,
        date: DateTime(2026, 5, 1),
        animals: [_smallAnimal(4)],
      );
      await repo.applyManualEntryToClient(
        cId,
        date: DateTime(2026, 5, 1),
        prestations: [_small(4)],
      );
      // Sanity: small now reflects the manual entry; large untouched.
      expect((await repo.findById(cId))!.animals, const [
        AnimalCount(categoryId: 1, count: 4),
        AnimalCount(categoryId: 2, count: 1),
      ]);

      await manual.delete(id);
      await repo.recomputeClientFromHistory(cId);

      final c = (await repo.findById(cId))!;
      expect(c.lastInterventionDate, isNull);
      // No source to rebuild from → animals cleared.
      expect(c.animals, const <AnimalCount>[]);
    });

    test('MAX rule + most-recent wins per category across interventions',
        () async {
      final tours = TourRepository(db);
      final cId = await repo.insert(_newClient(animals: const []));

      // Tour 1 (older, 2025-05-01): small=5, large=2
      final t1 = await tours.plan(TourDraft(
        plannedDate: DateTime(2025, 5, 1),
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
            plannedPrestations: [_small(5), _large(2)],
            feeShareCents: 0,
          ),
        ],
      ));
      await tours.markCompleted(t1, {
        (await tours.findById(t1))!.stops.first.id: (
          actuals: [_small(5), _large(2)],
          note: null,
        ),
      });

      // Tour 2 (newer, 2026-05-01): two prestations bound to small (catId=1),
      // qty 7 each (MAX rule → 7, not 14). large is NOT in this tour.
      final t2 = await tours.plan(TourDraft(
        plannedDate: DateTime(2026, 5, 1),
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
            plannedPrestations: [
              _small(7, prestationId: 21),
              _small(7, prestationId: 22),
            ],
            feeShareCents: 0,
          ),
        ],
      ));
      await tours.markCompleted(t2, {
        (await tours.findById(t2))!.stops.first.id: (
          actuals: [
            _small(7, prestationId: 21),
            _small(7, prestationId: 22),
          ],
          note: null,
        ),
      });

      await repo.recomputeClientFromHistory(cId);
      final c = (await repo.findById(cId))!;
      // small comes from the most-recent tour with MAX = 7.
      // large only appeared in the older tour → still picked up at 2.
      expect(c.animals, const [
        AnimalCount(categoryId: 1, count: 7),
        AnimalCount(categoryId: 2, count: 2),
      ]);
      // lastInterventionDate is the newest.
      expect(c.lastInterventionDate, DateTime(2026, 5, 1));
    });
  });
}
