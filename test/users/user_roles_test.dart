import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/users/user_roles_screen.dart';
import 'package:redix/users/users_screen.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openScreen(WidgetTester tester, {FakeApi? given}) async {
    final api = (given ?? FakeApi())..addProject('غصون 6');
    final manager = api.addUser('متعب', username: 'muteb');
    final user = api.addUser('نواف', username: 'nawaf');
    api
      ..giveRole(manager, 'project-0', 'role-manager')
      ..giveRole(user, 'project-0', 'role-reader');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.projectsKey)));
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.usersKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.rolesKey)));
    return api;
  }

  bool isTicked(WidgetTester tester, String roleId) => tester.widget<CheckboxListTile>(find.byKey(UserRolesScreen.roleKey(roleId))).value!;

  testWidgets('the screen says whose roles these are, and ticks what they hold', (tester) async {
    await openScreen(tester);

    expect(tester.widget<Text>(find.byKey(UserRolesScreen.nameKey)).data, 'نواف');
    expect(find.text('en users.roles · غصون 6'), findsOneWidget);
    expect(isTicked(tester, 'role-reader'), isTrue);
    expect(isTicked(tester, 'role-finance'), isFalse);
  });

  testWidgets('a tick gives the role at once, and someone can hold more than one', (tester) async {
    final api = await openScreen(tester);

    await act(tester, api, () => tester.tap(find.byKey(UserRolesScreen.roleKey('role-finance'))));

    expect(api.sentUserChanges.single.$1, '/projects/project-0/users/user-1/roles/role-finance');
    expect(isTicked(tester, 'role-finance'), isTrue);
    expect(isTicked(tester, 'role-reader'), isTrue);
  });

  testWidgets('unticking takes the role away', (tester) async {
    final api = await openScreen(tester);
    await act(tester, api, () => tester.tap(find.byKey(UserRolesScreen.roleKey('role-finance'))));

    await act(tester, api, () => tester.tap(find.byKey(UserRolesScreen.roleKey('role-finance'))));

    expect(api.sentUserChanges.last.$1, '/projects/project-0/users/user-1/roles/role-finance/remove');
    expect(isTicked(tester, 'role-finance'), isFalse);
  });

  testWidgets('roles come from the API, a new one included', (tester) async {
    final api = FakeApi();
    api.roles.add({'id': 'role-auditor', 'wordKey': 'users.roleReader'});

    await openScreen(tester, given: api);

    expect(find.byKey(UserRolesScreen.roleKey('role-auditor')), findsOneWidget);
  });

  testWidgets('a refusal shows its word in a SnackBar, and nothing changes', (tester) async {
    final api = await openScreen(tester);

    api.userAnswer = (status: 409, code: 'lastManager');
    await act(tester, api, () => tester.tap(find.byKey(UserRolesScreen.roleKey('role-reader'))));

    expect(find.text('en users.lastManager'), findsOneWidget);
    expect(isTicked(tester, 'role-reader'), isTrue);
  });

  testWidgets('taking their last role takes them off the list', (tester) async {
    final api = await openScreen(tester);

    await act(tester, api, () => tester.tap(find.byKey(UserRolesScreen.roleKey('role-reader'))));
    expect(find.byKey(UserRolesScreen.nameKey), findsNothing);

    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    expect(find.byKey(UsersScreen.rowKey('user-1')), findsNothing);
    expect(find.byKey(UsersScreen.rowKey('user-0')), findsOneWidget);
  });

  testWidgets('the row in Users follows each change', (tester) async {
    final api = await openScreen(tester);
    await act(tester, api, () => tester.tap(find.byKey(UserRolesScreen.roleKey('role-field'))));

    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect(tester.widget<Text>(find.byKey(UsersScreen.projectsLineKey('user-1'))).data, 'en users.roleReader · en users.roleField');
  });
}
