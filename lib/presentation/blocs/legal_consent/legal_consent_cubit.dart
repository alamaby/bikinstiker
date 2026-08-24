import 'dart:convert';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:crypto/crypto.dart';

import '../../../core/app_version.dart';
import '../../../data/repositories/legal_consent_repository.dart';
import 'legal_consent_state.dart';

class LegalConsentCubit extends Cubit<LegalConsentState> {
  final LegalConsentRepository _repo;
  static final Random _rand = Random.secure();
  String _guardKey = '';
  String? _pendingRequestId;

  LegalConsentCubit(this._repo)
      : super(const LegalConsentState.loading());

  /// RFC-4122 v4 UUID used as an idempotency key for retries.
  static String newRequestId() {
    final b = List<int>.generate(16, (_) => _rand.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    const hex = '0123456789abcdef';
    final sb = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) sb.write('-');
      sb
        ..write(hex[(b[i] >> 4) & 0x0f])
        ..write(hex[b[i] & 0x0f]);
    }
    return sb.toString();
  }

  /// UTF-8 SHA-256 hex string of a document asset.
  static String sha256HexUtf8(String source) =>
      sha256.convert(utf8.encode(source)).toString();

  /// Run one status check. Guarded to trigger at most once per (user, locale).
  /// A prior error lifts the guard so retry can re-run the check.
  Future<void> check({required String userId, required String locale}) async {
    final key = '$userId|$locale';
    if (key == _guardKey && state.phase != LegalConsentPhase.error) return;
    _guardKey = key;
    await _fetchStatus(locale);
  }

  Future<void> retry({required String userId, required String locale}) =>
      check(userId: userId, locale: locale);

  Future<void> _fetchStatus(String locale) async {
    emit(const LegalConsentState.loading());
    try {
      final s = await _repo.fetchStatus(locale: locale);
      emit(LegalConsentState(phase: LegalConsentPhase.ready, status: s));
    } on Exception catch (e) {
      emit(LegalConsentState(
        phase: LegalConsentPhase.error,
        errorMessage: _message(e),
      ));
    }
  }

  /// Records bundle acceptance (idempotent request id reused on retry).
  Future<void> accept({
    required String userId,
    required String locale,
    required LegalConsentStatus status,
    required String termsSha256,
    required String privacySha256,
  }) async {
    final requestId = _pendingRequestId ??= newRequestId();
    emit(state.copyWith(submitting: true));
    try {
      final s = await _repo.acceptCurrent(
        locale: locale,
        termsVersion: status.terms.version,
        termsSha256: termsSha256,
        privacyVersion: status.privacy.version,
        privacySha256: privacySha256,
        appVersion: AppBuildInfo.version,
        clientRequestId: requestId,
      );
      _pendingRequestId = null;
      emit(LegalConsentState(phase: LegalConsentPhase.ready, status: s));
    } on Exception catch (e) {
      emit(LegalConsentState(
        phase: LegalConsentPhase.error,
        errorMessage: _message(e),
      ));
    }
  }

  Future<void> withdrawPrivacy({
    required String userId,
    required String locale,
  }) async {
    final requestId = _pendingRequestId ??= newRequestId();
    emit(state.copyWith(submitting: true));
    try {
      final s = await _repo.withdrawPrivacy(
        locale: locale,
        appVersion: AppBuildInfo.version,
        clientRequestId: requestId,
      );
      _pendingRequestId = null;
      emit(LegalConsentState(phase: LegalConsentPhase.ready, status: s));
    } on Exception catch (e) {
      emit(state.copyWith(
        phase: LegalConsentPhase.error,
        errorMessage: _message(e),
      ));
    }
  }

  String _message(Exception e) =>
      e is LegalConsentStorageException ? e.message : e.toString();
}