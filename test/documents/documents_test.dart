import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/attachment_screen.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/documents/documents_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

void main() {
  Map<String, Object> document(String id, String name, String group, {String fileName = 'plan.png', String contentType = 'image/png'}) => {
    'id': id,
    'name': name,
    'group': group,
    'attachmentId': 'attachment-$id',
    'fileName': fileName,
    'contentType': contentType,
    'sizeBytes': 4,
    'uploadedAt': '2026-11-07T20:00:00Z',
  };

  Future<({FakeApi api, FakeCapture capture})> openDocuments(WidgetTester tester, {List<String> permissions = managerAndFinance, void Function(FakeApi api)? arrange}) async {
    final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية'], permissions: permissions);
    arrange?.call(api);
    final capture = FakeCapture();
    await openProject(tester, api, capture: capture);
    await tester.ensureVisible(find.byKey(HomeScreen.documentsKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.documentsKey('project-0'))));
    return (api: api, capture: capture);
  }

  Future<void> openDialog(WidgetTester tester, FakeApi api, String name) async {
    await act(tester, api, () => tester.tap(find.byKey(DocumentsScreen.addKey)));
    await tester.enterText(find.byKey(DocumentsScreen.nameKey), name);
  }

  testWidgets('UC-064: everyone opens the documents, those in no group first with no heading, then each group under its name', (tester) async {
    final (:api, capture: _) = await openDocuments(tester, permissions: field, arrange: (api) {
      api.documentRows.addAll([document('contract', 'عقد المقاول الرئيسي', ''), document('permit', 'رخصة البناء', 'التراخيص'), document('villa', 'المخطط المعماري', 'مخططات')]);
    });

    expect(find.byKey(DocumentsScreen.groupHeadingKey('التراخيص')), findsOneWidget);
    expect(find.byKey(DocumentsScreen.groupHeadingKey('مخططات')), findsOneWidget);
    expect(find.byKey(DocumentsScreen.groupHeadingKey('')), findsNothing);
    expect(tester.getTopLeft(find.byKey(DocumentsScreen.documentKey('contract'))).dy, lessThan(tester.getTopLeft(find.byKey(DocumentsScreen.groupHeadingKey('التراخيص'))).dy));
    expect(isEnabled(tester, DocumentsScreen.addKey), isFalse);
    expect(find.byKey(DocumentsScreen.documentKey('permit').swipe), findsNothing);
    expect(find.byKey(DocumentsScreen.swipeHintKey), findsNothing);
    expect(find.byKey(DocumentsScreen.downloadKey('permit')), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(DocumentsScreen.documentKey('villa'))));

    expect(find.byKey(AttachmentScreen.pictureKey), findsOneWidget);
  });

  testWidgets('UC-064: a file that is neither a picture nor a PDF is handed to the phone by its own name', (tester) async {
    final (:api, :capture) = await openDocuments(tester, arrange: (api) {
      api.documentRows.add(document('quantities', 'جدول الكميات', '', fileName: 'quantities.xlsx', contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'));
    });

    await act(tester, api, () => tester.tap(find.byKey(DocumentsScreen.documentKey('quantities'))));
    await act(tester, api, () => tester.tap(find.byKey(AttachmentScreen.openFileKey)));

    expect(capture.sharedOut.single, ('quantities.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'));
  });

  testWidgets('UC-064: a PDF is handed to the phone by its own name too, never as invoice.pdf', (tester) async {
    final (:api, :capture) = await openDocuments(tester, arrange: (api) {
      api.documentRows.add(document('permit', 'رخصة البناء', '', fileName: 'permit.pdf', contentType: 'application/pdf'));
    });

    await act(tester, api, () => tester.tap(find.byKey(DocumentsScreen.documentKey('permit'))));
    await act(tester, api, () => tester.tap(find.byKey(AttachmentScreen.openFileKey)));

    expect(capture.sharedOut.single, ('permit.pdf', 'application/pdf'));
  });

  testWidgets('UC-064: the manager keeps any file under a name and a group, sent together', (tester) async {
    final (:api, :capture) = await openDocuments(tester);
    capture.files = PickedFile('permit.docx', '/phone/permit.docx', Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]));

    await openDialog(tester, api, 'رخصة البناء');
    await tester.enterText(find.byKey(DocumentsScreen.groupKey), 'التراخيص');
    await act(tester, api, () => tester.tap(find.byKey(DocumentsScreen.fileKey)));
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    final (path, fields) = api.sentDocuments.single;
    expect(path, '/projects/project-0/documents');
    expect(fields, {'name': 'رخصة البناء', 'group': 'التراخيص', 'file': 'permit.docx'});
    expect(find.byKey(DocumentsScreen.groupHeadingKey('التراخيص')), findsOneWidget);
  });

  testWidgets('UC-064: a document with no group is sent with an empty one', (tester) async {
    final (:api, :capture) = await openDocuments(tester);
    capture.files = PickedFile('contract.pdf', '/phone/contract.pdf', Uint8List.fromList([0x25, 0x50, 0x44, 0x46]));

    await openDialog(tester, api, 'عقد المقاول الرئيسي');
    await act(tester, api, () => tester.tap(find.byKey(DocumentsScreen.fileKey)));
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(api.sentDocuments.single.$2, {'name': 'عقد المقاول الرئيسي', 'group': '', 'file': 'contract.pdf'});
  });

  testWidgets('typing a group offers the project\'s own, and picking one fills it', (tester) async {
    final (:api, :capture) = await openDocuments(tester, arrange: (api) => api.documentRows.add(document('permit', 'رخصة البناء', 'التراخيص')));
    capture.files = PickedFile('plan.pdf', '/phone/plan.pdf', Uint8List.fromList([0x25, 0x50, 0x44, 0x46]));

    await openDialog(tester, api, 'رخصة الهدم');
    await tester.enterText(find.byKey(DocumentsScreen.groupKey), 'التر');
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.text('التراخيص').last));
    await act(tester, api, () => tester.tap(find.byKey(DocumentsScreen.fileKey)));
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(api.sentDocuments.single.$2['group'], 'التراخيص');
  });

  testWidgets('a document with no file is not kept, and says so', (tester) async {
    final (:api, capture: _) = await openDocuments(tester);

    await openDialog(tester, api, 'مستند');
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(tester.widget<Text>(find.byKey(ChangeDialog.messageKey)).data, 'en documents.fileRequired');
    expect(api.sentDocuments, isEmpty);
  });

  testWidgets('redix-api #102 R1, R4: a swipe removes a document with no question, and the list says how', (tester) async {
    final (:api, capture: _) = await openDocuments(tester, arrange: (api) => api.documentRows.add(document('permit', 'رخصة البناء', 'التراخيص')));
    expect(tester.widget<Text>(find.byKey(DocumentsScreen.swipeHintKey.label)).data, 'en swipe.hint');

    await swipeToRemove(tester, api, DocumentsScreen.documentKey('permit'));

    expect(find.byType(AlertDialog), findsNothing);
    expect(api.sentDocuments.single.$1, '/projects/project-0/documents/permit/delete');
    expect(find.byKey(DocumentsScreen.documentKey('permit')), findsNothing);
  });

  testWidgets('redix-api #102 R5: a swipe shorter than 40% springs back and removes nothing', (tester) async {
    final (:api, capture: _) = await openDocuments(tester, arrange: (api) => api.documentRows.add(document('permit', 'رخصة البناء', 'التراخيص')));

    await swipeToRemove(tester, api, DocumentsScreen.documentKey('permit'), share: 0.2);

    expect(api.sentDocuments, isEmpty);
    expect(find.byKey(DocumentsScreen.documentKey('permit')), findsOneWidget);
  });

  testWidgets('redix-api #102 R2: Download keeps the document\'s file in the phone\'s Downloads under its own name', (tester) async {
    final (:api, :capture) = await openDocuments(tester, permissions: field, arrange: (api) => api.documentRows.add(document('permit', 'رخصة البناء', 'التراخيص', fileName: 'permit.pdf', contentType: 'application/pdf')));

    await act(tester, api, () => tester.tap(find.byKey(DocumentsScreen.downloadKey('permit'))));

    expect(capture.savedOut.single, ('permit.pdf', 'application/pdf'));
    expect(find.text('en reports.downloaded'), findsOneWidget);
  });

  testWidgets('AC-04.1: a closed project shows its documents with no Add and no Remove', (tester) async {
    final api = FakeApi()..addProject('غصون 5', status: 'finished', units: ['الفلة الغربية']);
    api.documentRows.add(document('permit', 'رخصة البناء', 'التراخيص'));
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.documentsKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.documentsKey('project-0'))));

    expect(find.byKey(DocumentsScreen.documentKey('permit')), findsOneWidget);
    expect(isEnabled(tester, DocumentsScreen.addKey), isFalse);
    expect(find.byKey(DocumentsScreen.documentKey('permit').swipe), findsNothing);
  });
}
