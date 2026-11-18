// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/item_reports_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/money_steps.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Contracts.
Future<void> onContracts(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.contractsKey(person.projectId));
  await $.reach($(ContractsScreen.addKey));
}

/// Goes back to the home of [person] and opens Contracts again, which reads them again.
Future<void> reopenContracts(PatrolIntegrationTester $, Person person) async {
  await $.back();
  await $.tapOn(HomeScreen.contractsKey(person.projectId));
  await $.reach($(ContractsScreen.addKey));
}

/// A payment of [amount] on [contract], approved. Its id is answered.
Future<String> approvedPayment(Person manager, MadeContract contract, num amount, {String accountId = '', bool outside = false, String notes = ''}) async {
  final payment = await Given.contractorPayment(manager, contract, amount: amount, accountId: accountId, outside: outside, notes: notes);
  await Given.entriesApproved(manager, [payment]);
  return payment;
}

/// The standing of the contract [id] says [text].
Future<void> standsAs(PatrolIntegrationTester $, String id, String text) => $.says(ContractsScreen.standingKey(id).label, text);

void main() {
  phoneClass('A contract\'s figures as its payments move (AC-07.1 and AC-12.1)', () {
    phoneCase('AC-12.1: a payment entered on the phone waits on its contract, and the next payment counts it', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final contract = await Given.contract(manager, value: 1000);
      await $.onAddEntry(manager);
      await $.pickTable(contract.id, search: contract.contractor);
      await $.fill(AddEntryScreen.amountKey, '300');
      await $.pumpAndSettle();
      await $.says(AddEntryScreen.remainingKey, '700.00');
      await $.choosePayment(manager, account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      await $.tapOn(HomeScreen.addEntryKey(manager.projectId));
      await $.reach($(AddEntryScreen.tableKey));
      await $.pickTable(contract.id, search: contract.contractor);
      await $.says(AddEntryScreen.paidKey, '0.00');
      await $.says(AddEntryScreen.pendingKey, '${$.words.contractsPending} 300.00');
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.pumpAndSettle();
      await $.says(AddEntryScreen.remainingKey, '600.00');
    });

    phoneCase('AC-07.1: approval moves a payment from waiting to paid, lowers what remains, is an expense, and leaves its account', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final contract = await Given.contract(manager, value: 1000);
      final payment = await Given.contractorPayment(manager, contract, amount: 300, accountId: account);
      await onContracts($, manager);
      await $.contractStands(contract.id, paid: '0.00', remaining: '1,000.00', pending: '300.00', afterApproval: '700.00');
      await Given.entriesApproved(manager, [payment]);
      await reopenContracts($, manager);
      await $.contractStands(contract.id, paid: '300.00', remaining: '700.00');
      await $.back();
      await $.homeFigures(surplus: '(300.00)', revenue: '0.00', expenses: '300.00');
      await $.accountStands(manager, account, '(300.00)');
    });

    phoneCase('a draft payment is in neither what was paid nor what waits', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await Given.contractorPayment(manager, contract, amount: 300, sent: false);
      await onContracts($, manager);
      await $.contractStands(contract.id, paid: '0.00', remaining: '1,000.00');
    });

    phoneCase('a rejected payment leaves what waits, and what remains', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await Given.entryRejected(manager, await Given.contractorPayment(manager, contract, amount: 300));
      await onContracts($, manager);
      await $.contractStands(contract.id, paid: '0.00', remaining: '1,000.00');
    });

    phoneCase('AC-50.1: a removed payment leaves what was paid, and what remains comes back', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await approvedPayment(manager, contract, 200);
      await Given.entryRemoved(manager, await approvedPayment(manager, contract, 300));
      await onContracts($, manager);
      await $.contractStands(contract.id, paid: '200.00', remaining: '800.00');
    });

    phoneCase('several payments add up to the halala', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      for (final amount in [100.10, 200.20, 0.03]) {
        await approvedPayment(manager, contract, amount);
      }
      await onContracts($, manager);
      await $.contractStands(contract.id, paid: '300.33', remaining: '699.67');
    });

    phoneCase('AC-07.1: paying exactly the value leaves nothing and raises no overrun', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await approvedPayment(manager, contract, 1000);
      await onContracts($, manager);
      await $.contractStands(contract.id, paid: '1,000.00', remaining: '0.00');
      await standsAs($, contract.id, $.words.contractsRunning);
    });

    phoneCase('AC-07.1: one halala beyond the value is an overrun', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await approvedPayment(manager, contract, 1000.01);
      await onContracts($, manager);
      await $.contractStands(contract.id, paid: '1,000.01', remaining: '(0.01)');
      await standsAs($, contract.id, $.words.contractsOverrun);
    });

    phoneCase('AC-13.1: a payment outside the contract stays out of its figures, yet is an expense and leaves its account', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final contract = await Given.contract(manager, value: 1000);
      await approvedPayment(manager, contract, 300, accountId: account, outside: true);
      await onContracts($, manager);
      await $.contractStands(contract.id, paid: '0.00', remaining: '1,000.00');
      await $.back();
      await $.homeFigures(surplus: '(300.00)', revenue: '0.00', expenses: '300.00');
      await $.accountStands(manager, account, '(300.00)');
    });

    phoneCase('AC-14.1: a deduction lowers what was paid and the expenses, and raises what remains and the account', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final contract = await Given.contract(manager, value: 1000);
      await approvedPayment(manager, contract, 500, accountId: account);
      await approvedPayment(manager, contract, -100, accountId: account, notes: 'خصم تأخير');
      await onContracts($, manager);
      await $.contractStands(contract.id, paid: '400.00', remaining: '600.00');
      await $.back();
      await $.homeFigures(surplus: '(400.00)', revenue: '0.00', expenses: '400.00');
      await $.accountStands(manager, account, '(400.00)');
    });

    phoneCase('AC-07.2: an open-value contract adds up what was paid and shows no remaining', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, openValue: true);
      await approvedPayment(manager, contract, 100);
      await approvedPayment(manager, contract, 250.5);
      await onContracts($, manager);
      await $.contractStands(contract.id, paid: '350.50', remaining: '—');
    });

    phoneCase('AC-12.1: opening a waiting payment counts it once', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      final payment = await Given.contractorPayment(manager, contract, amount: 500);
      await $.onTheEntry(manager, payment);
      await $.says(AddEntryScreen.paidKey, '0.00');
      await $.says(AddEntryScreen.pendingKey, '${$.words.contractsPending} 500.00');
      await $.says(AddEntryScreen.remainingKey, '500.00');
      expect($(AddEntryScreen.overrunKey), findsNothing);
    });

    phoneCase('AC-12.1: opening an approved payment counts it once, and raises no false overrun', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      final payment = await approvedPayment(manager, contract, 800);
      await $.onTheEntry(manager, payment);
      await $.says(AddEntryScreen.paidKey, '800.00');
      await $.says(AddEntryScreen.remainingKey, '200.00');
      expect($(AddEntryScreen.overrunKey), findsNothing);
    });

    phoneCase('AC-12.1: opening a draft counts it, since neither figure holds it yet', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      final payment = await Given.contractorPayment(manager, contract, amount: 300, sent: false);
      await $.onTheEntry(manager, payment);
      await $.says(AddEntryScreen.remainingKey, '700.00');
    });

    phoneCase('AC-12.1: opening a rejected payment counts it, since neither figure holds it', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      final payment = await Given.contractorPayment(manager, contract, amount: 300);
      await Given.entryRejected(manager, payment);
      await $.onTheEntry(manager, payment);
      await $.says(AddEntryScreen.remainingKey, '700.00');
    });

    phoneCase('AC-12.1: changing what a waiting payment comes to counts only the change', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      final payment = await Given.contractorPayment(manager, contract, amount: 500);
      await $.onTheEntry(manager, payment);
      await $.tapOn(AddEntryScreen.changeKey);
      await $.reach($(AddEntryScreen.amountKey));
      await $.fill(AddEntryScreen.amountKey, '700');
      await $.pumpAndSettle();
      await $.says(AddEntryScreen.remainingKey, '300.00');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      await $.tapOn(HomeScreen.contractsKey(manager.projectId));
      await $.reach($(ContractsScreen.addKey));
      await $.contractStands(contract.id, paid: '0.00', remaining: '1,000.00', pending: '700.00', afterApproval: '300.00');
    });

    phoneCase('AC-13.1: moving a waiting payment outside the contract takes it out of what remains', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      final payment = await Given.contractorPayment(manager, contract, amount: 500);
      await $.onTheEntry(manager, payment);
      await $.tapOn(AddEntryScreen.changeKey);
      await $.tapOn(AddEntryScreen.outsideKey);
      await $.pumpAndSettle();
      await $.says(AddEntryScreen.remainingKey, '1,000.00');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      await $.tapOn(HomeScreen.contractsKey(manager.projectId));
      await $.reach($(ContractsScreen.addKey));
      await $.contractStands(contract.id, paid: '0.00', remaining: '1,000.00');
    });

    phoneCase('AC-30.1: the item report shows the contract as Contracts does, leaving out what waits', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await approvedPayment(manager, contract, 300);
      await Given.contractorPayment(manager, contract, amount: 100);
      final category = await Given.categoryOf(manager, contract.itemId);
      await $.onTheHome(manager);
      await $.openReportCategory(manager, category);
      await $.says(ItemReportsScreen.itemKey(contract.itemId).trailing, '300.00');
      await $.tapOn(ItemReportsScreen.itemKey(contract.itemId));
      await $.goTo($(ItemReportScreen.contractCardKey(contract.id)));
      await $.says(ItemReportScreen.contractKey(contract.id), '${$.words.reportsContractValue}: 1,000.00 · ${$.words.reportsPaid}: 300.00 · ${$.words.reportsRemaining}: 700.00');
      await $.says(ItemReportScreen.contractTotalKey(contract.id), '${$.words.reportsGrandTotal}: 300.00');
    });
  });
}
