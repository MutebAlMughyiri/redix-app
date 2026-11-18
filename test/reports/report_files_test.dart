// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/summary.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/periodic_report_screen.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/reports/reports_screen.dart';
import 'package:redix/reports/quarter_picker.dart';
import 'package:redix/reports/vat_statement_screen.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/ui/bottom_button.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/screen_title.dart';
import 'package:redix/reports/item_reports_screen.dart';

import '../app_harness.dart';

void main() {
  Future<({FakeApi api, FakeCapture capture})> openReports(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة']);
    arrange(api);
    final capture = FakeCapture();
    await openProject(tester, api, capture: capture);
    await scrollAndTap(tester, api, HomeScreen.reportsKey('project-0'));
    return (api: api, capture: capture);
  }

  testWidgets('UC-053: issuing asks first, saying its number, and the report then shows', (tester) async {
    final (:api, capture: _) = await openReports(tester, (api) {});

    expect(find.byKey(ReportsScreen.noneIssuedKey), findsOneWidget);
    expect(find.descendant(of: find.byKey(BottomButton.barKey), matching: find.byKey(ReportsScreen.issueKey)), findsOneWidget, reason: 'Muteb, 9 Nov 2026: issuing is the bottom button of the screen');
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.issueKey)));
    expect(tester.widget<Text>(find.byKey(ConfirmDialog.titleKey)).data, 'en reports.issueQuestion');

    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(find.byKey(ReportsScreen.periodicKey(1)), findsOneWidget);
  });

  testWidgets('UC-053: a report opens as it was issued, with the difference from the last', (tester) async {
    final (:api, capture: _) = await openReports(tester, (api) {
      api
        ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
        ..periodicAnswer = issuedReport();
    });

    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.periodicKey(1))));

    expect(tester.widget<Text>(find.byKey(PeriodicReportScreen.surplusKey)).data, '860.00');
    expect(tester.widget<Text>(find.byKey(PeriodicReportScreen.differenceKey)).data, '40.00');
  });

  testWidgets('AC-48.1: print opens the phone\'s printer with the PDF, and share hands the workbook on', (tester) async {
    final (:api, :capture) = await openReports(tester, (api) {
      api
        ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
        ..periodicAnswer = issuedReport();
    });
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.periodicKey(1))));

    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey('report-1', ReportFileKind.print))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey('report-1', ReportFileKind.excel))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey('report-1', ReportFileKind.excel, FileHandling.share))));

    expect(capture.printed, ['report-1.pdf']);
    expect(capture.sharedOut, [('report-1.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')]);
    expect(api.sentFileReads, ['/projects/project-0/periodic-reports/1/pdf', '/projects/project-0/periodic-reports/1/xlsx']);
  });

  testWidgets('FR-48: Excel asks once, and saving keeps the workbook on the phone, to copy to a computer, and says so', (tester) async {
    final (:api, :capture) = await openReports(tester, (api) {
      api
        ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
        ..periodicAnswer = issuedReport();
    });
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.periodicKey(1))));

    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey('report-1', ReportFileKind.excel))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey('report-1', ReportFileKind.excel, FileHandling.save))));

    expect(capture.savedOut, [('report-1.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')]);
    expect(api.sentFileReads, ['/projects/project-0/periodic-reports/1/xlsx']);
    expect(tester.widget<Text>(find.byKey(messageKeyOf('reports.downloaded').label)).data, 'en reports.downloaded');
  });

  testWidgets('redix-api #131: someone holding «يرى التقارير» alone reads the report, and its Issue, PDF, Excel and Print show gray, never hidden', (tester) async {
    final (:api, capture: _) = await openReports(tester, (api) {
      api
        ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
        ..periodicAnswer = issuedReport();
    }, permissions: const ['readProject', 'seeReports', 'moveMoney', 'seeAllCapital']);

    expect(isEnabled(tester, ReportsScreen.issueKey), isFalse);
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.periodicKey(1))));

    expect(find.byKey(PeriodicReportScreen.surplusKey), findsOneWidget);
    for (final kind in const [ReportFileKind.pdf, ReportFileKind.excel, ReportFileKind.print]) {
      expect(isEnabled(tester, ReportFileButtons.buttonKey('report-1', kind)), isFalse, reason: kind.name);
    }
    expect(api.sentFileReads, isEmpty);
  });

  testWidgets('redix-api #131: «يُصدر التقارير» issues and takes the files without moving money or seeing all capital', (tester) async {
    final (:api, capture: _) = await openReports(tester, (api) {
      api
        ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
        ..periodicAnswer = issuedReport();
    }, permissions: const ['readProject', 'seeReports', 'generateReports']);

    expect(isEnabled(tester, ReportsScreen.issueKey), isTrue);
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.periodicKey(1))));

    for (final kind in const [ReportFileKind.pdf, ReportFileKind.excel, ReportFileKind.print]) {
      expect(isEnabled(tester, ReportFileButtons.buttonKey('report-1', kind)), isTrue, reason: kind.name);
    }
  });

  testWidgets('redix-api #131: a finished project issues nothing, and «يُصدر التقارير» still takes its files', (tester) async {
    final api = FakeApi()..addProject('غصون 6', status: 'finished', units: ['الفلة']);
    api
      ..periodicRows.add({'number': 1, 'issuedAt': '2026-11-05T20:00:00Z', 'expenses': 140})
      ..periodicAnswer = issuedReport();
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.reportsKey('project-0'));

    expect(isEnabled(tester, ReportsScreen.issueKey), isFalse);
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.periodicKey(1))));

    expect(isEnabled(tester, ReportFileButtons.buttonKey('report-1', ReportFileKind.pdf)), isTrue);
  });

  testWidgets('UC-057, D20: the VAT statement hands on its workbook for the period shown', (tester) async {
    final (:api, :capture) = await openReports(tester, (api) {});
    await act(tester, api, () => tester.pageBack());
    await openFromTheHome(tester, api, VatStatementScreen.pathOf('project-0'));
    final quarter = quarterOf(riyadhToday());
    final name = VatStatementScreen.fileNameOf(quarter);
    final from = apiDate(quarter.$1);
    final to = apiDate(quarter.$2);

    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey(name, ReportFileKind.excel))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey(name, ReportFileKind.excel, FileHandling.share))));

    expect(capture.sharedOut.single, ('$name.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'));
    expect(api.sentFileReads.single, '/projects/project-0/vat-statement/xlsx?from=$from&to=$to');
    expect(tester.widget<Text>(find.byKey(ScreenTitle.titleKey)).data, 'en vat.title');
  });

  testWidgets('AC-33.1: an item report hands on its PDF', (tester) async {
    final (:api, :capture) = await openReports(tester, (api) {
      api.summaryAnswer = {
        ...api.summaryAnswer,
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
    await act(tester, api, () => tester.pageBack());
    await scrollAndTap(tester, api, HomeScreen.itemReportsKey('project-0', SummarySide.expenses));
    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.categoryKey('category-1'))));
    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.itemKey('item-1'))));

    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey('البلاط', ReportFileKind.pdf))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey('البلاط', ReportFileKind.pdf, FileHandling.share))));

    expect(find.byKey(ItemReportScreen.totalKey), findsOneWidget);
    expect(capture.sharedOut.single, ('البلاط.pdf', 'application/pdf'));
  });

  testWidgets('redix-api #131: without «يُصدر التقارير» an item report\'s PDF and Excel show gray', (tester) async {
    final (:api, capture: _) = await openReports(tester, (api) {
      api.summaryAnswer = {
        ...api.summaryAnswer,
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
    }, permissions: const ['readProject', 'seeReports', 'seeAllCapital']);
    await act(tester, api, () => tester.pageBack());
    await scrollAndTap(tester, api, HomeScreen.itemReportsKey('project-0', SummarySide.expenses));
    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.categoryKey('category-1'))));
    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.itemKey('item-1'))));

    expect(isEnabled(tester, ReportFileButtons.buttonKey('البلاط', ReportFileKind.pdf)), isFalse);
    expect(isEnabled(tester, ReportFileButtons.buttonKey('البلاط', ReportFileKind.excel)), isFalse);
  });

  testWidgets('a file that cannot be read says so', (tester) async {
    final (:api, capture: _) = await openReports(tester, (api) {});
    final contract = api.addContract('project-0', 'مبلط الغربية', value: 34000)['id']! as String;
    await act(tester, api, () => tester.pageBack());
    await scrollAndTap(tester, api, HomeScreen.contractsKey('project-0'));
    api.online = false;

    await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.menuKey(contract))));
    await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.fileKey(ReportFileKind.pdf))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey('مبلط الغربية', ReportFileKind.pdf, FileHandling.share))));

    expect(tester.widget<Text>(find.byKey(messageKeyOf('reports.fileFailed').label)).data, 'en reports.fileFailed');
  });
}
