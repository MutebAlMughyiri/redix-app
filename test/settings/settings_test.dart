import 'package:flutter_test/flutter_test.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/users/users_screen.dart';

import '../app_harness.dart';

void main() {
  Future<void> openSettings(WidgetTester tester, FakeApi api) async {
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));
  }

  testWidgets('an owner sees Projects, Users and My account', (tester) async {
    await openSettings(tester, FakeApi()..isOwner = true);

    expect(find.byKey(SettingsScreen.projectsKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.usersKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.myAccountKey), findsOneWidget);
  });

  testWidgets('anyone else sees My account only', (tester) async {
    await openSettings(tester, FakeApi());

    expect(find.byKey(SettingsScreen.projectsKey), findsNothing);
    expect(find.byKey(SettingsScreen.usersKey), findsNothing);
    expect(find.byKey(SettingsScreen.myAccountKey), findsOneWidget);
  });

  testWidgets('Projects opens from Settings', (tester) async {
    final api = FakeApi()..isOwner = true;
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.projectsKey)));

    expect(find.byKey(ProjectsScreen.newProjectKey), findsOneWidget);
  });

  testWidgets('Users opens from Settings', (tester) async {
    final api = FakeApi()..isOwner = true;
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.usersKey)));

    expect(find.byKey(UsersScreen.newUserKey), findsOneWidget);
  });

  testWidgets('My account opens from Settings', (tester) async {
    final api = FakeApi();
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));

    expect(find.byKey(MyAccountScreen.changePasswordKey), findsOneWidget);
  });
}
