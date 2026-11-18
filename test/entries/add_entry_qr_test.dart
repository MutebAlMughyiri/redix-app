// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';
import '../expenses/made_up_qr.dart';

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
    await openProject(tester, api, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.cameraKey)));
    return (api: api, capture: capture);
  }

  String shown(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  String typed(WidgetTester tester, Key key) => tester.widget<TextField>(find.byKey(key)).controller!.text;

  testWidgets('AC-11.1, D21: the date, the total and the supplier fill, from the QR code', (tester) async {
    await openExpense(tester, madeUpQr());

    expect(shown(tester, AddEntryScreen.qrReadKey), 'en expenses.qrRead');
    expect(shown(tester, AddEntryScreen.qrSellerKey), 'شركة البواني للتجارة');
    expect(shown(tester, AddEntryScreen.qrVatNumberKey), '310823353100003');
    expect(shown(tester, AddEntryScreen.qrTimeKey), '26.10.2026 14:25');
    expect(shown(tester, AddEntryScreen.qrAmountsKey), 'en expenses.total 6,000.00');
    expect(typed(tester, AddEntryScreen.amountKey), '6000');
    expect(shown(tester, AddEntryScreen.supplierKey.label), 'شركة البواني للتجارة');
    expect(shown(tester, AddEntryScreen.supplierDetailsKey), contains('310823353100003'));
    expect(shown(tester, AddEntryScreen.dateKey.label), formatDate(DateTime(2026, 10, 26)));
  });

  for (final text in ['', 'https://example.com/invoice']) {
    testWidgets('AC-11.2: a QR code that reads "$text" says it could not be read, and the fields stay open', (tester) async {
      await openExpense(tester, text);

      expect(shown(tester, AddEntryScreen.qrMessageKey), 'en expenses.qrUnreadable');
      expect(find.byKey(AddEntryScreen.qrReadKey), findsNothing);
      expect(find.byKey(AddEntryScreen.invoicePictureKey), findsOneWidget);
      expect(typed(tester, AddEntryScreen.amountKey), isEmpty);
      await tester.enterText(find.byKey(AddEntryScreen.amountKey), '100');
      await tester.pumpAndSettle();
      expect(typed(tester, AddEntryScreen.amountKey), '100');
    });
  }

  testWidgets('supplier not in the register: the app offers a quick add with the seller and its number, and goes on with it', (tester) async {
    final opened = await openExpense(tester, madeUpQr(), hasSupplier: false);

    expect(find.byKey(AddEntryScreen.supplierDetailsKey), findsNothing);
    expect(shown(tester, AddEntryScreen.qrSupplierMissingKey), 'en expenses.qrSupplierMissing');

    await tester.ensureVisible(find.byKey(AddEntryScreen.qrAddSupplierKey));
    await tester.pumpAndSettle();
    await act(tester, opened.api, () => tester.tap(find.byKey(AddEntryScreen.qrAddSupplierKey)));
    expect(tester.widget<TextField>(find.byKey(SuppliersScreen.supplierNameKey)).controller!.text, 'شركة البواني للتجارة');
    expect(tester.widget<TextField>(find.byKey(SuppliersScreen.vatNumberKey)).controller!.text, '310823353100003');

    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(find.byKey(AddEntryScreen.qrSupplierMissingKey), findsNothing);
    expect(shown(tester, AddEntryScreen.supplierDetailsKey), contains('310823353100003'));
  });

  testWidgets('who cannot add a supplier is told, and offered nothing to tap', (tester) async {
    await openExpense(tester, madeUpQr(), hasSupplier: false, permissions: ['readProject', 'recordEntries', 'attachFiles']);

    expect(find.byKey(AddEntryScreen.qrAddSupplierKey), findsNothing);
  });

  testWidgets('a PDF is not looked at for a QR code, and says nothing about one', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field, units: ['الفلة الغربية']);
    final capture = FakeCapture()..files = PickedFile('invoice.pdf', '/phone/invoice.pdf', Uint8List.fromList([1, 2, 3]));
    await openProject(tester, api, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));

    await tester.ensureVisible(find.byKey(AddEntryScreen.filesKey));
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));

    expect(capture.qrReads, 0);
    expect(find.byKey(AddEntryScreen.qrMessageKey), findsNothing);
  });

  testWidgets('a picture from the files is read too, and going back from the camera keeps what was read', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field, units: ['الفلة الغربية']);
    api.addSupplier('project-0', 'شركة البواني للتجارة', vatNumber: '310823353100003');
    final capture = FakeCapture()
      ..files = picture
      ..qrText = madeUpQr();
    await openProject(tester, api, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));

    await tester.ensureVisible(find.byKey(AddEntryScreen.filesKey));
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));
    expect(find.byKey(AddEntryScreen.qrReadKey), findsOneWidget);

    await tester.ensureVisible(find.byKey(AddEntryScreen.cameraKey));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.cameraKey)));
    expect(find.byKey(AddEntryScreen.qrReadKey), findsOneWidget);
  });

  testWidgets('a picture taken again starts its reading afresh', (tester) async {
    final opened = await openExpense(tester, madeUpQr());

    opened.capture.qrText = '';
    await tester.ensureVisible(find.byKey(AddEntryScreen.cameraKey));
    await tester.pumpAndSettle();
    await act(tester, opened.api, () => tester.tap(find.byKey(AddEntryScreen.cameraKey)));

    expect(find.byKey(AddEntryScreen.qrReadKey), findsNothing);
    expect(shown(tester, AddEntryScreen.qrMessageKey), 'en expenses.qrUnreadable');
  });
}
