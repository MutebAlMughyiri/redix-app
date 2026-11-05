import 'package:flutter_test/flutter_test.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';

import '../app_harness.dart';

void main() {
  Future<void> openSettings(WidgetTester tester, FakeApi api) async {
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
  }

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

  testWidgets('My account opens from Settings', (tester) async {
    final api = FakeApi();
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));

    expect(find.byKey(MyAccountScreen.changePasswordKey), findsOneWidget);
  });
}
