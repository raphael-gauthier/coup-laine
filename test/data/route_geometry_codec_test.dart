import 'package:flutter_test/flutter_test.dart';
import 'package:coup_laine/data/repositories/tour_repository.dart';
import 'package:coup_laine/domain/models/coordinates.dart';

void main() {
  group('encodeRouteGeometry / decodeRouteGeometry', () {
    test('null in → null out', () {
      expect(encodeRouteGeometry(null), isNull);
      expect(decodeRouteGeometry(null), isNull);
    });

    test('empty list → null out (round-trip safe)', () {
      expect(encodeRouteGeometry(const []), isNull);
      expect(decodeRouteGeometry(''), isNull);
    });

    test('round-trip preserves order and values', () {
      final coords = [
        const Coordinates(lat: 48.0, lon: -3.0),
        const Coordinates(lat: 48.5, lon: -2.5),
        const Coordinates(lat: 49.0, lon: -2.0),
      ];
      final encoded = encodeRouteGeometry(coords);
      expect(encoded, isNotNull);
      final decoded = decodeRouteGeometry(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.length, 3);
      expect(decoded[0].lat, 48.0);
      expect(decoded[0].lon, -3.0);
      expect(decoded[2].lat, 49.0);
      expect(decoded[2].lon, -2.0);
    });

    test('decode skips malformed entries silently', () {
      const json = '[[48.0, -3.0], "bad", [49.0]]';
      final decoded = decodeRouteGeometry(json);
      expect(decoded, isNotNull);
      expect(decoded!.length, 1);
      expect(decoded[0].lat, 48.0);
    });

    test('decode invalid JSON returns null', () {
      expect(() => decodeRouteGeometry('not-json'), throwsA(anything));
    });
  });
}
