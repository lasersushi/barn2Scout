import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/pit_scouting_repository.dart';
import '../config/pit_config.dart';
import '../cubit/pit_form_cubit.dart';
import '../widgets/field_input.dart';

//TODO: Could use some UI love. Fix overflow isssues.

class PitFormPage extends StatelessWidget {
  const PitFormPage({
    super.key,
    required this.teamNumber,
    required this.eventKey,
    required this.scouterName,
  });

  final int teamNumber;
  final String eventKey;
  final String scouterName;

  static Route<void> route({
    required int teamNumber,
    required String eventKey,
    required String scouterName,
  }) {
    return MaterialPageRoute<void>(
      builder: (context) => PitFormPage(
        teamNumber: teamNumber,
        eventKey: eventKey,
        scouterName: scouterName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PitFormCubit(
        repository: context.read<PitScoutingRepository>(),
        teamNumber: teamNumber,
        eventKey: eventKey,
        scouterName: scouterName,
      ),
      child: _PitFormView(teamNumber: teamNumber),
    );
  }
}

class _PitFormView extends StatelessWidget {
  const _PitFormView({required this.teamNumber});

  final int teamNumber;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PitFormCubit, PitFormState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == PitFormStatus.saved) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pit record saved — Team $teamNumber')),
          );
        } else if (state.status == PitFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Save failed: ${state.error ?? 'unknown'}'),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<PitFormCubit>();
        final saving = state.status == PitFormStatus.saving;

        // Build section-grouped items:
        // [(section header, null) | (null, FieldConfig)]
        final items = <({String? header, dynamic field})>[];
        String? lastSection;
        for (final f in kPitScoutingConfig) {
          if (f.section != null && f.section != lastSection) {
            items.add((header: f.section, field: null));
            lastSection = f.section;
          }
          items.add((header: null, field: f));
        }

        return Scaffold(
          appBar: AppBar(title: Text('Pit Scout — Team $teamNumber')),
          body: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item.header != null) {
                return _SectionHeader(item.header!);
              }
              final field = item.field;
              return FieldInput(
                key: ValueKey(field.key),
                config: field,
                value: state.values[field.key],
                onChanged: (v) => cubit.fieldChanged(field.key, v),
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: saving ? null : cubit.submit,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Saving…' : 'Save'),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
