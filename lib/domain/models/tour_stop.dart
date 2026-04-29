class TourStop {
  final int id;
  final int tourId;
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final int plannedSmall;
  final int plannedLarge;
  final int minutesPerSmallSnapshot;
  final int minutesPerLargeSnapshot;
  final int? actualSmall;
  final int? actualLarge;
  final String? interventionNote;
  final int feeShareCents;

  const TourStop({
    required this.id,
    required this.tourId,
    required this.clientNameSnapshot,
    required this.orderIndex,
    required this.estimatedArrivalMinutes,
    required this.estimatedDepartureMinutes,
    required this.plannedSmall,
    required this.plannedLarge,
    required this.minutesPerSmallSnapshot,
    required this.minutesPerLargeSnapshot,
    required this.feeShareCents,
    this.clientId,
    this.actualSmall,
    this.actualLarge,
    this.interventionNote,
  });
}
