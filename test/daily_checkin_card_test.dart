import 'package:bikin_stiker/data/models/daily_checkin_streak.dart';
import 'package:bikin_stiker/data/models/mission.dart';
import 'package:bikin_stiker/data/models/user_subscription.dart';
import 'package:bikin_stiker/l10n/app_localizations.dart';
import 'package:bikin_stiker/presentation/screens/missions/widgets/daily_checkin_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildCard({
  required DailyCheckinStreak streak,
  int? justClaimedDay,
}) {
  return MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: DailyCheckinCard(
        mission: Mission(
          id: 'test-daily',
          code: 'daily_login',
          label: 'Daily check-in',
          description: 'Check in daily',
          rewardCredits: 1,
          requiredTier: SubscriptionTier.free,
          sortOrder: 1,
        ),
        userTier: SubscriptionTier.free,
        streak: streak,
        justClaimedDay: justClaimedDay,
      ),
    ),
  );
}

void main() {
  group('DailyCheckinCard renders day boxes', () {
    testWidgets('all 7 day numbers visible when no streak', (tester) async {
      await tester.pumpWidget(
        buildCard(streak: DailyCheckinStreak.empty()),
      );
      await tester.pumpAndSettle();

      for (int day = 1; day <= 7; day++) {
        expect(
          find.text('$day'),
          findsOneWidget,
          reason: 'Day $day number should be visible',
        );
      }
    });

    testWidgets(
      'day 1 shows checkmark after checking in today',
      (tester) async {
        await tester.pumpWidget(
          buildCard(
            streak: DailyCheckinStreak.fromJson({
              'current_streak': 1,
              'current_cycle_day': 1,
              'last_checked_on': '2026-07-14T10:00:00Z',
              'cycle_completed_at': null,
              'checked_in_today': true,
            }),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('✅'),
          findsOneWidget,
          reason: 'Checkmark emoji should show on checked-in day',
        );
      },
    );

    testWidgets(
      'day 1 shows themed marker when not checked in yet',
      (tester) async {
        await tester.pumpWidget(
          buildCard(
            streak: DailyCheckinStreak.fromJson({
              'current_streak': 1,
              'current_cycle_day': 1,
              'last_checked_on': '2026-07-13T10:00:00Z',
              'cycle_completed_at': null,
              'checked_in_today': false,
            }),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('✅'),
          findsNothing,
          reason: 'No checkmark when not checked in today',
        );
        // should show themed marker emoji for day 1: sunrise \u{1F305}
        expect(
          find.text('\u{1F305}'),
          findsOneWidget,
          reason: 'Day 1 should show sunrise emoji when not completed',
        );
      },
    );

    testWidgets(
      'shows "Cycle complete!" text when cooldown active',
      (tester) async {
        await tester.pumpWidget(
          buildCard(
            streak: DailyCheckinStreak.fromJson({
              'current_streak': 7,
              'current_cycle_day': 7,
              'last_checked_on': '2026-07-14T10:00:00Z',
              'cycle_completed_at': '2026-07-14T10:00:00Z',
              'checked_in_today': true,
              'cycle_cooldown_finished': false,
              'cooldown_remaining_seconds': 5000,
            }),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Cycle complete!'),
          findsOneWidget,
          reason: 'Cycle complete text should show during cooldown',
        );
        expect(
          find.textContaining('Next in'),
          findsOneWidget,
          reason: 'Countdown text should show during cooldown',
        );
      },
    );

    testWidgets(
      'shows "Start new cycle" button after cooldown',
      (tester) async {
        await tester.pumpWidget(
          buildCard(
            streak: DailyCheckinStreak.fromJson({
              'current_streak': 7,
              'current_cycle_day': 7,
              'last_checked_on': '2026-07-12T10:00:00Z',
              'cycle_completed_at': '2026-07-12T10:00:00Z',
              'checked_in_today': false,
              'cycle_cooldown_finished': true,
              'cooldown_remaining_seconds': 0,
            }),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Start new cycle'),
          findsOneWidget,
          reason: 'Start new cycle button should appear after cooldown',
        );
      },
    );

    testWidgets(
      'all 7 days show checkmark when cycle completed',
      (tester) async {
        await tester.pumpWidget(
          buildCard(
            streak: DailyCheckinStreak.fromJson({
              'current_streak': 7,
              'current_cycle_day': 7,
              'last_checked_on': '2026-07-12T10:00:00Z',
              'cycle_completed_at': '2026-07-12T10:00:00Z',
              'checked_in_today': true,
              'cycle_cooldown_finished': false,
              'cooldown_remaining_seconds': 5000,
            }),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Cycle complete!'),
          findsOneWidget,
          reason: 'Cycle complete should show',
        );
      },
    );
  });
}
