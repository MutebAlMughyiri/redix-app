import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/home/summary_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/item_reports_screen.dart';
import 'package:redix/reports/periodic_report_screen.dart';
import 'package:redix/reports/reports_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/money_steps.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Approved revenue of [revenue] and an approved expense of [expense], through one account. The expense is left out when it is 0, the revenue likewise.
Future<void> approved(Person manager, {num revenue = 0, num expense = 0}) async {
  final account = await Given.account(manager);
  await Given.entriesApproved(manager, [
    if (revenue != 0) await Given.revenue(manager, amount: revenue, accountId: account),
    if (expense != 0) await Given.entry(manager, amount: expense, accountId: account),
  ]);
}

/// Signs [person] in, opens Reports and the periodic report [number].
Future<void> onReport(PatrolIntegrationTester $, Person person, int number) async {
  await $.fromTheHome(person, HomeScreen.reportsKey(person.projectId));
  await $.reach($(ReportsScreen.periodicHeadingKey));
  await $.tapOn(ReportsScreen.periodicKey(number));
  await $.reach($(PeriodicReportScreen.surplusKey));
}

void main() {
  phoneClass('The figures in the reports (UC-049, UC-053 and UC-063)', () {
    phoneCase('the home, the category and the item report agree', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      await approved(manager, expense: 120.75);
      await $.onTheHome(manager);
      await $.homeFigures(surplus: '(120.75)', revenue: '0.00', expenses: '120.75');
      await $.reach($(SummaryCard.expensesKey));
      await $(SummaryCard.expensesKey.body).tap();
      final id = await $.idShowing('summary.category.', table.category);
      await $.says(SummaryCard.categoryKey(id).trailing, '120.75');
      await $.openReportCategory(manager, table.category);
      await $.says(ItemReportsScreen.itemKey(table.itemId).trailing, '120.75');
      await $.tapOn(ItemReportsScreen.itemKey(table.itemId));
      await $.says(ItemReportScreen.totalKey, '120.75');
    });

    phoneCase('UC-063: the completion is the expenses over the revenue, to two decimals', ($) async {
      final manager = await Given.manager();
      await approved(manager, revenue: 300, expense: 100);
      await $.onTheHome(manager);
      await $.says(SummaryCard.completionKey, '${$.words.summaryCompletion}: 33.33%');
    });

    phoneCase('UC-063: a whole percent shows with no decimals', ($) async {
      final manager = await Given.manager();
      await approved(manager, revenue: 200, expense: 100);
      await $.onTheHome(manager);
      await $.says(SummaryCard.completionKey, '${$.words.summaryCompletion}: 50%');
    });

    phoneCase('UC-063: expenses past the revenue take the completion over 100, and the bar stops full', ($) async {
      final manager = await Given.manager();
      await approved(manager, revenue: 300, expense: 500);
      await $.onTheHome(manager);
      await $.says(SummaryCard.completionKey, '${$.words.summaryCompletion}: 166.67%');
      expect($.tester.widget<LinearProgressIndicator>(find.byKey(SummaryCard.completionBarKey)).value, 1);
    });

    phoneCase('UC-063: with no revenue the completion stays at 0', ($) async {
      final manager = await Given.manager();
      await approved(manager, expense: 100);
      await $.onTheHome(manager);
      await $.homeFigures(surplus: '(100.00)', revenue: '0.00', expenses: '100.00');
      await $.says(SummaryCard.completionKey, '${$.words.summaryCompletion}: 0%');
    });

    phoneCase('BR-26: an issued report keeps its figures when a later entry moves the home', ($) async {
      final manager = await Given.manager();
      await approved(manager, revenue: 300, expense: 100);
      await Given.reportIssued(manager);
      await approved(manager, expense: 50);
      await onReport($, manager, 1);
      await $.says(PeriodicReportScreen.surplusKey, '200.00');
      await $.back();
      await $.back();
      await $.says(SummaryCard.surplusKey, '150.00');
    });

    phoneCase('the next report shows the expenses since the last one', ($) async {
      final manager = await Given.manager();
      await approved(manager, expense: 100);
      await Given.reportIssued(manager);
      await approved(manager, expense: 50);
      await Given.reportIssued(manager);
      await onReport($, manager, 2);
      await $.says(PeriodicReportScreen.lineKey('expenses', 'previous'), '100.00');
      await $.says(PeriodicReportScreen.lineKey('expenses', 'current'), '150.00');
      await $.says(PeriodicReportScreen.differenceKey, '50.00');
    });

    phoneCase('a report shows what the actual balances differ from the surplus', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await Given.entriesApproved(manager, [await Given.revenue(manager, amount: 300, accountId: account)]);
      await Given.reconciled(manager, {account: 250});
      await Given.reportIssued(manager);
      await onReport($, manager, 1);
      await $.says(PeriodicReportScreen.surplusKey, '300.00');
      await $.goTo($(PeriodicReportScreen.lineKey('surplus', 'reconciliation')));
      await $.says(PeriodicReportScreen.lineKey('surplus', 'reconciliation'), '(50.00)');
    });
  });
}
