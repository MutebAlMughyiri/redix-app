import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// Goes back from Settings to the project's home, which reads the project again.
  Future<void> backHome(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byType(BackButton)));

  Future<void> openHome(WidgetTester tester, FakeApi api) async {
    await openProject(tester, api);
  }

  const keptDirect = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false, "defaultProjectId": "project-0"}';

  testWidgets('a card opens its home, whose title names it, and back returns to the list', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openHome(tester, api);

    expect(text(tester, HomeScreen.titleKey), 'غصون 6');

    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('the buttons follow the permissions in the open project', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..addProject('غصون 7', permissions: ['readProject']);
    await openHome(tester, api);
    await openSettings(tester, api);
    expect(find.byKey(SettingsScreen.usersKey), findsOneWidget);

    await backHome(tester, api);
    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-1'))));

    await openSettings(tester, api, projectId: 'project-1');
    expect(find.byKey(SettingsScreen.projectInfoKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.usersKey), findsNothing);
    expect(find.byKey(SettingsScreen.categoriesKey), findsNothing);
  });

  testWidgets('AC-37.1: with a default, the app opens that project at start, with no back arrow', (tester) async {
    final api = FakeApi()
      ..defaultProjectId = 'project-0'
      ..addProject('غصون 6');

    await pumpRedix(tester, api, stored: {'session': keptDirect});

    expect(text(tester, HomeScreen.titleKey), 'غصون 6');
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('Switch project reaches the list from a project opened directly, and stays there', (tester) async {
    final api = FakeApi()
      ..defaultProjectId = 'project-0'
      ..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptDirect});

    await openSettings(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.switchProjectKey)));

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
    expect(find.byKey(HomeScreen.titleKey), findsNothing);
  });

  testWidgets('a project gone while open returns to the list', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openHome(tester, api);

    await openSettings(tester, api);
    api.projects.clear();
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('with no network and nothing kept the home says so, and Try again reads it', (tester) async {
    final store = MemoryStore();
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession}, store: store);

    api.online = false;
    await store.clear('copies');
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    expect(text(tester, HomeScreen.messageKey), 'en projects.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.retryKey)));
    expect(find.byKey(HomeScreen.cardKey('project-0')), findsOneWidget);
  });

  testWidgets('R1: the home shows no start date, status or units, only its buttons', (tester) async {
    final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية']);
    await openHome(tester, api);

    for (final key in [ProjectInfoScreen.detailsKey, ProjectInfoScreen.statusKey, ProjectInfoScreen.unitKey('project-0-unit-0'), ProjectInfoScreen.noUnitsKey, HomeScreen.finishedKey('project-0')]) {
      expect(find.byKey(key), findsNothing, reason: '$key');
    }
    expect(find.byKey(HomeScreen.accountsKey('project-0')), findsOneWidget);
    expect(find.byKey(HomeScreen.settingsKey('project-0')), findsOneWidget);
  });

  testWidgets('R13: a finished project stays listed, and its home says in one line that it is finished and read-only', (tester) async {
    final api = FakeApi()..addProject('غصون 5', status: 'finished', units: ['الفلة الشرقية']);
    await openHome(tester, api);

    expect(tester.widget<Text>(find.byKey(HomeScreen.finishedKey('project-0').title)).data, 'en projects.finished · en projects.readOnly');
    expect(find.byKey(HomeScreen.addEntryKey('project-0')), findsNothing);
  });

  testWidgets('a reader or a field supervisor has More info in Settings, and nothing that changes the project', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: reader);
    await openHome(tester, api);

    await openSettings(tester, api);
    expect(find.byKey(SettingsScreen.projectInfoKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.usersKey), findsNothing);
    expect(find.byKey(SettingsScreen.categoriesKey), findsNothing);
    expect(find.byKey(SettingsScreen.paymentMethodsKey), findsNothing);
  });

  testWidgets('whoever only manages users has Users, and More info offers them no change', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['manageUsers', 'readProject', 'seeAllCapital']);
    await openHome(tester, api);

    await openSettings(tester, api);
    expect(find.byKey(SettingsScreen.usersKey), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.projectInfoKey)));
    expect(find.byKey(ProjectInfoScreen.addUnitKey), findsNothing);
    expect(find.byKey(ProjectInfoScreen.closeKey), findsNothing);
  });

  testWidgets('whoever manages the project but not its users has Add unit and Close in More info, but no Users', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject', 'seeAllCapital', 'manageProject']);
    await openHome(tester, api);

    await openSettings(tester, api);
    expect(find.byKey(SettingsScreen.usersKey), findsNothing);
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.projectInfoKey)));
    expect(find.byKey(ProjectInfoScreen.addUnitKey), findsOneWidget);
    expect(find.byKey(ProjectInfoScreen.closeKey), findsOneWidget);
  });

  testWidgets('Users stays on a finished project, and the list is read again on coming back', (tester) async {
    final api = FakeApi()..addProject('غصون 6', status: 'finished', permissions: ['manageUsers', 'readProject']);
    await openHome(tester, api);

    await openSettings(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.usersKey)));
    api.projects.single['permissions'] = ['readProject'];
    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    await openSettings(tester, api);
    expect(find.byKey(SettingsScreen.usersKey), findsNothing);
  });
}
