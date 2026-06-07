import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/scouting_repository.dart';
import '../bloc/scouting_form_bloc.dart';
import '../config/field_config.dart';
import '../config/game_config.dart';
import '../widgets/field_input.dart';

/// Opens the scouting form for one team in one match. Provides the
/// [ScoutingFormBloc] and hosts the [ScoutingFormView].
/// TODO: implement pit scouting
/// TODO: add database, servers, and wifi support
class ScoutingFormPage extends StatelessWidget {
  const ScoutingFormPage({
    super.key,
    required this.teamNumber,
    required this.matchNumber,
    required this.eventKey,
    required this.scouterName,
    required this.isMatch,
    this.config = kDefaultGameConfig,
  });

  final int teamNumber;
  final bool isMatch;
  final int matchNumber;
  final String eventKey;
  final String scouterName;
  final List<FieldConfig> config;

  static Route<void> route({
    required int teamNumber,
    required int matchNumber,
    required String eventKey,
    required String scouterName,
    required bool isMatch,
    List<FieldConfig> config = kDefaultGameConfig,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => ScoutingFormPage(
        teamNumber: teamNumber,
        isMatch: isMatch,
        matchNumber: matchNumber,
        eventKey: eventKey,
        scouterName: scouterName,
        config: config,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScoutingFormBloc(
        repository: context.read<ScoutingRepository>(),
        config: config,
        teamNumber: teamNumber,
        matchNumber: matchNumber,
        eventKey: eventKey,
        scouterName: scouterName,
      ),
      child: const ScoutingFormView(),
    );
  }
}

class ScoutingFormView extends StatelessWidget {
  const ScoutingFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ScoutingFormBloc>();
    return BlocConsumer<ScoutingFormBloc, ScoutingFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.status == FormStatus.saved) {
          final navigator = Navigator.of(context);
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                  'Saved team ${bloc.teamNumber} · match ${bloc.matchNumber}'),
            ),
          );
        } else if (state.status == FormStatus.failure) {
          messenger.showSnackBar(
            SnackBar(content: Text('Save failed: ${state.error ?? 'unknown'}')),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
                'Team ${bloc.teamNumber} · Match ${bloc.matchNumber}'),
          ),
          body: Column(
            children: [
              _PhaseStepper(current: state.phase),
              const Divider(height: 1),
              Expanded(
                child: state.isReview
                    ? _ReviewPanel(bloc: bloc, state: state)
                    : _PhaseFields(bloc: bloc, state: state),
              ),
            ],
          ),
          bottomNavigationBar: _FormNavBar(state: state),
        );
      },
    );
  }
}

/// The auto → teleop → endgame → review progress indicator.
class _PhaseStepper extends StatelessWidget {
  const _PhaseStepper({required this.current});

  final FormPhase current;

  static const _labels = ['Auto', 'Teleop', 'Endgame', 'Review'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= current.index
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                ),
              ),
            _PhaseDot(
              label: _labels[i],
              done: i < current.index,
              active: i == current.index,
            ),
          ],
        ],
      ),
    );
  }
}

class _PhaseDot extends StatelessWidget {
  const _PhaseDot(
      {required this.label, required this.done, required this.active});

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlighted = done || active;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor:
              highlighted ? scheme.primary : scheme.surfaceContainerHighest,
          foregroundColor:
              highlighted ? scheme.onPrimary : scheme.onSurfaceVariant,
          child: done
              ? const Icon(Icons.check, size: 16)
              : Text(label[0]),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// The list of input fields for the current (non-review) phase.
class _PhaseFields extends StatelessWidget {
  const _PhaseFields({required this.bloc, required this.state});

  final ScoutingFormBloc bloc;
  final ScoutingFormState state;

  static const _phaseMap = {
    FormPhase.auto: ScoutPhase.auto,
    FormPhase.teleop: ScoutPhase.teleop,
    FormPhase.endgame: ScoutPhase.endgame,
  };

  @override
  Widget build(BuildContext context) {
    final scoutPhase = _phaseMap[state.phase]!;
    final fields =
        bloc.config.where((field) => field.phase == scoutPhase).toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: fields.length,
      itemBuilder: (context, index) {
        final field = fields[index];
        return FieldInput(
          // Rebuild the right field when its value changes.
          key: ValueKey(field.key),
          config: field,
          value: state.values[field.key],
          onChanged: (value) => bloc.add(FieldChanged(field, value)),
        );
      },
    );
  }
}

/// Review screen: read-only recap of every field, grouped by phase, plus notes.
class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({required this.bloc, required this.state});

  final ScoutingFormBloc bloc;
  final ScoutingFormState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final phase in ScoutPhase.values) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(
              phase.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final field
              in bloc.config.where((field) => field.phase == phase))
            ListTile(
              dense: true,
              title: Text(field.label),
              trailing: Text(
                '${state.values[field.key] ?? '—'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          initialValue: state.notes,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => bloc.add(NotesChanged(value)),
        ),
      ],
    );
  }
}

/// Back / Next-or-Save buttons that drive the FSM.
class _FormNavBar extends StatelessWidget {
  const _FormNavBar({required this.state});

  final ScoutingFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ScoutingFormBloc>();
    final saving = state.status == FormStatus.saving;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isFirstPhase || saving
                    ? null
                    : () => bloc.add(const PhaseReverted()),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: state.isReview
                  ? FilledButton.icon(
                      onPressed:
                          saving ? null : () => bloc.add(const FormSubmitted()),
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(saving ? 'Saving…' : 'Save'),
                    )
                  : FilledButton.icon(
                      onPressed: () => bloc.add(const PhaseAdvanced()),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
