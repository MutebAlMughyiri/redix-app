import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../structure/item_column.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import '../entries/add_entry_screen.dart';
import '../ui/part_keys.dart';

/// The field of one of an item's columns (FR-41, redix-api #129, R3), drawn from what the column holds: a list a dropdown of its choices, a required one marked.
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

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final fieldKey = AddEntryScreen.columnKey(column.key);
    final label = column.isRequired ? '${column.name} *' : column.name;
    final errorText = error.isEmpty ? null : words.text(error);
    final decoration = InputDecoration(labelText: label, errorText: errorText);
    return switch (column.dataType) {
      ColumnDataType.list => DropdownButtonFormField<String>(
        key: fieldKey,
        isExpanded: true,
        initialValue: value.isEmpty ? null : value,
        decoration: decoration,
        items: [
          for (final choice in column.choices)
            DropdownMenuItem(key: AddEntryScreen.columnOptionKey(column.key, choice.id), value: choice.id, child: Text(choice.name, key: AddEntryScreen.columnOptionKey(column.key, choice.id).label, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (chosen) => onChanged(chosen ?? ''),
      ),
      ColumnDataType.date => PickerField(
        key: fieldKey,
        label: label,
        value: value.isEmpty ? '' : formatDate(DateTime.parse(value)),
        onTap: () => onChooseDate(value.isEmpty ? DateTime.now() : DateTime.parse(value), (date) => onChanged(apiDate(date))),
      ),
      ColumnDataType.number || ColumnDataType.amount => TextFormField(key: fieldKey, initialValue: value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: decoration, onChanged: onChanged),
      _ => TextFormField(key: fieldKey, initialValue: value, decoration: decoration, onChanged: onChanged),
    };
  }
}
