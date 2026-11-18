// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/expenses/payment_choices.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/money_steps.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Picks the VAT refund table in Add entry by searching for it.
Future<void> pickRefund(PatrolIntegrationTester $, Person person) async {
  await $.tapOn(AddEntryScreen.tableKey);
  await $(TablePicker.searchKey).enterText('استرجاع');
  final id = await $.idOf('tablePicker.option.', () => Given.entryTableNamed(person, 'استرجاع الضرائب'));
  await $.tapOn(TablePicker.optionKey(id));
  await $.pumpAndSettle();
}

void main() {
  phoneClass('Revenue in the figures (BR-06 and BR-07)', () {
    phoneCase('BR-10: revenue entered on the phone waits and moves nothing, and approving it raises the revenue, the surplus and its account', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await pickRefund($, manager);
      await $.fill(AddEntryScreen.amountKey, '300.75');
      await $.tapOn(PaymentChoices.accountKey(account));
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      await $.revenueWaiting(1, '300.75');
      await $.homeFigures(surplus: '0.00', revenue: '0.00', expenses: '0.00');
      await $.approveOnThePhone(manager, (await Given.waitingIds(manager)).single);
      await $.homeFigures(surplus: '300.75', revenue: '300.75', expenses: '0.00');
      await $.nothingWaits();
      await $.accountStands(manager, account, '300.75');
    });

    phoneCase('BR-10: waiting revenue leaves the revenue and its account alone', ($) async {
      final money = await aProjectWithMoney();
      await Given.revenue(money.manager, amount: 300, accountId: money.account);
      await $.onTheHome(money.manager);
      await $.homeFigures(surplus: '(10.00)', revenue: '0.00', expenses: '10.00');
      await $.revenueWaiting(1, '300.00');
      await $.accountStands(money.manager, money.account, '(10.00)');
    });

    phoneCase('BR-10: draft revenue counts nowhere, not even as waiting', ($) async {
      final money = await aProjectWithMoney();
      await Given.revenue(money.manager, sent: false, amount: 300, accountId: money.account);
      await $.onTheHome(money.manager);
      await $.homeFigures(surplus: '(10.00)', revenue: '0.00', expenses: '10.00');
      await $.nothingWaits();
    });

    phoneCase('BR-10: rejected revenue leaves what waits, and counts nowhere', ($) async {
      final money = await aProjectWithMoney();
      await Given.entryRejected(money.manager, await Given.revenue(money.manager, amount: 300, accountId: money.account));
      await $.onTheHome(money.manager);
      await $.homeFigures(surplus: '(10.00)', revenue: '0.00', expenses: '10.00');
      await $.nothingWaits();
    });

    phoneCase('AC-50.1: removing revenue takes it back out of the revenue, the surplus and the account', ($) async {
      final money = await aProjectWithMoney();
      final entry = await Given.revenue(money.manager, amount: 300, accountId: money.account);
      await Given.entriesApproved(money.manager, [entry]);
      await Given.entryRemoved(money.manager, entry);
      await $.onTheHome(money.manager);
      await $.homeFigures(surplus: '(10.00)', revenue: '0.00', expenses: '10.00');
      await $.accountStands(money.manager, money.account, '(10.00)');
    });

    phoneCase('several revenue entries add up to the halala', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await Given.entriesApproved(manager, [for (final amount in [100.10, 200.20, 0.03]) await Given.revenue(manager, amount: amount, accountId: account)]);
      await $.onTheHome(manager);
      await $.homeFigures(surplus: '300.33', revenue: '300.33', expenses: '0.00');
      await $.accountStands(manager, account, '300.33');
    });

    phoneCase('BR-07: the surplus is the revenue less the expenses', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await Given.entriesApproved(manager, [await Given.revenue(manager, amount: 1000.5, accountId: account), await Given.entry(manager, amount: 250.25, accountId: account)]);
      await $.onTheHome(manager);
      await $.homeFigures(surplus: '750.25', revenue: '1,000.50', expenses: '250.25');
    });
  });
}
