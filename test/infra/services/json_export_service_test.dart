import 'dart:convert';

import 'package:coup_laine/data/repositories/animal_category_repository.dart';
import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/distance_matrix_repository.dart';
import 'package:coup_laine/data/repositories/manual_history_repository.dart';
import 'package:coup_laine/data/repositories/prestation_repository.dart';
import 'package:coup_laine/data/repositories/settings_repository.dart';
import 'package:coup_laine/data/repositories/species_repository.dart';
import 'package:coup_laine/data/repositories/tour_repository.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/distance_matrix_entry.dart';
import 'package:coup_laine/domain/models/settings.dart';
import 'package:coup_laine/domain/models/tour.dart';
import 'package:coup_laine/domain/models/tour_stop_prestation.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:coup_laine/infra/services/json_export_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late JsonExportService svc;
  late SettingsRepository settings;
  late ClientRepository clients;
  late ManualHistoryRepository manualHistory;
  late SpeciesRepository species;
  late AnimalCategoryRepository categories;
  late PrestationRepository prestations;
  late DistanceMatrixRepository matrix;
  late TourRepository tours;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = SettingsRepository(db);
    manualHistory = ManualHistoryRepository(db);
    clients = ClientRepository(db, manualHistory: manualHistory);
    species = SpeciesRepository(db);
    categories = AnimalCategoryRepository(db);
    prestations = PrestationRepository(db);
    matrix = DistanceMatrixRepository(db);
    tours = TourRepository(db);
    svc = JsonExportService(
      database: db,
      settings: settings,
      clients: clients,
      matrix: matrix,
      tours: tours,
    );
    await settings.save(Settings(
      baseCoordinates: const Coordinates(lat: 48.5, lon: -2.7),
      baseAddressLabel: 'base',
      seasonStartedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> wipeAll() async {
    // Order matters for FK cascades.
    await db.delete(db.tourStopsTable).go();
    await db.delete(db.toursTable).go();
    await db.delete(db.distanceMatrixTable).go();
    await db.delete(db.manualHistoryEntriesTable).go();
    await db.delete(db.prestationsTable).go();
    await db.delete(db.animalCategoriesTable).go();
    await db.delete(db.speciesTable).go();
    await db.delete(db.clientsTable).go();
    await db.delete(db.settingsTable).go();
  }

  group('legacy round-trip', () {
    test('export then import round-trips clients', () async {
      await clients.insert(Client(
        id: 0,
        name: 'A',
        addressLabel: 'addr',
        postcode: '22000',
        city: 'Saint-Brieuc',
        coordinates: const Coordinates(lat: 48.5, lon: -2.8),
      ));
      final json = await svc.exportToJsonString();

      await db.delete(db.clientsTable).go();
      expect(await clients.listAll(), isEmpty);

      await svc.importFromJsonString(json);
      final list = await clients.listAll();
      expect(list.length, 1);
      expect(list.first.name, 'A');
      expect(list.first.city, 'Saint-Brieuc');
    });
  });

  group('round-trip — 4 tables ajoutées', () {
    test('species : round-trip preserves name/iconKey/archivedAt', () async {
      final activeId = await species.insert(name: 'Mouton', iconKey: 'sheep');
      final archivedId = await species.insert(name: 'Cheval', iconKey: 'horse');
      await species.archive(archivedId);

      final json = await svc.exportToJsonString();
      await wipeAll();
      expect(await species.listAll(), isEmpty);

      await svc.importFromJsonString(json);

      final all = await species.listAll();
      expect(all, hasLength(2));
      final mouton = all.firstWhere((s) => s.id == activeId);
      expect(mouton.name, 'Mouton');
      expect(mouton.iconKey, 'sheep');
      expect(mouton.archivedAt, isNull);
      final cheval = all.firstWhere((s) => s.id == archivedId);
      expect(cheval.name, 'Cheval');
      expect(cheval.iconKey, 'horse');
      expect(cheval.archivedAt, isNotNull);
    });

    test('animal_categories : round-trip preserves speciesId + name', () async {
      final spId = await species.insert(name: 'Mouton');
      final petitId = await categories.insert(speciesId: spId, name: 'Petit');
      final grandId = await categories.insert(speciesId: spId, name: 'Grand');
      await categories.archive(grandId);

      final json = await svc.exportToJsonString();
      await wipeAll();

      await svc.importFromJsonString(json);

      final all = await categories.listAll();
      expect(all, hasLength(2));
      final petit = all.firstWhere((c) => c.id == petitId);
      expect(petit.name, 'Petit');
      expect(petit.speciesId, spId);
      expect(petit.archivedAt, isNull);
      final grand = all.firstWhere((c) => c.id == grandId);
      expect(grand.archivedAt, isNotNull);
    });

    test('prestations : round-trip preserves priceCents/minutes/categoryId',
        () async {
      final spId = await species.insert(name: 'Mouton');
      final catId = await categories.insert(speciesId: spId, name: 'Petit');

      final boundId = await prestations.insert(
        name: 'Tonte petit',
        priceCents: 800,
        minutes: 8,
        categoryId: catId,
      );
      final libreId = await prestations.insert(
        name: 'Visite',
        priceCents: 2000,
        minutes: 0,
        categoryId: null,
      );
      final nullValuesId = await prestations.insert(
        name: 'À compléter',
        categoryId: null,
      );

      final json = await svc.exportToJsonString();
      await wipeAll();

      await svc.importFromJsonString(json);

      final all = [
        ...await prestations.listActive(),
        ...await prestations.listArchived(),
      ];
      expect(all, hasLength(3));
      final bound = all.firstWhere((p) => p.id == boundId);
      expect(bound.name, 'Tonte petit');
      expect(bound.priceCents, 800);
      expect(bound.minutes, 8);
      expect(bound.categoryId, catId);
      final libre = all.firstWhere((p) => p.id == libreId);
      expect(libre.priceCents, 2000);
      expect(libre.minutes, 0);
      expect(libre.categoryId, isNull);
      final nullVals = all.firstWhere((p) => p.id == nullValuesId);
      expect(nullVals.priceCents, isNull);
      expect(nullVals.minutes, isNull);
      expect(nullVals.categoryId, isNull);
    });

    test('manual_history_entries : round-trip preserves prestations snapshot',
        () async {
      final spId = await species.insert(name: 'Mouton');
      final catId = await categories.insert(speciesId: spId, name: 'Petit');
      final clientId = await clients.insert(Client(
        id: 0,
        name: 'Le Gall',
        addressLabel: 'addr',
        postcode: '29000',
        city: 'Quimper',
        coordinates: const Coordinates(lat: 48.0, lon: -4.1),
      ));
      await manualHistory.insert(
        clientId: clientId,
        date: DateTime(2025, 5, 1),
        prestations: [
          TourStopPrestation(
            prestationId: 11,
            qty: 5,
            nameSnapshot: 'Tonte petit',
            priceCentsSnapshot: 800,
            minutesSnapshot: 8,
            categoryIdSnapshot: catId,
            categoryNameSnapshot: 'Petit',
            speciesNameSnapshot: 'Mouton',
          ),
          TourStopPrestation(
            prestationId: 12,
            qty: 2,
            nameSnapshot: 'Tonte grand',
            priceCentsSnapshot: 2500,
            minutesSnapshot: 25,
            categoryIdSnapshot: catId,
            categoryNameSnapshot: 'Petit',
            speciesNameSnapshot: 'Mouton',
          ),
        ],
        note: 'manual entry',
      );

      final json = await svc.exportToJsonString();
      await wipeAll();

      await svc.importFromJsonString(json);

      final all = await manualHistory.listForClient(clientId);
      expect(all, hasLength(1));
      final entry = all.single;
      expect(entry.date, DateTime(2025, 5, 1));
      expect(entry.note, 'manual entry');
      expect(entry.prestations, hasLength(2));
      final p1 = entry.prestations.firstWhere((p) => p.prestationId == 11);
      expect(p1.qty, 5);
      expect(p1.nameSnapshot, 'Tonte petit');
      expect(p1.priceCentsSnapshot, 800);
      expect(p1.minutesSnapshot, 8);
      expect(p1.categoryIdSnapshot, catId);
      expect(p1.categoryNameSnapshot, 'Petit');
      expect(p1.speciesNameSnapshot, 'Mouton');
      final p2 = entry.prestations.firstWhere((p) => p.prestationId == 12);
      expect(p2.qty, 2);
      expect(p2.nameSnapshot, 'Tonte grand');
      expect(p2.priceCentsSnapshot, 2500);
      expect(p2.minutesSnapshot, 25);
    });
  });

  group('round-trip complet', () {
    test('every populated table is preserved after export+import', () async {
      // settings already populated in setUp.

      // species + categories
      final spId = await species.insert(name: 'Mouton', iconKey: 'sheep');
      final catId = await categories.insert(speciesId: spId, name: 'Petit');

      // prestations
      final prestationId = await prestations.insert(
        name: 'Tonte petit',
        priceCents: 800,
        minutes: 8,
        categoryId: catId,
      );

      // clients
      final clientId = await clients.insert(Client(
        id: 0,
        name: 'Le Gall',
        addressLabel: '1 rue, 29000 Quimper',
        postcode: '29000',
        city: 'Quimper',
        coordinates: const Coordinates(lat: 48.0, lon: -4.1),
      ));

      // manual history
      await manualHistory.insert(
        clientId: clientId,
        date: DateTime(2025, 5, 1),
        prestations: [
          TourStopPrestation(
            prestationId: prestationId,
            qty: 3,
            nameSnapshot: 'Tonte petit',
            priceCentsSnapshot: 800,
            minutesSnapshot: 8,
            categoryIdSnapshot: catId,
            categoryNameSnapshot: 'Petit',
            speciesNameSnapshot: 'Mouton',
          ),
        ],
        note: 'mh',
      );

      // distance matrix
      await matrix.upsertMany([
        DistanceMatrixEntry(
          fromId: 0,
          toId: clientId,
          distanceMeters: 5000,
          durationSeconds: 360,
          computedAt: DateTime(2026, 4, 1),
        ),
        DistanceMatrixEntry(
          fromId: clientId,
          toId: 0,
          distanceMeters: 5100,
          durationSeconds: 370,
          computedAt: DateTime(2026, 4, 1),
        ),
      ]);

      // tour + tour stop
      final tourId = await tours.plan(TourDraft(
        plannedDate: DateTime(2026, 5, 12),
        startTimeMinutes: 8 * 60,
        totalDistanceMeters: 10100,
        totalDriveSeconds: 720,
        totalTravelFeeCents: 1500,
        stops: [
          TourStopDraft(
            clientId: clientId,
            clientNameSnapshot: 'Le Gall',
            orderIndex: 0,
            estimatedArrivalMinutes: 8 * 60 + 20,
            estimatedDepartureMinutes: 9 * 60,
            plannedPrestations: [
              TourStopPrestation(
                prestationId: prestationId,
                qty: 4,
                nameSnapshot: 'Tonte petit',
                priceCentsSnapshot: 800,
                minutesSnapshot: 8,
                categoryIdSnapshot: catId,
                categoryNameSnapshot: 'Petit',
                speciesNameSnapshot: 'Mouton',
              ),
            ],
            feeShareCents: 1500,
          ),
        ],
      ));

      final json = await svc.exportToJsonString();
      await wipeAll();

      // Sanity: everything wiped.
      expect(await clients.listAll(), isEmpty);
      expect(await species.listAll(), isEmpty);
      expect(await prestations.listActive(), isEmpty);
      expect(await categories.listAll(), isEmpty);
      expect(await tours.findById(tourId), isNull);

      await svc.importFromJsonString(json);

      // settings
      final s = await settings.read();
      expect(s, isNotNull);
      expect(s!.baseAddressLabel, 'base');
      expect(s.baseCoordinates.lat, 48.5);

      // species
      final sp = await species.listAll();
      expect(sp, hasLength(1));
      expect(sp.single.id, spId);
      expect(sp.single.iconKey, 'sheep');

      // categories
      final cats = await categories.listAll();
      expect(cats, hasLength(1));
      expect(cats.single.id, catId);
      expect(cats.single.speciesId, spId);

      // prestations
      final pr = await prestations.listActive();
      expect(pr, hasLength(1));
      expect(pr.single.id, prestationId);
      expect(pr.single.categoryId, catId);

      // clients
      final cs = await clients.listAll();
      expect(cs, hasLength(1));
      expect(cs.single.id, clientId);
      expect(cs.single.name, 'Le Gall');

      // manual history
      final mh = await manualHistory.listForClient(clientId);
      expect(mh, hasLength(1));
      expect(mh.single.prestations.single.qty, 3);
      expect(mh.single.prestations.single.categoryIdSnapshot, catId);

      // distance matrix
      expect(await matrix.distanceMeters(from: 0, to: clientId), 5000);
      expect(await matrix.distanceMeters(from: clientId, to: 0), 5100);

      // tour + stops
      final read = await tours.findById(tourId);
      expect(read, isNotNull);
      expect(read!.tour.status, TourStatus.planned);
      expect(read.tour.totalDistanceMeters, 10100);
      expect(read.stops, hasLength(1));
      expect(read.stops.single.clientId, clientId);
      expect(read.stops.single.plannedPrestations.single.qty, 4);
      expect(
        read.stops.single.plannedPrestations.single.categoryIdSnapshot,
        catId,
      );
    });
  });

  group('schema versioning', () {
    test('rejects a future schema (>schemaVersion)', () async {
      final body = jsonEncode({
        'schema': 99,
        'settings': null,
        'clients': [],
        'distanceMatrix': [],
        'tours': [],
        'tourStops': [],
      });
      expect(
        () => svc.importFromJsonString(body),
        throwsA(isA<JsonImportException>()),
      );
    });

    test('accepts a past schema (forward compat — v1 without 4 new keys)',
        () async {
      // v1 body intentionally omits species/animalCategories/prestations/
      // manualHistoryEntries to verify the `?? []` fallback.
      final body = jsonEncode({
        'schema': 1,
        'settings': null,
        'clients': [],
        'distanceMatrix': [],
        'tours': [],
        'tourStops': [],
      });
      // Must not throw.
      await svc.importFromJsonString(body);
      expect(await clients.listAll(), isEmpty);
      expect(await species.listAll(), isEmpty);
      expect(await categories.listAll(), isEmpty);
      expect(await prestations.listActive(), isEmpty);
    });
  });
}
