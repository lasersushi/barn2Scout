import 'package:flutter/material.dart';

/// What [NewRecordDialog] returns when the user starts a record.
class NewRecordRequest {
  const NewRecordRequest({
    required this.teamNumber,
    required this.matchNumber,
    required this.eventKey,
    required this.scouterName,
  });

  final int teamNumber;
  final int matchNumber;
  final String eventKey;
  final String scouterName;
}

/// Quick manual entry to start a scouting record. Temporary until the schedule
/// view opens the form with team/match/event already known. Uses a
/// [StatefulWidget] only to own the text controllers' lifecycle.
class NewRecordDialog extends StatefulWidget {
  const NewRecordDialog({super.key});

  @override
  State<NewRecordDialog> createState() => _NewRecordDialogState();
}

class _NewRecordDialogState extends State<NewRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _team = TextEditingController();
  final _match = TextEditingController();
  final _scouter = TextEditingController();

  // Placeholder until Settings/Schedule provides the active event key.
  static const _eventKey = '2027casvr';

  @override
  void dispose() {
    _team.dispose();
    _match.dispose();
    _scouter.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NewRecordRequest(
        teamNumber: int.parse(_team.text.trim()),
        matchNumber: int.parse(_match.text.trim()),
        eventKey: _eventKey,
        scouterName: _scouter.text.trim(),
      ),
    );
  }

  String? _requireInt(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (int.tryParse(value.trim()) == null) return 'Numbers only';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New scouting record'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _team,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Team number'),
              validator: _requireInt,
            ),
            TextFormField(
              controller: _match,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Match number'),
              validator: _requireInt,
            ),
            TextFormField(
              controller: _scouter,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Scouter name'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Start')),
      ],
    );
  }
}
