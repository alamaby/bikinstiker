import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-side legal consent registry status for a single document.
class LegalConsentDoc {
  final String version;
  final String sha256;

  const LegalConsentDoc({required this.version, required this.sha256});

  factory LegalConsentDoc.fromJson(Map<String, dynamic>? json) {
    return LegalConsentDoc(
      version: json?['version'] as String? ?? '',
      sha256: json?['sha256'] as String? ?? '',
    );
  }
}

/// Authoritative consent status returned by Supabase RPCs.
class LegalConsentStatus {
  final LegalConsentDoc terms;
  final LegalConsentDoc privacy;
  final bool requiresAcceptance;

  const LegalConsentStatus({
    required this.terms,
    required this.privacy,
    required this.requiresAcceptance,
  });

  factory LegalConsentStatus.fromJson(Map<String, dynamic> json) {
    return LegalConsentStatus(
      terms: LegalConsentDoc.fromJson(json['terms'] as Map<String, dynamic>?),
      privacy:
          LegalConsentDoc.fromJson(json['privacy'] as Map<String, dynamic>?),
      requiresAcceptance: json['requiresAcceptance'] as bool? ?? true,
    );
  }
}

class LegalConsentStorageException implements Exception {
  final String message;
  const LegalConsentStorageException(this.message);
  @override
  String toString() => message;
}

/// Fetches/swrites legal acceptance exclusively through server-side
/// SECURITY DEFINER RPCs. Server timestamps are authoritative. The client
/// submits only current version + content-hash + app version.
class LegalConsentRepository {
  static const String currentTermsVersion = '2026-07-03';
  static const String currentPrivacyVersion = '2026-07-03';

  final SupabaseClient _client;

  LegalConsentRepository(this._client);

  /// Reads current consent status for an authenticated (inc. anonymous) user.
  Future<LegalConsentStatus> fetchStatus({required String locale}) async {
    try {
      final res = await _client.rpc(
        'get_legal_consent_status',
        params: {'p_locale': locale},
      );
      return LegalConsentStatus.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      throw LegalConsentStorageException(_describe(e));
    }
  }

  /// Records acceptance of the current Terms + Privacy bundle (append-only).
  Future<LegalConsentStatus> acceptCurrent({
    required String locale,
    required String termsVersion,
    required String termsSha256,
    required String privacyVersion,
    required String privacySha256,
    required String appVersion,
    required String clientRequestId,
  }) async {
    try {
      final res = await _client.rpc(
        'accept_current_legal_documents',
        params: {
          'p_locale': locale,
          'p_terms_version': termsVersion,
          'p_terms_sha256': termsSha256,
          'p_privacy_version': privacyVersion,
          'p_privacy_sha256': privacySha256,
          'p_app_version': appVersion,
          'p_client_request_id': clientRequestId,
        },
      );
      return LegalConsentStatus.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      throw LegalConsentStorageException(_describe(e));
    }
  }

  /// Records withdrawal of the current privacy consent (Terms unaffected).
  Future<LegalConsentStatus> withdrawPrivacy({
    required String locale,
    required String appVersion,
    required String clientRequestId,
  }) async {
    try {
      final res = await _client.rpc(
        'withdraw_current_privacy_consent',
        params: {
          'p_locale': locale,
          'p_app_version': appVersion,
          'p_client_request_id': clientRequestId,
        },
      );
      return LegalConsentStatus.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      throw LegalConsentStorageException(_describe(e));
    }
  }

  String _describe(Object e) {
    if (e is PostgrestException) return e.message;
    return e.toString();
  }
}