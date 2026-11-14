import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/launcher/launcher_add_entry.dart';
import 'package:redix/projects/projects_screen.dart';

import '../app_harness.dart';

/// Where «إضافة قيد» from the icon's menu or the home-screen widget lands: the one link `/add-entry`, resolved by the session (redix-app #86, the rule).
void main() {
  const keptWithDefault = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false, "defaultProjectId": "project-0"}';

  /// The API holding غصون 6, where the signed-in user holds [permissions], their default project unless [hasDefault] is false.
  FakeApi apiWith({List<String> permissions = field, bool hasDefault = true}) => FakeApi()
    ..defaultProjectId = hasDefault ? 'project-0' : ''
    ..addProject('غصون 6', permissions: permissions);

  /// Follows `/add-entry` from the screen keyed [from], as a tap on the icon's menu or the widget does with the app open.
  Future<void> follow(WidgetTester tester, FakeApi api, Key from) =>
      act(tester, api, () async => GoRouter.of(tester.element(find.byKey(from))).go(LauncherAddEntry.path));

  testWidgets('redix-app #86 AC-86.1, AC-86.2: whoever records in the default project lands on Add entry in it, its home behind to come back to', (tester) async {
    final api = apiWith();
    await pumpRedix(tester, api, stored: {'session': keptWithDefault});

    await follow(tester, api, HomeScreen.titleKey);

    expect(find.byKey(AddEntryScreen.tableKey), findsOneWidget);
    await pressBack(tester, api);
    expect(tester.widget<Text>(find.byKey(HomeScreen.titleKey)).data, 'غصون 6');
  });

  testWidgets('redix-app #86 AC-86.1: started by the link, before the projects are read, the app still lands on Add entry in the default project', (tester) async {
    tester.platformDispatcher.defaultRouteNameTestValue = LauncherAddEntry.path;
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);

    await pumpRedix(tester, apiWith(), stored: {'session': keptWithDefault});

    expect(find.byKey(AddEntryScreen.tableKey), findsOneWidget);
  });

  testWidgets('redix-app #86 AC-86.3: without a default project, the link opens the project list', (tester) async {
    final api = apiWith(hasDefault: false);
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));

    await follow(tester, api, HomeScreen.titleKey);

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
    expect(find.byKey(AddEntryScreen.tableKey), findsNothing);
  });

  testWidgets('redix-app #86 AC-86.3: with a default project the person is no longer active in, the link opens the project list', (tester) async {
    final api = apiWith();
    await pumpRedix(tester, api, stored: {'session': keptWithDefault});
    api.makeInactive(api.projects.single);

    await follow(tester, api, HomeScreen.titleKey);

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
    expect(find.byKey(AddEntryScreen.tableKey), findsNothing);
  });

  testWidgets('redix-app #86 AC-86.6: for whoever may not record in the default project, the link opens its home, «إضافة قيد» gray', (tester) async {
    final api = apiWith(permissions: reader);
    await pumpRedix(tester, api, stored: {'session': keptWithDefault});

    await follow(tester, api, HomeScreen.titleKey);

    expect(find.byKey(AddEntryScreen.tableKey), findsNothing);
    expect(find.byKey(HomeScreen.addEntryKey('project-0')), findsOneWidget);
    expect(isEnabled(tester, HomeScreen.addEntryKey('project-0')), isFalse);
  });

  testWidgets('redix-app #86 AC-86.5, G1: signed out, the link opens sign-in, and signing in lands on the home as every sign-in does', (tester) async {
    final api = apiWith();
    await pumpRedix(tester, api);

    await follow(tester, api, SignInScreen.usernameKey);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
    expect(find.byKey(AddEntryScreen.tableKey), findsNothing);

    await act(tester, api, () async {
      await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
      await tester.enterText(find.byKey(SignInScreen.passwordKey), 'secret');
      await tester.tap(find.byKey(SignInScreen.submitKey));
    });
    expect(tester.widget<Text>(find.byKey(HomeScreen.titleKey)).data, 'غصون 6');
    expect(find.byKey(AddEntryScreen.tableKey), findsNothing);
  });
}
