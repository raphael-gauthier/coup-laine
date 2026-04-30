class AnimalCategory {
  final int id;
  final int speciesId;
  final String name;
  final int? defaultMinutes;
  final int? defaultPriceCents;
  final DateTime? archivedAt;

  const AnimalCategory({
    required this.id,
    required this.speciesId,
    required this.name,
    this.defaultMinutes,
    this.defaultPriceCents,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}
