// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/structure/item_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/search_line.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/search_steps.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Suppliers.
Future<void> onSuppliers(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.suppliersKey(person.projectId));
  await $.reach($(SuppliersScreen.addKey));
}

/// Opens the dialog of a new supplier and types [name].
Future<void> openNew(PatrolIntegrationTester $, String name) async {
  await $.tapOn(SuppliersScreen.addKey);
  await $(SuppliersScreen.supplierNameKey).enterText(name);
}

/// Saves the dialog and answers the id of the supplier called [name].
Future<String> saveAndFind(PatrolIntegrationTester $, Person person, String name) async {
  await $(ChangeDialog.saveKey).tap();
  return $.idOf('suppliers.name.', () => Given.supplierNamed(person, name));
}

void main() {
  phoneClass('Suppliers (UC-017)', () {
    phoneCase('a supplier is added with its VAT number and default item', ($) async {
      final manager = await Given.manager(project: 'مشروع B');
      final table = await Given.firstPurchaseTable(manager);
      await Given.supplier(manager, name: 'مؤسسة الأفق', vatNumber: Given.vatNumber());
      await onSuppliers($, manager);
      await openNew($, 'شركة النخيل');
      await $(SuppliersScreen.vatNumberKey).enterText(Given.vatNumber());
      await $.tapOn(SuppliersScreen.defaultItemKey);
      await $.tapOn(ItemPicker.optionKey(table.itemId));
      await $.pumpAndSettle();
      await $.picture('supplier-dialog');
      await saveAndFind($, manager, 'شركة النخيل');
      await $.picture('suppliers');
    });

    phoneCase('each supplier shows its VAT number and default item, and one with no number shows none', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final vat = Given.vatNumber();
      final withNumber = await Given.supplier(manager, vatNumber: vat, defaultItemId: table.itemId);
      final without = await Given.supplier(manager, defaultItemId: table.itemId);
      await onSuppliers($, manager);
      await $.says(SuppliersScreen.detailsKey(withNumber), '$vat · ${table.itemName}');
      await $.says(SuppliersScreen.detailsKey(without), table.itemName);
    });

    phoneCase('adding sends only what was filled in', ($) async {
      final manager = await Given.manager();
      await onSuppliers($, manager);
      await openNew($, 'مورد بالاسم فقط');
      final id = await saveAndFind($, manager, 'مورد بالاسم فقط');
      expect($(SuppliersScreen.nameKey(id)), findsOneWidget);
    });

    phoneCase('Arabic digits are sent as Western ones', ($) async {
      final manager = await Given.manager();
      await onSuppliers($, manager);
      await openNew($, 'مورد الأرقام');
      final western = Given.vatNumber();
      final arabic = String.fromCharCodes(western.codeUnits.map((unit) => 0x0660 + unit - 0x30));
      await $(SuppliersScreen.vatNumberKey).enterText(arabic);
      final id = await saveAndFind($, manager, 'مورد الأرقام');
      await $.says(SuppliersScreen.detailsKey(id), western);
    });

    phoneCase('BR-16: the VAT number may stay empty, with no switch for it', ($) async {
      final manager = await Given.manager();
      await onSuppliers($, manager);
      await openNew($, 'مورد بلا رقم');
      expect(find.byType(Switch), findsNothing);
      await saveAndFind($, manager, 'مورد بلا رقم');
    });

    phoneCase('editing starts from the supplier and changes it', ($) async {
      final manager = await Given.manager();
      final name = 'Supplier ${Given.unique()}';
      final id = await Given.supplier(manager, name: name);
      await onSuppliers($, manager);
      await $.menuChoice(SuppliersScreen.menuKey(id), SuppliersScreen.editKey);
      await $.reach($(SuppliersScreen.supplierNameKey));
      expect($.typed(SuppliersScreen.supplierNameKey), name);
      await $(SuppliersScreen.supplierNameKey).enterText('اسم جديد');
      await $(ChangeDialog.saveKey).tap();
      await $.says(SuppliersScreen.nameKey(id), 'اسم جديد');
    });

    phoneCase('editing a supplier with no number shows it empty', ($) async {
      final manager = await Given.manager();
      final id = await Given.supplier(manager);
      await onSuppliers($, manager);
      await $.menuChoice(SuppliersScreen.menuKey(id), SuppliersScreen.editKey);
      await $.reach($(SuppliersScreen.vatNumberKey));
      expect($.typed(SuppliersScreen.vatNumberKey), '');
    });

    phoneCase('a default item is chosen among what a purchase is offered', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final id = await Given.supplier(manager);
      await onSuppliers($, manager);
      await $.menuChoice(SuppliersScreen.menuKey(id), SuppliersScreen.editKey);
      await $.tapOn(SuppliersScreen.defaultItemKey);
      await $.tapOn(ItemPicker.optionKey(table.itemId));
      await $.pumpAndSettle();
      await $(ChangeDialog.saveKey).tap();
      await $.says(SuppliersScreen.detailsKey(id), table.itemName);
    });

    phoneCase('a supplier pending approval is marked', ($) async {
      final manager = await Given.manager();
      final field = await Given.member(manager, permissions: [Permission.addSupplier]);
      final id = await Given.supplier(field);
      await onSuppliers($, manager);
      await $.says(SuppliersScreen.detailsKey(id), $.words.suppliersPendingApproval);
    });

    phoneCase('BR-15: disabled, it stays on the list, marked, and can be enabled', ($) async {
      final manager = await Given.manager();
      final id = await Given.supplier(manager);
      await onSuppliers($, manager);
      await $.menuChoice(SuppliersScreen.menuKey(id), SuppliersScreen.disableKey);
      String details() => $.tester.widget<Text>(find.byKey(SuppliersScreen.detailsKey(id))).data!;
      await $.until(() => details().startsWith($.words.suppliersDisabled));
      expect(details(), startsWith($.words.suppliersDisabled));
      await $.menuChoice(SuppliersScreen.menuKey(id), SuppliersScreen.enableKey);
      await $.until(() => !details().startsWith($.words.suppliersDisabled));
      expect(details(), isNot(startsWith($.words.suppliersDisabled)));
    });

    phoneCase('AC-06.1: an invalid number stays in the dialog with the rule', ($) async {
      final manager = await Given.manager();
      await onSuppliers($, manager);
      await openNew($, 'مورد');
      await $(SuppliersScreen.vatNumberKey).enterText('30012A');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.suppliersInvalidVatNumber);
      expect($(SuppliersScreen.supplierNameKey), findsOneWidget);
    });

    phoneCase('AC-06.1: a number another supplier holds is refused, naming it', ($) async {
      final manager = await Given.manager();
      final vat = Given.vatNumber();
      await Given.supplier(manager, name: 'شركة النخيل', vatNumber: vat);
      await onSuppliers($, manager);
      await openNew($, 'مورد آخر');
      await $(SuppliersScreen.vatNumberKey).enterText(vat);
      await $(ChangeDialog.saveKey).tap();
      await $.says(SuppliersScreen.holderKey, '${$.words.suppliersHolder} شركة النخيل');
    });

    phoneCase('the general cash supplier stays active, and the refusal says why', ($) async {
      final manager = await Given.manager();
      await onSuppliers($, manager);
      final id = await $.idOf('suppliers.name.', () => Given.supplierNamed(manager, 'مورد نقدي عام'));
      await $.menuChoice(SuppliersScreen.menuKey(id), SuppliersScreen.disableKey);
      await $.messageSays('suppliers.generalCashSupplier', $.words.suppliersGeneralCashSupplier);
    });

    phoneCase('without keeping the settings there is nothing to change', ($) async {
      final manager = await Given.manager();
      final id = await Given.supplier(manager);
      final member = await Given.member(manager);
      await onSuppliers($, member);
      await $.reach($(SuppliersScreen.nameKey(id)));
      expect($.isEnabled(SuppliersScreen.addKey), isFalse);
      expect($(SuppliersScreen.menuKey(id)), findsNothing);
    });

    phoneCase('redix-app #104 R1-R3: Suppliers opens on its rows; the search icon shows the line, and its ✕ closes it and shows every supplier again', ($) async {
      final manager = await Given.manager();
      final horizon = await Given.supplier(manager, name: 'مؤسسة الأفق ${Given.unique()}');
      final palm = await Given.supplier(manager, name: 'شركة النخيل ${Given.unique()}');
      await onSuppliers($, manager);
      expect($(SearchLine.searchKey), findsNothing);
      await $.searchFor('الافق');
      await $.gone($(SuppliersScreen.rowKey(palm)));
      await $.reach($(SuppliersScreen.rowKey(horizon)));
      await $.tapOn(SearchLine.closeKey);
      expect($(SearchLine.searchKey), findsNothing);
      await $.goTo($(SuppliersScreen.rowKey(palm)));
    });

    phoneCase('a list that cannot be read says so', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await Pc.cutNetwork();
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.suppliersKey(manager.projectId));
      await $.says(ApiListBody.messageKey, $.words.suppliersLoadFailed);
    });
  });
}
