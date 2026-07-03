import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/daily_checkin_streak.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/mission_progress.dart';
import '../../../data/repositories/mission_repository.dart';
import '../../../data/repositories/rewarded_ad_repository.dart';

sealed class MissionEvent extends Equatable {
  const MissionEvent();
  @override
  List<Object?> get props => [];
}

class MissionLoadRequested extends MissionEvent {
  final String userId;
  const MissionLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class MissionCompleteRequested extends MissionEvent {
  final String userId;
  final String missionId;
  const MissionCompleteRequested(this.userId, this.missionId);
  @override
  List<Object?> get props => [userId, missionId];
}

class MissionWatchAdRequested extends MissionEvent {
  final String userId;
  final String missionId;
  const MissionWatchAdRequested(this.userId, this.missionId);
  @override
  List<Object?> get props => [userId, missionId];
}

class MissionDailyCheckinClaimRequested extends MissionEvent {
  const MissionDailyCheckinClaimRequested();
}

class MissionErrorCleared extends MissionEvent {
  const MissionErrorCleared();
}

enum MissionStatus { initial, loading, loaded, error }

class MissionState extends Equatable {
  final MissionStatus status;
  final List<Mission> missions;
  final List<MissionProgress> progress;
  final DailyCheckinStreak? streak;
  final String? errorMessage;
  final String? successMessage;
  final Set<String> pendingMissionIds;
  final Map<String, DateTime> lastClaimAt;

  const MissionState({
    this.status = MissionStatus.initial,
    this.missions = const [],
    this.progress = const [],
    this.streak,
    this.errorMessage,
    this.successMessage,
    this.pendingMissionIds = const {},
    this.lastClaimAt = const {},
  });

  int completionsFor(String missionId) {
    return progress.where((p) => p.missionId == missionId).length;
  }

  bool isMissionPending(String missionId) =>
      pendingMissionIds.contains(missionId);

  bool isMissionDebounced(String missionId) {
    final ts = lastClaimAt[missionId];
    if (ts == null) return false;
    return DateTime.now().difference(ts) < const Duration(milliseconds: 500);
  }

  /// Returns the remaining cooldown duration for a mission, or null if no cooldown or not in cooldown.
  Duration? cooldownRemainingFor(String missionId, Mission mission) {
    if (mission.cooldownSeconds == null) return null;
    final lastCompleted = _lastCompletedAt(missionId);
    if (lastCompleted == null) return null;
    final cooldownEnd = lastCompleted.add(
      Duration(seconds: mission.cooldownSeconds!),
    );
    final remaining = cooldownEnd.difference(DateTime.now());
    if (remaining.isNegative) return null;
    return remaining;
  }

  /// Returns true if daily limit is reached for this mission.
  bool isDailyLimitReached(String missionId, Mission mission) {
    if (mission.maxCompletionsPerDay == null) return false;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final count = progress
        .where(
          (p) => p.missionId == missionId && p.completedAt.isAfter(startOfDay),
        )
        .length;
    return count >= mission.maxCompletionsPerDay!;
  }

  /// Returns true if mission is completed (for one-time missions).
  bool isMissionCompleted(String missionId, Mission mission) {
    final maxCompletions = mission.maxCompletionsPerUser;
    if (maxCompletions == null) return false;
    return completionsFor(missionId) >= maxCompletions;
  }

  DateTime? _lastCompletedAt(String missionId) {
    final relevant = progress.where((p) => p.missionId == missionId).toList();
    if (relevant.isEmpty) return null;
    relevant.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return relevant.first.completedAt;
  }

  static const Object _undefined = Object();

  MissionState copyWith({
    MissionStatus? status,
    List<Mission>? missions,
    List<MissionProgress>? progress,
    DailyCheckinStreak? streak,
    String? errorMessage,
    String? successMessage,
    Set<String>? pendingMissionIds,
    Map<String, DateTime>? lastClaimAt,
  }) {
    return MissionState(
      status: status ?? this.status,
      missions: missions ?? this.missions,
      progress: progress ?? this.progress,
      streak: streak ?? this.streak,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage,
      successMessage: identical(successMessage, _undefined)
          ? this.successMessage
          : successMessage,
      pendingMissionIds: pendingMissionIds ?? this.pendingMissionIds,
      lastClaimAt: lastClaimAt ?? this.lastClaimAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    missions,
    progress,
    streak,
    errorMessage,
    successMessage,
    pendingMissionIds,
    lastClaimAt,
  ];
}

class MissionBloc extends Bloc<MissionEvent, MissionState> {
  final MissionRepository _repo;
  final RewardedAdRepository _adRepo;

  MissionBloc(this._repo, this._adRepo) : super(const MissionState()) {
    on<MissionLoadRequested>(_onLoad);
    on<MissionCompleteRequested>(_onComplete);
    on<MissionWatchAdRequested>(_onWatchAd);
    on<MissionDailyCheckinClaimRequested>(_onDailyCheckinClaim);
    on<MissionErrorCleared>(_onErrorCleared);
  }

  Future<void> _onLoad(
    MissionLoadRequested e,
    Emitter<MissionState> emit,
  ) async {
    emit(state.copyWith(status: MissionStatus.loading));
    try {
      final results = await Future.wait([
        _repo.fetchMissions(),
        _repo.fetchUserProgress(e.userId),
        _repo.fetchDailyCheckinStreak(),
      ]);
      emit(
        state.copyWith(
          status: MissionStatus.loaded,
          missions: results[0] as List<Mission>,
          progress: results[1] as List<MissionProgress>,
          streak: results[2] as DailyCheckinStreak,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: MissionStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onComplete(
    MissionCompleteRequested e,
    Emitter<MissionState> emit,
  ) async {
    emit(
      state.copyWith(
        pendingMissionIds: {...state.pendingMissionIds, e.missionId},
        lastClaimAt: {...state.lastClaimAt, e.missionId: DateTime.now()},
      ),
    );
    try {
      final newProgress = await _repo.completeMission(
        userId: e.userId,
        missionId: e.missionId,
      );
      final pending = {...state.pendingMissionIds}..remove(e.missionId);
      emit(
        state.copyWith(
          status: MissionStatus.loaded,
          progress: [...state.progress, newProgress],
          pendingMissionIds: pending,
        ),
      );
    } catch (err) {
      final pending = {...state.pendingMissionIds}..remove(e.missionId);
      emit(
        state.copyWith(
          status: MissionStatus.loaded,
          errorMessage: err.toString(),
          pendingMissionIds: pending,
        ),
      );
    }
  }

  Future<void> _onWatchAd(
    MissionWatchAdRequested e,
    Emitter<MissionState> emit,
  ) async {
    // First show the rewarded ad
    final rewardEarned = await _adRepo.loadAndShow();
    if (!rewardEarned) {
      final detail = _adRepo.lastErrorMessage;
      emit(
        state.copyWith(
          errorMessage: detail != null && detail.isNotEmpty
              ? 'Ad error: $detail'
              : 'Failed to load or watch ad. Please try again.',
        ),
      );
      return;
    }

    // If reward earned, proceed with mission completion
    add(MissionCompleteRequested(e.userId, e.missionId));
  }

  Future<void> _onDailyCheckinClaim(
    MissionDailyCheckinClaimRequested e,
    Emitter<MissionState> emit,
  ) async {
    emit(state.copyWith(successMessage: null));
    try {
      final result = await _repo.claimDailyCheckin();
      // Refresh streak after claim
      final streak = await _repo.fetchDailyCheckinStreak();
      emit(
        state.copyWith(
          streak: streak,
          successMessage: 'checkin_success:${result.creditsAwarded}',
        ),
      );
    } catch (err) {
      emit(state.copyWith(errorMessage: err.toString()));
    }
  }

  Future<void> _onErrorCleared(
    MissionErrorCleared e,
    Emitter<MissionState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
  }
}
