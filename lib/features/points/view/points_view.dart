import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/match_bet.dart';
import '../../../data/models/tba_match.dart';
import '../cubit/points_cubit.dart';
import '../points.dart';
import 'open_matches_page.dart';
import 'place_bet_dialog.dart';

/// How many open matches the Points view lists before "See all".
const _kOpenMatchesShown = 5;

/// Points balance, bettable matches, your bets, and standings — the Points
/// half of the Leaderboard tab.
class PointsView extends StatelessWidget {
  const PointsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsCubit, PointsState>(
      builder: (context, state) => switch (state) {
        PointsLoading() => const Center(child: CircularProgressIndicator()),
        PointsNoEvent() => const _NoEventState(),
        PointsError(:final message) => _ErrorState(message: message),
        PointsLoaded s => _Points(state: s),
      },
    );
  }
}

class _Points extends StatelessWidget {
  const _Points({required this.state});

  final PointsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final open = state.openMatches;
    final myBets = state.myBets;
    final standings = state.ledger.standings;

    return RefreshIndicator(
      onRefresh: () => context.read<PointsCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _BalanceCard(state: state),
          if (state.refreshError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${state.refreshError} Showing the last loaded bets.',
                style: TextStyle(fontSize: 12, color: cs.error),
              ),
            ),
          const _SectionHeader('Open matches'),
          if (open.isEmpty)
            const _Hint('No open matches. Betting closes when a match starts.')
          else ...[
            for (final m in open.take(_kOpenMatchesShown)) ...[
              BetMatchTile(match: m, state: state),
              const Divider(height: 1),
            ],
            if (open.length > _kOpenMatchesShown)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextButton(
                    onPressed: () => OpenMatchesPage.push(context),
                    child: Text('See all ${open.length} open matches'),
                  ),
                ),
              ),
          ],
          const _SectionHeader('Your bets'),
          if (myBets.isEmpty)
            const _Hint('No bets yet. Pick an alliance above.')
          else
            for (final r in myBets) ...[
              _MyBetTile(result: r, match: state.matchFor(r.bet.matchKey)),
              const Divider(height: 1),
            ],
          const _SectionHeader('Standings'),
          if (standings.isEmpty)
            const _Hint('No one has points yet. Every report earns points.')
          else
            for (final e in standings) ...[
              _StandingsRow(entry: e),
              const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.state});

  final PointsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = state.me;
    final onCard = cs.onTertiaryContainer;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      color: cs.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.toll, color: onCard),
                const SizedBox(width: 8),
                Text(
                  me == null ? 'Unranked' : 'Rank #${me.rank}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onCard,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  color: onCard,
                  tooltip: 'How points work',
                  onPressed: () => _showRules(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${state.available} points',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: onCard,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              me == null
                  ? 'File a scouting report to earn points to bet with.'
                  : '${me.inPlay} in play · ${me.earned} earned scouting · '
                      '${me.wins}W ${me.losses}L',
              style: TextStyle(
                fontSize: 12,
                color: onCard.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('How points work'),
        content: const SingleChildScrollView(
          child: Text(
            'Earn: match report $kMatchReportPoints points, pit report '
            '$kPitReportPoints points.\n\n'
            'Bet: pick Red or Blue on any match that hasn\'t started. One bet '
            'per match, and bets are final.\n\n'
            'Win: everyone who picked the winner gets their stake back plus a '
            'share of the losing side\'s points, split by how much they bet '
            '(rounded down). Long shots pay more.\n\n'
            'Refunds: ties, and matches where only one side was bet on, give '
            'everyone their stake back.\n\n'
            'Points are separate from XP and start over each competition.',
          ),
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

// ── Open match tile ───────────────────────────────────────────────────────────

/// One bettable match: alliances, the current pool, and Red/Blue bet buttons
/// (or your bet, once placed). Shared with [OpenMatchesPage].
class BetMatchTile extends StatelessWidget {
  const BetMatchTile({super.key, required this.match, required this.state});

  final TbaMatch match;
  final PointsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pool = state.poolFor(match.key);
    final myBet = state.myBetOn(match.key);
    final time = match.predictedTime ?? match.scheduledTime;
    final canBet = state.currentUserId != null && state.available > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                match.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (time != null) ...[
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEE h:mm a').format(time),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
              const Spacer(),
              Text(
                'Pool ${pool.total}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _SideButton(
                  side: BetSide.red,
                  teams: match.redTeams,
                  pool: pool.red,
                  picked: myBet?.bet.side == BetSide.red,
                  onPressed: myBet == null && canBet
                      ? () => _bet(context, BetSide.red)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SideButton(
                  side: BetSide.blue,
                  teams: match.blueTeams,
                  pool: pool.blue,
                  picked: myBet?.bet.side == BetSide.blue,
                  onPressed: myBet == null && canBet
                      ? () => _bet(context, BetSide.blue)
                      : null,
                ),
              ),
            ],
          ),
          if (myBet != null) ...[
            const SizedBox(height: 4),
            Text(
              'You bet ${myBet.bet.stake} on '
              '${myBet.bet.side == BetSide.red ? 'Red' : 'Blue'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _bet(BuildContext context, BetSide side) async {
    final cubit = context.read<PointsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final stake = await PlaceBetDialog.show(
      context,
      match: match,
      side: side,
      state: state,
    );
    if (stake == null) return;
    final error = await cubit.placeBet(match, side, stake);
    messenger.showSnackBar(SnackBar(
      content: Text(error ??
          'Bet $stake on ${side == BetSide.red ? 'Red' : 'Blue'} · '
              '${match.label}'),
    ));
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.side,
    required this.teams,
    required this.pool,
    required this.picked,
    required this.onPressed,
  });

  final BetSide side;
  final List<String> teams;
  final int pool;
  final bool picked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = side == BetSide.red ? Colors.red : Colors.blue;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        // Your pick stays in full color even though the button is disabled.
        disabledForegroundColor: picked ? color : null,
        backgroundColor: picked ? color.withValues(alpha: 0.15) : null,
        side: BorderSide(
          color: color.withValues(alpha: onPressed == null && !picked ? 0.3 : 1),
          width: picked ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      child: Column(
        children: [
          Text(
            teams.map(TbaMatch.displayNumber).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            '$pool bet',
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Your bets ─────────────────────────────────────────────────────────────────

class _MyBetTile extends StatelessWidget {
  const _MyBetTile({required this.result, required this.match});

  final BetResult result;
  final TbaMatch? match;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bet = result.bet;
    final sideName = bet.side == BetSide.red ? 'Red' : 'Blue';
    final (IconData icon, Color color, String label) = switch (result.outcome) {
      BetOutcome.pending => (Icons.hourglass_top, cs.onSurfaceVariant, 'Pending'),
      BetOutcome.won => (Icons.trending_up, Colors.green, '+${result.net}'),
      BetOutcome.lost => (Icons.trending_down, cs.error, '${result.net}'),
      BetOutcome.refunded => (Icons.undo, cs.onSurfaceVariant, 'Refunded'),
    };

    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text('${match?.label ?? bet.matchKey} · ${bet.stake} on $sideName'),
      subtitle: result.refundReason == null
          ? null
          : Text(result.refundReason!),
      trailing: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── Standings ─────────────────────────────────────────────────────────────────

class _StandingsRow extends StatelessWidget {
  const _StandingsRow({required this.entry});

  final PointsEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final e = entry;
    return Container(
      color: e.isMe ? cs.tertiaryContainer.withValues(alpha: 0.30) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${e.rank}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: e.isMe ? cs.tertiary : cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.isMe ? '${e.name} (you)' : e.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${e.wins}W ${e.losses}L · ${e.inPlay} in play',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${e.total} pts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small pieces ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => context.read<PointsCubit>().init(),
              child: const Text('Retry'),
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
            const Text(
              'No active competition.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Points and betting start fresh\nat your next comp.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
