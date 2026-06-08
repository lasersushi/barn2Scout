import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/pit_scouting_record.dart';
import '../../../data/repositories/pit_scouting_repository.dart';

class PitRecordsCubit extends Cubit<List<PitScoutingRecord>> {
  PitRecordsCubit(this._repository) : super(const []) {
    _subscription = _repository.watchAll().listen(emit);
  }

  final PitScoutingRepository _repository;
  late final StreamSubscription<List<PitScoutingRecord>> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
