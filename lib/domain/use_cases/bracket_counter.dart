class BracketCounter {
  final int bracketKm;
  final int feeEurosPerBracket;

  const BracketCounter({
    required this.bracketKm,
    required this.feeEurosPerBracket,
  });

  int bracketsFor(int distanceMeters) {
    if (distanceMeters <= 0) return 0;
    final bracketMeters = bracketKm * 1000;
    return ((distanceMeters + bracketMeters - 1) ~/ bracketMeters);
  }

  int feeCentsFor(int distanceMeters) =>
      bracketsFor(distanceMeters) * feeEurosPerBracket * 100;
}
