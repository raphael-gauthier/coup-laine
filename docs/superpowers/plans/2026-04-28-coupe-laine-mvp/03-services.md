# Phase 3 — External services (BAN + ORS)

**Goal:** HTTP service classes for BAN address autocomplete and OpenRouteService matrix, fully tested with mocked `http.Client` against captured fixture JSON.

**Verification at end of phase:** `flutter test test/infra/services/` is green; both services parse real-world responses and map errors to typed exceptions.

> The MVP only uses ORS's **matrix** endpoint (we already have all the distances we need from there). We do not draw route polylines on the map, so no directions endpoint.

---

## Task 3.1: BAN response fixture + service tests

**Files:**
- Create: `test/infra/fixtures/ban_search_response.json`
- Create: `test/infra/services/ban_geocoding_service_test.dart`

- [ ] **Step 1: Capture a real BAN response as a fixture**

```bash
curl 'https://api-adresse.data.gouv.fr/search/?q=1+rue+de+brest+saint+brieuc&limit=2&autocomplete=1' \
  -o test/infra/fixtures/ban_search_response.json
```

- [ ] **Step 2: Verify the fixture is non-empty**

```bash
head -c 200 test/infra/fixtures/ban_search_response.json
```
Expected: starts with `{"type":"FeatureCollection",...`.

- [ ] **Step 3: Write the failing test**

```dart
// test/infra/services/ban_geocoding_service_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:coupe_laine/infra/services/ban_geocoding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('BanGeocodingService', () {
    late String fixture;

    setUpAll(() {
      fixture = File('test/infra/fixtures/ban_search_response.json')
          .readAsStringSync();
    });

    test('parses a successful response', () async {
      final client = MockClient((req) async {
        expect(req.url.host, 'api-adresse.data.gouv.fr');
        expect(req.url.queryParameters['q'], '1 rue de brest saint brieuc');
        expect(req.url.queryParameters['limit'], '5');
        return http.Response(fixture, 200,
            headers: {'content-type': 'application/json'});
      });
      final svc = BanGeocodingService(httpClient: client);
      final results = await svc.search('1 rue de brest saint brieuc');
      expect(results, isNotEmpty);
      final first = results.first;
      expect(first.label, isNotEmpty);
      expect(first.postcode, isNotEmpty);
      expect(first.city, isNotEmpty);
      expect(first.coordinates.lat, inExclusiveRange(40.0, 52.0));
      expect(first.coordinates.lon, inExclusiveRange(-6.0, 10.0));
    });

    test('returns empty list when API returns no features', () async {
      final empty = jsonEncode({'type': 'FeatureCollection', 'features': []});
      final client = MockClient((_) async => http.Response(empty, 200));
      final svc = BanGeocodingService(httpClient: client);
      expect(await svc.search('zzzzz'), isEmpty);
    });

    test('throws GeocodingException on 5xx', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      final svc = BanGeocodingService(httpClient: client);
      expect(svc.search('x'), throwsA(isA<GeocodingException>()));
    });

    test('throws GeocodingException on network error', () async {
      final client = MockClient((_) async {
        throw const SocketException('offline');
      });
      final svc = BanGeocodingService(httpClient: client);
      expect(svc.search('x'), throwsA(isA<GeocodingException>()));
    });

    test('does not call API for queries shorter than 3 chars', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      final svc = BanGeocodingService(httpClient: client);
      expect(await svc.search('ab'), isEmpty);
      expect(called, isFalse);
    });
  });
}
```

- [ ] **Step 4: Run, expect FAIL** (no service yet)

```bash
flutter test test/infra/services/ban_geocoding_service_test.dart
```

- [ ] **Step 5: Implement `lib/infra/services/ban_geocoding_service.dart`**

```dart
// lib/infra/services/ban_geocoding_service.dart
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
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final features = (body['features'] as List? ?? const []);
      return features
          .map((f) => _parseFeature(f as Map<String, dynamic>))
          .whereType<GeocodingResult>()
          .toList();
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
```

- [ ] **Step 6: Run, expect PASS**

```bash
flutter test test/infra/services/ban_geocoding_service_test.dart
```

- [ ] **Step 7: Commit**

```bash
git add lib/infra/services/ban_geocoding_service.dart \
        test/infra/services/ban_geocoding_service_test.dart \
        test/infra/fixtures/ban_search_response.json
git commit -m "feat(infra): BAN geocoding service with autocomplete"
```

---

## Task 3.2: ORS matrix fixture + service tests

**Files:**
- Create: `test/infra/fixtures/ors_matrix_response.json`
- Create: `test/infra/services/ors_routing_service_test.dart`

- [ ] **Step 1: Capture a real ORS matrix response**

> Replace `<KEY>` with your ORS key for the capture only. The fixture stays committed without a key.

```bash
curl -X POST 'https://api.openrouteservice.org/v2/matrix/driving-car' \
  -H 'Authorization: <KEY>' \
  -H 'Content-Type: application/json' \
  -d '{"locations":[[-2.7676,48.5092],[-3.5821,48.7500],[-4.0855,48.4014]],"metrics":["distance","duration"]}' \
  -o test/infra/fixtures/ors_matrix_response.json
```

Verify:

```bash
head -c 200 test/infra/fixtures/ors_matrix_response.json
```
Expected: contains `"distances"` and `"durations"` arrays.

- [ ] **Step 2: Write the failing test**

```dart
// test/infra/services/ors_routing_service_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:coupe_laine/infra/services/ors_routing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OrsRoutingService.matrix', () {
    late String fixture;

    setUpAll(() {
      fixture = File('test/infra/fixtures/ors_matrix_response.json')
          .readAsStringSync();
    });

    final locations = const [
      Coordinates(lat: 48.5092, lon: -2.7676),
      Coordinates(lat: 48.7500, lon: -3.5821),
      Coordinates(lat: 48.4014, lon: -4.0855),
    ];

    test('sends key and parses distances/durations', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(fixture, 200,
            headers: {'content-type': 'application/json'});
      });
      final svc = OrsRoutingService(apiKey: 'TESTKEY', httpClient: client);
      final result = await svc.matrix(locations: locations);
      expect(captured.headers['authorization'], 'TESTKEY');
      expect(captured.method, 'POST');
      expect(captured.url.path, '/v2/matrix/driving-car');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['locations'], hasLength(3));
      expect(result.distances.length, 3);
      expect(result.distances[0].length, 3);
      expect(result.distances[0][0], 0); // self-distance
    });

    test('passes sources/destinations when provided', () async {
      final empty = jsonEncode({
        'distances': [
          [0.0, 5000.0]
        ],
        'durations': [
          [0.0, 600.0]
        ],
      });
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(empty, 200);
      });
      final svc = OrsRoutingService(apiKey: 'KEY', httpClient: client);
      await svc.matrix(
        locations: locations,
        sources: const [0],
        destinations: const [0, 1],
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['sources'], [0]);
      expect(body['destinations'], [0, 1]);
    });

    test('throws OrsAuthException on 403', () async {
      final client = MockClient((_) async => http.Response('forbidden', 403));
      final svc = OrsRoutingService(apiKey: 'KEY', httpClient: client);
      expect(
        svc.matrix(locations: locations),
        throwsA(isA<OrsAuthException>()),
      );
    });

    test('throws OrsQuotaException on 429', () async {
      final client = MockClient((_) async => http.Response('limit', 429));
      final svc = OrsRoutingService(apiKey: 'KEY', httpClient: client);
      expect(
        svc.matrix(locations: locations),
        throwsA(isA<OrsQuotaException>()),
      );
    });

    test('throws OrsException on 5xx', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      final svc = OrsRoutingService(apiKey: 'KEY', httpClient: client);
      expect(
        svc.matrix(locations: locations),
        throwsA(isA<OrsException>()),
      );
    });

    test('throws OrsException on socket failure', () async {
      final client = MockClient((_) async {
        throw const SocketException('down');
      });
      final svc = OrsRoutingService(apiKey: 'KEY', httpClient: client);
      expect(
        svc.matrix(locations: locations),
        throwsA(isA<OrsException>()),
      );
    });
  });
}
```

- [ ] **Step 3: Run, expect FAIL**

```bash
flutter test test/infra/services/ors_routing_service_test.dart
```

- [ ] **Step 4: Implement `lib/infra/services/ors_routing_service.dart`**

```dart
// lib/infra/services/ors_routing_service.dart
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
  /// distances[i][j] in metres; null if ORS reported unreachable
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
```

- [ ] **Step 5: Run, expect PASS**

```bash
flutter test test/infra/services/ors_routing_service_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/infra/services/ors_routing_service.dart \
        test/infra/services/ors_routing_service_test.dart \
        test/infra/fixtures/ors_matrix_response.json
git commit -m "feat(infra): ORS matrix routing service with typed errors"
```

---

## Task 3.3: Phase 3 sweep

- [ ] **Step 1: Run service tests**

```bash
flutter test test/infra/services/
```

- [ ] **Step 2: Run all tests**

```bash
flutter test
```
Expected: domain + data + services all green.

---

**Phase 3 done.** External I/O is encapsulated. The next phase wires repositories and services into Riverpod and starts the UI.
