// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/users/user_permissions_screen.dart';
import 'package:redix/users/users_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// [manager] standing on the permissions of the person [id].
Future<void> onPermissions(PatrolIntegrationTester $, Person manager, String id) async {
  await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
  await $.reach($(UsersScreen.nameKey(id)));
  await $.menuChoice(UsersScreen.menuKey(id), UsersScreen.permissionsKey);
  await $.reach($(UserPermissionsScreen.nameKey));
}

/// Taps the tick of [permission] and waits until it reads [ticked].
Future<void> tick(PatrolIntegrationTester $, Permission permission, {required bool ticked}) async {
  final key = UserPermissionsScreen.permissionKey(permission);
  await $.tapOn(key);
  await $.until(() => $.isTicked(key) == ticked);
  expect($.isTicked(key), ticked);
}

void main() {
  phoneClass('Tick a person\'s permissions (UC-008)', () {
    phoneCase('the screen names whose permissions these are, and ticks every one they hold', ($) async {
      final manager = await Given.manager(project: 'غصون 7', manager: 'ريم');
      final member = await Given.member(manager, name: 'نواف', permissions: [Permission.recordEntries]);
      await onPermissions($, manager, member.id);
      await $.says(UserPermissionsScreen.nameKey, 'نواف');
      await $.goTo($(UserPermissionsScreen.permissionKey(Permission.recordEntries)));
      expect($.isTicked(UserPermissionsScreen.permissionKey(Permission.recordEntries)), isTrue);
      await $.goTo($(UserPermissionsScreen.permissionKey(Permission.approveEntries)));
      expect($.isTicked(UserPermissionsScreen.permissionKey(Permission.approveEntries)), isFalse);
      await $.picture('user-permissions');
    });

    phoneCase('a tick gives the permission at once, and their home follows', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await onPermissions($, manager, member.id);
      await tick($, Permission.approveEntries, ticked: true);
      await $.back();
      await $.back();
      await $.switchPersonTo(member, projectId: manager.projectId);
      await $.goTo($(HomeScreen.approvalsKey(member.projectId)));
    });

    phoneCase('unticking takes it away, and their home follows', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.approveEntries]);
      await onPermissions($, manager, member.id);
      await tick($, Permission.approveEntries, ticked: false);
      await $.back();
      await $.back();
      await $.switchPersonTo(member, projectId: manager.projectId);
      await $.goTo($(HomeScreen.documentsKey(member.projectId)));
      expect(await $.anyProjectSettingPage(HomeScreen.approvalsKey(member.projectId)), isFalse);
    });

    phoneCase('unticking See the project takes them off the list', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await onPermissions($, manager, member.id);
      await $.tapOn(UserPermissionsScreen.permissionKey(Permission.readProject));
      await $.pumpAndSettle();
      await $.back();
      await $.gone($(UsersScreen.nameKey(member.id)));
    });

    phoneCase('a refusal shows its word, and nothing changes', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      final id = await $.idOf('users.name.', () async => manager.id);
      await $.menuChoice(UsersScreen.menuKey(id), UsersScreen.permissionsKey);
      final key = UserPermissionsScreen.permissionKey(Permission.manageUsers);
      await $.tapOn(key);
      await $.messageSays('users.lastManager', $.words.usersLastManager);
      expect($.isTicked(key), isTrue);
    });
  });
}
