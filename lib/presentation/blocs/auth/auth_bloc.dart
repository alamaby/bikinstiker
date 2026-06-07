import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../data/repositories/auth_repository.dart';

// ----------------- Events -----------------
sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignUpRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class _AuthUserChanged extends AuthEvent {
  final User? user;
  const _AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user?.id];
}

// ----------------- State -----------------
enum AuthStatus { unknown, authenticated, unauthenticated, submitting }

class AuthBlocState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? infoMessage;

  const AuthBlocState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.infoMessage,
  });

  // Sentinel for copyWith: omit a parameter to keep the current value,
  // pass an explicit value (including null) to overwrite it.
  static const Object _undefined = Object();

  AuthBlocState copyWith({
    AuthStatus? status,
    Object? user = _undefined,
    Object? errorMessage = _undefined,
    Object? infoMessage = _undefined,
  }) =>
      AuthBlocState(
        status: status ?? this.status,
        user: identical(user, _undefined) ? this.user : user as User?,
        errorMessage: identical(errorMessage, _undefined)
            ? this.errorMessage
            : errorMessage as String?,
        infoMessage: identical(infoMessage, _undefined)
            ? this.infoMessage
            : infoMessage as String?,
      );

  @override
  List<Object?> get props => [status, user?.id, errorMessage, infoMessage];
}

// ----------------- Bloc -----------------
class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  final AuthRepository _repo;
  StreamSubscription<AuthState>? _sub;

  AuthBloc(this._repo) : super(const AuthBlocState()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
    on<_AuthUserChanged>(_onUserChanged);
  }

  Future<void> _onStarted(AuthStarted e, Emitter<AuthBlocState> emit) async {
    final user = _repo.currentUser;
    emit(state.copyWith(
      status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      user: user,
    ));
    _sub ??= _repo.authChanges.listen((s) => add(_AuthUserChanged(s.session?.user)));
  }

  void _onUserChanged(_AuthUserChanged e, Emitter<AuthBlocState> emit) {
    emit(state.copyWith(
      status: e.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      user: e.user,
    ));
  }

  Future<void> _onSignIn(AuthSignInRequested e, Emitter<AuthBlocState> emit) async {
    emit(state.copyWith(status: AuthStatus.submitting));
    try {
      await _repo.signIn(email: e.email, password: e.password);
      // _AuthUserChanged will update state
    } on Failure catch (f) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: f.message));
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested e, Emitter<AuthBlocState> emit) async {
    emit(state.copyWith(status: AuthStatus.submitting));
    try {
      await _repo.signUp(email: e.email, password: e.password);
      emit(state.copyWith(
        status: _repo.currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: _repo.currentUser,
        infoMessage: 'Account created. You can now sign in.',
      ));
    } on Failure catch (f) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: f.message));
    }
  }

  Future<void> _onSignOut(AuthSignOutRequested e, Emitter<AuthBlocState> emit) async {
    await _repo.signOut();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
