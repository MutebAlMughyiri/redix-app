// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../api_list.dart';
import '../auth/session.dart';
import '../entries/entry_tables.dart';
import '../ui/part_keys.dart';

/// The project's tables as «الجداول» ticks them (redix-api #106 R4, D8): every group and contract by category and item, in the order of the report, finished ones included; one
/// the signed-in user does not see is listed only to someone who manages the people, who can tick it back (G2).
class ProjectTables extends ApiList<TableCategory> {
  /// The tables of the project [projectId], seen through [session].
  ProjectTables(Session session, String projectId) : super(session, '/projects/$projectId/tables', 'categories', TableCategory.fromJson);
}

/// «الجداول» under a person's permissions (redix-api #106 D8): each category folded, each of its items ticking all its tables at once, half-ticked while it sees some, and under it
/// its tables, each ticked while the person sees it. What is not ticked, the person does not see: not its entries, not its total. The one list the Permissions screen, the
/// new-person form and صلاحياتي draw.
class TableTicks extends StatelessWidget {
  /// The [categories]' tables under [heading] and [hint], ticked as [sees] says and changed through [onChangedOf], which answers null where they cannot change (صلاحياتي, D9).
  const TableTicks({super.key, required this.heading, required this.hint, required this.categories, required this.sees, required this.onChangedOf});

  /// What the list is called.
  final String heading;

  /// What ticking does, under the heading; empty for none.
  final String hint;

  /// The tables, by category and item.
  final List<TableCategory> categories;

  /// Whether the person sees the table.
  final bool Function(String tableId) sees;

  /// What ticking the tables does: an item's tick ticks all its tables at once; null where they cannot change.
  final ValueChanged<bool>? Function(List<String> tableIds) onChangedOf;

  /// The heading over the tables.
  static const headingKey = Key('tables.heading');

  /// The category [id]'s fold.
  static Key categoryKey(String id) => Key('tables.category.$id');

  /// The item [id]'s tick, which ticks all its tables.
  static Key itemKey(String id) => Key('tables.item.$id');

  /// The table [id]'s tick.
  static Key tableKey(String id) => Key('tables.table.$id');

  Widget _tick(Key key, String title, bool? value, ValueChanged<bool>? change, {double start = 0}) => Padding(
    key: key,
    padding: EdgeInsetsDirectional.only(start: start),
    child: CheckboxListTile(
      key: key.body,
      controlAffinity: ListTileControlAffinity.leading,
      tristate: value == null,
      value: value,
      title: Text(title, key: key.title),
      onChanged: change == null ? null : (ticked) => change(ticked ?? false),
    ),
  );

  Widget _item(TableItem item) {
    final ids = [for (final table in item.tables) table.id];
    final seen = ids.where(sees).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tick(itemKey(item.id), item.name, seen == ids.length ? true : (seen == 0 ? false : null), onChangedOf(ids)),
        for (final table in item.tables) _tick(tableKey(table.id), table.name, sees(table.id), onChangedOf([table.id]), start: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(heading, key: headingKey, style: theme.textTheme.titleSmall),
        ),
        if (hint.isNotEmpty) Text(hint, key: headingKey.subtitle, style: theme.textTheme.bodySmall),
        for (final category in categories)
          ExpansionTile(
            key: categoryKey(category.id),
            tilePadding: EdgeInsets.zero,
            title: Text(category.name, key: categoryKey(category.id).title),
            children: [for (final item in category.items) _item(item)],
          ),
      ],
    );
  }
}
