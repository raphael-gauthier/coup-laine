import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/use_cases/client_status.dart';
import 'package:flutter_test/flutter_test.dart';

Client _client({
  bool isWaiting = false,
  bool isBanned = false,
  List<AnimalCount> animals = const [AnimalCount(categoryId: 1, count: 5)],
}) {
  return Client(
    id: 1,
    name: 'X',
    addressLabel: '1 rue X',
    postcode: '22000',
    city: 'Saint-Brieuc',
    coordinates: const Coordinates(lat: 48, lon: -3),
    animals: animals,
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

    test('animals empty → noAnimals', () {
      expect(
        _derive(
          _client(animals: const []),
          planned: true,
          completed: true,
        ),
        ClientStatus.noAnimals,
      );
    });

    test('animalsTotal > 0 → NOT noAnimals', () {
      // Any non-zero total keeps the client active.
      expect(
        _derive(_client(animals: const [AnimalCount(categoryId: 1, count: 3)])),
        ClientStatus.defaultStatus,
      );
    });

    test('banned beats everything', () {
      expect(
        _derive(
          _client(
            isBanned: true,
            animals: const [],
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
