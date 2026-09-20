import 'package:bikin_stiker/core/auth_gate_policy.dart';
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
  late MockUser nonAnonUser;

  setUp(() {
    repo = MockAuthRepository();
    nonAnonUser = MockUser();
    when(() => nonAnonUser.id).thenReturn('user-1');
    when(() => nonAnonUser.isAnonymous).thenReturn(false);
  });

  AuthBlocState authenticatedSeed() =>
      AuthBlocState(status: AuthStatus.authenticated, user: nonAnonUser);

  group('signOut', () {
    blocTest<AuthBloc, AuthBlocState>(
      'successful signOut emits submitting then unauthenticated with explicitSignOut:true and user null',
      build: () {
        when(repo.signOut).thenAnswer((_) async {});
        return AuthBloc(repo);
      },
      seed: authenticatedSeed,
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        AuthBlocState(
          status: AuthStatus.submitting,
          user: nonAnonUser,
          explicitSignOut: false,
        ),
        const AuthBlocState(
          status: AuthStatus.unauthenticated,
          explicitSignOut: true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthBlocState>(
      'signOut throwing AuthFailure keeps previous status/user and shows errorMessage',
      build: () {
        when(repo.signOut).thenThrow(const AuthFailure('Network error'));
        return AuthBloc(repo);
      },
      seed: authenticatedSeed,
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        AuthBlocState(
          status: AuthStatus.submitting,
          user: nonAnonUser,
          explicitSignOut: false,
        ),
        AuthBlocState(
          status: AuthStatus.authenticated,
          user: nonAnonUser,
          errorMessage: 'Network error',
        ),
      ],
    );

    blocTest<AuthBloc, AuthBlocState>(
      'signOut throwing a generic exception keeps previous status/user and shows error toString',
      build: () {
        when(repo.signOut).thenThrow(Exception('unexpected'));
        return AuthBloc(repo);
      },
      seed: authenticatedSeed,
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        AuthBlocState(
          status: AuthStatus.submitting,
          user: nonAnonUser,
          explicitSignOut: false,
        ),
        AuthBlocState(
          status: AuthStatus.authenticated,
          user: nonAnonUser,
          errorMessage: 'Exception: unexpected',
        ),
      ],
    );
  });

  group('shouldAutoSpawnGuest', () {
    test('returns false when state is explicitly signed out', () {
      final state = const AuthBlocState(
        status: AuthStatus.unauthenticated,
        explicitSignOut: true,
      );
      expect(shouldAutoSpawnGuest(state), isFalse);
    });

    test('returns true when state is fresh unauthenticated', () {
      final state = const AuthBlocState(status: AuthStatus.unauthenticated);
      expect(shouldAutoSpawnGuest(state), isTrue);
    });

    test('returns false when state is authenticated', () {
      final state =
          AuthBlocState(status: AuthStatus.authenticated, user: nonAnonUser);
      expect(shouldAutoSpawnGuest(state), isFalse);
    });

    test('returns false when state is guest', () {
      final state = AuthBlocState(status: AuthStatus.guest, user: nonAnonUser);
      expect(shouldAutoSpawnGuest(state), isFalse);
    });

    test('returns false when state is submitting', () {
      final state = AuthBlocState(
        status: AuthStatus.submitting,
        user: nonAnonUser,
      );
      expect(shouldAutoSpawnGuest(state), isFalse);
    });
  });
}
