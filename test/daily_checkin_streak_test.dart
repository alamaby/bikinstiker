import 'package:bikin_stiker/data/models/daily_checkin_streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyCheckinStreak.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'current_streak': 3,
        'current_cycle_day': 4,
        'last_checked_on': '2026-07-04T10:00:00Z',
        'cycle_completed_at': '2026-07-03T10:00:00Z',
        'checked_in_today': true,
      };
      final streak = DailyCheckinStreak.fromJson(json);

      expect(streak.currentStreak, 3);
      expect(streak.currentCycleDay, 4);
      expect(streak.lastCheckedOn, isNotNull);
      expect(streak.lastCheckedOn!.day, 4);
      expect(streak.cycleCompletedAt, isNotNull);
      expect(streak.checkedInToday, isTrue);
    });

    test('defaults to zeros when fields are null', () {
      final json = {
        'current_streak': null,
        'current_cycle_day': null,
        'last_checked_on': null,
        'cycle_completed_at': null,
        'checked_in_today': null,
      };
      final streak = DailyCheckinStreak.fromJson(json);

      expect(streak.currentStreak, 0);
      expect(streak.currentCycleDay, 0);
      expect(streak.lastCheckedOn, isNull);
      expect(streak.cycleCompletedAt, isNull);
      expect(streak.checkedInToday, isFalse);
    });
  });

  group('DailyCheckinStreak.empty', () {
    test('creates streak with zero values', () {
      final streak = DailyCheckinStreak.empty();

      expect(streak.currentStreak, 0);
      expect(streak.currentCycleDay, 0);
      expect(streak.checkedInToday, isFalse);
      expect(streak.lastCheckedOn, isNull);
      expect(streak.cycleCompletedAt, isNull);
    });
  });

  group('DailyCheckinStreak.cycleCompleted', () {
    test('true when cycleCompletedAt is set', () {
      final streak = DailyCheckinStreak.fromJson({
        'current_streak': 7,
        'current_cycle_day': 7,
        'last_checked_on': '2026-07-04T10:00:00Z',
        'cycle_completed_at': '2026-07-04T10:00:00Z',
        'checked_in_today': true,
      });
      expect(streak.cycleCompleted, isTrue);
    });

    test('false when cycleCompletedAt is null', () {
      final streak = DailyCheckinStreak.fromJson({
        'current_streak': 3,
        'current_cycle_day': 3,
        'last_checked_on': '2026-07-04T10:00:00Z',
        'cycle_completed_at': null,
        'checked_in_today': true,
      });
      expect(streak.cycleCompleted, isFalse);
    });
  });

  group('DailyCheckinStreak.canClaim', () {
    test('true when checkedInToday is false', () {
      final streak = DailyCheckinStreak.fromJson({
        'current_streak': 3,
        'current_cycle_day': 4,
        'last_checked_on': '2026-07-03T10:00:00Z',
        'cycle_completed_at': null,
        'checked_in_today': false,
      });
      expect(streak.canClaim, isTrue);
    });

    test('false when checkedInToday is true', () {
      final streak = DailyCheckinStreak.fromJson({
        'current_streak': 3,
        'current_cycle_day': 4,
        'last_checked_on': '2026-07-04T10:00:00Z',
        'cycle_completed_at': null,
        'checked_in_today': true,
      });
      expect(streak.canClaim, isFalse);
    });
  });

  group('DailyCheckinClaimResult.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'credits_awarded': 2,
        'new_streak': 4,
        'new_cycle_day': 5,
        'cycle_completed': false,
        'total_weekly': 8,
      };
      final result = DailyCheckinClaimResult.fromJson(json);

      expect(result.creditsAwarded, 2);
      expect(result.newStreak, 4);
      expect(result.newCycleDay, 5);
      expect(result.cycleCompleted, isFalse);
      expect(result.totalWeekly, 8);
    });

    test('parses cycleCompleted as true when applicable', () {
      final json = {
        'credits_awarded': 5,
        'new_streak': 7,
        'new_cycle_day': 7,
        'cycle_completed': true,
        'total_weekly': 14,
      };
      final result = DailyCheckinClaimResult.fromJson(json);

      expect(result.cycleCompleted, isTrue);
      expect(result.creditsAwarded, 5);
    });
  });
}
