import 'package:flutter/material.dart';

import 'part_keys.dart';

/// A screen's main action: one full-width filled button at its bottom, the same on every screen (Muteb, 8 Nov 2026; issue #85).
class BottomButton extends StatelessWidget {
  /// The button keyed [buttonKey], saying [label] beside [icon].
  const BottomButton({required this.buttonKey, required this.label, required this.onPressed, this.icon = Icons.add, super.key});

  /// The button's key; its icon and label take their parts of it.
  final Key buttonKey;

  /// What the button does, in words.
  final String label;

  /// The action; null grays the button, as Flutter's own buttons do.
  final VoidCallback? onPressed;

  /// A plus, unless the action says otherwise.
  final IconData icon;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: FilledButton.icon(key: buttonKey, icon: Icon(icon, key: buttonKey.icon), label: Text(label, key: buttonKey.label), onPressed: onPressed),
    ),
  );
}
