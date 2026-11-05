import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../structure/item_column.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import 'add_expense_screen.dart';

/// The field of one custom column (FR-41), drawn from what the column holds: a required one is marked.
class ColumnValueField extends StatelessWidget {
  /// The field of [column], showing [value], with [error] the word key of what is wrong, answering [onChanged] and choosing a date with [onChooseDate].
  const ColumnValueField({super.key, required this.column, required this.value, required this.error, required this.onChanged, required this.onChooseDate});

  /// The column.
  final ItemColumn column;

  /// Its value so far; empty for none.
  final String value;

  /// The word key of what is wrong with it; empty when nothing is.
  final String error;

  /// Called with the new value.
  final ValueChanged<String> onChanged;

  /// Opens a date picker from the date given, calling back with the date chosen.
  final void Function(DateTime current, ValueChanged<DateTime> onChosen) onChooseDate;

  String _isoOf(DateTime date) => date.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final fieldKey = AddExpenseScreen.columnKey(column.key);
    final label = column.isRequired ? '${column.name} *' : column.name;
    final errorText = error.isEmpty ? null : words.text(error);
    final decoration = InputDecoration(labelText: label, border: const OutlineInputBorder(), errorText: errorText);
    return switch (column.dataType) {
      ColumnDataType.list => DropdownButtonFormField<String>(
        key: fieldKey,
        isExpanded: true,
        initialValue: value.isEmpty ? null : value,
        decoration: decoration,
        items: [for (final option in column.options) DropdownMenuItem(value: option, child: Text(option, overflow: TextOverflow.ellipsis))],
        onChanged: (chosen) => onChanged(chosen ?? ''),
      ),
      ColumnDataType.date => PickerField(
        key: fieldKey,
        label: label,
        value: value.isEmpty ? '' : formatDate(DateTime.parse(value)),
        onTap: () => onChooseDate(value.isEmpty ? DateTime.now() : DateTime.parse(value), (date) => onChanged(_isoOf(date))),
      ),
      ColumnDataType.number || ColumnDataType.amount => TextFormField(key: fieldKey, initialValue: value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: decoration, onChanged: onChanged),
      _ => TextFormField(key: fieldKey, initialValue: value, decoration: decoration, onChanged: onChanged),
    };
  }
}
