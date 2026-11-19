// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/accounts/account_history_screen.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/accounts/transfer_dialog.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/format/number_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/search_scope.dart';
import 'package:redix/words/word_fill.dart';

import '../support/given.dart';
import '../support/money_steps.dart';
import '../support/phone_case.dart';
import '../support/search_steps.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Accounts.
Future<void> onAccounts(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.accountsKey(person.projectId));
  await $.reach($(AccountsScreen.historyKey));
}

/// From Accounts, moves [amount] from the first active account to the next, as the dialog offers them.
Future<void> transferOnThePhone(PatrolIntegrationTester $, String amount) async {
  await $.tapOn(AccountsScreen.transferKey);
  await $.fill(TransferDialog.amountKey, amount);
  await $(ChangeDialog.saveKey).tap();
  await $.gone($(TransferDialog.amountKey));
}

/// From Accounts, opens History.
Future<void> onHistory(PatrolIntegrationTester $) async {
  await $.tapOn(AccountsScreen.historyKey);
  await $.reach($(SearchIcons.searchKey));
}

/// The id of the one line of the accounts' History of [person]'s project that [isLine] picks, as the API answers it to [person].
Future<int> historyLine(Person person, bool Function(Map<String, dynamic> line) isLine) async => (await Given.history(person, 'accounts/history')).singleWhere(isLine)['id'] as int;

/// The ids of every line of the accounts' History of [person]'s project.
Future<List<int>> historyLines(Person person) async => [for (final line in await Given.history(person, 'accounts/history')) line['id'] as int];

/// Waits until the History line [line] says [text].
Future<void> historySays(PatrolIntegrationTester $, int line, String text) => $.says(AccountHistoryScreen.lineKey(line).title, text);

/// History shows none of [lines].
void showsNoneOf(PatrolIntegrationTester $, List<int> lines) {
  for (final line in lines) {
    expect($(AccountHistoryScreen.lineKey(line)), findsNothing);
  }
}

void main() {
  phoneClass('Transfers, deleting and History on Accounts (redix-app #89)', () {
    phoneCase('FR-23: a transfer on the phone moves money between two accounts at once', ($) async {
      final manager = await Given.manager();
      final bank = await Given.account(manager, name: 'حساب ${Given.unique()}');
      final custody = await Given.account(manager, name: 'كاش ${Given.unique()}', custodian: manager);
      await Given.funded(manager, bank, 1000);
      await onAccounts($, manager);
      await $.tapOn(AccountsScreen.transferKey);
      await $.says(TransferDialog.balanceNowKey, $.words.transfersBalanceNow.fill(['1,000.00']));
      await $.fill(TransferDialog.amountKey, '400');
      await $.picture('transfer');
      await $(ChangeDialog.saveKey).tap();
      await $.says(AccountsScreen.balanceKey(bank), '600.00');
      await $.says(AccountsScreen.balanceKey(custody), '400.00');
    });

    phoneCase('R26: more than the account holds is refused in the transfer\'s own words, and nothing moves', ($) async {
      final manager = await Given.manager();
      final bank = await Given.account(manager);
      await Given.account(manager, custodian: manager);
      await Given.funded(manager, bank, 100);
      await onAccounts($, manager);
      await $.tapOn(AccountsScreen.transferKey);
      await $.fill(TransferDialog.amountKey, '500');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.transfersInsufficientBalance);
      await $(ChangeDialog.cancelKey).tap();
      await $.says(AccountsScreen.balanceKey(bank), '100.00');
    });

    phoneCase('the short custody flow: the inbox notes the gap, a transfer takes the note away, and the approval leaves both accounts right', ($) async {
      final manager = await Given.manager();
      final bank = await Given.account(manager);
      final custodyName = 'كاش ${Given.unique()}';
      final custody = await Given.account(manager, name: custodyName, custodian: manager);
      await Given.funded(manager, bank, 1000);
      final purchase = await Given.entry(manager, amount: 300, accountId: custody);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.approvalsKey(manager.projectId));
      await $.says(ApprovalsScreen.shortKey(purchase).label, $.words.approvalsAccountShort.fill([custodyName, formatMoney(0), formatMoney(300), formatMoney(300)]));
      await $.picture('approvals-short');
      await $.back();
      await $.tapOn(HomeScreen.accountsKey(manager.projectId));
      await transferOnThePhone($, '300');
      await $.back();
      await $.tapOn(HomeScreen.approvalsKey(manager.projectId));
      await $.reach($(ApprovalsScreen.cardKey(purchase)));
      await $.gone($(ApprovalsScreen.shortKey(purchase)));
      await $.back();
      await $.approveOnThePhone(manager, purchase);
      await $.accountStands(manager, custody, '0.00');
      await $.says(AccountsScreen.balanceKey(bank), '700.00');
    });

    phoneCase('Muteb, 10 Nov 2026: two purchases that each fit but not together are both noted with the whole gap', ($) async {
      final manager = await Given.manager();
      final bankName = 'حساب ${Given.unique()}';
      final bank = await Given.account(manager, name: bankName);
      await Given.funded(manager, bank, 1000);
      final first = await Given.entry(manager, amount: 600, accountId: bank);
      final second = await Given.entry(manager, amount: 600, accountId: bank);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.approvalsKey(manager.projectId));
      final note = $.words.approvalsAccountShort.fill([bankName, formatMoney(1000), formatMoney(1200), formatMoney(200)]);
      await $.says(ApprovalsScreen.shortKey(first).label, note);
      await $.reach($(ApprovalsScreen.shortKey(second)));
      await $.says(ApprovalsScreen.shortKey(second).label, note);
    });

    phoneCase('BR-15: an account nothing names is deleted after the question', ($) async {
      final manager = await Given.manager();
      final spare = await Given.account(manager);
      await onAccounts($, manager);
      await $.menuChoice(AccountsScreen.menuKey(spare), AccountsScreen.deleteKey);
      await $(ConfirmDialog.confirmKey).tap();
      await $.messageShows('accounts.deleted');
      await $.gone($(AccountsScreen.rowKey(spare)));
    });

    phoneCase('BR-15: an account an entry names keeps Delete gray, saying why', ($) async {
      final manager = await Given.manager();
      final used = await Given.account(manager);
      await Given.entry(manager, sent: false, accountId: used);
      await onAccounts($, manager);
      await $.tapOn(AccountsScreen.menuKey(used));
      await $.says(AccountsScreen.deleteKey.subtitle, $.words.accountsAccountInUse);
      expect($.tester.widget<PopupMenuItem<VoidCallback>>(find.byKey(AccountsScreen.deleteKey)).enabled, isFalse);
    });

    phoneCase('H1, H2: History shows this project\'s transfers, approvals and checks with who, and never another project\'s', ($) async {
      final a = await Given.manager();
      final b = await Given.manager();
      final aFirst = 'حساب ${Given.unique()}';
      final aSecond = 'كاش ${Given.unique()}';
      final bName = 'غيرهم ${Given.unique()}';
      final first = await Given.account(a, name: aFirst);
      final second = await Given.account(a, name: aSecond);
      await Given.funded(a, first, 1000);
      await Given.transferred(a, first, second, 400);
      await Given.reconciled(a, {first: 600, second: 400});
      final theirs = await Given.account(b, name: bName);
      await Given.funded(b, theirs, 500);
      await Given.transferred(b, theirs, await Given.account(b), 100);
      await onAccounts($, a);
      await onHistory($);
      await historySays($, await historyLine(a, (line) => line['kind'] == 'transfer'), $.words.historyTransfer.fill([formatMoney(400), aFirst, aSecond]));
      await historySays($, await historyLine(a, (line) => line['kind'] == 'check'), $.words.historyCheck.fill([formatMoney(1000)]));
      await $.picture('account-history');
      showsNoneOf($, await historyLines(b));
    });

    phoneCase('H3: a person in two projects sees each project\'s lines only under it', ($) async {
      final a = await Given.manager();
      final b = await Given.manager();
      final aName = 'حساب ${Given.unique()}';
      final bName = 'حساب ${Given.unique()}';
      await Given.account(a, name: aName);
      await Given.account(b, name: bName);
      final both = await Given.member(a);
      await Given.joined(both, by: b);
      await onAccounts($, both);
      await onHistory($);
      await historySays($, await historyLine(a, (line) => line['account'] == aName), $.words.historyAccountCreated.fill([aName]));
      showsNoneOf($, await historyLines(b));
      await $.back();
      await $.back();
      await $(HomeScreen.sharedSettingsKey(both.projectId)).tap();
      await $.tapOn(SharedSettingsScreen.switchProjectKey);
      await $.openProject(b.projectId);
      await $.tapOn(HomeScreen.accountsKey(b.projectId));
      await onHistory($);
      await historySays($, await historyLine(b, (line) => line['account'] == bName), $.words.historyAccountCreated.fill([bName]));
      showsNoneOf($, await historyLines(a));
    });

    phoneCase('H7: a deleted account\'s lines stay in its project\'s History with its name', ($) async {
      final manager = await Given.manager();
      final name = 'احتياطي ${Given.unique()}';
      final spare = await Given.account(manager, name: name);
      await onAccounts($, manager);
      await $.menuChoice(AccountsScreen.menuKey(spare), AccountsScreen.deleteKey);
      await $(ConfirmDialog.confirmKey).tap();
      await $.gone($(AccountsScreen.rowKey(spare)));
      await onHistory($);
      await historySays($, await historyLine(manager, (line) => line['kind'] == 'accountDeleted'), $.words.historyAccountDeleted.fill([name]));
      await historySays($, await historyLine(manager, (line) => line['kind'] == 'accountCreated' && line['account'] == name), $.words.historyAccountCreated.fill([name]));
    });

    phoneCase('H9: a partner\'s money shows in History only to whoever sees all capital', ($) async {
      final manager = await Given.manager();
      final name = 'حساب ${Given.unique()}';
      final account = await Given.account(manager, name: name);
      final partner = await Given.partner(manager, 'هيثم');
      await Given.entriesApproved(manager, [await Given.partnerMoney(manager, partner, amount: 5000, accountId: account)]);
      final reader = await Given.member(manager);
      final partnerMoney = await historyLine(manager, (line) => line['kind'] == 'entryIn' && line['entryKind'] == 'capitalIn');
      await onAccounts($, manager);
      await onHistory($);
      await $.saysContaining(AccountHistoryScreen.lineKey(partnerMoney).title, $.words.capitalContribution);
      await $.startApp();
      await onAccounts($, reader);
      await onHistory($);
      await historySays($, await historyLine(reader, (line) => line['kind'] == 'accountCreated' && line['account'] == name), $.words.historyAccountCreated.fill([name]));
      expect($(AccountHistoryScreen.lineKey(partnerMoney)), findsNothing);
    });

    phoneCase('redix-app #104: History asks the API for what was typed, and choosing an account under the arrow keeps it', ($) async {
      final manager = await Given.manager();
      final firstName = 'بنك ${Given.unique()}';
      final secondName = 'كاش ${Given.unique()}';
      final first = await Given.account(manager, name: firstName);
      final second = await Given.account(manager, name: secondName);
      await Given.funded(manager, first, 1000);
      await Given.transferred(manager, first, second, 100);
      await Given.account(manager, name: 'صندوق ${Given.unique()}');
      final transferLine = await historyLine(manager, (line) => line['kind'] == 'transfer');
      final firstAddedLine = await historyLine(manager, (line) => line['kind'] == 'accountCreated' && line['account'] == firstName);
      final secondAddedLine = await historyLine(manager, (line) => line['kind'] == 'accountCreated' && line['account'] == secondName);
      await onAccounts($, manager);
      await onHistory($);
      final transfer = $.words.historyTransfer.fill([formatMoney(100), firstName, secondName]);
      await historySays($, firstAddedLine, $.words.historyAccountCreated.fill([firstName]));

      await $.searchFor(secondName);
      await historySays($, transferLine, transfer);
      await $.gone($(AccountHistoryScreen.lineKey(firstAddedLine)));

      await $.chooseIn(AccountHistoryScreen.accountChoiceKey, AccountHistoryScreen.accountKey(first));
      await $.saysContaining(AccountHistoryScreen.accountChoiceKey.label, firstName);
      await historySays($, transferLine, transfer);
      await $.gone($(AccountHistoryScreen.lineKey(secondAddedLine)));
    });

    phoneCase('H10, redix-api #86 R13: the person chip\'s «أنا» keeps the signed-in person\'s own lines', ($) async {
      final manager = await Given.manager();
      final mover = await Given.member(manager, permissions: [Permission.moveMoney]);
      final firstName = 'حساب ${Given.unique()}';
      final secondName = 'كاش ${Given.unique()}';
      final first = await Given.account(manager, name: firstName);
      final second = await Given.account(manager, name: secondName);
      await Given.funded(manager, first, 1000);
      await Given.transferred(mover, first, second, 100);
      await Given.transferred(manager, first, second, 50);
      await onAccounts($, mover);
      await onHistory($);
      await $.chooseIn(AccountHistoryScreen.personChoiceKey, AccountHistoryScreen.personKey(mover.id));
      await historySays($, await historyLine(manager, (line) => line['kind'] == 'transfer' && line['amount'] == 100), $.words.historyTransfer.fill([formatMoney(100), firstName, secondName]));
      expect($(AccountHistoryScreen.lineKey(await historyLine(manager, (line) => line['kind'] == 'transfer' && line['amount'] == 50))), findsNothing);
    });
  });
}
