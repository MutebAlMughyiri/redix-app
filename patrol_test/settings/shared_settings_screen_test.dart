// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('The Settings screen (UC-009 and UC-010)', () {
    phoneCase('everyone has Switch project and Default project', ($) async {
      final admin = await Given.admin();
      await $.startApp();
      await $.signIn(admin.username, admin.password);
      await $.reach($(ProjectsScreen.sharedSettingsKey));
      await $(ProjectsScreen.sharedSettingsKey).tap();
      await $.reach($(SharedSettingsScreen.switchProjectKey));
      expect($(SharedSettingsScreen.defaultProjectKey), findsOneWidget);
      await $.reach($(SharedSettingsScreen.registeredKey));
      await $.picture('settings');
    });

    phoneCase('Switch project reaches the list', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $(HomeScreen.sharedSettingsKey(manager.projectId)).tap();
      await $.tapOn(SharedSettingsScreen.switchProjectKey);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
    });

    phoneCase('Settings shows who is signed in', ($) async {
      final manager = await Given.manager(manager: 'ريم');
      await $.onTheList(manager);
      await $(ProjectsScreen.sharedSettingsKey).tap();
      await $.says(SharedSettingsScreen.whoKey.title, 'ريم');
      await $.says(SharedSettingsScreen.whoKey.subtitle, manager.username);
      await $.picture('my-account');
    });

    phoneCase('redix-api #127 AC-10.4: «بريدي» sends a code to a new address, names it, and a wrong code leaves the email as it was', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      final email = '${member.username}@example.com';
      final changed = 'changed-${Given.unique()}@example.com';
      await $.onTheList(member);
      await $(ProjectsScreen.sharedSettingsKey).tap();
      await $.goTo($(SharedSettingsScreen.myEmailKey));
      await $.says(SharedSettingsScreen.myEmailKey.subtitle, email);
      await $.tapOn(SharedSettingsScreen.myEmailKey);
      await $.fill(SharedSettingsScreen.myEmailFieldKey, changed);
      await $(ChangeDialog.saveKey).tap();
      await $.saysContaining(SharedSettingsScreen.myEmailSentToKey, changed);
      await $.picture('my-email');
      await $.fill(SharedSettingsScreen.myEmailCodeKey, '000000');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.authCodeWrong);
      await $(ChangeDialog.cancelKey).tap();
      await $.says(SharedSettingsScreen.myEmailKey.subtitle, email);
    });

    phoneCase('redix-api #127 R9: «بريدي» refuses an address another account holds, and asks no code', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      final other = await Given.member(manager);
      await $.onTheList(member);
      await $(ProjectsScreen.sharedSettingsKey).tap();
      await $.tapOn(SharedSettingsScreen.myEmailKey);
      await $.fill(SharedSettingsScreen.myEmailFieldKey, '${other.username}@example.com');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.usersEmailTaken);
      expect($(SharedSettingsScreen.myEmailCodeKey), findsNothing);
    });

    phoneCase('Settings holds no project screen', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $(HomeScreen.sharedSettingsKey(manager.projectId)).tap();
      await $.reach($(SharedSettingsScreen.whoKey));
      for (final key in [HomeScreen.projectInfoKey(manager.projectId), HomeScreen.usersKey(manager.projectId), HomeScreen.categoriesKey(manager.projectId), HomeScreen.paymentMethodsKey(manager.projectId)]) {
        expect($(key), findsNothing);
      }
    });
  });
}
