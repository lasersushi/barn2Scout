import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/team_rating.dart';
import '../../../data/models/team_strength.dart';
import '../cubit/picklist_cubit.dart';
import '../cubit/ratings_cubit.dart';
import 'picklist_sheet.dart';
import 'team_dossier_sheet.dart';

/// The alliance-picklist board (prototype "Variant A"): every team at the
/// event ranked by TBA-derived strength (no scouting), with swipe-to-pick /
/// swipe-to-veto and a consistency dot. Tap a row for the full dossier; the
/// header row manages multiple named lists and opens the ordered picks sheet.
class PicklistPage extends StatelessWidget {
  const PicklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RatingsCubit, RatingsState>(
      builder: (context, state) => switch (state) {
        RatingsLoading() => const Center(child: CircularProgressIndicator()),
        RatingsNoEvent() => const _NoEventState(),
        RatingsEmpty() => const _EmptyState(),
        RatingsError s => _ErrorState(message: s.message),
        RatingsLoaded s => _Board(teams: s.teams),
      },
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.teams});

  final List<TeamStrength> teams;

  @override
  Widget build(BuildContext context) {
    // Teams arrive sorted by blend desc; the top score scales the bars.
    final maxBlend = teams.isEmpty ? 1.0 : teams.first.blend.clamp(1.0, 1e9);

    return BlocBuilder<PicklistCubit, PicklistState>(
      builder: (context, pick) {
        return Column(
          children: [
            _ListBar(state: pick, teams: teams),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: teams.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _PickRow(
                  strength: teams[i],
                  rank: i + 1,
                  status: pick.statusOf(teams[i].team),
                  maxBlend: maxBlend.toDouble(),
                  totalTeams: teams.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// List selector + management + the "View picks" button.
class _ListBar extends StatelessWidget {
  const _ListBar({required this.state, required this.teams});

  final PicklistState state;
  final List<TeamStrength> teams;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PicklistCubit>();
    final pickCount = state.active.picks.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: state.activeId,
                items: [
                  for (final l in state.lists)
                    DropdownMenuItem(value: l.id, child: Text(l.name)),
                ],
                onChanged: (id) {
                  if (id != null) cubit.selectList(id);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New list',
            onPressed: () async {
              final name = await _promptName(context, 'New picklist');
              if (name != null) cubit.createList(name);
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'List options',
            onSelected: (choice) async {
              if (choice == 'rename') {
                final name = await _promptName(context, 'Rename list',
                    initial: state.active.name);
                if (name != null) cubit.renameList(state.activeId, name);
              } else if (choice == 'delete') {
                final ok = await _confirmDelete(context, state.active.name);
                if (ok) cubit.deleteList(state.activeId);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename list')),
              PopupMenuItem(value: 'delete', child: Text('Delete list')),
            ],
          ),
          const SizedBox(width: 4),
          FilledButton.tonalIcon(
            onPressed: () => showPicklistSheet(context, teams),
            icon: const Icon(Icons.list_alt, size: 18),
            label: Text('Picks ($pickCount)'),
          ),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.strength,
    required this.rank,
    required this.status,
    required this.maxBlend,
    required this.totalTeams,
  });

  final TeamStrength strength;
  final int rank;
  final PickStatus status;
  final double maxBlend;
  final int totalTeams;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<PicklistCubit>();
    final r = strength.rating;
    final dnp = status == PickStatus.veto;
    final picked = status == PickStatus.picked;
    final mine = r.team == AppConfig.myTeamNumber;

    return Dismissible(
      key: ValueKey(r.team),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          picked ? cubit.clear(r.team) : cubit.pick(r.team);
        } else {
          dnp ? cubit.clear(r.team) : cubit.veto(r.team);
        }
        return false; // never actually dismiss — just toggle state
      },
      background: _swipeBg(Colors.green.shade600, Icons.check,
          picked ? 'UNPICK' : 'PICK',
          left: true),
      secondaryBackground: _swipeBg(
          Colors.red.shade600, Icons.block, dnp ? 'UNVETO' : 'VETO',
          left: false),
      child: Opacity(
        opacity: dnp ? 0.45 : 1,
        child: InkWell(
          onTap: () => TeamDossierSheet.show(
            context,
            strength: strength,
            rank: rank,
            totalTeams: totalTeams,
          ),
          child: Container(
            color: picked
                ? Colors.green.withValues(alpha: 0.10)
                : mine
                    ? cs.primaryContainer.withValues(alpha: 0.30)
                    : null,
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Team ${r.team}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration:
                                  dnp ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (mine) ...[
                            const SizedBox(width: 6),
                            _Badge(text: 'YOU', color: cs.primary),
                          ],
                          if (picked) ...[
                            const SizedBox(width: 6),
                            _Badge(text: 'PICKED', color: Colors.green.shade700),
                          ],
                          if (dnp) ...[
                            const SizedBox(width: 6),
                            _Badge(text: 'DNP', color: Colors.red.shade700),
                          ],
                          const SizedBox(width: 8),
                          _ReliabilityDot(bucket: strength.reliabilityBucket),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _Bar(
                        frac: strength.blend / maxBlend,
                        fill: cs.primary,
                        track: cs.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _miniStats(r),
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Text(
                      strength.blend.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    Text('rating',
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One-line TBA summary beneath the team name.
  String _miniStats(TeamRating r) {
    final parts = <String>[
      'OPR ${r.opr.toStringAsFixed(0)}',
      'DPR ${r.dpr.toStringAsFixed(0)}',
    ];
    if (r.avgRp != null) parts.add('RP ${r.avgRp!.toStringAsFixed(1)}');
    if (r.rank != null) parts.add('#${r.rank}');
    return parts.join('  ·  ');
  }
}

Widget _swipeBg(Color c, IconData icon, String label, {required bool left}) =>
    Container(
      color: c,
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );

// ─────────────────────────────────────────────────── dialogs + mini-widgets

Future<String?> _promptName(BuildContext context, String title,
    {String? initial}) {
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'List name'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save')),
      ],
    ),
  ).then((v) => (v == null || v.trim().isEmpty) ? null : v.trim());
}

Future<bool> _confirmDelete(BuildContext context, String name) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete "$name"?'),
      content: const Text('This picklist will be removed.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  ).then((v) => v ?? false);
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
            Icon(Icons.event_busy_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('No upcoming competitions.',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Picklist rankings will appear here\nonce your next event is on TBA.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('No TBA ratings yet.',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Once the event has played a few matches, OPR-based\nrankings will appear here.',
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

class _Bar extends StatelessWidget {
  const _Bar({required this.frac, required this.fill, required this.track});

  final double frac;
  final Color fill;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final f = (frac.clamp(0.0, 1.0) * 1000).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          if (f > 0)
            Expanded(flex: f, child: Container(height: 8, color: fill)),
          if (f < 1000)
            Expanded(flex: 1000 - f, child: Container(height: 8, color: track)),
        ],
      ),
    );
  }
}

/// Consistency at a glance: green = steady, amber = variable, red = streaky,
/// grey = not enough matches played to judge.
class _ReliabilityDot extends StatelessWidget {
  const _ReliabilityDot({required this.bucket});

  final int? bucket;

  static const _colors = [Color(0xFF2E7D32), Color(0xFFF9A825), Color(0xFFC62828)];
  static const _labels = ['steady', 'variable', 'streaky'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = bucket == null ? cs.outline : _colors[bucket!];
    final label = bucket == null ? 'n/a' : _labels[bucket!];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
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
