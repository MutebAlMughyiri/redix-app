import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/periodic_report_screen.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/reports/reports_screen.dart';
import 'package:redix/reports/vat_statement_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';

import '../app_harness.dart';

void main() {
  Map<String, Object> report() => {
    'number': 1,
    'issuedAt': '2026-11-05T20:00:00Z',
    'accounts': [
      {'name': 'البنك', 'type': 'bank', 'balance': 900},
    ],
    'accountsTotal': 900,
    'previousExpenses': 100,
    'expenses': 140,
    'expensesDifference': 40,
    'capital': 1000,
    'vatRefunds': 0,
    'sales': 0,
    'revenue': 1000,
    'revenueWithoutSales': 1000,
    'categories': [
      {'id': 'category-1', 'name': 'التشطيب', 'total': 140, 'items': <Map<String, Object>>[]},
    ],
    'surplus': 860,
    'surplusWithoutSales': 860,
    'liquidation': 0,
    'reconciliationDifference': 40,
    'pendingCount': 0,
    'pendingAmount': 0,
    'capitalTotal': 1000,
    'partners': [
      {'name': 'متعب', 'balance': 1000, 'sharePercent': 100},
    ],
  };

  Future<({FakeApi api, FakeCapture capture})> openReports(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة']);
    arrange(api);
    final capture = FakeCapture();
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.reportsKey('project-0'))));
    return (api: api, capture: capture);
  }

  testWidgets('UC-053: issuing asks first, saying its number, and the report then shows', (tester) async {
    final (:api, capture: _) = await openReports(tester, (api) {});

    expect(find.byKey(ReportsScreen.noneIssuedKey), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.issueKey)));
    expect(find.text('en reports.issueQuestion'), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(find.byKey(ReportsScreen.periodicKey(1)), findsOneWidget);
  });

  testWidgets('UC-053: a report opens as it was issued, with the difference from the last', (tester) async {
    final (:api, capture: _) = await openReports(tester, (api) {
      api
        ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
        ..periodicAnswer = report();
    });

    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.periodicKey(1))));

    expect(tester.widget<Text>(find.byKey(PeriodicReportScreen.surplusKey)).data, '860.00');
    expect(tester.widget<Text>(find.byKey(PeriodicReportScreen.differenceKey)).data, '40.00');
  });

  testWidgets('AC-48.1: print opens the phone\'s printer with the PDF, and share hands the workbook on', (tester) async {
    final (:api, :capture) = await openReports(tester, (api) {
      api
        ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
        ..periodicAnswer = report();
    });
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.periodicKey(1))));

    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey('report-1', ReportFileKind.print))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey('report-1', ReportFileKind.excel))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey('report-1', ReportFileKind.excel, FileHanding.share))));

    expect(capture.printed, ['report-1.pdf']);
    expect(capture.sharedOut, [('report-1.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')]);
    expect(api.sentFileReads, ['/projects/project-0/periodic-reports/1/pdf', '/projects/project-0/periodic-reports/1/xlsx']);
  });

  testWidgets('FR-48: Excel asks once, and saving keeps the workbook on the phone, to copy to a computer, and says so', (tester) async {
    final (:api, :capture) = await openReports(tester, (api) {
      api
        ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
        ..periodicAnswer = report();
    });
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.periodicKey(1))));

    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey('report-1', ReportFileKind.excel))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey('report-1', ReportFileKind.excel, FileHanding.save))));

    expect(capture.savedOut, [('report-1.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')]);
    expect(api.sentFileReads, ['/projects/project-0/periodic-reports/1/xlsx']);
    expect(find.text('en reports.downloaded'), findsOneWidget);
  });

  testWidgets('BR-31: someone who sees only their own capital reads the report and gets no files', (tester) async {
    final (:api, capture: _) = await openReports(tester, (api) {
      api
        ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
        ..periodicAnswer = report();
    }, permissions: const ['readProject']);

    expect(find.byKey(ReportsScreen.issueKey), findsNothing);
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.periodicKey(1))));

    expect(find.byKey(PeriodicReportScreen.surplusKey), findsOneWidget);
    expect(find.byKey(ReportFileButtons.buttonKey('report-1', ReportFileKind.pdf)), findsNothing);
  });

  testWidgets('UC-057, UC-058: the VAT statement hands on its workbook, its PDF and its invoice images for the period shown', (tester) async {
    final (:api, :capture) = await openReports(tester, (api) {});
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.vatKey)));
    final start = DateTime(DateTime.now().year, (DateTime.now().month - 1) ~/ 3 * 3 + 1);
    final from = start.toIso8601String().substring(0, 10);
    final to = DateTime(start.year, start.month + 3, 0).toIso8601String().substring(0, 10);

    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey('vat-$from-$to', ReportFileKind.zip))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey('vat-$from-$to', ReportFileKind.zip, FileHanding.share))));

    expect(capture.sharedOut.single, ('vat-$from-$to.zip', 'application/zip'));
    expect(api.sentFileReads.single, '/projects/project-0/vat-statement/zip?from=$from&to=$to');
    expect(find.byType(VatStatementScreen), findsOneWidget);
  });

  testWidgets('AC-33.1: an item report hands on its PDF', (tester) async {
    final (:api, :capture) = await openReports(tester, (api) {
      api.dashboardAnswer = {
        ...api.dashboardAnswer,
        'categories': [
          {
            'id': 'category-1',
            'name': 'التشطيب',
            'total': 0,
            'items': [
              {'id': 'item-1', 'name': 'البلاط', 'total': 0},
            ],
          },
        ],
      };
    });
    await act(tester, api, () => tester.tap(find.text('التشطيب')));
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.itemKey('item-1'))));

    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey('البلاط', ReportFileKind.pdf))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey('البلاط', ReportFileKind.pdf, FileHanding.share))));

    expect(find.byType(ItemReportScreen), findsOneWidget);
    expect(capture.sharedOut.single, ('البلاط.pdf', 'application/pdf'));
  });

  testWidgets('UC-060: each unit shows what it cost, its own and its part of the shared, and the shared unit what was never split', (tester) async {
    await openReports(tester, (api) {
      api.unitTotalsAnswer = [
        {'unitId': 'project-0-unit-0', 'name': 'الفلة', 'isShared': false, 'direct': 200, 'fromShared': 700, 'total': 900},
        {'unitId': 'project-0-unit-shared', 'name': 'مشترك', 'isShared': true, 'direct': 50, 'fromShared': 0, 'total': 50},
      ];
    });

    final own = find.byKey(ReportsScreen.unitKey('project-0-unit-0'));
    final shared = find.byKey(ReportsScreen.unitKey('project-0-unit-shared'));
    await tester.ensureVisible(shared);

    expect(find.descendant(of: own, matching: find.text('en reports.unitDirect: 200.00 · en reports.unitFromShared: 700.00')), findsOneWidget);
    expect(find.descendant(of: own, matching: find.text('900.00')), findsOneWidget);
    expect(find.descendant(of: shared, matching: find.text('en reports.unsplit')), findsOneWidget);
    expect(find.descendant(of: shared, matching: find.text('50.00')), findsOneWidget);
  });

  testWidgets('a file that cannot be read says so', (tester) async {
    final (:api, capture: _) = await openReports(tester, (api) {});
    api.online = false;

    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey('contracts', ReportFileKind.pdf))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey('contracts', ReportFileKind.pdf, FileHanding.share))));

    expect(find.text('en reports.fileFailed'), findsOneWidget);
  });
}
