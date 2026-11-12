import 'package:flutter_test/flutter_test.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/home/summary_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/item_reports_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Approved money in the project of [manager] through one new account, whose id is answered.
Future<String> approvedMoney(Person manager, {num expense = 100, num revenue = 300}) async {
  final account = await Given.account(manager);
  await Given.entriesApproved(manager, [await Given.entry(manager, amount: expense, accountId: account), await Given.revenue(manager, amount: revenue, accountId: account)]);
  return account;
}

void main() {
  phoneClass('The conclusion at the top (UC-049)', () {
    phoneCase('the waiting count rises with each entry sent', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      await $.onTheHome(manager);
      await $.says(SummaryCard.pendingKey.title, $.words.summaryPending.replaceFirst('{0}', '1'));
      await Given.entry(manager);
      await $.pullDown();
      await $.says(SummaryCard.pendingKey.title, $.words.summaryPending.replaceFirst('{0}', '2'));
    });

    phoneCase('the waiting count leaves once nothing waits', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await $.onTheHome(manager);
      await $.reach($(SummaryCard.pendingKey));
      await Given.entriesApproved(manager, [entry]);
      await $.pullDown();
      await $.gone($(SummaryCard.pendingKey));
    });

    phoneCase('AC-34.1: it shows the surplus, revenue, expenses and difference of the approved entries, to the halala', ($) async {
      final manager = await Given.manager();
      final account = await approvedMoney(manager, expense: 100.25, revenue: 300.75);
      await Given.reconciled(manager, {account: 150.5});
      await $.onTheHome(manager);
      await $.says(SummaryCard.surplusKey, '200.50');
      await $.says(SummaryCard.revenueKey, '300.75');
      await $.says(SummaryCard.expensesKey, '100.25');
      await $.says(SummaryCard.differenceKey, '(50.00)');
    });

    phoneCase('AC-34.1: an approval shows as soon as Finance returns to the home', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await $.onTheHome(manager);
      await $.says(SummaryCard.expensesKey, '0.00');
      await $.tapOn(HomeScreen.approvalsKey(manager.projectId));
      await $.tapOn(ApprovalsScreen.approveKey(entry));
      await $.gone($(ApprovalsScreen.cardKey(entry)));
      await $.back();
      await $.says(SummaryCard.expensesKey, '100.00');
    });

    phoneCase('AC-50.1: a removed entry takes its amount back out', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      await Given.entryRemoved(manager, entry);
      await $.onTheHome(manager);
      await $.says(SummaryCard.expensesKey, '0.00');
    });

    phoneCase('waiting expenses and waiting revenue with capital show apart, each only when something waits', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      await $.onTheHome(manager);
      await $.reach($(SummaryCard.pendingKey));
      final onlyExpenses = [$.words.summaryPendingHint, '${$.words.reportsPendingExpenses} (1): 100.00'].join('\n');
      await $.says(SummaryCard.pendingKey.subtitle, onlyExpenses);
      await Given.revenue(manager);
      await $.pullDown();
      await $.says(SummaryCard.pendingKey.subtitle, '$onlyExpenses\n${$.words.reportsPendingRevenue} (1): 300.00');
    });

    phoneCase('Expenses opens the expense categories with their totals', ($) async {
      final manager = await Given.manager();
      await approvedMoney(manager);
      final table = await Given.firstPurchaseTable(manager);
      await $.onTheHome(manager);
      await $.reach($(SummaryCard.expensesKey));
      await $(SummaryCard.expensesKey.body).tap();
      final id = await $.idShowing('summary.category.', table.category);
      await $.says(SummaryCard.categoryKey(id).trailing, '100.00');
    });

    phoneCase('BR-06: revenue opens its categories in the structure\'s order, رأس المال first, adding up to the revenue', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'متعب');
      await Given.entriesApproved(manager, [await Given.partnerMoney(manager, partner, amount: 500), await Given.revenue(manager, amount: 300)]);
      await $.onTheHome(manager);
      await $.says(SummaryCard.revenueKey, '800.00');
      await $(SummaryCard.revenueKey.body).tap();
      final capital = await $.idShowing('summary.category.', 'رأس المال');
      final refund = await $.idShowing('summary.category.', 'استرجاع ضرائب');
      await $.says(SummaryCard.categoryKey(capital).trailing, '500.00');
      await $.says(SummaryCard.categoryKey(refund).trailing, '300.00');
      expect($.topOf(SummaryCard.categoryKey(capital)), lessThan($.topOf(SummaryCard.categoryKey(refund))));
    });

    phoneCase('UC-063: the completion the API computed shows, with no cost line beside it', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $.says(SummaryCard.completionKey, '${$.words.summaryCompletion}: 0%');
    });

    phoneCase('the surplus comes first, then the completion, then the difference', ($) async {
      final manager = await Given.manager();
      final account = await approvedMoney(manager);
      await Given.reconciled(manager, {account: 200});
      await $.onTheHome(manager);
      await $.reach($(SummaryCard.differenceKey));
      expect($.topOf(SummaryCard.surplusKey), lessThan($.topOf(SummaryCard.completionKey)));
      expect($.topOf(SummaryCard.completionKey), lessThan($.topOf(SummaryCard.differenceKey)));
    });

    phoneCase('NFR-04: a deficit shows in brackets', ($) async {
      final manager = await Given.manager();
      await approvedMoney(manager, expense: 500, revenue: 300);
      await $.onTheHome(manager);
      await $.says(SummaryCard.surplusKey, '(200.00)');
    });

    phoneCase('what waits opens the inbox, and coming back reads the figures again', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await $.onTheHome(manager);
      await $.tapOn(SummaryCard.pendingKey);
      await $.reach($(ApprovalsScreen.cardKey(entry)));
      await Given.entriesApproved(manager, [entry]);
      await $.back();
      await $.gone($(SummaryCard.pendingKey));
      await $.says(SummaryCard.expensesKey, '100.00');
    });

    phoneCase('pulling the home down reads the figures again', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $.says(SummaryCard.expensesKey, '0.00');
      await Given.entriesApproved(manager, [await Given.entry(manager)]);
      await $.pullDown();
      await $.says(SummaryCard.expensesKey, '100.00');
    });

    phoneCase('AC-34.1: waiting, draft and rejected entries are not in the totals', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      await Given.entry(manager, sent: false);
      await Given.entryRejected(manager, await Given.entry(manager));
      await $.onTheHome(manager);
      await $.says(SummaryCard.expensesKey, '0.00');
      await $.says(SummaryCard.surplusKey, '0.00');
    });

    phoneCase('AC-34.1: before any reconciliation there is no difference to show', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $.reach($(SummaryCard.surplusKey));
      expect($(SummaryCard.differenceKey), findsNothing);
    });

    phoneCase('a category on the home opens nothing; items and reports are under الإيرادات والمصروفات', ($) async {
      final manager = await Given.manager();
      await approvedMoney(manager);
      final table = await Given.firstPurchaseTable(manager);
      await $.onTheHome(manager);
      await $.reach($(SummaryCard.expensesKey));
      await $(SummaryCard.expensesKey.body).tap();
      final id = await $.idShowing('summary.category.', table.category);
      await $(SummaryCard.categoryKey(id)).tap();
      await $.pumpAndSettle();
      expect(find.byType(ItemReportsScreen), findsNothing);
      expect($(HomeScreen.titleKey), findsOneWidget);
    });

    phoneCase('field sees the figures and no way to approve', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      final member = await Given.member(manager);
      await $.onTheHome(member);
      await $.reach($(SummaryCard.surplusKey));
      expect($(SummaryCard.pendingKey), findsNothing);
    });

    phoneCase('without a network and nothing kept the conclusion says so, and Try again reads it', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await Pc.cutNetwork();
      await $.openProject(manager.projectId);
      await $.says(ApiListBody.messageKey, $.words.summaryLoadFailed);
      await Pc.restoreNetwork();
      await $.tapOn(ApiListBody.retryKey);
      await $.reach($(SummaryCard.surplusKey));
    });
  });
}
