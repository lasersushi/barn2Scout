import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/scouting_record.dart';
import '../../../data/repositories/scouting_repository.dart';
import '../../scouting/view/scouting_form_page.dart';
import '../cubit/records_cubit.dart';
import '../widgets/new_record_dialog.dart';

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
      appBar: AppBar(title: const Text('Records')),
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
    return ListTile(
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
  }
}
