import 'package:bikin_stiker/core/di.dart';
import 'package:bikin_stiker/data/repositories/onboarding_repository.dart';
import 'package:bikin_stiker/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp(Widget screen) {
  return MaterialApp(home: screen);
}

Future<OnboardingRepository> _initRepo() async {
  final prefs = await SharedPreferences.getInstance();
  return SharedPrefsOnboardingRepository(prefs);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<OnboardingRepository>(
      SharedPrefsOnboardingRepository(prefs),
    );
  });

  tearDown(() {
    getIt.reset();
  });

  group('OnboardingScreen', () {
    testWidgets('shows first step with Next button', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingScreen()));

      expect(find.text('Create your sticker'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('navigates to second step on Next', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingScreen()));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Add it to a pack'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('navigates to third step on Next from step 2', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingScreen()));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Add your pack to WhatsApp'), findsOneWidget);
      expect(find.text('Create My First Sticker'), findsOneWidget);
    });

    testWidgets('Back returns to previous step', (tester) async {
      await tester.pumpWidget(_buildTestApp(const OnboardingScreen()));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Create your sticker'), findsOneWidget);
    });

    testWidgets('Skip completes core flow', (tester) async {
      bool completed = false;
      await tester.pumpWidget(_buildTestApp(
        OnboardingScreen(
          onFinished: () => completed = true,
        ),
      ));

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      final repo = await _initRepo();
      expect(repo.hasCompletedCoreFlow, isTrue);
      expect(completed, isTrue);
    });

    testWidgets('Create My First Sticker completes flow', (tester) async {
      bool completed = false;
      await tester.pumpWidget(_buildTestApp(
        OnboardingScreen(
          onFinished: () => completed = true,
        ),
      ));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create My First Sticker'));
      await tester.pumpAndSettle();

      final repo = await _initRepo();
      expect(repo.hasCompletedCoreFlow, isTrue);
      expect(completed, isTrue);
    });

    testWidgets('replay mode does not set completion', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const OnboardingScreen(replay: true),
      ));

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      final repo = await _initRepo();
      expect(repo.hasCompletedCoreFlow, isFalse);
    });
  });
}
