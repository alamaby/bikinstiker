import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';

class LocaleState extends Equatable {
  final Locale locale;
  final bool explicitlySelected;

  const LocaleState({
    required this.locale,
    this.explicitlySelected = false,
  });

  LocaleState copyWith({
    Locale? locale,
    bool? explicitlySelected,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      explicitlySelected: explicitlySelected ?? this.explicitlySelected,
    );
  }

  @override
  List<Object?> get props => [locale, explicitlySelected];
}
