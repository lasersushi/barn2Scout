import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/pit_assignment.dart';
import '../../../data/models/pit_scouting_record.dart';
import '../../../data/repositories/assignment_repository.dart';
import '../../../data/repositories/pit_scouting_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/team_repository.dart';

part 'my_tasks_state.dart';

class MyTasksCubit extends Cubit<MyTasksState> {
  MyTasksCubit(
    this._assignments,
    this._schedule,
    this._pitRecords,
    this._teams,
  ) : super(const MyTasksEmpty());

  final AssignmentRepository _assignments;
  final ScheduleRepository _schedule;
  final PitScoutingRepository _pitRecords;
  final TeamRepository _teams;

  StreamSubscription<List<PitAssignment>>? _assignmentSub;
  StreamSubscription<List<PitScoutingRecord>>? _recordSub;

  String _eventKey = '';
  List<PitAssignment> _mine = const [];
  Set<int> _scouted = const {};
  Map<int, String> _names = const {};

  Future<void> init() async {
    try {
      final detected = await _schedule.detectCurrentEvent();
      if (detected.status == EventStatus.past) {
        emit(const MyTasksEmpty());
        return;
      }
      _eventKey = detected.key;

      _names = {
        for (final team in await _teams.getAll()) team.teamNumber: team.nickname,
      };

      await _assignmentSub?.cancel();
      await _recordSub?.cancel();

      _assignmentSub = _assignments.watchMine(_eventKey).listen((mine) {
        _mine = mine
            .where((a) => a.teamNumber != AppConfig.myTeamNumber)
            .toList();
        _emit();
      });
      _recordSub = _pitRecords.watchForEvent(_eventKey).listen((records) {
        _scouted = {for (final r in records) r.teamNumber};
        _emit();
      });
    } catch (_) {
      emit(const MyTasksEmpty());
    }
  }

  void _emit() {
    if (isClosed) return;
    if (_mine.isEmpty) {
      emit(const MyTasksEmpty());
      return;
    }
    emit(MyTasksLoaded(
      eventKey: _eventKey,
      tasks: [
        for (final a in _mine)
          MyTask(
            teamNumber: a.teamNumber,
            nickname: _names[a.teamNumber] ?? 'Team ${a.teamNumber}',
            done: _scouted.contains(a.teamNumber),
          ),
      ],
    ));
  }

  @override
  Future<void> close() async {
    await _assignmentSub?.cancel();
    await _recordSub?.cancel();
    return super.close();
  }
}
