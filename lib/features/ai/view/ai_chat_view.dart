import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/ai_models.dart';
import '../../schedule/cubit/schedule_cubit.dart';
import '../cubit/ai_chat_cubit.dart';

/// Ask-anything chat about the current event. AI role and admins only.
class AiChatView extends StatefulWidget {
  const AiChatView({super.key});

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final schedule = context.read<ScheduleCubit>().state;
    if (schedule is! ScheduleLoaded) return;
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    context.read<AiChatCubit>().send(
          text,
          eventKey: schedule.eventKey,
          ratings: schedule.ratings,
          matches: schedule.allMatches,
        );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<AiChatCubit, AiChatState>(
      listenWhen: (prev, curr) =>
          curr.unsentQuestion != null &&
          prev.unsentQuestion != curr.unsentQuestion,
      listener: (context, state) {
        // Put a failed question back so it can be re-sent.
        if (_input.text.isEmpty) _input.text = state.unsentQuestion!;
      },
      builder: (context, state) {
        _scrollToEnd();
        final empty = state.turns.isEmpty && !state.sending;

        return Column(
          children: [
            _Header(state: state),
            const Divider(height: 1),
            Expanded(
              child: empty
                  ? const _Suggestions()
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final t in state.turns) _Bubble(turn: t),
                        if (state.sending)
                          _Bubble(
                            turn: AiTurn.assistant(
                              (state.reply ?? '').isEmpty ? 'Thinking…' : state.reply!,
                            ),
                            streaming: true,
                          ),
                      ],
                    ),
            ),
            if (state.errorMessage != null)
              Container(
                width: double.infinity,
                color: cs.errorContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(state.errorMessage!,
                    style: TextStyle(color: cs.onErrorContainer)),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask about this event…',
                          counterText: '',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      tooltip: 'Send',
                      onPressed: state.sending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final AiChatState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final asOf = state.dataAsOf;
    final parts = [
      if (asOf != null)
        'Data from ${DateFormat.jm().format(asOf)}'
      else
        'Uses our scouting + TBA stats for this event',
      if (state.omittedReports > 0)
        '${state.omittedReports} older reports left out',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(parts.join('  ·  '),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
          TextButton.icon(
            onPressed: state.sending ? null : context.read<AiChatCubit>().clear,
            icon: const Icon(Icons.add_comment_outlined, size: 18),
            label: const Text('New chat'),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.forum_outlined, size: 48, color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
        const Text(
          'Ask anything about this event',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'For example: "Which teams did scouts say play good defense?" or '
          '"What should we watch for in our next match?"\n\n'
          'Answers are AI-generated from scout notes and TBA stats, and can be '
          'wrong. They are not used in rankings or predictions.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn, this.streaming = false});

  final AiTurn turn;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mine = turn.fromUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          turn.text,
          style: TextStyle(
            color: mine ? cs.onPrimaryContainer : cs.onSurface,
            fontStyle: streaming && turn.text == 'Thinking…'
                ? FontStyle.italic
                : null,
          ),
        ),
      ),
    );
  }
}
