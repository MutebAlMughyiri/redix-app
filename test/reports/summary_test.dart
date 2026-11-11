import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/format/number_format.dart';
import 'package:redix/home/summary_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/reports_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/app_color.dart';
import 'package:redix/reports/summary.dart';
import 'package:redix/reports/item_reports_screen.dart';
import 'package:redix/reports/report_files.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Map<String, Object> figures({int pendingCount = 0, double surplus = 1000, bool wasReconciled = false, double difference = 0, double completion = 0}) => {
    'revenue': 5000,
    'expenses': 4000,
    'surplus': surplus,
    'wasReconciled': wasReconciled,
    'reconciliationDifference': difference,
    'waiting': waiting(expensesCount: pendingCount, expensesAmount: pendingCount * 100.0),
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
        'id': 'category-capital',
        'name': 'رأس المال',
        'total': 4000,
        'items': [
          {'id': 'item-capital', 'name': 'رأس المال', 'total': 4000},
        ],
      },
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
    await openHome(tester, (api) => api.summaryAnswer = figures(wasReconciled: true, difference: -348.06));

    expect(tester.widget<Text>(find.byKey(SummaryCard.surplusKey)).data, '1,000.00');
    expect(tester.widget<Text>(find.byKey(SummaryCard.revenueKey)).data, '5,000.00');
    expect(tester.widget<Text>(find.byKey(SummaryCard.expensesKey)).data, '4,000.00');
    expect(tester.widget<Text>(find.byKey(SummaryCard.differenceKey)).data, '(348.06)');
  });

  testWidgets('before any reconciliation there is no difference to show', (tester) async {
    await openHome(tester, (api) => api.summaryAnswer = figures());

    expect(find.byKey(SummaryCard.differenceKey), findsNothing);
  });

  testWidgets('what waits opens the inbox, and coming back reads the figures again', (tester) async {
    final api = await openHome(tester, (api) => api.summaryAnswer = figures(pendingCount: 6));

    expect(find.text('en summary.pending'.replaceFirst('{0}', '6')), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(SummaryCard.pendingKey)));
    expect(find.byType(ApprovalsScreen), findsOneWidget);

    api.summaryAnswer = figures(surplus: 2500);
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect(tester.widget<Text>(find.byKey(SummaryCard.surplusKey)).data, '2,500.00');
  });

  testWidgets('coming back from approving reads the latest entries again', (tester) async {
    final api = await openHome(tester, (api) {
      api.summaryAnswer = figures(pendingCount: 1);
      api.addEntry();
    });
    await act(tester, api, () => tester.tap(find.byKey(SummaryCard.pendingKey)));

    api.entryRows.single['status'] = 'approved';
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect(frameOf(tester, 'entry-0'), AppColor.frame);
  });

  testWidgets('Muteb, 9 Nov 2026: the home has no Refresh button, and pulling it down reads the latest entries again', (tester) async {
    final api = await openHome(tester, (api) {
      api.summaryAnswer = figures();
      api.addEntry();
    });

    api.entryRows.single['status'] = 'approved';
    expect(find.byIcon(Icons.refresh), findsNothing);
    await act(tester, api, () => tester.drag(find.byType(ListView).first, const Offset(0, 1500)));

    expect(frameOf(tester, 'entry-0'), AppColor.frame);
  });

  testWidgets('Field sees the figures and no way to approve', (tester) async {
    await openHome(tester, (api) => api.summaryAnswer = figures(pendingCount: 6), permissions: field);

    expect(find.byKey(SummaryCard.surplusKey), findsOneWidget);
    expect(find.byKey(SummaryCard.pendingKey), findsNothing);
  });

  /// Opens الإيرادات والمصروفات from the home's buttons (Muteb, 9 Nov 2026).
  Future<void> openRevenueAndExpenses(WidgetTester tester, FakeApi api) => scrollAndTap(tester, api, HomeScreen.itemReportsKey('project-0'));

  SummarySide sideShown(WidgetTester tester) => tester.widget<SegmentedButton<SummarySide>>(find.byKey(ItemReportsScreen.sideKey)).selected.single;

  testWidgets('the categories show only once a tile is tapped: expenses opens the expense categories, revenue the revenue ones, each with its total', (tester) async {
    final api = await openHome(tester, (api) => api.summaryAnswer = figures());

    expect(find.byKey(SummaryCard.categoryKey('category-1')), findsNothing);
    expect(find.byKey(SummaryCard.categoryKey('category-9')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(SummaryCard.expensesKey)));
    expect(find.byKey(SummaryCard.categoryKey('category-1')), findsOneWidget);
    expect(find.byKey(SummaryCard.categoryKey('category-9')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(SummaryCard.revenueKey)));
    expect(find.byKey(SummaryCard.categoryKey('category-9')), findsOneWidget);
    expect(find.byKey(SummaryCard.categoryKey('category-1')), findsNothing);
    expect(text(tester, SummaryCard.categoryKey('category-capital').trailing), formatMoney(4000));
    expect(text(tester, SummaryCard.categoryKey('category-9').trailing), formatMoney(1000));

    await act(tester, api, () => tester.tap(find.byKey(SummaryCard.revenueKey)));
    expect(find.byKey(SummaryCard.categoryKey('category-9')), findsNothing);
  });

  testWidgets("Muteb, 9 Nov 2026: a category on the home opens nothing; its items and their reports are on الإيرادات والمصروفات", (tester) async {
    final api = await openHome(tester, (api) => api.summaryAnswer = figures());
    await act(tester, api, () => tester.tap(find.byKey(SummaryCard.expensesKey)));

    await act(tester, api, () => tester.tap(find.byKey(SummaryCard.categoryKey('category-1'))));

    expect(find.text('التشطيب'), findsOneWidget);
    expect(find.byKey(ItemReportsScreen.itemKey('item-1')), findsNothing);
    expect(find.byType(ItemReportScreen), findsNothing);
    expect(text(tester, HomeScreen.itemReportsKey('project-0').label), 'en reports.revenueAndExpenses');
  });

  testWidgets('Muteb, 9 Nov 2026: الإيرادات والمصروفات opens on the expenses, and its switch, like the language one, shows the revenue categories instead', (tester) async {
    final api = await openHome(tester, (api) => api.summaryAnswer = figures());
    await openRevenueAndExpenses(tester, api);

    expect(find.text('en reports.revenueAndExpenses'), findsOneWidget);
    expect(sideShown(tester), SummarySide.expenses);
    expect(text(tester, ItemReportsScreen.sideOptionKey(SummarySide.revenue)), 'en summary.revenue');
    expect(text(tester, ItemReportsScreen.sideOptionKey(SummarySide.expenses)), 'en summary.expenses');
    expect(find.byKey(ItemReportsScreen.categoryKey('category-1')), findsOneWidget);
    expect(find.byKey(ItemReportsScreen.categoryKey('category-9')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.sideOptionKey(SummarySide.revenue))));

    expect(sideShown(tester), SummarySide.revenue);
    expect(find.byKey(ItemReportsScreen.categoryKey('category-9')), findsOneWidget);
    expect(find.byKey(ItemReportsScreen.categoryKey('category-1')), findsNothing);
  });

  testWidgets("BR-06, redix-api #109: the revenue side is its categories in the structure's order, رأس المال first like any other, each with its total", (tester) async {
    final api = await openHome(tester, (api) => api.summaryAnswer = figures());
    await openRevenueAndExpenses(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.sideOptionKey(SummarySide.revenue))));

    expect(text(tester, ItemReportsScreen.categoryKey('category-capital').title), 'رأس المال');
    expect(text(tester, ItemReportsScreen.categoryKey('category-capital').trailing), formatMoney(4000));
    expect(text(tester, ItemReportsScreen.categoryKey('category-9').trailing), formatMoney(1000));
    expect(tester.getTopLeft(find.byKey(ItemReportsScreen.categoryKey('category-capital'))).dy < tester.getTopLeft(find.byKey(ItemReportsScreen.categoryKey('category-9'))).dy, isTrue);
  });

  testWidgets('redix-api #109: رأس المال opens to its item like any category, and the item to its report, whose tables are its partners', (tester) async {
    final api = await openHome(tester, (api) => api.summaryAnswer = figures());
    await openRevenueAndExpenses(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.sideOptionKey(SummarySide.revenue))));
    expect(find.byKey(ItemReportsScreen.itemKey('item-capital')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.categoryKey('category-capital'))));

    expect(text(tester, ItemReportsScreen.itemKey('item-capital').title), 'رأس المال');
    expect(text(tester, ItemReportsScreen.itemKey('item-capital').trailing), formatMoney(4000));
    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.itemKey('item-capital'))));
    expect(find.byType(ItemReportScreen), findsOneWidget);
  });

  testWidgets('the surplus comes first, then the completion, then the difference, and nothing without sales', (tester) async {
    await openHome(tester, (api) => api.summaryAnswer = figures(wasReconciled: true, difference: 12));

    final surplus = tester.getTopLeft(find.byKey(SummaryCard.surplusKey)).dy;
    final completion = tester.getTopLeft(find.byKey(SummaryCard.completionKey)).dy;
    final difference = tester.getTopLeft(find.byKey(SummaryCard.differenceKey)).dy;
    expect(surplus < completion && completion < difference, isTrue);
    expect(find.textContaining('en summary.surplusWithoutSales'), findsNothing);
  });

  testWidgets('a category opens to its items with their totals, and an item opens its report', (tester) async {
    final api = await openHome(tester, (api) => api.summaryAnswer = figures());
    await openRevenueAndExpenses(tester, api);

    expect(find.byKey(ItemReportsScreen.itemKey('item-1')), findsNothing);
    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.categoryKey('category-1'))));
    expect(text(tester, ItemReportsScreen.itemKey('item-1').trailing), '3,000.00');

    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.itemKey('item-1'))));

    expect(find.byKey(ItemReportScreen.totalKey), findsOneWidget);
  });

  testWidgets('UC-063: everyone sees the completion the API computed, and no cost line beside it', (tester) async {
    await openHome(tester, (api) => api.summaryAnswer = figures(completion: 40), permissions: field);

    expect(tester.widget<Text>(find.byKey(SummaryCard.completionKey)).data, 'en summary.completion: 40%');
    expect(find.textContaining('summary.cost'), findsNothing, reason: 'the cost line left the summary on 7 Nov');
  });

  testWidgets('AC-30.1: an item report shows its total, a table per subgroup, and each contract with what remains', (tester) async {
    final api = await openHome(tester, (api) {
      api
        ..summaryAnswer = figures()
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
    await showProjectSetting(tester, HomeScreen.itemReportsKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, api, HomeScreen.itemReportsKey('project-0'));
    await act(tester, api, () => tester.tap(find.text('التشطيب')));
    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.itemKey('item-1'))));

    expect(tester.widget<Text>(find.byKey(ItemReportScreen.totalKey)).data, '3,000.00');
    expect(tester.widget<Text>(find.byKey(ItemReportScreen.subgroupTotalKey('subgroup-1'))).data, '1,000.00');
    expect(find.textContaining('اللون: أبيض'), findsOneWidget);
    expect(find.byKey(ItemReportScreen.overrunKey('contract-1')), findsOneWidget);
    expect(find.textContaining('(500.00)'), findsOneWidget);
  });

  testWidgets('Muteb, 9 Nov 2026: Reports holds the periodic reports alone; the home opens the item reports and the VAT refund, and Contracts holds the contracts report\'s files', (tester) async {
    final api = await openHome(tester, (api) => api.summaryAnswer = figures());
    await showProjectSetting(tester, HomeScreen.vatKey('project-0'));
    expect(tester.widget<Text>(find.byKey(HomeScreen.vatKey('project-0').label)).data, 'en vat.title');
    await showProjectSetting(tester, HomeScreen.itemReportsKey('project-0'));
    expect(find.byKey(HomeScreen.itemReportsKey('project-0')), findsOneWidget);

    await showProjectSetting(tester, HomeScreen.reportsKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, api, HomeScreen.reportsKey('project-0'));
    expect(find.byKey(ReportsScreen.periodicCardKey), findsOneWidget);
    for (final gone in ['en reports.contracts', 'en reports.partners', 'en vat.title', 'en reports.revenueAndExpenses']) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    await showProjectSetting(tester, HomeScreen.contractsKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, api, HomeScreen.contractsKey('project-0'));
    expect(find.byType(ContractsScreen), findsOneWidget);
    expect(find.byKey(ReportFileButtons.buttonKey('contracts', ReportFileKind.pdf)), findsOneWidget);
    expect(find.byKey(ReportFileButtons.buttonKey('contracts', ReportFileKind.excel)), findsOneWidget);
  });
}
