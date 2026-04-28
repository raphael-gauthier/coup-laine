import 'package:coupe_laine/domain/models/coordinates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coordinates', () {
    test('equal when lat and lon match', () {
      const a = Coordinates(lat: 48.0, lon: -3.0);
      const b = Coordinates(lat: 48.0, lon: -3.0);
      expect(a, equals(b));
    });

    test('rejects out-of-range latitude', () {
      expect(() => Coordinates.checked(lat: 91, lon: 0), throwsArgumentError);
    });

    test('rejects out-of-range longitude', () {
      expect(() => Coordinates.checked(lat: 0, lon: 181), throwsArgumentError);
    });
  });
}
