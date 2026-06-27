import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../data/repositories/sticker_repository.dart';

sealed class StickerGenEvent extends Equatable {
  const StickerGenEvent();
  @override
  List<Object?> get props => [];
}

class StickerGenSubmitted extends StickerGenEvent {
  final String presetId;
  final String prompt;
  const StickerGenSubmitted({required this.presetId, required this.prompt});
  @override
  List<Object?> get props => [presetId, prompt];
}

class StickerGenReset extends StickerGenEvent {
  const StickerGenReset();
}

enum StickerGenStatus { idle, submitting, success, failure }

class StickerGenBlocState extends Equatable {
  final StickerGenStatus status;
  final String? signedUrl;
  final String? stickerId;
  final Failure? failure;

  const StickerGenBlocState({
    this.status = StickerGenStatus.idle,
    this.signedUrl,
    this.stickerId,
    this.failure,
  });

  @override
  List<Object?> get props => [status, signedUrl, stickerId, failure];
}

class StickerGenBloc extends Bloc<StickerGenEvent, StickerGenBlocState> {
  final StickerRepository _repo;

  StickerGenBloc(this._repo) : super(const StickerGenBlocState()) {
    on<StickerGenSubmitted>(_onSubmit);
    on<StickerGenReset>((_, emit) => emit(const StickerGenBlocState()));
  }

  Future<void> _onSubmit(
    StickerGenSubmitted e,
    Emitter<StickerGenBlocState> emit,
  ) async {
    emit(const StickerGenBlocState(status: StickerGenStatus.submitting));
    try {
      final result = await _repo.generate(
        presetId: e.presetId,
        userInput: e.prompt,
      );
      emit(
        StickerGenBlocState(
          status: StickerGenStatus.success,
          signedUrl: result.signedUrl,
          stickerId: result.stickerId,
        ),
      );
    } on Failure catch (f) {
      emit(StickerGenBlocState(status: StickerGenStatus.failure, failure: f));
    } catch (e) {
      emit(
        StickerGenBlocState(
          status: StickerGenStatus.failure,
          failure: UnknownFailure(e.toString()),
        ),
      );
    }
  }
}
