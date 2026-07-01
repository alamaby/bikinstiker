import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePrefillState extends Equatable {
  final String? presetId;
  final String? prompt;
  final String? captionText;
  final String? captionPosition;

  const HomePrefillState({
    this.presetId,
    this.prompt,
    this.captionText,
    this.captionPosition,
  });

  bool get hasData => presetId != null || prompt != null;

  @override
  List<Object?> get props => [presetId, prompt, captionText, captionPosition];
}

class HomePrefillCubit extends Cubit<HomePrefillState> {
  HomePrefillCubit() : super(const HomePrefillState());

  void set({
    String? presetId,
    String? prompt,
    String? captionText,
    String? captionPosition,
  }) {
    emit(HomePrefillState(
      presetId: presetId,
      prompt: prompt,
      captionText: captionText,
      captionPosition: captionPosition,
    ));
  }

  void clear() => emit(const HomePrefillState());
}
