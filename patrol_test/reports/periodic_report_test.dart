// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/periodic_report_screen.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/reports/reports_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Reports.
Future<void> onReports(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.reportsKey(person.projectId));
  await $.reach($(ReportsScreen.periodicHeadingKey));
}

/// A new manager with some approved money and one issued report, standing on it.
Future<Person> onReportOne(PatrolIntegrationTester $) async {
  final manager = await Given.manager();
  await Given.entriesApproved(manager, [await Given.entry(manager)]);
  await Given.reportIssued(manager);
  await onReports($, manager);
  await $.tapOn(ReportsScreen.periodicKey(1));
  await $.reach($(PeriodicReportScreen.surplusKey));
  return manager;
}

void main() {
  phoneClass('The periodic report (UC-053)', () {
    phoneCase('issuing asks first, saying its number, and the report then shows', ($) async {
      final manager = await Given.manager();
      await onReports($, manager);
      await $.tapOn(ReportsScreen.issueKey);
      await $.reach($(ConfirmDialog.confirmKey));
      await $(ConfirmDialog.confirmKey).tap();
      await $.reach($(ReportsScreen.periodicKey(1)));
    });

    phoneCase('a report opens as it was issued, with the difference from the last', ($) async {
      await onReportOne($);
      await $.reach($(PeriodicReportScreen.titleKey));
      await $.reach($(PeriodicReportScreen.differenceKey));
    });

    phoneCase('AC-48.1: print opens the phone\'s printer with the PDF', ($) async {
      await onReportOne($);
      await $.tapToThePhone(ReportFileButtons.buttonKey('report-1', ReportFileKind.print));
      await $.printScreenOpens();
    });

    phoneCase('AC-48.1: share hands on the workbook', ($) async {
      await onReportOne($);
      await $.tapOn(ReportFileButtons.buttonKey('report-1', ReportFileKind.excel));
      await $.tapToThePhone(ReportFileButtons.handingKey('report-1', ReportFileKind.excel, FileHandling.share));
      await $.shareSheetOffers('.xlsx');
    });

    phoneCase('AC-48.1: saving keeps the workbook in the phone\'s Download folder', ($) async {
      await onReportOne($);
      await $.tapOn(ReportFileButtons.buttonKey('report-1', ReportFileKind.excel));
      await $.tapOn(ReportFileButtons.handingKey('report-1', ReportFileKind.excel, FileHandling.save));
      await $.messageShows('reports.downloaded');
      await Pc.expectDownloaded('report-1');
    });

    phoneCase('Reports holds the periodic reports alone', ($) async {
      final manager = await Given.manager();
      await onReports($, manager);
      expect($(ReportsScreen.periodicCardKey), findsOneWidget);
    });

    phoneCase('Cancel issues nothing', ($) async {
      final manager = await Given.manager();
      await onReports($, manager);
      await $.tapOn(ReportsScreen.issueKey);
      await $(ConfirmDialog.cancelKey).tap();
      await $.gone($(ConfirmDialog.cancelKey));
      expect($(ReportsScreen.periodicKey(1)), findsNothing);
      await $.reach($(ReportsScreen.noneIssuedKey));
    });

    phoneCase('redix-api #131: without «يُصدر التقارير» Issue shows gray, moving money and seeing all capital or not', ($) async {
      final member = await Given.member(await Given.manager(), permissions: [Permission.seeReports, Permission.moveMoney, Permission.seeAllCapital]);
      await onReports($, member);
      await $.reach($(ReportsScreen.issueKey));
      expect($.isEnabled(ReportsScreen.issueKey), isFalse);
    });

    phoneCase('redix-api #131: «يُصدر التقارير» issues without moving money', ($) async {
      final member = await Given.member(await Given.manager(), permissions: [Permission.seeReports, Permission.generateReports]);
      await onReports($, member);
      await $.tapOn(ReportsScreen.issueKey);
      await $.reach($(ConfirmDialog.confirmKey));
      await $(ConfirmDialog.confirmKey).tap();
      await $.reach($(ReportsScreen.periodicKey(1)));
    });

    phoneCase('redix-api #131: whoever holds «يرى التقارير» alone reads the report, its PDF, Excel and Print gray, never hidden', ($) async {
      final manager = await Given.manager();
      await Given.reportIssued(manager);
      final member = await Given.member(manager, permissions: [Permission.seeReports, Permission.seeAllCapital]);
      await onReports($, member);
      await $.tapOn(ReportsScreen.periodicKey(1));
      await $.reach($(PeriodicReportScreen.surplusKey));
      for (final kind in const [ReportFileKind.pdf, ReportFileKind.excel, ReportFileKind.print]) {
        await $.reach($(ReportFileButtons.buttonKey('report-1', kind)));
        expect($.isEnabled(ReportFileButtons.buttonKey('report-1', kind)), isFalse, reason: kind.name);
      }
    });

    phoneCase('redix-api #131: «يُصدر التقارير» takes the files without seeing all capital', ($) async {
      final manager = await Given.manager();
      await Given.reportIssued(manager);
      final member = await Given.member(manager, permissions: [Permission.seeReports, Permission.generateReports]);
      await onReports($, member);
      await $.tapOn(ReportsScreen.periodicKey(1));
      await $.tapOn(ReportFileButtons.buttonKey('report-1', ReportFileKind.excel));
      await $.tapOn(ReportFileButtons.handingKey('report-1', ReportFileKind.excel, FileHandling.save));
      await $.messageShows('reports.downloaded');
    });

    phoneCase('a file that cannot be read says so', ($) async {
      await onReportOne($);
      await Pc.cutNetwork();
      await $.tapOn(ReportFileButtons.buttonKey('report-1', ReportFileKind.print));
      await $.messageSays('reports.fileFailed', $.words.reportsFileFailed);
    });
  });
}
