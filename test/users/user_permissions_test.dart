import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/users/user_permissions_screen.dart';
import 'package:redix/users/users_screen.dart';
import 'package:redix/settings/settings_screen.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openScreen(WidgetTester tester) async {
    final api = FakeApi()..addProject('غصون 6');
    final manager = api.addUser('متعب', username: 'muteb');
    final user = api.addUser('نواف', username: 'nawaf');
    api
      ..give(manager, 'project-0', managerAndFinance)
      ..give(user, 'project-0', reader);
    await openProject(tester, api);
    await openSettings(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.usersKey)));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.permissionsKey)));
    return api;
  }

  Finder tick(Permission permission) => find.descendant(of: find.byKey(UserPermissionsScreen.permissionKey(permission)), matching: find.byType(CheckboxListTile));

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
    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    expect(api.sentReads, isNot(contains('/projects')));

    saved.complete();
    await act(tester, api, () async {});

    expect(api.sentReads, contains('/projects'));
  });

  testWidgets('the screen says whose permissions these are, and ticks every one a project can give, with what they hold ticked', (tester) async {
    await openScreen(tester);

    expect(tester.widget<Text>(find.byKey(UserPermissionsScreen.nameKey)).data, 'نواف');
    expect(find.text('en permissions.title'), findsOneWidget);
    expect(find.text('غصون 6'), findsOneWidget);
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
    expect(api.sentUserChanges.last.$1, '/projects/project-0/users/user-1/permissions/approveEntries/remove');
    expect(isTicked(tester, Permission.approveEntries), isFalse);
  });

  testWidgets('a refusal shows its word in a SnackBar, and nothing changes', (tester) async {
    final api = await openScreen(tester);

    api.userAnswer = (status: 409, code: 'lastManager');
    await toggle(tester, api, Permission.readProject);

    expect(find.text('en users.lastManager'), findsOneWidget);
    expect(isTicked(tester, Permission.readProject), isTrue);
  });

  testWidgets('unticking See the project takes them off the list', (tester) async {
    final api = await openScreen(tester);

    await toggle(tester, api, Permission.readProject);
    expect(find.byKey(UserPermissionsScreen.nameKey), findsNothing);

    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    expect(find.byKey(UsersScreen.rowKey('user-1')), findsNothing);
    expect(find.byKey(UsersScreen.rowKey('user-0')), findsOneWidget);
  });
}
