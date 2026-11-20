import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/ai_models.dart';
import '../cubit/ai_access_cubit.dart';
import '../cubit/ai_generate_cubit.dart';

/// Bottom sheet for one AI write-up (team summary, match brief, picklist
/// review). Nothing is generated until the user presses [buttonLabel].
class AiOutputSheet extends StatelessWidget {
  const AiOutputSheet({
    super.key,
    required this.title,
    required this.buttonLabel,
    this.subtitle,
    this.intro,
  });

  final String title;
  final String? subtitle;
  final String buttonLabel;

  /// What the button will do, shown before anything is generated.
  final String? intro;

  /// Opens the sheet. [start] runs only when the button is pressed.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String buttonLabel,
    required Stream<AiEvent> Function() start,
    String? subtitle,
    String? intro,
  }) {
    // The sheet's route sits above the shell, so hand the shell's cubit over.
    final access = context.read<AiAccessCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: access),
          BlocProvider(
            create: (_) =>
                AiGenerateCubit(start, onRemaining: access.updateRemaining),
          ),
        ],
        child: AiOutputSheet(
          title: title,
          subtitle: subtitle,
          buttonLabel: buttonLabel,
          intro: intro,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scroll) => BlocBuilder<AiGenerateCubit, AiGenerateState>(
        builder: (context, state) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.auto_awesome, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: TextStyle(color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            ..._body(context, state),
            const SizedBox(height: 20),
            Text(
              'AI-generated from scout notes and TBA stats. It can be wrong. '
              'Not used in rankings or predictions.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, AiGenerateState state) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<AiGenerateCubit>();

    switch (state.status) {
      case AiGenerateStatus.idle:
        return [
          if (intro != null) Text(intro!),
          const SizedBox(height: 8),
          const _UsageNote(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: cubit.generate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(buttonLabel),
          ),
        ];
      case AiGenerateStatus.streaming:
        return [
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          if (state.text.isEmpty)
            Text('Thinking…', style: TextStyle(color: cs.onSurfaceVariant))
          else
            SelectableText(state.text),
        ];
      case AiGenerateStatus.done:
        return [
          if (state.cached)
            _Chip(
              icon: Icons.bolt,
              text: 'Already generated for this data, so this one was free.',
            ),
          SelectableText(state.text),
          if (state.truncated) ...[
            const SizedBox(height: 8),
            Text('(Cut short at the length limit.)',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ];
      case AiGenerateStatus.failed:
        final retryable = switch (state.errorCode) {
          AiErrorCode.forbidden ||
          AiErrorCode.dailyLimit ||
          AiErrorCode.budgetReached ||
          AiErrorCode.refused ||
          AiErrorCode.badRequest =>
            false,
          _ => true,
        };
        return [
          Row(
            children: [
              Icon(Icons.error_outline, color: cs.error),
              const SizedBox(width: 8),
              Expanded(child: Text(state.errorMessage ?? 'Something went wrong.')),
            ],
          ),
          if (state.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(state.text),
          ],
          if (retryable) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: cubit.generate,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ];
    }
  }
}

/// "N of 20 left today" for limited users; nothing for unlimited ones.
class _UsageNote extends StatelessWidget {
  const _UsageNote();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<AiAccessCubit, AiAccessState>(
      builder: (context, state) {
        if (state is! AiAccessReady || state.access.unlimited) {
          return const SizedBox.shrink();
        }
        final a = state.access;
        return Text(
          'You have ${a.remainingToday ?? '?'} of ${a.dailyLimit ?? '?'} AI '
          'generations left today. If someone already generated this with the '
          'same data, it is free.',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSecondaryContainer),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: cs.onSecondaryContainer)),
          ),
        ],
      ),
    );
  }
}
