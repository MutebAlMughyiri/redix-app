// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/history/my_history_screen.dart';
import 'package:redix/history/project_history_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/search_scope.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/search_steps.dart';
import '../support/steps.dart';

/// UC-069, redix-api #86: «سجل المشروع» and «سجلي» on the phone, against the API.
void main() {
  phoneClass('UC-069: «سجل المشروع» and «سجلي» (redix-api #86)', () {
    phoneCase('R1, R2: «سجل المشروع» opens from Project settings and says each action once, by whom', ($) async {
      final manager = await Given.manager();
      final name = 'حساب ${Given.unique()}';
      await Given.account(manager, name: name);
      final line = (await Given.history(manager, 'history')).firstWhere((line) => line['thing'] == 'account' && line['name'] == name)['id'] as int;
      await $.fromTheHome(manager, HomeScreen.projectHistoryKey(manager.projectId));
      await $.reach($(SearchIcons.searchKey));
      await $.says(ProjectHistoryScreen.lineKey(line).title, '${$.words.historyActionCreated} ${$.words.historyThingAccount} $name');
    });

    phoneCase('R3, R13: someone holding the permission without ManageUsers sees no permission line, and the person chip keeps one member\'s lines', ($) async {
      final manager = await Given.manager();
      final reader = await Given.member(manager, permissions: [Permission.seeProjectHistory]);
      final name = 'حساب ${Given.unique()}';
      await Given.account(manager, name: name);
      final lines = await Given.history(reader, 'history');
      expect(lines.where((line) => line['thing'] == 'permission'), isEmpty);
      final account = lines.firstWhere((line) => line['thing'] == 'account' && line['name'] == name)['id'] as int;
      await $.fromTheHome(reader, HomeScreen.projectHistoryKey(reader.projectId));
      await $.reach($(ProjectHistoryScreen.lineKey(account)));
      await $.chooseIn(ProjectHistoryScreen.personChoiceKey, ProjectHistoryScreen.personKey(reader.id));
      await $.gone($(ProjectHistoryScreen.lineKey(account)));
    });

    phoneCase('R9: «سجلي» opens from Shared settings and shows one\'s own sign-in', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.readProject]);
      await $.onTheHome(member);
      final signIn = (await Given.myHistory(member)).firstWhere((line) => line['kind'] == 'signIn')['id'] as int;
      await $.tapOn(HomeScreen.sharedSettingsKey(member.projectId));
      await $.tapOn(SharedSettingsScreen.myHistoryKey);
      await $.says(MyHistoryScreen.lineKey(signIn).title, $.words.historyLoginSignIn);
    });
  });
}
