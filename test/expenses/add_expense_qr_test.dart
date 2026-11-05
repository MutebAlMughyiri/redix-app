import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/expenses/add_expense_screen.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/change_dialog.dart';

import '../app_harness.dart';
import 'made_up_qr.dart';

void main() {
  final picture = PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng));

  Future<({FakeApi api, FakeCapture capture})> openExpense(WidgetTester tester, String qrText, {bool hasSupplier = true, List<String> permissions = field}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة الغربية']);
    if (hasSupplier) {
      api.addSupplier('project-0', 'شركة البواني للتجارة', vatNumber: '310823353100003');
    }
    final capture = FakeCapture()
      ..camera = picture
      ..qrText = qrText;
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addExpenseKey('project-0'))));
    return (api: api, capture: capture);
  }

  String shown(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  String typed(WidgetTester tester, Key key) => tester.widget<TextField>(find.byKey(key)).controller!.text;

  testWidgets('AC-11.1: the five fields fill, and the supplier with that VAT number is chosen', (tester) async {
    await openExpense(tester, madeUpQr());

    expect(shown(tester, AddExpenseScreen.qrReadKey), 'en expenses.qrRead');
    expect(shown(tester, AddExpenseScreen.qrSellerKey), 'شركة البواني للتجارة');
    expect(shown(tester, AddExpenseScreen.qrVatNumberKey), '310823353100003');
    expect(shown(tester, AddExpenseScreen.qrTimeKey), '26.10.2026 14:25');
    expect(shown(tester, AddExpenseScreen.qrAmountsKey), 'en expenses.total 6,000.00 · en expenses.vat 782.61');
    expect(typed(tester, AddExpenseScreen.amountKey), '6000');
    expect(find.text('شركة البواني للتجارة'), findsNWidgets(2));
    expect(shown(tester, AddExpenseScreen.supplierDetailsKey), contains('310823353100003'));
    expect(find.descendant(of: find.byKey(AddExpenseScreen.invoiceDateKey), matching: find.text(formatDate(DateTime(2026, 10, 26)))), findsOneWidget);
    expect(shown(tester, AddExpenseScreen.totalKey), '6,000.00');
  });

  testWidgets('a QR code sets the amount as including VAT, whatever was chosen', (tester) async {
    final opened = await openExpense(tester, '');
    await tester.ensureVisible(find.byKey(AddExpenseScreen.beforeVatKey));
    await tester.pumpAndSettle();
    await act(tester, opened.api, () => tester.tap(find.byKey(AddExpenseScreen.beforeVatKey)));

    opened.capture.qrText = madeUpQr();
    await tester.ensureVisible(find.byKey(AddExpenseScreen.cameraKey));
    await tester.pumpAndSettle();
    await act(tester, opened.api, () => tester.tap(find.byKey(AddExpenseScreen.cameraKey)));

    expect(shown(tester, AddExpenseScreen.afterDiscountKey), '5,217.39');
    expect(shown(tester, AddExpenseScreen.vatKey), '782.61');
  });

  for (final text in ['', 'https://example.com/invoice']) {
    testWidgets('AC-11.2: a QR code that reads "$text" says it could not be read, and the fields stay open', (tester) async {
      await openExpense(tester, text);

      expect(shown(tester, AddExpenseScreen.qrMessageKey), 'en expenses.qrUnreadable');
      expect(find.byKey(AddExpenseScreen.qrReadKey), findsNothing);
      expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsOneWidget);
      expect(typed(tester, AddExpenseScreen.amountKey), isEmpty);
      await tester.enterText(find.byKey(AddExpenseScreen.amountKey), '100');
      await tester.pumpAndSettle();
      expect(shown(tester, AddExpenseScreen.totalKey), '100.00');
    });
  }

  testWidgets('supplier not in the register: the app offers a quick add with the seller and its number, and goes on with it', (tester) async {
    final opened = await openExpense(tester, madeUpQr(), hasSupplier: false);

    expect(find.byKey(AddExpenseScreen.supplierDetailsKey), findsNothing);
    expect(shown(tester, AddExpenseScreen.qrSupplierMissingKey), 'en expenses.qrSupplierMissing');

    await tester.ensureVisible(find.byKey(AddExpenseScreen.qrAddSupplierKey));
    await tester.pumpAndSettle();
    await act(tester, opened.api, () => tester.tap(find.byKey(AddExpenseScreen.qrAddSupplierKey)));
    expect(tester.widget<TextField>(find.byKey(SuppliersScreen.supplierNameKey)).controller!.text, 'شركة البواني للتجارة');
    expect(tester.widget<TextField>(find.byKey(SuppliersScreen.vatNumberKey)).controller!.text, '310823353100003');

    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(find.byKey(AddExpenseScreen.qrSupplierMissingKey), findsNothing);
    expect(shown(tester, AddExpenseScreen.supplierDetailsKey), contains('310823353100003'));
  });

  testWidgets('who cannot add a supplier is told, and offered nothing to tap', (tester) async {
    await openExpense(tester, madeUpQr(), hasSupplier: false, permissions: ['readProject', 'recordEntries', 'attachFiles']);

    expect(find.byKey(AddExpenseScreen.qrAddSupplierKey), findsNothing);
  });

  testWidgets('AC-11.3: a QR code\'s VAT more than 0.01 from the computed VAT warns, and saving still works', (tester) async {
    final opened = await openExpense(tester, madeUpQr(vat: '700.00'));

    expect(shown(tester, AddExpenseScreen.qrVatDiffersKey), 'en expenses.qrVatDiffers');

    await tester.ensureVisible(find.byKey(AddExpenseScreen.draftKey));
    await tester.pumpAndSettle();
    await act(tester, opened.api, () => tester.tap(find.byKey(AddExpenseScreen.draftKey)));

    expect(opened.api.sentExpenses, hasLength(1));
  });

  testWidgets('AC-11.3: a QR code\'s VAT within 0.01 of the computed VAT does not warn', (tester) async {
    await openExpense(tester, madeUpQr(vat: '782.61'));

    expect(find.byKey(AddExpenseScreen.qrVatDiffersKey), findsNothing);
  });

  testWidgets('AC-11.3: the warning follows the fields as they change', (tester) async {
    await openExpense(tester, madeUpQr(vat: '782.61'));

    await tester.enterText(find.byKey(AddExpenseScreen.amountKey), '5000');
    await tester.pumpAndSettle();

    expect(find.byKey(AddExpenseScreen.qrVatDiffersKey), findsOneWidget);
  });

  testWidgets('a PDF is not looked at for a QR code, and says nothing about one', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field, units: ['الفلة الغربية']);
    final capture = FakeCapture()..files = PickedFile('invoice.pdf', '/phone/invoice.pdf', Uint8List.fromList([1, 2, 3]));
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addExpenseKey('project-0'))));

    await tester.ensureVisible(find.byKey(AddExpenseScreen.filesKey));
    await act(tester, api, () => tester.tap(find.byKey(AddExpenseScreen.filesKey)));

    expect(capture.qrReads, 0);
    expect(find.byKey(AddExpenseScreen.qrMessageKey), findsNothing);
  });

  testWidgets('a picture from the files is read too, and going back from the camera keeps what was read', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field, units: ['الفلة الغربية']);
    api.addSupplier('project-0', 'شركة البواني للتجارة', vatNumber: '310823353100003');
    final capture = FakeCapture()
      ..files = picture
      ..qrText = madeUpQr();
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addExpenseKey('project-0'))));

    await tester.ensureVisible(find.byKey(AddExpenseScreen.filesKey));
    await act(tester, api, () => tester.tap(find.byKey(AddExpenseScreen.filesKey)));
    expect(find.byKey(AddExpenseScreen.qrReadKey), findsOneWidget);

    await tester.ensureVisible(find.byKey(AddExpenseScreen.cameraKey));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(AddExpenseScreen.cameraKey)));
    expect(find.byKey(AddExpenseScreen.qrReadKey), findsOneWidget);
  });

  testWidgets('a picture taken again starts its reading afresh', (tester) async {
    final opened = await openExpense(tester, madeUpQr());

    opened.capture.qrText = '';
    await tester.ensureVisible(find.byKey(AddExpenseScreen.cameraKey));
    await tester.pumpAndSettle();
    await act(tester, opened.api, () => tester.tap(find.byKey(AddExpenseScreen.cameraKey)));

    expect(find.byKey(AddExpenseScreen.qrReadKey), findsNothing);
    expect(shown(tester, AddExpenseScreen.qrMessageKey), 'en expenses.qrUnreadable');
  });
}
