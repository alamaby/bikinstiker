import 'package:flutter_bloc/flutter_bloc.dart';

/// Index of the active MainShell tab. 0 = Home.
class ShellTabCubit extends Cubit<int> {
  ShellTabCubit() : super(0);

  /// Switch to the Home tab (index 0).
  ///
  /// NOTE: caller must guarantee a tab-switch is needed (i.e. current tab != 0).
  /// If state is already 0 this emit is deduped by Bloc and no listener fires —
  /// that is acceptable because we only call [goHome] from the History tab
  /// (index 3), so 3→0 always changes.
  void goHome() => emit(0);

  void select(int i) => emit(i);
}
