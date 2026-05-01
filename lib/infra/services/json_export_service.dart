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

// Drift's row.toJson() leaves typed-list converter fields as their domain
// object lists (e.g. List<TourStopPrestation>, List<AnimalCount>), which
// jsonEncode can't serialize. Replace them with plain JSON-friendly maps
// before encoding.
List<Map<String, dynamic>> _serializeTourStopPrestations(
  List<TourStopPrestation> list,
) =>
    [
      for (final p in list)
        {
          'prestationId': p.prestationId,
          'qty': p.qty,
          'nameSnapshot': p.nameSnapshot,
          'priceCentsSnapshot': p.priceCentsSnapshot,
          'minutesSnapshot': p.minutesSnapshot,
          'categoryIdSnapshot': p.categoryIdSnapshot,
          'categoryNameSnapshot': p.categoryNameSnapshot,
          'speciesNameSnapshot': p.speciesNameSnapshot,
        },
    ];

List<Map<String, dynamic>> _serializeAnimalCounts(List<AnimalCount> list) => [
      for (final a in list) {'categoryId': a.categoryId, 'count': a.count},
    ];

class JsonImportException implements Exception {
  final String message;
  JsonImportException(this.message);
  @override
  String toString() => 'JsonImportException: $message';
}

class JsonExportService {
  static const int schemaVersion = 2;

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
    final sp = await database.select(database.speciesTable).get();
    final ac = await database.select(database.animalCategoriesTable).get();
    final pr = await database.select(database.prestationsTable).get();
    final mh = await database.select(database.manualHistoryEntriesTable).get();
    return jsonEncode({
      'schema': schemaVersion,
      'settings': s?.toJson(),
      'clients': cs.map((r) {
        final j = r.toJson();
        j['animals'] = _serializeAnimalCounts(r.animals);
        return j;
      }).toList(),
      'distanceMatrix': dm.map((r) => r.toJson()).toList(),
      'tours': ts.map((r) => r.toJson()).toList(),
      'tourStops': stops.map((r) {
        final j = r.toJson();
        j['plannedPrestations'] =
            _serializeTourStopPrestations(r.plannedPrestations);
        final actuals = r.actualPrestations;
        if (actuals != null) {
          j['actualPrestations'] = _serializeTourStopPrestations(actuals);
        }
        return j;
      }).toList(),
      'species': sp.map((r) => r.toJson()).toList(),
      'animalCategories': ac.map((r) => r.toJson()).toList(),
      'prestations': pr.map((r) => r.toJson()).toList(),
      'manualHistoryEntries': mh.map((r) {
        final j = r.toJson();
        j['prestations'] = _serializeTourStopPrestations(r.prestations);
        return j;
      }).toList(),
    });
  }

  Future<void> importFromJsonString(String body) async {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final schema = json['schema'];
    if (schema is! int || schema > schemaVersion) {
      throw JsonImportException(
        'Sauvegarde au format v$schema, non supportée (max v$schemaVersion).',
      );
    }
    // schema < schemaVersion : accepté en lecture (forward compat —
    // les `?? []` plus bas gèrent l'absence des nouvelles clés).
    await database.transaction(() async {
      // wipe — ordre important pour respecter les FK cascade
      await database.delete(database.tourStopsTable).go();
      await database.delete(database.toursTable).go();
      await database.delete(database.distanceMatrixTable).go();
      await database.delete(database.manualHistoryEntriesTable).go();
      await database.delete(database.prestationsTable).go();
      await database.delete(database.animalCategoriesTable).go();
      await database.delete(database.speciesTable).go();
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
      for (final sp in (json['species'] as List? ?? [])) {
        await database.into(database.speciesTable).insert(
              SpeciesRow.fromJson(sp as Map<String, dynamic>),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final ac in (json['animalCategories'] as List? ?? [])) {
        await database.into(database.animalCategoriesTable).insert(
              AnimalCategoryRow.fromJson(ac as Map<String, dynamic>),
              mode: InsertMode.insertOrReplace,
            );
      }
      for (final pr in (json['prestations'] as List? ?? [])) {
        await database.into(database.prestationsTable).insert(
              PrestationRow.fromJson(pr as Map<String, dynamic>),
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
      for (final mh in (json['manualHistoryEntries'] as List? ?? [])) {
        final row = Map<String, dynamic>.from(mh as Map<String, dynamic>);
        if (row['prestations'] is List) {
          row['prestations'] =
              _coerceTourStopPrestations(row['prestations'] as List);
        }
        await database.into(database.manualHistoryEntriesTable).insert(
              ManualHistoryEntryRow.fromJson(row),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }
}
