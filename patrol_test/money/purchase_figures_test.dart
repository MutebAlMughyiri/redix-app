import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/dashboard_card.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/item_reports_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/money_steps.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new category with the name [name], holding an item that takes purchases and one table of its own.
Future<({String category, String item, String table, String itemName})> newExpense(Person manager, String name) async {
  final category = await Given.category(manager, name);
  final itemName = 'بند $name';
  final item = await Given.item(manager, category, itemName, type: 'purchases');
  return (category: category, item: item, table: await Given.subgroup(manager, item, 'جدول $name'), itemName: itemName);
}

/// The home of [manager] opens its expense categories.
Future<void> openExpenseCategories(PatrolIntegrationTester $, Person manager) async {
  await $.onTheHome(manager);
  await $.reach($(DashboardCard.expensesKey));
  await $(DashboardCard.expensesKey.body).tap();
}

void main() {
  phoneClass('A purchase in the figures (BR-10)', () {
    phoneCase('BR-10: a purchase entered on the phone waits and moves nothing, and approving it moves the expenses, the surplus and its account', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager, opening: 1000);
      final table = await Given.firstPurchaseTable(manager);
      await $.onAddEntry(manager);
      await $.pickTable(table.tableId);
      await $.chooseANewSupplier(manager);
      await $.fill(AddEntryScreen.amountKey, '250.50');
      await $.choosePayment(manager, account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      await $.expensesWaiting(1, '250.50');
      await $.homeFigures(surplus: '0.00', revenue: '0.00', expenses: '0.00');
      await $.approveOnThePhone(manager, (await Given.waitingIds(manager)).single);
      await $.homeFigures(surplus: '(250.50)', revenue: '0.00', expenses: '250.50');
      await $.nothingWaits();
      await $.accountStands(manager, account, '749.50');
    });

    phoneCase('BR-10: a waiting purchase leaves the expenses and its account alone', ($) async {
      final money = await aProjectWithMoney();
      await Given.entry(money.manager, amount: 100, accountId: money.account);
      await $.onTheHome(money.manager);
      await $.homeFigures(surplus: '(10.00)', revenue: '0.00', expenses: '10.00');
      await $.expensesWaiting(1, '100.00');
      await $.accountStands(money.manager, money.account, '990.00');
    });

    phoneCase('BR-10: a draft counts nowhere, not even as waiting', ($) async {
      final money = await aProjectWithMoney();
      await Given.entry(money.manager, sent: false, amount: 100, accountId: money.account);
      await $.onTheHome(money.manager);
      await $.homeFigures(surplus: '(10.00)', revenue: '0.00', expenses: '10.00');
      await $.nothingWaits();
      await $.accountStands(money.manager, money.account, '990.00');
    });

    phoneCase('BR-10: a rejected purchase leaves what waits, and counts nowhere', ($) async {
      final money = await aProjectWithMoney();
      await Given.entryRejected(money.manager, await Given.entry(money.manager, amount: 100, accountId: money.account));
      await $.onTheHome(money.manager);
      await $.homeFigures(surplus: '(10.00)', revenue: '0.00', expenses: '10.00');
      await $.nothingWaits();
      await $.accountStands(money.manager, money.account, '990.00');
    });

    phoneCase('AC-50.1: reversing a purchase puts the expenses, the surplus and the account back', ($) async {
      final money = await aProjectWithMoney();
      final entry = await Given.entry(money.manager, amount: 100, accountId: money.account);
      await Given.entriesApproved(money.manager, [entry]);
      await Given.entryReversed(money.manager, entry);
      await $.onTheHome(money.manager);
      await $.homeFigures(surplus: '(10.00)', revenue: '0.00', expenses: '10.00');
      await $.accountStands(money.manager, money.account, '990.00');
    });

    phoneCase('a purchase deleted while it waits leaves no trace in the figures', ($) async {
      final money = await aProjectWithMoney();
      await Given.entryDeleted(money.manager, await Given.entry(money.manager, amount: 100, accountId: money.account));
      await $.onTheHome(money.manager);
      await $.homeFigures(surplus: '(10.00)', revenue: '0.00', expenses: '10.00');
      await $.nothingWaits();
    });

    phoneCase('changing what a waiting purchase comes to shows the new amount waiting, and approval counts only that', ($) async {
      final money = await aProjectWithMoney();
      final entry = await Given.entry(money.manager, amount: 100, accountId: money.account);
      await $.onTheEntry(money.manager, entry);
      await $.tapOn(AddEntryScreen.changeKey);
      await $.reach($(AddEntryScreen.amountKey));
      await $.fill(AddEntryScreen.amountKey, '175.25');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      await $.expensesWaiting(1, '175.25');
      await $.approveOnThePhone(money.manager, entry);
      await $.homeFigures(surplus: '(185.25)', revenue: '0.00', expenses: '185.25');
      await $.accountStands(money.manager, money.account, '814.75');
    });

    phoneCase('several purchases add up to the halala', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager, opening: 1000);
      await Given.entriesApproved(manager, [for (final amount in [100.10, 200.20, 0.03]) await Given.entry(manager, amount: amount, accountId: account)]);
      await $.onTheHome(manager);
      await $.homeFigures(surplus: '(300.33)', revenue: '0.00', expenses: '300.33');
      await $.accountStands(manager, account, '699.67');
    });

    phoneCase('each expense category totals only its own purchases', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final first = await newExpense(manager, 'أول ${Given.unique()}');
      final second = await newExpense(manager, 'ثان ${Given.unique()}');
      await Given.entriesApproved(manager, [
        await Given.entry(manager, amount: 120, accountId: account, itemId: first.item, tableId: first.table),
        await Given.entry(manager, amount: 80.5, accountId: account, itemId: second.item, tableId: second.table),
      ]);
      await openExpenseCategories($, manager);
      await $.goTo($(DashboardCard.categoryKey(first.category)));
      await $.says(DashboardCard.categoryKey(first.category).trailing, '120.00');
      await $.goTo($(DashboardCard.categoryKey(second.category)));
      await $.says(DashboardCard.categoryKey(second.category).trailing, '80.50');
    });

    phoneCase('AC-30.1: an item\'s report totals its purchases, and each table its own', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final name = 'تفصيل ${Given.unique()}';
      final made = await newExpense(manager, name);
      final other = await Given.subgroup(manager, made.item, 'جدول ثان');
      await Given.entriesApproved(manager, [
        await Given.entry(manager, amount: 70, accountId: account, itemId: made.item, tableId: made.table),
        await Given.entry(manager, amount: 30.5, accountId: account, itemId: made.item, tableId: other),
      ]);
      await Given.entry(manager, amount: 999, accountId: account, itemId: made.item, tableId: made.table);
      await $.onTheHome(manager);
      await $.openReportCategory(manager, name);
      await $.says(ItemReportsScreen.itemKey(made.item).trailing, '100.50');
      await $.tapOn(ItemReportsScreen.itemKey(made.item));
      await $.says(ItemReportScreen.totalKey, '100.50');
      await $.says(ItemReportScreen.subgroupTotalKey(made.table), '70.00');
      await $.says(ItemReportScreen.subgroupTotalKey(other), '30.50');
    });
  });
}
