class TourStop {
  final int id;
  final int tourId;
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final int sheepCountSnapshot;
  final int minutesPerSheepSnapshot;
  final int feeShareCents;

  const TourStop({
    required this.id,
    required this.tourId,
    required this.clientNameSnapshot,
    required this.orderIndex,
    required this.estimatedArrivalMinutes,
    required this.estimatedDepartureMinutes,
    required this.sheepCountSnapshot,
    required this.minutesPerSheepSnapshot,
    required this.feeShareCents,
    this.clientId,
  });
}
