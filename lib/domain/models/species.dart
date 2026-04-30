class Species {
  final int id;
  final String name;
  final String? iconKey;
  final DateTime? archivedAt;

  const Species({
    required this.id,
    required this.name,
    this.iconKey,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}
