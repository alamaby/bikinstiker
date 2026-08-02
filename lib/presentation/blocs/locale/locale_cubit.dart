import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/locale_repository.dart';
import 'locale_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  final LocaleRepository _repository;

  LocaleCubit(this._repository, {Locale? platformLocale})
      : super(
          LocaleState(
            locale: _repository.resolveLocale(platformLocale),
            explicitlySelected: _repository.savedLocale != null &&
                _repository.hasSelectionCompleted,
          ),
        );

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (!LocaleRepository.supportedLanguageCodes.contains(code)) return;
    emit(LocaleState(locale: Locale(code), explicitlySelected: true));
    try {
      await _repository.saveLocale(Locale(code), markSelectionCompleted: true);
    } catch (_) {
      // On failure, revert to previous locale
      final previous = _repository.savedLocale ?? const Locale('en');
      emit(LocaleState(
        locale: previous,
        explicitlySelected: _repository.hasSelectionCompleted,
      ));
    }
  }
}
