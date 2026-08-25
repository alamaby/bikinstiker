import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/errors/failures.dart';
import '../../../data/repositories/surprise_me_repository.dart';
import 'surprise_me_state.dart';

class SurpriseMeCubit extends Cubit<SurpriseMeState> {
  final SurpriseMeRepository _repository;

  SurpriseMeCubit({SurpriseMeRepository? repository})
    : _repository = repository ?? getIt<SurpriseMeRepository>(),
      super(const SurpriseMeInitial());

  Future<SurpriseMeQuota> fetchQuota() => _repository.fetchQuota();

  Future<void> requestSurprise({required String presetId}) async {
    emit(const SurpriseMeLoading());
    try {
      final result = await _repository.requestSurprise(presetId: presetId);
      emit(
        SurpriseMeSuccess(
          prompt: result.prompt,
          charged: result.charged,
          balance: result.balance,
          freeRemaining: result.freeRemaining,
        ),
      );
    } on Failure catch (f) {
      emit(SurpriseMeFailure(f));
    } catch (e) {
      emit(SurpriseMeFailure(UnknownFailure(e.toString())));
    }
  }

  void reset() {
    emit(const SurpriseMeInitial());
  }
}
