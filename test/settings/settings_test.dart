import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/default_project_sheet.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/refusal_snack_bar.dart';

import '../app_harness.dart';
import '../app_harness.dart' as harness;

void main() {
  Future<void> openSettings(WidgetTester tester, FakeApi api) async {
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
  }

  testWidgets('Muteb, 8 Nov 2026: the home opens Settings from an icon in its top bar, beside Refresh, and the project card has no Settings button', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);

    final icon = find.descendant(of: find.byType(AppBar), matching: find.byKey(HomeScreen.settingsKey('project-0')));
    expect(icon, findsOneWidget);
    expect(tester.widget<Icon>(find.byKey(HomeScreen.settingsKey('project-0').icon)).icon, Icons.precision_manufacturing_outlined);
    expect(find.byKey(HomeScreen.settingsKey('project-0').label), findsNothing);

    await act(tester, api, () => tester.tap(icon));

    expect(find.byKey(SettingsScreen.myAccountKey), findsOneWidget);
  });

  testWidgets('the admin sees Switch project, Registered projects and My account', (tester) async {
    await openSettings(tester, FakeApi()..permissions = admin);

    expect(find.byKey(SettingsScreen.switchProjectKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.registeredKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.myAccountKey), findsOneWidget);
  });

  testWidgets('anyone else sees Switch project and My account, and not the registered projects', (tester) async {
    await openSettings(tester, FakeApi());

    expect(find.byKey(SettingsScreen.switchProjectKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.registeredKey), findsNothing);
    expect(find.byKey(SettingsScreen.myAccountKey), findsOneWidget);
  });

  testWidgets('Switch project goes back to the list', (tester) async {
    final api = FakeApi();
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.switchProjectKey)));

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.switchProjectKey), findsNothing);
  });

  testWidgets('Registered projects opens from Settings', (tester) async {
    final api = FakeApi()..permissions = admin;
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.registeredKey)));

    expect(find.byKey(RegisteredProjectsScreen.emptyKey), findsOneWidget);
  });

  bool? isTicked(WidgetTester tester, String id) => tester.widget<CheckboxListTile>(find.byKey(DefaultProjectSheet.optionKey(id))).value;

  Future<FakeApi> openDefaultProject(WidgetTester tester) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..addProject('غصون 7')
      ..addProject('غصون 8', status: 'pendingApproval')
      ..addProject('غصون 9', status: 'rejected');
    await openSettings(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.defaultProjectKey)));
    return api;
  }

  testWidgets('Default project lists every approved project with a tick, the default ticked, and none waiting or rejected', (tester) async {
    final api = await openDefaultProject(tester);
    await act(tester, api, () => tester.tap(find.byKey(DefaultProjectSheet.optionKey('project-1'))));

    expect(find.byKey(DefaultProjectSheet.titleKey), findsOneWidget);
    expect((isTicked(tester, 'project-0'), isTicked(tester, 'project-1')), (false, true));
    expect(find.byKey(DefaultProjectSheet.optionKey('project-2')), findsNothing);
    expect(find.byKey(DefaultProjectSheet.optionKey('project-3')), findsNothing);
  });

  testWidgets('AC-37.1: ticking a project makes it the default and a message says so; ticking another moves it', (tester) async {
    final api = await openDefaultProject(tester);

    await act(tester, api, () => tester.tap(find.byKey(DefaultProjectSheet.optionKey('project-0'))));
    expect(api.sentProjectChanges.last.$1, '/projects/project-0/default');
    expect(isTicked(tester, 'project-0'), isTrue);
    expect(tester.widget<Text>(find.byKey(messageKeyOf('projects.defaultSet').label)).data, 'en projects.defaultSet');

    await act(tester, api, () => tester.tap(find.byKey(DefaultProjectSheet.optionKey('project-1'))));
    expect(api.sentProjectChanges.last.$1, '/projects/project-1/default');
    expect((isTicked(tester, 'project-0'), isTicked(tester, 'project-1')), (false, true));
  });

  testWidgets('unticking the default clears it, so sign-in shows the list', (tester) async {
    final api = await openDefaultProject(tester);
    await act(tester, api, () => tester.tap(find.byKey(DefaultProjectSheet.optionKey('project-0'))));

    await act(tester, api, () => tester.tap(find.byKey(DefaultProjectSheet.optionKey('project-0'))));

    expect(api.sentProjectChanges.last.$1, '/projects/default/remove');
    expect(api.defaultProjectId, '');
    expect(isTicked(tester, 'project-0'), isFalse);
  });

  testWidgets('a refused tick says why, and nothing is ticked', (tester) async {
    final api = await openDefaultProject(tester);
    api.projectAnswer = (status: 403, code: '');

    await act(tester, api, () => tester.tap(find.byKey(DefaultProjectSheet.optionKey('project-0'))));

    expect(tester.widget<Text>(find.byKey(messageKeyOf('projects.refused').label)).data, 'en projects.refused');
    expect((isTicked(tester, 'project-0'), isTicked(tester, 'project-1')), (false, false));
  });

  testWidgets('from the project list Settings holds nothing of a project', (tester) async {
    await openSettings(tester, FakeApi()..addProject('غصون 6'));

    expect(find.byKey(SettingsScreen.projectInfoKey), findsNothing);
    expect(find.byKey(SettingsScreen.usersKey), findsNothing);
    expect(find.byKey(SettingsScreen.categoriesKey), findsNothing);
    expect(find.byKey(SettingsScreen.paymentMethodsKey), findsNothing);
  });

  testWidgets('from a project Settings holds More info, its users, categories and items, and payment methods', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);

    await harness.openSettings(tester, api);

    expect(find.byKey(SettingsScreen.myAccountKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.projectInfoKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.usersKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.categoriesKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.paymentMethodsKey), findsOneWidget);
  });

  testWidgets('My account opens from Settings', (tester) async {
    final api = FakeApi();
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));

    expect(find.byKey(MyAccountScreen.changePasswordKey), findsOneWidget);
  });
}
