import 'package:flutter_bloc/flutter_bloc.dart';

/// Tracks which bottom-nav tab is selected.
///
/// This is the simplest possible example of the project's one-rule-everywhere
/// state pattern: even trivial UI state lives in a Cubit, so nothing in the app
/// mixes `setState` with Bloc. The state is just the selected tab index.
class NavigationCubit extends Cubit<int> {
  NavigationCubit() : super(0);

  void select(int index) => emit(index);
}
