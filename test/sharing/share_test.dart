import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/expenses/add_expense_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/sharing/share_screen.dart';
import 'package:redix/structure/item_picker.dart';

import '../app_harness.dart';

const _vatNumber = '300000000000003';

String _qrText({double total = 6000}) {
  final fields = ['شركة البواني', _vatNumber, '2026-10-26T10:00:00Z', '$total', '782.61'];
  final bytes = <int>[];
  for (var tag = 0; tag < fields.length; tag++) {
    final value = utf8.encode(fields[tag]);
    bytes
      ..add(tag + 1)
      ..add(value.length)
      ..addAll(value);
  }
  return base64.encode(bytes);
}

PickedFile _picture() => PickedFile('invoice.png', '', Uint8List.fromList(onePixelPng));

void main() {
  Future<({FakeApi api, FakeCapture capture})> share(WidgetTester tester, void Function(FakeApi api) arrange, {String qrText = '', PickedFile? file, List<String> permissions = field, bool signedIn = true}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة الغربية']);
    api.addItem(api.addCategory('project-0', 'التشطيب'), 'اللياسة');
    arrange(api);
    final capture = FakeCapture()..qrText = qrText;
    await pumpRedix(tester, api, stored: signedIn ? {'session': keptSession} : const {}, capture: capture);
    capture.share(file ?? _picture());
    await act(tester, api, () async {});
    return (api: api, capture: capture);
  }

  Future<void> chooseItem(WidgetTester tester, FakeApi api) async {
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.itemKey)));
    final items = api.categories['project-0']!.single['items']! as List<Map<String, Object>>;
    await act(tester, api, () => tester.tap(find.byKey(ItemPicker.optionKey(items.single['id']! as String))));
  }

  testWidgets('AC-49.1: a shared file opens the attach screen', (tester) async {
    await share(tester, (api) {});

    expect(find.byKey(ShareScreen.itemKey), findsOneWidget);
    expect(find.text('en share.title'), findsOneWidget);
  });

  testWidgets('AC-49.1: not signed in, sign in comes first and the attach screen continues with the file', (tester) async {
    final (:api, :capture) = await share(tester, (api) {}, signedIn: false);
    expect(capture.cameraOpened, 0);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);

    await tester.enterText(find.byKey(SignInScreen.usernameKey), 'ahmed');
    await tester.enterText(find.byKey(SignInScreen.passwordKey), 'correct-password');
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.submitKey)));

    expect(find.byKey(ShareScreen.itemKey), findsOneWidget);
  });

  testWidgets('without a project to enter in, the screen says so', (tester) async {
    await share(tester, (api) {}, permissions: const ['readProject']);

    expect(find.byKey(ShareScreen.noProjectKey), findsOneWidget);
  });

  testWidgets('with more than one project, the person chooses', (tester) async {
    await share(tester, (api) => api.addProject('غصون 7', permissions: field, units: ['الفلة']));

    expect(find.byKey(ShareScreen.projectKey('project-0')), findsOneWidget);
    expect(find.byKey(ShareScreen.projectKey('project-1')), findsOneWidget);
  });

  testWidgets('leaving lets go of the file', (tester) async {
    final (:api, capture: _) = await share(tester, (api) {});

    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.closeKey)));

    expect(find.byKey(ShareScreen.itemKey), findsNothing);
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('AC-49.2: the expense matching the QR code is marked and chosen', (tester) async {
    final (:api, capture: _) = await share(tester, (api) {
      api
        ..addAttachable(id: 'entry-other')
        ..addAttachable(id: 'entry-match', isMatching: true, amount: 6000, supplierVatNumber: _vatNumber);
    }, qrText: _qrText());

    await chooseItem(tester, api);

    expect(find.byKey(ShareScreen.matchingKey('entry-match')), findsOneWidget);
    expect(find.byKey(ShareScreen.matchingKey('entry-other')), findsNothing);
    expect(find.byKey(ShareScreen.attachKey), findsOneWidget);
    expect(find.byKey(ShareScreen.goesBackKey), findsNothing);
    expect(find.byKey(ShareScreen.amountDiffersKey), findsNothing);
    expect(find.byKey(ShareScreen.supplierDiffersKey), findsNothing);
    expect(api.sentReads.last, contains('attachable'));
  });

  testWidgets('without a QR code nothing is chosen, and the attach button waits', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addAttachable(id: 'entry-1'));

    await chooseItem(tester, api);

    expect(find.byKey(ShareScreen.attachKey), findsNothing);
  });

  testWidgets('AC-49.3: choosing shows what differs and that approved goes back', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addAttachable(id: 'entry-1', status: 'approved', amount: 5000, supplierVatNumber: '300000000000099'), qrText: _qrText());

    await chooseItem(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.entryKey('entry-1'))));

    expect(find.byKey(ShareScreen.goesBackKey), findsOneWidget);
    expect(find.byKey(ShareScreen.amountDiffersKey), findsOneWidget);
    expect(find.byKey(ShareScreen.supplierDiffersKey), findsOneWidget);
  });

  testWidgets('attaching keeps the file, puts it on the expense, and lets go of it', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addAttachable(id: 'entry-1', amount: 6000, supplierVatNumber: _vatNumber), qrText: _qrText());

    await chooseItem(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.entryKey('entry-1'))));
    await tester.enterText(find.byKey(ShareScreen.numberKey), '٢٦١٧');
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.attachKey)));

    expect(api.sentAttachments, hasLength(1));
    expect(api.sentInvoices.single.$1, 'entry-1');
    expect(api.sentInvoices.single.$2, containsPair('invoiceNumber', '2617'));
    expect(api.sentInvoices.single.$2, containsPair('invoiceDate', '2026-10-26'));
    expect(api.sentInvoices.single.$2, containsPair('sellerVatNumber', _vatNumber));
    expect(find.byKey(ShareScreen.itemKey), findsNothing);
  });

  testWidgets('AC-49.3: the same invoice on another expense is refused, and the person stays', (tester) async {
    final (:api, capture: _) = await share(tester, (api) {
      api
        ..addAttachable(id: 'entry-1', amount: 6000, supplierVatNumber: _vatNumber)
        ..invoiceAnswer = (status: 409, code: 'duplicateInvoice');
    }, qrText: _qrText());

    await chooseItem(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.entryKey('entry-1'))));
    await tester.enterText(find.byKey(ShareScreen.numberKey), '2617');
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.attachKey)));

    expect(find.text('en share.duplicateInvoice'), findsOneWidget);
    expect(find.byKey(ShareScreen.itemKey), findsOneWidget);
  });

  testWidgets('UC-046: a new expense opens with the shared file and its QR code, not the camera', (tester) async {
    final (:api, :capture) = await share(tester, (api) {}, qrText: _qrText());

    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.newExpenseKey)));

    expect(capture.cameraOpened, 0);
    expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsOneWidget);
    expect(find.byKey(AddExpenseScreen.qrReadKey), findsOneWidget);
  });
}
