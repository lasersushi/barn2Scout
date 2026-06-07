import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/match_prediction.dart';
import '../../../data/models/tba_match.dart';
import '../../../data/models/team_rating.dart';
import '../cubit/schedule_cubit.dart';
import '../widgets/match_prediction_bar.dart';

/// Full event schedule — all matches, all teams.
/// Highlights any match containing Team 751.
class OtherTeamSchedulesPage extends StatefulWidget {
  const OtherTeamSchedulesPage({super.key});

  @override
  State<OtherTeamSchedulesPage> createState() => _OtherTeamSchedulesPageState();
}

class _OtherTeamSchedulesPageState extends State<OtherTeamSchedulesPage> {
  @override
  void initState() {
    super.initState();
    context.read<ScheduleCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: switch (state) {
              ScheduleLoaded s when s.isActiveEvent => Text(s.eventName),
              ScheduleLoaded s when s.isUpcomingEvent => Text(
                'Next: ${s.eventName}',
              ),
              ScheduleLoaded s => Text('Last: ${s.eventName}'),
              _ => const Text('Schedules'),
            },
          ),
          body: switch (state) {
            ScheduleInitial() || ScheduleLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ScheduleError s => Center(child: Text(s.message)),
            ScheduleLoaded s =>
              s.upcomingMatches.isEmpty
                  ? const Center(child: Text('No upcoming matches found.'))
                  : ListView.separated(
                      itemCount: s.upcomingMatches.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) => _FullMatchTile(
                        match: s.upcomingMatches[i],
                        ratings: s.ratings,
                      ),
                    ),
          },
        );
      },
    );
  }
}

class _FullMatchTile extends StatelessWidget {
  const _FullMatchTile({required this.match, this.ratings});
  final TbaMatch match;
  final Map<int, TeamRating>? ratings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final has751 = match.containsTeam(AppConfig.myTeamKey);

    String teamList(List<String> keys) =>
        keys.map(TbaMatch.displayNumber).join(' · ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: has751 ? cs.primaryContainer.withValues(alpha: 0.3) : null,
          child: ListTile(
            title: Row(
              children: [
                Text(
                  match.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (match.isPlayed)
                  Row(
                    children: [
                      Text(
                        '${match.redScore}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: match.winningAlliance == 'red'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(' – ', style: TextStyle(color: cs.onSurfaceVariant)),
                      Text(
                        '${match.blueScore}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: match.winningAlliance == 'blue'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      color: Colors.red.shade700,
                      margin: const EdgeInsets.only(right: 6),
                    ),
                    Text(
                      teamList(match.redTeams),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      color: Colors.blue.shade700,
                      margin: const EdgeInsets.only(right: 6),
                    ),
                    Text(
                      teamList(match.blueTeams),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (ratings != null && !match.isPlayed)
          MatchPredictionBar(
            prediction: MatchPrediction.compute(match, ratings!),
          ),
      ],
    );
  }
}
