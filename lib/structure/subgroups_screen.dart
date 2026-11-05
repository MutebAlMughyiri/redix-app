import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/name_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'categories.dart';
import 'category.dart';

/// An item's subgroups (FR-05), such as مواد and دفان, each printed as its own table in the report, in the order dragged here. The item's general group is not shown: it needs nothing from anyone.
class SubgroupsScreen extends StatelessWidget {
  /// The screen of the item [itemId] of [project], changed through [categories].
  const SubgroupsScreen({super.key, required this.itemId, required this.project, required this.categories});

  /// The item whose subgroups these are.
  final String itemId;

  /// The project it belongs to.
  final Project project;

  /// The way to change it.
  final Categories categories;

  /// The screen's route.
  static const path = '/projects/:projectId/items/:itemId/subgroups';

  /// The route of the subgroups of the item [itemId] of the project [projectId].
  static String pathOf(String projectId, String itemId) => '/projects/$projectId/items/$itemId/subgroups';

  /// The line that says what a subgroup is for.
  static const hintKey = Key('subgroups.hint');

  /// The line shown while the item has no subgroups.
  static const emptyKey = Key('subgroups.empty');

  /// The button that adds a subgroup.
  static const addKey = Key('subgroups.add');

  /// The name, in the dialogs that add and rename.
  static const nameKey = NameDialog.nameKey;

  /// The button that saves, in the dialogs that add and rename.
  static const saveKey = ChangeDialog.saveKey;

  /// The row of the subgroup [id].
  static Key rowKey(String id) => Key('subgroups.row.$id');

  /// The handle that drags the subgroup [id].
  static Key handleKey(String id) => Key('subgroups.handle.$id');

  /// The name of the subgroup [id].
  static Key subgroupNameKey(String id) => Key('subgroups.name.$id');

  /// The button that renames the subgroup [id].
  static Key renameKey(String id) => Key('subgroups.rename.$id');

  /// The button that removes the subgroup [id].
  static Key deleteKey(String id) => Key('subgroups.delete.$id');

  void _ask(BuildContext context, {required String title, required String saveLabel, String name = '', required Future<String> Function(String name) onSave}) {
    showDialog<void>(
      context: context,
      builder: (_) => NameDialog(title: title, label: Words.of(context).categoriesSubgroupName, saveLabel: saveLabel, name: name, onSave: onSave),
    );
  }

  void _askToRemove(BuildContext context, Item item, Subgroup subgroup) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.subgroupsDeleteQuestion,
        subject: subgroup.name,
        explanation: words.subgroupsDeleteExplain,
        confirmLabel: words.subgroupsDelete,
        onConfirm: () => showRefusalOf(context, categories.deleteSubgroup(item, subgroup)),
      ),
    );
  }

  Widget _row(BuildContext context, Item item, Subgroup subgroup, int index) {
    final words = Words.of(context);
    return ListTile(
      key: rowKey(subgroup.id),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
      leading: project.mayChangeStructure ? ReorderableDragStartListener(key: handleKey(subgroup.id), index: index, child: const Icon(Icons.drag_indicator)) : null,
      title: Text(subgroup.name, key: subgroupNameKey(subgroup.id)),
      trailing: project.mayChangeStructure
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: renameKey(subgroup.id),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: words.categoriesRename,
                  onPressed: () => _ask(
                    context,
                    title: words.categoriesRename,
                    saveLabel: words.categoriesSave,
                    name: subgroup.name,
                    onSave: (name) => categories.renameSubgroup(item, subgroup, name),
                  ),
                ),
                IconButton(
                  key: deleteKey(subgroup.id),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: words.subgroupsDelete,
                  onPressed: () => _askToRemove(context, item, subgroup),
                ),
              ],
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: categories,
      builder: (context, _) {
        final item = categories.itemOf(itemId);
        return Scaffold(
          appBar: AppBar(title: Text('${words.categoriesSubgroups} · ${item.name}')),
          floatingActionButton: project.mayChangeStructure
              ? FloatingActionButton.extended(
                  key: addKey,
                  icon: const Icon(Icons.add),
                  label: Text(words.subgroupsNew),
                  onPressed: () => _ask(
                    context,
                    title: words.subgroupsNew,
                    saveLabel: words.subgroupsNew,
                    onSave: (name) => categories.addSubgroup(item, name),
                  ),
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(words.categoriesSubgroupsHint, key: hintKey, style: Theme.of(context).textTheme.bodySmall),
              ),
              if (item.namedSubgroups.isEmpty) ListTile(title: Text(words.categoriesNoSubgroups, key: emptyKey)),
              Expanded(
                child: ReorderableListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  buildDefaultDragHandles: false,
                  onReorderItem: (from, to) => showRefusalOf(context, categories.moveSubgroup(item, from, to)),
                  children: [for (final (index, subgroup) in item.namedSubgroups.indexed) _row(context, item, subgroup, index)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
