import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/manual_history_repository.dart';
import 'package:coup_laine/data/repositories/tour_repository.dart';
import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/tour.dart';
import 'package:coup_laine/domain/models/tour_stop_animal.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_helpers/animal_fixtures.dart';

void main() {
  late AppDatabase db;
  late TourRepository tours;
  late ClientRepository clients;
  late AnimalFixtures fix;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tours = TourRepository(db);
    clients = ClientRepository(db, manualHistory: ManualHistoryRepository(db));
    fix = await seedTestSpeciesAndCategories(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addClient(String name, {bool waiting = true}) {
    return clients.insert(Client(
      id: 0,
      name: name,
      addressLabel: 'addr',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48, lon: -4),
      animals: [AnimalCount(categoryId: fix.catPetit, count: 5)],
      isWaiting: waiting,
    ));
  }

  TourStopAnimal petit(int count) => TourStopAnimal(
        categoryId: fix.catPetit,
        count: count,
        categoryNameSnapshot: 'Petit',
        speciesNameSnapshot: 'Mouton',
        minutesSnapshot: 8,
      );

  TourStopAnimal grand(int count) => TourStopAnimal(
        categoryId: fix.catGrand,
        count: count,
        categoryNameSnapshot: 'Grand',
        speciesNameSnapshot: 'Mouton',
        minutesSnapshot: 25,
      );

  test('plan + read round-trip', () async {
    final c1 = await addClient('A');
    final c2 = await addClient('B');
    final draft = TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 30000,
      totalDriveSeconds: 3600,
      totalTravelFeeCents: 4000,
      stops: [
        TourStopDraft(
          clientId: c1,
          clientNameSnapshot: 'A',
          orderIndex: 0,
          estimatedArrivalMinutes: 8 * 60 + 20,
          estimatedDepartureMinutes: 8 * 60 + 80,
          planned: [petit(5)],
          feeShareCents: 2000,
        ),
        TourStopDraft(
          clientId: c2,
          clientNameSnapshot: 'B',
          orderIndex: 1,
          estimatedArrivalMinutes: 9 * 60 + 30,
          estimatedDepartureMinutes: 10 * 60 + 30,
          planned: [petit(5)],
          feeShareCents: 2000,
        ),
      ],
    );
    final tourId = await tours.plan(draft);
    final read = await tours.findById(tourId);
    expect(read, isNotNull);
    expect(read!.tour.status, TourStatus.planned);
    expect(read.stops.length, 2);
    expect(read.stops.map((s) => s.clientNameSnapshot), ['A', 'B']);
  });

  test(
      'markCompleted persists actuals + note and auto-syncs the client counts',
      () async {
    final c1 = await addClient('A', waiting: true);
    final tourId = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: c1,
          clientNameSnapshot: 'A',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          planned: [petit(5)],
          feeShareCents: 0,
        ),
      ],
    ));
    final stopId = (await tours.findById(tourId))!.stops.first.id;
    await tours.markCompleted(tourId, {
      stopId: (actuals: [petit(4), grand(1)], note: 'OK'),
    });

    final read = await tours.findById(tourId);
    expect(read!.tour.status, TourStatus.completed);
    expect(read.stops.first.actual, [petit(4), grand(1)]);
    expect(read.stops.first.interventionNote, 'OK');

    final c = await clients.findById(c1);
    // The client was waiting before completion and stays waiting — only
    // the animal counts and lastShearingDate change.
    expect(c!.isWaiting, isTrue);
    expect(c.animals, [
      AnimalCount(categoryId: fix.catPetit, count: 4),
      AnimalCount(categoryId: fix.catGrand, count: 1),
    ]);
    expect(c.lastShearingDate, DateTime(2026, 5, 12));
  });

  test('soft FK preserves stop after client delete', () async {
    final c1 = await addClient('A');
    final tourId = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: c1,
          clientNameSnapshot: 'A',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          planned: [petit(5)],
          feeShareCents: 0,
        ),
      ],
    ));
    await clients.delete(c1);
    final read = await tours.findById(tourId);
    expect(read!.stops.length, 1);
    expect(read.stops.first.clientId, isNull);
    expect(read.stops.first.clientNameSnapshot, 'A');
  });

  test('update replaces stops and updates totals while preserving id, '
      'createdAt and status', () async {
    final c1 = await addClient('A');
    final c2 = await addClient('B');
    final c3 = await addClient('C');

    final tourId = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 30000,
      totalDriveSeconds: 3600,
      totalTravelFeeCents: 4000,
      stops: [
        TourStopDraft(
          clientId: c1,
          clientNameSnapshot: 'A',
          orderIndex: 0,
          estimatedArrivalMinutes: 8 * 60 + 20,
          estimatedDepartureMinutes: 8 * 60 + 80,
          planned: [petit(5)],
          feeShareCents: 2000,
        ),
        TourStopDraft(
          clientId: c2,
          clientNameSnapshot: 'B',
          orderIndex: 1,
          estimatedArrivalMinutes: 9 * 60 + 30,
          estimatedDepartureMinutes: 10 * 60 + 30,
          planned: [petit(5)],
          feeShareCents: 2000,
        ),
      ],
    ));
    final beforeRead = await tours.findById(tourId);
    final originalCreatedAt = beforeRead!.tour.createdAt;

    // Replace [A, B] with [C, A] and bump the date / start / totals.
    await tours.update(
      tourId,
      TourDraft(
        plannedDate: DateTime(2026, 5, 14),
        startTimeMinutes: 9 * 60,
        totalDistanceMeters: 50000,
        totalDriveSeconds: 7200,
        totalTravelFeeCents: 6000,
        stops: [
          TourStopDraft(
            clientId: c3,
            clientNameSnapshot: 'C',
            orderIndex: 0,
            estimatedArrivalMinutes: 9 * 60 + 40,
            estimatedDepartureMinutes: 10 * 60 + 20,
            planned: [petit(5)],
            feeShareCents: 3000,
          ),
          TourStopDraft(
            clientId: c1,
            clientNameSnapshot: 'A',
            orderIndex: 1,
            estimatedArrivalMinutes: 11 * 60,
            estimatedDepartureMinutes: 11 * 60 + 40,
            planned: [petit(5)],
            feeShareCents: 3000,
          ),
        ],
      ),
    );

    final after = await tours.findById(tourId);
    expect(after, isNotNull);
    expect(after!.tour.id, tourId);
    expect(after.tour.createdAt, originalCreatedAt);
    expect(after.tour.status, TourStatus.planned);
    expect(after.tour.plannedDate, DateTime(2026, 5, 14));
    expect(after.tour.startTimeMinutes, 9 * 60);
    expect(after.tour.totalDistanceMeters, 50000);
    expect(after.tour.totalDriveSeconds, 7200);
    expect(after.tour.totalTravelFeeCents, 6000);
    expect(after.stops.map((s) => s.clientNameSnapshot), ['C', 'A']);
    expect(after.stops.map((s) => s.clientId), [c3, c1]);
  });

  test('update does not leak stops from other tours', () async {
    final c1 = await addClient('A');
    final c2 = await addClient('B');
    final tourA = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: c1,
          clientNameSnapshot: 'A',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          planned: [petit(1)],
          feeShareCents: 0,
        ),
      ],
    ));
    final tourB = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 13),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 0,
      totalDriveSeconds: 0,
      totalTravelFeeCents: 0,
      stops: [
        TourStopDraft(
          clientId: c2,
          clientNameSnapshot: 'B',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          planned: [petit(1)],
          feeShareCents: 0,
        ),
      ],
    ));

    // Replace tourA's stops only — tourB must remain untouched.
    await tours.update(
      tourA,
      TourDraft(
        plannedDate: DateTime(2026, 5, 12),
        startTimeMinutes: 8 * 60,
        totalDistanceMeters: 0,
        totalDriveSeconds: 0,
        totalTravelFeeCents: 0,
        stops: const [],
      ),
    );

    final readA = await tours.findById(tourA);
    final readB = await tours.findById(tourB);
    expect(readA!.stops, isEmpty);
    expect(readB!.stops.map((s) => s.clientNameSnapshot), ['B']);
  });

  test('update is atomic: FK violation rolls back tour and stops', () async {
    final c1 = await addClient('A');
    final tourId = await tours.plan(TourDraft(
      plannedDate: DateTime(2026, 5, 12),
      startTimeMinutes: 8 * 60,
      totalDistanceMeters: 10000,
      totalDriveSeconds: 1800,
      totalTravelFeeCents: 2000,
      stops: [
        TourStopDraft(
          clientId: c1,
          clientNameSnapshot: 'A',
          orderIndex: 0,
          estimatedArrivalMinutes: 480,
          estimatedDepartureMinutes: 580,
          planned: [petit(3)],
          feeShareCents: 2000,
        ),
      ],
    ));

    await expectLater(
      tours.update(
        tourId,
        TourDraft(
          plannedDate: DateTime(2026, 6, 1),
          startTimeMinutes: 9 * 60,
          totalDistanceMeters: 99999,
          totalDriveSeconds: 9999,
          totalTravelFeeCents: 9999,
          stops: [
            TourStopDraft(
              clientId: 99999,
              clientNameSnapshot: 'Ghost',
              orderIndex: 0,
              estimatedArrivalMinutes: 540,
              estimatedDepartureMinutes: 640,
              planned: [petit(1)],
              feeShareCents: 9999,
            ),
          ],
        ),
      ),
      throwsA(isA<Exception>()),
    );

    final after = await tours.findById(tourId);
    expect(after!.tour.plannedDate, DateTime(2026, 5, 12));
    expect(after.tour.startTimeMinutes, 8 * 60);
    expect(after.tour.totalDistanceMeters, 10000);
    expect(after.stops.length, 1);
    expect(after.stops.first.clientNameSnapshot, 'A');
  });
}
