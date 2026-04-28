class Coordinates {
  final double lat;
  final double lon;

  const Coordinates({required this.lat, required this.lon})
      : assert(lat >= -90 && lat <= 90, 'lat out of range'),
        assert(lon >= -180 && lon <= 180, 'lon out of range');

  factory Coordinates.checked({required double lat, required double lon}) {
    if (lat < -90 || lat > 90) {
      throw ArgumentError.value(lat, 'lat', 'must be in [-90, 90]');
    }
    if (lon < -180 || lon > 180) {
      throw ArgumentError.value(lon, 'lon', 'must be in [-180, 180]');
    }
    return Coordinates(lat: lat, lon: lon);
  }

  @override
  bool operator ==(Object other) =>
      other is Coordinates && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);

  @override
  String toString() => 'Coordinates($lat, $lon)';
}
