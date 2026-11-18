// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

/// UC-073, redix-api #130: «أرشفة المشروع» hands the project's archive to the phone, and «استرجاع المشروع» puts one back over the project after saying what it changes.
/// Every archive here is made up for the test.
void main() {
  const project = 'project-0';
  final archive = HomeScreen.archiveKey(project);
  final retrieve = HomeScreen.retrieveKey(project);
  final madeUpArchive = PickedFile('غصون 6 - أرشيف.json', '/phone/archive.json', Uint8List.fromList(utf8.encode('{"format": "redix.archive"}')));
  final archivedAt = momentOf('2026-11-11T18:15:04Z');
  final when = '${formatDate(archivedAt)} ${formatTime(archivedAt)}';

  /// The home of a project in [status], seen with [permissions], [button] brought into view, the archive to retrieve picked from the phone's files.
  Future<FakeApi> onTheHome(WidgetTester tester, Key button, {List<String> permissions = managerAndFinance, String status = 'active'}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, status: status);
    await openProject(tester, api, capture: FakeCapture()..files = madeUpArchive);
    await showProjectSetting(tester, button);
    await bringIntoView(tester, find.byKey(button));
    return api;
  }

  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// The archive's name the button gives it at [at].
  String nameAt(DateTime at) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'en projects.archiveFileName غصون 6 ${at.year}-${two(at.month)}-${two(at.day)} ${two(at.hour)}.${two(at.minute)}';
  }

  testWidgets('AC-73.1: «أرشفة المشروع» asks whether to save or share, and takes the archive as JSON from its address, named for the project and the moment', (tester) async {
    final api = await onTheHome(tester, archive);
    final before = DateTime.now();

    await act(tester, api, () => tester.tap(find.byKey(archive)));
    final share = [nameAt(before), nameAt(DateTime.now())].map((name) => find.byKey(ReportFileButtons.handingKey(name, ReportFileKind.archive, FileHandling.share))).firstWhere((found) => found.evaluate().isNotEmpty);
    expect(text(tester, archive.label), 'en projects.archive');
    await act(tester, api, () => tester.tap(share));

    expect(api.sentFileReads.last, '/projects/$project/archive/json');
  });

  testWidgets('AC-73.2, D8: the picked archive is previewed, and the question names the project and the archive\'s moment, who took it, each count now and after, and what stays; going back retrieves nothing', (tester) async {
    final api = await onTheHome(tester, retrieve);

    await act(tester, api, () => tester.tap(find.byKey(retrieve)));

    expect(api.sentArchives, [('/projects/$project/retrieve?preview=true', 'غصون 6 - أرشيف.json')]);
    expect(text(tester, ConfirmDialog.titleKey), 'en projects.retrieveConfirm غصون 6 $when');
    expect(text(tester, ConfirmDialog.explanationKey), [
      'en projects.retrieveTakenBy متعب',
      'en projects.retrieve.part.entries: en projects.retrieveNow 1056 · en projects.retrieveAfter 1000',
      'en projects.retrieve.part.contracts: en projects.retrieveNow 37 · en projects.retrieveAfter 35',
      'en projects.retrieve.part.accounts: en projects.retrieveNow 4 · en projects.retrieveAfter 4',
      'en projects.retrieve.part.suppliers: en projects.retrieveNow 35 · en projects.retrieveAfter 33',
      'en projects.retrieve.part.partners: en projects.retrieveNow 7 · en projects.retrieveAfter 7',
      'en projects.retrieve.part.items: en projects.retrieveNow 34 · en projects.retrieveAfter 34',
      'en projects.retrieve.part.attachments: en projects.retrieveNow 6 · en projects.retrieveAfter 4',
      'en projects.retrieveWhat',
    ].join('\n'));
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.cancelKey)));
    expect(api.sentArchives, hasLength(1));
  });

  testWidgets('AC-73.3: once confirmed the archive is retrieved, and the bar says when it was taken and how many entries the project holds, from the API\'s answer', (tester) async {
    final api = await onTheHome(tester, retrieve);

    await act(tester, api, () => tester.tap(find.byKey(retrieve)));
    api.retrieveAnswer = (status: 200, body: {'archivedAt': '2026-11-11T18:15:04Z', 'after': {'entries': 998}});
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(api.sentArchives.last, ('/projects/$project/retrieve', 'غصون 6 - أرشيف.json'));
    expect(text(tester, messageKeyOf('projects.retrieveDone').label), 'en projects.retrieveDone $when 998');
  });

  testWidgets('R12: another project\'s archive is refused in the bar, naming that project, and nothing is asked', (tester) async {
    final api = await onTheHome(tester, retrieve);
    api.retrieveAnswer = (status: 409, body: {'code': 'archiveOfAnotherProject', 'project': 'غصزن 7'});

    await act(tester, api, () => tester.tap(find.byKey(retrieve)));

    expect(text(tester, messageKeyOf('projects.retrieve.archiveOfAnotherProject').label), 'en projects.retrieve.archiveOfAnotherProject غصزن 7');
    expect(find.byKey(ConfirmDialog.dialogKey), findsNothing);
  });

  testWidgets('AC-73.5: a file that is no archive says so in the bar, and nothing is asked', (tester) async {
    final api = await onTheHome(tester, retrieve);
    api.retrieveAnswer = (status: 400, body: {'code': 'notAnArchive'});

    await act(tester, api, () => tester.tap(find.byKey(retrieve)));

    expect(text(tester, messageKeyOf('projects.retrieve.notAnArchive').label), 'en projects.retrieve.notAnArchive');
    expect(find.byKey(ConfirmDialog.dialogKey), findsNothing);
  });

  testWidgets('a person who picks nothing is asked nothing and sends nothing', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api, capture: FakeCapture());
    await showProjectSetting(tester, retrieve);
    await bringIntoView(tester, find.byKey(retrieve));

    await act(tester, api, () => tester.tap(find.byKey(retrieve)));

    expect(api.sentArchives, isEmpty);
    expect(find.byKey(ConfirmDialog.dialogKey), findsNothing);
  });

  testWidgets('R17: in a finished project «أرشفة المشروع» works and «استرجاع المشروع» is gray', (tester) async {
    await onTheHome(tester, retrieve, status: 'finished');

    expect(isEnabled(tester, retrieve), isFalse);
    expect(isEnabled(tester, archive), isTrue);
  });

  testWidgets('D10: without «ملفات المشروع» neither «أرشفة المشروع» nor «استرجاع المشروع» is there', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: [for (final permission in managerAndFinance) if (permission != 'manageProjectFiles') permission]);
    await openProject(tester, api);

    for (final key in [archive, retrieve]) {
      await showProjectSetting(tester, key);
      expect(find.byKey(key), findsNothing, reason: '$key');
    }
  });
}
