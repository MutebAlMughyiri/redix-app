import 'package:flutter/material.dart';

import 'part_keys.dart';
import 'act_once.dart';

/// A screen's main action: one full-width filled button at its bottom, the same on every screen (Muteb, 8 Nov 2026; issue #85). A screen with two main actions, as
/// Accounts' Transfer and Update (redix-app #89, D21), gives the second as [second]: it sits beside the first, tonal, and the two never run together.
class BottomButton extends StatelessWidget {
  /// The button keyed [buttonKey], saying [label] beside [icon], and [second] beside it when it has one.
  const BottomButton({required this.buttonKey, required this.label, required this.onPressed, this.icon = Icons.add, this.second = BottomAction.none, super.key});

  /// The button's key; its icon and label take their parts of it.
  final Key buttonKey;

  /// What the button does, in words.
  final String label;

  /// The action; null grays the button, as Flutter's own buttons do, and so does a tap until the action ends.
  final TapAction? onPressed;

  /// A plus, unless the action says otherwise.
  final IconData icon;

  /// The action beside it; [BottomAction.none] for a screen with one.
  final BottomAction second;

  /// The bar at the screen's bottom that holds its main actions.
  static const barKey = Key('bottom.bar');

  @override
  Widget build(BuildContext context) => SafeArea(
    key: barKey,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: ActOnce(
        builder: (once) {
          final first = FilledButton.icon(key: buttonKey, icon: Icon(icon, key: buttonKey.icon), label: Text(label, key: buttonKey.label), onPressed: once(onPressed));
          if (second.isNone) {
            return first;
          }
          return Row(
            spacing: 8,
            children: [
              Expanded(child: first),
              Expanded(
                child: FilledButton.tonalIcon(key: second.key, icon: Icon(second.icon, key: second.key.icon), label: Text(second.label, key: second.key.label), onPressed: once(second.onPressed)),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// The second action of a screen's bottom bar.
class BottomAction {
  /// The action keyed [key], saying [label] beside [icon], doing [onPressed]; null grays it, as the first's does.
  const BottomAction({required this.key, required this.label, required this.onPressed, this.icon = Icons.add});

  /// No second action.
  static const none = BottomAction(key: Key('bottom.none'), label: '', onPressed: null);

  /// The button's key; its icon and label take their parts of it.
  final Key key;

  /// What it does, in words.
  final String label;

  /// The action; null grays it.
  final TapAction? onPressed;

  /// Its icon.
  final IconData icon;

  /// True for [none].
  bool get isNone => label.isEmpty;
}
