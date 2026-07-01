import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/profile_repository.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {
  final UserProfile? profile;
  const ProfileLoading({this.profile});
  @override
  List<Object?> get props => [profile];
}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  const ProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  final UserProfile? profile;
  const ProfileError({required this.message, this.profile});
  @override
  List<Object?> get props => [message, profile];
}

class ProfileActionInProgress extends ProfileState {
  final String message;
  final UserProfile? profile;
  const ProfileActionInProgress({required this.message, this.profile});
  @override
  List<Object?> get props => [message, profile];
}

class ProfileActionSuccess extends ProfileState {
  final String message;
  final UserProfile profile;
  const ProfileActionSuccess({required this.message, required this.profile});
  @override
  List<Object?> get props => [message, profile];
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepo;

  ProfileCubit(this._profileRepo) : super(ProfileInitial());

  void loadProfile(String userId) async {
    emit(
      ProfileLoading(
        profile: state is ProfileLoaded
            ? (state as ProfileLoaded).profile
            : null,
      ),
    );
    try {
      final profile = await _profileRepo.fetchProfile(userId);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(
        ProfileError(
          message: e is Failure ? e.message : e.toString(),
          profile: state is ProfileLoaded
              ? (state as ProfileLoaded).profile
              : null,
        ),
      );
    }
  }

  Future<void> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {
    final currentProfile = _currentProfile;
    emit(
      ProfileActionInProgress(
        message: 'Updating display name...',
        profile: currentProfile,
      ),
    );
    try {
      final updated = await _profileRepo.updateProfile(
        userId: userId,
        displayName: displayName,
      );
      emit(
        ProfileActionSuccess(message: 'Display name updated', profile: updated),
      );
    } catch (e) {
      emit(
        ProfileError(
          message: e is Failure ? e.message : e.toString(),
          profile: currentProfile,
        ),
      );
    }
  }

  Future<void> updateAvatar({
    required String userId,
    required File file,
  }) async {
    final currentProfile = _currentProfile;
    emit(
      ProfileActionInProgress(
        message: 'Uploading avatar...',
        profile: currentProfile,
      ),
    );
    try {
      await _profileRepo.uploadAvatar(userId: userId, file: file);
      final refreshed = await _profileRepo.fetchProfile(userId);
      emit(ProfileActionSuccess(message: 'Avatar updated', profile: refreshed));
    } catch (e) {
      emit(
        ProfileError(
          message: e is Failure ? e.message : e.toString(),
          profile: currentProfile,
        ),
      );
    }
  }

  Future<void> toggleEmailMarketing({
    required String userId,
    required bool currentOptIn,
  }) async {
    final currentProfile = _currentProfile;
    try {
      final updated = await _profileRepo.updateProfile(
        userId: userId,
        emailMarketingOptIn: !currentOptIn,
      );
      emit(ProfileLoaded(updated));
    } catch (e) {
      emit(
        ProfileError(
          message: e is Failure ? e.message : e.toString(),
          profile: currentProfile,
        ),
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentProfile = _currentProfile;
    emit(
      ProfileActionInProgress(
        message: 'Changing password...',
        profile: currentProfile,
      ),
    );
    try {
      await _profileRepo.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(
        ProfileActionSuccess(
          message: 'Password changed successfully',
          profile: currentProfile!,
        ),
      );
    } catch (e) {
      emit(
        ProfileError(
          message: e is Failure ? e.message : e.toString(),
          profile: currentProfile,
        ),
      );
    }
  }

  Future<void> deleteAccount() async {
    final currentProfile = _currentProfile;
    emit(
      ProfileActionInProgress(
        message: 'Deleting account...',
        profile: currentProfile,
      ),
    );
    try {
      await _profileRepo.softDeleteAccount();
      emit(ProfileInitial());
    } catch (e) {
      emit(
        ProfileError(
          message: e is Failure ? e.message : e.toString(),
          profile: currentProfile,
        ),
      );
    }
  }

  UserProfile? get _currentProfile {
    final s = state;
    if (s is ProfileLoaded) return s.profile;
    if (s is ProfileActionInProgress) return s.profile;
    if (s is ProfileActionSuccess) return s.profile;
    if (s is ProfileError) return s.profile;
    if (s is ProfileLoading) return s.profile;
    return null;
  }
}
