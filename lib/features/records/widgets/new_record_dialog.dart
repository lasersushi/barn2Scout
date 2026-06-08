import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/schedule_repository.dart';
import '../../../features/settings/cubit/settings_cubit.dart';

class NewRecordRequest {
  const NewRecordRequest({
    required this.teamNumber,
    required this.matchNumber,
    required this.eventKey,
    required this.scouterName,
    required this.isMatch,
  });

  final int teamNumber;
  final int matchNumber;
  final String eventKey;
  final String scouterName;
  final bool isMatch;
}

class NewRecordDialog extends StatefulWidget {
  /// [isPit] pre-selects pit mode and hides the match number field.
  const NewRecordDialog({super.key, this.isPit = false});

  final bool isPit;

  @override
  State<NewRecordDialog> createState() => _NewRecordDialogState();
}

class _NewRecordDialogState extends State<NewRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _team = TextEditingController();
  final _match = TextEditingController();
  late final TextEditingController _scouter;
  late final String _eventKey;
  late bool _isMatch;

  @override
  void initState() {
    super.initState();
    _isMatch = !widget.isPit;
    final settings = context.read<SettingsCubit>().state;
    _scouter = TextEditingController(text: settings.scouterName);
    _eventKey = settings.eventKeyOverride ??
        context.read<ScheduleRepository>().resolvedEventKey;
  }

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
        matchNumber: _isMatch ? int.parse(_match.text.trim()) : 0,
        eventKey: _eventKey,
        scouterName: _scouter.text.trim(),
        isMatch: _isMatch,
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
      title: Text(_isMatch ? 'Match scouting' : 'Pit scouting'),
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
            if (_isMatch)
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
