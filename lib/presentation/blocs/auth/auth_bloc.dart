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
  final bool isGuestAuthWall;
  const AuthSignInRequested(
    this.email,
    this.password, {
    this.isGuestAuthWall = false,
  });
  @override
  List<Object?> get props => [email, password, isGuestAuthWall];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final bool upgradeGuest;
  const AuthSignUpRequested(
    this.email,
    this.password, {
    this.upgradeGuest = false,
  });
  @override
  List<Object?> get props => [email, password, upgradeGuest];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthAnonymousRequested extends AuthEvent {
  const AuthAnonymousRequested();
}

class AuthUpgradeAnonymousRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthUpgradeAnonymousRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class _AuthUserChanged extends AuthEvent {
  final User? user;
  const _AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user?.id];
}

// ----------------- State -----------------
enum AuthStatus { unknown, guest, authenticated, unauthenticated, submitting }

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

  bool get isGuest => user?.isAnonymous == true;

  // Sentinel for copyWith: omit a parameter to keep the current value,
  // pass an explicit value (including null) to overwrite it.
  static const Object _undefined = Object();

  AuthBlocState copyWith({
    AuthStatus? status,
    Object? user = _undefined,
    Object? errorMessage = _undefined,
    Object? infoMessage = _undefined,
  }) => AuthBlocState(
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
    on<AuthAnonymousRequested>(_onAnonymous);
    on<AuthUpgradeAnonymousRequested>(_onUpgradeAnonymous);
    on<_AuthUserChanged>(_onUserChanged);
  }

  Future<void> _onStarted(AuthStarted e, Emitter<AuthBlocState> emit) async {
    final user = _repo.currentUser;
    final status = _resolveStatus(user);
    emit(state.copyWith(status: status, user: user));
    _sub ??= _repo.authChanges.listen(
      (s) => add(_AuthUserChanged(s.session?.user)),
    );
  }

  AuthStatus _resolveStatus(User? user) {
    if (user == null) return AuthStatus.unauthenticated;
    if (user.isAnonymous) return AuthStatus.guest;
    return AuthStatus.authenticated;
  }

  void _onUserChanged(_AuthUserChanged e, Emitter<AuthBlocState> emit) {
    final status = _resolveStatus(e.user);
    emit(
      state.copyWith(
        status: status,
        user: e.user,
        errorMessage: null,
        infoMessage: null,
      ),
    );
  }

  Future<void> _onAnonymous(
    AuthAnonymousRequested e,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.submitting,
        errorMessage: null,
        infoMessage: null,
      ),
    );
    try {
      await _repo.signInAnonymously();
      final user = _repo.currentUser;
      final status = _resolveStatus(user);
      emit(
        state.copyWith(
          status: status,
          user: user,
          errorMessage: null,
          infoMessage: null,
        ),
      );
    } on Failure catch (f) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: f.message,
        ),
      );
    }
  }

  Future<void> _onUpgradeAnonymous(
    AuthUpgradeAnonymousRequested e,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.submitting,
        errorMessage: null,
        infoMessage: null,
      ),
    );
    try {
      await _repo.upgradeAnonymousAccount(email: e.email, password: e.password);
      await _repo.grantRegisteredBonus();
      final user = _repo.currentUser;
      final status = _resolveStatus(user);
      emit(
        state.copyWith(
          status: status,
          user: user,
          errorMessage: null,
          infoMessage: null,
        ),
      );
    } on Failure catch (f) {
      emit(state.copyWith(status: AuthStatus.guest, errorMessage: f.message));
    }
  }

  Future<void> _onSignIn(
    AuthSignInRequested e,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.submitting,
        errorMessage: null,
        infoMessage: null,
      ),
    );
    try {
      await _repo.signIn(email: e.email, password: e.password);
      final user = _repo.currentUser;
      final status = _resolveStatus(user);
      emit(
        state.copyWith(
          status: status,
          user: user,
          errorMessage: null,
          infoMessage: null,
        ),
      );
    } on Failure catch (f) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: f.message,
        ),
      );
    }
  }

  Future<void> _onSignUp(
    AuthSignUpRequested e,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.submitting,
        errorMessage: null,
        infoMessage: null,
      ),
    );
    try {
      if (e.upgradeGuest) {
        await _repo.upgradeAnonymousAccount(
          email: e.email,
          password: e.password,
        );
        await _repo.grantRegisteredBonus();
        final user = _repo.currentUser;
        final status = _resolveStatus(user);
        emit(
          state.copyWith(
            status: status,
            user: user,
            errorMessage: null,
            infoMessage: null,
          ),
        );
      } else {
        await _repo.signUp(email: e.email, password: e.password);
        emit(
          state.copyWith(
            status: _resolveStatus(_repo.currentUser),
            user: _repo.currentUser,
            infoMessage: 'Account created. You can now sign in.',
          ),
        );
      }
    } on Failure catch (f) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: f.message,
        ),
      );
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested e,
    Emitter<AuthBlocState> emit,
  ) async {
    await _repo.signOut();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
