import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/match_bet.dart';
import '../../../data/models/tba_match.dart';
import '../cubit/points_cubit.dart';
import '../points.dart';

/// Asks how many points to stake on [side] in [match]. Pops the stake, or
/// null if cancelled.
class PlaceBetDialog extends StatefulWidget {
  const PlaceBetDialog({
    super.key,
    required this.match,
    required this.side,
    required this.available,
    required this.pool,
  });

  final TbaMatch match;
  final BetSide side;
  final int available;
  final BetPool pool;

  static Future<int?> show(
    BuildContext context, {
    required TbaMatch match,
    required BetSide side,
    required PointsLoaded state,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => PlaceBetDialog(
        match: match,
        side: side,
        available: state.available,
        pool: state.poolFor(match.key),
      ),
    );
  }

  @override
  State<PlaceBetDialog> createState() => _PlaceBetDialogState();
}

class _PlaceBetDialogState extends State<PlaceBetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stake;

  @override
  void initState() {
    super.initState();
    final initial = widget.available < 10 ? widget.available : 10;
    _stake = TextEditingController(text: '$initial');
  }

  @override
  void dispose() {
    _stake.dispose();
    super.dispose();
  }

  String get _sideName => widget.side == BetSide.red ? 'Red' : 'Blue';
  String get _otherName => widget.side == BetSide.red ? 'Blue' : 'Red';

  String? _validate(String? value) {
    final stake = int.tryParse(value?.trim() ?? '');
    if (stake == null) return 'Numbers only';
    if (stake < 1) return 'Bet at least 1 point';
    if (stake > widget.available) return 'You have ${widget.available}';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(int.parse(_stake.text.trim()));
  }

  /// What the stake would return if the match ended with today's pools.
  String _estimate(int? stake) {
    if (stake == null || stake < 1) return '';
    final mine = widget.pool.on(widget.side) + stake;
    final theirs = widget.pool.total - widget.pool.on(widget.side);
    if (theirs == 0) {
      return 'No one has bet $_otherName yet. If it stays that way, '
          'you get your $stake back either way.';
    }
    final win = winningsFor(
      stake: stake,
      winningPool: mine,
      losingPool: theirs,
    );
    return 'If $_sideName wins with today\'s pools: +$win '
        '(you get ${stake + win} back). Pools change until the match starts.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.side == BetSide.red ? Colors.red : Colors.blue;
    final quick = {10, 25, 50, widget.available}
        .where((v) => v > 0 && v <= widget.available)
        .toList()
      ..sort();

    return AlertDialog(
      title: Text('Bet on $_sideName · ${widget.match.label}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pool now: Red ${widget.pool.red} · Blue ${widget.pool.blue}',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stake,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Points to bet',
                helperText: 'You have ${widget.available}',
                border: const OutlineInputBorder(),
              ),
              validator: _validate,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final v in quick)
                  ActionChip(
                    label: Text(v == widget.available ? 'All ($v)' : '$v'),
                    onPressed: () => _stake.text = '$v',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _stake,
              builder: (_, value, _) => Text(
                _estimate(int.tryParse(value.text.trim())),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bets are final.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: _submit,
          child: Text('Bet on $_sideName'),
        ),
      ],
    );
  }
}
