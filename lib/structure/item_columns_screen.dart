import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/bottom_button.dart';
import '../ui/change_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../ui/swipe_to_remove.dart';
import '../words/words.dart';
import 'add_column_dialog.dart';
import 'apply_to_all_dialog.dart';
import 'category.dart';
import 'column_row.dart';
import 'columns.dart';
import 'edit_column_dialog.dart';
import 'item_column.dart';

/// The fields an item asks for (UC-013): this item's own, or the project's default template for its type, each added, renamed, dragged and deleted. A change to the template asks whether
/// it reaches the items that already exist (BR-21).
class ItemColumnsScreen extends StatefulWidget {
  /// The screen of [item] under the category [categoryName] of [project], showing [itemColumns] and [defaultColumns].
  const ItemColumnsScreen({super.key, required this.item, required this.categoryName, required this.project, required this.itemColumns, required this.defaultColumns});

  /// The item.
  final Item item;

  /// The name of its category.
  final String categoryName;

  /// The project it belongs to.
  final Project project;

  /// The item's own columns.
  final Columns itemColumns;

  /// The default template for its type.
  final Columns defaultColumns;

  /// The screen's route.
  static const path = '/projects/:projectId/items/:itemId/columns';

  /// The route of the columns of the item [itemId] of the project [projectId].
  static String pathOf(String projectId, String itemId) => '/projects/$projectId/items/$itemId/columns';

  /// The item's category and type.
  static const itemDetailsKey = Key('columns.itemDetails');

  /// The choice that shows the default template.
  static const templateKey = Key('columns.template');

  /// The choice that shows this item's own columns.
  static const thisItemKey = Key('columns.thisItem');

  /// The line that says what can be done, and what a lock means.
  static const hintKey = Key('columns.hint');

  /// The button that adds a column.
  static const addKey = Key('columns.add');

  /// The name, in the dialogs that add and change.
  static const columnNameKey = Key('columns.columnName');

  /// The type, in the Add column dialog.
  static const dataTypeKey = Key('columns.dataType');

  /// The choices of a list, in the Add column dialog.
  static const choicesKey = Key('columns.choices');

  /// The choices a list has, in the Edit column dialog.
  static const existingChoicesKey = Key('columns.existingChoices');

  /// The choices a list gains, in the Edit column dialog.
  static const newChoicesKey = Key('columns.newChoices');

  /// Whether entry requires it, in the dialogs that add and change.
  static const requiredKey = Key('columns.required');

  /// Whether it prints, in the dialogs that add and change.
  static const showInReportsKey = Key('columns.showInReports');

  /// The button that saves, in the dialogs that add and change.
  static const saveKey = ChangeDialog.saveKey;

  /// The line that says why a change was refused, in the dialogs that add and change.
  static const dialogMessageKey = ChangeDialog.messageKey;

  /// The line saying a column is removed by a swipe (redix-api #102).
  static const swipeHintKey = Key('columns.swipeHint');

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The row of the column [id].
  static Key rowKey(String id) => Key('columns.row.$id');

  /// The handle that drags the column [id].
  static Key handleKey(String id) => Key('columns.handle.$id');

  /// The name of the column [id].
  static Key nameKey(String id) => Key('columns.name.$id');

  /// What the column [id] is.
  static Key detailsKey(String id) => Key('columns.details.$id');

  /// The button that changes the column [id].
  static Key editKey(String id) => Key('columns.edit.$id');

  /// The lock on the core column [id].
  static Key lockKey(String id) => Key('columns.lock.$id');

  /// The choice of the data type [dataType], in the add dialog.
  static Key dataTypeOptionKey(ColumnDataType dataType) => Key('columns.dataTypeOption.${dataType.name}');

  /// The note saying the column [id] is built in.
  static Key coreKey(String id) => Key('columns.core.$id');

  /// The choice of changing the template's columns or this item's.
  static const scopeKey = Key('columns.scope');

  @override
  State<ItemColumnsScreen> createState() => _ItemColumnsScreenState();
}

class _ItemColumnsScreenState extends State<ItemColumnsScreen> {
  var _showsTemplate = false;

  Columns get _columns => _showsTemplate ? widget.defaultColumns : widget.itemColumns;

  @override
  void initState() {
    super.initState();
    _columns.loadOnOpen();
  }

  void _show({required bool template}) {
    setState(() => _showsTemplate = template);
    _columns.load();
  }

  /// Only a change to the template has anything to ask.
  Future<bool> _applyToAll() async =>
      _showsTemplate && (await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => const ApplyToAllDialog()) ?? false);

  Widget _row(ItemColumn column) {
    final columns = _columns;
    return SwipeToRemove(
      key: ItemColumnsScreen.rowKey(column.id),
      rowKey: ItemColumnsScreen.rowKey(column.id),
      mayRemove: widget.project.mayChangeStructure && !column.isCore,
      onRemove: () => _applyToAll().then((applyToAll) => columns.delete(column, applyToAll: applyToAll)),
      child: ColumnRow(
        column: column,
        index: columns.all.indexOf(column),
        mayChange: widget.project.mayChangeStructure,
        onEdit: () => showDialog<void>(
          context: context,
          builder: (_) => EditColumnDialog(column: column, columns: columns, applyToAll: _applyToAll),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final textTheme = Theme.of(context).textTheme;
    final mayChange = widget.project.mayChangeStructure;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.columnsTitle, subject: widget.item.name)),
      bottomNavigationBar: BottomButton(
        buttonKey: ItemColumnsScreen.addKey,
        label: words.columnsNew,
        onPressed: mayChange && !widget.item.type.isRevenue ? () => showDialog<void>(context: context, builder: (_) => AddColumnDialog(columns: _columns, applyToAll: _applyToAll)) : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              [widget.categoryName, words.text(widget.item.type.wordKey), if (widget.item.type.isRevenue) words.columnsRevenueTakesNoColumns].join(' · '),
              key: ItemColumnsScreen.itemDetailsKey,
              style: textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              key: ItemColumnsScreen.scopeKey,
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: true, label: Text(words.columnsTemplate, key: ItemColumnsScreen.templateKey)),
                ButtonSegment(value: false, label: Text(words.columnsThisItem, key: ItemColumnsScreen.thisItemKey)),
              ],
              selected: {_showsTemplate},
              onSelectionChanged: (selected) => _show(template: selected.single),
            ),
          ),
          if (mayChange)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(words.columnsHint, key: ItemColumnsScreen.hintKey, style: textTheme.bodySmall),
                  const SwipeHint(key: ItemColumnsScreen.swipeHintKey),
                ],
              ),
            ),
          Expanded(
            child: ApiListBody(
              list: _columns,
              emptyText: words.columnsEmpty,
              itemBuilder: _row,
              listOf: (rows) => ReorderableListView(
                padding: ApiListBody.padding,
                physics: ApiListBody.physics,
                buildDefaultDragHandles: false,
                onReorderItem: (from, to) => showRefusalOf(context, _applyToAll().then((applyToAll) => _columns.move(from, to, applyToAll: applyToAll))),
                children: rows,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
