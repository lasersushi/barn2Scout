import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pit_scouting_record.dart';
import '../../../data/models/scouting_record.dart';
import '../../../data/repositories/pit_scouting_repository.dart';
import '../../../data/repositories/scouting_repository.dart';
import '../../../data/repositories/sync_repository.dart';
import '../../scouting/view/pit_form_page.dart';
import '../../scouting/view/scouting_form_page.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../sync/cubit/sync_cubit.dart';
import '../cubit/pit_records_cubit.dart';
import '../cubit/records_cubit.dart';
import '../widgets/new_record_dialog.dart';
import 'pit_record_detail_page.dart';
import 'qr_scan_page.dart';
import 'record_detail_page.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (ctx) => RecordsCubit(ctx.read<ScoutingRepository>())),
        BlocProvider(
            create: (ctx) =>
                PitRecordsCubit(ctx.read<PitScoutingRepository>())),
      ],
      child: const _RecordsView(),
    );
  }
}

class _RecordsView extends StatefulWidget {
  const _RecordsView();

  @override
  State<_RecordsView> createState() => _RecordsViewState();
}

class _RecordsViewState extends State<_RecordsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          BlocBuilder<SyncCubit, SyncState>(
            builder: (context, sync) {
              if (sync is SyncInProgress) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return IconButton(
                icon: Icon(sync is SyncError
                    ? Icons.sync_problem_outlined
                    : Icons.sync_outlined),
                tooltip: 'Sync with cloud',
                onPressed: () => context.read<SyncCubit>().syncNow(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR code',
            onPressed: () => QrScanPage.push(context),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.sports_score_outlined), text: 'Match'),
            Tab(icon: Icon(Icons.build_outlined), text: 'Pit'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewRecord(context),
        icon: const Icon(Icons.add),
        label: Text(_tab.index == 0 ? 'Scout' : 'Pit Scout'),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_MatchRecordsList(), _PitRecordsList()],
      ),
    );
  }

  Future<void> _startNewRecord(BuildContext context) async {
    if (_tab.index == 1) {
      // Pit scouting — ask for team only
      final request = await showDialog<NewRecordRequest>(
        context: context,
        builder: (_) => const NewRecordDialog(isPit: true),
      );
      if (request == null || !context.mounted) return;
      await Navigator.of(context).push(
        PitFormPage.route(
          teamNumber: request.teamNumber,
          eventKey: request.eventKey,
          scouterName: request.scouterName,
        ),
      );
    } else {
      final request = await showDialog<NewRecordRequest>(
        context: context,
        builder: (_) => const NewRecordDialog(isPit: false),
      );
      if (request == null || !context.mounted) return;
      await Navigator.of(context).push(
        ScoutingFormPage.route(
          isMatch: request.isMatch,
          teamNumber: request.teamNumber,
          matchNumber: request.matchNumber,
          eventKey: request.eventKey,
          scouterName: request.scouterName,
        ),
      );
    }
  }
}

// ── Match records list ────────────────────────────────────────────────────────

class _MatchRecordsList extends StatelessWidget {
  const _MatchRecordsList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordsCubit, List<ScoutingRecord>>(
      builder: (context, records) {
        if (records.isEmpty) {
          return const Center(
            child: Text(
              'No match records yet.\nTap "Scout" to add one.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) =>
              _MatchRecordTile(record: records[index]),
        );
      },
    );
  }
}

class _MatchRecordTile extends StatelessWidget {
  const _MatchRecordTile({required this.record});

  final ScoutingRecord record;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('MMM d · h:mm a').format(record.timestamp);
    final isAdmin = context.read<AuthCubit>().state is AuthAuthenticatedAdmin || context.read<AuthCubit>().state is AuthAuthenticatedSuperAdmin;

    final tile = ListTile(
      onTap: () => RecordDetailPage.push(context, record),
      leading: CircleAvatar(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text('${record.teamNumber}'),
          ),
        ),
      ),
      title: Text('Team ${record.teamNumber} · Match ${record.matchNumber}'),
      subtitle: Text('${record.scouterName} · $when'),
      trailing: Icon(
        record.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
        color: record.synced
            ? Colors.green
            : Theme.of(context).colorScheme.outline,
      ),
    );

    if (!isAdmin) return tile;

    return Dismissible(
      key: ValueKey(record.uuid),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) =>
          context.read<SyncRepository>().deleteRecord(record.uuid),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: tile,
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text(
          'Team ${record.teamNumber} · Match ${record.matchNumber} will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ── Pit records list ──────────────────────────────────────────────────────────

class _PitRecordsList extends StatelessWidget {
  const _PitRecordsList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PitRecordsCubit, List<PitScoutingRecord>>(
      builder: (context, records) {
        if (records.isEmpty) {
          return const Center(
            child: Text(
              'No pit records yet.\nTap "Pit Scout" to add one.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) =>
              _PitRecordTile(record: records[index]),
        );
      },
    );
  }
}

class _PitRecordTile extends StatelessWidget {
  const _PitRecordTile({required this.record});

  final PitScoutingRecord record;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('MMM d · h:mm a').format(record.timestamp);
    final isAdmin = context.read<AuthCubit>().state is AuthAuthenticatedAdmin || context.read<AuthCubit>().state is AuthAuthenticatedSuperAdmin;

    final tile = ListTile(
      onTap: () => PitRecordDetailPage.push(context, record),
      leading: CircleAvatar(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text('${record.teamNumber}'),
          ),
        ),
      ),
      title: Text('Team ${record.teamNumber} · Pit'),
      subtitle: Text('${record.scouterName} · $when'),
      trailing: Icon(
        record.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
        color: record.synced
            ? Colors.green
            : Theme.of(context).colorScheme.outline,
      ),
    );

    if (!isAdmin) return tile;

    return Dismissible(
      key: ValueKey(record.uuid),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) =>
          context.read<SyncRepository>().deletePitRecord(record.uuid),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: tile,
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete pit record?'),
        content: Text(
          'Pit record for Team ${record.teamNumber} will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
