// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/screen_title.dart';
import 'package:redix/users/permission_ticks.dart';
import 'package:redix/users/user_permissions_screen.dart';
import 'package:redix/users/users_screen.dart';
import 'package:redix/home/home_screen.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openScreen(WidgetTester tester) async {
    final api = FakeApi()..addProject('مشروع A');
    api
      ..addPartner('project-0', 'خالد')
      ..addPartner('project-0', 'سعد');
    final manager = api.addUser('A', username: 'owner');
    final user = api.addUser('B', username: 'b');
    api
      ..give(manager, 'project-0', managerAndFinance)
      ..give(user, 'project-0', reader);
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.usersKey('project-0'));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.permissionsKey)));
    return api;
  }

  Finder tick(Permission permission) => find.byKey(UserPermissionsScreen.permissionKey(permission).body);

  bool isTicked(WidgetTester tester, Permission permission) => tester.widget<CheckboxListTile>(tick(permission)).value!;

  Future<void> toggle(WidgetTester tester, FakeApi api, Permission permission) async {
    await tester.ensureVisible(tick(permission));
    await act(tester, api, () => tester.tap(tick(permission)));
  }

  testWidgets('going back while a permission is being saved, the home reads only after it is saved, so it never shows the old one', (tester) async {
    final api = await openScreen(tester);
    final saved = Completer<void>();
    api.holdWrites = saved.future;

    await toggle(tester, api, Permission.approveEntries);
    api.sentReads.clear();
    await act(tester, api, () => tester.pageBack());
    await actWhileWaiting(tester, api, () => tester.pageBack());
    expect(api.sentReads, isNot(contains('/projects')));

    saved.complete();
    await act(tester, api, () async {});

    expect(api.sentReads, contains('/projects'));
  });

  testWidgets('the screen says whose permissions these are, and ticks every one a project can give, with what they hold ticked', (tester) async {
    await openScreen(tester);

    expect(tester.widget<Text>(find.byKey(UserPermissionsScreen.nameKey)).data, 'B');
    expect(tester.widget<Text>(find.byKey(ScreenTitle.titleKey)).data, 'en permissions.title');
    expect(tester.widget<Text>(find.byKey(ScreenTitle.subjectKey)).data, 'مشروع A');
    for (final permission in Permission.inAProject) {
      expect(find.byKey(UserPermissionsScreen.permissionKey(permission)), findsOneWidget);
    }
    expect(find.byKey(UserPermissionsScreen.permissionKey(Permission.approveProjects)), findsNothing);
    expect(isTicked(tester, Permission.readProject), isTrue);
    expect(isTicked(tester, Permission.approveEntries), isFalse);
  });

  testWidgets('a tick gives the permission at once, by its name, and unticking takes it away', (tester) async {
    final api = await openScreen(tester);

    await toggle(tester, api, Permission.approveEntries);
    expect(api.sentUserChanges.single.$1, '/projects/project-0/users/user-1/permissions/approveEntries');
    expect(isTicked(tester, Permission.approveEntries), isTrue);
    expect(isTicked(tester, Permission.readProject), isTrue);

    await toggle(tester, api, Permission.approveEntries);
    expect(api.sentUserChanges.last.$1, 'DELETE /projects/project-0/users/user-1/permissions/approveEntries');
    expect(isTicked(tester, Permission.approveEntries), isFalse);
  });

  testWidgets('a refusal shows its word in a SnackBar, and nothing changes', (tester) async {
    final api = await openScreen(tester);

    api.userAnswer = (status: 409, code: 'lastManager');
    await toggle(tester, api, Permission.readProject);

    expect(tester.widget<Text>(find.byKey(messageKeyOf('users.lastManager').label)).data, 'en users.lastManager');
    expect(isTicked(tester, Permission.readProject), isTrue);
  });

  testWidgets('unticking See the project takes them off the list', (tester) async {
    final api = await openScreen(tester);

    await toggle(tester, api, Permission.readProject);
    expect(find.byKey(UserPermissionsScreen.nameKey), findsNothing);

    await act(tester, api, () => tester.pageBack());
    expect(find.byKey(UsersScreen.rowKey('user-1')), findsNothing);
    expect(find.byKey(UsersScreen.rowKey('user-0')), findsOneWidget);
  });

  Finder partnerTick(FakeApi api, String name) => find.byKey(PermissionTicks.partnerKey(api.partners['project-0']!.singleWhere((partner) => partner['name'] == name)['id']! as String));

  testWidgets('redix-api #106: the two capital ticks sit under رأس المال, and the partners show only under a ticked رأس مال شركاء محددين', (tester) async {
    final api = await openScreen(tester);

    expect(find.byKey(PermissionTicks.capitalGroupKey), findsOneWidget);
    expect(partnerTick(api, 'خالد'), findsNothing);
    await toggle(tester, api, Permission.seeChosenCapital);

    expect(isTicked(tester, Permission.seeChosenCapital), isTrue);
    await tester.scrollUntilVisible(partnerTick(api, 'سعد'), 100);
    expect(partnerTick(api, 'خالد'), findsOneWidget);
    expect(partnerTick(api, 'سعد'), findsOneWidget);
  });

  testWidgets('redix-api #131: the two report ticks sit under التقارير, the way the capital ticks sit under رأس المال', (tester) async {
    await openScreen(tester);
    final heading = find.byKey(PermissionTicks.reportsGroupKey);

    await tester.scrollUntilVisible(find.byKey(UserPermissionsScreen.permissionKey(Permission.generateReports)), 100);

    expect(heading, findsOneWidget);
    final above = tester.getTopLeft(heading).dy;
    expect(above, lessThan(tester.getTopLeft(find.byKey(UserPermissionsScreen.permissionKey(Permission.seeReports))).dy));
    expect(tester.getTopLeft(find.byKey(UserPermissionsScreen.permissionKey(Permission.moveMoney))).dy, lessThan(above));
  });

  testWidgets('redix-api #106: unticking a chosen partner takes them from the person', (tester) async {
    final api = await openScreen(tester);
    await toggle(tester, api, Permission.seeChosenCapital);
    final khaled = api.partners['project-0']!.first['id']! as String;
    await tester.scrollUntilVisible(find.byKey(PermissionTicks.partnerKey(khaled)), 100);
    await act(tester, api, () => tester.tap(find.byKey(PermissionTicks.partnerKey(khaled).body)));

    await act(tester, api, () => tester.tap(find.byKey(PermissionTicks.partnerKey(khaled).body)));

    expect(api.sentUserChanges.last.$1, 'DELETE /projects/project-0/users/user-1/partners/$khaled');
    expect(tester.widget<CheckboxListTile>(find.byKey(PermissionTicks.partnerKey(khaled).body)).value, isFalse);
  });

  testWidgets('redix-api #106: ticking a partner chooses them for the person, and رأس مال كل الشركاء takes chosen capital and closes the list', (tester) async {
    final api = await openScreen(tester);
    await toggle(tester, api, Permission.seeChosenCapital);
    final khaled = api.partners['project-0']!.first['id']! as String;

    await tester.scrollUntilVisible(find.byKey(PermissionTicks.partnerKey(khaled)), 100);
    await act(tester, api, () => tester.tap(find.byKey(PermissionTicks.partnerKey(khaled).body)));
    expect(api.sentUserChanges.last.$1, '/projects/project-0/users/user-1/partners/$khaled');
    expect(tester.widget<CheckboxListTile>(find.byKey(PermissionTicks.partnerKey(khaled).body)).value, isTrue);

    await toggle(tester, api, Permission.seeAllCapital);

    expect((isTicked(tester, Permission.seeAllCapital), isTicked(tester, Permission.seeChosenCapital)), (true, false));
    expect(find.byKey(PermissionTicks.partnerKey(khaled)), findsNothing);
  });
}
