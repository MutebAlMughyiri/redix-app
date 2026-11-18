// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/structure/apply_to_all_dialog.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/item_columns_screen.dart';
import 'package:redix/ui/change_dialog.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager standing on the columns template that an item of theirs shares.
Future<({Person manager, String itemId})> onTemplate(PatrolIntegrationTester $) async {
  final manager = await Given.manager(project: 'غصون 7');
  final bone = await Given.aCategoryAndItem(manager);
  await $.fromTheHome(manager, HomeScreen.categoriesKey(manager.projectId));
  await $.tapOn(CategoriesScreen.categoryTileKey(bone.categoryId));
  await $.tapOn(CategoriesScreen.itemColumnsKey(bone.itemId));
  await $(keyedBy(ItemColumnsScreen.lockKey)).waitUntilExists();
  await $.tapOn(ItemColumnsScreen.templateKey);
  await $(keyedBy(ItemColumnsScreen.lockKey)).waitUntilExists();
  return (manager: manager, itemId: bone.itemId);
}

/// Adds a column to the template, standing on the question that follows.
Future<void> addToTemplate(PatrolIntegrationTester $, String name) async {
  await $.tapOn(ItemColumnsScreen.addKey);
  await $(ItemColumnsScreen.columnNameKey).enterText(name);
  await $(ChangeDialog.saveKey).tap();
  await $.reach($(ApplyToAllDialog.applyKey));
}

void main() {
  phoneClass('The columns template (UC-013)', () {
    phoneCase('AC-41.3: adding to the template asks whether it reaches existing items', ($) async {
      await onTemplate($);
      await addToTemplate($, 'رقم أمر الشراء');
      await $.says(ApplyToAllDialog.explainKey, $.words.columnsApplyExplain);
      await $.picture('apply-to-all');
    });

    phoneCase('AC-41.3: applying reaches the items that exist', ($) async {
      final made = await onTemplate($);
      await addToTemplate($, 'رقم أمر الشراء');
      await $(ApplyToAllDialog.applyKey).tap();
      await $.idOf('columns.name.', () => Given.templateColumnNamed(made.manager, made.itemId, 'رقم أمر الشراء'));
      await $.tapOn(ItemColumnsScreen.thisItemKey);
      await $.idOf('columns.name.', () => Given.columnNamed(made.manager, made.itemId, 'رقم أمر الشراء'));
    });

    phoneCase('AC-41.3: keeping it to new items leaves the existing ones as they were', ($) async {
      final made = await onTemplate($);
      await addToTemplate($, 'رقم أمر الشراء');
      await $(ApplyToAllDialog.templateOnlyKey).tap();
      await $.idOf('columns.name.', () => Given.templateColumnNamed(made.manager, made.itemId, 'رقم أمر الشراء'));
      await $.tapOn(ItemColumnsScreen.thisItemKey);
      await $(keyedBy(ItemColumnsScreen.lockKey)).waitUntilExists();
      expect(find.text('رقم أمر الشراء'), findsNothing);
    });

    phoneCase('AC-41.3: renaming, reordering or deleting in the template asks too', ($) async {
      final made = await onTemplate($);
      await addToTemplate($, 'رقم أمر الشراء');
      await $(ApplyToAllDialog.templateOnlyKey).tap();
      final id = await $.idOf('columns.name.', () => Given.templateColumnNamed(made.manager, made.itemId, 'رقم أمر الشراء'));
      await $.menuChoice(ItemColumnsScreen.menuKey(id), ItemColumnsScreen.editKey);
      await $(ItemColumnsScreen.columnNameKey).enterText('رقم الأمر');
      await $(ChangeDialog.saveKey).tap();
      await $.reach($(ApplyToAllDialog.applyKey));
      await $(ApplyToAllDialog.templateOnlyKey).tap();
      await $.gone($(ApplyToAllDialog.applyKey));
      await $.swipeAway(ItemColumnsScreen.rowKey(id));
      await $.reach($(ApplyToAllDialog.applyKey));
    });

    phoneCase('AC-41.3: Cancel changes nothing', ($) async {
      await onTemplate($);
      await addToTemplate($, 'رقم أمر الشراء');
      await $.back();
      await $.gone($(ApplyToAllDialog.applyKey));
      await $.pumpAndSettle();
      expect(find.text('رقم أمر الشراء'), findsNothing);
    });
  });
}
