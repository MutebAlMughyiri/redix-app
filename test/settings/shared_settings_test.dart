import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/default_project_sheet.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/words/language_switch.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/users/my_permissions_screen.dart';
import 'package:redix/users/permission_ticks.dart';
import 'package:redix/auth/permission.dart';

import '../app_harness.dart';
import '../app_harness.dart' as harness;
import 'package:redix/ui/api_list_body.dart';

void main() {
  Future<void> openSettings(WidgetTester tester, FakeApi api) async {
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.sharedSettingsKey)));
  }

  testWidgets('Muteb, 8 and 9 Nov 2026: the home opens Settings from a gear in its top bar, colored by the theme, and the project card has no Settings button', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);

    final icon = find.descendant(of: find.byType(AppBar), matching: find.byKey(HomeScreen.sharedSettingsKey('project-0')));
    expect(icon, findsOneWidget);
    final gear = tester.widget<Icon>(find.byKey(HomeScreen.sharedSettingsKey('project-0').icon));
    expect((gear.icon, gear.color), (Icons.settings_outlined, null), reason: 'a color of its own would not follow a light or a dark theme');
    expect(find.byKey(HomeScreen.sharedSettingsKey('project-0').label), findsNothing);

    await act(tester, api, () => tester.tap(icon));

    expect(find.byKey(SharedSettingsScreen.switchProjectKey), findsOneWidget);
  });

  testWidgets('the admin sees Switch project, the default project and Registered projects', (tester) async {
    await openSettings(tester, FakeApi()..permissions = admin);

    expect(find.byKey(SharedSettingsScreen.switchProjectKey), findsOneWidget);
    expect(find.byKey(SharedSettingsScreen.defaultProjectKey), findsOneWidget);
    expect(find.byKey(SharedSettingsScreen.registeredKey), findsOneWidget);
  });

  testWidgets('anyone else sees Switch project and the default project, and not the registered projects', (tester) async {
    await openSettings(tester, FakeApi());

    expect(find.byKey(SharedSettingsScreen.switchProjectKey), findsOneWidget);
    expect(find.byKey(SharedSettingsScreen.defaultProjectKey), findsOneWidget);
    expect(find.byKey(SharedSettingsScreen.registeredKey), findsNothing);
  });

  testWidgets('Muteb, 9 Nov 2026: opened from a project, Settings shows the role name typed there beside the username; from the project list, the username alone', (tester) async {
    final api = FakeApi()..addProject('غصون 6', roleName: 'مدير المشروع');
    await openProject(tester, api);
    await harness.openSettings(tester, api);

    expect(tester.widget<Text>(find.byKey(SharedSettingsScreen.whoKey.subtitle)).data, 'muteb · مدير المشروع');

    await act(tester, api, () => tester.tap(find.byKey(SharedSettingsScreen.switchProjectKey)));
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.sharedSettingsKey)));
    expect(tester.widget<Text>(find.byKey(SharedSettingsScreen.whoKey.subtitle)).data, 'muteb');
  });

  testWidgets('Muteb, 9 Nov 2026: Settings shows the account itself, with no My account or language row to open first', (tester) async {
    await openSettings(tester, FakeApi());

    for (final key in [SharedSettingsScreen.whoKey, SharedSettingsScreen.languageKey, LanguageSwitch.choiceKey, SharedSettingsScreen.biometricsKey, SharedSettingsScreen.changePasswordKey, SharedSettingsScreen.signOutKey]) {
      expect(find.byKey(key), findsOneWidget, reason: '$key');
    }
    expect(find.text('en myAccount.title'), findsNothing);
  });

  testWidgets('Switch project goes back to the list', (tester) async {
    final api = FakeApi();
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SharedSettingsScreen.switchProjectKey)));

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
    expect(find.byKey(SharedSettingsScreen.switchProjectKey), findsNothing);
  });

  testWidgets('Registered projects opens from Settings', (tester) async {
    final api = FakeApi()..permissions = admin;
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SharedSettingsScreen.registeredKey)));

    expect(find.byKey(ApiListBody.emptyKey), findsOneWidget);
  });

  bool? isTicked(WidgetTester tester, String id) => tester.widget<CheckboxListTile>(find.byKey(DefaultProjectSheet.optionKey(id))).value;

  Future<FakeApi> openDefaultProject(WidgetTester tester) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..addProject('غصون 7')
      ..addProject('غصون 8', status: 'pendingApproval')
      ..addProject('غصون 9', status: 'rejected');
    await openSettings(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(SharedSettingsScreen.defaultProjectKey)));
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

    expect(api.sentProjectChanges.last.$1, 'DELETE /projects/default');
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

  testWidgets("Muteb, 9 Nov 2026: a project's More info, permissions, users, categories and items, and payment methods open from its home, beside a grayed import of its settings, and Settings holds none of them", (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);

    for (final key in [HomeScreen.projectInfoKey('project-0'), HomeScreen.myPermissionsKey('project-0'), HomeScreen.usersKey('project-0'), HomeScreen.categoriesKey('project-0'), HomeScreen.paymentMethodsKey('project-0')]) {
      await showProjectSetting(tester, key);
      expect(isEnabled(tester, key), isTrue, reason: '$key');
    }
    await showProjectSetting(tester, HomeScreen.importSettingsKey('project-0'));
    expect(isEnabled(tester, HomeScreen.importSettingsKey('project-0')), isFalse);
    expect(tester.widget<Text>(find.byKey(HomeScreen.importSettingsKey('project-0').label)).data, 'en projects.importSettings');

    await harness.openSettings(tester, api);
    for (final word in ['projectInfo.title', 'permissions.mine', 'users.title', 'categories.title', 'paymentMethods.title', 'projects.importSettings']) {
      expect(find.text('en $word'), findsNothing, reason: word);
    }
  });

  testWidgets('Muteb, 9 Nov 2026: صلاحياتي on the home shows every permission, those the person holds ticked, and none can be changed there', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field);
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.myPermissionsKey('project-0'));
    expect(tester.widget<Text>(find.byKey(HomeScreen.myPermissionsKey('project-0').label)).data, 'en permissions.mine');

    await scrollAndTap(tester, api, HomeScreen.myPermissionsKey('project-0'));

    expect(find.byKey(MyPermissionsScreen.hintKey), findsOneWidget);
    for (final permission in Permission.inAProject) {
      final tick = tester.widget<CheckboxListTile>(find.byKey(MyPermissionsScreen.permissionKey(permission).body));
      expect(tick.value, field.contains(permission.name), reason: permission.name);
      expect(tick.onChanged, isNull, reason: permission.name);
    }
  });

  testWidgets('Muteb, 12 Nov 2026: صلاحياتي is searched: what was typed keeps the permissions whose name or what it allows holds it, the capital heading over a capital tick kept', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field);
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.myPermissionsKey('project-0'));

    await searchFor(tester, api, 'approveEntries');
    expect(find.byKey(MyPermissionsScreen.permissionKey(Permission.approveEntries)), findsOneWidget);
    expect(find.byKey(MyPermissionsScreen.permissionKey(Permission.recordEntries)), findsNothing);
    expect(find.byKey(PermissionTicks.capitalGroupKey), findsNothing);

    await searchFor(tester, api, 'seeChosenCapitalHint');
    expect(find.byKey(MyPermissionsScreen.permissionKey(Permission.seeChosenCapital)), findsOneWidget);
    expect(find.byKey(MyPermissionsScreen.permissionKey(Permission.seeAllCapital)), findsNothing);
    expect(find.byKey(PermissionTicks.capitalGroupKey), findsOneWidget);

    await searchFor(tester, api, '');
    expect(find.byKey(MyPermissionsScreen.permissionKey(Permission.inAProject.first)), findsOneWidget);
    expect(find.byKey(MyPermissionsScreen.permissionKey(Permission.recordEntries)), findsOneWidget);
  });
}
