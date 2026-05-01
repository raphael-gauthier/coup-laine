import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/repositories/client_repository.dart';
import '../../data/repositories/distance_matrix_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/tour_repository.dart';
import '../../domain/models/animal_count.dart';
import '../../domain/models/tour_stop_prestation.dart';
import '../db/app_database.dart';

List<TourStopPrestation> _coerceTourStopPrestations(List raw) => [
      for (final e in raw)
        TourStopPrestation(
          prestationId: (e as Map<String, dynamic>)['prestationId'] as int,
          qty: e['qty'] as int,
          nameSnapshot: e['nameSnapshot'] as String,
          priceCentsSnapshot: e['priceCentsSnapshot'] as int,
          minutesSnapshot: e['minutesSnapshot'] as int,
          categoryIdSnapshot: e['categoryIdSnapshot'] as int?,
          categoryNameSnapshot: e['categoryNameSnapshot'] as String?,
          speciesNameSnapshot: e['speciesNameSnapshot'] as String?,
        ),
    ];

class JsonImportException implements Exception {
  final String message;
  JsonImportException(this.message);
  @override
  String toString() => 'JsonImportException: $message';
}

class JsonExportService {
  static const int schemaVersion = 1;

  final AppDatabase database;
  final SettingsRepository settings;
  final ClientRepository clients;
  final DistanceMatrixRepository matrix;
  final TourRepository tours;

  JsonExportService({
    required this.database,
    required this.settings,
    required this.clients,
    required this.matrix,
    required this.tours,
  });

  Future<String> exportToJsonString() async {
    final s = await database.select(database.settingsTable).getSingleOrNull();
    final cs = await database.select(database.clientsTable).get();
    final dm = await database.select(database.distanceMatrixTable).get();
    final ts = await database.select(database.toursTable).get();
    final stops = await database.select(database.tourStopsTable).get();
    return jsonEncode({
      'schema': schemaVersion,
      'settings': s?.toJson(),
      'clients': cs.map((r) => r.toJson()).toList(),
      'distanceMatrix': dm.map((r) => r.toJson()).toList(),
      'tours': ts.map((r) => r.toJson()).toList(),
      'tourStops': stops.map((r) => r.toJson()).toList(),
    });
  }

  Future<void> importFromJsonString(String body) async {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final schema = json['schema'];
    if (schema != schemaVersion) {
      throw JsonImportException('Unsupported schema $schema');
    }
    await database.transaction(() async {
      // wipe
      await database.delete(database.tourStopsTable).go();
      await database.delete(database.toursTable).go();
      await database.delete(database.distanceMatrixTable).go();
      await database.delete(database.clientsTable).go();
      await database.delete(database.settingsTable).go();

      final s = json['settings'] as Map<String, dynamic>?;
      if (s != null) {
        await database.into(database.settingsTable).insert(
              SettingsRow.fromJson(s),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final c in (json['clients'] as List)) {
        final row = Map<String, dynamic>.from(c as Map<String, dynamic>);
        // Drift's default serializer cannot cast List<dynamic> to List<String>
        // or to List<AnimalCount>; coerce typed-list fields manually before
        // handing to fromJson.
        if (row['phones'] is List) {
          row['phones'] = (row['phones'] as List).cast<String>();
        }
        if (row['animals'] is List) {
          row['animals'] = [
            for (final e in row['animals'] as List)
              AnimalCount(
                categoryId: (e as Map<String, dynamic>)['categoryId'] as int,
                count: e['count'] as int,
              ),
          ];
        }
        await database.into(database.clientsTable).insert(
              ClientRow.fromJson(row),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final d in (json['distanceMatrix'] as List)) {
        await database.into(database.distanceMatrixTable).insert(
              DistanceMatrixRow.fromJson(d as Map<String, dynamic>),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final t in (json['tours'] as List)) {
        await database.into(database.toursTable).insert(
              TourRow.fromJson(t as Map<String, dynamic>),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final st in (json['tourStops'] as List)) {
        final row = Map<String, dynamic>.from(st as Map<String, dynamic>);
        if (row['plannedPrestations'] is List) {
          row['plannedPrestations'] =
              _coerceTourStopPrestations(row['plannedPrestations'] as List);
        }
        if (row['actualPrestations'] is List) {
          row['actualPrestations'] =
              _coerceTourStopPrestations(row['actualPrestations'] as List);
        }
        await database.into(database.tourStopsTable).insert(
              TourStopRow.fromJson(row),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }
}
