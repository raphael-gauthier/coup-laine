String formatHm(int minutesSinceMidnight) {
  final h = (minutesSinceMidnight ~/ 60).toString().padLeft(2, '0');
  final m = (minutesSinceMidnight % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String formatDuration(int totalMinutes) {
  if (totalMinutes < 60) return '$totalMinutes min';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return m == 0 ? '${h}h' : '${h}h$m';
}

String formatEuros(int cents) {
  final euros = cents ~/ 100;
  final c = (cents % 100).toString().padLeft(2, '0');
  return '$euros,$c €';
}
