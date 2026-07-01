import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> fetchProfile(String userId);
  Stream<UserProfile?> watchProfile(String userId);
  Future<UserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    bool? emailMarketingOptIn,
  });
  Future<String> uploadAvatar({required String userId, required File file});
  Future<void> softDeleteAccount();
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<UserProfile> fetchProfile(String userId) async {
    final row = await _client
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .maybeSingle();

    if (row == null) {
      // Profile may not exist yet for legacy users; create one.
      await _createProfile(userId);
      return fetchProfile(userId);
    }

    return UserProfile.fromJson(row);
  }

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _client
        .from('user_profiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          final row = rows.first;
          if (row['is_deleted'] == true) return null;
          return UserProfile.fromJson(row);
        });
  }

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    bool? emailMarketingOptIn,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (emailMarketingOptIn != null) {
      updates['email_marketing_opt_in'] = emailMarketingOptIn;
    }
    updates['updated_at'] = DateTime.now().toIso8601String();

    if (updates.length <= 1) {
      // Only updated_at — nothing to do
      return fetchProfile(userId);
    }

    try {
      await _client.from('user_profiles').update(updates).eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }

    return fetchProfile(userId);
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    final ext = file.path.split('.').last;
    final storagePath = 'avatars/$userId/avatar.$ext';

    try {
      await _client.storage
          .from('avatars')
          .upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
    } on StorageException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }

    // Update profile with new avatar URL
    await updateProfile(userId: userId, avatarUrl: storagePath);
    return storagePath;
  }

  @override
  Future<void> softDeleteAccount() async {
    try {
      await _client.rpc('soft_delete_account');
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Verify current password by re-authenticating
      final email = _client.auth.currentUser?.email;
      if (email == null) throw const AuthFailure('Not authenticated');

      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // Update password
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  Future<void> _createProfile(String userId) async {
    try {
      final user = _client.auth.currentUser;
      final provider = user?.isAnonymous == true
          ? 'anonymous'
          : (user?.appMetadata['provider'] as String?) ?? 'email';
      await _client.from('user_profiles').insert({
        'user_id': userId,
        'provider': provider,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Silently fail; will retry on next fetch
    }
  }
}
