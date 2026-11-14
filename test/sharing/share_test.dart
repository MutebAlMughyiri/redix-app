import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/sharing/share_screen.dart';
import 'package:redix/ui/screen_title.dart';

import '../app_harness.dart';
import 'package:redix/entries/table_picker.dart';

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
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.tableKey)));
    final items = api.categories['project-0']!.single['items']! as List<Map<String, Object>>;
    final table = (items.single['subgroups']! as List<Map<String, Object>>).first['id']! as String;
    await act(tester, api, () => tester.tap(find.byKey(TablePicker.optionKey(table))));
  }

  testWidgets('findings row 177: the share screen picks from the one table list of Add entry, expense tables only', (tester) async {
    late String revenueTable;
    final (:api, capture: _) = await share(tester, (api) {
      final refund = api.addItem(api.addCategory('project-0', 'استرجاع ضرائب'), 'استرجاع الضرائب', type: 'vatRefund');
      revenueTable = (refund['subgroups']! as List<Map<String, Object>>).first['id']! as String;
    });

    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.tableKey)));

    final items = api.categories['project-0']!.first['items']! as List<Map<String, Object>>;
    expect(find.byKey(TablePicker.optionKey((items.single['subgroups']! as List<Map<String, Object>>).first['id']! as String)), findsOneWidget);
    expect(find.byKey(TablePicker.optionKey(revenueTable)), findsNothing);
  });

  testWidgets('AC-49.1: a shared file opens the attach screen', (tester) async {
    await share(tester, (api) {});

    expect(find.byKey(ShareScreen.tableKey), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(ScreenTitle.titleKey)).data, 'en share.title');
  });

  testWidgets('findings row 211 (Muteb, 13 Nov 2026): the shared picture\'s preview is a quarter of the screen\'s height, never a fixed number', (tester) async {
    await share(tester, (api) {});

    expect(tester.getSize(find.byKey(ShareScreen.pictureKey)).height, 2400 / 4);
  });

  testWidgets('AC-49.1: not signed in, sign in comes first and the attach screen continues with the file', (tester) async {
    final (:api, :capture) = await share(tester, (api) {}, signedIn: false);
    expect(capture.cameraOpened, 0);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);

    await tester.enterText(find.byKey(SignInScreen.usernameKey), 'ahmed');
    await tester.enterText(find.byKey(SignInScreen.passwordKey), 'correct-password');
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.submitKey)));

    expect(find.byKey(ShareScreen.tableKey), findsOneWidget);
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

    expect(find.byKey(ShareScreen.tableKey), findsNothing);
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
    expect(find.byKey(ShareScreen.amountDiffersKey), findsNothing);
    expect(find.byKey(ShareScreen.supplierDiffersKey), findsNothing);
    expect(api.sentReads.last, contains('attachable'));
  });

  testWidgets('without a QR code nothing is chosen, and the attach button waits', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addAttachable(id: 'entry-1'));

    await chooseItem(tester, api);

    expect(find.byKey(ShareScreen.attachKey), findsNothing);
  });

  testWidgets('AC-49.3: choosing shows what differs from the QR code', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addAttachable(id: 'entry-1', status: 'approved', amount: 5000, supplierVatNumber: '300000000000099'), qrText: _qrText());

    await chooseItem(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.entryKey('entry-1'))));

    expect(find.byKey(ShareScreen.amountDiffersKey), findsOneWidget);
    expect(find.byKey(ShareScreen.supplierDiffersKey), findsOneWidget);
  });

  testWidgets('D15: attaching keeps the file, puts it alone on the expense, and lets go of it', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addAttachable(id: 'entry-1', amount: 6000, supplierVatNumber: _vatNumber), qrText: _qrText());

    await chooseItem(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.entryKey('entry-1'))));
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.attachKey)));

    expect(api.sentAttachments, hasLength(1));
    expect(api.sentInvoices.single.$1, 'entry-1');
    expect(api.sentInvoices.single.$2.keys, ['attachmentId']);
    expect(find.byKey(ShareScreen.tableKey), findsNothing);
  });

  testWidgets('BR-22: a file already on another expense is refused, and the person stays', (tester) async {
    final (:api, capture: _) = await share(tester, (api) {
      api
        ..addAttachable(id: 'entry-1', amount: 6000, supplierVatNumber: _vatNumber)
        ..invoiceAnswer = (status: 409, code: 'invoiceAlreadyAttached');
    }, qrText: _qrText());

    await chooseItem(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.entryKey('entry-1'))));
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.attachKey)));

    expect(tester.widget<Text>(find.byKey(ShareScreen.messageKey)).data, 'en share.invoiceAlreadyAttached');
    expect(find.byKey(ShareScreen.tableKey), findsOneWidget);
  });

  testWidgets('UC-046: a new expense opens with the shared file and its QR code, not the camera', (tester) async {
    final (:api, :capture) = await share(tester, (api) {}, qrText: _qrText());

    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.newExpenseKey)));

    expect(capture.cameraOpened, 0);
    expect(find.byKey(AddEntryScreen.invoicePictureKey), findsOneWidget);
    expect(find.byKey(AddEntryScreen.qrReadKey), findsOneWidget);
  });
}
