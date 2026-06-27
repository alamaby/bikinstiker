import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/sticker_generation.dart';
import '../../../data/repositories/sticker_repository.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class HistoryRefreshed extends HistoryEvent {
  const HistoryRefreshed();
}

class HistoryCleared extends HistoryEvent {
  const HistoryCleared();
}

enum HistoryStatus { idle, loading, success, failure }

class HistoryBlocState extends Equatable {
  final HistoryStatus status;
  final List<StickerGeneration> items;
  final String? errorMessage;

  const HistoryBlocState({
    this.status = HistoryStatus.idle,
    this.items = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, items, errorMessage];
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryBlocState> {
  final StickerRepository _repo;
  HistoryBloc(this._repo) : super(const HistoryBlocState()) {
    on<HistoryRefreshed>(_onRefresh);
    on<HistoryCleared>((_, emit) => emit(const HistoryBlocState()));
  }

  Future<void> _onRefresh(
    HistoryRefreshed e,
    Emitter<HistoryBlocState> emit,
  ) async {
    emit(HistoryBlocState(status: HistoryStatus.loading, items: state.items));
    try {
      final list = await _repo.fetchHistory();
      emit(HistoryBlocState(status: HistoryStatus.success, items: list));
    } catch (err) {
      emit(
        HistoryBlocState(
          status: HistoryStatus.failure,
          items: state.items,
          errorMessage: err.toString(),
        ),
      );
    }
  }
}
