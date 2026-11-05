import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/attachment_screen.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/blueprints_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';

import '../app_harness.dart';

void main() {
  Map<String, Object> blueprint(String id, String title, String unitName) => {
    'id': id,
    'title': title,
    'unitId': '',
    'unitName': unitName,
    'attachmentId': 'attachment-$id',
    'fileName': '$id.png',
    'contentType': 'image/png',
    'sizeBytes': 4,
    'uploadedAt': '2026-11-05T20:00:00Z',
  };

  Future<({FakeApi api, FakeCapture capture})> openBlueprints(WidgetTester tester, {List<String> permissions = managerAndFinance, void Function(FakeApi api)? arrange}) async {
    final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية'], permissions: permissions);
    arrange?.call(api);
    final capture = FakeCapture();
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.blueprintsKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.blueprintsKey('project-0'))));
    return (api: api, capture: capture);
  }

  testWidgets('UC-064: everyone opens the blueprints, the whole project\'s first, each under its place', (tester) async {
    final (:api, capture: _) = await openBlueprints(tester, permissions: field, arrange: (api) {
      api.blueprintRows.addAll([blueprint('site', 'مخطط الموقع العام', ''), blueprint('villa', 'المخطط المعماري', 'الفلة الغربية')]);
    });

    expect(find.text('en blueprints.project'), findsOneWidget);
    expect(find.text('الفلة الغربية'), findsOneWidget);
    expect(find.byKey(BlueprintsScreen.addKey), findsNothing);
    expect(find.byKey(BlueprintsScreen.removeKey('site')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(BlueprintsScreen.blueprintKey('villa'))));

    expect(find.byType(AttachmentScreen), findsOneWidget);
  });

  testWidgets('UC-064: the manager keeps a unit\'s blueprint from a file on the phone', (tester) async {
    final (:api, :capture) = await openBlueprints(tester);
    capture.files = PickedFile('plan.png', '/phone/plan.png', Uint8List.fromList(onePixelPng));

    await act(tester, api, () => tester.tap(find.byKey(BlueprintsScreen.addKey)));
    await tester.enterText(find.byKey(BlueprintsScreen.titleKey), 'المخطط المعماري');
    await act(tester, api, () => tester.tap(find.byKey(BlueprintsScreen.unitKey('project-0-unit-0'))));
    await act(tester, api, () => tester.tap(find.byKey(BlueprintsScreen.fileKey)));
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    final (path, body) = api.sentBlueprints.single;
    expect(path, '/projects/project-0/blueprints');
    expect(body, {'attachmentId': startsWith('attachment-'), 'title': 'المخطط المعماري', 'unitId': 'project-0-unit-0'});
    expect(api.sentAttachments.single, contains('plan.png'));
    expect(find.text('المخطط المعماري'), findsOneWidget);
  });

  testWidgets('a blueprint with no file is not kept, and says so', (tester) async {
    final (:api, capture: _) = await openBlueprints(tester);

    await act(tester, api, () => tester.tap(find.byKey(BlueprintsScreen.addKey)));
    await tester.enterText(find.byKey(BlueprintsScreen.titleKey), 'مخطط');
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(tester.widget<Text>(find.byKey(ChangeDialog.messageKey)).data, 'en blueprints.unknownAttachment');
    expect(api.sentBlueprints, isEmpty);
  });

  testWidgets('removing asks first, and the blueprint leaves the list', (tester) async {
    final (:api, capture: _) = await openBlueprints(tester, arrange: (api) => api.blueprintRows.add(blueprint('site', 'مخطط الموقع العام', '')));

    await act(tester, api, () => tester.tap(find.byKey(BlueprintsScreen.removeKey('site'))));
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(api.sentBlueprints.single.$1, '/projects/project-0/blueprints/site/delete');
    expect(find.byKey(BlueprintsScreen.blueprintKey('site')), findsNothing);
  });
}
