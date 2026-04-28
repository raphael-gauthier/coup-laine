import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/use_cases/client_status.dart';
import 'package:flutter_test/flutter_test.dart';

Client _client({
  bool isWaiting = false,
  bool needsDistanceRecompute = false,
  DateTime? lastShearingDate,
}) {
  return Client(
    id: 1,
    name: 'X',
    addressLabel: '1 rue X',
    postcode: '22000',
    city: 'Saint-Brieuc',
    coordinates: const Coordinates(lat: 48, lon: -3),
    isWaiting: isWaiting,
    needsDistanceRecompute: needsDistanceRecompute,
    lastShearingDate: lastShearingDate,
  );
}

void main() {
  group('ClientStatus', () {
    test('default when nothing special', () {
      expect(_client().status, ClientStatus.defaultStatus);
    });

    test('recompute beats everything', () {
      final c = _client(
        needsDistanceRecompute: true,
        isWaiting: true,
        lastShearingDate: DateTime.now().subtract(const Duration(days: 500)),
      );
      expect(c.status, ClientStatus.recompute);
    });

    test('waiting beats overdue', () {
      final c = _client(
        isWaiting: true,
        lastShearingDate: DateTime.now().subtract(const Duration(days: 500)),
      );
      expect(c.status, ClientStatus.waiting);
    });

    test('overdue when last shearing > 395 days ago and not waiting', () {
      final c = _client(
        lastShearingDate: DateTime.now().subtract(const Duration(days: 500)),
      );
      expect(c.status, ClientStatus.overdue);
    });

    test('default when last shearing recent', () {
      final c = _client(
        lastShearingDate: DateTime.now().subtract(const Duration(days: 200)),
      );
      expect(c.status, ClientStatus.defaultStatus);
    });

    test('default when last shearing is null and no flags', () {
      expect(_client().status, ClientStatus.defaultStatus);
    });
  });
}
