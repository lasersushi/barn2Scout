import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/tba_match.dart';
import '../../../data/models/team_strength.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../schedule/cubit/schedule_cubit.dart';
import 'ai_output_sheet.dart';
import 'ai_page.dart';

/// Every team at the event. Tapping one opens a sheet whose button generates
/// its scouting summary.
class AiTeamList extends StatelessWidget {
  const AiTeamList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        if (state is! ScheduleLoaded) return const SizedBox.shrink();

        final strengths = {
          for (final s in TeamStrength.rank(state.ratings)) s.team: s,
        };
        final roster = {
          ...strengths.keys,
          for (final m in state.allMatches)
            for (final key in [...m.redTeams, ...m.blueTeams])
              ?int.tryParse(TbaMatch.displayNumber(key)),
        }.toList()
          ..sort();

        if (roster.isEmpty) {
          return const AiMessage(
            icon: Icons.groups_outlined,
            title: 'No team list yet',
            body: 'Teams appear once TBA posts the schedule or the teams have '
                'played an earlier event this season.',
          );
        }

        return ListView.separated(
          itemCount: roster.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final team = roster[i];
            final s = strengths[team];
            return ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(
                team == AppConfig.myTeamNumber ? 'Team $team (us)' : 'Team $team',
              ),
              subtitle: s == null
                  ? null
                  : Text(
                      'Rating ${s.expectedPoints.toStringAsFixed(0)}'
                      '${s.rating.rank != null ? '  ·  #${s.rating.rank}' : ''}',
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AiOutputSheet.show(
                context,
                title: 'Team $team',
                subtitle: 'Scouting summary · ${state.eventName}',
                intro: 'Writes a summary of this team from our match and pit '
                    'scouting, with its TBA stats.',
                buttonLabel: 'Generate summary',
                start: () => context.read<AiRepository>().teamSummary(
                      eventKey: state.eventKey,
                      team: team,
                      ratings: state.ratings,
                    ),
              ),
            );
          },
        );
      },
    );
  }
}
