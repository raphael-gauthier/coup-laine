class ManualHistoryEntry {
  final int id;
  final int clientId;
  final DateTime date;
  final int small;
  final int large;
  final String? note;

  const ManualHistoryEntry({
    required this.id,
    required this.clientId,
    required this.date,
    required this.small,
    required this.large,
    this.note,
  });

  int get total => small + large;
}
