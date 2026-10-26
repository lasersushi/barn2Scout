import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/match_bet.dart';
import '../../../data/models/pit_scouting_record.dart';
import '../../../data/models/scout_profile.dart';
import '../../../data/models/scouting_record.dart';
import '../../../data/models/tba_match.dart';
import '../../../data/repositories/assignment_repository.dart';
import '../../../data/repositories/bet_repository.dart';
import '../../../data/repositories/pit_scouting_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/scouting_repository.dart';
import '../points.dart';

part 'points_state.dart';

/// Points balances, open matches, and bets for the current comp.
///
/// Reports and profiles stream from Isar; bets (Supabase) and the schedule
/// (TBA) are fetched by [refresh] — on init, after placing a bet, and on
/// pull-to-refresh. Bails on past events like LeaderboardCubit.
class PointsCubit extends Cubit<PointsState> {
  PointsCubit(
    this._scouting,
    this._pitScouting,
    this._assignments,
    this._schedule,
    this._bets,
  ) : super(const PointsLoading());

  final ScoutingRepository _scouting;
  final PitScoutingRepository _pitScouting;
  final AssignmentRepository _assignments;
  final ScheduleRepository _schedule;
  final BetRepository _bets;

  StreamSubscription<List<ScoutingRecord>>? _matchSub;
  StreamSubscription<List<PitScoutingRecord>>? _pitSub;
  StreamSubscription<List<ScoutProfile>>? _profileSub;

  /// Bumped by every [init] so a slow refresh from a previous event can't
  /// overwrite the current one.
  int _generation = 0;

  String _eventKey = '';
  List<ScoutingRecord> _matchRecords = const [];
  List<PitScoutingRecord> _pitRecords = const [];
  List<ScoutProfile> _profiles = const [];
  List<MatchBet>? _betList;
  List<TbaMatch>? _matches;
  String? _refreshError;

  /// Detects the current comp, subscribes to its records, and fetches bets.
  /// Safe to call again (e.g. when the event override changes).
  Future<void> init() async {
    final generation = ++_generation;
    await _cancelSubscriptions();
    if (isClosed) return;
    emit(const PointsLoading());

    final detected = await _schedule.detectCurrentEvent();
    if (isClosed || generation != _generation) return;
    if (detected.status == EventStatus.past) {
      emit(const PointsNoEvent());
      return;
    }

    _eventKey = detected.key;
    _matchRecords = const [];
    _pitRecords = const [];
    _profiles = const [];
    _betList = null;
    _matches = null;
    _refreshError = null;

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

    await refresh();
  }

  /// Re-fetches bets and the TBA schedule. On failure, keeps showing the last
  /// good data with [PointsLoaded.refreshError] set.
  Future<void> refresh() async {
    final generation = _generation;
    final eventKey = _eventKey;
    if (eventKey.isEmpty) return;
    try {
      final (bets, matches) = await (
        _bets.fetchForEvent(eventKey),
        _schedule.getMatches(eventKey),
      ).wait;
      if (isClosed || generation != _generation) return;
      _betList = bets;
      _matches = matches;
      _refreshError = null;
    } catch (e) {
      if (isClosed || generation != _generation) return;
      _refreshError = 'Couldn\'t load bets — check your connection.';
    }
    _emit();
  }

  /// Places a bet for the signed-in scout. Returns an error message to show,
  /// or null on success.
  Future<String?> placeBet(TbaMatch match, BetSide side, int stake) async {
    final s = state;
    if (s is! PointsLoaded) return 'Still loading.';
    if (s.currentUserId == null) return 'Sign in to bet.';
    if (!isOpenForBets(match)) return 'Betting is closed for ${match.label}.';
    if (s.myBetOn(match.key) != null) {
      return 'You already bet on ${match.label}.';
    }
    if (stake <= 0 || stake > s.available) {
      return 'You have ${s.available} points to bet.';
    }

    try {
      await _bets.placeBet(
        eventKey: s.eventKey,
        matchKey: match.key,
        side: side,
        stake: stake,
      );
    } on DuplicateBetException {
      await refresh();
      return 'You already bet on ${match.label}.';
    } catch (_) {
      return 'Couldn\'t place bet — check your connection.';
    }
    await refresh();
    return null;
  }

  void _emit() {
    if (isClosed) return;
    final bets = _betList;
    final matches = _matches;
    if (bets == null || matches == null) {
      // Records stream in before the first fetch finishes; wait for it.
      if (_refreshError != null) emit(PointsError(_refreshError!));
      return;
    }
    final currentUserId = _assignments.currentUserId;
    emit(PointsLoaded(
      eventKey: _eventKey,
      matches: matches,
      currentUserId: currentUserId,
      refreshError: _refreshError,
      ledger: buildPointsLedger(
        matchRecords: _matchRecords,
        pitRecords: _pitRecords,
        profiles: _profiles,
        bets: bets,
        matches: matches,
        currentUserId: currentUserId,
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
