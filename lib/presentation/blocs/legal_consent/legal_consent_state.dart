import 'package:equatable/equatable.dart';

import '../../../data/repositories/legal_consent_repository.dart';

/// Server-side legal consent evaluation as surfaced to the UI.
enum LegalConsentPhase { loading, ready, error }

class LegalConsentState extends Equatable {
  final LegalConsentPhase phase;
  final LegalConsentStatus? status;
  final String? errorMessage;
  final bool submitting;

  const LegalConsentState({
    this.phase = LegalConsentPhase.loading,
    this.status,
    this.errorMessage,
    this.submitting = false,
  });

  bool get isAccepted => status?.requiresAcceptance == false;

  const LegalConsentState.loading()
      : this(phase: LegalConsentPhase.loading);

  LegalConsentState copyWith({
    LegalConsentPhase? phase,
    LegalConsentStatus? status,
    Object? errorMessage = _undefined,
    bool? submitting,
  }) {
    return LegalConsentState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
      submitting: submitting ?? this.submitting,
    );
  }

  static const Object _undefined = Object();

  @override
  List<Object?> get props => [phase, status, errorMessage, submitting];
}