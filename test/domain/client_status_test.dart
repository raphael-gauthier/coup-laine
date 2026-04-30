import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/use_cases/client_status.dart';
import 'package:flutter_test/flutter_test.dart';

Client _client({
  bool isWaiting = false,
  bool isBanned = false,
  int sheepCountSmall = 5,
  int sheepCountLarge = 0,
}) {
  return Client(
    id: 1,
    name: 'X',
    addressLabel: '1 rue X',
    postcode: '22000',
    city: 'Saint-Brieuc',
    coordinates: const Coordinates(lat: 48, lon: -3),
    sheepCountSmall: sheepCountSmall,
    sheepCountLarge: sheepCountLarge,
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

    test('planned tour beats completed (scheduled surfaces upcoming work)',
        () {
      expect(
        _derive(_client(isWaiting: true), planned: true, completed: true),
        ClientStatus.scheduled,
      );
    });

    test('completed tour without planned → done', () {
      expect(
        _derive(_client(), completed: true),
        ClientStatus.done,
      );
    });

    test('both counts at 0 → noSheep', () {
      expect(
        _derive(
          _client(sheepCountSmall: 0, sheepCountLarge: 0),
          planned: true,
          completed: true,
        ),
        ClientStatus.noSheep,
      );
    });

    test('only large at 0 (small > 0) → NOT noSheep', () {
      // The small flock is enough to keep the client active.
      expect(
        _derive(_client(sheepCountSmall: 3, sheepCountLarge: 0)),
        ClientStatus.defaultStatus,
      );
    });

    test('only small at 0 (large > 0) → NOT noSheep', () {
      expect(
        _derive(_client(sheepCountSmall: 0, sheepCountLarge: 2)),
        ClientStatus.defaultStatus,
      );
    });

    test('banned beats everything', () {
      expect(
        _derive(
          _client(
            isBanned: true,
            sheepCountSmall: 0,
            sheepCountLarge: 0,
            isWaiting: true,
          ),
          planned: true,
          completed: true,
        ),
        ClientStatus.banned,
      );
    });
  });
}
