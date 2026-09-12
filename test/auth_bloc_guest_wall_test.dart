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

  setUp(() {
    repo = MockAuthRepository();
    guestUser = MockUser();
    when(() => guestUser.id).thenReturn('guest-1');
    when(() => guestUser.isAnonymous).thenReturn(true);
  });

  AuthBlocState guestSeed() =>
      AuthBlocState(status: AuthStatus.guest, user: guestUser);

  group('guest-wall failure fallback (regression: must not bounce to legal)',
      () {
    blocTest<AuthBloc, AuthBlocState>(
      'signup with existing email from guest wall stays guest with error',
      build: () {
        when(() => repo.upgradeAnonymousAccount(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const AuthFailure('User already registered'));
        return AuthBloc(repo);
      },
      seed: guestSeed,
      act: (bloc) => bloc.add(
        const AuthSignUpRequested(
          'existing@mail.com',
          'secret123',
          upgradeGuest: true,
        ),
      ),
      expect: () => [
        AuthBlocState(status: AuthStatus.submitting, user: guestUser),
        AuthBlocState(
          status: AuthStatus.guest,
          user: guestUser,
          errorMessage: 'User already registered',
        ),
      ],
    );

    blocTest<AuthBloc, AuthBlocState>(
      'sign-in failure from guest wall stays guest with error',
      build: () {
        when(() => repo.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const AuthFailure('Invalid login credentials'));
        return AuthBloc(repo);
      },
      seed: guestSeed,
      act: (bloc) => bloc.add(
        const AuthSignInRequested(
          'user@mail.com',
          'wrongpass',
          isGuestAuthWall: true,
        ),
      ),
      expect: () => [
        AuthBlocState(status: AuthStatus.submitting, user: guestUser),
        AuthBlocState(
          status: AuthStatus.guest,
          user: guestUser,
          errorMessage: 'Invalid login credentials',
        ),
      ],
    );

    blocTest<AuthBloc, AuthBlocState>(
      'normal (non-wall) signup failure still goes unauthenticated',
      build: () {
        when(() => repo.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const AuthFailure('Signup disabled'));
        return AuthBloc(repo);
      },
      act: (bloc) =>
          bloc.add(const AuthSignUpRequested('a@mail.com', 'secret123')),
      expect: () => [
        const AuthBlocState(status: AuthStatus.submitting),
        const AuthBlocState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Signup disabled',
        ),
      ],
    );

    blocTest<AuthBloc, AuthBlocState>(
      'normal (non-wall) sign-in failure still goes unauthenticated',
      build: () {
        when(() => repo.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const AuthFailure('Invalid login credentials'));
        return AuthBloc(repo);
      },
      act: (bloc) =>
          bloc.add(const AuthSignInRequested('a@mail.com', 'wrongpass')),
      expect: () => [
        const AuthBlocState(status: AuthStatus.submitting),
        const AuthBlocState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Invalid login credentials',
        ),
      ],
    );
  });
}
