import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/nexus_pit.dart';
import '../../../data/repositories/picklist_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../cubit/picklist_cubit.dart';
import '../cubit/ratings_cubit.dart';
import '../cubit/teams_cubit.dart';
import 'picklist_page.dart';
import 'rankings_tab.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Recreate the TBA-backed cubits whenever the event override changes, so
    // Rankings and Pit Map reload against the newly selected event. (They live
    // in a kept-alive IndexedStack, so without a changing key they would never
    // reload.)
    final override = context
        .select<SettingsCubit, String?>((c) => c.state.eventKeyOverride);
    return MultiBlocProvider(
      key: ValueKey(override),
      providers: [
        BlocProvider(
          create: (ctx) =>
              TeamsCubit(ctx.read<ScheduleRepository>())..load(),
        ),
        BlocProvider(
          create: (ctx) => RatingsCubit(ctx.read<ScheduleRepository>())..load(),
        ),
        BlocProvider(
          create: (ctx) => PicklistCubit(ctx.read<PicklistRepository>()),
        ),
      ],
      child: _TeamsView(tab: _tab),
    );
  }
}

class _TeamsView extends StatelessWidget {
  const _TeamsView({required this.tab});

  final TabController tab;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Teams'),
            actions: [
              if (state is TeamsLoaded)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<TeamsCubit>().load(),
                ),
            ],
            bottom: TabBar(
              controller: tab,
              tabs: const [
                Tab(text: 'Rankings'),
                Tab(text: 'Pit Map'),
                Tab(text: 'Picklist'),
              ],
            ),
          ),
          body: TabBarView(
            controller: tab,
            children: [
              // ── Rankings ─────────────────────────────────────────────────
              const RankingsTab(),
              // ── Pit Map ─────────────────────────────────────────────────
              switch (state) {
                TeamsInitial() || TeamsLoading() =>
                  const Center(child: CircularProgressIndicator()),
                TeamsError s => Center(child: Text(s.message)),
                TeamsLoaded s => s.pits.isEmpty
                    ? const _NoPitsPlaceholder()
                    : _PitMap(byRow: s.byRow),
              },
              // ── Picklist ─────────────────────────────────────────────────
              const PicklistPage(),
            ],
          ),
        );
      },
    );
  }
}

class _NoPitsPlaceholder extends StatelessWidget {
  const _NoPitsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined,
              size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('Pit map not yet configured',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Check back once event volunteers\nset up pit locations in Nexus.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PitMap extends StatelessWidget {
  const _PitMap({required this.byRow});

  final Map<String, List<NexusPit>> byRow;

  @override
  Widget build(BuildContext context) {
    final rows = byRow.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        return _PitRow(rowLabel: row, pits: byRow[row]!);
      },
    );
  }
}

class _PitRow extends StatelessWidget {
  const _PitRow({required this.rowLabel, required this.pits});

  final String rowLabel;
  final List<NexusPit> pits;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Row $rowLabel',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: pits.map((p) => _PitTile(pit: p)).toList(),
          ),
        ),
        const Divider(height: 20),
      ],
    );
  }
}

class _PitTile extends StatelessWidget {
  const _PitTile({required this.pit});

  final NexusPit pit;

  bool get _isMyTeam => pit.teamNumber == AppConfig.myTeamNumber.toString();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 70,
      height: 70,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _isMyTeam ? cs.primary : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isMyTeam ? cs.primary : cs.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            pit.label,
            style: TextStyle(
              fontSize: 11,
              color: _isMyTeam ? cs.onPrimary : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pit.teamNumber,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _isMyTeam ? cs.onPrimary : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
