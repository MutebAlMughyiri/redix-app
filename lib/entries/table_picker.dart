import 'package:flutter/material.dart';

import '../suppliers/arabic_spelling.dart';
import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import 'entry_tables.dart';
import '../ui/picker_sheet.dart';

/// The field that chooses the table an expense goes into (redix-app #84), opening a sheet of every table on offer: by category, each item with its general table first and its
/// named tables and contracts under it, with a search over the items' and the tables' names.
class TablePicker extends StatelessWidget {
  /// The field showing [chosen], choosing among [tables] and answering [onChanged].
  const TablePicker({super.key, required this.tables, required this.chosen, required this.onChanged});

  /// What is on offer.
  final EntryTables tables;

  /// The table chosen; none yet when its id is empty.
  final EntryTable chosen;

  /// Called with the table chosen.
  final ValueChanged<EntryTable> onChanged;

  /// The choice of the table [id].
  static Key optionKey(String id) => Key('tablePicker.option.$id');

  /// The search field, in the sheet.
  static const searchKey = Key('tablePicker.search');

  /// The line that says nothing matches the search.
  static const noMatchKey = Key('tablePicker.noMatch');

  /// The name of the item [id] that takes no purchase, shown without a table to choose.
  static Key itemKey(String id) => Key('tablePicker.item.$id');

  /// The heading of the category [name].
  static Key categoryKey(String name) => Key('tablePicker.category.$name');

  Future<void> _choose(BuildContext context) async {
    final picked = await showPickerSheet<EntryTable>(context, (_) => _TableSheet(tables: tables));
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) => PickerField(key: key.field, label: Words.of(context).entriesTable, value: chosen.label, onTap: () => _choose(context));
}

/// The sheet of tables, narrowed by what is typed.
class _TableSheet extends StatefulWidget {
  const _TableSheet({required this.tables});

  final EntryTables tables;

  @override
  State<_TableSheet> createState() => _TableSheetState();
}

class _TableSheetState extends State<_TableSheet> {
  var _typed = '';

  /// The tables of [item] the search keeps: all of them when the item's name holds what was typed, otherwise those whose own name does, in one spelling.
  List<EntryTable> _keptOf(TableItem item) {
    bool holds(String name) => sameSpelling(name).contains(_typed);
    return holds(item.name) ? item.tables : item.tables.where((table) => holds(table.name)).toList();
  }

  /// The item's general table, or its name when it takes no purchase, and under it each of its other [kept] tables.
  List<Widget> _rowsOf(TableItem item, List<EntryTable> kept) {
    final words = Words.of(context);
    final general = kept.where((table) => table.isNamedAfterItem);
    ListTile row(EntryTable table, String title, {double indent = 16}) => ListTile(
      key: TablePicker.optionKey(table.id),
      contentPadding: EdgeInsetsDirectional.only(start: indent, end: 16),
      title: Text(title, key: TablePicker.optionKey(table.id).title),
      subtitle: Text(words.text(table.kindWordKey), key: TablePicker.optionKey(table.id).subtitle),
      onTap: () => Navigator.of(context).pop(table),
    );
    return [
      if (general.isEmpty) ListTile(key: TablePicker.itemKey(item.id), title: Text(item.name, key: TablePicker.itemKey(item.id).title), enabled: false) else row(general.first, item.name),
      for (final table in kept.where((table) => !table.isNamedAfterItem)) row(table, table.name, indent: 40),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: TablePicker.searchKey,
                onChanged: (text) => setState(() => _typed = searchable(text)),
                decoration: InputDecoration(prefixIcon: Icon(Icons.search, key: TablePicker.searchKey.icon), hintText: words.entriesTableSearchHint),
              ),
            ),
            ListenableBuilder(
              listenable: widget.tables,
              builder: (context, _) => widget.tables.all.any((category) => category.items.any((item) => _keptOf(item).isNotEmpty)) || widget.tables.all.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(words.entriesNoTableMatch, key: TablePicker.noMatchKey),
                    ),
            ),
            Expanded(
              child: ApiListBody(
                list: widget.tables,
                emptyText: words.categoriesEmpty,
                itemBuilder: (category) {
                  final items = [for (final item in category.items) (item, _keptOf(item))].where((pair) => pair.$2.isNotEmpty).toList();
                  final title = category.name;
                  return items.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, key: TablePicker.categoryKey(title), style: Theme.of(context).textTheme.titleSmall),
                            for (final (item, kept) in items) ..._rowsOf(item, kept),
                          ],
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
