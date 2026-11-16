import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/one_field_dialog.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// What the line under the category [id] says.
String detailsOf(PatrolIntegrationTester $, String id) => $.tester.widget<Text>(find.byKey(CategoriesScreen.categoryDetailsKey(id))).data!;

void main() {
  phoneClass('Categories (UC-012)', () {
    phoneCase('a category is added', ($) async {
      final manager = await Given.manager(project: 'غصون 7');
      await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
      await $.tapOn(CategoriesScreen.addCategoryKey);
      await $.saveName('تكاليف إدارية');
      await $.idOf('categories.name.', () => Given.categoryNamed(manager, 'تكاليف إدارية'));
      await $.picture('categories');
    });

    phoneCase('AC-39.1: dragging a category sends the order, and it stays where it was dropped', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
      final land = await $.idOf('categories.name.', () => Given.categoryNamed(manager, 'تكلفة الأراضي'));
      final top = $.topOf(CategoriesScreen.categoryNameKey(land));
      await $.dragDown(CategoriesScreen.categoryHandleKey(land));
      expect($.topOf(CategoriesScreen.categoryNameKey(land)), greaterThan(top));
      await $.restartApp();
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.categoriesKey(manager.projectId));
      await $.reach($(CategoriesScreen.categoryNameKey(land)));
      expect($.topOf(CategoriesScreen.categoryNameKey(land)), greaterThan(top));
    });

    phoneCase('categories show in order, each with how many items it holds', ($) async {
      final manager = await Given.manager();
      final first = await Given.category(manager, 'Category one ${Given.unique()}');
      final second = await Given.category(manager, 'Category two ${Given.unique()}');
      await Given.item(manager, first, 'أول');
      await Given.item(manager, first, 'ثان');
      await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
      await $.goTo($(CategoriesScreen.categoryNameKey(second)));
      await $.goTo($(CategoriesScreen.categoryNameKey(first)));
      expect(detailsOf($, first), contains('2'));
      expect($.topOf(CategoriesScreen.categoryNameKey(first)), lessThan($.topOf(CategoriesScreen.categoryNameKey(second))));
    });

    phoneCase('renaming starts from the name, from the category\'s menu', ($) async {
      final manager = await Given.manager();
      final name = 'Category ${Given.unique()}';
      final id = await Given.category(manager, name);
      await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
      await $.tapOn(CategoriesScreen.categoryTileKey(id));
      await $.pumpAndSettle();
      await $.menuChoice(CategoriesScreen.categoryMenuKey(id), CategoriesScreen.renameCategoryKey(id));
      await $.reach($(OneFieldDialog.fieldKey));
      expect($.typed(OneFieldDialog.fieldKey), name);
      await $.saveName('اسم جديد');
      await $.gone($(OneFieldDialog.fieldKey));
      await $.goTo($(CategoriesScreen.categoryNameKey(id)));
      await $.says(CategoriesScreen.categoryNameKey(id), 'اسم جديد');
    });

    phoneCase('a category is disabled and enabled, and says so', ($) async {
      final manager = await Given.manager();
      final id = await Given.category(manager, 'Category ${Given.unique()}');
      await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
      await $.tapOn(CategoriesScreen.categoryTileKey(id));
      await $.pumpAndSettle();
      await $.menuChoice(CategoriesScreen.categoryMenuKey(id), CategoriesScreen.disableCategoryKey(id));
      await $.pumpAndSettle();
      await $.goTo($(CategoriesScreen.categoryDetailsKey(id)));
      await $.until(() => detailsOf($, id).contains($.words.categoriesDisabled));
      expect(detailsOf($, id), contains($.words.categoriesDisabled));
      await $.menuChoice(CategoriesScreen.categoryMenuKey(id), CategoriesScreen.enableCategoryKey(id));
      await $.pumpAndSettle();
      await $.goTo($(CategoriesScreen.categoryDetailsKey(id)));
      await $.until(() => !detailsOf($, id).contains($.words.categoriesDisabled));
      expect(detailsOf($, id), isNot(contains($.words.categoriesDisabled)));
    });

    phoneCase('a refused name stays in its dialog, with why', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
      await $.tapOn(CategoriesScreen.addCategoryKey);
      await $.saveName(' ');
      await $.says(ChangeDialog.messageKey, $.words.categoriesInvalidName);
      expect($(OneFieldDialog.fieldKey), findsOneWidget);
    });

    phoneCase('a refused or lost order goes back to what the API holds', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
      final land = await $.idOf('categories.name.', () => Given.categoryNamed(manager, 'تكلفة الأراضي'));
      final top = $.topOf(CategoriesScreen.categoryNameKey(land));
      await Pc.cutNetwork();
      await $.dragDown(CategoriesScreen.categoryHandleKey(land));
      await $.messageSays('categories.noConnection', $.words.categoriesNoConnection);
      await $.until(() => $.topOf(CategoriesScreen.categoryNameKey(land)) == top);
      expect($.topOf(CategoriesScreen.categoryNameKey(land)), top);
    });
  });
}
