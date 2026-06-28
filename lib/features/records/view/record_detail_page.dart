import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/utils/qr_record_codec.dart';
import '../../../data/models/scouting_record.dart';
import '../../../data/repositories/sync_repository.dart';
import '../../auth/cubit/auth_cubit.dart';

/// Full-screen view of a single scouting record.
///
/// The top section shows a scannable QR code (encoded via [QrRecordCodec]).
/// The bottom section shows a human-readable summary of the record's fields.
class RecordDetailPage extends StatelessWidget {
  const RecordDetailPage({super.key, required this.record});

  final ScoutingRecord record;

  /// Convenience push helper so callers don't need to know the route type.
  static Future<void> push(BuildContext context, ScoutingRecord record) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecordDetailPage(record: record)),
    );
  }

  Future<void> _deleteRecord(BuildContext context) async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed == true && context.mounted) {
      try {
        await context.read<SyncRepository>().deleteRecord(record.uuid);
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
    final qrData = QrRecordCodec.encode(record);
    final when = DateFormat('MMM d, yyyy · h:mm a').format(record.timestamp);
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = context.read<AuthCubit>().state is AuthAuthenticatedAdmin || context.read<AuthCubit>().state is AuthAuthenticatedSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text('Team ${record.teamNumber} · Match ${record.matchNumber}'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete record',
              color: scheme.error,
              onPressed: () => _deleteRecord(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── QR code ──────────────────────────────────────────────────
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 240,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Point another phone\'s scanner at this QR',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),

            // ── Stats summary ─────────────────────────────────────────────
            _InfoRow(label: 'Event', value: record.eventKey),
            _InfoRow(label: 'Scouter', value: record.scouterName),
            _InfoRow(label: 'Recorded', value: when),
            _InfoRow(
              label: 'Sync status',
              value: record.synced ? 'Uploaded' : 'Pending upload',
              valueColor: record.synced ? Colors.green : scheme.onSurfaceVariant,
            ),

            if (record.autoData.isNotEmpty) ...[
              const SizedBox(height: 16),
              _PhaseCard(title: 'Auto', data: record.autoData),
            ],
            if (record.teleopData.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PhaseCard(title: 'Teleop', data: record.teleopData),
            ],
            if (record.endgameData.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PhaseCard(title: 'Endgame', data: record.endgameData),
            ],
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PhaseCard(title: 'Notes', data: {'': record.notes}),
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

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.title, required this.data});
  final String title;
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
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...data.entries.map((e) {
            final value = e.value.toString();
            const valueStyle = TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            );

            // Notes — just show the value.
            if (e.key.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(value, style: const TextStyle(fontSize: 13)),
              );
            }

            final keyText = Text(
              _prettyKey(e.key),
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            );

            // Long free-text answers read better stacked under their label
            // than squeezed into a right-aligned column.
            if (value.length > 40) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    keyText,
                    const SizedBox(height: 2),
                    Text(value, style: valueStyle),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: keyText),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      value,
                      style: valueStyle,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Converts snake_case / camelCase field keys into human-readable labels.
  static String _prettyKey(String key) {
    // camelCase → words
    final spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    // snake_case → words
    return spaced.replaceAll('_', ' ').trim();
  }
}
