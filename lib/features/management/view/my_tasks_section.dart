import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../scouting/view/pit_form_page.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../cubit/my_tasks_cubit.dart';

class MyTasksSection extends StatelessWidget {
  const MyTasksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyTasksCubit, MyTasksState>(
      builder: (context, state) => switch (state) {
        MyTasksEmpty() => const SizedBox.shrink(),
        MyTasksLoaded s => _Tasks(state: s),
      },
    );
  }
}

class _Tasks extends StatelessWidget {
  const _Tasks({required this.state});

  final MyTasksLoaded state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(
                  state.allDone ? Icons.check_circle : Icons.assignment_ind,
                  size: 18,
                  color: state.allDone ? Colors.green.shade700 : cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'MY PIT TEAMS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  state.allDone
                      ? 'All done'
                      : '${state.remainingCount} to go',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: state.allDone
                        ? Colors.green.shade700
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ...state.tasks.map((task) => _TaskTile(task: task, state: state)),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.state});

  final MyTask task;
  final MyTasksLoaded state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      leading: Icon(
        task.done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: task.done ? Colors.green.shade700 : cs.onSurfaceVariant,
      ),
      title: Text(
        '${task.teamNumber}  ${task.nickname}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: task.done ? TextDecoration.lineThrough : null,
          color: task.done ? cs.onSurfaceVariant : null,
        ),
      ),
      trailing: task.done ? null : const Icon(Icons.chevron_right, size: 20),
      onTap: task.done ? null : () => _startPitScout(context),
    );
  }

  Future<void> _startPitScout(BuildContext context) async {
    final scouterName = context.read<SettingsCubit>().state.scouterName;
    await Navigator.of(context).push(
      PitFormPage.route(
        teamNumber: task.teamNumber,
        eventKey: state.eventKey,
        scouterName: scouterName,
      ),
    );
  }
}
