import 'package:flutter/material.dart';

/// Strip shown above team lists before the event's first matches, so nobody
/// mistakes ratings borrowed from each team's previous event for live ones.
class PreCompBanner extends StatelessWidget {
  const PreCompBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: cs.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: cs.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
