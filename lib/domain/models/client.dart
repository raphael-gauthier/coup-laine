import 'coordinates.dart';

class Client {
  final int id;
  final String name;
  final List<String> phones;
  final String addressLabel;
  final String postcode;
  final String city;
  final Coordinates coordinates;
  final int sheepCountSmall;
  final int sheepCountLarge;
  final String? markerColorHex;
  final bool isWaiting;
  final bool isBanned;
  final DateTime? lastShearingDate;
  final bool needsDistanceRecompute;

  const Client({
    required this.id,
    required this.name,
    required this.addressLabel,
    required this.postcode,
    required this.city,
    required this.coordinates,
    this.sheepCountSmall = 0,
    this.sheepCountLarge = 0,
    this.phones = const [],
    this.markerColorHex,
    this.isWaiting = false,
    this.isBanned = false,
    this.lastShearingDate,
    this.needsDistanceRecompute = false,
  });

  int get sheepCountTotal => sheepCountSmall + sheepCountLarge;

  /// First entry of [phones], or null if the list is empty. Used as the
  /// default phone for call/SMS actions on surfaces that show a single
  /// action button (e.g. the map popup).
  String? get principalPhone => phones.isNotEmpty ? phones.first : null;
}
