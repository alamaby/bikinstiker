import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';

sealed class SurpriseMeState extends Equatable {
  const SurpriseMeState();

  @override
  List<Object?> get props => [];
}

class SurpriseMeInitial extends SurpriseMeState {
  const SurpriseMeInitial();
}

class SurpriseMeLoading extends SurpriseMeState {
  const SurpriseMeLoading();
}

class SurpriseMeSuccess extends SurpriseMeState {
  final String prompt;
  final bool charged;
  final int balance;
  final int freeRemaining;

  const SurpriseMeSuccess({
    required this.prompt,
    required this.charged,
    required this.balance,
    required this.freeRemaining,
  });

  @override
  List<Object?> get props => [prompt, charged, balance, freeRemaining];
}

class SurpriseMeFailure extends SurpriseMeState {
  final Failure failure;

  const SurpriseMeFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
