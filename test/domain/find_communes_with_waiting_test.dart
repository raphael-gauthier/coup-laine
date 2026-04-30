import 'package:coup_laine/domain/models/animal_count.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:coup_laine/domain/use_cases/client_status.dart';
import 'package:coup_laine/domain/use_cases/find_communes_with_waiting.dart';
import 'package:flutter_test/flutter_test.dart';

Client _c(int id, String city, {bool needsRecompute = false}) => Client(
      id: id,
      name: 'C$id',
      addressLabel: 'a',
      postcode: '00000',
      city: city,
      coordinates: const Coordinates(lat: 48, lon: -3),
      animals: const [AnimalCount(categoryId: 1, count: 5)],
      isWaiting: true,
      needsDistanceRecompute: needsRecompute,
    );

void main() {
  test('groups waiting clients by city and sorts alphabetically', () {
    final clients = [
      _c(1, 'Quimper'),
      _c(2, 'Carhaix'),
      _c(3, 'Quimper'),
      _c(4, 'Brest'),
    ];
    final statuses = {
      1: ClientStatus.waiting,
      2: ClientStatus.waiting,
      3: ClientStatus.waiting,
      4: ClientStatus.waiting,
    };
    final result = const FindCommunesWithWaiting().call(
      clients: clients,
      statusByClientId: statuses,
    );
    expect(result.map((e) => e.name), ['Brest', 'Carhaix', 'Quimper']);
    expect(result.map((e) => e.count), [1, 1, 2]);
  });

  test('excludes non-waiting clients', () {
    final clients = [_c(1, 'Quimper'), _c(2, 'Quimper')];
    final statuses = {
      1: ClientStatus.waiting,
      2: ClientStatus.scheduled,
    };
    final result = const FindCommunesWithWaiting().call(
      clients: clients,
      statusByClientId: statuses,
    );
    expect(result, [(name: 'Quimper', count: 1)]);
  });

  test('excludes clients with needsDistanceRecompute', () {
    final clients = [
      _c(1, 'Quimper'),
      _c(2, 'Quimper', needsRecompute: true),
    ];
    final statuses = {
      1: ClientStatus.waiting,
      2: ClientStatus.waiting,
    };
    final result = const FindCommunesWithWaiting().call(
      clients: clients,
      statusByClientId: statuses,
    );
    expect(result, [(name: 'Quimper', count: 1)]);
  });

  test('omits communes whose only client was filtered out', () {
    final clients = [_c(1, 'Carhaix', needsRecompute: true)];
    final statuses = {1: ClientStatus.waiting};
    final result = const FindCommunesWithWaiting().call(
      clients: clients,
      statusByClientId: statuses,
    );
    expect(result, isEmpty);
  });
}
