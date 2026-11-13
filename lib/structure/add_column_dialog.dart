import 'package:flutter/material.dart';

import '../ui/change_dialog.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'columns.dart';
import 'item_column.dart';
import 'item_columns_screen.dart';

/// Asks for a new column: its name, its type, which never changes after, the choices of a list, whether entry requires it, and whether it prints (FR-41).
class AddColumnDialog extends StatefulWidget {
  /// The dialog adding a column to [columns], asking [applyToAll] whether existing items follow.
  const AddColumnDialog({super.key, required this.columns, required this.applyToAll});

  /// The list the column joins.
  final Columns columns;

  /// Whether the change reaches every item, asked as the change is sent.
  final Future<bool> Function() applyToAll;

  @override
  State<AddColumnDialog> createState() => _AddColumnDialogState();
}

class _AddColumnDialogState extends State<AddColumnDialog> {
  final _name = TextEditingController();
  final _choices = TextEditingController();
  var _dataType = ColumnDataType.text;
  var _isRequired = false;
  var _showInReports = true;

  @override
  void dispose() {
    _name.dispose();
    _choices.dispose();
    super.dispose();
  }

  Future<String> _save() async => widget.columns.add(
    _name.text,
    _dataType,
    isRequired: _isRequired,
    showInReports: _showInReports,
    choices: _dataType == ColumnDataType.list ? _choices.text.split('\n') : [],
    applyToAll: await widget.applyToAll(),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.columnsNew,
      saveLabel: words.columnsNew,
      onSave: _save,
      children: [
        TextField(
          key: ItemColumnsScreen.columnNameKey,
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: words.columnsName),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ColumnDataType>(
          key: ItemColumnsScreen.dataTypeKey,
          initialValue: _dataType,
          isExpanded: true,
          decoration: InputDecoration(labelText: words.columnsType),
          items: [for (final dataType in ColumnDataType.offered) DropdownMenuItem(key: ItemColumnsScreen.dataTypeOptionKey(dataType), value: dataType, child: Text(words.text(dataType.wordKey), key: ItemColumnsScreen.dataTypeOptionKey(dataType).label))],
          onChanged: (dataType) => setState(() => _dataType = dataType ?? _dataType),
        ),
        if (_dataType == ColumnDataType.list) ...[
          const SizedBox(height: 16),
          TextField(
            key: ItemColumnsScreen.choicesKey,
            controller: _choices,
            maxLines: 3,
            decoration: InputDecoration(labelText: words.columnsChoices),
          ),
        ],
        SwitchListTile(
          key: ItemColumnsScreen.requiredKey,
          contentPadding: EdgeInsets.zero,
          title: Text(words.columnsRequired, key: ItemColumnsScreen.requiredKey.title),
          value: _isRequired,
          onChanged: (value) => setState(() => _isRequired = value),
        ),
        SwitchListTile(
          key: ItemColumnsScreen.showInReportsKey,
          contentPadding: EdgeInsets.zero,
          title: Text(words.columnsShowInReports, key: ItemColumnsScreen.showInReportsKey.title),
          value: _showInReports,
          onChanged: (value) => setState(() => _showInReports = value),
        ),
      ],
    );
  }
}
