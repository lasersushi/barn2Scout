import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/schedule_cubit.dart';
import 'barn2_schedule_page.dart';
import 'other_team_schedules_page.dart';

/// Schedule tab — "My Schedule" (Team 751 only) and "All Schedules" (every
/// match at the event) as sub-tabs, sharing one [ScheduleCubit] load.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    context.read<ScheduleCubit>().load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: switch (state) {
              ScheduleLoaded s when s.isActiveEvent => Text(s.eventName),
              ScheduleLoaded s when s.isUpcomingEvent => Text(
                'Next: ${s.eventName}',
              ),
              ScheduleLoaded s => Text('Last: ${s.eventName}'),
              _ => const Text('Schedule'),
            },
            actions: [
              if (state is ScheduleLoaded)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<ScheduleCubit>().load(),
                ),
            ],
            bottom: TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'My Schedule'),
                Tab(text: 'All Schedules'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: const [Barn2SchedulePage(), OtherTeamSchedulesPage()],
          ),
        );
      },
    );
  }
}
