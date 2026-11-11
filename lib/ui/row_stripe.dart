import 'package:flutter/material.dart';

import 'app_color.dart';

/// Rows one under another tell apart by their ground (redix-app #108): an even row keeps the ground it sits on, the scheme's surface, and an odd one takes the scheme's
/// next tone, a shade darker in light and a shade lighter in dark, grown from the one seed so it suits every theme. Every card and list tile of an odd row takes it, so the
/// row reads as one; its frame, its colored words and its borders stay as they are.
class RowStripe extends StatelessWidget {
  /// The [index]th row, from 0, of its list: [child]. Its key is drawn from the row's own, so a list whose rows are dragged still tells them apart and the row is still
  /// found by its key, once.
  RowStripe({required this.index, required this.child}) : super(key: ValueKey((RowStripe, child.key ?? index)));

  /// The row's place in its list, from 0.
  final int index;

  /// The row.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (index.isEven) {
      return child;
    }
    final theme = Theme.of(context);
    final ground = AppColor.oddRow.of(context);
    return Theme(
      data: theme.copyWith(cardTheme: theme.cardTheme.copyWith(color: ground), listTileTheme: theme.listTileTheme.copyWith(tileColor: ground)),
      child: child,
    );
  }
}
