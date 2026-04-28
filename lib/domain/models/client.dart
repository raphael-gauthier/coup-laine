import 'coordinates.dart';
import 'settings.dart';

class Client {
  final int id;
  final String name;
  final String? phone;
  final String addressLabel;
  final String postcode;
  final String city;
  final Coordinates coordinates;
  final int sheepCount;
  final int? minutesPerSheepOverride;
  final String? notes;
  final String? markerColorHex;
  final bool isWaiting;
  final DateTime? lastShearingDate;
  final bool needsDistanceRecompute;

  const Client({
    required this.id,
    required this.name,
    required this.addressLabel,
    required this.postcode,
    required this.city,
    required this.coordinates,
    this.sheepCount = 0,
    this.phone,
    this.minutesPerSheepOverride,
    this.notes,
    this.markerColorHex,
    this.isWaiting = false,
    this.lastShearingDate,
    this.needsDistanceRecompute = false,
  });

  int minutesPerSheep(Settings settings) =>
      minutesPerSheepOverride ?? settings.defaultMinutesPerSheep;
}
