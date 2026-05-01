class TourStopPrestation {
  final int prestationId;
  final int qty;
  final String nameSnapshot;
  final int priceCentsSnapshot;
  final int minutesSnapshot;
  final int? categoryIdSnapshot;
  final String? categoryNameSnapshot;
  final String? speciesNameSnapshot;

  const TourStopPrestation({
    required this.prestationId,
    required this.qty,
    required this.nameSnapshot,
    required this.priceCentsSnapshot,
    required this.minutesSnapshot,
    this.categoryIdSnapshot,
    this.categoryNameSnapshot,
    this.speciesNameSnapshot,
  });

  @override
  bool operator ==(Object other) =>
      other is TourStopPrestation &&
      other.prestationId == prestationId &&
      other.qty == qty &&
      other.nameSnapshot == nameSnapshot &&
      other.priceCentsSnapshot == priceCentsSnapshot &&
      other.minutesSnapshot == minutesSnapshot &&
      other.categoryIdSnapshot == categoryIdSnapshot &&
      other.categoryNameSnapshot == categoryNameSnapshot &&
      other.speciesNameSnapshot == speciesNameSnapshot;

  @override
  int get hashCode => Object.hash(
        prestationId,
        qty,
        nameSnapshot,
        priceCentsSnapshot,
        minutesSnapshot,
        categoryIdSnapshot,
        categoryNameSnapshot,
        speciesNameSnapshot,
      );
}
