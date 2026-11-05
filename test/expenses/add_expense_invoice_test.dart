import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/expenses/add_expense_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';

import '../app_harness.dart';

void main() {
  /// A picture small enough to draw, which the fake camera hands over.
  final picture = PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng));

  Future<({FakeApi api, FakeCapture capture})> openExpense(WidgetTester tester, {PickedFile? camera}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field, units: ['الفلة الغربية']);
    final capture = FakeCapture()..camera = camera ?? PickedFile.none();
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addExpenseKey('project-0'))));
    return (api: api, capture: capture);
  }

  testWidgets('FR-10: the camera opens first, and the picture it gives stays on the screen', (tester) async {
    final opened = await openExpense(tester, camera: picture);

    expect(opened.capture.cameraOpened, 1);
    expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsOneWidget);
  });

  testWidgets('going back from the camera leaves the way to take it again', (tester) async {
    final opened = await openExpense(tester);

    expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsNothing);
    expect(find.text('en attachments.takePhoto'), findsOneWidget);

    opened.capture.camera = picture;
    await act(tester, opened.api, () => tester.tap(find.byKey(AddExpenseScreen.cameraKey)));

    expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsOneWidget);
    expect(find.text('en attachments.retake'), findsOneWidget);
  });

  testWidgets('no camera permission: the message says so and the files stay offered', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile.failed('attachments.cameraFailed'));

    expect(tester.widget<Text>(find.byKey(AddExpenseScreen.invoiceMessageKey)).data, 'en attachments.cameraFailed');

    opened.capture.files = picture;
    await act(tester, opened.api, () => tester.tap(find.byKey(AddExpenseScreen.filesKey)));

    expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsOneWidget);
    expect(find.byKey(AddExpenseScreen.invoiceMessageKey), findsNothing);
  });

  testWidgets('a PDF picked from the files shows its name', (tester) async {
    final opened = await openExpense(tester);

    opened.capture.files = PickedFile('فاتورة.pdf', '/phone/فاتورة.pdf', Uint8List.fromList([1, 2, 3]));
    await act(tester, opened.api, () => tester.tap(find.byKey(AddExpenseScreen.filesKey)));

    expect(tester.widget<Text>(find.byKey(AddExpenseScreen.invoiceNameKey)).data, 'فاتورة.pdf');
  });

  testWidgets('going back from the files keeps the picture already taken', (tester) async {
    final opened = await openExpense(tester, camera: picture);

    await act(tester, opened.api, () => tester.tap(find.byKey(AddExpenseScreen.filesKey)));

    expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsOneWidget);
  });
}
