// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:patrol/patrol.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/money_steps.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Accounts.
Future<void> onAccounts(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.accountsKey(person.projectId));
  await $.reach($(AccountsScreen.addKey));
}

void main() {
  phoneClass('An account\'s balance (UC-015 and UC-040)', () {
    phoneCase('redix-app #89: a balance is what came in less what went out, from nothing', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      final account = await Given.account(manager);
      final contract = await Given.contract(manager, value: 1000);
      await Given.entriesApproved(manager, [
        await Given.revenue(manager, amount: 500, accountId: account),
        await Given.entry(manager, amount: 200, accountId: account),
        await Given.contractorPayment(manager, contract, amount: 100, accountId: account),
        await Given.partnerMoney(manager, partner, amount: 300, accountId: account),
        await Given.partnerMoney(manager, partner, amount: 50, withdrawal: true, accountId: account),
      ]);
      await onAccounts($, manager);
      await $.says(AccountsScreen.balanceKey(account), '450.00');
    });

    phoneCase('BR-10: nothing that waits moves it, whatever its kind', ($) async {
      final money = await aProjectWithMoney();
      final partner = await Given.partner(money.manager, 'هيثم');
      final contract = await Given.contract(money.manager, value: 1000);
      await Given.entry(money.manager, amount: 100, accountId: money.account);
      await Given.revenue(money.manager, amount: 300, accountId: money.account);
      await Given.contractorPayment(money.manager, contract, amount: 50, accountId: money.account);
      await Given.partnerMoney(money.manager, partner, amount: 500, accountId: money.account);
      await onAccounts($, money.manager);
      await $.says(AccountsScreen.balanceKey(money.account), '(10.00)');
    });

    phoneCase('AC-50.1: a removal puts it back, whatever was removed', ($) async {
      final money = await aProjectWithMoney();
      final partner = await Given.partner(money.manager, 'هيثم');
      final contract = await Given.contract(money.manager, value: 1000);
      final entries = [
        await Given.entry(money.manager, amount: 100, accountId: money.account),
        await Given.revenue(money.manager, amount: 300, accountId: money.account),
        await Given.contractorPayment(money.manager, contract, amount: 50, accountId: money.account),
        await Given.partnerMoney(money.manager, partner, amount: 500, accountId: money.account),
      ];
      await Given.entriesApproved(money.manager, entries);
      for (final entry in entries) {
        await Given.entryRemoved(money.manager, entry);
      }
      await onAccounts($, money.manager);
      await $.says(AccountsScreen.balanceKey(money.account), '(10.00)');
    });

    phoneCase('each account moves only by its own entries', ($) async {
      final manager = await Given.manager();
      final first = await Given.account(manager);
      final second = await Given.account(manager);
      await Given.entriesApproved(manager, [await Given.entry(manager, amount: 100, accountId: first), await Given.revenue(manager, amount: 300, accountId: second)]);
      await onAccounts($, manager);
      await $.says(AccountsScreen.balanceKey(first), '(100.00)');
      await $.says(AccountsScreen.balanceKey(second), '300.00');
    });

    phoneCase('a custody shows the same balance on the home and on Accounts', ($) async {
      final manager = await Given.manager();
      final custody = await Given.account(manager, custodian: manager);
      await Given.entriesApproved(manager, [await Given.entry(manager, amount: 100, accountId: custody), await Given.revenue(manager, amount: 50.5, accountId: custody)]);
      await $.onTheHome(manager);
      await $.reach($(HomeScreen.custodyBalanceKey(custody)));
      await $.says(HomeScreen.custodyBalanceKey(custody), '(49.50) ${$.words.accountsRiyal}');
      await $.accountStands(manager, custody, '(49.50)');
    });

    phoneCase('moving a waiting purchase to another account takes the money from the new one once approved', ($) async {
      final manager = await Given.manager();
      final first = await Given.account(manager);
      final second = await Given.account(manager);
      final entry = await Given.entry(manager, amount: 100, accountId: first);
      await $.onTheEntry(manager, entry);
      await $.tapOn(AddEntryScreen.changeKey);
      await $.reach($(AddEntryScreen.amountKey));
      await $.tapOn(PaymentChoices.accountKey(second));
      await $.pumpAndSettle();
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      await Given.entriesApproved(manager, [entry]);
      await $.accountStands(manager, second, '(100.00)');
      await $.says(AccountsScreen.balanceKey(first), '0.00');
    });
  });
}
