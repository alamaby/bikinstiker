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

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
