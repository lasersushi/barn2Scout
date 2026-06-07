import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/scouting_record.dart';
import '../../../data/models/team_analytics.dart';
import '../../../data/repositories/scouting_repository.dart';

part 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit(ScoutingRepository repo) : super(const AnalyticsLoading()) {
    // Subscribe to the live stream so rankings refresh whenever a record is
    // saved or deleted — no manual reload needed.
    _sub = repo.watchAll().listen(_recompute);
  }

  late final StreamSubscription<List<ScoutingRecord>> _sub;

  void _recompute(List<ScoutingRecord> records) {
    if (records.isEmpty) {
      emit(const AnalyticsEmpty());
      return;
    }

    // Group records by team number, then aggregate each group.
    final byTeam = <int, List<ScoutingRecord>>{};
    for (final r in records) {
      (byTeam[r.teamNumber] ??= []).add(r);
    }

    final teams = byTeam.entries
        .map((e) => TeamAnalytics.aggregate(e.key, e.value))
        .toList()
      ..sort((a, b) => b.composite.compareTo(a.composite));

    emit(AnalyticsLoaded(teams: teams));
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
