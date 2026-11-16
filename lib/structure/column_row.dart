import 'package:flutter/material.dart';

import '../format/parts_line.dart';
import '../ui/row_menu.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'item_column.dart';
import 'item_columns_screen.dart';
import '../ui/app_color.dart';
import '../ui/drag_handle.dart';

/// One column on the list: its name and what it is, a handle to drag it and a way to change it; a core column shows a lock, and any other is removed by a swipe (redix-api #102).
class ColumnRow extends StatelessWidget {
  /// The row of [column], at [index] of the list, with its controls when [mayChange], calling [onEdit].
  const ColumnRow({super.key, required this.column, required this.index, required this.mayChange, required this.onEdit});

  /// The column this row shows.
  final ItemColumn column;

  /// Its place in the list, for dragging.
  final int index;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

  /// Called when Edit is tapped.
  final VoidCallback onEdit;


  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final details = [
      if (column.isCustom) words.columnsCustom,
      words.text(column.dataType.wordKey),
      if (column.isRequired) words.columnsRequired else words.columnsOptional,
      if (column.showInReports) words.columnsInReports,
    ];
    return ListTile(
      key: ItemColumnsScreen.rowKey(column.id).body,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 0, 4, 0),
      leading: mayChange ? DragHandle(key: ItemColumnsScreen.handleKey(column.id), index: index) : null,
      title: Text(column.name, key: ItemColumnsScreen.nameKey(column.id)),
      subtitle: Text(partsLine(details), key: ItemColumnsScreen.detailsKey(column.id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mayChange)
            rowMenu(ItemColumnsScreen.menuKey(column.id), [rowMenuItem(ItemColumnsScreen.editKey, words.columnsEdit, onEdit)]),
          if (column.isCore)
            Tooltip(
              key: ItemColumnsScreen.coreKey(column.id),
                message: words.columnsCore,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.lock_outline, key: ItemColumnsScreen.lockKey(column.id), color: AppColor.quiet.of(context)),
                ),
              ),
          ],
        ),
    );
  }
}
