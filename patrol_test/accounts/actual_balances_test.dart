import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/accounts/reconcile_screen.dart';
import 'package:redix/accounts/reconciliation_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/words/word_fill.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Accounts, which holds the actual balances since redix-app #89.
Future<void> onBalances(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.accountsKey(person.projectId));
  await $.reach($(ReconciliationCard.cardKey));
}

/// The line under the account [id].
String detailsOf(PatrolIntegrationTester $, String id) => $.tester.widget<Text>(find.byKey(AccountsScreen.detailsKey(id))).data!;

/// Approved money through a new account of [manager], whose id is answered.
Future<String> withMoney(Person manager) async {
  final account = await Given.account(manager);
  await Given.entriesApproved(manager, [await Given.revenue(manager, amount: 300, accountId: account), await Given.entry(manager, amount: 100, accountId: account)]);
  return account;
}

void main() {
  phoneClass('Actual balances, on Accounts (UC-040, redix-app #89)', () {
    phoneCase('AC-24.1: the card shows the surplus, the total, and the difference in brackets', ($) async {
      final manager = await Given.manager();
      final account = await withMoney(manager);
      await Given.reconciled(manager, {account: 150});
      await onBalances($, manager);
      await $.says(ReconciliationCard.surplusKey, '200.00');
      await $.says(ReconciliationCard.actualTotalKey, '150.00');
      await $.says(ReconciliationCard.differenceKey, '(50.00)');
    });

    phoneCase('redix-app #89: each account shows what it holds, and on its line what the latest check counted, or nothing when that check did not hold it', ($) async {
      final manager = await Given.manager();
      final checked = await Given.account(manager);
      await Given.funded(manager, checked, 100);
      await Given.reconciled(manager, {checked: 80});
      final later = await Given.account(manager);
      await onBalances($, manager);
      await $.says(AccountsScreen.balanceKey(checked), '100.00');
      await $.until(() => detailsOf($, checked).contains($.words.accountsCounted.fill(['80.00'])));
      expect(detailsOf($, later), isNot(contains($.words.accountsCounted.split('{0}').first)));
    });

    phoneCase('typing a balance shows the total and the difference, and saving sends each', ($) async {
      final manager = await Given.manager();
      final account = await withMoney(manager);
      await onBalances($, manager);
      await $.tapOn(AccountsScreen.updateKey);
      await $.fill(ReconcileScreen.balanceKey(account), '150');
      await $.pumpAndSettle();
      await $.saysContaining(ReconcileScreen.totalKey, '150.00');
      await $.saysContaining(ReconcileScreen.differenceKey, '(50.00)');
      await $.tapOn(ReconcileScreen.saveKey);
      await $.says(ReconciliationCard.actualTotalKey, '150.00');
    });

    phoneCase('everyone sees the card', ($) async {
      final manager = await Given.manager();
      await Given.account(manager);
      final member = await Given.member(manager);
      await onBalances($, member);
      expect($(ReconciliationCard.cardKey), findsOneWidget);
    });

    phoneCase('pulling down reads the card again', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await onBalances($, manager);
      await $.reach($(ReconciliationCard.neverKey));
      await Given.reconciled(manager, {account: 100});
      await $.pullDown();
      await $.says(ReconciliationCard.actualTotalKey, '100.00');
    });

    phoneCase('a balance left empty stops it before it is sent', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await onBalances($, manager);
      await $.tapOn(AccountsScreen.updateKey);
      await $.fill(ReconcileScreen.balanceKey(account), '');
      await $.tapOn(ReconcileScreen.saveKey);
      await $.reach($(ReconcileScreen.messageKey));
      expect($(ReconcileScreen.saveKey), findsOneWidget);
    });

    phoneCase('FR-24: without moveMoney Update and Transfer are gray', ($) async {
      final manager = await Given.manager();
      await Given.account(manager);
      await Given.account(manager);
      final member = await Given.member(manager);
      await onBalances($, member);
      await $.reach($(AccountsScreen.updateKey));
      expect($.isEnabled(AccountsScreen.updateKey), isFalse);
      expect($.isEnabled(AccountsScreen.transferKey), isFalse);
    });

    phoneCase('redix-app #89: the home has no Actual balances button any more', ($) async {
      await onBalances($, await Given.manager());
    });
  });
}
