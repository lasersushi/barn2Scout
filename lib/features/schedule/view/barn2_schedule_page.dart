import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/tba_match.dart';
import '../cubit/schedule_cubit.dart';
import '../widgets/match_tile.dart';

/// Team 751's upcoming matches at the current event, with live Nexus queue status.
/// Past (already-played) matches are hidden here; enable the Past Matches tab
/// in Settings → Tabs to see them.
class Barn2SchedulePage extends StatefulWidget {
  const Barn2SchedulePage({super.key});

  @override
  State<Barn2SchedulePage> createState() => _Barn2SchedulePageState();
}

class _Barn2SchedulePageState extends State<Barn2SchedulePage> {
  @override
  void initState() {
    super.initState();
    context.read<ScheduleCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: switch (state) {
              ScheduleLoaded s when s.isActiveEvent =>
                Text('751 @ ${s.eventName}'),
              ScheduleLoaded s when s.isUpcomingEvent =>
                Text('Next: ${s.eventName}'),
              ScheduleLoaded s => Text('Last: ${s.eventName}'),
              _ => const Text('My Schedule'),
            },
            actions: [
              if (state is ScheduleLoaded)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<ScheduleCubit>().load(),
                ),
            ],
          ),
          body: switch (state) {
            ScheduleInitial() || ScheduleLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            ScheduleError s => _ErrorView(
                message: s.message,
                onRetry: () => context.read<ScheduleCubit>().load(),
              ),
            ScheduleLoaded s => () {
                // For past events (all matches played), fall back to showing all
                // of 751's matches with retrodiction bars (predicted vs actual).
                final displayMatches = s.myUpcomingMatches.isNotEmpty
                    ? s.myUpcomingMatches
                    : s.isPastEvent
                        ? s.myMatches
                        : <TbaMatch>[];

                if (displayMatches.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_available, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'No matches yet.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Check back once the schedule is posted.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: displayMatches.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => MatchTile(
                    match: displayMatches[i],
                    nexus: s.nexusFor(displayMatches[i].label),
                    ratings: s.ratings,
                  ),
                );
              }(),
          },
        );
      },
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
