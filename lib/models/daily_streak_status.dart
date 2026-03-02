class DailyStreakStatus {
  final int streakDays;
  final bool hasAnsweredToday;
  final DateTime? lastAnsweredDate;

  const DailyStreakStatus({
    required this.streakDays,
    required this.hasAnsweredToday,
    required this.lastAnsweredDate,
  });
}
