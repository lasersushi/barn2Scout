import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/team_rating.dart';
import '../cubit/ratings_cubit.dart';
import 'pre_comp_banner.dart';

/// Official event standings from TBA — teams sorted by their current rank.
///
/// Before the event's first matches there are no standings, so it instead
/// lists the roster in expected-points order from each team's previous event
/// this season, under a [PreCompBanner].
class RankingsTab extends StatelessWidget {
  const RankingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RatingsCubit, RatingsState>(
      builder: (context, state) => switch (state) {
        RatingsLoading() => const Center(child: CircularProgressIndicator()),
        RatingsNoEvent() => const _NoEventState(),
        RatingsEmpty() => const _NoRankingsYet(),
        RatingsError s => _ErrorState(message: s.message),
        // Already in expected-points order from TeamStrength.rank.
        RatingsLoaded s when s.isPreComp => _RankingsList(
            teams: [for (final ts in s.teams) ts.rating], preComp: true),
        RatingsLoaded s => _RankingsList(teams: _sortedByRank(s.teams
            .map((ts) => ts.rating)
            .where((r) => r.rank != null)
            .toList())),
      },
    );
  }

  static List<TeamRating> _sortedByRank(List<TeamRating> teams) =>
      teams..sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));
}

class _RankingsList extends StatelessWidget {
  const _RankingsList({required this.teams, this.preComp = false});

  final List<TeamRating> teams;

  /// Ratings are borrowed from earlier events: number rows by projected
  /// position rather than official rank, and say so in a banner.
  final bool preComp;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) return const _NoRankingsYet();
    final list = ListView.separated(
      itemCount: teams.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _RankRow(
        rating: teams[i],
        position: preComp ? i + 1 : teams[i].rank,
      ),
    );
    if (!preComp) return list;

    final year = teams.first.sourceEventKey!.substring(0, 4);
    return Column(
      children: [
        PreCompBanner(
          message: 'Pre-comp: projected from each team\'s latest $year '
              'event. Official rankings appear once quals start.',
        ),
        Expanded(child: list),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rating, required this.position});

  final TeamRating rating;

  /// Official rank, or projected position when pre-comp.
  final int? position;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = rating;
    final mine = r.team == AppConfig.myTeamNumber;

    return Container(
      color: mine ? cs.primaryContainer.withValues(alpha: 0.30) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '${position ?? '—'}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: mine ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Team + record
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Team ${r.team}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 6),
                      _Badge(text: 'YOU', color: cs.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(r),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // OPR + RP column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (r.avgRp != null)
                Text(
                  '${r.avgRp!.toStringAsFixed(2)} RP',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary),
                ),
              Text(
                'OPR ${r.opr.toStringAsFixed(0)}',
                style:
                    TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle(TeamRating r) {
    final parts = <String>[];
    if (r.isPreComp) parts.add('From ${r.sourceEventKey}');
    if (r.record != null) parts.add(r.record!);
    if (r.scoreMean != null) parts.add('Avg ${r.scoreMean!.toStringAsFixed(0)} pts');
    return parts.join('  ·  ');
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _NoRankingsYet extends StatelessWidget {
  const _NoRankingsYet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('Rankings not posted yet.',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Check back after qualification matches begin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoEventState extends StatelessWidget {
  const _NoEventState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('No ongoing competitions.',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Rankings will appear here once your\n event is on TBA.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

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
            FilledButton(
              onPressed: () => context.read<RatingsCubit>().load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
