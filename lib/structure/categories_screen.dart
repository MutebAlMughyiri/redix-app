// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/bottom_button.dart';
import '../ui/one_field_dialog.dart';
import '../ui/messages.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'categories.dart';
import 'category.dart';
import 'category_card.dart';
import '../ui/list_search.dart';
import '../ui/search_scope.dart';
import '../words/word_fill.dart';
import '../format/parts_line.dart';

/// A project's categories and items (UC-012): whoever shapes the structure adds, renames, drags and disables them. Nothing is deleted (BR-15).
class CategoriesScreen extends StatefulWidget {
  /// The screen, showing and changing the [categories] of [project].
  const CategoriesScreen({super.key, required this.categories, required this.project});

  /// The categories this screen shows and changes.
  final Categories categories;

  /// The project they belong to.
  final Project project;

  /// The screen's route.
  static const path = '/projects/:projectId/categories';

  /// The route of the categories of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/categories';

  /// The line that says dragging sets the order of the report.
  static const hintKey = Key('categories.hint');

  /// The button that adds a category.
  static const addCategoryKey = Key('categories.add');

  /// Rename, in an item's menu.
  static const renameItemKey = Key('categories.renameItem');

  /// Change type, in an item's menu.
  static const changeTypeKey = Key('categories.changeType');

  /// The check of whether an item's sheet calculates each table's percentage.
  static const tablePercentagesKey = Key('categories.tablePercentages');

  /// Subgroups, in an item's menu.
  static const tablesKey = Key('categories.tables');

  /// Disable, in an item's menu.
  static const disableItemKey = Key('categories.disableItem');

  /// Enable, in an item's menu.
  static const enableItemKey = Key('categories.enableItem');

  /// The choice of [type], in the Add item dialog.
  static Key itemTypeKey(ItemType type) => Key('categories.itemType.${type.name}');

  /// The choice of an item's side: revenue when [isRevenue], expenses otherwise.
  static Key sideKey({required bool isRevenue}) => Key('categories.side.$isRevenue');

  /// The card of the category [id].
  static Key cardKey(String id) => Key('categories.card.$id');

  /// The tile of the category [id], which opens and closes it.
  static Key categoryTileKey(String id) => Key('categories.tile.$id');

  /// The handle that drags the category [id].
  static Key categoryHandleKey(String id) => Key('categories.handle.$id');

  /// The name of the category [id].
  static Key categoryNameKey(String id) => Key('categories.name.$id');

  /// How many items the category [id] holds, or that it is disabled.
  static Key categoryDetailsKey(String id) => Key('categories.details.$id');

  /// The button that adds an item to the category [id].
  static Key addItemKey(String id) => Key('categories.addItem.$id');

  /// The button that renames the category [id].
  static Key renameCategoryKey(String id) => Key('categories.rename.$id');

  /// The ⋮ menu of the category [id], holding its rename and disable or enable (the owner, 9 Nov 2026).
  static Key categoryMenuKey(String id) => Key('categories.categoryMenu.$id');

  /// The button that disables the category [id].
  static Key disableCategoryKey(String id) => Key('categories.disable.$id');

  /// The button that enables the category [id].
  static Key enableCategoryKey(String id) => Key('categories.enable.$id');

  /// The line of a category [id] with no items.
  static Key noItemsKey(String id) => Key('categories.noItems.$id');

  /// The row of the item [id].
  static Key itemKey(String id) => Key('categories.item.$id');

  /// The handle that drags the item [id].
  static Key itemHandleKey(String id) => Key('categories.itemHandle.$id');

  /// The name of the item [id].
  static Key itemNameKey(String id) => Key('categories.itemName.$id');

  /// The type of the item [id], or that it is disabled.
  static Key itemDetailsKey(String id) => Key('categories.itemDetails.$id');

  /// The way into the columns of the item [id].
  static Key itemColumnsKey(String id) => Key('categories.itemColumns.$id');

  /// The menu of the item [id].
  static Key itemMenuKey(String id) => Key('categories.itemMenu.$id');

  /// The row saying the category [id] has no items.
  static Key noItemsRowKey(String id) => Key('categories.noItemsRow.$id');

  /// The heading over the side, in the item dialogs.
  static const sideHeadingKey = Key('categories.sideHeading');

  /// The heading over the item types, in the item dialogs.
  static const typeHeadingKey = Key('categories.typeHeading');

  /// The choice of an item's side: expenses or revenue.
  static const sideChoiceKey = Key('categories.sideChoice');

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    widget.categories.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final categories = widget.categories;
    final project = widget.project;
    return SearchScope(
      child: Scaffold(
        appBar: AppBar(title: ScreenTitle(words.categoriesTitle, subject: project.name), actions: const [SearchIcons()]),
        bottomNavigationBar: BottomButton(
          buttonKey: CategoriesScreen.addCategoryKey,
          label: words.categoriesNew,
          onPressed: project.mayChangeStructure
              ? () => showDialog<void>(
                  context: context,
                  builder: (_) => OneFieldDialog(title: words.categoriesNew, label: words.categoriesCategoryName, saveLabel: words.categoriesNew, onSave: categories.addCategory),
                )
              : null,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (project.mayChangeStructure)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(words.categoriesHint, key: CategoriesScreen.hintKey, style: Theme.of(context).textTheme.bodySmall),
              ),
            Expanded(
              child: ApiListBody<Category>(
                list: categories,
                emptyText: words.categoriesEmpty,
                search: ListSearch(
                  hint: words.commonSearchIn.fill([words.categoriesTitle]),
                  textOf: (category) => partsLine([category.name, for (final item in category.items) item.name]),
                ),
                itemBuilder: (category) => CategoryCard(
                  key: CategoriesScreen.cardKey(category.id),
                  category: category,
                  index: categories.all.indexOf(category),
                  project: project,
                  categories: categories,
                ),
                listOf: (cards) => ReorderableListView(
                  padding: ApiListBody.padding,
                  physics: ApiListBody.physics,
                  buildDefaultDragHandles: false,
                  onReorderItem: (from, to) => showRefusalOf(context, categories.moveCategory(from, to)),
                  children: cards,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
