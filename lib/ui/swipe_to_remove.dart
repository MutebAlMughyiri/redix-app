import 'package:flutter/material.dart';

import '../words/words.dart';
import 'part_keys.dart';
import 'refusal_snack_bar.dart';

/// The one way a row is removed (Muteb, 8 Nov 2026, redix-api #102): swiped from its end toward its start, which turns with the language, past 40% of its width, with no
/// question. Red with a bin and the word Remove shows behind it while it moves. When [onRemove] answers a refusal the row comes back and the refusal shows; where [mayRemove]
/// is false the row does not move.
class SwipeToRemove extends StatelessWidget {
  /// The swipe of the row keyed [rowKey], removing it through [onRemove] while [mayRemove].
  const SwipeToRemove({super.key, required this.rowKey, required this.mayRemove, required this.onRemove, required this.child});

  /// The row's own key; the swipe's is its `swipe` part, and what shows behind it is that part's icon and label.
  final Key rowKey;

  /// Whether the signed-in user may remove it now.
  final bool mayRemove;

  /// Removes it; answers an empty string once removed, otherwise the word key of the refusal.
  final Future<String> Function() onRemove;

  /// The row.
  final Widget child;

  Future<bool> _remove(BuildContext context) async => (await showRefusalOf(context, onRemove())).isEmpty;

  @override
  Widget build(BuildContext context) {
    if (!mayRemove) {
      return child;
    }
    final colors = Theme.of(context).colorScheme;
    final swipe = rowKey.swipe;
    return Dismissible(
      key: swipe,
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      confirmDismiss: (_) => _remove(context),
      background: Container(
        color: colors.errorContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(Icons.delete_outline, key: swipe.icon, color: colors.onErrorContainer),
            Text(Words.of(context).swipeRemove, key: swipe.label, style: TextStyle(color: colors.onErrorContainer, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// The quiet line under a list's title saying its rows are removed by a swipe (redix-api #102, D7).
class SwipeHint extends StatelessWidget {
  /// The hint, keyed by its list's screen.
  const SwipeHint({super.key});

  @override
  Widget build(BuildContext context) => Text(Words.of(context).swipeHint, key: key.label, style: Theme.of(context).textTheme.bodySmall);
}
