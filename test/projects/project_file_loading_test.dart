// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/project_file_refusals_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

/// UC-071, redix-api #132: the manager loads a project's file from تحميل ملف المشروع, where importing the settings was (D2). Every file here is made up for the test.
void main() {
  const project = 'project-0';
  final loadFile = HomeScreen.loadFileKey(project);
  final madeUpFile = PickedFile('مشروع الاختبار.json', '/phone/project.json', Uint8List.fromList(utf8.encode('{"format": "redix.project", "version": 1}')));

  /// The home of a project seen with [permissions], its file to load picked from the phone's files.
  Future<(FakeApi, FakeCapture)> onTheHome(WidgetTester tester, {List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions);
    final capture = FakeCapture()..files = madeUpFile;
    await openProject(tester, api, capture: capture);
    await showProjectSetting(tester, loadFile);
    await bringIntoView(tester, find.byKey(loadFile));
    return (api, capture);
  }

  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('AC-53.2, UC-073 D2, D10: without «ملفات المشروع» تحميل ملف المشروع is not there, whatever else one holds', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: [for (final permission in managerAndFinance) if (permission != 'manageProjectFiles') permission]);
    await openProject(tester, api);
    await showProjectSetting(tester, loadFile);
    expect(find.byKey(loadFile), findsNothing);
  });

  testWidgets('AC-53.2, UC-073 D2: «ملفات المشروع» opens تحميل ملف المشروع without «إدارة المشروع»', (tester) async {
    await onTheHome(tester, permissions: [for (final permission in managerAndFinance) if (permission != 'manageProject') permission]);
    expect(isEnabled(tester, loadFile), isTrue);
    expect(text(tester, loadFile.label), 'en projects.loadFile');
  });

  testWidgets('AC-53.3, D4, D15: once the API says the project holds an entry the button is gray', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    api.projects.single['holdsEntries'] = true;
    await openProject(tester, api);
    await showProjectSetting(tester, loadFile);

    expect(isEnabled(tester, loadFile), isFalse);
  });

  testWidgets('FR-53: the picked file is named in the question with the project, and going back sends nothing', (tester) async {
    final (api, _) = await onTheHome(tester);

    await act(tester, api, () => tester.tap(find.byKey(loadFile)));

    expect(text(tester, ConfirmDialog.titleKey), 'en projects.loadFileConfirm مشروع الاختبار.json غصون 6');
    expect(text(tester, ConfirmDialog.explanationKey), 'en projects.loadFileWhat');
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.cancelKey)));
    expect(api.sentProjectFiles, isEmpty);
  });

  testWidgets('FR-53, AC-53.1: once loaded the bar says what the API loaded, and the button turns gray', (tester) async {
    final (api, _) = await onTheHome(tester);

    await act(tester, api, () => tester.tap(find.byKey(loadFile)));
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(api.sentProjectFiles, [('/projects/$project/project-file', 'مشروع الاختبار.json')]);
    expect(text(tester, messageKeyOf('projects.loadFileDone').label), 'en projects.loadFileDone 8 6 7');
    await showProjectSetting(tester, loadFile);
    expect(isEnabled(tester, loadFile), isFalse);
  });

  testWidgets('AC-53.5, D14: every refused row opens a list of its own, by its item, table and row, each with its owner\'s word; nothing loaded, the button stays', (tester) async {
    final (api, _) = await onTheHome(tester);
    api.projectFileAnswer = (status: 400, body: {
      'code': 'rowsRefused',
      'rows': [
        {'category': 'التشطيب', 'item': 'بلاط', 'table': 'بلاط', 'row': 3, 'owner': 'file', 'code': 'accountNotInProject', 'columnKey': 'account', 'value': 'حساب غير موجود', 'column': 'الحساب'},
        {'category': 'التشطيب', 'item': 'بلاط', 'table': 'بلاط', 'row': 41, 'owner': 'entry', 'code': 'invalidAmount', 'columnKey': '', 'value': '', 'column': ''},
        {'category': 'رأس المال', 'item': 'رأس مال آخر', 'table': '', 'row': 0, 'owner': 'file', 'code': 'unknownChoice', 'columnKey': 'movementType', 'value': 'إضافة', 'column': 'نوع الحركة'},
      ],
    });

    await act(tester, api, () => tester.tap(find.byKey(loadFile)));
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(text(tester, ProjectFileRefusalsScreen.headingKey), 'en projects.loadFile.rowsRefused');
    expect([for (var index = 0; index < 3; index++) text(tester, ProjectFileRefusalsScreen.refusalKey(index).title)], ['بلاط · بلاط · #3', 'بلاط · بلاط · #41', 'رأس مال آخر']);
    expect([for (var index = 0; index < 3; index++) text(tester, ProjectFileRefusalsScreen.refusalKey(index).subtitle)], [
      'en projects.loadFile.accountNotInProject حساب غير موجود',
      'en expenses.invalidAmount',
      'en projects.loadFile.unknownChoice إضافة نوع الحركة',
    ]);
    await pressBack(tester, api);
    await showProjectSetting(tester, loadFile);
    expect(isEnabled(tester, loadFile), isTrue);
  });

  testWidgets('D9: a file that carries no report is loaded with a bar that names no report', (tester) async {
    final (api, _) = await onTheHome(tester);
    api.projectFileAnswer = (status: 200, body: {'entries': 0, 'tables': 0, 'report': 0});

    await act(tester, api, () => tester.tap(find.byKey(loadFile)));
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(text(tester, messageKeyOf('projects.loadFileDoneNoReport').label), 'en projects.loadFileDoneNoReport 0 0');
    expect(find.byKey(messageKeyOf('projects.loadFileDone')), findsNothing);
  });

  testWidgets('AC-29.3: a report the project issued already is listed with its number, and nothing is loaded', (tester) async {
    final (api, _) = await onTheHome(tester);
    api.projectFileAnswer = (status: 400, body: {
      'code': 'rowsRefused',
      'rows': [
        {'category': '', 'item': '', 'table': '', 'row': 0, 'owner': 'file', 'code': 'reportAlreadyIssued', 'columnKey': '', 'value': '7', 'column': ''},
      ],
    });

    await act(tester, api, () => tester.tap(find.byKey(loadFile)));
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(text(tester, ProjectFileRefusalsScreen.refusalKey(0).subtitle), 'en projects.loadFile.reportAlreadyIssued 7');
  });

  testWidgets('AC-53.9: a file that is not a project file says so in the bar, and opens no list', (tester) async {
    final (api, _) = await onTheHome(tester);
    api.projectFileAnswer = (status: 400, body: {'code': 'notAProjectFile'});

    await act(tester, api, () => tester.tap(find.byKey(loadFile)));
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(text(tester, messageKeyOf('projects.loadFile.notAProjectFile').label), 'en projects.loadFile.notAProjectFile');
    expect(find.byKey(ProjectFileRefusalsScreen.headingKey), findsNothing);
  });

  testWidgets('a person who picks nothing is asked nothing and sends nothing', (tester) async {
    final (api, capture) = await onTheHome(tester);
    capture.files = PickedFile.none();

    await act(tester, api, () => tester.tap(find.byKey(loadFile)));

    expect(find.byKey(ConfirmDialog.dialogKey), findsNothing);
    expect(api.sentProjectFiles, isEmpty);
  });
}
