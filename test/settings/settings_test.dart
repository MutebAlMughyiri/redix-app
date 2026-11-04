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

  testWidgets('the system admin sees Projects, Users and My account', (tester) async {
    await openSettings(tester, FakeApi()..permissions = systemAdmin);

    expect(find.byKey(SettingsScreen.projectsKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.usersKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.myAccountKey), findsOneWidget);
  });

  testWidgets('anyone else sees Projects and My account, and not every login', (tester) async {
    await openSettings(tester, FakeApi());

    expect(find.byKey(SettingsScreen.projectsKey), findsOneWidget);
    expect(find.byKey(SettingsScreen.usersKey), findsNothing);
    expect(find.byKey(SettingsScreen.myAccountKey), findsOneWidget);
  });

  testWidgets('Projects opens from Settings', (tester) async {
    final api = FakeApi();
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.projectsKey)));

    expect(find.byKey(ProjectsScreen.emptyKey), findsOneWidget);
  });

  testWidgets('Users opens every login from Settings, where no one new is added', (tester) async {
    final api = FakeApi()
      ..permissions = systemAdmin
      ..addUser('نواف', username: 'nawaf');
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.usersKey)));

    expect(find.byKey(UsersScreen.rowKey('user-0')), findsOneWidget);
    expect(find.byKey(UsersScreen.newUserKey), findsNothing);
    expect(find.byKey(UsersScreen.addExistingKey), findsNothing);
  });

  testWidgets('My account opens from Settings', (tester) async {
    final api = FakeApi();
    await openSettings(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));

    expect(find.byKey(MyAccountScreen.changePasswordKey), findsOneWidget);
  });
}
