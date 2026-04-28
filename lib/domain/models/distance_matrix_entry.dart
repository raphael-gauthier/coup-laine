class DistanceMatrixEntry {
  /// 0 = base, otherwise client.id
  final int fromId;
  final int toId;
  final int distanceMeters;
  final int durationSeconds;
  final DateTime computedAt;

  const DistanceMatrixEntry({
    required this.fromId,
    required this.toId,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.computedAt,
  });

  static const int baseId = 0;
}
