import 'package:flutter/material.dart';

import 'part_keys.dart';

/// A screen's add action in its title bar, for what is added rarely (redix-app #101, #106): a plus beside the title, while [BottomButton] holds a screen's main action.
/// Without the permission it shows grayed, never hidden.
class TitleBarAdd extends StatelessWidget {
  /// The plus keyed [buttonKey], saying [tooltip] when held, doing [onPressed].
  const TitleBarAdd({required this.buttonKey, required this.tooltip, required this.onPressed, super.key});

  /// The button's key; its icon takes its part of it.
  final Key buttonKey;

  /// What adding adds, in words.
  final String tooltip;

  /// The action; null grays the button, as Flutter's own buttons do.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(key: buttonKey, tooltip: tooltip, icon: Icon(Icons.add, key: buttonKey.icon), onPressed: onPressed);
}
