import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  String status(WidgetTester tester, String id) =>
      tester.widget<Text>(find.descendant(of: find.byKey(ProjectsScreen.statusKey(id)), matching: find.byType(Text))).data!;

  Future<void> openProjects(WidgetTester tester, FakeApi api) async {
    api.permissions = systemAdmin;
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.projectsKey)));
  }

  testWidgets('with no projects yet, the list says what to do next', (tester) async {
    await openProjects(tester, FakeApi());

    expect(text(tester, ProjectsScreen.emptyKey), 'en projects.empty');
    expect(find.byKey(ProjectsScreen.newProjectKey), findsOneWidget);
  });

  testWidgets('without a network the list says so, and Try again reads it', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));

    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.projectsKey)));
    expect(text(tester, ProjectsScreen.messageKey), 'en projects.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.retryKey)));
    expect(find.byKey(ProjectsScreen.messageKey), findsNothing);
    expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsOneWidget);
  });

  testWidgets('a running project shows its date, status and units in order, and offers its changes', (tester) async {
    final api = FakeApi()..addProject('غصون 6', startDate: '2026-03-01', units: ['الفلة الغربية', 'الفلة الجنوبية']);
    await openProjects(tester, api);

    expect(text(tester, ProjectsScreen.detailsKey('project-0')), 'en projects.startDate 01.03.2026');
    expect(status(tester, 'project-0'), 'en projects.running');
    expect(text(tester, ProjectsScreen.unitKey('project-0-unit-0')), 'الفلة الغربية');
    expect(text(tester, ProjectsScreen.unitKey('project-0-unit-1')), 'الفلة الجنوبية');
    expect(
      tester.getTopLeft(find.byKey(ProjectsScreen.unitKey('project-0-unit-0'))).dy,
      lessThan(tester.getTopLeft(find.byKey(ProjectsScreen.unitKey('project-0-unit-1'))).dy),
    );
    expect(find.byKey(ProjectsScreen.addUnitKey('project-0')), findsOneWidget);
    expect(find.byKey(ProjectsScreen.closeKey('project-0')), findsOneWidget);
  });

  testWidgets('Arabic names show as typed', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);

    expect(text(tester, ProjectsScreen.nameKey('project-0')), 'غصون 6');
  });

  testWidgets('a project with no units says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);

    expect(text(tester, ProjectsScreen.noUnitsKey('project-0')), 'en projects.noUnits');
  });

  testWidgets('a finished project stays listed, read-only, and offers no change', (tester) async {
    final api = FakeApi()..addProject('غصون 5', status: 'finished', startDate: '2024-01-15', units: ['الفلة الشرقية']);
    await openProjects(tester, api);

    expect(status(tester, 'project-0'), 'en projects.finished');
    expect(text(tester, ProjectsScreen.detailsKey('project-0')), 'en projects.startDate 15.01.2024 · en projects.readOnly');
    expect(find.byKey(ProjectsScreen.unitKey('project-0-unit-0')), findsOneWidget);
    expect(find.byKey(ProjectsScreen.addUnitKey('project-0')), findsNothing);
    expect(find.byKey(ProjectsScreen.closeKey('project-0')), findsNothing);
  });

  testWidgets('closing asks first, says what it means, and Cancel changes nothing', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.closeKey('project-0'))));
    expect(text(tester, ProjectsScreen.closeNameKey), 'غصون 6');
    expect(text(tester, ProjectsScreen.closeExplainKey), 'en projects.closeExplain');
    expect(api.sentProjectChanges, isEmpty);

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cancelCloseKey)));
    expect(api.sentProjectChanges, isEmpty);
    expect(status(tester, 'project-0'), 'en projects.running');
  });

  testWidgets('closing a project makes it finished, with no more changes offered', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.closeKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.confirmCloseKey)));

    expect(api.sentProjectChanges.single.$1, '/projects/project-0/close');
    expect(status(tester, 'project-0'), 'en projects.finished');
    expect(find.byKey(ProjectsScreen.closeKey('project-0')), findsNothing);
  });

  testWidgets('closing without a network says so, and the project stays as it was', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.closeKey('project-0'))));

    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.confirmCloseKey)));

    expect(find.text('en projects.noConnection'), findsOneWidget);
    expect(status(tester, 'project-0'), 'en projects.running');
  });

  testWidgets('a project someone else closed shows its refusal, and the list is read again', (tester) async {
    final api = FakeApi();
    final project = api.addProject('غصون 6');
    await openProjects(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.closeKey('project-0'))));

    project['status'] = 'finished';
    api.projectAnswer = (status: 409, code: 'projectFinished');
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.confirmCloseKey)));

    expect(find.text('en projects.projectFinished'), findsOneWidget);
    expect(status(tester, 'project-0'), 'en projects.finished');
    expect(find.byKey(ProjectsScreen.closeKey('project-0')), findsNothing);
  });

  testWidgets('a refusal with no code shows the general word, never a raw key', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.closeKey('project-0'))));

    api.projectAnswer = (status: 403, code: '');
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.confirmCloseKey)));

    expect(find.text('en projects.refused'), findsOneWidget);
  });

  testWidgets('Add unit adds to the end of a running project', (tester) async {
    final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية']);
    await openProjects(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.addUnitKey('project-0'))));
    await act(tester, api, () async {
      await tester.enterText(find.byKey(ProjectsScreen.unitNameKey), 'الفلة الجنوبية');
      await tester.tap(find.byKey(ProjectsScreen.saveUnitKey));
    });

    expect(find.byKey(ProjectsScreen.saveUnitKey), findsNothing);
    expect(api.sentProjectChanges.single.$1, '/projects/project-0/units');
    expect(text(tester, ProjectsScreen.unitKey('project-0-unit-1')), 'الفلة الجنوبية');
  });

  testWidgets('a refused unit stays in the dialog with what was typed', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProjects(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.addUnitKey('project-0'))));

    api.projectAnswer = (status: 400, code: 'invalidName');
    await act(tester, api, () async {
      await tester.enterText(find.byKey(ProjectsScreen.unitNameKey), 'x');
      await tester.tap(find.byKey(ProjectsScreen.saveUnitKey));
    });

    expect(text(tester, ProjectsScreen.unitMessageKey), 'en projects.invalidName');
    expect(tester.widget<TextField>(find.byKey(ProjectsScreen.unitNameKey)).controller!.text, 'x');
  });

  testWidgets('an expired access token is renewed once when reading the list', (tester) async {
    final api = FakeApi()
      ..refreshStatus = 500;
    await pumpRedix(tester, api, stored: {'session': keptSession});
    api
      ..expiredAccessTokens.add('kept-access')
      ..refreshStatus = 200;

    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.projectsKey)));

    expect(api.sentAccessTokens, ['kept-access', 'new-access']);
    expect(find.byKey(ProjectsScreen.emptyKey), findsOneWidget);
  });

  Future<void> openAsAnyone(WidgetTester tester, FakeApi api) async {
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.projectsKey)));
  }

  testWidgets('New project shows only with startProject', (tester) async {
    await openAsAnyone(tester, FakeApi()..addProject('غصون 6'));

    expect(find.byKey(ProjectsScreen.newProjectKey), findsNothing);
  });

  testWidgets('each project says what the user is in it', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..addProject('غصون 7', roles: ['users.roleReader'], permissions: ['readProject']);
    await openAsAnyone(tester, api);

    expect(text(tester, ProjectsScreen.rolesKey('project-0')), 'en users.roleManager · en users.roleFinance');
    expect(text(tester, ProjectsScreen.rolesKey('project-1')), 'en users.roleReader');
  });

  testWidgets('a reader or a field supervisor sees the project and can change nothing', (tester) async {
    final api = FakeApi()..addProject('غصون 6', roles: ['users.roleReader'], permissions: ['readProject']);
    await openAsAnyone(tester, api);

    expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsOneWidget);
    expect(find.byKey(ProjectsScreen.usersKey('project-0')), findsNothing);
    expect(find.byKey(ProjectsScreen.addUnitKey('project-0')), findsNothing);
    expect(find.byKey(ProjectsScreen.closeKey('project-0')), findsNothing);
  });

  testWidgets('a manager with no other role has Users, but no Add unit or Close', (tester) async {
    final api = FakeApi()..addProject('غصون 6', roles: ['users.roleManager'], permissions: ['manageUsers', 'readProject', 'seeAllCapital']);
    await openAsAnyone(tester, api);

    expect(find.byKey(ProjectsScreen.usersKey('project-0')), findsOneWidget);
    expect(find.byKey(ProjectsScreen.addUnitKey('project-0')), findsNothing);
    expect(find.byKey(ProjectsScreen.closeKey('project-0')), findsNothing);
  });

  testWidgets('a financial supervisor has Add unit and Close, but no Users', (tester) async {
    final api = FakeApi()..addProject('غصون 6', roles: ['users.roleFinance'], permissions: ['readProject', 'seeAllCapital', 'manageProject']);
    await openAsAnyone(tester, api);

    expect(find.byKey(ProjectsScreen.usersKey('project-0')), findsNothing);
    expect(find.byKey(ProjectsScreen.addUnitKey('project-0')), findsOneWidget);
    expect(find.byKey(ProjectsScreen.closeKey('project-0')), findsOneWidget);
  });

  testWidgets('Users stays on a finished project, and the list is read again on coming back', (tester) async {
    final api = FakeApi()..addProject('غصون 6', status: 'finished', roles: ['users.roleManager'], permissions: ['manageUsers', 'readProject']);
    await openAsAnyone(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.usersKey('project-0'))));
    api.projects.single['permissions'] = ['readProject'];
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect(find.byKey(ProjectsScreen.usersKey('project-0')), findsNothing);
  });
}
