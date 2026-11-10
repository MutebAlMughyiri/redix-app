import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Opens the supplier sheet in Add entry.
Future<void> openSheet(PatrolIntegrationTester $) async {
  await $.tapOn(AddEntryScreen.supplierKey);
  await $.reach($(SupplierPicker.searchKey));
}

void main() {
  phoneClass('Pick a supplier (UC-018)', () {
    phoneCase('AC-43.1: typing shows what the API finds', ($) async {
      final manager = await Given.manager();
      final found = await Given.supplier(manager, name: 'شركة النخيل', vatNumber: Given.vatNumber());
      final other = await Given.supplier(manager, name: 'مؤسسة الأفق');
      await $.onAddEntry(manager);
      await openSheet($);
      await $.reach($(SupplierPicker.rowKey(found)));
      await $.picture('supplier-picker');
      await $(SupplierPicker.searchKey).enterText('النخيل');
      await $.gone($(SupplierPicker.rowKey(other)));
      await $.reach($(SupplierPicker.rowKey(found)));
    });

    phoneCase('FR-43: picking closes the sheet and answers the supplier', ($) async {
      final manager = await Given.manager();
      final found = await Given.supplier(manager, name: 'شركة النخيل');
      await $.onAddEntry(manager);
      await openSheet($);
      await $.tapOn(SupplierPicker.rowKey(found));
      await $.gone($(SupplierPicker.searchKey));
      await $.says(AddEntryScreen.supplierKey.label, 'شركة النخيل');
    });

    phoneCase('opening shows what is on offer, each with its VAT number and default item', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final vat = Given.vatNumber();
      final found = await Given.supplier(manager, vatNumber: vat, defaultItemId: table.itemId);
      await $.onAddEntry(manager);
      await openSheet($);
      await $.goTo($(SupplierPicker.detailsKey(found)));
      await $.says(SupplierPicker.detailsKey(found), '$vat · ${table.itemName}');
    });

    phoneCase('Arabic digits are asked in Western ones', ($) async {
      final manager = await Given.manager();
      final vat = Given.vatNumber();
      final found = await Given.supplier(manager, vatNumber: vat);
      await $.onAddEntry(manager);
      await openSheet($);
      await $(SupplierPicker.searchKey).enterText(String.fromCharCodes(vat.substring(0, 12).codeUnits.map((unit) => 0x0660 + unit - 0x30)));
      await $.reach($(SupplierPicker.rowKey(found)));
    });

    phoneCase('opening again starts with nothing typed', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await openSheet($);
      await $(SupplierPicker.searchKey).enterText('النخيل');
      await $.tapOn(SupplierPicker.closeKey);
      await $.gone($(SupplierPicker.searchKey));
      await openSheet($);
      expect($.typed(SupplierPicker.searchKey), '');
    });

    phoneCase('a search that finds nothing says so', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await openSheet($);
      await $(SupplierPicker.searchKey).enterText('لا يوجد ${Given.unique()}');
      await $(find.text($.words.suppliersNoMatch)).waitUntilExists();
    });

    phoneCase('closing answers no supplier', ($) async {
      final manager = await Given.manager();
      await Given.supplier(manager, name: 'شركة النخيل');
      await $.onAddEntry(manager);
      await openSheet($);
      await $.tapOn(SupplierPicker.closeKey);
      await $.gone($(SupplierPicker.searchKey));
      expect(find.text('شركة النخيل'), findsNothing);
    });
  });
}
