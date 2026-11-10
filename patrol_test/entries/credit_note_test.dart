import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/expenses/original_invoice_picker.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager, their account and an approved bill of [amount] from a supplier, standing on Add entry as a credit note for that supplier.
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
  await $.tapOn(AddEntryScreen.creditNoteKey);
  await $.pumpAndSettle();
  return (manager: manager, account: account, bill: bill, supplier: supplier);
}

void main() {
  phoneClass('A credit note (UC-026)', () {
    phoneCase('AC-14.2: a credit note names the bill it returns and sends a plain amount', ($) async {
      final made = await onCreditNote($);
      await $.tapOn(AddEntryScreen.originalInvoiceKey);
      await $.tapOn(OriginalInvoicePicker.optionKey(made.bill));
      await $.pumpAndSettle();
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.choosePayment(made.manager, made.account);
      await $.tester.ensureVisible(find.byKey(AddEntryScreen.originalInvoiceKey));
      await $.pumpAndSettle();
      await $.picture('add-expense-credit-note');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('a new bill shows its date', ($) async {
      final made = await onCreditNote($);
      await $.tapOn(AddEntryScreen.originalInvoiceKey);
      await $.reach($(OriginalInvoicePicker.optionKey(made.bill)));
      expect(find.descendant(of: find.byKey(OriginalInvoicePicker.optionKey(made.bill)), matching: find.textContaining(formatDate(DateTime.now()))), findsWidgets);
    });

    phoneCase('changing the supplier takes the link away', ($) async {
      final made = await onCreditNote($);
      final other = await Given.supplier(made.manager, name: 'مورد آخر');
      await $.tapOn(AddEntryScreen.originalInvoiceKey);
      await $.tapOn(OriginalInvoicePicker.optionKey(made.bill));
      await $.pumpAndSettle();
      await $.tapOn(AddEntryScreen.supplierKey);
      await $.tapOn(SupplierPicker.rowKey(other));
      await $.pumpAndSettle();
      await $.goTo($(AddEntryScreen.originalInvoiceKey));
      expect(find.descendant(of: find.byKey(AddEntryScreen.originalInvoiceKey), matching: find.textContaining(formatDate(DateTime.now()))), findsNothing);
    });

    phoneCase('BR-18: an amount above what is left of the bill is blocked with a message', ($) async {
      final made = await onCreditNote($, amount: 100);
      await $.tapOn(AddEntryScreen.originalInvoiceKey);
      await $.tapOn(OriginalInvoicePicker.optionKey(made.bill));
      await $.pumpAndSettle();
      await $.fill(AddEntryScreen.amountKey, '500');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.says(AddEntryScreen.messageKey, $.words.expensesCreditNoteAboveOriginal);
      expect($(AddEntryScreen.supplierKey.label), findsWidgets);
    });
  });
}
