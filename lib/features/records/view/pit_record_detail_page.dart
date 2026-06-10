import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/pit_scouting_record.dart';
import '../../../data/repositories/sync_repository.dart';
import '../../auth/cubit/auth_cubit.dart';

class PitRecordDetailPage extends StatelessWidget {
  const PitRecordDetailPage({super.key, required this.record});

  final PitScoutingRecord record;

  static Future<void> push(BuildContext context, PitScoutingRecord record) {
    return Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => PitRecordDetailPage(record: record)),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed == true && context.mounted) {
      try {
        await context.read<SyncRepository>().deletePitRecord(record.uuid);
        if (context.mounted) Navigator.of(context).pop();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not delete record. Are you online?'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final when =
        DateFormat('MMM d, yyyy · h:mm a').format(record.timestamp);
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = context.read<AuthCubit>().state is AuthAuthenticatedAdmin || context.read<AuthCubit>().state is AuthAuthenticatedSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text('Team ${record.teamNumber} · Pit'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete record',
              color: scheme.error,
              onPressed: () => _delete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _InfoRow(label: 'Event', value: record.eventKey),
            _InfoRow(label: 'Scouter', value: record.scouterName),
            _InfoRow(label: 'Recorded', value: when),
            _InfoRow(
              label: 'Sync status',
              value: record.synced ? 'Uploaded' : 'Pending upload',
              valueColor:
                  record.synced ? Colors.green : scheme.onSurfaceVariant,
            ),
            if (record.pitData.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _DataCard(data: record.pitData),
            ],
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DataCard(data: {'Notes': record.notes}),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _prettyKey(e.key),
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      _prettyValue(e.value),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  static String _prettyKey(String key) => key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .trim();

  static String _prettyValue(dynamic v) {
    if (v is bool) return v ? 'Yes' : 'No';
    return v.toString();
  }
}
