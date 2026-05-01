class AnimalCategory {
  final int id;
  final int speciesId;
  final String name;
  final DateTime? archivedAt;

  const AnimalCategory({
    required this.id,
    required this.speciesId,
    required this.name,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}
