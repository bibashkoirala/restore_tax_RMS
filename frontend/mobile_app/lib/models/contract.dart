class Contract {
  const Contract({
    required this.id,
    required this.baseRent,
    required this.startedAt,
    required this.endsAt,
    required this.incrementPercentPerYear,
  });

  final String id;
  final double baseRent;
  final DateTime startedAt;
  final DateTime endsAt;
  final double incrementPercentPerYear;

  double rentForDate(DateTime date) {
    final yearDiff = date.year - startedAt.year;
    final factor = 1 + ((incrementPercentPerYear / 100) * yearDiff);
    return baseRent * factor;
  }
}
