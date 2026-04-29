import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/tour_repository.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/tour.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TourRepository tours;
  late ClientRepository clients;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tours = TourRepository(db);
    clients = ClientRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> _addClient(String name, {bool waiting = true}) {
    return clients.insert(Client(
      id: 0,
      name: name,
      addressLabel: 'addr',
      postcode: '29000',
      city: 'Quimper',
      coordinates: const Coordinates(lat: 48, lon: -4),
      sheepCountSmall: 5,
      sheepCountLarge: 0,
      isWaiting: waiting,
    ));
  }

  test('plan + read round-trip', () async {
    final c1 = await _addClient('A');
    final c2 = await _addClient('B');
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
          plannedSmall: 5,
          plannedLarge: 0,
          minutesPerSmallSnapshot: 8,
          minutesPerLargeSnapshot: 25,
          feeShareCents: 2000,
        ),
        TourStopDraft(
          clientId: c2,
          clientNameSnapshot: 'B',
          orderIndex: 1,
          estimatedArrivalMinutes: 9 * 60 + 30,
          estimatedDepartureMinutes: 10 * 60 + 30,
          plannedSmall: 5,
          plannedLarge: 0,
          minutesPerSmallSnapshot: 8,
          minutesPerLargeSnapshot: 25,
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
    final c1 = await _addClient('A', waiting: true);
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
          plannedSmall: 5,
          plannedLarge: 0,
          minutesPerSmallSnapshot: 8,
          minutesPerLargeSnapshot: 25,
          feeShareCents: 0,
        ),
      ],
    ));
    final stopId = (await tours.findById(tourId))!.stops.first.id;
    await tours.markCompleted(tourId, {
      stopId: (actualSmall: 4, actualLarge: 1, note: 'OK'),
    });

    final read = await tours.findById(tourId);
    expect(read!.tour.status, TourStatus.completed);
    expect(read.stops.first.actualSmall, 4);
    expect(read.stops.first.actualLarge, 1);
    expect(read.stops.first.interventionNote, 'OK');

    final c = await clients.findById(c1);
    // The client was waiting before completion and stays waiting — only
    // the breed counts and lastShearingDate change.
    expect(c!.isWaiting, isTrue);
    expect(c.sheepCountSmall, 4);
    expect(c.sheepCountLarge, 1);
    expect(c.lastShearingDate, DateTime(2026, 5, 12));
  });

  test('soft FK preserves stop after client delete', () async {
    final c1 = await _addClient('A');
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
          plannedSmall: 5,
          plannedLarge: 0,
          minutesPerSmallSnapshot: 8,
          minutesPerLargeSnapshot: 25,
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
}
