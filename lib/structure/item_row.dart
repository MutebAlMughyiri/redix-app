import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../projects/project.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'categories.dart';
import 'categories_screen.dart';
import 'category.dart';
import 'name_dialog.dart';
import 'subgroups_screen.dart';

/// One item under its category: its name and type, or that it is disabled, a handle to drag it, and a menu of what can be done to it.
class ItemRow extends StatelessWidget {
  /// The row of [item], at [index] of its category, in [project], changed through [categories].
  const ItemRow({super.key, required this.item, required this.index, required this.project, required this.categories});

  /// The item this row shows.
  final Item item;

  /// Its place in its category, for dragging.
  final int index;

  /// The project it belongs to.
  final Project project;

  /// The way to change it.
  final Categories categories;

  void _askForName(BuildContext context) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => NameDialog(
        title: words.categoriesRename,
        label: words.categoriesItemName,
        saveLabel: words.categoriesSave,
        name: item.name,
        onSave: (name) => categories.renameItem(item, name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final mayChange = project.mayChangeStructure;
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
      leading: mayChange ? ReorderableDragStartListener(key: CategoriesScreen.itemHandleKey(item.id), index: index, child: const Icon(Icons.drag_indicator)) : null,
      title: Text(
        item.name,
        key: CategoriesScreen.itemNameKey(item.id),
        style: item.isActive ? null : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      subtitle: Text(item.isActive ? words.text(item.type.wordKey) : words.categoriesDisabled, key: CategoriesScreen.itemDetailsKey(item.id)),
      trailing: mayChange
          ? PopupMenuButton<VoidCallback>(
              key: CategoriesScreen.itemMenuKey(item.id),
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                PopupMenuItem(key: CategoriesScreen.renameItemKey, value: () => _askForName(context), child: Text(words.categoriesRename)),
                PopupMenuItem(
                  key: CategoriesScreen.subgroupsKey,
                  value: () => context.push(SubgroupsScreen.pathOf(project.id, item.id), extra: project),
                  child: Text(words.categoriesSubgroups),
                ),
                if (item.isActive)
                  PopupMenuItem(
                    key: CategoriesScreen.disableItemKey,
                    value: () => showRefusalOf(context, categories.disableItem(item)),
                    child: Text(words.categoriesDisable),
                  )
                else
                  PopupMenuItem(
                    key: CategoriesScreen.enableItemKey,
                    value: () => showRefusalOf(context, categories.enableItem(item)),
                    child: Text(words.categoriesEnable),
                  ),
              ],
            )
          : null,
    );
  }
}
