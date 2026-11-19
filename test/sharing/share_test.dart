// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/sharing/share_screen.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/screen_title.dart';
import 'package:redix/ui/search_line.dart';

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
  Future<({FakeApi api, FakeCapture capture})> share(WidgetTester tester, void Function(FakeApi api) arrange, {String qrText = '', PickedFile? file, List<String> permissions = field, bool signedIn = true, Size screen = const Size(800, 2400), double textScale = 1}) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة الغربية']);
    api.addItem(api.addCategory('project-0', 'التشطيب'), 'اللياسة');
    arrange(api);
    final capture = FakeCapture()..qrText = qrText;
    await pumpRedix(tester, api, stored: signedIn ? {'session': keptSession} : const {}, capture: capture);
    capture.share(file ?? _picture());
    await act(tester, api, () async {});
    return (api: api, capture: capture);
  }

  /// The entries the share screen lists, by their row's key, in their order.
  List<String> listed() => idsKeyedBy(EntriesScreen.rowKey);

  testWidgets('AC-49.1, AC-46.10b, AC-46.10c, D3: a shared file opens the share screen with the file, its middle القيود\'s list and its search, asking the API only entries that take a file', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api..addEntry(id: 'entry-1')..addEntry(id: 'entry-2', takesAFile: false));

    expect(tester.widget<Text>(find.byKey(ScreenTitle.titleKey)).data, 'en share.title');
    expect(find.byKey(ShareScreen.pictureKey), findsOneWidget);
    expect(find.byKey(SearchLine.searchKey), findsOneWidget);
    expect(api.entryQueries.last['attachable'], ['true']);
    expect(listed(), ['entry-1']);
  });

  testWidgets('findings row 211 (Muteb, 13 Nov 2026): the shared picture\'s preview is a quarter of the screen\'s height, never a fixed number', (tester) async {
    await share(tester, (api) {});

    expect(tester.getSize(find.byKey(ShareScreen.pictureKey)).height, 2400 / 4);
  });

  testWidgets('AC-49.1: not signed in, sign in comes first and the share screen continues with the file', (tester) async {
    final (:api, :capture) = await share(tester, (api) {}, signedIn: false);
    expect(capture.cameraOpened, 0);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);

    await tester.enterText(find.byKey(SignInScreen.usernameKey), 'ahmed');
    await tester.enterText(find.byKey(SignInScreen.passwordKey), 'correct-password');
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.submitKey)));

    expect(find.byKey(ShareScreen.pictureKey), findsOneWidget);
  });

  testWidgets('without a project to enter in, the screen says so', (tester) async {
    await share(tester, (api) {}, permissions: const ['readProject']);

    expect(find.byKey(ShareScreen.noProjectKey), findsOneWidget);
  });

  testWidgets('with more than one project, the person chooses, and the list is the project chosen', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addProject('غصون 7', permissions: field, units: ['الفلة']));

    expect(find.byKey(ShareScreen.projectKey('project-0')), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.projectKey('project-1'))));

    expect(api.sentReads, contains('/projects/project-1/entries'));
  });

  testWidgets('leaving lets go of the file', (tester) async {
    final (:api, capture: _) = await share(tester, (api) {});

    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.closeKey)));

    expect(find.byKey(ShareScreen.pictureKey), findsNothing);
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('AC-49.2, D4: the entry the QR code matches is pinned over the list, saying so, and chosen; the list does not hold it twice', (tester) async {
    final (:api, capture: _) = await share(tester, (api) {
      api
        ..addEntry(id: 'entry-other')
        ..addMatch(id: 'entry-match', supplierVatNumber: _vatNumber);
    }, qrText: _qrText());

    expect(tester.widget<Text>(find.byKey(ShareScreen.matchingKey('entry-match'))).data, 'en share.matches');
    expect(find.byKey(ShareScreen.matchingKey('entry-other')), findsNothing);
    expect(find.byKey(EntriesScreen.rowKey('entry-match')), findsOneWidget);
    expect(tester.widget<ListTile>(find.byKey(EntriesScreen.rowKey('entry-match'))).selected, isTrue);
    expect(find.byKey(ShareScreen.attachKey), findsOneWidget);
    expect(find.byKey(ShareScreen.amountDiffersKey), findsNothing);
    expect(find.byKey(ShareScreen.supplierDiffersKey), findsNothing);
    expect(api.sentReads, contains('/projects/project-0/entries/attachable'));
  });

  testWidgets('findings row 254: on a small phone with large text the picture, the QR code and the pinned match scroll away, so the list still has room', (tester) async {
    final (:api, capture: _) = await share(tester, (api) {
      api
        ..addEntry(id: 'entry-other')
        ..addMatch(id: 'entry-match', supplierVatNumber: _vatNumber);
    }, qrText: _qrText(), screen: const Size(360, 640), textScale: 2);

    await act(tester, api, () => tester.drag(find.byType(NestedScrollView), const Offset(0, -600)));

    expect(tester.getRect(find.byKey(EntriesScreen.rowKey('entry-other'))).overlaps(tester.getRect(find.byType(NestedScrollView))), isTrue);
  });

  testWidgets('without a QR code nothing is pinned or chosen, the API is not asked for a match, and the attach button waits', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addEntry(id: 'entry-1'));

    expect(find.byKey(ShareScreen.attachKey), findsNothing);
    expect(api.sentReads, isNot(contains('/projects/project-0/entries/attachable')));
    expect(listed(), ['entry-1']);
  });

  testWidgets('AC-49.3: choosing an entry from the list shows what differs from the QR code', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addEntry(id: 'entry-1', status: 'approved', amount: 5000, supplierVatNumber: '300000000000099'), qrText: _qrText());

    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey('entry-1'))));

    expect(tester.widget<ListTile>(find.byKey(EntriesScreen.rowKey('entry-1'))).selected, isTrue);
    expect(find.byKey(ShareScreen.amountDiffersKey), findsOneWidget);
    expect(find.byKey(ShareScreen.supplierDiffersKey), findsOneWidget);
  });

  testWidgets('findings row 268: with the keyboard up and an entry chosen, scrolling back to the picture squeezes nothing, and the search stays over the list', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addEntry(id: 'entry-1', status: 'approved', amount: 5000, supplierVatNumber: '300000000000099'),
        qrText: _qrText(), screen: const Size(411, 914));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    final row = find.byKey(EntriesScreen.rowKey('entry-1'), skipOffstage: false);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(row));

    expect(tester.getRect(find.byKey(SearchLine.searchKey)).bottom, lessThanOrEqualTo(tester.getRect(row).top));
    await tester.drag(row, const Offset(0, 900));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(ShareScreen.pictureKey).hitTestable(), findsOneWidget);
  });

  testWidgets('R3, D3: what is typed in the search is asked of the API, with only the entries that take a file', (tester) async {
    final (:api, capture: _) = await share(tester, (api) {
      api
        ..addEntry(id: 'entry-1', itemName: 'بلاط الارضيات')
        ..addEntry(id: 'entry-2', itemName: 'رمل');
    });

    await searchFor(tester, api, 'بلاط');

    expect(api.entryQueries.last['text'], ['بلاط']);
    expect(api.entryQueries.last['attachable'], ['true']);
    expect(listed(), ['entry-1']);
  });

  testWidgets('AC-46.10a, D15: attaching to an approved entry keeps the file, puts it on the entry, names the entry in the bar, and lets go of the file', (tester) async {
    final (:api, capture: _) = await share(tester, (api) => api.addEntry(id: 'entry-1', status: 'approved', itemName: 'بلاط الارضيات'));

    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey('entry-1'))));
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.attachKey)));

    expect(api.sentAttachments, hasLength(1));
    expect(api.sentInvoices.single.$1, 'entry-1');
    expect(api.sentInvoices.single.$2.keys, ['attachmentId']);
    expect(tester.widget<Text>(find.byKey(messageKeyOf('share.attached').label)).data, 'en share.attached بلاط الارضيات');
    expect(find.byKey(ShareScreen.pictureKey), findsNothing);
  });

  testWidgets('BR-22, G1: a file already on another entry is refused, and the person stays', (tester) async {
    final (:api, capture: _) = await share(tester, (api) {
      api
        ..addEntry(id: 'entry-1')
        ..invoiceAnswer = (status: 409, code: 'invoiceAlreadyAttached');
    });

    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey('entry-1'))));
    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.attachKey)));

    expect(tester.widget<Text>(find.byKey(ShareScreen.messageKey)).data, 'en share.invoiceAlreadyAttached');
    expect(find.byKey(ShareScreen.pictureKey), findsOneWidget);
  });

  testWidgets('UC-046: a new expense opens with the shared file and its QR code, not the camera', (tester) async {
    final (:api, :capture) = await share(tester, (api) {}, qrText: _qrText());

    await act(tester, api, () => tester.tap(find.byKey(ShareScreen.newEntryKey)));

    expect(capture.cameraOpened, 0);
    expect(find.byKey(AddEntryScreen.invoicePictureKey), findsOneWidget);
    expect(find.byKey(AddEntryScreen.qrReadKey), findsOneWidget);
  });
}
