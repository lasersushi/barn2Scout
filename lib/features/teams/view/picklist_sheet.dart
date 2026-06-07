import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/team_strength.dart';
import '../cubit/picklist_cubit.dart';

/// Opens the ordered picks sheet. A modal sheet builds under the root
/// navigator — above the Teams providers — so the [PicklistCubit] is captured
/// here and re-provided to the sheet's subtree.
void showPicklistSheet(BuildContext context, List<TeamStrength> teams) {
  final cubit = context.read<PicklistCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _PicklistSheet(teams: teams),
    ),
  );
}

class _PicklistSheet extends StatelessWidget {
  const _PicklistSheet({required this.teams});

  final List<TeamStrength> teams;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statsByTeam = {for (final t in teams) t.team: t};

    return BlocBuilder<PicklistCubit, PicklistState>(
      builder: (context, state) {
        final cubit = context.read<PicklistCubit>();
        final list = state.active;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(list.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${list.picks.length} picked',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: (list.picks.isEmpty && list.vetoes.isEmpty)
                      ? _emptyHint(cs)
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 32),
                          children: [
                            if (list.picks.isNotEmpty)
                              _sectionLabel(cs, 'PICK ORDER — drag to reorder'),
                            ReorderableListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              onReorderItem: cubit.reorder,
                              children: [
                                for (var i = 0; i < list.picks.length; i++)
                                  _PickTile(
                                    key: ValueKey('pick_${list.picks[i]}'),
                                    rank: i + 1,
                                    team: list.picks[i],
                                    stats: statsByTeam[list.picks[i]],
                                    onRemove: () => cubit.clear(list.picks[i]),
                                  ),
                              ],
                            ),
                            if (list.vetoes.isNotEmpty) ...[
                              _sectionLabel(cs, 'DO NOT PICK'),
                              for (final t in list.vetoes)
                                ListTile(
                                  dense: true,
                                  leading:
                                      const Icon(Icons.block, color: Colors.red),
                                  title: Text('Team $t',
                                      style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough)),
                                  trailing: TextButton(
                                    onPressed: () => cubit.clear(t),
                                    child: const Text('Un-veto'),
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(ColorScheme cs, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: cs.onSurfaceVariant)),
      );

  Widget _emptyHint(ColorScheme cs) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No picks yet.\nSwipe a team right to pick, left to veto.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    super.key,
    required this.rank,
    required this.team,
    required this.stats,
    required this.onRemove,
  });

  final int rank;
  final int team;
  final TeamStrength? stats;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.green.withValues(alpha: 0.08),
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade600,
        child: Text('$rank',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text('Team $team',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: stats == null
          ? const Text('no rating')
          : Text(
              '${stats!.blend.toStringAsFixed(0)} rating · OPR ${stats!.rating.opr.toStringAsFixed(0)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Remove',
            onPressed: onRemove,
          ),
          const Icon(Icons.drag_handle),
        ],
      ),
    );
  }
}
