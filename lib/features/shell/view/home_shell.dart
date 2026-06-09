import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/pit_scouting_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/scouting_repository.dart';
import '../../../data/repositories/sync_repository.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../records/view/records_page.dart';
import '../../schedule/cubit/schedule_cubit.dart';
import '../../schedule/view/barn2_schedule_page.dart';
import '../../schedule/view/other_team_schedules_page.dart';
import '../../schedule/view/past_matches_page.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../settings/view/settings_page.dart';
import '../../sync/cubit/sync_cubit.dart';
import '../../teams/view/teams_page.dart';
import '../cubit/navigation_cubit.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const _inactivityLimit = Duration(hours: 2);
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final inactive = DateTime.now().difference(_pausedAt!);
      if (inactive > _inactivityLimit) {
        context.read<AuthCubit>().signOutDueToInactivity();
      }
      _pausedAt = null;
    }
  }

  static List<Widget> _buildPages(bool showPast) => [
        const Barn2SchedulePage(),
        const OtherTeamSchedulesPage(),
        const TeamsPage(),
        const RecordsPage(),
        const SettingsPage(),
        if (showPast) const PastMatchesPage(),
      ];

  static List<NavigationDestination> _buildDestinations(bool showPast) => [
        const NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event),
          label: 'My Schedule',
        ),
        const NavigationDestination(
          icon: Icon(Icons.schedule_outlined),
          selectedIcon: Icon(Icons.schedule),
          label: 'Schedules',
        ),
        const NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Teams',
        ),
        const NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: 'Records',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
        if (showPast)
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Past',
          ),
      ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider(
          create: (ctx) => ScheduleCubit(ctx.read<ScheduleRepository>()),
        ),
        BlocProvider(
          create: (ctx) => SyncCubit(
            ctx.read<SyncRepository>(),
            ctx.read<ScheduleRepository>(),
            ctx.read<ScoutingRepository>(),
            ctx.read<PitScoutingRepository>(),
          )..syncNow(),
        ),
      ],
      // Reload the schedule (and Past Matches) whenever the event override
      // changes, since the pages live in a kept-alive IndexedStack and would
      // otherwise never re-run their initial load().
      child: BlocListener<SettingsCubit, SettingsState>(
        listenWhen: (prev, curr) =>
            prev.eventKeyOverride != curr.eventKeyOverride,
        listener: (context, _) => context.read<ScheduleCubit>().load(),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (prev, curr) =>
              prev.showPastMatchesTab != curr.showPastMatchesTab,
          builder: (context, settings) {
            final pages = _buildPages(settings.showPastMatchesTab);
            final destinations =
                _buildDestinations(settings.showPastMatchesTab);

            return BlocBuilder<NavigationCubit, int>(
              builder: (context, rawIndex) {
                final index = rawIndex.clamp(0, pages.length - 1);

                return Scaffold(
                  body: IndexedStack(index: index, children: pages),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: index,
                    onDestinationSelected:
                        context.read<NavigationCubit>().select,
                    destinations: destinations,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
