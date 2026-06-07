import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/team_rating.dart';
import '../cubit/ratings_cubit.dart';

/// Official event standings from TBA — teams sorted by their current rank.
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
  const _RankingsList({required this.teams});

  final List<TeamRating> teams;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) return const _NoRankingsYet();
    return ListView.separated(
      itemCount: teams.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _RankRow(rating: teams[i]),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rating});

  final TeamRating rating;

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
              '${r.rank}',
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
            const Text('No upcoming competitions.',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Rankings will appear here once your\nnext event is on TBA.',
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
