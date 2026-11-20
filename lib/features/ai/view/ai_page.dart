import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/ai_models.dart';
import '../../schedule/cubit/schedule_cubit.dart';
import '../cubit/ai_access_cubit.dart';
import 'ai_chat_view.dart';
import 'ai_match_brief_list.dart';
import 'ai_team_list.dart';

/// The AI tab. Everyone gets Teams (summaries on a button press); the AI role
/// and admins also get Match briefs and Chat. The server enforces the same
/// split.
class AiPage extends StatelessWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiAccessCubit, AiAccessState>(
      builder: (context, access) {
        final tabs = <(String, Widget)>[
          ('Teams', const AiTeamList()),
          if (access case AiAccessReady(:final access)) ...[
            if (access.can(AiKind.matchBrief))
              ('Match briefs', const AiMatchBriefList()),
            if (access.can(AiKind.chat)) ('Chat', const AiChatView()),
          ],
        ];

        return DefaultTabController(
          // A new controller when the tab count changes (access loaded).
          key: ValueKey(tabs.length),
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('AI'),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<AiAccessCubit>().load();
                    context.read<ScheduleCubit>().load();
                  },
                ),
              ],
              bottom: tabs.length > 1
                  ? TabBar(tabs: [for (final (label, _) in tabs) Tab(text: label)])
                  : null,
            ),
            body: switch (access) {
              AiAccessLoading() =>
                const Center(child: CircularProgressIndicator()),
              AiAccessFailed(:final message) => _AccessError(message: message),
              AiAccessReady() => _EventGate(
                  child: TabBarView(
                    children: [for (final (_, page) in tabs) page],
                  ),
                ),
            },
          ),
        );
      },
    );
  }
}

/// Shows [child] only while there is a current or upcoming event.
class _EventGate extends StatelessWidget {
  const _EventGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) => switch (state) {
        ScheduleInitial() || ScheduleLoading() =>
          const Center(child: CircularProgressIndicator()),
        ScheduleError(:final message) => AiMessage(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load the event",
            body: message,
          ),
        ScheduleLoaded s when s.isPastEvent => const AiMessage(
            icon: Icons.event_busy_outlined,
            title: 'No upcoming competitions',
            body: 'AI features work on the current or next event.',
          ),
        ScheduleLoaded() => child,
      },
    );
  }
}

class _AccessError extends StatelessWidget {
  const _AccessError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AiMessage(
      icon: Icons.cloud_off_outlined,
      title: "AI isn't available right now",
      body: message,
      action: FilledButton(
        onPressed: () => context.read<AiAccessCubit>().load(),
        child: const Text('Retry'),
      ),
    );
  }
}

/// Centered icon + title + body, used for the AI tab's empty and error states.
class AiMessage extends StatelessWidget {
  const AiMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
