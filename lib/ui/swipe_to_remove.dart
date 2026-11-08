import 'package:flutter/material.dart';

import '../words/words.dart';
import 'part_keys.dart';
import 'refusal_snack_bar.dart';

/// The one way a row is removed (Muteb, 8 Nov 2026, redix-api #102), and the one frame of a row that can be: an outlined card. Where [mayRemove] is true a red bar lies inside
/// the card along its end edge (redix-app #88), and the row is swiped from that edge toward its start, which turns with the language, past 40% of its width, with no question;
/// red with a bin and the word Remove shows behind it while it moves. When [onRemove] answers a refusal the row comes back and the refusal shows. Where [mayRemove] is false
/// the card has no bar and does not move.
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

  /// The red bar's width, in logical pixels (redix-app #88, D2).
  static const barWidth = 4.0;

  Future<bool> _remove(BuildContext context) async => (await showRefusalOf(context, onRemove())).isEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final swipe = rowKey.swipe;
    final framed = Card.outlined(
      key: rowKey.card,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          child,
          if (mayRemove) PositionedDirectional(key: rowKey.bar, end: 0, top: 0, bottom: 0, width: barWidth, child: ColoredBox(color: colors.error)),
        ],
      ),
    );
    if (!mayRemove) {
      return framed;
    }
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
      child: framed,
    );
  }
}
