import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/field_config.dart';

/// Renders a single [FieldConfig] as the right input control, wired to
/// [value] / [onChanged].
///
/// This `switch` is the *only* place the form knows about widget types: to add
/// a new [FieldType], add a case here and the whole form (and every game
/// config) can use it. That's what keeps the form game-agnostic.
class FieldInput extends StatelessWidget {
  const FieldInput({
    super.key,
    required this.config,
    required this.value,
    required this.onChanged,
  });

  final FieldConfig config;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    switch (config.type) {
      case FieldType.counter:
        return _CounterField(
            config: config, value: (value as int?) ?? 0, onChanged: onChanged);
      case FieldType.toggle:
        return _ToggleField(
            config: config,
            value: (value as bool?) ?? false,
            onChanged: onChanged);
      case FieldType.choice:
        return _ChoiceField(
            config: config, value: value as String?, onChanged: onChanged);
      case FieldType.rating:
        return _RatingField(
            config: config, value: (value as int?) ?? 0, onChanged: onChanged);
      case FieldType.stopwatch:
        return _StopwatchField(
            config: config, value: (value as int?) ?? 0, onChanged: onChanged);
      case FieldType.text:
        return _TextField(
            config: config, value: (value as String?) ?? '', onChanged: onChanged);
    }
  }
}

/// Shared card chrome so every field looks consistent.
class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _CounterField extends StatelessWidget {
  const _CounterField(
      {required this.config, required this.value, required this.onChanged});

  final FieldConfig config;
  final int value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final min = config.min ?? 0;
    final max = config.max;
    final canDecrement = value > min;
    final canIncrement = max == null || value < max;
    return _FieldCard(
      child: Row(
        children: [
          Expanded(child: _FieldLabel(config.label)),
          IconButton.filledTonal(
            onPressed: canDecrement ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton.filledTonal(
            onPressed: canIncrement ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _ToggleField extends StatelessWidget {
  const _ToggleField(
      {required this.config, required this.value, required this.onChanged});

  final FieldConfig config;
  final bool value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldCard(
      child: Row(
        children: [
          Expanded(child: _FieldLabel(config.label)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField(
      {required this.config, required this.value, required this.onChanged});

  final FieldConfig config;
  final String? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(config.label),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final option in config.options)
                ChoiceChip(
                  label: Text(option),
                  selected: value == option,
                  onSelected: (_) => onChanged(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingField extends StatelessWidget {
  const _RatingField(
      {required this.config, required this.value, required this.onChanged});

  final FieldConfig config;
  final int value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final max = config.max ?? 5;
    return _FieldCard(
      child: Row(
        children: [
          Expanded(child: _FieldLabel(config.label)),
          for (var star = 1; star <= max; star++)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(star <= value ? Icons.star : Icons.star_border),
              // Tapping the current rating again clears it back to zero.
              onPressed: () => onChanged(value == star ? 0 : star),
            ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField(
      {required this.config, required this.value, required this.onChanged});

  final FieldConfig config;
  final String value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(config.label),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stopwatch — the one field with live-ticking state. Per the project's
// "one pattern everywhere" rule, that state lives in a Cubit (owning the
// Timer), not in a StatefulWidget's setState.
// ---------------------------------------------------------------------------

/// Emits elapsed whole seconds. Start/stop accumulate; reset zeroes.
class StopwatchCubit extends Cubit<int> {
  StopwatchCubit(super.initialSeconds) {
    _accumulated = Duration(seconds: state);
  }

  final Stopwatch _stopwatch = Stopwatch();
  Duration _accumulated = Duration.zero;
  Timer? _ticker;

  bool get isRunning => _stopwatch.isRunning;

  void start() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _ticker =
        Timer.periodic(const Duration(milliseconds: 200), (_) => _emitElapsed());
    _emitElapsed();
  }

  void stop() {
    if (!_stopwatch.isRunning) return;
    _accumulated += _stopwatch.elapsed;
    _stopwatch
      ..stop()
      ..reset();
    _ticker?.cancel();
    _emitElapsed();
  }

  void reset() {
    _stopwatch
      ..stop()
      ..reset();
    _accumulated = Duration.zero;
    _ticker?.cancel();
    emit(0);
  }

  void _emitElapsed() => emit((_accumulated + _stopwatch.elapsed).inSeconds);

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}

class _StopwatchField extends StatelessWidget {
  const _StopwatchField(
      {required this.config, required this.value, required this.onChanged});

  final FieldConfig config;
  final int value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StopwatchCubit(value),
      child: _StopwatchView(config: config, onChanged: onChanged),
    );
  }
}

class _StopwatchView extends StatelessWidget {
  const _StopwatchView({required this.config, required this.onChanged});

  final FieldConfig config;
  final ValueChanged<Object?> onChanged;

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StopwatchCubit, int>(
      builder: (context, seconds) {
        final cubit = context.read<StopwatchCubit>();
        return _FieldCard(
          child: Row(
            children: [
              Expanded(child: _FieldLabel(config.label)),
              Text(_format(seconds),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () {
                  if (cubit.isRunning) {
                    cubit.stop();
                    onChanged(cubit.state); // record final time on stop
                  } else {
                    cubit.start();
                  }
                },
                child: Text(cubit.isRunning ? 'Stop' : 'Start'),
              ),
              IconButton(
                tooltip: 'Reset',
                onPressed: () {
                  cubit.reset();
                  onChanged(0);
                },
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
        );
      },
    );
  }
}
