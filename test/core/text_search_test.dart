import 'package:coup_laine/core/text_search.dart';
import 'package:coup_laine/domain/models/client.dart';
import 'package:coup_laine/domain/models/coordinates.dart';
import 'package:flutter_test/flutter_test.dart';

Client _client({
  String name = 'Le Gall',
  List<String> phones = const [],
  String city = 'Quimper',
  String postcode = '29000',
  String addressLabel = '1 rue Test, 29000 Quimper',
}) {
  return Client(
    id: 1,
    name: name,
    addressLabel: addressLabel,
    postcode: postcode,
    city: city,
    coordinates: const Coordinates(lat: 48.0, lon: -4.1),
    phones: phones,
  );
}

void main() {
  group('matchesClient — phones list', () {
    test('matches the principal number', () {
      final c = _client(phones: const ['0612', '0145']);
      expect(matchesClient(c, normalize('0612')), isTrue);
    });

    test('matches a non-principal number', () {
      final c = _client(phones: const ['0612', '0145']);
      expect(matchesClient(c, normalize('0145')), isTrue);
    });

    test('does not match a number that is not in the list', () {
      final c = _client(phones: const ['0612']);
      expect(matchesClient(c, normalize('0788')), isFalse);
    });

    test('a client with empty phones still matches by name', () {
      final c = _client(name: 'Le Gall', phones: const []);
      expect(matchesClient(c, normalize('gall')), isTrue);
    });
  });
}
