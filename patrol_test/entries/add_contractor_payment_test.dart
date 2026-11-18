// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager, an account and a contract of [value], standing on Add entry with the contract's table picked.
Future<({Person manager, String account, MadeContract contract})> onPayment(PatrolIntegrationTester $, {num value = 34000, bool openValue = false}) async {
  final manager = await Given.manager(project: 'غصون 7');
  final account = await Given.account(manager, name: 'حساب المؤسسة');
  final contract = await Given.contract(manager, value: value, openValue: openValue, contractor: 'مبلط الغربية');
  await $.onAddEntry(manager);
  await $.pickTable(contract.id, search: contract.contractor);
  return (manager: manager, account: account, contract: contract);
}

/// A payment of [amount] on [contract], approved.
Future<void> paid(Person manager, MadeContract contract, num amount) async {
  await Given.entriesApproved(manager, [await Given.contractorPayment(manager, contract, amount: amount)]);
}

void main() {
  phoneClass('Add a contractor payment (UC-027)', () {
    phoneCase('R10: a contract\'s table takes the payment, sent with its contract', ($) async {
      final made = await onPayment($);
      await $.fill(AddEntryScreen.amountKey, '35000');
      await $.reach($(AddEntryScreen.overrunKey));
      await $.picture('contractor-payment');
      await $.choosePayment(made.manager, made.account);
      await $.goTo($(AddEntryScreen.sendKey));
      await $.picture('contractor-payment-send');
      await $.sendEntry();
      await $.messageShows('contractorPayments.savedOverrun');
    });

    phoneCase('AC-12.1: value, paid and what remains show before saving', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await paid(manager, contract, 400);
      await $.onAddEntry(manager);
      await $.pickTable(contract.id, search: contract.contractor);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.pumpAndSettle();
      await $.says(AddEntryScreen.valueKey, '1,000.00');
      await $.says(AddEntryScreen.paidKey, '400.00');
      await $.says(AddEntryScreen.remainingKey, '500.00');
    });

    phoneCase('AC-07.1: an overrun alerts with its amount in brackets, and is still saved', ($) async {
      final made = await onPayment($, value: 1000);
      await $.fill(AddEntryScreen.amountKey, '1500');
      await $.pumpAndSettle();
      await $.reach($(AddEntryScreen.overrunKey));
      await $.says(AddEntryScreen.remainingKey, '(500.00)');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.messageShows('contractorPayments.savedOverrun');
    });

    phoneCase('what waits shows beside what was paid, and counts', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await Given.contractorPayment(manager, contract, amount: 300);
      await $.onAddEntry(manager);
      await $.pickTable(contract.id, search: contract.contractor);
      await $.says(AddEntryScreen.pendingKey, '${$.words.contractsPending} 300.00');
      await $.says(AddEntryScreen.remainingKey, '700.00');
    });

    phoneCase('AC-07.2: an open value shows no remaining, bar or alert', ($) async {
      await onPayment($, openValue: true);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.pumpAndSettle();
      await $.says(AddEntryScreen.remainingKey, '—');
      expect($(AddEntryScreen.progressKey), findsNothing);
      expect($(AddEntryScreen.overrunKey), findsNothing);
    });

    phoneCase('AC-13.1: a payment outside the contract leaves what remains unchanged', ($) async {
      await onPayment($, value: 1000);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.tapOn(AddEntryScreen.outsideKey);
      await $.pumpAndSettle();
      await $.goTo($(AddEntryScreen.remainingKey));
      await $.says(AddEntryScreen.remainingKey, '1,000.00');
    });

    phoneCase('AC-14.1: a deduction is negative, raises what remains, and says why in its notes', ($) async {
      final made = await onPayment($, value: 1000);
      await $.fill(AddEntryScreen.amountKey, '-100');
      await $.pumpAndSettle();
      await $.says(AddEntryScreen.remainingKey, '1,100.00');
      await $.fill(AddEntryScreen.descriptionKey, 'خصم جودة');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('D16: a receipt taken is kept and sent', ($) async {
      final made = await onPayment($);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('D16: a payment is sent with no receipt', ($) async {
      final made = await onPayment($);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('FR-41: its item\'s custom columns show and are sent', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      await Given.column(manager, contract.itemId, 'رقم المستخلص');
      final column = (await Given.columns(manager, contract.itemId)).singleWhere((column) => column['name'] == 'رقم المستخلص');
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.pickTable(contract.id, search: contract.contractor);
      await $.fill(AddEntryScreen.columnKey(column['key'] as String), '5');
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.choosePayment(manager, account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('a disabled contract is not on offer', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      await Given.contractDisabled(manager, contract.id);
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.tableKey);
      await $.reach($(TablePicker.searchKey));
      expect($(TablePicker.optionKey(contract.id)), findsNothing);
    });

    phoneCase('D14: a deduction with no notes is refused', ($) async {
      final made = await onPayment($);
      await $.fill(AddEntryScreen.amountKey, '-100');
      await $.choosePayment(made.manager, made.account);
      await $.sendEntry();
      await $.says(AddEntryScreen.messageKey, $.words.expensesDeductionNeedsDescription);
    });
  });
}
