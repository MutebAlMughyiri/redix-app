import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/reports/reports_screen.dart';
import 'package:redix/reports/vat_statement_screen.dart';
import 'package:redix/revenue/quarter_picker.dart';
import 'package:redix/revenue/revenue_screen.dart';
import 'package:redix/revenue/sales_invoice_screen.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openHome(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة'], startDate: '2025-01-01');
    arrange(api);
    await openProject(tester, api);
    return api;
  }

  Future<FakeApi> openRevenue(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    final api = await openHome(tester, arrange, permissions: permissions);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.revenueKey('project-0'))));
    return api;
  }

  Future<FakeApi> openVat(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    final api = await openHome(tester, arrange, permissions: permissions);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.reportsKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(ReportsScreen.vatKey)));
    return api;
  }

  Future<void> takeExcel(WidgetTester tester, FakeApi api, String name) async {
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.buttonKey(name, ReportFileKind.excel))));
    await act(tester, api, () => tester.tap(find.byKey(ReportFileButtons.handingKey(name, ReportFileKind.excel, FileHanding.save))));
  }

  group('UC-047', () {
    testWidgets('everyone sees revenue, and only whoever moves money issues a sales invoice', (tester) async {
      await openRevenue(tester, (api) => api.addRevenue(), permissions: field);

      expect(find.byKey(RevenueScreen.rowKey('revenue-0')), findsOneWidget);
      expect(find.byKey(RevenueScreen.newSaleKey), findsNothing);
    });
  });

  group('UC-048', () {
    testWidgets('D22: a sales invoice sends the buyer, its number and its total', (tester) async {
      final api = await openRevenue(tester, (api) => api.addAccount('project-0', 'البنك'));
      final accountId = api.accounts['project-0']!.single['id']! as String;
      await act(tester, api, () => tester.tap(find.byKey(RevenueScreen.newSaleKey)));

      await tester.enterText(find.byKey(SalesInvoiceScreen.buyerKey), 'أحمد');
      await tester.enterText(find.byKey(SalesInvoiceScreen.numberKey), '١٢');
      await tester.enterText(find.byKey(SalesInvoiceScreen.amountKey), '900000');
      await act(tester, api, () => tester.tap(find.byKey(SalesInvoiceScreen.accountKey(accountId))));
      await act(tester, api, () => tester.tap(find.byKey(SalesInvoiceScreen.saveKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-0/sales-invoices');
      expect((body['buyerName'], body['number'], body['total'], body['accountId']), ('أحمد', '12', 900000.0, accountId));
      for (final gone in ['amount', 'discount', 'taxType', 'saleEntryId']) {
        expect(body.containsKey(gone), isFalse);
      }
    });

    testWidgets('AC-42.1: an invoice may go on a sale already recorded, so it counts once', (tester) async {
      final api = await openRevenue(tester, (api) => api.addRevenue(type: 'sale', amount: 900000));
      await act(tester, api, () => tester.tap(find.byKey(RevenueScreen.newSaleKey)));

      await tester.enterText(find.byKey(SalesInvoiceScreen.buyerKey), 'أحمد');
      await tester.enterText(find.byKey(SalesInvoiceScreen.numberKey), '12');
      await tester.enterText(find.byKey(SalesInvoiceScreen.amountKey), '900000');
      await act(tester, api, () => tester.tap(find.byKey(SalesInvoiceScreen.saleKey('revenue-0'))));
      await act(tester, api, () => tester.tap(find.byKey(SalesInvoiceScreen.saveKey)));

      expect(api.sentMoney.single.$2['saleEntryId'], 'revenue-0');
    });
  });

  group('UC-056', () {
    testWidgets('AC-32.2, D20: the third quarter of 2026 takes its Excel, and nothing else, from 01.07.2026 to 30.09.2026', (tester) async {
      final api = await openVat(tester, (api) {});

      await act(tester, api, () => tester.tap(find.byKey(QuarterPicker.yearKey(2026))));
      await act(tester, api, () => tester.tap(find.byKey(QuarterPicker.quarterKey(3))));
      expect(find.byKey(ReportFileButtons.buttonKey('vat-2026-07-01-2026-09-30', ReportFileKind.pdf)), findsNothing);
      await takeExcel(tester, api, 'vat-2026-07-01-2026-09-30');

      expect(api.sentFileReads.single, '/projects/project-0/vat-statement/xlsx?from=2026-07-01&to=2026-09-30');
    });

    testWidgets('AC-32.2: a half-year takes six months', (tester) async {
      final api = await openVat(tester, (api) {});

      await act(tester, api, () => tester.tap(find.byKey(VatStatementScreen.halfYearKey)));
      await act(tester, api, () => tester.tap(find.byKey(QuarterPicker.yearKey(2026))));
      await act(tester, api, () => tester.tap(find.byKey(VatStatementScreen.secondHalfKey)));
      await takeExcel(tester, api, 'vat-2026-07-01-2026-12-31');

      expect(api.sentFileReads.single, '/projects/project-0/vat-statement/xlsx?from=2026-07-01&to=2026-12-31');
    });

    testWidgets('AC-32.2: a custom period never ends before it starts: a first day after the last moves the last day to it', (tester) async {
      final api = await openVat(tester, (api) {});
      final day = DateTime.now().add(const Duration(days: 30));
      final typed = '${day.month.toString().padLeft(2, '0')}/${day.day.toString().padLeft(2, '0')}/${day.year}';
      final sent = day.toIso8601String().substring(0, 10);

      await act(tester, api, () => tester.tap(find.byKey(VatStatementScreen.customKey)));
      await act(tester, api, () => tester.tap(find.byKey(VatStatementScreen.fromKey)));
      await act(tester, api, () => tester.tap(find.byIcon(Icons.edit_outlined)));
      await tester.enterText(find.byType(TextField).last, typed);
      await act(tester, api, () => tester.tap(find.text('OK')));
      await takeExcel(tester, api, 'vat-$sent-$sent');

      expect(api.sentFileReads.single, '/projects/project-0/vat-statement/xlsx?from=$sent&to=$sent');
    });
  });
}
