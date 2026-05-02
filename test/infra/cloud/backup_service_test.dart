import 'package:coup_laine/data/repositories/client_repository.dart';
import 'package:coup_laine/data/repositories/distance_matrix_repository.dart';
import 'package:coup_laine/data/repositories/manual_history_repository.dart';
import 'package:coup_laine/data/repositories/settings_repository.dart';
import 'package:coup_laine/data/repositories/tour_repository.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/models/settings.dart';
import 'package:coup_laine/infra/cloud/backup_service.dart';
import 'package:coup_laine/infra/db/app_database.dart';
import 'package:coup_laine/infra/services/json_export_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backups_repository.dart';

void main() {
  group('shouldRunAutoBackup', () {
    final now = DateTime.utc(2026, 5, 1, 12);

    test('false si pas opt-in', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: false,
          lastBackupAt: null,
          hasNetwork: true,
        ),
        isFalse,
      );
    });

    test('false si pas de réseau', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: null,
          hasNetwork: false,
        ),
        isFalse,
      );
    });

    test('true si jamais sauvegardé', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: null,
          hasNetwork: true,
        ),
        isTrue,
      );
    });

    test('false si dernier backup < 24h', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: now.subtract(const Duration(hours: 23)),
          hasNetwork: true,
        ),
        isFalse,
      );
    });

    test('true si dernier backup >= 24h', () {
      expect(
        shouldRunAutoBackup(
          now: now,
          cloudOptIn: true,
          lastBackupAt: now.subtract(const Duration(hours: 24, minutes: 1)),
          hasNetwork: true,
        ),
        isTrue,
      );
    });
  });

  group('BackupService orchestration', () {
    late AppDatabase db;
    late SettingsRepository settings;
    late ClientRepository clients;
    late JsonExportService exporter;
    late FakeBackupsRepository fakeRepo;
    late BackupService service;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      settings = SettingsRepository(db);
      final manualHistory = ManualHistoryRepository(db);
      clients = ClientRepository(db, manualHistory: manualHistory);
      final matrix = DistanceMatrixRepository(db);
      final tours = TourRepository(db);
      exporter = JsonExportService(
        database: db,
        settings: settings,
        clients: clients,
        matrix: matrix,
        tours: tours,
      );
      // setLastBackupAt fait un UPDATE WHERE id=1 — il faut un row settings.
      await settings.save(Settings(
        baseCoordinates: const Coordinates(lat: 48.5, lon: -2.7),
        baseAddressLabel: 'base',
        seasonStartedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ));
      fakeRepo = FakeBackupsRepository();
      service = BackupService(
        repo: fakeRepo,
        exporter: exporter,
        settings: settings,
      );
    });

    tearDown(() async {
      await db.close();
    });

    group('runBackup', () {
      test('uploads, sets lastBackupAt, returns BackupMeta', () async {
        expect((await settings.read())!.lastBackupAt, isNull);
        final before = DateTime.now();

        final meta = await service.runBackup();

        expect(meta, isNotNull);
        expect(meta!.schemaVersion, JsonExportService.schemaVersion);
        expect(meta.sizeBytes, greaterThan(0));
        expect(fakeRepo.all, hasLength(1));
        expect(fakeRepo.all.single.id, meta.id);

        final s = await settings.read();
        expect(s!.lastBackupAt, isNotNull);
        expect(
          s.lastBackupAt!
              .isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('rotates: keeps 3 most recent', () async {
        // 5 backups séquentiels avec des createdAt strictement croissants.
        for (var i = 0; i < 5; i++) {
          fakeRepo.nextCreatedAt = DateTime.utc(2026, 5, 1, 10 + i);
          await service.runBackup();
        }

        final remaining = await fakeRepo.listForCurrentUser();
        expect(remaining, hasLength(3));
        // Triés desc → on garde les 3 derniers (heures 14, 13, 12).
        expect(
          remaining.map((b) => b.createdAt.hour).toList(),
          [14, 13, 12],
        );
      });

      test('does not rotate when only 3 exist', () async {
        for (var i = 0; i < 3; i++) {
          fakeRepo.nextCreatedAt = DateTime.utc(2026, 5, 1, 10 + i);
          await service.runBackup();
        }
        expect(await fakeRepo.listForCurrentUser(), hasLength(3));
      });

      test('skips when already in progress (mutex)', () async {
        // Lance deux runBackup en parallèle. Le second doit voir _inProgress
        // et retourner null sans créer un second backup.
        final f1 = service.runBackup();
        final f2 = service.runBackup();
        final results = await Future.wait([f1, f2]);

        // Exactement un des deux a été exécuté ; l'autre a renvoyé null.
        final nonNull = results.where((r) => r != null).toList();
        final nullResults = results.where((r) => r == null).toList();
        expect(nonNull, hasLength(1));
        expect(nullResults, hasLength(1));
        expect(fakeRepo.all, hasLength(1));
      });

      test('on upload failure: does not call setLastBackupAt', () async {
        fakeRepo.throwOnUpload = true;
        expect((await settings.read())!.lastBackupAt, isNull);

        await expectLater(service.runBackup(), throwsA(isA<StateError>()));

        expect((await settings.read())!.lastBackupAt, isNull);
        expect(fakeRepo.all, isEmpty);
      });
    });

    group('restore', () {
      test('round-trip: backup then restore restores original data',
          () async {
        await clients.insert(Client(
          id: 0,
          name: 'Alice',
          addressLabel: 'addr',
          postcode: '22000',
          city: 'Saint-Brieuc',
          coordinates: const Coordinates(lat: 48.5, lon: -2.8),
        ));
        final meta = await service.runBackup();
        expect(meta, isNotNull);

        // Wipe local et restore.
        await db.delete(db.clientsTable).go();
        expect(await clients.listAll(), isEmpty);

        await service.restore(meta!);

        final list = await clients.listAll();
        expect(list, hasLength(1));
        expect(list.first.name, 'Alice');
      });

      test('does NOT touch lastBackupAt', () async {
        // 1er backup : pose lastBackupAt.
        await service.runBackup();
        final firstBackupAt = (await settings.read())!.lastBackupAt;
        expect(firstBackupAt, isNotNull);

        // 2e backup : son snapshot contient déjà firstBackupAt, et son
        // setLastBackupAt() postérieur va écraser settings avec une valeur
        // plus récente (secondBackupAt).
        await Future<void>.delayed(const Duration(milliseconds: 5));
        final meta2 = await service.runBackup();
        final secondBackupAt = (await settings.read())!.lastBackupAt;
        expect(secondBackupAt, isNotNull);
        expect(secondBackupAt!.isAfter(firstBackupAt!), isTrue);

        // restore() : ne doit PAS appeler setLastBackupAt. La valeur dans
        // settings après restore = celle du snapshot importé = firstBackupAt
        // (snapshot pris avant l'écriture du 2e setLastBackupAt).
        await service.restore(meta2!);
        final postRestore = (await settings.read())!.lastBackupAt;
        expect(postRestore, equals(firstBackupAt));
      });
    });

    group('resolveInitialStateAfterOptIn', () {
      test('cloud empty: pushes initial backup, returns true', () async {
        expect(await fakeRepo.countForCurrentUser(), 0);

        final pushed = await service.resolveInitialStateAfterOptIn();

        expect(pushed, isTrue);
        expect(await fakeRepo.countForCurrentUser(), 1);
        expect((await settings.read())!.lastBackupAt, isNotNull);
      });

      test('cloud has backups: returns false, does not push', () async {
        // Pré-remplit avec un backup existant.
        fakeRepo.nextCreatedAt = DateTime.utc(2026, 4, 1);
        await service.runBackup();
        // Reset lastBackupAt pour vérifier que resolve... ne le retouche pas.
        final priorBackupAt = (await settings.read())!.lastBackupAt;
        expect(await fakeRepo.countForCurrentUser(), 1);

        final pushed = await service.resolveInitialStateAfterOptIn();

        expect(pushed, isFalse);
        expect(await fakeRepo.countForCurrentUser(), 1);
        expect((await settings.read())!.lastBackupAt, equals(priorBackupAt));
      });
    });
  });
}
