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
      expect(svc.search('test'), throwsA(isA<GeocodingException>()));
    });

    test('throws GeocodingException on network error', () async {
      final client = MockClient((_) async {
        throw const SocketException('offline');
      });
      final svc = BanGeocodingService(httpClient: client);
      expect(svc.search('test'), throwsA(isA<GeocodingException>()));
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
