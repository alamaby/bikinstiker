import 'package:bikin_stiker/core/errors/failures.dart';
import 'package:bikin_stiker/data/repositories/auth_repository.dart';
import 'package:bikin_stiker/presentation/blocs/auth/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepository repo;
  late MockUser guestUser;
  late MockUser nonAnonUser;

  setUp(() {
    repo = MockAuthRepository();
    guestUser = MockUser();
    when(() => guestUser.id).thenReturn('guest-1');
    when(() => guestUser.isAnonymous).thenReturn(true);
    nonAnonUser = MockUser();
    when(() => nonAnonUser.id).thenReturn('user-1');
    when(() => nonAnonUser.isAnonymous).thenReturn(false);
    when(() => repo.currentUser).thenReturn(null);
  });

  // T1: send OTP success (normal) — R1
  blocTest<AuthBloc, AuthBlocState>(
    'send OTP success sets pendingOtpEmail and restores previous status',
    build: () {
      when(
        () => repo.sendEmailOtp(email: any(named: 'email')),
      ).thenAnswer((_) async {});
      return AuthBloc(repo);
    },
    seed: () => const AuthBlocState(status: AuthStatus.unauthenticated),
    act: (bloc) => bloc.add(const AuthOtpSendRequested('a@mail.com')),
    expect: () => [
      const AuthBlocState(status: AuthStatus.submitting),
      const AuthBlocState(
        status: AuthStatus.unauthenticated,
        pendingOtpEmail: 'a@mail.com',
      ),
    ],
    verify: (bloc) {
      verify(() => repo.sendEmailOtp(email: 'a@mail.com')).called(1);
    },
  );

  // T2: send OTP rejected for new email — R2
  blocTest<AuthBloc, AuthBlocState>(
    'send OTP for unregistered email shows error and clears pendingOtpEmail',
    build: () {
      when(
        () => repo.sendEmailOtp(email: any(named: 'email')),
      ).thenThrow(const AuthFailure('Signups not allowed for otp'));
      return AuthBloc(repo);
    },
    seed: () => const AuthBlocState(status: AuthStatus.unauthenticated),
    act: (bloc) => bloc.add(const AuthOtpSendRequested('new@mail.com')),
    expect: () => [
      const AuthBlocState(status: AuthStatus.submitting),
      const AuthBlocState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Signups not allowed for otp',
      ),
    ],
  );

  // T3: send OTP failure from guest wall stays guest — R4, F2
  blocTest<AuthBloc, AuthBlocState>(
    'guest-wall OTP send failure stays guest with error and keeps explicitSignOut',
    build: () {
      when(
        () => repo.sendEmailOtp(email: any(named: 'email')),
      ).thenThrow(const AuthFailure('Signups not allowed for otp'));
      return AuthBloc(repo);
    },
    seed: () => AuthBlocState(
      status: AuthStatus.guest,
      user: guestUser,
      explicitSignOut: true,
    ),
    act: (bloc) =>
        bloc.add(AuthOtpSendRequested('x@mail.com', isGuestAuthWall: true)),
    expect: () => [
      AuthBlocState(
        status: AuthStatus.submitting,
        user: guestUser,
        explicitSignOut: false,
      ),
      AuthBlocState(
        status: AuthStatus.guest,
        user: guestUser,
        errorMessage: 'Signups not allowed for otp',
        explicitSignOut: true,
      ),
    ],
  );

  // T3b: normal OTP send preserves explicitSignOut on failure — gate must not
  // auto-spawn a guest while waiting for the code.
  blocTest<AuthBloc, AuthBlocState>(
    'normal OTP send failure preserves explicitSignOut flag',
    build: () {
      when(
        () => repo.sendEmailOtp(email: any(named: 'email')),
      ).thenThrow(const AuthFailure('Signups not allowed for otp'));
      return AuthBloc(repo);
    },
    seed: () => const AuthBlocState(
      status: AuthStatus.unauthenticated,
      explicitSignOut: true,
    ),
    act: (bloc) => bloc.add(const AuthOtpSendRequested('new@mail.com')),
    expect: () => [
      const AuthBlocState(status: AuthStatus.submitting),
      const AuthBlocState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Signups not allowed for otp',
        explicitSignOut: true,
      ),
    ],
  );

  // T3c: OTP send success preserves explicitSignOut — the success state is an
  // unauthenticated wait-for-code, not a session, so _AuthGate must not spawn
  // a guest behind the OTP screen.
  blocTest<AuthBloc, AuthBlocState>(
    'normal OTP send success preserves explicitSignOut flag',
    build: () {
      when(
        () => repo.sendEmailOtp(email: any(named: 'email')),
      ).thenAnswer((_) async {});
      return AuthBloc(repo);
    },
    seed: () => const AuthBlocState(
      status: AuthStatus.unauthenticated,
      explicitSignOut: true,
    ),
    act: (bloc) => bloc.add(const AuthOtpSendRequested('a@mail.com')),
    expect: () => [
      const AuthBlocState(status: AuthStatus.submitting),
      const AuthBlocState(
        status: AuthStatus.unauthenticated,
        pendingOtpEmail: 'a@mail.com',
        explicitSignOut: true,
      ),
    ],
  );

  // T4: verify OTP success — R1
  blocTest<AuthBloc, AuthBlocState>(
    'verify OTP success transitions to authenticated',
    build: () {
      when(
        () => repo.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});
      when(() => repo.currentUser).thenReturn(nonAnonUser);
      return AuthBloc(repo);
    },
    seed: () => const AuthBlocState(status: AuthStatus.unauthenticated),
    act: (bloc) =>
        bloc.add(const AuthOtpVerifyRequested('a@mail.com', '12345678')),
    expect: () => [
      const AuthBlocState(status: AuthStatus.submitting),
      AuthBlocState(status: AuthStatus.authenticated, user: nonAnonUser),
    ],
  );

  // T4b: OTP verify success clears the wait-for-code flag without an
  // _AuthUserChanged round-trip so the OTP screen does not push twice.
  blocTest<AuthBloc, AuthBlocState>(
    'verify OTP success from pending state clears pendingOtpEmail',
    build: () {
      when(
        () => repo.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});
      when(() => repo.currentUser).thenReturn(nonAnonUser);
      return AuthBloc(repo);
    },
    seed: () => const AuthBlocState(
      status: AuthStatus.unauthenticated,
      pendingOtpEmail: 'a@mail.com',
    ),
    act: (bloc) =>
        bloc.add(const AuthOtpVerifyRequested('a@mail.com', '12345678')),
    expect: () => [
      const AuthBlocState(
        status: AuthStatus.submitting,
        pendingOtpEmail: 'a@mail.com',
      ),
      AuthBlocState(status: AuthStatus.authenticated, user: nonAnonUser),
    ],
  );

  // T5: verify OTP expired — R6
  blocTest<AuthBloc, AuthBlocState>(
    'verify OTP expired keeps pendingOtpEmail for resend',
    build: () {
      when(
        () => repo.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const AuthFailure('otp_expired'));
      return AuthBloc(repo);
    },
    seed: () => const AuthBlocState(status: AuthStatus.unauthenticated),
    act: (bloc) =>
        bloc.add(const AuthOtpVerifyRequested('a@mail.com', '00000000')),
    expect: () => [
      const AuthBlocState(status: AuthStatus.submitting),
      const AuthBlocState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'otp_expired',
        pendingOtpEmail: 'a@mail.com',
      ),
    ],
  );

  // T6: verify OTP failure from guest wall stays guest — R4
  blocTest<AuthBloc, AuthBlocState>(
    'guest-wall OTP verify failure stays guest',
    build: () {
      when(
        () => repo.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const AuthFailure('Invalid login'));
      return AuthBloc(repo);
    },
    seed: () => AuthBlocState(status: AuthStatus.guest, user: guestUser),
    act: (bloc) => bloc.add(
      const AuthOtpVerifyRequested(
        'a@mail.com',
        '12345678',
        isGuestAuthWall: true,
      ),
    ),
    expect: () => [
      AuthBlocState(status: AuthStatus.submitting, user: guestUser),
      AuthBlocState(
        status: AuthStatus.guest,
        user: guestUser,
        errorMessage: 'Invalid login',
        pendingOtpEmail: 'a@mail.com',
      ),
    ],
  );
}
