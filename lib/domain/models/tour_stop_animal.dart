class TourStopAnimal {
  final int categoryId;
  final int count;
  final String categoryNameSnapshot;
  final String speciesNameSnapshot;
  final int minutesSnapshot;

  const TourStopAnimal({
    required this.categoryId,
    required this.count,
    required this.categoryNameSnapshot,
    required this.speciesNameSnapshot,
    required this.minutesSnapshot,
  });

  @override
  bool operator ==(Object other) =>
      other is TourStopAnimal &&
      other.categoryId == categoryId &&
      other.count == count &&
      other.categoryNameSnapshot == categoryNameSnapshot &&
      other.speciesNameSnapshot == speciesNameSnapshot &&
      other.minutesSnapshot == minutesSnapshot;

  @override
  int get hashCode => Object.hash(
        categoryId,
        count,
        categoryNameSnapshot,
        speciesNameSnapshot,
        minutesSnapshot,
      );
}
