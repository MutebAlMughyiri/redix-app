import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/general_settings_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/item_column.dart';
import 'package:redix/structure/item_columns_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/words/language_switch.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager with a new item in a new category, standing on its columns.
Future<({Person manager, String category, String categoryName, String item, String itemName})> onColumns(PatrolIntegrationTester $) async {
  final manager = await Given.manager(project: 'غصون 7');
  final categoryName = 'Category ${Given.unique()}';
  final itemName = 'Item ${Given.unique()}';
  final category = await Given.category(manager, categoryName);
  final item = await Given.item(manager, category, itemName);
  await openColumns($, manager, category, item);
  return (manager: manager, category: category, categoryName: categoryName, item: item, itemName: itemName);
}

/// [manager] goes from the home to the columns of [item].
Future<void> openColumns(PatrolIntegrationTester $, Person manager, String category, String item) async {
  await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
  await $.tapOn(CategoriesScreen.categoryTileKey(category));
  await $.tapOn(CategoriesScreen.itemColumnsKey(item));
  await $(keyStartingWith('columns.lock.')).waitUntilExists();
}

/// Adds a list column called [name] with [choices], one a line.
Future<void> addList(PatrolIntegrationTester $, String name, String choices) async {
  await $.tapOn(ItemColumnsScreen.addKey);
  await $(ItemColumnsScreen.columnNameKey).enterText(name);
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await $.pumpAndSettle();
  await $(ItemColumnsScreen.dataTypeKey).tap();
  await $.pumpAndSettle();
  await $.tester.tap(find.byKey(ItemColumnsScreen.dataTypeOptionKey(ColumnDataType.list)));
  await $.pumpAndSettle();
  await $(ItemColumnsScreen.choicesKey).enterText(choices);
  await $(ChangeDialog.saveKey).tap();
}

/// The line under the column [id].
String detailsOf(PatrolIntegrationTester $, String id) => $.tester.widget<Text>(find.byKey(ItemColumnsScreen.detailsKey(id))).data!;

void main() {
  phoneClass('An item\'s columns (UC-013)', () {
    phoneCase('AC-41.1: a required column is added to this item, asking nothing about other items', ($) async {
      await onColumns($);
      await $.tapOn(ItemColumnsScreen.addKey);
      await $(ItemColumnsScreen.columnNameKey).enterText('المساحة م²');
      await $(ItemColumnsScreen.requiredKey).tap();
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('columns.name.', 'المساحة م²');
      await $.goTo($(ItemColumnsScreen.nameKey(id)));
      await $.picture('item-columns');
    });

    phoneCase('a pick list sends its choices', ($) async {
      await onColumns($);
      await addList($, 'الجهة', 'شرق');
      final id = await $.idShowing('columns.name.', 'الجهة');
      expect(detailsOf($, id), contains($.words.columnsTypeList));
    });

    phoneCase('a list a person added gains choices, and those it has stay', ($) async {
      await onColumns($);
      await addList($, 'الجهة', 'شرق');
      final id = await $.idShowing('columns.name.', 'الجهة');
      await $.tapOn(ItemColumnsScreen.editKey(id));
      await $(ItemColumnsScreen.newChoicesKey).enterText('غرب');
      await $(ChangeDialog.saveKey).tap();
      await $.gone($(ItemColumnsScreen.newChoicesKey));
      await $.tapOn(ItemColumnsScreen.editKey(id));
      await $.reach($(ItemColumnsScreen.existingChoicesKey));
      final existing = $.tester.widget<Text>(find.byKey(ItemColumnsScreen.existingChoicesKey)).data!;
      expect(existing, allOf(contains('شرق'), contains('غرب')));
    });

    phoneCase('redix-api #102: a swipe deletes a column with no question', ($) async {
      await onColumns($);
      await addList($, 'الجهة', 'شرق');
      final id = await $.idShowing('columns.name.', 'الجهة');
      await $.swipeAway(ItemColumnsScreen.rowKey(id));
      expect(find.byType(AlertDialog), findsNothing);
      await $.gone($(ItemColumnsScreen.nameKey(id)));
    });

    phoneCase('it opens on this item, and says where the item sits and what it is', ($) async {
      final made = await onColumns($);
      final details = $.tester.widget<Text>(find.byKey(ItemColumnsScreen.itemDetailsKey)).data!;
      expect(details, contains(made.categoryName));
      expect(find.text(made.itemName), findsWidgets);
    });

    phoneCase('a row says what the column is', ($) async {
      final manager = await Given.manager();
      final bone = await Given.aCategoryAndItem(manager);
      await Given.column(manager, bone.itemId, 'رقم الأمر');
      await openColumns($, manager, bone.categoryId, bone.itemId);
      final id = await $.idShowing('columns.name.', 'رقم الأمر');
      expect(detailsOf($, id), contains($.words.columnsCustom));
    });

    phoneCase('a core column changes its name only', ($) async {
      await onColumns($);
      final id = await $.idShowing('columns.name.', 'التاريخ');
      await $.tapOn(ItemColumnsScreen.editKey(id));
      await $.reach($(ItemColumnsScreen.requiredKey));
      expect($.tester.widget<SwitchListTile>(find.byKey(ItemColumnsScreen.requiredKey)).onChanged, isNull);
      expect($(ItemColumnsScreen.columnNameKey), findsOneWidget);
    });

    phoneCase('dragging sends the new order, and on an item asks nothing', ($) async {
      final manager = await Given.manager();
      final bone = await Given.aCategoryAndItem(manager);
      await Given.column(manager, bone.itemId, 'العمود الأول');
      await Given.column(manager, bone.itemId, 'العمود الثاني');
      await openColumns($, manager, bone.categoryId, bone.itemId);
      final first = await $.idShowing('columns.name.', 'العمود الأول');
      final second = await $.idShowing('columns.name.', 'العمود الثاني');
      await $.goTo($(ItemColumnsScreen.nameKey(second)));
      expect($.topOf(ItemColumnsScreen.nameKey(first)), lessThan($.topOf(ItemColumnsScreen.nameKey(second))));
      await $.dragDown(ItemColumnsScreen.handleKey(first), distance: 100);
      expect(find.byType(AlertDialog), findsNothing);
      await $.until(() => $.topOf(ItemColumnsScreen.nameKey(first)) > $.topOf(ItemColumnsScreen.nameKey(second)));
      expect($.topOf(ItemColumnsScreen.nameKey(first)), greaterThan($.topOf(ItemColumnsScreen.nameKey(second))));
    });

    phoneCase('in Arabic a built-in field on the entry forms carries its column\'s name', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      await $.onTheList(manager);
      await $(ProjectsScreen.generalSettingsKey).tap();
      await $.goTo($(LanguageSwitch.arabicKey));
      await $(LanguageSwitch.arabicKey).tap();
      await $.until(() => Directionality.of($.tester.element(find.byKey(GeneralSettingsScreen.languageKey))) == TextDirection.rtl);
      await $.tapOn(GeneralSettingsScreen.switchProjectKey);
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.addEntryKey(manager.projectId));
      await $.pickTable(table.tableId);
      await $.goTo($(AddEntryScreen.dateKey));
      expect(find.descendant(of: find.byKey(AddEntryScreen.dateKey), matching: find.text('التاريخ')), findsWidgets);
    });

    phoneCase('AC-41.2: a core column has a lock, no delete, and does not swipe', ($) async {
      await onColumns($);
      final id = await $.idShowing('columns.name.', 'التاريخ');
      expect($(ItemColumnsScreen.lockKey(id)), findsOneWidget);
      expect($(ItemColumnsScreen.rowKey(id).swipe), findsNothing);
      expect($(ItemColumnsScreen.rowKey(id).bar), findsNothing);
    });

    phoneCase('redix-api #102: a short swipe deletes nothing', ($) async {
      await onColumns($);
      await addList($, 'الجهة', 'شرق');
      final id = await $.idShowing('columns.name.', 'الجهة');
      await $.swipeAway(ItemColumnsScreen.rowKey(id), share: 0.15);
      await Future<void>.delayed(const Duration(seconds: 1));
      await $.pumpAndSettle();
      expect($(ItemColumnsScreen.nameKey(id)), findsOneWidget);
    });

    phoneCase('AC-41.3: no dialog offers a type to change', ($) async {
      await onColumns($);
      await addList($, 'الجهة', 'شرق');
      final id = await $.idShowing('columns.name.', 'الجهة');
      await $.tapOn(ItemColumnsScreen.editKey(id));
      await $.reach($(ItemColumnsScreen.requiredKey));
      expect($(ItemColumnsScreen.dataTypeKey), findsNothing);
    });

    phoneCase('no file type is offered', ($) async {
      await onColumns($);
      await $.tapOn(ItemColumnsScreen.addKey);
      await $(ItemColumnsScreen.dataTypeKey).tap();
      await $.pumpAndSettle();
      await $(ItemColumnsScreen.dataTypeOptionKey(ColumnDataType.list)).waitUntilExists();
      expect($(ItemColumnsScreen.dataTypeOptionKey(ColumnDataType.file)), findsNothing);
    });

    phoneCase('a refused column stays in its dialog, with why', ($) async {
      await onColumns($);
      await addList($, 'الجهة', ' ');
      await $.says(ChangeDialog.messageKey, $.words.columnsInvalidOptions);
      expect($(ItemColumnsScreen.choicesKey), findsOneWidget);
    });

    phoneCase('only a list a person added offers more choices', ($) async {
      final manager = await Given.manager();
      final bone = await Given.aCategoryAndItem(manager);
      await Given.column(manager, bone.itemId, 'رقم الأمر');
      await openColumns($, manager, bone.categoryId, bone.itemId);
      final id = await $.idShowing('columns.name.', 'رقم الأمر');
      await $.tapOn(ItemColumnsScreen.editKey(id));
      await $.reach($(ItemColumnsScreen.requiredKey));
      expect($(ItemColumnsScreen.newChoicesKey), findsNothing);
    });
  });
}
