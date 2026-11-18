// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/project_file_refusals_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/steps.dart';

/// The name of the made-up project file in the phone's Downloads.
const _fileName = 'project-file-test.json';

/// A made-up project file (redix-api #130's shape, with D11): one new category with one new item, whose table holds a purchase paid from [account] on today's date, what
/// [account] really held, and report 3. Nothing in it is real.
List<int> _projectFile(String account, {String rowAccount = ''}) {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  return utf8.encode(jsonEncode({
    'format': 'redix.project',
    'version': 1,
    'project': 'مشروع الاختبار',
    'report': {'number': 3, 'date': today, 'time': '00:00'},
    'accounts': [
      {'name': account, 'actualBalance': -125},
    ],
    'lists': [
      {
        'key': 'account',
        'name': 'الحساب',
        'options': [
          {'id': 'account-1', 'label': account, 'sign': ''},
          {'id': 'account-2', 'label': 'حساب غير موجود', 'sign': ''},
        ],
      },
      {
        'key': 'paymentMethod',
        'name': 'طريقة الدفع',
        'options': [
          {'id': 'paymentMethod-1', 'label': 'شبكة', 'sign': ''},
        ],
      },
    ],
    'categories': [
      {
        'name': 'فئة الاختبار',
        'items': [
          {
            'name': 'بند الاختبار',
            'type': 'purchases',
            'tables': [
              {
                'name': 'بند الاختبار',
                'kind': 'purchases',
                'columns': [
                  {'key': 'description', 'name': 'الوصف', 'type': 'text'},
                  {'key': 'date', 'name': 'التاريخ', 'type': 'date'},
                  {'key': 'account', 'name': 'الحساب', 'type': 'list', 'list': 'account'},
                  {'key': 'paymentMethod', 'name': 'طريقة الدفع', 'type': 'list', 'list': 'paymentMethod'},
                  {'key': 'total', 'name': 'التكلفة', 'type': 'amount'},
                ],
                'rows': [
                  {'description': 'صنف', 'date': today, 'account': rowAccount.isEmpty ? 'account-1' : rowAccount, 'paymentMethod': 'paymentMethod-1', 'total': 125},
                ],
              },
            ],
          },
        ],
      },
    ],
  }));
}

/// Picks [bytes] as the project file of [manager]'s project from تحميل ملف المشروع, and says yes to loading it.
Future<void> loadFromTheHome(PatrolIntegrationTester $, Person manager, List<int> bytes) async {
  await $.onTheHome(manager);
  await $.goTo($(HomeScreen.loadFileKey(manager.projectId)));
  await $.pickFromThePhone(HomeScreen.loadFileKey(manager.projectId), _fileName, bytes);
  await $(ConfirmDialog.titleKey).waitUntilVisible();
  await $.picture('project-file-confirm');
  await $.tapOn(ConfirmDialog.confirmKey);
}

void main() {
  phoneClass('Load a project file (UC-071, redix-api #132)', () {
    phoneCase('AC-53.1: the manager loads the file, the bar says one entry in one table and report 3, and the button turns gray', ($) async {
      final manager = await Given.manager();
      final account = 'حساب ${manager.projectName}';
      await Given.account(manager, name: account);

      await loadFromTheHome($, manager, _projectFile(account));

      await $.messageShows('projects.loadFileDone');
      await $.picture('project-file-loaded');
      await $.goTo($(HomeScreen.loadFileKey(manager.projectId)));
      expect($.isEnabled(HomeScreen.loadFileKey(manager.projectId)), isFalse);
    });

    phoneCase('AC-53.5: a row naming an account the project lacks opens the refused list, and nothing is saved', ($) async {
      final manager = await Given.manager();
      final account = 'حساب ${manager.projectName}';
      await Given.account(manager, name: account);

      await loadFromTheHome($, manager, _projectFile(account, rowAccount: 'account-2'));

      await $(ProjectFileRefusalsScreen.headingKey).waitUntilVisible();
      await $.says(ProjectFileRefusalsScreen.refusalKey(0).title, 'بند الاختبار · بند الاختبار · #1');
      await $.saysContaining(ProjectFileRefusalsScreen.refusalKey(0).subtitle, 'حساب غير موجود');
      await $.picture('project-file-refused');
      await $.back();
      await $.goTo($(HomeScreen.loadFileKey(manager.projectId)));
      expect($.isEnabled(HomeScreen.loadFileKey(manager.projectId)), isTrue);
    });

    phoneCase('AC-53.9: any other JSON file is not a project file, and the bar says so', ($) async {
      final manager = await Given.manager();

      await loadFromTheHome($, manager, utf8.encode('{"name": "not a project"}'));

      await $.messageShows('projects.loadFile.notAProjectFile');
      expect($(messageKeyOf('projects.loadFileDone')), findsNothing);
    });

    phoneCase('AC-53.2, UC-073 D2: someone without «ملفات المشروع» has no تحميل ملف المشروع', ($) async {
      final member = await Given.member(await Given.manager());
      await $.onTheHome(member);
      await $.goTo($(HomeScreen.myPermissionsKey(member.projectId)));
      expect(await $.anyProjectSettingPage(HomeScreen.loadFileKey(member.projectId)), isFalse);
    });
  });
}
