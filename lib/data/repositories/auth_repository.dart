import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';

abstract class AuthRepository {
  Stream<AuthState> get authChanges;
  User? get currentUser;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();
  Future<void> signInAnonymously();
  Future<void> upgradeAnonymousAccount({
    required String email,
    required String password,
  });
  Future<void> grantRegisteredBonus();
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  SupabaseAuthRepository(this._client);

  @override
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> signInAnonymously() async {
    try {
      await _client.auth.signInAnonymously();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> upgradeAnonymousAccount({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(email: email, password: password),
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> grantRegisteredBonus() async {
    try {
      await _client.rpc('grant_registered_bonus');
    } on Exception catch (e) {
      throw UnknownFailure('Failed to grant registered bonus: $e');
    }
  }
}
