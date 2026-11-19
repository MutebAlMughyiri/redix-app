// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

void main() {
  /// A picture small enough to draw, which the fake camera hands over.
  final picture = PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng));

  Future<({FakeApi api, FakeCapture capture})> openExpense(WidgetTester tester, {PickedFile? camera}) async {
    final api = FakeApi()..addProject('مشروع A', permissions: field, units: ['الفلة الغربية']);
    final capture = FakeCapture()..camera = camera ?? PickedFile.none();
    await openProject(tester, api, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));
    if (camera != null) {
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.cameraKey)));
    }
    return (api: api, capture: capture);
  }

  testWidgets('FR-10 (the owner, 8 Nov 2026): the camera opens only when asked, and the picture it gives stays on the screen', (tester) async {
    final opened = await openExpense(tester);
    expect(opened.capture.cameraOpened, 0);

    opened.capture.camera = picture;
    await act(tester, opened.api, () => tester.tap(find.byKey(AddEntryScreen.cameraKey)));

    expect(opened.capture.cameraOpened, 1);
    expect(find.byKey(AddEntryScreen.invoicePictureKey), findsOneWidget);
  });

  testWidgets('going back from the camera leaves the way to take it again', (tester) async {
    final opened = await openExpense(tester);

    expect(find.byKey(AddEntryScreen.invoicePictureKey), findsNothing);
    expect(tester.widget<Text>(find.byKey(AddEntryScreen.cameraKey.label)).data, 'en attachments.takePhoto');

    opened.capture.camera = picture;
    await act(tester, opened.api, () => tester.tap(find.byKey(AddEntryScreen.cameraKey)));

    expect(find.byKey(AddEntryScreen.invoicePictureKey), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(AddEntryScreen.cameraKey.label)).data, 'en attachments.retake');
  });

  testWidgets('no camera permission: the message says so and the files stay offered', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile.failed('attachments.cameraFailed'));

    expect(tester.widget<Text>(find.byKey(AddEntryScreen.invoiceMessageKey)).data, 'en attachments.cameraFailed');

    opened.capture.files = picture;
    await act(tester, opened.api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));

    expect(find.byKey(AddEntryScreen.invoicePictureKey), findsOneWidget);
    expect(find.byKey(AddEntryScreen.invoiceMessageKey), findsNothing);
  });

  testWidgets('a PDF picked from the files shows its name', (tester) async {
    final opened = await openExpense(tester);

    opened.capture.files = PickedFile('فاتورة.pdf', '/phone/فاتورة.pdf', Uint8List.fromList([1, 2, 3]));
    await act(tester, opened.api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));

    expect(tester.widget<Text>(find.byKey(AddEntryScreen.invoiceNameKey)).data, 'فاتورة.pdf');
  });

  testWidgets('going back from the files keeps the picture already taken', (tester) async {
    final opened = await openExpense(tester, camera: picture);

    await act(tester, opened.api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));

    expect(find.byKey(AddEntryScreen.invoicePictureKey), findsOneWidget);
  });
}
