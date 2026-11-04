import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/users/project_role.dart';
import 'package:redix/users/user_projects_screen.dart';
import 'package:redix/users/users_screen.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openScreen(WidgetTester tester) async {
    final api = FakeApi()..isOwner = true;
    api
      ..addUser('متعب', username: 'muteb', isOwner: true)
      ..addUser('نواف', username: 'nawaf')
      ..addProject('غصون 6')
      ..addProject('غصون 5', status: 'finished');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.usersKey)));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.projectsKey)));
    return api;
  }

  bool isTicked(WidgetTester tester, String projectId) => tester.widget<CheckboxListTile>(find.byKey(UserProjectsScreen.tickKey(projectId))).value!;

  bool isChosen(WidgetTester tester, String projectId, ProjectRole role) =>
      tester.widget<ChoiceChip>(find.byKey(UserProjectsScreen.roleKey(projectId, role))).selected;

  testWidgets('the screen says whose projects these are, and nothing is ticked at first', (tester) async {
    await openScreen(tester);

    expect(tester.widget<Text>(find.byKey(UserProjectsScreen.nameKey)).data, 'نواف');
    expect(isTicked(tester, 'project-0'), isFalse);
    expect(find.byKey(UserProjectsScreen.roleKey('project-0', ProjectRole.reader)), findsNothing);
  });

  testWidgets('ticking gives the project as a reader, the least a user can be given', (tester) async {
    final api = await openScreen(tester);

    await act(tester, api, () => tester.tap(find.byKey(UserProjectsScreen.tickKey('project-0'))));

    final (path, body) = api.sentUserChanges.single;
    expect(path, '/users/user-1/projects/project-0');
    expect(body, {'role': 'reader'});
    expect(isTicked(tester, 'project-0'), isTrue);
    expect(isChosen(tester, 'project-0', ProjectRole.reader), isTrue);
  });

  testWidgets('choosing a role changes it at once', (tester) async {
    final api = await openScreen(tester);
    await act(tester, api, () => tester.tap(find.byKey(UserProjectsScreen.tickKey('project-0'))));

    await act(tester, api, () => tester.tap(find.byKey(UserProjectsScreen.roleKey('project-0', ProjectRole.financeSupervisor))));

    expect(api.sentUserChanges.last.$2, {'role': 'financeSupervisor'});
    expect(isChosen(tester, 'project-0', ProjectRole.financeSupervisor), isTrue);
    expect(isChosen(tester, 'project-0', ProjectRole.reader), isFalse);
  });

  testWidgets('unticking takes the project away', (tester) async {
    final api = await openScreen(tester);
    await act(tester, api, () => tester.tap(find.byKey(UserProjectsScreen.tickKey('project-0'))));

    await act(tester, api, () => tester.tap(find.byKey(UserProjectsScreen.tickKey('project-0'))));

    expect(api.sentUserChanges.last.$1, '/users/user-1/projects/project-0/remove');
    expect(isTicked(tester, 'project-0'), isFalse);
  });

  testWidgets('a finished project can be given, and says it is finished', (tester) async {
    final api = await openScreen(tester);

    expect(
      find.descendant(of: find.byKey(UserProjectsScreen.tickKey('project-1')), matching: find.text('غصون 5 (en projects.finished)')),
      findsOneWidget,
    );

    await act(tester, api, () => tester.tap(find.byKey(UserProjectsScreen.tickKey('project-1'))));

    expect(isTicked(tester, 'project-1'), isTrue);
  });

  testWidgets('a refusal shows its word in a SnackBar, and nothing changes', (tester) async {
    final api = await openScreen(tester);

    api.userAnswer = (status: 409, code: 'ownerIsInEveryProject');
    await act(tester, api, () => tester.tap(find.byKey(UserProjectsScreen.tickKey('project-0'))));

    expect(find.text('en users.ownerIsInEveryProject'), findsOneWidget);
    expect(isTicked(tester, 'project-0'), isFalse);
  });

  testWidgets('the row in Users follows each change', (tester) async {
    final api = await openScreen(tester);
    await act(tester, api, () => tester.tap(find.byKey(UserProjectsScreen.tickKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(UserProjectsScreen.roleKey('project-0', ProjectRole.fieldSupervisor))));

    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect(tester.widget<Text>(find.byKey(UsersScreen.projectsLineKey('user-1'))).data, 'en users.roleField · غصون 6');
  });
}
