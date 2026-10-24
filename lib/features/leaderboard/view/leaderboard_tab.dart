import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/leaderboard_cubit.dart';
import '../xp.dart';

/// Scouter XP standings for the current comp — the Records page's third tab.
class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) => switch (state) {
        LeaderboardLoading() =>
          const Center(child: CircularProgressIndicator()),
        LeaderboardNoEvent() => const _NoEventState(),
        LeaderboardLoaded s => _Leaderboard(state: s),
      },
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.state});

  final LeaderboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final entries = state.entries;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      // Header (your card) + one row per scouter, or the empty hint.
      itemCount: 1 + (entries.isEmpty ? 1 : entries.length),
      separatorBuilder: (_, i) =>
          i == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == 0) return _MyXpCard(me: state.me);
        if (entries.isEmpty) return const _NoReportsYet();
        return LeaderboardRow(entry: entries[i - 1]);
      },
    );
  }
}

// ── Your XP card ──────────────────────────────────────────────────────────────

class _MyXpCard extends StatelessWidget {
  const _MyXpCard({required this.me});

  final LeaderboardEntry? me;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final xp = me?.xp ?? 0;
    final level = levelFor(xp);
    final toNext = kXpPerLevel - xp % kXpPerLevel;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: cs.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  me == null ? 'Unranked' : 'Rank #${me!.rank}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  color: cs.onPrimaryContainer,
                  tooltip: 'How XP works',
                  onPressed: () => _showXpRules(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$xp XP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Level $level',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: levelProgress(xp),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              me == null
                  ? 'File a scouting report to get on the board.'
                  : '$toNext XP to level ${level + 1}',
              style: TextStyle(
                fontSize: 12,
                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showXpRules(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('How XP works'),
        content: const Text(
          'Match report: $kMatchReportXp XP\n'
          'Pit report: $kPitReportXp XP\n'
          'Written notes ($kNotesBonusMinChars+ characters): '
          '+$kNotesBonusXp XP\n\n'
          'Every $kXpPerLevel XP is a new level. XP counts reports filed at '
          'the current event and resets each competition.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ── Ranked rows ───────────────────────────────────────────────────────────────

/// One ranked scouter. Shared with the admin Scout XP page.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({super.key, required this.entry});

  final LeaderboardEntry entry;

  static const _medalColors = {
    1: Color(0xFFD4AF37), // gold
    2: Color(0xFFA8A9AD), // silver
    3: Color(0xFFCD7F32), // bronze
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final e = entry;
    // No medals or rank numbers for scouts who haven't earned any XP.
    final medal = e.xp > 0 ? _medalColors[e.rank] : null;

    return Container(
      color: e.isMe ? cs.primaryContainer.withValues(alpha: 0.30) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: medal != null
                ? Icon(Icons.military_tech, color: medal, size: 28)
                : Text(
                    e.xp > 0 ? '${e.rank}' : '–',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: e.isMe ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (e.isMe) ...[
                      const SizedBox(width: 6),
                      _Badge(text: 'YOU', color: cs.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${e.matchCount} match · ${e.pitCount} pit · '
                  'Level ${e.level}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${e.xp} XP',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _NoReportsYet extends StatelessWidget {
  const _NoReportsYet();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'No reports yet this event.\nScout a match or pit to earn XP.',
        textAlign: TextAlign.center,
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
            const Text(
              'No active competition.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'The XP leaderboard starts fresh\nat your next comp.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
