import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/models/coordinates.dart';

class GeocodingException implements Exception {
  final String message;
  final Object? cause;
  GeocodingException(this.message, [this.cause]);
  @override
  String toString() => 'GeocodingException: $message';
}

class GeocodingResult {
  final String label;
  final String postcode;
  final String city;
  final Coordinates coordinates;

  const GeocodingResult({
    required this.label,
    required this.postcode,
    required this.city,
    required this.coordinates,
  });
}

class BanGeocodingService {
  static const _host = 'api-adresse.data.gouv.fr';
  final http.Client _http;

  BanGeocodingService({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  Future<List<GeocodingResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final uri = Uri.https(_host, '/search/', {
      'q': q,
      'limit': '5',
      'autocomplete': '1',
    });
    try {
      final res = await _http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        throw GeocodingException('HTTP ${res.statusCode}');
      }
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final features = (body['features'] as List? ?? const []);
        return features
            .map((f) => _parseFeature(f as Map<String, dynamic>))
            .whereType<GeocodingResult>()
            .toList();
      } on FormatException catch (e) {
        throw GeocodingException('Invalid JSON response', e);
      }
    } on GeocodingException {
      rethrow;
    } on SocketException catch (e) {
      throw GeocodingException('Network unavailable', e);
    } on TimeoutException catch (e) {
      throw GeocodingException('Request timed out', e);
    } catch (e) {
      throw GeocodingException('Unexpected error', e);
    }
  }

  GeocodingResult? _parseFeature(Map<String, dynamic> feature) {
    final geom = feature['geometry'] as Map<String, dynamic>?;
    final coords = geom?['coordinates'] as List?;
    final props = feature['properties'] as Map<String, dynamic>?;
    if (coords == null || coords.length < 2 || props == null) return null;
    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();
    final label = props['label'] as String?;
    final postcode = props['postcode'] as String?;
    final city = props['city'] as String?;
    if (label == null || postcode == null || city == null) return null;
    return GeocodingResult(
      label: label,
      postcode: postcode,
      city: city,
      coordinates: Coordinates(lat: lat, lon: lon),
    );
  }
}
