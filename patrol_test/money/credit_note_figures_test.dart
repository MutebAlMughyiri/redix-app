import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/item_reports_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/money_steps.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager, an account that held nothing before, a supplier and that supplier's approved bill of [amount].
Future<({Person manager, String account, String supplier, String bill})> aBill({num amount = 500}) async {
  final manager = await Given.manager();
  final account = await Given.account(manager);
  final supplier = await Given.supplier(manager, name: 'مورد ${Given.unique()}');
  final bill = await Given.entry(manager, amount: amount, accountId: account, supplierId: supplier);
  await Given.entriesApproved(manager, [bill]);
  return (manager: manager, account: account, supplier: supplier, bill: bill);
}

/// A credit note of [amount] from the supplier of [made], naming no bill (redix-api #119, D4), sent for approval. Its id is answered.
Future<String> aNote(({Person manager, String account, String supplier, String bill}) made, num amount) =>
    Given.entry(made.manager, amount: amount, accountId: made.account, supplierId: made.supplier, creditNote: true);

/// Stands on Add entry with a credit note of [amount] from the supplier of [made], all filled in and not yet sent.
Future<void> fillNote(PatrolIntegrationTester $, ({Person manager, String account, String supplier, String bill}) made, String amount) async {
  await $.onAddEntry(made.manager);
  await $.pickTable((await Given.firstPurchaseTable(made.manager)).tableId);
  await $.tapOn(AddEntryScreen.supplierKey);
  await $.tapOn(SupplierPicker.rowKey(made.supplier));
  await $.pumpAndSettle();
  await $.tapOn(AddEntryScreen.columnKey('entryType'));
  await $.tapOn(AddEntryScreen.columnOptionKey('entryType', Given.creditNoteChoiceId));
  await $.pumpAndSettle();
  await $.fill(AddEntryScreen.amountKey, amount);
  await $.choosePayment(made.manager, made.account);
}

void main() {
  phoneClass('A credit note in the figures (AC-14.2, redix-api #119 D4)', () {
    phoneCase('AC-14.2: a credit note entered on the phone waits and moves nothing, and approving it lowers the expenses and returns the money', ($) async {
      final made = await aBill();
      await fillNote($, made, '100');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      await $.expensesWaiting(1, '(100.00)');
      await $.homeFigures(surplus: '(500.00)', revenue: '0.00', expenses: '500.00');
      await $.approveOnThePhone(made.manager, (await Given.waitingIds(made.manager)).single);
      await $.homeFigures(surplus: '(400.00)', revenue: '0.00', expenses: '400.00');
      await $.accountStands(made.manager, made.account, '(400.00)');
    });

    phoneCase('BR-10: a waiting credit note leaves the account alone', ($) async {
      final made = await aBill();
      await aNote(made, 100);
      await $.onTheHome(made.manager);
      await $.homeFigures(surplus: '(500.00)', revenue: '0.00', expenses: '500.00');
      await $.accountStands(made.manager, made.account, '(500.00)');
    });

    phoneCase('BR-10: a rejected credit note counts nowhere', ($) async {
      final made = await aBill();
      await Given.entryRejected(made.manager, await aNote(made, 100));
      await $.onTheHome(made.manager);
      await $.homeFigures(surplus: '(500.00)', revenue: '0.00', expenses: '500.00');
      await $.nothingWaits();
      await $.accountStands(made.manager, made.account, '(500.00)');
    });

    phoneCase('AC-50.1: removing an approved credit note brings the expense and the account back', ($) async {
      final made = await aBill();
      final note = await aNote(made, 100);
      await Given.entriesApproved(made.manager, [note]);
      await Given.entryRemoved(made.manager, note);
      await $.onTheHome(made.manager);
      await $.homeFigures(surplus: '(500.00)', revenue: '0.00', expenses: '500.00');
      await $.accountStands(made.manager, made.account, '(500.00)');
    });

    phoneCase('AC-30.1: the item report shows the bill less what came back', ($) async {
      final made = await aBill();
      await Given.entriesApproved(made.manager, [await aNote(made, 100)]);
      final table = await Given.firstPurchaseTable(made.manager);
      await $.onTheHome(made.manager);
      await $.openReportCategory(made.manager, table.category);
      await $.says(ItemReportsScreen.itemKey(table.itemId).trailing, '400.00');
      await $.tapOn(ItemReportsScreen.itemKey(table.itemId));
      await $.says(ItemReportScreen.totalKey, '400.00');
    });

    phoneCase('D4: a credit note is held to no bill, so one above what is left of every bill is sent', ($) async {
      final made = await aBill();
      await aNote(made, 300);
      await fillNote($, made, '300');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });
  });
}
