import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/name_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'categories.dart';
import 'item_tables.dart';

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

  /// The name, in the dialogs that add and rename.
  static const nameKey = NameDialog.nameKey;

  /// The button that saves, in the dialogs that add and rename.
  static const saveKey = ChangeDialog.saveKey;

  /// The row of the table [id].
  static Key rowKey(String id) => Key('tables.row.$id');

  /// The handle that drags the table [id].
  static Key handleKey(String id) => Key('tables.handle.$id');

  /// The name of the table [id].
  static Key tableNameKey(String id) => Key('tables.name.$id');

  /// What the table [id] prints and how many entries it holds.
  static Key detailsKey(String id) => Key('tables.details.$id');

  /// The button that renames the subgroup [id].
  static Key renameKey(String id) => Key('tables.rename.$id');

  /// The button that removes the subgroup [id].
  static Key deleteKey(String id) => Key('tables.delete.$id');

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
      builder: (_) => NameDialog(title: title, label: Words.of(context).categoriesSubgroupName, saveLabel: saveLabel, name: name, onSave: onSave),
    );
  }

  void _askToRemove(ItemTable table) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.subgroupsDeleteQuestion,
        subject: table.name,
        explanation: words.subgroupsDeleteExplain,
        confirmLabel: words.subgroupsDelete,
        onConfirm: () => showRefusalOf(context, widget.tables.deleteSubgroup(table)),
      ),
    );
  }

  String _kindOf(ItemTable table, Words words) {
    if (table.kind == ItemTableKind.contract) {
      return words.categoriesTableContract;
    }
    return widget.categories.itemOf(widget.itemId).type.isRevenue ? words.categoriesTableRevenue : words.categoriesTablePurchases;
  }

  Widget _row(ItemTable table, int index) {
    final words = Words.of(context);
    final mayChange = widget.project.mayChangeStructure;
    return ListTile(
      key: ItemTablesScreen.rowKey(table.id),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
      leading: mayChange ? ReorderableDragStartListener(key: ItemTablesScreen.handleKey(table.id), index: index, child: const Icon(Icons.drag_indicator)) : null,
      title: Text(table.name, key: ItemTablesScreen.tableNameKey(table.id)),
      subtitle: Text('${_kindOf(table, words)} · ${table.count}', key: ItemTablesScreen.detailsKey(table.id)),
      trailing: mayChange && table.isNamedSubgroup
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: ItemTablesScreen.renameKey(table.id),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: words.categoriesRename,
                  onPressed: () => _ask(title: words.categoriesRename, saveLabel: words.categoriesSave, name: table.name, onSave: (name) => widget.tables.renameSubgroup(table, name)),
                ),
                IconButton(key: ItemTablesScreen.deleteKey(table.id), icon: const Icon(Icons.delete_outline), tooltip: words.subgroupsDelete, onPressed: () => _askToRemove(table)),
              ],
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: widget.tables,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: ScreenTitle(words.categoriesTables, subject: widget.categories.itemOf(widget.itemId).name)),
        floatingActionButton: widget.project.mayChangeStructure
            ? FloatingActionButton.extended(
                key: ItemTablesScreen.addKey,
                icon: const Icon(Icons.add),
                label: Text(words.subgroupsNew),
                onPressed: () => _ask(title: words.subgroupsNew, saveLabel: words.subgroupsNew, onSave: widget.tables.addSubgroup),
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(words.categoriesTablesHint, key: ItemTablesScreen.hintKey, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: ReorderableListView(
                padding: const EdgeInsets.only(bottom: 96),
                buildDefaultDragHandles: false,
                onReorderItem: (from, to) => showRefusalOf(context, widget.tables.move(from, to)),
                children: [for (final (index, table) in widget.tables.all.indexed) _row(table, index)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
