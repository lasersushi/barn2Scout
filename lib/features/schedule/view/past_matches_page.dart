import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/tba_match.dart';
import '../cubit/schedule_cubit.dart';
import '../widgets/match_tile.dart';

/// Played matches from the most recently completed competition.
///
/// Two tabs — "Mine" (Team 751 only) and "All" (every team at the event).
/// Uses [ScheduleCubit]'s [ScheduleLoaded.pastAllMatches], which may come from
/// a different event than the current schedule if 751 is between competitions.
class PastMatchesPage extends StatefulWidget {
  const PastMatchesPage({super.key});

  @override
  State<PastMatchesPage> createState() => _PastMatchesPageState();
}

class _PastMatchesPageState extends State<PastMatchesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    context.read<ScheduleCubit>().load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        final eventLabel = switch (state) {
          ScheduleLoaded s => s.pastEventName,
          _ => 'Past Matches',
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(eventLabel),
            actions: [
              if (state is ScheduleLoaded)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<ScheduleCubit>().load(),
                ),
            ],
            bottom: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Mine'),
                Tab(text: 'All'),
              ],
            ),
          ),
          body: switch (state) {
            ScheduleInitial() || ScheduleLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ScheduleError s => _ErrorView(
                message: s.message,
                onRetry: () => context.read<ScheduleCubit>().load(),
              ),
            ScheduleLoaded s => TabBarView(
                controller: _tabs,
                children: [
                  _MatchList(
                    matches: s.myPastMatches,
                    emptyMessage: 'No played matches for Team 751.',
                    use751Tile: true,
                  ),
                  _MatchList(
                    matches: s.pastMatches,
                    emptyMessage: 'No played matches yet.',
                    use751Tile: false,
                  ),
                ],
              ),
          },
        );
      },
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.matches,
    required this.emptyMessage,
    required this.use751Tile,
  });

  final List<TbaMatch> matches;
  final String emptyMessage;

  /// When true, use the alliance-colored [MatchTile] (for 751's matches).
  /// When false, use [_FullMatchTile] (all teams, red vs blue layout).
  final bool use751Tile;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.separated(
      itemCount: matches.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => use751Tile
          ? MatchTile(match: matches[i]) // no nexus — already played
          : _FullMatchTile(match: matches[i]),
    );
  }
}

/// Red vs blue score tile for the "All" tab.
class _FullMatchTile extends StatelessWidget {
  const _FullMatchTile({required this.match});
  final TbaMatch match;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String teamList(List<String> keys) =>
        keys.map(TbaMatch.displayNumber).join(' · ');

    return ListTile(
      title: Row(
        children: [
          Text(match.label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 3, height: 14,
                color: Colors.red.shade700,
                margin: const EdgeInsets.only(right: 6)),
            Text(teamList(match.redTeams),
                style: const TextStyle(fontSize: 12)),
          ]),
          Row(children: [
            Container(
                width: 3, height: 14,
                color: Colors.blue.shade700,
                margin: const EdgeInsets.only(right: 6)),
            Text(teamList(match.blueTeams),
                style: const TextStyle(fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
