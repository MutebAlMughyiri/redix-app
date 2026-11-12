import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../ui/name_dialog.dart';
import '../ui/part_keys.dart';
import '../ui/messages.dart';
import '../words/words.dart';
import 'add_item_dialog.dart';
import 'categories.dart';
import 'categories_screen.dart';
import 'category.dart';
import 'item_row.dart';
import '../ui/app_color.dart';
import '../ui/row_menu.dart';
import '../ui/drag_handle.dart';

/// One category of the list: its name, how many items it holds or that it is disabled, and a handle to drag it. Opened, it shows what can be done to it, and its items.
class CategoryCard extends StatelessWidget {
  /// The card of [category], at [index] of the list, in [project], changed through [categories].
  const CategoryCard({super.key, required this.category, required this.index, required this.project, required this.categories});

  /// The category this card shows.
  final Category category;

  /// Its place in the list, for dragging.
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
        label: words.categoriesCategoryName,
        saveLabel: words.categoriesSave,
        name: category.name,
        onSave: (name) => categories.renameCategory(category, name),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final words = Words.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            key: CategoriesScreen.addItemKey(category.id),
            icon: Icon(Icons.add, key: CategoriesScreen.addItemKey(category.id).icon),
            label: Text(words.categoriesAddItem, key: CategoriesScreen.addItemKey(category.id).label),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AddItemDialog(category: category, categories: categories),
            ),
          ),
          rowMenu(CategoriesScreen.categoryMenuKey(category.id), [
            rowMenuItem(CategoriesScreen.renameCategoryKey(category.id), words.categoriesRename, () => _askForName(context)),
            if (category.isActive)
              rowMenuItem(CategoriesScreen.disableCategoryKey(category.id), words.categoriesDisable, () => showRefusalOf(context, categories.disableCategory(category)))
            else
              rowMenuItem(CategoriesScreen.enableCategoryKey(category.id), words.categoriesEnable, () => showRefusalOf(context, categories.enableCategory(category))),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final mayChange = project.mayChangeStructure;
    return Card.outlined(
      key: CategoriesScreen.cardKey(category.id).card,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: CategoriesScreen.categoryTileKey(category.id),
        shape: const Border(),
        leading: mayChange
            ? DragHandle(key: CategoriesScreen.categoryHandleKey(category.id), index: index)
            : null,
        title: Text(
          category.name,
          key: CategoriesScreen.categoryNameKey(category.id),
          style: TextStyle(fontWeight: FontWeight.w700, color: category.isActive ? null : AppColor.quiet.of(context)),
        ),
        subtitle: Text(
          category.isActive ? '${words.categoriesItems}: ${category.items.length}' : words.categoriesDisabled,
          key: CategoriesScreen.categoryDetailsKey(category.id),
        ),
        children: [
          if (mayChange) _actions(context),
          if (category.items.isEmpty) ListTile(key: CategoriesScreen.noItemsRowKey(category.id), dense: true, title: Text(words.categoriesNoItems, key: CategoriesScreen.noItemsKey(category.id))),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (from, to) => showRefusalOf(context, categories.moveItem(category, from, to)),
            children: [
              for (final (itemIndex, item) in category.items.indexed)
                ItemRow(key: CategoriesScreen.itemKey(item.id), item: item, index: itemIndex, project: project, categories: categories),
            ],
          ),
        ],
      ),
    );
  }
}
