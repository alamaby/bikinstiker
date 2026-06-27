import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class InsufficientCreditsFailure extends Failure {
  const InsufficientCreditsFailure() : super('Insufficient credits');
}

class GenerationFailure extends Failure {
  const GenerationFailure(super.message);
}

class RateLimitedFailure extends Failure {
  final int retryAfterSeconds;
  const RateLimitedFailure(this.retryAfterSeconds)
    : super('Too many requests. Please wait before generating again.');
  @override
  List<Object?> get props => [message, retryAfterSeconds];
}

class GenerationInProgressFailure extends Failure {
  final int? retryAfterSeconds;
  const GenerationInProgressFailure({this.retryAfterSeconds})
    : super('A sticker generation is already in progress.');
  @override
  List<Object?> get props => [message, retryAfterSeconds];
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
