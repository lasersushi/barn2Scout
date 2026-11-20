import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/tba_match.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../schedule/cubit/schedule_cubit.dart';
import 'ai_output_sheet.dart';
import 'ai_page.dart';

/// Our upcoming matches. Tapping one opens a sheet whose button generates a
/// strategy brief. AI role and admins only.
class AiMatchBriefList extends StatelessWidget {
  const AiMatchBriefList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        if (state is! ScheduleLoaded) return const SizedBox.shrink();
        final matches = state.myUpcomingMatches;

        if (matches.isEmpty) {
          return const AiMessage(
            icon: Icons.sports_esports_outlined,
            title: 'No upcoming matches',
            body: 'Briefs appear here once TBA posts our match schedule.',
          );
        }

        return ListView.separated(
          itemCount: matches.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final m = matches[i];
            final side = m.allianceFor(AppConfig.myTeamKey);
            return ListTile(
              leading: Icon(
                Icons.flag,
                color: side == 'red' ? Colors.red.shade600 : Colors.blue.shade600,
              ),
              title: Text(m.label),
              subtitle: Text(
                'Red ${_teams(m.redTeams)}\nBlue ${_teams(m.blueTeams)}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => AiOutputSheet.show(
                context,
                title: '${m.label} brief',
                subtitle: 'We are $side · ${state.eventName}',
                intro: 'Writes a strategy brief on our partners and opponents '
                    'from our scouting, TBA stats and the match prediction.',
                buttonLabel: 'Generate brief',
                start: () => context.read<AiRepository>().matchBrief(
                      eventKey: state.eventKey,
                      match: m,
                      ratings: state.ratings,
                    ),
              ),
            );
          },
        );
      },
    );
  }

  static String _teams(List<String> keys) =>
      keys.map(TbaMatch.displayNumber).join(', ');
}
