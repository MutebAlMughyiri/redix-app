import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/category.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/one_field_dialog.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// [manager] standing on Categories with [categoryId] open.
Future<void> onCategory(PatrolIntegrationTester $, Person manager, String categoryId) async {
  await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
  await $.tapOn(CategoriesScreen.categoryTileKey(categoryId));
  await $.pumpAndSettle();
}

/// What the line under the item [id] says.
String detailsOf(PatrolIntegrationTester $, String id) => $.tester.widget<Text>(find.byKey(CategoriesScreen.itemDetailsKey(id))).data!;

/// A new manager, a new category of theirs and a new item in it, standing on it.
Future<({Person manager, String category, String item})> onNewItem(PatrolIntegrationTester $, {String type = 'purchases'}) async {
  final manager = await Given.manager();
  final category = await Given.category(manager, 'Category ${Given.unique()}');
  final item = await Given.item(manager, category, 'Item ${Given.unique()}', type: type);
  await onCategory($, manager, category);
  await $.goTo($(CategoriesScreen.itemNameKey(item)));
  return (manager: manager, category: category, item: item);
}

void main() {
  phoneClass('Items (UC-012)', () {
    phoneCase('an item is added with the type chosen', ($) async {
      final manager = await Given.manager();
      final category = await Given.category(manager, 'Category ${Given.unique()}');
      await onCategory($, manager, category);
      await $.tapOn(CategoriesScreen.addItemKey(category));
      await $(OneFieldDialog.fieldKey).enterText('الدهان');
      await $.tapOn(CategoriesScreen.itemTypeKey(ItemType.purchases));
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('categories.itemName.', 'الدهان');
      expect(detailsOf($, id), contains($.words.categoriesTypePurchases));
    });

    phoneCase('an item\'s type changes from its menu, starting from the one it has', ($) async {
      final made = await onNewItem($);
      await $.menuChoice(CategoriesScreen.itemMenuKey(made.item), CategoriesScreen.changeTypeKey);
      await $.tapOn(CategoriesScreen.itemTypeKey(ItemType.both));
      await $(ChangeDialog.saveKey).tap();
      await $.until(() => detailsOf($, made.item).contains($.words.categoriesTypeBoth));
      expect(detailsOf($, made.item), contains($.words.categoriesTypeBoth));
    });

    phoneCase('AC-05.3: Disable takes it out of use', ($) async {
      final made = await onNewItem($);
      await $.menuChoice(CategoriesScreen.itemMenuKey(made.item), CategoriesScreen.disableItemKey);
      await $.until(() => detailsOf($, made.item).contains($.words.categoriesDisabled));
      expect(detailsOf($, made.item), contains($.words.categoriesDisabled));
    });

    phoneCase('an item shows its type', ($) async {
      final made = await onNewItem($);
      expect(detailsOf($, made.item), contains($.words.categoriesTypePurchases));
    });

    phoneCase('dragging an item orders its category', ($) async {
      final manager = await Given.manager();
      final category = await Given.category(manager, 'Category ${Given.unique()}');
      final first = await Given.item(manager, category, 'First ${Given.unique()}');
      final second = await Given.item(manager, category, 'Second ${Given.unique()}');
      await onCategory($, manager, category);
      await $.goTo($(CategoriesScreen.itemNameKey(second)));
      expect($.topOf(CategoriesScreen.itemNameKey(first)), lessThan($.topOf(CategoriesScreen.itemNameKey(second))));
      await $.dragDown(CategoriesScreen.itemHandleKey(first), distance: 100);
      await $.until(() => $.topOf(CategoriesScreen.itemNameKey(first)) > $.topOf(CategoriesScreen.itemNameKey(second)));
      expect($.topOf(CategoriesScreen.itemNameKey(first)), greaterThan($.topOf(CategoriesScreen.itemNameKey(second))));
    });

    phoneCase('AC-05.3: Enable brings it back', ($) async {
      final manager = await Given.manager();
      final category = await Given.category(manager, 'Category ${Given.unique()}');
      final item = await Given.item(manager, category, 'Item ${Given.unique()}');
      await Given.itemDisabled(manager, item);
      await onCategory($, manager, category);
      await $.goTo($(CategoriesScreen.itemNameKey(item)));
      await $.menuChoice(CategoriesScreen.itemMenuKey(item), CategoriesScreen.enableItemKey);
      await $.until(() => !detailsOf($, item).contains($.words.categoriesDisabled));
      expect(detailsOf($, item), isNot(contains($.words.categoriesDisabled)));
    });

    phoneCase('AC-05.3: an item has no delete', ($) async {
      final made = await onNewItem($);
      await $.tapOn(CategoriesScreen.itemMenuKey(made.item));
      await $.reach($(CategoriesScreen.disableItemKey));
    });

    phoneCase('an item with entries keeps its type, and the dialog says why', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      final table = await Given.firstPurchaseTable(manager);
      final bone = await Given.aCategoryAndItem(manager);
      await onCategory($, manager, bone.categoryId);
      await $.goTo($(CategoriesScreen.itemNameKey(table.itemId)));
      await $.menuChoice(CategoriesScreen.itemMenuKey(table.itemId), CategoriesScreen.changeTypeKey);
      await $.tapOn(CategoriesScreen.itemTypeKey(ItemType.contractorPayments));
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.categoriesItemHasEntries);
    });

    phoneCase('a refused name stays in its dialog, with why', ($) async {
      final made = await onNewItem($);
      await $.menuChoice(CategoriesScreen.itemMenuKey(made.item), CategoriesScreen.renameItemKey);
      await $.saveName(' ');
      await $.says(ChangeDialog.messageKey, $.words.categoriesInvalidName);
      expect($(OneFieldDialog.fieldKey), findsOneWidget);
    });

    phoneCase('AC-05.3: a disabled item is not offered in Add entry', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      await Given.itemDisabled(manager, table.itemId);
      await $.fromTheHome(manager, HomeScreen.addEntryKey(manager.projectId));
      await $.tapOn(AddEntryScreen.tableKey);
      await $.reach($(TablePicker.searchKey));
      expect($(TablePicker.optionKey(table.tableId)), findsNothing);
    });
  });
}
