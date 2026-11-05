import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Future<FakeApi> openList(WidgetTester tester) async {
    final api = FakeApi()
      ..permissions = admin
      ..addRegistered('غصون 8');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.registeredKey)));
    return api;
  }

  testWidgets('a waiting project shows what is needed to decide', (tester) async {
    await openList(tester);

    expect(find.text('غصون 8'), findsOneWidget);
    expect(text(tester, RegisteredProjectsScreen.detailsKey('registered-0')), '05.11.2026 · الفلة الغربية');
    expect(text(tester, RegisteredProjectsScreen.managerKey('registered-0')), 'ريم · reem · 0500000000');
  });

  testWidgets('with nothing waiting, the list says so', (tester) async {
    final api = FakeApi()..permissions = admin;
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.registeredKey)));

    expect(text(tester, RegisteredProjectsScreen.emptyKey), 'en registered.empty');
  });

  testWidgets('Approve sends it, and it leaves the list', (tester) async {
    final api = await openList(tester);

    await act(tester, api, () => tester.tap(find.byKey(RegisteredProjectsScreen.approveKey('registered-0'))));

    expect(api.sentRegistrations.single.$1, '/projects/registered-0/approve');
    expect(find.byKey(RegisteredProjectsScreen.cardKey('registered-0')), findsNothing);
  });

  testWidgets('a refused decision shows its word in a SnackBar', (tester) async {
    final api = await openList(tester);

    api.registrationAnswer = (status: 409, code: 'notPending');
    await act(tester, api, () => tester.tap(find.byKey(RegisteredProjectsScreen.approveKey('registered-0'))));

    expect(find.text('en registered.notPending'), findsOneWidget);
  });

  testWidgets('Reject names the project, sends the reason, and it leaves the list', (tester) async {
    final api = await openList(tester);

    await act(tester, api, () => tester.tap(find.byKey(RegisteredProjectsScreen.rejectKey('registered-0'))));
    expect(text(tester, RegisteredProjectsScreen.rejectNameKey), 'غصون 8');
    await act(tester, api, () async {
      await tester.enterText(find.byKey(RegisteredProjectsScreen.reasonKey), 'الاسم مكرر');
      await tester.tap(find.byKey(RegisteredProjectsScreen.saveKey));
    });

    final (path, body) = api.sentRegistrations.single;
    expect(path, '/projects/registered-0/reject');
    expect(body, {'reason': 'الاسم مكرر'});
    expect(find.byKey(RegisteredProjectsScreen.cardKey('registered-0')), findsNothing);
  });

  testWidgets('a refused reason stays in the dialog', (tester) async {
    final api = await openList(tester);
    await act(tester, api, () => tester.tap(find.byKey(RegisteredProjectsScreen.rejectKey('registered-0'))));

    api.registrationAnswer = (status: 400, code: 'invalidReason');
    await act(tester, api, () => tester.tap(find.byKey(RegisteredProjectsScreen.saveKey)));

    expect(text(tester, RegisteredProjectsScreen.dialogMessageKey), 'en registered.invalidReason');
  });

  testWidgets('without a network the list says so, and Try again reads it', (tester) async {
    final api = FakeApi()
      ..permissions = admin
      ..addRegistered('غصون 8');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));

    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.registeredKey)));
    expect(text(tester, RegisteredProjectsScreen.messageKey), 'en registered.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(RegisteredProjectsScreen.retryKey)));
    expect(find.byKey(RegisteredProjectsScreen.cardKey('registered-0')), findsOneWidget);
  });
}
