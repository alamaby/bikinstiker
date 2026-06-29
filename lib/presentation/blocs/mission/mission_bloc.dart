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

enum MissionStatus { initial, loading, loaded, completing, error }

class MissionState extends Equatable {
  final MissionStatus status;
  final List<Mission> missions;
  final List<MissionProgress> progress;
  final String? errorMessage;

  const MissionState({
    this.status = MissionStatus.initial,
    this.missions = const [],
    this.progress = const [],
    this.errorMessage,
  });

  int completionsFor(String missionId) {
    return progress.where((p) => p.missionId == missionId).length;
  }

  MissionState copyWith({
    MissionStatus? status,
    List<Mission>? missions,
    List<MissionProgress>? progress,
    String? errorMessage,
  }) {
    return MissionState(
      status: status ?? this.status,
      missions: missions ?? this.missions,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, missions, progress, errorMessage];
}

class MissionBloc extends Bloc<MissionEvent, MissionState> {
  final MissionRepository _repo;
  String? _userId;

  MissionBloc(this._repo) : super(const MissionState()) {
    on<MissionLoadRequested>(_onLoad);
    on<MissionCompleteRequested>(_onComplete);
  }

  Future<void> _onLoad(
    MissionLoadRequested e,
    Emitter<MissionState> emit,
  ) async {
    _userId = e.userId;
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
    emit(state.copyWith(status: MissionStatus.completing));
    try {
      final newProgress = await _repo.completeMission(
        userId: e.userId,
        missionId: e.missionId,
      );
      emit(
        state.copyWith(
          status: MissionStatus.loaded,
          progress: [...state.progress, newProgress],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MissionStatus.loaded,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
