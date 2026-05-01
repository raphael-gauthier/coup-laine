import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/models/coordinates.dart';

class OrsException implements Exception {
  final String message;
  final Object? cause;
  OrsException(this.message, [this.cause]);
  @override
  String toString() => 'OrsException: $message';
}

class OrsAuthException extends OrsException {
  OrsAuthException(super.message, [super.cause]);
}

class OrsQuotaException extends OrsException {
  OrsQuotaException(super.message, [super.cause]);
}

class OrsMatrixResult {
  /// distances[i][j] in metres; -1 if ORS reported unreachable
  final List<List<int>> distances;
  /// durations[i][j] in seconds
  final List<List<int>> durations;

  const OrsMatrixResult({
    required this.distances,
    required this.durations,
  });
}

class OrsRoutingService {
  static const _host = 'api.openrouteservice.org';
  final String _apiKey;
  final http.Client _http;

  OrsRoutingService({required String apiKey, http.Client? httpClient})
      : _apiKey = apiKey,
        _http = httpClient ?? http.Client();

  /// Récupère la géométrie de route entre N waypoints (≥ 2). Retourne la
  /// liste de points lat/lon de la polyline. Lance [OrsException] sur
  /// erreur réseau / quota / 5xx — le caller doit tomber en fallback
  /// (lignes droites) gracieusement.
  ///
  /// Endpoint : `POST /v2/directions/driving-car/geojson`. Le format
  /// GeoJSON retourne les coordonnées en `[lon, lat]`, qu'on swap.
  Future<List<Coordinates>> getRouteGeometry({
    required List<Coordinates> waypoints,
  }) async {
    if (waypoints.length < 2) {
      throw ArgumentError('Need at least 2 waypoints to compute a route');
    }
    final uri = Uri.https(_host, '/v2/directions/driving-car/geojson');
    final body = <String, dynamic>{
      'coordinates': [
        for (final c in waypoints) [c.lon, c.lat],
      ],
    };

    try {
      final res = await _http
          .post(
            uri,
            headers: {
              'Authorization': _apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 403) {
        throw OrsAuthException('Forbidden — check ORS_API_KEY');
      }
      if (res.statusCode == 429) {
        throw OrsQuotaException('ORS quota exceeded');
      }
      if (res.statusCode != 200) {
        throw OrsException('HTTP ${res.statusCode}');
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final features = json['features'] as List?;
      if (features == null || features.isEmpty) {
        throw OrsException('Empty features in directions response');
      }
      final geometry = (features.first as Map)['geometry'] as Map?;
      final coords = geometry?['coordinates'] as List?;
      if (coords == null) {
        throw OrsException('Missing coordinates in directions geometry');
      }
      // GeoJSON returns [lon, lat] pairs — swap to our [lat, lon] convention.
      final polyline = <Coordinates>[
        for (final p in coords)
          if (p is List && p.length >= 2)
            Coordinates(
              lat: (p[1] as num).toDouble(),
              lon: (p[0] as num).toDouble(),
            ),
      ];

      // Defensive close-loop : si le dernier waypoint demandé est le même
      // que le premier (typique : tournée qui revient à la base), on
      // s'assure que la polyline retournée se termine bien sur ce point —
      // ORS peut tronquer le doublon de fin, ce qui laisse le trajet de
      // retour visiblement absent.
      if (polyline.isNotEmpty && waypoints.length >= 2) {
        final firstWp = waypoints.first;
        final lastWp = waypoints.last;
        final loopClosed = firstWp.lat == lastWp.lat && firstWp.lon == lastWp.lon;
        if (loopClosed) {
          final endpoint = polyline.last;
          // ~100m threshold (~0.001° lat ≈ 111m). Si la fin de polyline est
          // déjà à proximité de la base, pas besoin d'ajouter.
          final dLat = (endpoint.lat - lastWp.lat).abs();
          final dLon = (endpoint.lon - lastWp.lon).abs();
          if (dLat > 0.001 || dLon > 0.001) {
            polyline.add(lastWp);
          }
        }
      }

      return polyline;
    } on OrsException {
      rethrow;
    } on SocketException catch (e) {
      throw OrsException('Network unavailable', e);
    } on TimeoutException catch (e) {
      throw OrsException('Request timed out', e);
    } catch (e) {
      throw OrsException('Unexpected error', e);
    }
  }

  Future<OrsMatrixResult> matrix({
    required List<Coordinates> locations,
    List<int>? sources,
    List<int>? destinations,
  }) async {
    final uri = Uri.https(_host, '/v2/matrix/driving-car');
    final body = <String, dynamic>{
      'locations': [
        for (final c in locations) [c.lon, c.lat],
      ],
      'metrics': ['distance', 'duration'],
    };
    if (sources != null) body['sources'] = sources;
    if (destinations != null) body['destinations'] = destinations;

    try {
      final res = await _http
          .post(
            uri,
            headers: {
              'Authorization': _apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 403) {
        throw OrsAuthException('Forbidden — check ORS_API_KEY');
      }
      if (res.statusCode == 429) {
        throw OrsQuotaException('ORS quota exceeded');
      }
      if (res.statusCode != 200) {
        throw OrsException('HTTP ${res.statusCode}');
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final distances = (json['distances'] as List)
          .map((row) => (row as List)
              .map((v) => v == null ? -1 : (v as num).round())
              .toList())
          .toList();
      final durations = (json['durations'] as List)
          .map((row) => (row as List)
              .map((v) => v == null ? -1 : (v as num).round())
              .toList())
          .toList();
      return OrsMatrixResult(distances: distances, durations: durations);
    } on OrsException {
      rethrow;
    } on SocketException catch (e) {
      throw OrsException('Network unavailable', e);
    } on TimeoutException catch (e) {
      throw OrsException('Request timed out', e);
    } catch (e) {
      throw OrsException('Unexpected error', e);
    }
  }
}
