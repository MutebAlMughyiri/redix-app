import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager, their account and an approved bill of [amount] from a supplier, standing on Add entry as a credit note for that supplier, «مرتجع» chosen in «نوع القيد», which
/// names no bill (redix-api #119 D4, #129).
Future<({Person manager, String account, String bill, String supplier})> onCreditNote(PatrolIntegrationTester $, {num amount = 500}) async {
  final manager = await Given.manager(project: 'غصون 7');
  final account = await Given.account(manager, name: 'حساب المؤسسة');
  final supplier = await Given.supplier(manager, name: 'مورد الميدان');
  final bill = await Given.entry(manager, amount: amount, accountId: account, supplierId: supplier);
  await Given.entriesApproved(manager, [bill]);
  final table = await Given.firstPurchaseTable(manager);
  await $.onAddEntry(manager);
  await $.pickTable(table.tableId);
  await $.tapOn(AddEntryScreen.supplierKey);
  await $.tapOn(SupplierPicker.rowKey(supplier));
  await $.pumpAndSettle();
  await $.tapOn(AddEntryScreen.columnKey('entryType'));
  await $.tapOn(AddEntryScreen.columnOptionKey('entryType', Given.creditNoteChoiceId).label);
  await $.pumpAndSettle();
  return (manager: manager, account: account, bill: bill, supplier: supplier);
}

void main() {
  phoneClass('A credit note (UC-026)', () {
    phoneCase('AC-14.2, D4: a credit note sends a plain amount, names no bill, and is kept as a minus row', ($) async {
      final made = await onCreditNote($);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.choosePayment(made.manager, made.account);
      await $.tester.ensureVisible(find.byKey(AddEntryScreen.columnKey('entryType')));
      await $.pumpAndSettle();
      await $.picture('add-expense-credit-note');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      final note = (await Given.entries(made.manager)).singleWhere((entry) => entry['id'] != made.bill);
      expect(note['amount'], -100);
    });

    phoneCase('D4: a credit note above every bill of its supplier is sent all the same', ($) async {
      final made = await onCreditNote($, amount: 100);
      await $.fill(AddEntryScreen.amountKey, '500');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });
  });
}
