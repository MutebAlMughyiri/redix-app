import 'package:flutter/material.dart';

import 'app_color.dart';
import 'list_search.dart';
import 'part_keys.dart';

/// The handle a row is dragged into order by, the one way every list draws it. While a search narrows its list the handle stays in its place, grayed, and drags nothing:
/// a drag among rows out of sight would save the wrong order (Muteb, 11 Nov 2026: disabled, not hidden).
class DragHandle extends StatelessWidget {
  /// The handle of the row at [index] among its list's rows.
  const DragHandle({required Key super.key, required this.index});

  /// The row's place among its list's rows.
  final int index;

  @override
  Widget build(BuildContext context) {
    final narrowed = ListNarrowed.of(context);
    return ReorderableDragStartListener(
      index: index,
      enabled: !narrowed,
      child: Icon(Icons.drag_indicator, key: key.icon, color: narrowed ? AppColor.quiet.of(context) : null),
    );
  }
}
