// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:patrol/patrol.dart';
import 'package:redix/ui/search_scope.dart';
import 'package:redix/reports/summary.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/home/summary_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/item_reports_screen.dart';
import 'package:redix/ui/part_keys.dart';

import 'given.dart';
import 'steps.dart';

/// A new manager whose project holds one approved expense of 10.00, paid from its one account, which held nothing before and so stands at (10.00) (redix-app #89: no
/// account opens with money). A case then reads 10.00 rather than a zero, so the figure it waits for can only have come from the API.
Future<({Person manager, String account})> aProjectWithMoney() async {
  final manager = await Given.manager();
  final account = await Given.account(manager);
  await Given.entriesApproved(manager, [await Given.entry(manager, amount: 10, accountId: account)]);
  return (manager: manager, account: account);
}

/// The steps of reading a project's money, shared by every class that checks a figure.
extension MoneySteps on PatrolIntegrationTester {
  /// The home shows these three figures.
  Future<void> homeFigures({required String surplus, required String revenue, required String expenses}) async {
    await says(SummaryCard.surplusKey, surplus);
    await says(SummaryCard.revenueKey, revenue);
    await says(SummaryCard.expensesKey, expenses);
  }

  /// The home says [count] expenses wait for approval, coming to [amount], and no revenue does.
  Future<void> expensesWaiting(int count, String amount) => says(SummaryCard.pendingKey.subtitle, '${words.summaryPendingHint}\n${words.reportsPendingExpenses} ($count): $amount');

  /// The home says [count] revenue entries wait for approval, coming to [amount], and no expense does.
  Future<void> revenueWaiting(int count, String amount) => says(SummaryCard.pendingKey.subtitle, '${words.summaryPendingHint}\n${words.reportsPendingRevenue} ($count): $amount');

  /// The home says nothing waits.
  Future<void> nothingWaits() => gone(this(SummaryCard.pendingKey));

  /// From the home, [manager] approves [entry] in the inbox and comes back.
  Future<void> approveOnThePhone(Person manager, String entry) async {
    await tapOn(HomeScreen.approvalsKey(manager.projectId));
    await tapOn(ApprovalsScreen.approveKey(entry));
    await gone(this(ApprovalsScreen.cardKey(entry)));
    await back();
  }

  /// From the home of [person], opens Accounts and checks the account [id] stands at [balance].
  Future<void> accountStands(Person person, String id, String balance) async {
    await tapOn(HomeScreen.accountsKey(person.projectId));
    await reach(this(AccountsScreen.addKey));
    await says(AccountsScreen.balanceKey(id), balance);
  }

  /// On Contracts, the contract [id] shows what was [paid] and what [remaining], and what waits: [pending] with what remains [afterApproval], or no line at all when [pending] is empty.
  Future<void> contractStands(String id, {required String paid, required String remaining, String pending = '', String afterApproval = ''}) async {
    await says(ContractsScreen.paidKey(id), paid);
    await says(ContractsScreen.remainingKey(id), remaining);
    if (pending.isEmpty) {
      await gone(this(ContractsScreen.pendingKey(id)));
    } else {
      await says(ContractsScreen.pendingKey(id), '${words.contractsPending} $pending · $afterApproval ${words.contractsAfterApproval}');
    }
  }

  /// From the home of [person], opens المصروفات and the category named [categoryName].
  Future<void> openReportCategory(Person person, String categoryName) async {
    await tapOn(HomeScreen.itemReportsKey(person.projectId, SummarySide.expenses));
    await reach(this(SearchIcons.searchKey));
    final id = await idOf('itemReports.category.', () => Given.categoryNamed(person, categoryName));
    await tapOn(ItemReportsScreen.categoryKey(id));
    await pumpAndSettle();
  }
}
