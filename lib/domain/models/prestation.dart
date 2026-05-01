class Prestation {
  final int id;
  final String name;
  final int? priceCents;
  final int? minutes;
  final int? categoryId;
  final DateTime? archivedAt;

  const Prestation({
    required this.id,
    required this.name,
    this.priceCents,
    this.minutes,
    this.categoryId,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}
