import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager, an account and the first purchase table, standing on Add entry with the table picked.
Future<({Person manager, String account, ({String category, String itemId, String itemName, String tableId}) table})> onPurchase(PatrolIntegrationTester $) async {
  final manager = await Given.manager(project: 'غصون 7');
  final account = await Given.account(manager, name: 'حساب المؤسسة');
  final table = await Given.firstPurchaseTable(manager);
  await $.onAddEntry(manager);
  await $.pickTable(table.tableId);
  await $.chooseANewSupplier(manager);
  return (manager: manager, account: account, table: table);
}

void main() {
  phoneClass('Add a purchase (UC-022)', () {
    phoneCase('R5: one Add entry button on the home opens the screen', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $.reach($(HomeScreen.addEntryKey(manager.projectId)));
      await $(HomeScreen.addEntryKey(manager.projectId)).tap();
      await $.reach($(AddEntryScreen.tableKey));
    });

    phoneCase('R10: a purchase on an item\'s general table is sent for approval', ($) async {
      final made = await onPurchase($);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.qrReadKey));
      await $.picture('add-expense');
      await $.choosePayment(made.manager, made.account);
      await $.picture('add-expense-payment');
      await $.goTo($(AddEntryScreen.sendKey));
      await $.picture('add-expense-send');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      expect(await Given.waitingIds(made.manager), hasLength(1));
    });

    phoneCase('FR-44: Field reaches the supplier sheet and its quick add from the entry', ($) async {
      final field = await Given.member(await Given.manager(), permissions: [Permission.recordEntries, Permission.addSupplier]);
      await $.onAddEntry(field);
      await $.tapOn(AddEntryScreen.supplierKey);
      await $.reach($(SupplierPicker.searchKey));
      await $(SupplierPicker.searchKey).enterText('مورد جديد');
      await $.reach($(SupplierPicker.quickAddKey));
    });

    phoneCase('R10: a named table takes the purchase into that subgroup, and names it as the table then its item', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final subgroup = await Given.subgroup(manager, table.itemId, 'الجلاي');
      await $.onAddEntry(manager);
      await $.pickTable(subgroup);
      await $.says(AddEntryScreen.tableKey.field.label, 'الجلاي (${table.itemName})');
    });

    phoneCase('the table sheet searches items and tables, Arabic spelling read as one', ($) async {
      final manager = await Given.manager();
      final category = await Given.category(manager, 'Category ${Given.unique()}');
      await Given.item(manager, category, 'أعمال الحفر', type: 'purchases');
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.tableKey);
      await $(TablePicker.searchKey).enterText('اعمال');
      await $.idShowing('tablePicker.option.', 'أعمال الحفر');
    });

    phoneCase('choosing a supplier fills its usual item\'s general table while none is chosen', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final supplier = await Given.supplier(manager, defaultItemId: table.itemId);
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.supplierKey);
      await $.tapOn(SupplierPicker.rowKey(supplier));
      await $.says(AddEntryScreen.tableKey.field.label, table.itemName);
    });

    phoneCase('D3: an entry with no file is sent, with no reason asked', ($) async {
      final made = await onPurchase($);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('Arabic digits count as the amount', ($) async {
      final made = await onPurchase($);
      await $.fill(AddEntryScreen.amountKey, '٢٥٠');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      expect((await Given.entries(made.manager)).single['amount'], 250);
    });

    phoneCase('what was typed is what the entry holds, figure for figure', ($) async {
      final made = await onPurchase($);
      await $.fill(AddEntryScreen.amountKey, '123.45');
      await $.fill(AddEntryScreen.descriptionKey, 'دفعة أولى');
      await $.choosePayment(made.manager, made.account);
      await $.saveDraft();
      await $.messageShows('expenses.saved');
      final entry = (await Given.entries(made.manager)).single;
      expect(entry['amount'], 123.45);
    });

    phoneCase('D10: the entry\'s one date is saved as its payment date', ($) async {
      final made = await onPurchase($);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      expect((await Given.entries(made.manager)).single['entryDate'], DateTime.now().toIso8601String().substring(0, 10));
    });

    phoneCase('FR-09: a photo is kept first, and shows on the entry', ($) async {
      final made = await onPurchase($);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.choosePayment(made.manager, made.account);
      await $.saveDraft();
      await $.messageShows('expenses.saved');
      final entry = (await Given.entries(made.manager)).single['id'] as String;
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.reach($(AddEntryScreen.invoicePictureKey));
    });

    phoneCase('AC-41.1: custom columns are drawn, marked and sent', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      await Given.column(manager, table.itemId, 'رقم الأمر', required: true);
      final column = (await Given.columns(manager, table.itemId)).singleWhere((column) => column['name'] == 'رقم الأمر');
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.pickTable(table.tableId);
      await $.chooseANewSupplier(manager);
      await $.fill(AddEntryScreen.columnKey(column['key'] as String), '77');
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.choosePayment(manager, account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('a built-in column follows what Finance made of it', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final quantity = (await Given.columns(manager, table.itemId)).singleWhere((column) => column['key'] == 'quantity');
      await Given.columnDeleted(manager, table.itemId, quantity['id'] as String);
      await $.onAddEntry(manager);
      await $.pickTable(table.tableId);
      await $.goTo($(AddEntryScreen.amountKey));
      expect($(AddEntryScreen.columnKey('quantity')), findsNothing);
      expect($(AddEntryScreen.descriptionKey), findsOneWidget);
    });

    phoneCase('AC-43.1: the suppliers used most come first, under their title', ($) async {
      final manager = await Given.manager();
      final supplier = await Given.supplier(manager);
      await Given.entry(manager, supplierId: supplier);
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.supplierKey);
      await $.says(SupplierPicker.mostUsedKey, $.words.suppliersMostUsed);
      await $.reach($(SupplierPicker.rowKey(supplier)));
    });

    phoneCase('open question 4: with chargeAnyAccount any account is offered', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final table = await Given.firstPurchaseTable(manager);
      final member = await Given.member(manager, permissions: [Permission.recordEntries, Permission.chargeAnyAccount]);
      await $.onAddEntry(member);
      await $.pickTable(table.tableId);
      await $.goTo($(PaymentChoices.accountKey(account)));
    });

    phoneCase('AC-14.1: a deduction is a negative amount, sent with why in its notes', ($) async {
      final made = await onPurchase($);
      await $.fill(AddEntryScreen.amountKey, '-50');
      await $.fill(AddEntryScreen.descriptionKey, 'خصم جودة');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      expect((await Given.entries(made.manager)).single['amount'], -50);
    });

    phoneCase('R7: only tables taking a purchase or a contractor payment are offered', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'متعب');
      final member = await Given.member(manager, permissions: [Permission.recordEntries]);
      await $.onAddEntry(member);
      await $.tapOn(AddEntryScreen.tableKey);
      await $.reach($(TablePicker.searchKey));
      expect($(TablePicker.optionKey(partner)), findsNothing);
    });

    phoneCase('a table search that finds nothing says so', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.tableKey);
      await $(TablePicker.searchKey).enterText('لا يوجد ${Given.unique()}');
      await $.reach($(TablePicker.noMatchKey));
    });

    phoneCase('an amount that is not a number is refused here', ($) async {
      await onPurchase($);
      await $.fill(AddEntryScreen.amountKey, 'abc');
      await $.sendEntry();
      await $.says(AddEntryScreen.messageKey, $.words.expensesInvalidAmount);
    });

    phoneCase('a missing table or amount is refused here', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await $.sendEntry();
      await $.reach($(AddEntryScreen.messageKey));
      expect(await Given.entries(manager), isEmpty);
    });

    phoneCase('AC-41.1: a required custom column left empty is refused', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      await Given.column(manager, table.itemId, 'رقم الأمر', required: true);
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.pickTable(table.tableId);
      await $.chooseANewSupplier(manager);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.choosePayment(manager, account);
      await $.sendEntry();
      await $.says(AddEntryScreen.messageKey, $.words.expensesRequiredColumnMissing);
    });

    phoneCase('D14: a deduction with no notes is refused', ($) async {
      final made = await onPurchase($);
      await $.fill(AddEntryScreen.amountKey, '-50');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.says(AddEntryScreen.messageKey, $.words.expensesDeductionNeedsDescription);
    });

    phoneCase('open question 4: without chargeAnyAccount only the accounts held are offered', ($) async {
      final manager = await Given.manager();
      final other = await Given.account(manager);
      final table = await Given.firstPurchaseTable(manager);
      final member = await Given.member(manager, permissions: [Permission.recordEntries]);
      final custody = await Given.account(manager, custodian: member);
      await $.onAddEntry(member);
      await $.pickTable(table.tableId);
      await $.goTo($(PaymentChoices.accountKey(custody)));
      expect($(PaymentChoices.accountKey(other)), findsNothing);
    });

    phoneCase('AC-40.1: a disabled payment method is not offered', ($) async {
      final made = await onPurchase($);
      final methods = await Given.paymentMethods(made.manager);
      await Given.paymentMethodDisabled(made.manager, methods.first['id'] as String);
      await $.back();
      await $.pullDown();
      await $.tapOn(HomeScreen.addEntryKey(made.manager.projectId));
      await $.pickTable(made.table.tableId);
      await $.goTo($(PaymentChoices.paymentMethodKey(methods.last['id'] as String)));
      expect($(PaymentChoices.paymentMethodKey(methods.first['id'] as String)), findsNothing);
    });
  });
}
