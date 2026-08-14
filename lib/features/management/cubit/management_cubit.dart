import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/pit_assignment.dart';
import '../../../data/models/pit_scouting_record.dart';
import '../../../data/models/scout_profile.dart';
import '../../../data/models/team.dart';
import '../../../data/repositories/assignment_repository.dart';
import '../../../data/repositories/pit_scouting_repository.dart';
import '../../../data/repositories/schedule_repository.dart';

part 'management_state.dart';

class ManagementCubit extends Cubit<ManagementState> {
  ManagementCubit(this._assignments, this._schedule, this._pitRecords)
      : super(const ManagementLoading());

  final AssignmentRepository _assignments;
  final ScheduleRepository _schedule;
  final PitScoutingRepository _pitRecords;

  StreamSubscription<List<ScoutProfile>>? _profileSub;
  StreamSubscription<List<PitAssignment>>? _assignmentSub;
  StreamSubscription<List<PitScoutingRecord>>? _recordSub;

  String _eventKey = '';
  String _eventName = '';
  List<ScoutProfile> _profiles = const [];
  List<PitAssignment> _assigned = const [];
  List<Team> _teams = const [];
  Set<int> _scouted = const {};

  Future<void> load() async {
    emit(const ManagementLoading());
    try {
      final detected = await _schedule.detectCurrentEvent();
      if (detected.status == EventStatus.past) {
        emit(const ManagementNoEvent());
        return;
      }

      _eventKey = detected.key;
      _teams = await _schedule.getTeams(_eventKey);

      try {
        _eventName = await _schedule.getEventName(_eventKey);
      } catch (_) {
        _eventName = _eventKey;
      }

      await _listen();
      _emitLoaded();
    } catch (e) {
      emit(ManagementError(e.toString()));
    }
  }

  Future<void> _listen() async {
    await _cancelSubs();

    _profileSub = _assignments.watchProfiles().listen((profiles) {
      _profiles = profiles;
      _emitLoaded();
    });

    _assignmentSub = _assignments.watchForEvent(_eventKey).listen((assigned) {
      _assigned = assigned;
      _emitLoaded();
    });

    _recordSub = _pitRecords.watchForEvent(_eventKey).listen((records) {
      _scouted = {for (final r in records) r.teamNumber};
      _emitLoaded();
    });
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(ManagementLoaded(
      eventKey: _eventKey,
      eventName: _eventName,
      profiles: _profiles,
      assignments: _assigned,
      teams: _teams,
      scoutedTeams: _scouted,
    ));
  }

  Future<String?> assign(String userId, Set<int> teams) async {
    try {
      await _assignments.setAssignments(_eventKey, userId, teams);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> unassign(int teamNumber) async {
    try {
      await _assignments.unassign(_eventKey, teamNumber);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _cancelSubs() async {
    await _profileSub?.cancel();
    await _assignmentSub?.cancel();
    await _recordSub?.cancel();
  }

  @override
  Future<void> close() async {
    await _cancelSubs();
    return super.close();
  }
}
