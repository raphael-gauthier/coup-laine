import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/use_cases/client_status.dart';
import 'package:flutter_test/flutter_test.dart';

Client _client({
  bool isWaiting = false,
  bool isBanned = false,
  int sheepCount = 5,
}) {
  return Client(
    id: 1,
    name: 'X',
    addressLabel: '1 rue X',
    postcode: '22000',
    city: 'Saint-Brieuc',
    coordinates: const Coordinates(lat: 48, lon: -3),
    sheepCount: sheepCount,
    isWaiting: isWaiting,
    isBanned: isBanned,
  );
}

ClientStatus _derive(
  Client c, {
  bool planned = false,
  bool completed = false,
}) =>
    deriveStatus(
      c,
      hasPlannedTourThisSeason: planned,
      hasCompletedTourThisSeason: completed,
    );

void main() {
  group('deriveStatus priority', () {
    test('default when no flag and no tour', () {
      expect(_derive(_client()), ClientStatus.defaultStatus);
    });

    test('waiting flag → waiting', () {
      expect(_derive(_client(isWaiting: true)), ClientStatus.waiting);
    });

    test('planned tour beats waiting', () {
      expect(
        _derive(_client(isWaiting: true), planned: true),
        ClientStatus.scheduled,
      );
    });

    test('completed tour beats planned', () {
      expect(
        _derive(_client(isWaiting: true), planned: true, completed: true),
        ClientStatus.done,
      );
    });

    test('sheepCount=0 beats tour state', () {
      expect(
        _derive(_client(sheepCount: 0), planned: true, completed: true),
        ClientStatus.noSheep,
      );
    });

    test('banned beats everything', () {
      expect(
        _derive(
          _client(isBanned: true, sheepCount: 0, isWaiting: true),
          planned: true,
          completed: true,
        ),
        ClientStatus.banned,
      );
    });
  });
}
