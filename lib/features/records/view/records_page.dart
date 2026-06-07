import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/scouting_record.dart';
import '../../../data/repositories/scouting_repository.dart';
import '../../scouting/view/scouting_form_page.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../sync/cubit/sync_cubit.dart';
import '../cubit/records_cubit.dart';
import '../widgets/new_record_dialog.dart';
import 'qr_scan_page.dart';
import 'record_detail_page.dart';

/// Lists saved scouting records and lets you start a new one.
class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecordsCubit(context.read<ScoutingRepository>()),
      child: const _RecordsView(),
    );
  }
}

class _RecordsView extends StatelessWidget {
  const _RecordsView();

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
                icon: Icon(
                  sync is SyncError
                      ? Icons.sync_problem_outlined
                      : Icons.sync_outlined,
                ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewRecord(context),
        icon: const Icon(Icons.add),
        label: const Text('Scout'),
      ),
      body: BlocBuilder<RecordsCubit, List<ScoutingRecord>>(
        builder: (context, records) {
          if (records.isEmpty) {
            return const Center(
              child: Text(
                'No records yet.\nTap "Scout" to add one.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            itemCount: records.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _RecordTile(record: records[index]),
          );
        },
      ),
    );
  }

  Future<void> _startNewRecord(BuildContext context) async {
    final request = await showDialog<NewRecordRequest>(
      context: context,
      builder: (_) => const NewRecordDialog(),
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

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final ScoutingRecord record;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('MMM d · h:mm a').format(record.timestamp);
    final myName = context.read<SettingsCubit>().state.scouterName;
    final isMine = record.scouterName == myName && myName.isNotEmpty;

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

    if (!isMine) return tile;

    return Dismissible(
      key: ValueKey(record.uuid),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        context.read<ScoutingRepository>().deleteByUuid(record.uuid);
      },
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
