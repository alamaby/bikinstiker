import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/env_constants.dart';
import '../../core/errors/failures.dart';

abstract class AuthRepository {
  Stream<AuthState> get authChanges;
  User? get currentUser;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();
  Future<void> signInAnonymously();
  Future<void> signInWithGoogle();
  Future<void> upgradeAnonymousAccount({
    required String email,
    required String password,
  });
  Future<void> grantRegisteredBonus();

  /// Sign in with Google using native account picker modal.
  /// Returns true if sign-in succeeded, false if user cancelled.
  Future<bool> signInWithGoogleModal();

  /// Create a one-time migration token for guest sticker transfer.
  /// Must be called BEFORE switching from anonymous to Google session.
  Future<String> createGuestMigrationToken();

  /// Consume migration token and migrate guest stickers to current account.
  Future<MigrationResult> migrateGuestStickers({required String token});
}

class MigrationResult {
  final int stickersMoved;
  final int packsMoved;
  final bool bonusGranted;
  const MigrationResult({
    required this.stickersMoved,
    required this.packsMoved,
    required this.bonusGranted,
  });

  factory MigrationResult.fromJson(Map<String, dynamic> json) {
    return MigrationResult(
      stickersMoved: json['stickersMoved'] as int? ?? 0,
      packsMoved: json['packsMoved'] as int? ?? 0,
      bonusGranted: json['bonusGranted'] as bool? ?? false,
    );
  }
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
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.bikinstiker://login-callback/',
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<bool> signInWithGoogleModal() async {
    try {
      final serverClientId = EnvConstants.googleWebClientId;
      if (serverClientId == null || serverClientId.isEmpty) {
        throw const AuthFailure(
          'Google Sign-In not configured. Missing GOOGLE_WEB_CLIENT_ID.',
        );
      }

      final googleSignIn = GoogleSignIn(serverClientId: serverClientId);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw const AuthFailure('Failed to get Google ID token.');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      return true;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<String> createGuestMigrationToken() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        throw const AuthFailure('No active session');
      }

      final supabaseUrl = EnvConstants.supabaseUrl;
      final uri = Uri.parse('$supabaseUrl/functions/v1/create-guest-migration');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
          'apikey': EnvConstants.supabaseAnonKey,
        },
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthFailure(body['error'] as String? ?? 'Migration token failed');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['migrationToken'] as String;
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<MigrationResult> migrateGuestStickers({required String token}) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        throw const AuthFailure('No active session');
      }

      final supabaseUrl = EnvConstants.supabaseUrl;
      final uri = Uri.parse('$supabaseUrl/functions/v1/migrate-guest-stickers');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
          'apikey': EnvConstants.supabaseAnonKey,
        },
        body: jsonEncode({'migrationToken': token}),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthFailure(body['error'] as String? ?? 'Migration failed');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return MigrationResult.fromJson(body);
    } on AuthFailure {
      rethrow;
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
