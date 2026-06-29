import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/sticker_preset.dart';
import '../../../data/repositories/preset_repository.dart';

sealed class PresetEvent extends Equatable {
  const PresetEvent();
  @override
  List<Object?> get props => [];
}

class PresetRefreshRequested extends PresetEvent {
  final StickerPresetRole role;
  final bool force;
  const PresetRefreshRequested({required this.role, this.force = false});
  @override
  List<Object?> get props => [role, force];
}

class PresetCleared extends PresetEvent {
  const PresetCleared();
}

enum PresetStatus { idle, loading, success, failure }

class PresetState extends Equatable {
  final PresetStatus status;
  final List<StickerPreset> presets;
  final StickerPresetRole? role;
  final String? errorMessage;

  const PresetState({
    this.status = PresetStatus.idle,
    this.presets = const [],
    this.role,
    this.errorMessage,
  });

  PresetState copyWith({
    PresetStatus? status,
    List<StickerPreset>? presets,
    Object? role = _undefined,
    Object? errorMessage = _undefined,
  }) => PresetState(
    status: status ?? this.status,
    presets: presets ?? this.presets,
    role: identical(role, _undefined) ? this.role : role as StickerPresetRole?,
    errorMessage: identical(errorMessage, _undefined)
        ? this.errorMessage
        : errorMessage as String?,
  );

  static const Object _undefined = Object();

  @override
  List<Object?> get props => [status, presets, role, errorMessage];
}

class PresetBloc extends Bloc<PresetEvent, PresetState> {
  final PresetRepository _repo;

  PresetBloc(this._repo) : super(const PresetState()) {
    on<PresetRefreshRequested>(_onRefresh);
    on<PresetCleared>((_, emit) => emit(const PresetState()));
  }

  Future<void> _onRefresh(
    PresetRefreshRequested event,
    Emitter<PresetState> emit,
  ) async {
    if (state.status == PresetStatus.loading && state.role == event.role) {
      return;
    }

    emit(state.copyWith(status: PresetStatus.loading, errorMessage: null));

    try {
      final presets = await _repo.fetchPresets(
        role: event.role,
        forceRefresh: event.force,
      );
      emit(
        state.copyWith(
          status: PresetStatus.success,
          presets: presets,
          role: event.role,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PresetStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
