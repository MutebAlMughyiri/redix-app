// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../ui/row_menu.dart';
import '../ui/bottom_button.dart';
import '../ui/one_field_dialog.dart';
import '../ui/part_keys.dart';
import '../ui/messages.dart';
import '../ui/screen_title.dart';
import '../ui/swipe_to_remove.dart';
import '../words/words.dart';
import 'categories.dart';
import 'item_tables.dart';
import '../ui/drag_handle.dart';
import '../ui/api_list_body.dart';
import '../ui/list_search.dart';
import '../ui/search_scope.dart';
import '../words/word_fill.dart';

/// An item's tables (AC-46.8), in the order its sheet prints them: its general table, each subgroup a person named, and each contract's payments, each with how many approved
/// entries it holds. Dragging a table moves it in the sheet. A named subgroup is added, renamed and removed here; a contract is added in Contracts and only moved here.
class ItemTablesScreen extends StatefulWidget {
  /// The screen of the tables of the item [itemId] of [project], read and changed through [tables]; the item itself comes from [categories].
  const ItemTablesScreen({super.key, required this.itemId, required this.project, required this.categories, required this.tables});

  /// The item whose tables these are.
  final String itemId;

  /// The project it belongs to.
  final Project project;

  /// The structure, for the item's name and type.
  final Categories categories;

  /// The item's tables.
  final ItemTables tables;

  /// The screen's route.
  static const path = '/projects/:projectId/items/:itemId/tables';

  /// The route of the tables of the item [itemId] of the project [projectId].
  static String pathOf(String projectId, String itemId) => '/projects/$projectId/items/$itemId/tables';

  /// The line that says what the order means.
  static const hintKey = Key('tables.hint');

  /// The button that adds a subgroup.
  static const addKey = Key('tables.add');

  /// The row of the table [id].
  static Key rowKey(String id) => Key('tables.row.$id');

  /// The handle that drags the table [id].
  static Key handleKey(String id) => Key('tables.handle.$id');

  /// The name of the table [id].
  static Key tableNameKey(String id) => Key('tables.name.$id');

  /// What the table [id] prints and how many entries it holds.
  static Key detailsKey(String id) => Key('tables.details.$id');

  /// The ⋮ of the named sub-table [id] (redix-app #102: no pencil button).
  static Key menuKey(String id) => Key('tables.menu.$id');

  /// Rename, in a named sub-table's ⋮.
  static const renameKey = Key('tables.rename');

  @override
  State<ItemTablesScreen> createState() => _ItemTablesScreenState();
}

class _ItemTablesScreenState extends State<ItemTablesScreen> {
  @override
  void initState() {
    super.initState();
    widget.tables.loadOnOpen();
  }

  void _ask({required String title, required String saveLabel, String name = '', required Future<String> Function(String name) onSave}) {
    showDialog<void>(
      context: context,
      builder: (_) => OneFieldDialog(title: title, label: Words.of(context).categoriesSubgroupName, saveLabel: saveLabel, name: name, onSave: onSave),
    );
  }

  String _kindOf(ItemTable table, Words words) => words.text(table.kind.wordKeyOf(isRevenue: widget.categories.itemOf(widget.itemId).type.isRevenue));

  Widget _row(ItemTable table, int index) {
    final words = Words.of(context);
    final mayChange = widget.project.mayChangeStructure;
    return SwipeToRemove(
      key: ItemTablesScreen.rowKey(table.id),
      rowKey: ItemTablesScreen.rowKey(table.id),
      mayRemove: mayChange && table.isNamedSubgroup,
      onRemove: () => widget.tables.deleteSubgroup(table),
      child: ListTile(
      key: ItemTablesScreen.rowKey(table.id).body,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
      leading: mayChange ? DragHandle(key: ItemTablesScreen.handleKey(table.id), index: index) : null,
      title: Text(table.name, key: ItemTablesScreen.tableNameKey(table.id)),
      subtitle: Text('${_kindOf(table, words)} · ${table.count}', key: ItemTablesScreen.detailsKey(table.id)),
      trailing: mayChange && table.isNamedSubgroup
          ? rowMenu(ItemTablesScreen.menuKey(table.id), [
              rowMenuItem(
                ItemTablesScreen.renameKey,
                words.categoriesRename,
                () => _ask(title: words.categoriesRename, saveLabel: words.categoriesSave, name: table.name, onSave: (name) => widget.tables.renameSubgroup(table, name)),
              ),
            ])
          : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: widget.tables,
      builder: (context, _) => SearchScope(
        child: Scaffold(
          appBar: AppBar(title: ScreenTitle(words.categoriesTables, subject: widget.categories.itemOf(widget.itemId).name), actions: const [SearchIcons()]),
          bottomNavigationBar: BottomButton(
            buttonKey: ItemTablesScreen.addKey,
            label: words.subgroupsNew,
            onPressed: widget.project.mayChangeStructure && widget.categories.itemOf(widget.itemId).type.takesPurchases
                ? () => _ask(title: words.subgroupsNew, saveLabel: words.subgroupsNew, onSave: widget.tables.addSubgroup)
                : null,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(words.categoriesTablesHint, key: ItemTablesScreen.hintKey, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Expanded(
                child: ApiListBody<ItemTable>(
                  list: widget.tables,
                  emptyText: words.categoriesNoTableMatch,
                  search: ListSearch(hint: words.commonSearchIn.fill([words.categoriesTables]), textOf: (table) => table.name),
                  itemBuilder: (table) => _row(table, widget.tables.all.indexOf(table)),
                  listOf: (rows) => ReorderableListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    buildDefaultDragHandles: false,
                    onReorderItem: (from, to) => showRefusalOf(context, widget.tables.move(from, to)),
                    children: rows,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
