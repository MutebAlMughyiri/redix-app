import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';
import 'package:redix/ui/api_list_body.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

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

  testWidgets('Muteb, 9 Nov 2026: the role name typed for the signed-in user shows under the project name, and nothing shows where none was typed', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6', roleName: 'مدير المشروع')
      ..addProject('غصون 7');
    await openHome(tester, api);

    expect(text(tester, HomeScreen.titleKey), 'غصون 6');
    expect(text(tester, HomeScreen.roleNameKey), 'مدير المشروع');

    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-1'))));
    expect(text(tester, HomeScreen.titleKey), 'غصون 7');
    expect(find.byKey(HomeScreen.roleNameKey), findsNothing);
  });

  testWidgets('the buttons follow the permissions in the open project', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..addProject('غصون 7', permissions: ['readProject']);
    await openHome(tester, api);
    await showProjectSetting(tester, HomeScreen.usersKey('project-0'));
    expect(find.byKey(HomeScreen.usersKey('project-0')), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-1'))));

    for (final (key, shown) in [(HomeScreen.projectInfoKey('project-1'), findsOneWidget), (HomeScreen.usersKey('project-1'), findsNothing), (HomeScreen.categoriesKey('project-1'), findsNothing)]) {
      await showProjectSetting(tester, key);
      expect(find.byKey(key), shown);
    }
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
    await act(tester, api, () => tester.tap(find.byKey(SharedSettingsScreen.switchProjectKey)));

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
    expect(text(tester, ApiListBody.messageKey), 'en projects.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(ApiListBody.retryKey)));
    expect(find.byKey(HomeScreen.cardKey('project-0')), findsOneWidget);
  });

  testWidgets('R1: the home shows no start date, status or units, only its buttons', (tester) async {
    final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية']);
    await openHome(tester, api);

    for (final key in [ProjectInfoScreen.detailsKey, ProjectInfoScreen.statusKey, ProjectInfoScreen.unitKey('project-0-unit-0'), ProjectInfoScreen.noUnitsKey, HomeScreen.finishedKey('project-0')]) {
      expect(find.byKey(key), findsNothing, reason: '$key');
    }
    await showProjectSetting(tester, HomeScreen.accountsKey('project-0'));
    expect(find.byKey(HomeScreen.accountsKey('project-0')), findsOneWidget);
    expect(find.byKey(HomeScreen.sharedSettingsKey('project-0')), findsOneWidget);
  });

  testWidgets('entries that cannot be read say so on the home, never that there are none', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..addEntry(status: 'approved')
      ..unreachable.add('/projects/project-0/entries');

    await openProject(tester, api);

    expect(text(tester, HomeScreen.entriesEmptyKey('project-0')), 'en entries.loadFailed');
  });

  testWidgets('a project with no entries says so on the home', (tester) async {
    await openProject(tester, FakeApi()..addProject('غصون 6'));

    expect(text(tester, HomeScreen.entriesEmptyKey('project-0')), 'en entries.empty');
  });

  testWidgets('R13: a finished project stays listed, and its home says in one line that it is finished and read-only', (tester) async {
    final api = FakeApi()..addProject('غصون 5', status: 'finished', units: ['الفلة الشرقية']);
    await openHome(tester, api);

    expect(tester.widget<Text>(find.byKey(HomeScreen.finishedKey('project-0').title)).data, 'en projects.finished · en projects.readOnly');
    expect(isEnabled(tester, HomeScreen.addEntryKey('project-0')), isFalse);
  });

  testWidgets('a reader or a field supervisor has More info and their permissions on the home, and nothing that changes the project', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: reader);
    await openHome(tester, api);

    await showProjectSetting(tester, HomeScreen.projectInfoKey('project-0'));
    expect(find.byKey(HomeScreen.projectInfoKey('project-0')), findsOneWidget);
    await showProjectSetting(tester, HomeScreen.myPermissionsKey('project-0'));
    expect(find.byKey(HomeScreen.myPermissionsKey('project-0')), findsOneWidget);
    await showProjectSetting(tester, HomeScreen.usersKey('project-0'));
    expect(find.byKey(HomeScreen.usersKey('project-0')), findsNothing);
    await showProjectSetting(tester, HomeScreen.categoriesKey('project-0'));
    expect(find.byKey(HomeScreen.categoriesKey('project-0')), findsNothing);
    await showProjectSetting(tester, HomeScreen.paymentMethodsKey('project-0'));
    expect(find.byKey(HomeScreen.paymentMethodsKey('project-0')), findsNothing);
  });

  testWidgets('whoever only manages users has Users, and More info offers them no change', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['manageUsers', 'readProject', 'seeAllCapital']);
    await openHome(tester, api);

    await showProjectSetting(tester, HomeScreen.usersKey('project-0'));
    expect(find.byKey(HomeScreen.usersKey('project-0')), findsOneWidget);
    await scrollAndTap(tester, api, HomeScreen.projectInfoKey('project-0'));
    expect(find.byKey(ProjectInfoScreen.addUnitKey), findsNothing);
    expect(find.byKey(ProjectInfoScreen.closeKey), findsNothing);
  });

  testWidgets('whoever manages the project but not its users has Add unit and Close in More info, but no Users', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject', 'seeAllCapital', 'manageProject']);
    await openHome(tester, api);

    await showProjectSetting(tester, HomeScreen.usersKey('project-0'));
    expect(find.byKey(HomeScreen.usersKey('project-0')), findsNothing);
    await scrollAndTap(tester, api, HomeScreen.projectInfoKey('project-0'));
    expect(find.byKey(ProjectInfoScreen.addUnitKey), findsOneWidget);
    expect(find.byKey(ProjectInfoScreen.closeKey), findsOneWidget);
  });

  testWidgets('Users stays on a finished project, and the list is read again on coming back', (tester) async {
    final api = FakeApi()..addProject('غصون 6', status: 'finished', permissions: ['manageUsers', 'readProject']);
    await openHome(tester, api);

    await scrollAndTap(tester, api, HomeScreen.usersKey('project-0'));
    api.projects.single['permissions'] = ['readProject'];
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    await showProjectSetting(tester, HomeScreen.usersKey('project-0'));
    expect(find.byKey(HomeScreen.usersKey('project-0')), findsNothing);
  });
}
