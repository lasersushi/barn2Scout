import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/scout_profile.dart';
import '../cubit/management_cubit.dart';

class AssignSheet extends StatefulWidget {
  const AssignSheet({
    super.key,
    required this.scout,
    required this.state,
  });

  final ScoutProfile scout;
  final ManagementLoaded state;

  static Future<void> show(
    BuildContext context, {
    required ScoutProfile scout,
    required ManagementLoaded state,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ManagementCubit>(),
        child: AssignSheet(scout: scout, state: state),
      ),
    );
  }

  @override
  State<AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<AssignSheet> {
  late final Set<int> _selected = widget.state.teamsFor(widget.scout.userId);
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = widget.state;
    final teams = state.teams;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.scout.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_selected.length} of ${teams.length} teams',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: teams.isEmpty
                ? const _NoRoster()
                : ListView.builder(
                    controller: controller,
                    itemCount: teams.length,
                    itemBuilder: (context, i) {
                      final team = teams[i];
                      final owner = state.ownerOf(team.teamNumber);
                      final takenBy = (owner != null &&
                              owner != widget.scout.userId)
                          ? state.displayNameOf(owner)
                          : null;
                      final done = state.scoutedTeams.contains(team.teamNumber);

                      return CheckboxListTile(
                        value: _selected.contains(team.teamNumber),
                        onChanged: (checked) =>
                            _toggle(team.teamNumber, checked, takenBy),
                        title: Text(
                          '${team.teamNumber}  ${team.nickname}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: takenBy != null
                            ? Text(
                                'Covered by $takenBy',
                                style: TextStyle(color: cs.error),
                              )
                            : done
                                ? Text(
                                    'Already scouted',
                                    style: TextStyle(color: cs.onSurfaceVariant),
                                  )
                                : null,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(int team, bool? checked, String? takenBy) async {
    if (checked != true) {
      setState(() => _selected.remove(team));
      return;
    }

    if (takenBy != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Reassign team?'),
          content: Text(
            'Team $team is currently covered by $takenBy. '
            'Assigning it to ${widget.scout.displayName} will remove it from '
            'their list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reassign'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _selected.add(team));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await context
        .read<ManagementCubit>()
        .assign(widget.scout.userId, _selected);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }
}

class _NoRoster extends StatelessWidget {
  const _NoRoster();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text(
              'No team list yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "TBA has not published this event's team list, and nothing was "
              'cached. Try again once you have signal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
