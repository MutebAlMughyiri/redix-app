// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/users/users_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('The role name (the owner, 9 Nov 2026)', () {
    phoneCase('a role name typed in Users is kept per person per project, and shows on the home and in Settings', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      await $.reach($(UsersScreen.nameKey(member.id)));
      await $.menuChoice(UsersScreen.menuKey(member.id), UsersScreen.editKey);
      await $.fill(UsersScreen.editRoleNameKey, 'مهندس موقع');
      await $(ChangeDialog.saveKey).tap();
      await $.gone($(UsersScreen.editRoleNameKey));
      await $.back();
      await $.switchPersonTo(member, projectId: manager.projectId);
      await $.says(HomeScreen.roleNameKey, 'مهندس موقع');
      await $(HomeScreen.sharedSettingsKey(member.projectId)).tap();
      await $.says(SharedSettingsScreen.whoKey.subtitle, '${member.username} · مهندس موقع');
    });

    phoneCase('another project keeps its own role name', ($) async {
      final first = await Given.manager();
      final second = await Given.manager();
      final member = await Given.member(first, roleName: 'مهندس موقع');
      await Given.joined(member, by: second);
      await Given.roleName(member, 'محاسب', by: second);
      await $.onTheHome(member);
      await $.says(HomeScreen.roleNameKey, 'مهندس موقع');
      await $.back();
      await $.openProject(second.projectId);
      await $.says(HomeScreen.roleNameKey, 'محاسب');
    });

    phoneCase('changing only the role name leaves the name and mobile as they were', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, name: 'B', mobile: '0533333333');
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      await $.reach($(UsersScreen.nameKey(member.id)));
      await $.menuChoice(UsersScreen.menuKey(member.id), UsersScreen.editKey);
      await $.fill(UsersScreen.editRoleNameKey, 'مشرف');
      await $(ChangeDialog.saveKey).tap();
      await $.gone($(UsersScreen.editRoleNameKey));
      await $.says(UsersScreen.nameKey(member.id), 'B');
      await $.says(UsersScreen.detailsKey(member.id), '${member.username} · مشرف · 0533333333');
    });

    phoneCase('an empty role name shows nothing', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await $.onTheHome(member);
      expect($(HomeScreen.roleNameKey), findsNothing);
      await $(HomeScreen.sharedSettingsKey(member.projectId)).tap();
      await $.says(SharedSettingsScreen.whoKey.subtitle, member.username);
      expect($(ProjectsScreen.titleKey), findsNothing);
    });
  });
}
