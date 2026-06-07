import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../records/view/records_page.dart';
import '../../schedule/view/barn2_schedule_page.dart';
import '../../schedule/view/other_team_schedules_page.dart';
import '../../settings/view/settings_page.dart';
import '../../teams/view/teams_page.dart';
import '../cubit/navigation_cubit.dart';

/// The app's root scaffold: a bottom navigation bar over the main sections.
///
/// Pages live in an [IndexedStack] so switching tabs preserves each page's
/// state and scroll position instead of rebuilding from scratch.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const List<Widget> _pages = [
    Barn2SchedulePage(),
    OtherTeamSchedulesPage(),
    TeamsPage(),
    RecordsPage(),
    SettingsPage(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'My Schedule'),
    NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Schedules'),
    NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Teams'),
    NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Records'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationCubit(),
      child: BlocBuilder<NavigationCubit, int>(
        builder: (context, index) {
          return Scaffold(
            body: IndexedStack(index: index, children: _pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: context.read<NavigationCubit>().select,
              destinations: _destinations,
            ),
          );
        },
      ),
    );
  }
}
