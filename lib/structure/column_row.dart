import 'package:flutter/material.dart';

import '../ui/part_keys.dart';
import '../words/words.dart';
import 'item_column.dart';
import 'item_columns_screen.dart';

/// One column on the list: its name and what it is, a handle to drag it, a way to change it, and a way to delete it unless it is core, when a lock says so instead.
class ColumnRow extends StatelessWidget {
  /// The row of [column], at [index] of the list, with its controls when [mayChange], calling [onEdit] and [onDelete].
  const ColumnRow({super.key, required this.column, required this.index, required this.mayChange, required this.onEdit, required this.onDelete});

  /// The column this row shows.
  final ItemColumn column;

  /// Its place in the list, for dragging.
  final int index;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

  /// Called when Edit is tapped.
  final VoidCallback onEdit;

  /// Called when Delete is tapped.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final colors = Theme.of(context).colorScheme;
    final details = [
      if (column.isCustom) words.columnsCustom,
      words.text(column.dataType.wordKey),
      if (column.isRequired) words.columnsRequired else words.columnsOptional,
      if (column.showInReports) words.columnsInReports,
    ];
    return Card.outlined(
      key: ItemColumnsScreen.rowKey(column.id).card,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: ItemColumnsScreen.rowKey(column.id).body,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 0, 4, 0),
        leading: mayChange ? ReorderableDragStartListener(key: ItemColumnsScreen.handleKey(column.id), index: index, child: Icon(Icons.drag_indicator, key: ItemColumnsScreen.handleKey(column.id).icon)) : null,
        title: Text(column.name, key: ItemColumnsScreen.nameKey(column.id)),
        subtitle: Text(details.join(' · '), key: ItemColumnsScreen.detailsKey(column.id)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mayChange)
              IconButton(key: ItemColumnsScreen.editKey(column.id), icon: Icon(Icons.edit_outlined, key: ItemColumnsScreen.editKey(column.id).icon), tooltip: words.columnsEdit, onPressed: onEdit),
            if (column.isCore)
              Tooltip(
                key: ItemColumnsScreen.coreKey(column.id),
                message: words.columnsCore,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.lock_outline, key: ItemColumnsScreen.lockKey(column.id), color: colors.onSurfaceVariant),
                ),
              )
            else if (mayChange)
              IconButton(
                key: ItemColumnsScreen.deleteKey(column.id),
                icon: Icon(Icons.delete_outline, key: ItemColumnsScreen.deleteKey(column.id).icon, color: colors.error),
                tooltip: words.columnsDelete,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
