// lib/domain/models/client.dart
import 'animal_count.dart';
import 'coordinates.dart';

class Client {
  final int id;
  final String name;
  final List<String> phones;
  final String addressLabel;
  final String postcode;
  final String city;
  final Coordinates coordinates;
  final List<AnimalCount> animals;
  final String? markerColorHex;
  final bool isWaiting;
  final bool isBanned;
  final DateTime? lastInterventionDate;
  final bool needsDistanceRecompute;

  const Client({
    required this.id,
    required this.name,
    required this.addressLabel,
    required this.postcode,
    required this.city,
    required this.coordinates,
    this.animals = const [],
    this.phones = const [],
    this.markerColorHex,
    this.isWaiting = false,
    this.isBanned = false,
    this.lastInterventionDate,
    this.needsDistanceRecompute = false,
  });

  /// Total animal count across all categories. Used for the "no animals"
  /// status derivation and for compact list display.
  int get animalsTotal {
    var total = 0;
    for (final a in animals) {
      total += a.count;
    }
    return total;
  }

  String? get principalPhone => phones.isNotEmpty ? phones.first : null;
}
