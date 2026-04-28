import 'dart:convert';
import 'dart:io';

import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/infra/services/ors_routing_service.dart';
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
