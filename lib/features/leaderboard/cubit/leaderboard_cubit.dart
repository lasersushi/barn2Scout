import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/pit_scouting_record.dart';
import '../../../data/models/scout_profile.dart';
import '../../../data/models/scouting_record.dart';
import '../../../data/repositories/assignment_repository.dart';
import '../../../data/repositories/pit_scouting_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/scouting_repository.dart';
import '../xp.dart';

part 'leaderboard_state.dart';

/// Live XP leaderboard for the current comp, rebuilt whenever match records,
/// pit records, or scout profiles change. Bails on past events like
/// RecordsCubit.
class LeaderboardCubit extends Cubit<LeaderboardState> {
  LeaderboardCubit(
    this._scouting,
    this._pitScouting,
    this._assignments,
    this._schedule, {
    this.includeIdleScouts = false,
  }) : super(const LeaderboardLoading());

  final ScoutingRepository _scouting;
  final PitScoutingRepository _pitScouting;
  final AssignmentRepository _assignments;
  final ScheduleRepository _schedule;

  /// List scouts with no reports at 0 XP (the admin view).
  final bool includeIdleScouts;

  StreamSubscription<List<ScoutingRecord>>? _matchSub;
  StreamSubscription<List<PitScoutingRecord>>? _pitSub;
  StreamSubscription<List<ScoutProfile>>? _profileSub;

  String _eventKey = '';
  List<ScoutingRecord> _matchRecords = const [];
  List<PitScoutingRecord> _pitRecords = const [];
  List<ScoutProfile> _profiles = const [];

  /// Detects the current comp and subscribes to its records. Safe to call
  /// again (e.g. when the event override changes) — it tears down the
  /// previous subscriptions and re-detects.
  Future<void> init() async {
    await _cancelSubscriptions();
    if (isClosed) return;
    emit(const LeaderboardLoading());

    final detected = await _schedule.detectCurrentEvent();
    if (isClosed) return;
    if (detected.status == EventStatus.past) {
      emit(const LeaderboardNoEvent());
      return;
    }

    // A second init() may have subscribed while we awaited detection.
    await _cancelSubscriptions();
    _eventKey = detected.key;
    _matchRecords = const [];
    _pitRecords = const [];
    _profiles = const [];

    _matchSub = _scouting.watchForEvent(_eventKey).listen((records) {
      _matchRecords = records;
      _emit();
    });
    _pitSub = _pitScouting.watchForEvent(_eventKey).listen((records) {
      _pitRecords = records;
      _emit();
    });
    _profileSub = _assignments.watchProfiles().listen((profiles) {
      _profiles = profiles;
      _emit();
    });
  }

  void _emit() {
    if (isClosed) return;
    emit(LeaderboardLoaded(
      eventKey: _eventKey,
      entries: buildLeaderboard(
        matchRecords: _matchRecords,
        pitRecords: _pitRecords,
        profiles: _profiles,
        currentUserId: _assignments.currentUserId,
        includeIdleScouts: includeIdleScouts,
      ),
    ));
  }

  Future<void> _cancelSubscriptions() async {
    await _matchSub?.cancel();
    await _pitSub?.cancel();
    await _profileSub?.cancel();
    _matchSub = null;
    _pitSub = null;
    _profileSub = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
