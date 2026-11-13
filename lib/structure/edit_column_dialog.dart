import 'package:flutter/material.dart';

import '../ui/change_dialog.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'columns.dart';
import 'item_column.dart';
import 'item_columns_screen.dart';

/// Changes a column: its name, and unless it is core whether entry requires it and whether it prints (BR-20). Its type never changes (BR-21).
class EditColumnDialog extends StatefulWidget {
  /// The dialog changing [column] through [columns], asking [applyToAll] whether existing items follow.
  const EditColumnDialog({super.key, required this.column, required this.columns, required this.applyToAll});

  /// The column to change.
  final ItemColumn column;

  /// The way to change it.
  final Columns columns;

  /// Whether the change reaches every item, asked as the change is sent.
  final Future<bool> Function() applyToAll;

  @override
  State<EditColumnDialog> createState() => _EditColumnDialogState();
}

class _EditColumnDialogState extends State<EditColumnDialog> {
  late final _name = TextEditingController(text: widget.column.name);
  late var _isRequired = widget.column.isRequired;
  late var _showInReports = widget.column.showInReports;
  final _newChoices = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _newChoices.dispose();
    super.dispose();
  }

  Future<String> _save() async => widget.columns.edit(
    widget.column,
    _name.text,
    isRequired: _isRequired,
    showInReports: _showInReports,
    newChoices: _newChoices.text.trim().isEmpty ? [] : _newChoices.text.split('\n'),
    applyToAll: await widget.applyToAll(),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final mayChangeMore = !widget.column.isCore;
    return ChangeDialog(
      title: words.columnsEdit,
      saveLabel: words.columnsSave,
      onSave: _save,
      children: [
        TextField(
          key: ItemColumnsScreen.columnNameKey,
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: words.columnsName),
        ),
        SwitchListTile(
          key: ItemColumnsScreen.requiredKey,
          contentPadding: EdgeInsets.zero,
          title: Text(words.columnsRequired, key: ItemColumnsScreen.requiredKey.title),
          value: _isRequired,
          onChanged: mayChangeMore ? (value) => setState(() => _isRequired = value) : null,
        ),
        SwitchListTile(
          key: ItemColumnsScreen.showInReportsKey,
          contentPadding: EdgeInsets.zero,
          title: Text(words.columnsShowInReports, key: ItemColumnsScreen.showInReportsKey.title),
          value: _showInReports,
          onChanged: mayChangeMore ? (value) => setState(() => _showInReports = value) : null,
        ),
        if (widget.column.gainsChoices) ...[
          Text(widget.column.choices.map((choice) => choice.sign == ChoiceSign.none ? choice.name : '${choice.name} (${words.text(choice.sign.wordKey)})').join(' · '), key: ItemColumnsScreen.existingChoicesKey),
          const SizedBox(height: 8),
          TextField(
            key: ItemColumnsScreen.newChoicesKey,
            controller: _newChoices,
            maxLines: 3,
            decoration: InputDecoration(labelText: words.columnsNewChoices),
          ),
        ],
      ],
    );
  }
}
