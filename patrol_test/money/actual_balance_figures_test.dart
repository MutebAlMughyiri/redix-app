import 'package:patrol/patrol.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/accounts/reconcile_screen.dart';
import 'package:redix/accounts/reconciliation_card.dart';
import 'package:redix/home/summary_card.dart';
import 'package:redix/home/home_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Accounts, which holds the actual balances since redix-app #89.
Future<void> onBalances(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.accountsKey(person.projectId));
  await $.reach($(ReconciliationCard.cardKey));
}

/// Revenue of 300 and an expense of 100, approved through [account]: a surplus of 200.00.
Future<void> aSurplusOf200(Person manager, String account) async {
  await Given.entriesApproved(manager, [await Given.revenue(manager, amount: 300, accountId: account), await Given.entry(manager, amount: 100, accountId: account)]);
}

/// Waits until the card shows this surplus, this actual total and this difference.
Future<void> cardShows(PatrolIntegrationTester $, {required String surplus, required String actual, required String difference}) async {
  await $.says(ReconciliationCard.surplusKey, surplus);
  await $.says(ReconciliationCard.actualTotalKey, actual);
  await $.says(ReconciliationCard.differenceKey, difference);
}

void main() {
  phoneClass('Actual balances against the surplus (BR-08)', () {
    phoneCase('BR-08: balances typed on the phone add up as they are typed, and saving shows the same difference on the card and the home', ($) async {
      final manager = await Given.manager();
      final first = await Given.account(manager);
      final second = await Given.account(manager);
      await aSurplusOf200(manager, first);
      await onBalances($, manager);
      await $.tapOn(AccountsScreen.updateKey);
      await $.says(ReconcileScreen.booksKey(first), '${$.words.reconciliationsBooks}: 200.00');
      await $.fill(ReconcileScreen.balanceKey(first), '120.50');
      await $.fill(ReconcileScreen.balanceKey(second), '30');
      await $.pumpAndSettle();
      await $.says(ReconcileScreen.totalKey, '${$.words.reconciliationsActualTotal}: 150.50');
      await $.says(ReconcileScreen.differenceKey, '${$.words.reconciliationsDifference}: (49.50)');
      await $.tapOn(ReconcileScreen.saveKey);
      await cardShows($, surplus: '200.00', actual: '150.50', difference: '(49.50)');
      await $.back();
      await $.says(SummaryCard.differenceKey, '(49.50)');
    });

    phoneCase('BR-08: more than the surplus shows without brackets', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await aSurplusOf200(manager, account);
      await Given.reconciled(manager, {account: 260});
      await onBalances($, manager);
      await cardShows($, surplus: '200.00', actual: '260.00', difference: '60.00');
    });

    phoneCase('BR-08: holding exactly the surplus leaves no difference', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await aSurplusOf200(manager, account);
      await Given.reconciled(manager, {account: 200});
      await onBalances($, manager);
      await cardShows($, surplus: '200.00', actual: '200.00', difference: '0.00');
    });

    phoneCase('BR-08: an entry approved after the check moves the surplus and the difference, and not what was counted', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await aSurplusOf200(manager, account);
      await Given.reconciled(manager, {account: 200});
      await Given.entriesApproved(manager, [await Given.entry(manager, amount: 50, accountId: account)]);
      await onBalances($, manager);
      await cardShows($, surplus: '150.00', actual: '200.00', difference: '50.00');
    });

    phoneCase('BR-08: a waiting entry after the check moves nothing', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await aSurplusOf200(manager, account);
      await Given.reconciled(manager, {account: 200});
      await Given.entry(manager, amount: 50, accountId: account);
      await onBalances($, manager);
      await cardShows($, surplus: '200.00', actual: '200.00', difference: '0.00');
    });

    phoneCase('BR-08: the latest check replaces the earlier one', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await aSurplusOf200(manager, account);
      await Given.reconciled(manager, {account: 150});
      await Given.reconciled(manager, {account: 190});
      await onBalances($, manager);
      await cardShows($, surplus: '200.00', actual: '190.00', difference: '(10.00)');
    });
  });
}
