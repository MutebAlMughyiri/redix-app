// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// The save button of the dialog on top: the quick add opens over another dialog that shares its key.
PatrolFinder saveOnTop(PatrolIntegrationTester $) => $(find.byKey(ChangeDialog.saveKey).hitTestable());

/// Opens the supplier sheet in Add entry, types [search] and opens the quick add.
Future<void> openQuickAdd(PatrolIntegrationTester $, String search) async {
  await $.tapOn(AddEntryScreen.supplierKey);
  await $.reach($(SupplierPicker.searchKey));
  await $(SupplierPicker.searchKey).enterText(search);
  await $.tapOn(SupplierPicker.quickAddKey);
  await $.reach($(SuppliersScreen.vatNumberKey));
}

/// Someone who may enter expenses and add a supplier that then waits for approval, standing on Add entry.
Future<Person> fieldOnAddEntry(PatrolIntegrationTester $) async {
  final field = await Given.member(await Given.manager(), permissions: [Permission.recordEntries, Permission.addSupplier]);
  await $.onAddEntry(field);
  return field;
}

void main() {
  phoneClass('Quick add a supplier (UC-019)', () {
    phoneCase('a name in the search starts the name', ($) async {
      await fieldOnAddEntry($);
      await openQuickAdd($, 'مورد الميدان');
      expect($.typed(SuppliersScreen.supplierNameKey), 'مورد الميدان');
      await $(SuppliersScreen.vatNumberKey).enterText(Given.vatNumber());
      await $.pumpAndSettle();
      await $.picture('quick-add-supplier');
    });

    phoneCase('AC-44.1: what Field adds is picked', ($) async {
      await fieldOnAddEntry($);
      await openQuickAdd($, 'مورد الميدان');
      await saveOnTop($).tap();
      await $.says(AddEntryScreen.supplierKey.label, 'مورد الميدان');
    });

    phoneCase('AC-44.1: what Field adds shows pending approval', ($) async {
      await fieldOnAddEntry($);
      await openQuickAdd($, 'مورد الميدان');
      await saveOnTop($).tap();
      await $.says(AddEntryScreen.supplierKey.label, 'مورد الميدان');
      await $.goTo($(AddEntryScreen.supplierDetailsKey));
      expect($.tester.widget<Text>(find.byKey(AddEntryScreen.supplierDetailsKey)).data, contains($.words.suppliersPendingApproval));
    });

    phoneCase('a number in the search starts the VAT number, in Western digits', ($) async {
      await fieldOnAddEntry($);
      final vat = Given.vatNumber();
      await openQuickAdd($, String.fromCharCodes(vat.codeUnits.map((unit) => 0x0660 + unit - 0x30)));
      expect($.typed(SuppliersScreen.vatNumberKey), vat);
      expect($.typed(SuppliersScreen.supplierNameKey), '');
    });

    phoneCase('it says a new supplier waits, to whoever does not keep the settings', ($) async {
      await fieldOnAddEntry($);
      await openQuickAdd($, 'مورد الميدان');
      await $.says(SupplierPicker.pendingHintKey, $.words.suppliersPendingHint);
    });

    phoneCase('whoever keeps the settings adds it approved', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await openQuickAdd($, 'مورد الإدارة');
      expect($(SupplierPicker.pendingHintKey), findsNothing);
      await saveOnTop($).tap();
      await $.says(AddEntryScreen.supplierKey.label, 'مورد الإدارة');
      await $.goTo($(AddEntryScreen.supplierDetailsKey));
      expect($.tester.widget<Text>(find.byKey(AddEntryScreen.supplierDetailsKey)).data, isNot(contains($.words.suppliersPendingApproval)));
    });

    phoneCase('AC-06.1: an invalid number is blocked with the rule shown', ($) async {
      await fieldOnAddEntry($);
      await openQuickAdd($, 'مورد الميدان');
      await $(SuppliersScreen.vatNumberKey).enterText('30012A');
      await saveOnTop($).tap();
      await $.says(ChangeDialog.messageKey, $.words.suppliersInvalidVatNumber);
    });

    phoneCase('a number already used names the supplier and offers it instead', ($) async {
      final manager = await Given.manager();
      final vat = Given.vatNumber();
      await Given.supplier(manager, name: 'شركة النخيل', vatNumber: vat);
      await $.onAddEntry(manager);
      await openQuickAdd($, 'النخيل الجديدة');
      await $(SuppliersScreen.vatNumberKey).enterText(vat);
      await saveOnTop($).tap();
      await $.says(SuppliersScreen.holderKey, '${$.words.suppliersHolder} شركة النخيل');
      await $.reach($(SupplierPicker.useExistingKey));
    });

    phoneCase('BR-15: a disabled supplier holding it is named and not offered', ($) async {
      final manager = await Given.manager();
      final vat = Given.vatNumber();
      await Given.supplierDisabled(manager, await Given.supplier(manager, name: 'شركة النخيل', vatNumber: vat));
      await $.onAddEntry(manager);
      await openQuickAdd($, 'النخيل الجديدة');
      await $(SuppliersScreen.vatNumberKey).enterText(vat);
      await saveOnTop($).tap();
      await $.says(SuppliersScreen.holderKey, '${$.words.suppliersHolder} شركة النخيل');
      expect($(SupplierPicker.useExistingKey), findsNothing);
    });

    phoneCase('closing goes back to the search', ($) async {
      await fieldOnAddEntry($);
      await openQuickAdd($, 'مورد الميدان');
      await $(find.byKey(ChangeDialog.cancelKey).hitTestable()).tap();
      await $.gone($(SuppliersScreen.vatNumberKey));
      await $.reach($(SupplierPicker.searchKey));
      expect($.typed(SupplierPicker.searchKey), 'مورد الميدان');
    });

    phoneCase('without addSupplier there is no quick add', ($) async {
      final member = await Given.member(await Given.manager(), permissions: [Permission.recordEntries]);
      await $.onAddEntry(member);
      await $.tapOn(AddEntryScreen.supplierKey);
      await $.reach($(SupplierPicker.searchKey));
      await $(SupplierPicker.searchKey).enterText('لا يوجد ${Given.unique()}');
      await $.pumpAndSettle();
      expect($(SupplierPicker.quickAddKey), findsNothing);
    });
  });
}
