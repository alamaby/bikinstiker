class DailyCheckinStreak {
  final int currentStreak;
  final int currentCycleDay;
  final DateTime? lastCheckedOn;
  final DateTime? cycleCompletedAt;
  final bool checkedInToday;

  const DailyCheckinStreak({
    required this.currentStreak,
    required this.currentCycleDay,
    this.lastCheckedOn,
    this.cycleCompletedAt,
    required this.checkedInToday,
  });

  bool get cycleCompleted => cycleCompletedAt != null;

  /// Whether the user can claim today (not yet checked in and not in cooldown).
  bool get canClaim => !checkedInToday;

  factory DailyCheckinStreak.fromJson(Map<String, dynamic> json) {
    return DailyCheckinStreak(
      currentStreak: json['current_streak'] as int? ?? 0,
      currentCycleDay: json['current_cycle_day'] as int? ?? 0,
      lastCheckedOn: json['last_checked_on'] != null
          ? DateTime.parse(json['last_checked_on'] as String)
          : null,
      cycleCompletedAt: json['cycle_completed_at'] != null
          ? DateTime.parse(json['cycle_completed_at'] as String)
          : null,
      checkedInToday: json['checked_in_today'] as bool? ?? false,
    );
  }

  /// No streak yet (first visit).
  factory DailyCheckinStreak.empty() => const DailyCheckinStreak(
    currentStreak: 0,
    currentCycleDay: 0,
    checkedInToday: false,
  );
}

class DailyCheckinClaimResult {
  final int creditsAwarded;
  final int newStreak;
  final int newCycleDay;
  final bool cycleCompleted;
  final int totalWeekly;

  const DailyCheckinClaimResult({
    required this.creditsAwarded,
    required this.newStreak,
    required this.newCycleDay,
    required this.cycleCompleted,
    required this.totalWeekly,
  });

  factory DailyCheckinClaimResult.fromJson(Map<String, dynamic> json) {
    return DailyCheckinClaimResult(
      creditsAwarded: json['credits_awarded'] as int,
      newStreak: json['new_streak'] as int,
      newCycleDay: json['new_cycle_day'] as int,
      cycleCompleted: json['cycle_completed'] as bool,
      totalWeekly: json['total_weekly'] as int,
    );
  }
}
