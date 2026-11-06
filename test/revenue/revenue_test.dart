import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/reports/reports_screen.dart';
import 'package:redix/reports/vat_statement_screen.dart';
import 'package:redix/revenue/quarter_picker.dart';
import 'package:redix/revenue/revenue_form_screen.dart';
import 'package:redix/revenue/revenue_screen.dart';
import 'package:redix/revenue/sales_invoice_screen.dart';
import 'package:redix/structure/item_picker.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openHome(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة'], startDate: '2025-01-01');
    arrange(api);
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
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

  Map<String, Object> quarter(String start, String end, {double netDue = -150, List<Map<String, Object>> purchases = const []}) => {
    'start': start,
    'end': end,
    'purchases': purchases,
    'sales': <Map<String, Object>>[],
    'purchasesAfterDiscount': 1000,
    'purchasesVat': 150,
    'purchasesTotal': 1150,
    'salesVat': 0,
    'realEstateTax': 0,
    'netDue': netDue,
  };

  Map<String, Object> purchase(String entryId) => {'row': 1, 'entryId': entryId, 'date': '2026-08-02', 'companyName': 'البواني', 'description': 'بلاط / البواني / ف2617', 'total': 1150, 'isCreditNote': false};

  group('UC-047', () {
    testWidgets('AC-28.1: a refund shows what the statement expected and the difference', (tester) async {
      await openRevenue(tester, (api) => api.addRevenue(type: 'vatRefund', amount: 140, statementRefund: 150, refundDifference: -10));

      expect(find.text('en revenue.statementRefund: 150.00 · en revenue.refundDifference: (10.00)'), findsOneWidget);
    });

    testWidgets('FR-28: a refund goes on its revenue item and sends its quarter, its amount and its account', (tester) async {
      late String refunds;
      final api = await openRevenue(tester, (api) {
        api.addAccount('project-0', 'البنك');
        refunds = api.addItem(api.addCategory('project-0', 'استرجاع ضرائب'), 'استرجاع الضرائب', type: 'vatRefund')['id']! as String;
      });
      final accountId = api.accounts['project-0']!.single['id']! as String;
      await act(tester, api, () => tester.tap(find.byKey(RevenueScreen.newKey)));

      expect(find.byKey(QuarterPicker.yearKey(2026)), findsNothing);
      await act(tester, api, () => tester.tap(find.byKey(RevenueFormScreen.itemKey)));
      await act(tester, api, () => tester.tap(find.byKey(ItemPicker.optionKey(refunds))));
      await act(tester, api, () => tester.tap(find.byKey(QuarterPicker.yearKey(2026))));
      await act(tester, api, () => tester.tap(find.byKey(QuarterPicker.quarterKey(2))));
      await tester.enterText(find.byKey(RevenueFormScreen.amountKey), '140');
      await act(tester, api, () => tester.tap(find.byKey(RevenueFormScreen.accountKey(accountId))));
      await act(tester, api, () => tester.tap(find.byKey(RevenueFormScreen.saveKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-0/revenue');
      expect((body['itemId'], body['periodStart'], body['amount'], body['accountId']), (refunds, '2026-04-01', 140.0, accountId));
      expect(find.byKey(RevenueFormScreen.saveKey), findsNothing);
    });

    testWidgets('other revenue goes on its item and sends no quarter', (tester) async {
      late String other;
      final api = await openRevenue(tester, (api) => other = api.addItem(api.addCategory('project-0', 'إيرادات أخرى'), 'إيرادات أخرى', type: 'otherRevenue')['id']! as String);
      await act(tester, api, () => tester.tap(find.byKey(RevenueScreen.newKey)));

      await act(tester, api, () => tester.tap(find.byKey(RevenueFormScreen.itemKey)));
      await act(tester, api, () => tester.tap(find.byKey(ItemPicker.optionKey(other))));
      await tester.enterText(find.byKey(RevenueFormScreen.amountKey), '70');
      await act(tester, api, () => tester.tap(find.byKey(RevenueFormScreen.saveKey)));

      expect(api.sentMoney.single.$2.containsKey('periodStart'), isFalse);
      expect(api.sentMoney.single.$2['itemId'], other);
    });

    testWidgets('a refused entry says why and stays', (tester) async {
      final api = await openRevenue(tester, (api) => api.moneyAnswer = (status: 400, code: 'unknownAccount'));
      await act(tester, api, () => tester.tap(find.byKey(RevenueScreen.newKey)));

      await tester.enterText(find.byKey(RevenueFormScreen.amountKey), '70');
      await act(tester, api, () => tester.tap(find.byKey(RevenueFormScreen.saveKey)));

      expect(find.text('en revenue.unknownAccount'), findsOneWidget);
    });

    testWidgets('everyone sees revenue, and only whoever moves money records it', (tester) async {
      await openRevenue(tester, (api) => api.addRevenue(), permissions: field);

      expect(find.byKey(RevenueScreen.rowKey('revenue-0')), findsOneWidget);
      expect(find.byKey(RevenueScreen.newKey), findsNothing);
    });
  });

  group('UC-048', () {
    testWidgets('a sales invoice sends the buyer and its figures, with the real estate tax by default', (tester) async {
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
      expect((body['buyerName'], body['number'], body['amount'], body['discount'], body['taxType'], body['accountId']), ('أحمد', '12', 900000.0, 0.0, 'realEstateTransaction', accountId));
      expect(body.containsKey('saleEntryId'), isFalse);
    });

    testWidgets('AC-42.1: an invoice may go on a sale already recorded, so it counts once', (tester) async {
      final api = await openRevenue(tester, (api) => api.addRevenue(type: 'sale', amount: 900000));
      await act(tester, api, () => tester.tap(find.byKey(RevenueScreen.newSaleKey)));

      await tester.enterText(find.byKey(SalesInvoiceScreen.buyerKey), 'أحمد');
      await tester.enterText(find.byKey(SalesInvoiceScreen.numberKey), '12');
      await tester.enterText(find.byKey(SalesInvoiceScreen.amountKey), '900000');
      await act(tester, api, () => tester.tap(find.byKey(SalesInvoiceScreen.saleKey('revenue-0'))));
      await act(tester, api, () => tester.tap(find.byKey(SalesInvoiceScreen.taxKey('vat'))));
      await act(tester, api, () => tester.tap(find.byKey(SalesInvoiceScreen.saveKey)));

      final body = api.sentMoney.single.$2;
      expect((body['saleEntryId'], body['taxType']), ('revenue-0', 'vat'));
    });
  });

  group('UC-056', () {
    testWidgets('AC-32.2: the third quarter of 2026 runs from 01.07.2026 to 30.09.2026, and a refund shows in brackets', (tester) async {
      await openVat(tester, (api) => api.vatAnswer = {'from': '2026-07-01', 'to': '2026-09-30', 'quarters': [quarter('2026-07-01', '2026-09-30')], 'exceptions': <Map<String, Object>>[]});

      expect(find.textContaining('01.07.2026 – 30.09.2026'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(VatStatementScreen.netKey('2026-07-01'))).data, '(150.00)');
    });

    testWidgets('choosing a quarter reads its first and last days', (tester) async {
      final api = await openVat(tester, (api) {});

      await act(tester, api, () => tester.tap(find.byKey(QuarterPicker.yearKey(2026))));
      await act(tester, api, () => tester.tap(find.byKey(QuarterPicker.quarterKey(3))));

      expect(api.vatQuery, 'from=2026-07-01&to=2026-09-30');
    });

    testWidgets('AC-32.2: a half-year reads six months', (tester) async {
      final api = await openVat(tester, (api) {});

      await act(tester, api, () => tester.tap(find.byKey(VatStatementScreen.halfYearKey)));
      await act(tester, api, () => tester.tap(find.byKey(QuarterPicker.yearKey(2026))));
      await act(tester, api, () => tester.tap(find.byKey(VatStatementScreen.secondHalfKey)));

      expect(api.vatQuery, 'from=2026-07-01&to=2026-12-31');
    });

    testWidgets('AC-32.3: what was left out shows, saying why', (tester) async {
      await openVat(tester, (api) => api.vatAnswer = {
        'from': '2026-07-01',
        'to': '2026-09-30',
        'quarters': [quarter('2026-07-01', '2026-09-30')],
        'exceptions': [
          {'reason': 'noVatNumber', 'entryId': 'entry-9', 'date': '2026-08-01', 'companyName': 'الأفق', 'invoiceNumber': '77', 'amount': 500},
        ],
      });

      expect(find.byKey(VatStatementScreen.exceptionKey('entry-9')), findsOneWidget);
      expect(find.text('en vat.noVatNumber'), findsOneWidget);
    });

    testWidgets('BR-17: Finance may declare an invoice in the next quarter', (tester) async {
      final api = await openVat(tester, (api) => api.vatAnswer = {'from': '2026-07-01', 'to': '2026-09-30', 'quarters': [quarter('2026-07-01', '2026-09-30', purchases: [purchase('entry-1')])], 'exceptions': <Map<String, Object>>[]});

      await act(tester, api, () => tester.tap(find.text('en vat.purchaseInvoices').last));
      await act(tester, api, () => tester.tap(find.byKey(VatStatementScreen.rowKey('entry-1'))));
      await act(tester, api, () => tester.tap(find.byKey(VatStatementScreen.declareLaterKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-0/entries/entry-1/vat-period');
      expect(body['periodStart'], '2026-10-01');
    });
  });
}
