import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/mission.dart';
import '../../../data/models/mission_progress.dart';
import '../../../data/repositories/mission_repository.dart';

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

class MissionErrorCleared extends MissionEvent {
  const MissionErrorCleared();
}

enum MissionStatus { initial, loading, loaded, error }

class MissionState extends Equatable {
  final MissionStatus status;
  final List<Mission> missions;
  final List<MissionProgress> progress;
  final String? errorMessage;
  final Set<String> pendingMissionIds;
  final Map<String, DateTime> lastClaimAt;

  const MissionState({
    this.status = MissionStatus.initial,
    this.missions = const [],
    this.progress = const [],
    this.errorMessage,
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

  static const Object _undefined = Object();

  MissionState copyWith({
    MissionStatus? status,
    List<Mission>? missions,
    List<MissionProgress>? progress,
    String? errorMessage,
    Set<String>? pendingMissionIds,
    Map<String, DateTime>? lastClaimAt,
  }) {
    return MissionState(
      status: status ?? this.status,
      missions: missions ?? this.missions,
      progress: progress ?? this.progress,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage,
      pendingMissionIds: pendingMissionIds ?? this.pendingMissionIds,
      lastClaimAt: lastClaimAt ?? this.lastClaimAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    missions,
    progress,
    errorMessage,
    pendingMissionIds,
    lastClaimAt,
  ];
}

class MissionBloc extends Bloc<MissionEvent, MissionState> {
  final MissionRepository _repo;

  MissionBloc(this._repo) : super(const MissionState()) {
    on<MissionLoadRequested>(_onLoad);
    on<MissionCompleteRequested>(_onComplete);
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
      ]);
      emit(
        state.copyWith(
          status: MissionStatus.loaded,
          missions: results[0] as List<Mission>,
          progress: results[1] as List<MissionProgress>,
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
    } catch (e) {
      final pending = {...state.pendingMissionIds}..remove(e.missionId);
      emit(
        state.copyWith(
          status: MissionStatus.loaded,
          errorMessage: e.toString(),
          pendingMissionIds: pending,
        ),
      );
    }
  }

  Future<void> _onErrorCleared(
    MissionErrorCleared e,
    Emitter<MissionState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null));
  }
}
