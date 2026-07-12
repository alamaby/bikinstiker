import 'package:bikin_stiker/data/repositories/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPrefsOnboardingRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = SharedPrefsOnboardingRepository(prefs);
  });

  group('initial state', () {
    test('hasCompletedCoreFlow returns false by default', () {
      expect(repo.hasCompletedCoreFlow, isFalse);
    });
  });

  group('completeCoreFlow', () {
    test('sets completion to true', () async {
      await repo.completeCoreFlow();
      expect(repo.hasCompletedCoreFlow, isTrue);
    });

    test('persists across repo instances', () async {
      await repo.completeCoreFlow();

      final prefs2 = await SharedPreferences.getInstance();
      final repo2 = SharedPrefsOnboardingRepository(prefs2);
      expect(repo2.hasCompletedCoreFlow, isTrue);
    });
  });

  group('resetCoreFlow', () {
    test('resets completion to false', () async {
      await repo.completeCoreFlow();
      expect(repo.hasCompletedCoreFlow, isTrue);

      await repo.resetCoreFlow();
      expect(repo.hasCompletedCoreFlow, isFalse);
    });
  });
}
