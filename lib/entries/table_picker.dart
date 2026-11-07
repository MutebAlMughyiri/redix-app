import 'package:flutter/material.dart';

import '../structure/item_tables.dart';
import '../ui/api_list_body.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import 'entry_tables.dart';

/// The field that chooses the table an expense goes into (redix-app #84), opening a sheet of every table on offer: by category, each item with its general table first and its
/// named tables and contracts under it.
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

  Future<void> _choose(BuildContext context) async {
    final picked = await showModalBottomSheet<EntryTable>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheet) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ApiListBody(
          list: tables,
          emptyText: Words.of(sheet).categoriesEmpty,
          itemBuilder: (category) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.name, style: Theme.of(sheet).textTheme.titleSmall),
              for (final item in category.items) ..._rowsOf(sheet, item),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  /// The item's general table, or its name when it takes no purchase, and under it each of its other tables.
  List<Widget> _rowsOf(BuildContext sheet, TableItem item) {
    final words = Words.of(sheet);
    final general = item.tables.where((table) => table.kind == ItemTableKind.general);
    ListTile row(EntryTable table, String title, {double indent = 16}) => ListTile(
      key: optionKey(table.id),
      contentPadding: EdgeInsetsDirectional.only(start: indent, end: 16),
      title: Text(title),
      subtitle: Text(table.isContract ? words.categoriesTableContract : words.categoriesTablePurchases),
      onTap: () => Navigator.of(sheet).pop(table),
    );
    return [
      if (general.isEmpty) ListTile(title: Text(item.name), enabled: false) else row(general.first, item.name),
      for (final table in item.tables.where((table) => table.kind != ItemTableKind.general)) row(table, table.name, indent: 40),
    ];
  }

  @override
  Widget build(BuildContext context) => PickerField(label: Words.of(context).entriesTable, value: chosen.label, onTap: () => _choose(context));
}
