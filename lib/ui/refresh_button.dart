import 'package:flutter/material.dart';

import '../words/words.dart';
import 'part_keys.dart';

/// The title bar's button that reads a screen's data again, for what changed elsewhere, such as an approval on another phone. Pulling the list down does the same.
class RefreshButton extends StatelessWidget {
  /// The button that calls [onRefresh].
  const RefreshButton({super.key, required this.onRefresh});

  /// Reads the screen's data again.
  final Future<void> Function() onRefresh;

  /// The button.
  static const buttonKey = Key('refresh');

  @override
  Widget build(BuildContext context) => IconButton(key: buttonKey, icon: Icon(Icons.refresh, key: buttonKey.icon), tooltip: Words.of(context).commonRefresh, onPressed: onRefresh);
}
