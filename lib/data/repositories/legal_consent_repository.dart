import 'package:shared_preferences/shared_preferences.dart';

class LegalConsentRepository {
  static const String _termsKey = 'legal_terms_version';
  static const String _privacyKey = 'legal_privacy_version';
  static const String _acceptedAtKey = 'legal_accepted_at';

  final SharedPreferences _prefs;

  LegalConsentRepository(this._prefs);

  String get termsVersion => _prefs.getString(_termsKey) ?? '';
  String get privacyVersion => _prefs.getString(_privacyKey) ?? '';
  DateTime? get acceptedAt {
    final ts = _prefs.getString(_acceptedAtKey);
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  bool get hasAcceptedCurrent {
    const currentTerms = '2026-06-27';
    const currentPrivacy = '2026-06-27';
    return termsVersion == currentTerms && privacyVersion == currentPrivacy;
  }

  Future<void> accept({
    required String termsVersion,
    required String privacyVersion,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _prefs.setString(_termsKey, termsVersion);
    await _prefs.setString(_privacyKey, privacyVersion);
    await _prefs.setString(_acceptedAtKey, now);
  }

  Future<void> clear() async {
    await _prefs.remove(_termsKey);
    await _prefs.remove(_privacyKey);
    await _prefs.remove(_acceptedAtKey);
  }
}
