import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/reports/quarter_picker.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/reports/vat_statement_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/steps.dart';

/// Signs [person] in and opens the VAT statement.
Future<void> onStatement(PatrolIntegrationTester $, Person person) async {
  await $.openPathFromTheHome(person, VatStatementScreen.pathOf(person.projectId));
  await $.reach($(VatStatementScreen.modeKey));
}

/// The name of the first and last day [from] and [to] take in the name of the file.
String vatName(DateTime from, DateTime to) => 'vat-${from.toIso8601String().substring(0, 10)}-${to.toIso8601String().substring(0, 10)}';

/// The name of the files of the quarter the statement opens on, this one.
String thisQuarter() {
  final start = DateTime(DateTime.now().year, (DateTime.now().month - 1) ~/ 3 * 3 + 1);
  return vatName(start, DateTime(start.year, start.month + 3, 0));
}

/// The workbook button of the quarter the statement opens on.
PatrolFinder excelButton(PatrolIntegrationTester $) => $(ReportFileButtons.buttonKey(thisQuarter(), ReportFileKind.excel));

void main() {
  phoneClass('The VAT statement (UC-047)', () {
    phoneCase('AC-32.2: a quarter\'s Excel covers its first to its last day, and nothing else', ($) async {
      final manager = await Given.manager();
      await onStatement($, manager);
      await excelButton($).waitUntilExists();
      expect(excelButton($), findsOneWidget);
      expect($(ReportFileButtons.buttonKey('x', ReportFileKind.pdf)), findsNothing);
    });

    phoneCase('AC-32.2: a half-year takes six months, chosen by its year and half alone', ($) async {
      final manager = await Given.manager();
      await onStatement($, manager);
      await $.tapOn(VatStatementScreen.halfYearKey);
      await $.pumpAndSettle();
      await $.reach($(VatStatementScreen.firstHalfKey));
      await $.reach($(VatStatementScreen.secondHalfKey));
      for (var quarter = 1; quarter <= 4; quarter++) {
        expect($(QuarterPicker.quarterKey(quarter)), findsNothing);
      }
    });

    phoneCase('AC-32.2: a custom period takes the days picked', ($) async {
      final manager = await Given.manager();
      await onStatement($, manager);
      await $.tapOn(VatStatementScreen.customKey);
      await $.pumpAndSettle();
      await $.reach($(VatStatementScreen.fromKey));
      await $.reach($(VatStatementScreen.toKey));
    });

    phoneCase('D20: the statement hands on its workbook for the period shown', ($) async {
      final manager = await Given.manager();
      await onStatement($, manager);
      await excelButton($).waitUntilExists();
      await excelButton($).tap();
      await $.pumpAndSettle();
      await $(ReportFileButtons.handingKey(thisQuarter(), ReportFileKind.excel, FileHandling.share)).tap(settlePolicy: SettlePolicy.noSettle);
      await $.shareSheetOffers('vat');
    });

    phoneCase('AC-32.2: a custom period never ends before it starts: a first day after the last moves the last day', ($) async {
      final manager = await Given.manager();
      await onStatement($, manager);
      final day = DateTime.now().add(const Duration(days: 30));
      await $.tapOn(VatStatementScreen.customKey);
      await $.pumpAndSettle();
      await $.tapOn(VatStatementScreen.fromKey);
      await $.pumpAndSettle();
      await $.tester.tap(find.byIcon(Icons.edit_outlined));
      await $.pumpAndSettle();
      final typed = find.descendant(of: find.byType(DatePickerDialog), matching: find.byType(TextField));
      await $(typed).enterText('${day.month.toString().padLeft(2, '0')}/${day.day.toString().padLeft(2, '0')}/${day.year}');
      await $.pumpAndSettle();
      await $.tester.tap(find.text(MaterialLocalizations.of($.tester.element(find.byType(DatePickerDialog))).okButtonLabel));
      await $.pumpAndSettle();
      await $.says(VatStatementScreen.fromKey.label, formatDate(day));
      await $.says(VatStatementScreen.toKey.label, formatDate(day));
    });

    phoneCase('whoever does not see all capital gets no workbook', ($) async {
      final member = await Given.member(await Given.manager(), permissions: const <Permission>[]);
      await onStatement($, member);
      await $.pumpAndSettle();
      expect(excelButton($), findsNothing);
    });
  });
}
