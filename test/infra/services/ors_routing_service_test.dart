import 'dart:async';
import 'dart:io';

import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/infra/services/ors_routing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

void main() {
  late _MockFunctions functions;
  late OrsRoutingService service;

  setUpAll(() {
    registerFallbackValue(HttpMethod.post);
  });

  setUp(() {
    functions = _MockFunctions();
    service = OrsRoutingService(functions: functions);
  });

  FunctionResponse okResponse(Map<String, dynamic> data) =>
      FunctionResponse(status: 200, data: data);

  // Stubs the next invoke call to return [data] (or throw [error]).
  void stubInvokeOk(Map<String, dynamic> data) {
    when(() => functions.invoke(
          any(),
          body: any(named: 'body'),
          method: any(named: 'method'),
        )).thenAnswer((_) async => okResponse(data));
  }

  void stubInvokeThrows(Object error) {
    when(() => functions.invoke(
          any(),
          body: any(named: 'body'),
          method: any(named: 'method'),
        )).thenThrow(error);
  }

  group('getRouteGeometry', () {
    test('throws ArgumentError when fewer than 2 waypoints', () async {
      expect(
        () => service.getRouteGeometry(
          waypoints: const [Coordinates(lat: 48.85, lon: 2.35)],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('parses GeoJSON and swaps lon/lat to lat/lon', () async {
      stubInvokeOk({
        'features': [
          {
            'geometry': {
              'coordinates': [
                [2.35, 48.85],
                [2.36, 48.86],
              ],
            },
          },
        ],
      });

      final r = await service.getRouteGeometry(waypoints: const [
        Coordinates(lat: 48.85, lon: 2.35),
        Coordinates(lat: 48.86, lon: 2.36),
      ]);

      expect(r, hasLength(2));
      expect(r.first.lat, 48.85);
      expect(r.first.lon, 2.35);
      expect(r.last.lat, 48.86);
      expect(r.last.lon, 2.36);
    });

    test('sends [lon, lat] coordinates to ors-proxy directions', () async {
      stubInvokeOk({
        'features': [
          {
            'geometry': {
              'coordinates': [
                [2.35, 48.85],
                [2.36, 48.86],
              ],
            },
          },
        ],
      });

      await service.getRouteGeometry(waypoints: const [
        Coordinates(lat: 48.85, lon: 2.35),
        Coordinates(lat: 48.86, lon: 2.36),
      ]);

      final captured = verify(() => functions.invoke(
            captureAny(),
            body: captureAny(named: 'body'),
            method: HttpMethod.post,
          )).captured;
      expect(captured[0], 'ors-proxy/v2/directions/driving-car/geojson');
      final body = captured[1] as Map<String, dynamic>;
      expect(body['coordinates'], [
        [2.35, 48.85],
        [2.36, 48.86],
      ]);
    });

    test(
        'close-loop fallback adds last waypoint when polyline does not reach back',
        () async {
      // first == last, polyline ends far from base (> 0.001°).
      stubInvokeOk({
        'features': [
          {
            'geometry': {
              'coordinates': [
                [2.35, 48.85], // base
                [2.40, 48.90], // far point
                [2.39, 48.89], // ends well away from base
              ],
            },
          },
        ],
      });

      final r = await service.getRouteGeometry(waypoints: const [
        Coordinates(lat: 48.85, lon: 2.35),
        Coordinates(lat: 48.90, lon: 2.40),
        Coordinates(lat: 48.85, lon: 2.35),
      ]);

      // Original 3 polyline points + appended base = 4.
      expect(r, hasLength(4));
      expect(r.last.lat, 48.85);
      expect(r.last.lon, 2.35);
    });

    test(
        'close-loop fallback skipped when polyline ends within ~0.001° of base',
        () async {
      stubInvokeOk({
        'features': [
          {
            'geometry': {
              'coordinates': [
                [2.35, 48.85],
                [2.40, 48.90],
                [2.3505, 48.8505], // within threshold of base
              ],
            },
          },
        ],
      });

      final r = await service.getRouteGeometry(waypoints: const [
        Coordinates(lat: 48.85, lon: 2.35),
        Coordinates(lat: 48.90, lon: 2.40),
        Coordinates(lat: 48.85, lon: 2.35),
      ]);

      expect(r, hasLength(3));
    });

    test('throws OrsException on response missing features', () async {
      stubInvokeOk({'something': 'else'});
      expect(
        () => service.getRouteGeometry(waypoints: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ]),
        throwsA(isA<OrsException>()),
      );
    });

    test('throws OrsException on missing coordinates in geometry', () async {
      stubInvokeOk({
        'features': [
          {'geometry': <String, dynamic>{}}
        ],
      });
      expect(
        () => service.getRouteGeometry(waypoints: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ]),
        throwsA(isA<OrsException>()),
      );
    });
  });

  group('matrix', () {
    test('parses distances and durations, rounding to int', () async {
      stubInvokeOk({
        'distances': [
          [0, 1234.7],
          [1234.2, 0],
        ],
        'durations': [
          [0, 60.4],
          [60.6, 0],
        ],
      });

      final r = await service.matrix(locations: const [
        Coordinates(lat: 48.85, lon: 2.35),
        Coordinates(lat: 48.86, lon: 2.36),
      ]);

      expect(r.distances, [
        [0, 1235],
        [1234, 0],
      ]);
      expect(r.durations, [
        [0, 60],
        [61, 0],
      ]);
    });

    test('maps null cells to -1', () async {
      stubInvokeOk({
        'distances': [
          [0, null],
          [null, 0],
        ],
        'durations': [
          [0, null],
          [null, 0],
        ],
      });

      final r = await service.matrix(locations: const [
        Coordinates(lat: 48.85, lon: 2.35),
        Coordinates(lat: 48.86, lon: 2.36),
      ]);

      expect(r.distances, [
        [0, -1],
        [-1, 0],
      ]);
      expect(r.durations, [
        [0, -1],
        [-1, 0],
      ]);
    });

    test('passes sources/destinations and locations as [lon, lat]', () async {
      stubInvokeOk({
        'distances': [
          [0]
        ],
        'durations': [
          [0]
        ],
      });

      await service.matrix(
        locations: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ],
        sources: const [0],
        destinations: const [1],
      );

      final captured = verify(() => functions.invoke(
            captureAny(),
            body: captureAny(named: 'body'),
            method: HttpMethod.post,
          )).captured;
      expect(captured[0], 'ors-proxy/v2/matrix/driving-car');
      final body = captured[1] as Map<String, dynamic>;
      expect(body['locations'], [
        [2.35, 48.85],
        [2.36, 48.86],
      ]);
      expect(body['metrics'], ['distance', 'duration']);
      expect(body['sources'], [0]);
      expect(body['destinations'], [1]);
    });

    test('throws OrsException when distances/durations missing', () async {
      stubInvokeOk({'something': 'else'});
      expect(
        () => service.matrix(locations: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ]),
        throwsA(isA<OrsException>()),
      );
    });

    test('throws OrsException when matrix rows are malformed', () async {
      stubInvokeOk({
        'distances': 'not-a-list-of-lists',
        'durations': [[0]],
      });
      expect(
        () => service.matrix(locations: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ]),
        throwsA(isA<OrsException>()),
      );
    });

  });

  group('error mapping', () {
    test('FunctionException 401 -> OrsAuthException', () async {
      stubInvokeThrows(const FunctionException(status: 401));
      expect(
        () => service.matrix(locations: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ]),
        throwsA(isA<OrsAuthException>()),
      );
    });

    test('FunctionException 403 -> OrsAuthException', () async {
      stubInvokeThrows(const FunctionException(status: 403));
      expect(
        () => service.getRouteGeometry(waypoints: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ]),
        throwsA(isA<OrsAuthException>()),
      );
    });

    test('FunctionException 429 -> OrsQuotaException', () async {
      stubInvokeThrows(const FunctionException(status: 429));
      expect(
        () => service.matrix(locations: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ]),
        throwsA(isA<OrsQuotaException>()),
      );
    });

    test('FunctionException 500 -> plain OrsException (not auth/quota)',
        () async {
      stubInvokeThrows(const FunctionException(status: 500));
      await expectLater(
        () => service.matrix(locations: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ]),
        throwsA(allOf(
          isA<OrsException>(),
          isNot(isA<OrsAuthException>()),
          isNot(isA<OrsQuotaException>()),
        )),
      );
    });

    test('SocketException -> OrsException', () async {
      stubInvokeThrows(const SocketException('offline'));
      expect(
        () => service.matrix(locations: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ]),
        throwsA(isA<OrsException>()),
      );
    });

    test('TimeoutException -> OrsException', () async {
      stubInvokeThrows(TimeoutException('slow'));
      expect(
        () => service.matrix(locations: const [
          Coordinates(lat: 48.85, lon: 2.35),
          Coordinates(lat: 48.86, lon: 2.36),
        ]),
        throwsA(isA<OrsException>()),
      );
    });
  });
}
