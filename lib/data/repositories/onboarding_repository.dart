import 'package:shared_preferences/shared_preferences.dart';

abstract class OnboardingRepository {
  bool get hasCompletedCoreFlow;
  Future<void> completeCoreFlow();
  Future<void> resetCoreFlow();
}

class SharedPrefsOnboardingRepository implements OnboardingRepository {
  static const _coreFlowKey = 'onboarding.core_flow.completed.v1';

  final SharedPreferences _prefs;

  SharedPrefsOnboardingRepository(this._prefs);

  @override
  bool get hasCompletedCoreFlow => _prefs.getBool(_coreFlowKey) ?? false;

  @override
  Future<void> completeCoreFlow() => _prefs.setBool(_coreFlowKey, true);

  @override
  Future<void> resetCoreFlow() => _prefs.setBool(_coreFlowKey, false);
}
