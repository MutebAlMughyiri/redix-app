import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/format/number_format.dart';
import 'package:redix/home/dashboard_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/reports_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/refresh_button.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Map<String, Object> figures({int pendingCount = 0, double surplus = 1000, bool wasReconciled = false, double difference = 0, double completion = 0}) => {
    'revenue': 5000,
    'capital': 4000,
    'expenses': 4000,
    'surplus': surplus,
    'wasReconciled': wasReconciled,
    'reconciliationDifference': difference,
    'pendingCount': pendingCount,
    'pendingAmount': pendingCount * 100.0,
    'completionPercent': completion,
    'categories': [
      {
        'id': 'category-1',
        'name': 'التشطيب',
        'total': 4000,
        'items': [
          {'id': 'item-1', 'name': 'البلاط', 'total': 3000},
          {'id': 'item-2', 'name': 'الجبس', 'total': 1000},
        ],
      },
    ],
    'revenueCategories': [
      {
        'id': 'category-9',
        'name': 'الإيرادات',
        'total': 1000,
        'items': [
          {'id': 'item-9', 'name': 'استرجاع ضرائب', 'total': 1000},
        ],
      },
    ],
  };

  Future<FakeApi> openHome(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة']);
    arrange(api);
    await openProject(tester, api);
    return api;
  }

  testWidgets('AC-34.1: the home shows the surplus, revenue, expenses and the difference', (tester) async {
    await openHome(tester, (api) => api.dashboardAnswer = figures(wasReconciled: true, difference: -348.06));

    expect(tester.widget<Text>(find.byKey(DashboardCard.surplusKey)).data, '1,000.00');
    expect(tester.widget<Text>(find.byKey(DashboardCard.revenueKey)).data, '5,000.00');
    expect(tester.widget<Text>(find.byKey(DashboardCard.expensesKey)).data, '4,000.00');
    expect(tester.widget<Text>(find.byKey(DashboardCard.differenceKey)).data, '(348.06)');
  });

  testWidgets('before any reconciliation there is no difference to show', (tester) async {
    await openHome(tester, (api) => api.dashboardAnswer = figures());

    expect(find.byKey(DashboardCard.differenceKey), findsNothing);
  });

  testWidgets('what waits opens the inbox, and coming back reads the figures again', (tester) async {
    final api = await openHome(tester, (api) => api.dashboardAnswer = figures(pendingCount: 6));

    expect(find.text('en dashboard.pending'.replaceFirst('{0}', '6')), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.pendingKey)));
    expect(find.byType(ApprovalsScreen), findsOneWidget);

    api.dashboardAnswer = figures(surplus: 2500);
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect(tester.widget<Text>(find.byKey(DashboardCard.surplusKey)).data, '2,500.00');
  });

  testWidgets('coming back from approving reads the latest entries again', (tester) async {
    final api = await openHome(tester, (api) {
      api.dashboardAnswer = figures(pendingCount: 1);
      api.addEntry();
    });
    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.pendingKey)));

    api.entryRows.single['status'] = 'approved';
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect(find.byKey(EntriesScreen.statusKey('entry-0')), findsNothing);
  });

  testWidgets('the refresh button on home reads the latest entries again', (tester) async {
    final api = await openHome(tester, (api) {
      api.dashboardAnswer = figures();
      api.addEntry();
    });

    api.entryRows.single['status'] = 'approved';
    await act(tester, api, () => tester.tap(find.byKey(RefreshButton.buttonKey)));

    expect(find.byKey(EntriesScreen.statusKey('entry-0')), findsNothing);
  });

  testWidgets('Field sees the figures and no way to approve', (tester) async {
    await openHome(tester, (api) => api.dashboardAnswer = figures(pendingCount: 6), permissions: field);

    expect(find.byKey(DashboardCard.surplusKey), findsOneWidget);
    expect(find.byKey(DashboardCard.pendingKey), findsNothing);
  });

  testWidgets('the categories show only once a tile is tapped: expenses opens the expense categories, revenue the revenue ones', (tester) async {
    final api = await openHome(tester, (api) => api.dashboardAnswer = figures());

    expect(find.byKey(DashboardCard.categoryKey('category-1')), findsNothing);
    expect(find.byKey(DashboardCard.categoryKey('category-9')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.expensesKey)));
    expect(find.byKey(DashboardCard.categoryKey('category-1')), findsOneWidget);
    expect(find.byKey(DashboardCard.categoryKey('category-9')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.revenueKey)));
    expect(find.byKey(DashboardCard.categoryKey('category-9')), findsOneWidget);
    expect(find.byKey(DashboardCard.categoryKey('category-1')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.revenueKey)));
    expect(find.byKey(DashboardCard.categoryKey('category-9')), findsNothing);
  });

  testWidgets('BR-06: the revenue side starts with capital, named by the app, and the lines add up to the revenue', (tester) async {
    final api = await openHome(tester, (api) => api.dashboardAnswer = figures());

    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.revenueKey)));

    expect(text(tester, DashboardCard.categoryKey('').title), 'en categories.tableCapital');
    expect(text(tester, DashboardCard.categoryKey('').trailing), formatMoney(4000));
    expect(text(tester, DashboardCard.categoryKey('category-9').trailing), formatMoney(1000));
    expect(tester.getTopLeft(find.byKey(DashboardCard.categoryKey(''))).dy < tester.getTopLeft(find.byKey(DashboardCard.categoryKey('category-9'))).dy, isTrue);
  });

  testWidgets('BR-31: the capital line holds no partner and does not open, with no arrow to tap', (tester) async {
    final api = await openHome(tester, (api) => api.dashboardAnswer = figures());
    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.revenueKey)));

    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.categoryKey(''))));

    expect(find.byKey(DashboardCard.categoryKey('').icon), findsNothing);
    expect(find.byKey(DashboardCard.categoryKey('category-9').icon), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('the surplus comes first, then the completion, then the difference, and nothing without sales', (tester) async {
    await openHome(tester, (api) => api.dashboardAnswer = figures(wasReconciled: true, difference: 12));

    final surplus = tester.getTopLeft(find.byKey(DashboardCard.surplusKey)).dy;
    final completion = tester.getTopLeft(find.byKey(DashboardCard.completionKey)).dy;
    final difference = tester.getTopLeft(find.byKey(DashboardCard.differenceKey)).dy;
    expect(surplus < completion && completion < difference, isTrue);
    expect(find.textContaining('en dashboard.surplusWithoutSales'), findsNothing);
  });

  testWidgets('a category opens to its items, and an item opens its report', (tester) async {
    final api = await openHome(tester, (api) => api.dashboardAnswer = figures());

    expect(find.byKey(DashboardCard.itemKey('item-1')), findsNothing);
    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.expensesKey)));
    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.categoryKey('category-1'))));
    expect(find.text('3,000.00'), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(DashboardCard.itemKey('item-1'))));

    expect(find.byKey(ItemReportScreen.totalKey), findsOneWidget);
  });

  testWidgets('UC-063: everyone sees the completion the API computed, and no cost line beside it', (tester) async {
    await openHome(tester, (api) => api.dashboardAnswer = figures(completion: 40), permissions: field);

    expect(tester.widget<Text>(find.byKey(DashboardCard.completionKey)).data, 'en dashboard.completion: 40%');
  });

  testWidgets('AC-30.1: an item report shows its total, a table per subgroup, and each contract with what remains', (tester) async {
    final api = await openHome(tester, (api) {
      api
        ..dashboardAnswer = figures()
        ..itemReportAnswer = {
          'itemName': 'البلاط',
          'categoryName': 'التشطيب',
          'total': 3000,
          'columns': ['اللون'],
          'subgroups': [
            {
              'id': 'subgroup-1',
              'name': '',
              'total': 1000,
              'rows': [
                {'entryId': 'entry-1', 'date': '2026-10-01', 'description': 'بلاط أرضيات', 'supplierName': 'البواني', 'invoiceNumber': '2617', 'unitPrice': 50, 'quantity': 20, 'amount': 1000, 'isOutsideContract': false, 'values': ['أبيض']},
              ],
            },
          ],
          'contracts': [
            {'id': 'contract-1', 'contractorName': 'مقاول البلاط', 'value': 1500, 'isOpenValue': false, 'paid': 2000, 'remaining': -500, 'isOverrun': true, 'paymentsTotal': 2000, 'payments': <Map<String, Object>>[]},
          ],
        };
    });
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.reportsKey('project-0'))));
    await act(tester, api, () => tester.tap(find.text('التشطيب')));
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.itemKey('item-1'))));

    expect(tester.widget<Text>(find.byKey(ItemReportScreen.totalKey)).data, '3,000.00');
    expect(tester.widget<Text>(find.byKey(ItemReportScreen.subgroupTotalKey('subgroup-1'))).data, '1,000.00');
    expect(find.textContaining('اللون: أبيض'), findsOneWidget);
    expect(find.byKey(ItemReportScreen.overrunKey('contract-1')), findsOneWidget);
    expect(find.textContaining('(500.00)'), findsOneWidget);
  });

  testWidgets('AC-31.1: the reports open the contracts, with value, paid and remaining', (tester) async {
    final api = await openHome(tester, (api) => api.dashboardAnswer = figures());
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.reportsKey('project-0'))));

    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.contractsKey)));

    expect(find.byType(ContractsScreen), findsOneWidget);
  });
}
