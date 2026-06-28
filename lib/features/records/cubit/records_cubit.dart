import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/scouting_record.dart';
import '../../../data/repositories/scouting_repository.dart';

/// Streams all saved records (newest first) from the repository, keeping the
/// records UI on the same Cubit pattern as the rest of the app instead of a
/// bare StreamBuilder.
class RecordsCubit extends Cubit<List<ScoutingRecord>> {
  RecordsCubit(this._repository) : super(const []) {
    _subscription = _repository.watchAll().listen(emit);
  }

  final ScoutingRepository _repository;
  late final StreamSubscription<List<ScoutingRecord>> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
