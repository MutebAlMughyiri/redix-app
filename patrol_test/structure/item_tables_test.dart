import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/item_tables_screen.dart';
import 'package:redix/ui/name_dialog.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// [manager] standing on the tables of [itemId], in the category [categoryId].
Future<void> onTables(PatrolIntegrationTester $, Person manager, String categoryId, String itemId) async {
  await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
  await $.tapOn(CategoriesScreen.categoryTileKey(categoryId));
  await $.goTo($(CategoriesScreen.itemNameKey(itemId)));
  await $.menuChoice(CategoriesScreen.itemMenuKey(itemId), CategoriesScreen.tablesKey);
  await $.reach($(ItemTablesScreen.hintKey));
}

/// A new manager with a new item that takes purchases, in a new category.
Future<({Person manager, String category, String item, String itemName})> newItem({String type = 'purchases'}) async {
  final manager = await Given.manager(project: 'غصون 7');
  final category = await Given.category(manager, 'Category ${Given.unique()}');
  final itemName = 'البلاط ${Given.unique()}';
  return (manager: manager, category: category, item: await Given.item(manager, category, itemName, type: type), itemName: itemName);
}

void main() {
  phoneClass('An item\'s tables (UC-012)', () {
    phoneCase('a sub-table is added', ($) async {
      final made = await newItem();
      await onTables($, made.manager, made.category, made.item);
      await $.tapOn(ItemTablesScreen.addKey);
      await $.saveName('دفعات العظم');
      await $.idShowing('tables.name.', 'دفعات العظم');
      await $.picture('tables');
    });

    phoneCase('redix-api #102: a swipe removes it with no question', ($) async {
      final made = await newItem();
      final table = await Given.subgroup(made.manager, made.item, 'الجلاي');
      await onTables($, made.manager, made.category, made.item);
      await $.swipeAway(ItemTablesScreen.rowKey(table));
      expect(find.byType(AlertDialog), findsNothing);
      await $.gone($(ItemTablesScreen.tableNameKey(table)));
    });

    phoneCase('AC-46.8: an item lists every table its sheet prints', ($) async {
      final made = await newItem(type: 'both');
      final table = await Given.subgroup(made.manager, made.item, 'الجلاي');
      await onTables($, made.manager, made.category, made.item);
      await $.idShowing('tables.name.', made.itemName);
      await $.says(ItemTablesScreen.tableNameKey(table), 'الجلاي');
    });

    phoneCase('a sub-table is renamed', ($) async {
      final made = await newItem();
      final table = await Given.subgroup(made.manager, made.item, 'الجلاي');
      await onTables($, made.manager, made.category, made.item);
      await $.tapOn(ItemTablesScreen.renameKey(table));
      await $.reach($(NameDialog.nameKey));
      expect($.typed(NameDialog.nameKey), 'الجلاي');
      await $.saveName('السيراميك');
      await $.says(ItemTablesScreen.tableNameKey(table), 'السيراميك');
    });

    phoneCase('AC-46.8: dragging sends the order of every table, and it stays', ($) async {
      final made = await newItem();
      final first = await Given.subgroup(made.manager, made.item, 'الأولى');
      final second = await Given.subgroup(made.manager, made.item, 'الثانية');
      await onTables($, made.manager, made.category, made.item);
      await $.goTo($(ItemTablesScreen.tableNameKey(second)));
      expect($.topOf(ItemTablesScreen.tableNameKey(first)), lessThan($.topOf(ItemTablesScreen.tableNameKey(second))));
      await $.dragDown(ItemTablesScreen.handleKey(first), distance: 100);
      await $.until(() => $.topOf(ItemTablesScreen.tableNameKey(first)) > $.topOf(ItemTablesScreen.tableNameKey(second)));
      expect($.topOf(ItemTablesScreen.tableNameKey(first)), greaterThan($.topOf(ItemTablesScreen.tableNameKey(second))));
    });

    phoneCase('a sub-table added here is offered in إضافة قيد and takes a purchase', ($) async {
      final made = await newItem();
      final table = await Given.subgroup(made.manager, made.item, 'الجلاي');
      final account = await Given.account(made.manager);
      await $.onAddEntry(made.manager);
      await $.pickTable(table, search: 'الجلاي');
      await $.chooseANewSupplier(made.manager);
      await $.fill(AddEntryScreen.amountKey, '250');
      await $.choosePayment(made.manager, account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('only an item that takes purchases offers a sub-table', ($) async {
      final made = await newItem(type: 'contractorPayments');
      await onTables($, made.manager, made.category, made.item);
      await $.reach($(ItemTablesScreen.addKey));
      expect($.isEnabled(ItemTablesScreen.addKey), isFalse);
    });

    phoneCase('redix-api #102: the general table and a contract\'s table do not swipe', ($) async {
      final made = await newItem(type: 'both');
      await onTables($, made.manager, made.category, made.item);
      final general = await $.idShowing('tables.name.', made.itemName);
      expect($(ItemTablesScreen.rowKey(general).swipe), findsNothing);
    });

    phoneCase('redix-api #102: a table that entries use comes back, and the refusal says why', ($) async {
      final made = await newItem();
      final table = await Given.subgroup(made.manager, made.item, 'الجلاي');
      await Given.entry(made.manager, itemId: made.item, tableId: table);
      await onTables($, made.manager, made.category, made.item);
      await $.swipeAway(ItemTablesScreen.rowKey(table));
      await $.messageSays('categories.subgroupInUse', $.words.categoriesSubgroupInUse);
      await $.reach($(ItemTablesScreen.tableNameKey(table)));
    });

    phoneCase('AC-46.8: a refused order goes back and says why', ($) async {
      final made = await newItem();
      final first = await Given.subgroup(made.manager, made.item, 'الأولى');
      final second = await Given.subgroup(made.manager, made.item, 'الثانية');
      await onTables($, made.manager, made.category, made.item);
      await $.goTo($(ItemTablesScreen.tableNameKey(second)));
      final top = $.topOf(ItemTablesScreen.tableNameKey(first));
      await Pc.cutNetwork();
      await $.dragDown(ItemTablesScreen.handleKey(first), distance: 100);
      await $.messageSays('categories.noConnection', $.words.categoriesNoConnection);
      await $.until(() => $.topOf(ItemTablesScreen.tableNameKey(first)) == top);
      expect($.topOf(ItemTablesScreen.tableNameKey(first)), top);
    });
  });
}
