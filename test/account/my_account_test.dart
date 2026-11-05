import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/users/new_user_screen.dart';
import 'package:redix/users/user_roles_screen.dart';
import 'package:redix/users/users_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  TextDirection direction(WidgetTester tester, Key key) => Directionality.of(tester.element(find.byKey(key)));

  Future<void> openMyAccount(WidgetTester tester, FakeApi api) async {
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));
  }

  Future<void> choose(WidgetTester tester, FakeApi api, Key language) => act(tester, api, () => tester.tap(find.byKey(language)));

  testWidgets('choosing English on an Arabic phone switches every screen to English, left to right', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await openMyAccount(tester, api);

    await choose(tester, api, MyAccountScreen.englishKey);

    expect(text(tester, MyAccountScreen.englishKey), 'en myAccount.english');
    expect(direction(tester, MyAccountScreen.englishKey), TextDirection.ltr);
    await act(tester, api, tester.pageBack);
    await act(tester, api, tester.pageBack);
    expect(text(tester, ProjectsScreen.titleKey), 'en projects.choose');
    expect(direction(tester, ProjectsScreen.titleKey), TextDirection.ltr);
  });

  testWidgets('the chosen language is kept on the phone and used at the next start', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await openMyAccount(tester, api);
    await choose(tester, api, MyAccountScreen.englishKey);
    final preferences = await SharedPreferences.getInstance();
    final kept = {for (final key in preferences.getKeys()) key: preferences.get(key) ?? ''};

    await tester.pumpWidget(const SizedBox());
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession}, preferences: kept);

    expect(text(tester, ProjectsScreen.titleKey), 'en projects.choose');
  });

  testWidgets('without a network the language stays and the app says switching needs a network', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await openMyAccount(tester, api);

    api.online = false;
    await choose(tester, api, MyAccountScreen.englishKey);

    expect(text(tester, MyAccountScreen.messageKey), 'ar myAccount.languageNeedsNetwork');
    expect(direction(tester, MyAccountScreen.messageKey), TextDirection.rtl);
    expect((await SharedPreferences.getInstance()).containsKey('language'), isFalse);
  });

  testWidgets('the password change opens from My account and goes back to it', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await openMyAccount(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.changePasswordKey)));
    expect(find.byKey(ChangePasswordScreen.currentKey), findsOneWidget);

    await act(tester, api, tester.pageBack);
    expect(find.byKey(MyAccountScreen.changePasswordKey), findsOneWidget);
  });

  Future<void> signOut(WidgetTester tester, FakeApi api) async {
    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.signOutKey)));
    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.confirmSignOutKey)));
  }

  testWidgets('signing out asks first, says what it means, and Cancel changes nothing', (tester) async {
    final api = FakeApi();
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    await openMyAccount(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.signOutKey)));
    expect(text(tester, MyAccountScreen.signOutExplainKey), 'en myAccount.signOutExplain');
    expect(find.byKey(ConfirmDialog.subjectKey), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.cancelSignOutKey)));
    expect(api.signOuts, 0);
    expect(session.isOpen, isTrue);
    expect(find.byKey(MyAccountScreen.signOutKey), findsOneWidget);
  });

  testWidgets('signing out tells the API, forgets the session, and leads to sign-in with no message', (tester) async {
    final api = FakeApi();
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    await openMyAccount(tester, api);

    await signOut(tester, api);

    expect(api.signOuts, 1);
    expect(session.isOpen, isFalse);
    expect(await const FlutterSecureStorage().read(key: 'session'), isNull);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
    expect(find.byKey(SignInScreen.messageKey), findsNothing);
  });

  testWidgets('without a network the phone still signs out', (tester) async {
    final api = FakeApi();
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    await openMyAccount(tester, api);

    api.online = false;
    await signOut(tester, api);

    expect(session.isOpen, isFalse);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
  });

  testWidgets('the chosen language stays after signing out', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await openMyAccount(tester, api);
    await choose(tester, api, MyAccountScreen.englishKey);

    await signOut(tester, api);

    expect(text(tester, SignInScreen.titleKey), 'en app.title');
    expect(direction(tester, SignInScreen.titleKey), TextDirection.ltr);
  });

  testWidgets("the next user on this phone never sees the last user's projects, even for a moment", (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));
    await signOut(tester, api);
    api.projects.clear();

    await act(tester, api, () async {
      await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
      await tester.enterText(find.byKey(SignInScreen.passwordKey), 'secret');
      await tester.tap(find.byKey(SignInScreen.submitKey));
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsNothing);
      }
    });
  });

  testWidgets('the next user signs in as themselves', (tester) async {
    final api = FakeApi()..permissions = admin;
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await openMyAccount(tester, api);
    await signOut(tester, api);

    api.permissions = [];
    await act(tester, api, () async {
      await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
      await tester.enterText(find.byKey(SignInScreen.passwordKey), 'secret');
      await tester.tap(find.byKey(SignInScreen.submitKey));
    });
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));

    expect(find.byKey(SettingsScreen.registeredKey), findsNothing);
    expect(find.byKey(SettingsScreen.myAccountKey), findsOneWidget);
  });

  for (final (language, textDirection) in [('ar', TextDirection.rtl), ('en', TextDirection.ltr)]) {
    testWidgets('AC-N03: on a phone 360 points wide in $language, every screen reads ${textDirection.name} and fits', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      void expectFits(Key key) {
        final rect = tester.getRect(find.byKey(key));
        expect(direction(tester, key), textDirection);
        expect(rect.left, greaterThanOrEqualTo(0), reason: '$key starts off the screen');
        expect(rect.right, lessThanOrEqualTo(360), reason: '$key ends off the screen');
      }

      final api = FakeApi()
        ..mustChangePassword = true
        ..permissions = admin;
      final running = api.addProject('غصون 6', units: ['الفلة الغربية', 'الفلة الجنوبية']);
      final finished = api.addProject('غصون 5', status: 'finished', units: ['الفلة الشرقية']);
      final manager = api.addUser('متعب', username: 'muteb');
      final field = api.addUser('نواف', username: 'nawaf', mobile: '0500000000');
      final disabled = api.addUser('سالم', username: 'salem', isActive: false);
      for (final (user, role) in [(manager, 'role-manager'), (field, 'role-field'), (disabled, 'role-reader')]) {
        api.giveRole(user, running['id'] as String, role);
      }
      await pumpRedix(tester, api, locale: Locale(language));
      [SignInScreen.logoKey, SignInScreen.titleKey, SignInScreen.usernameKey, SignInScreen.passwordKey, SignInScreen.submitKey, SignInScreen.registerKey].forEach(expectFits);

      await act(tester, api, () async {
        await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
        await tester.enterText(find.byKey(SignInScreen.passwordKey), 'temporary');
        await tester.tap(find.byKey(SignInScreen.submitKey));
      });
      [ChangePasswordScreen.currentKey, ChangePasswordScreen.newKey, ChangePasswordScreen.confirmKey].forEach(expectFits);
      await tester.ensureVisible(find.byKey(ChangePasswordScreen.submitKey));
      expectFits(ChangePasswordScreen.submitKey);

      await act(tester, api, () async {
        await tester.enterText(find.byKey(ChangePasswordScreen.currentKey), 'temporary');
        await tester.enterText(find.byKey(ChangePasswordScreen.newKey), 'chosen-pass');
        await tester.enterText(find.byKey(ChangePasswordScreen.confirmKey), 'chosen-pass');
        await tester.tap(find.byKey(ChangePasswordScreen.submitKey));
      });
      final runningId = running['id'] as String;
      final finishedId = finished['id'] as String;
      [
        ProjectsScreen.titleKey,
        ProjectsScreen.hintKey,
        ProjectsScreen.settingsKey,
        ProjectsScreen.openDefaultKey,
        ProjectsScreen.newProjectKey,
        ProjectsScreen.nameKey(runningId),
        ProjectsScreen.detailsKey(runningId),
        ProjectsScreen.rolesKey(runningId),
        ProjectsScreen.statusKey(runningId),
        ProjectsScreen.starKey(runningId),
        ProjectsScreen.statusKey(finishedId),
        ProjectsScreen.detailsKey(finishedId),
      ].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.newProjectKey)));
      [NewProjectScreen.nameKey, NewProjectScreen.startDateKey, NewProjectScreen.unitNameKey, NewProjectScreen.addUnitKey, NewProjectScreen.submitKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey(runningId))));
      [
        HomeScreen.titleKey,
        HomeScreen.settingsKey,
        HomeScreen.rolesKey(runningId),
        HomeScreen.detailsKey(runningId),
        HomeScreen.statusKey(runningId),
        HomeScreen.usersKey(runningId),
        HomeScreen.addUnitKey(runningId),
        HomeScreen.closeKey(runningId),
      ].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.closeKey(runningId))));
      [HomeScreen.closeExplainKey, HomeScreen.confirmCloseKey, HomeScreen.cancelCloseKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.cancelCloseKey)));

      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.usersKey(runningId))));
      [
        UsersScreen.newUserKey,
        UsersScreen.addExistingKey,
        UsersScreen.nameKey('user-0'),
        UsersScreen.menuKey('user-0'),
        UsersScreen.detailsKey('user-1'),
        UsersScreen.rolesLineKey('user-1'),
        UsersScreen.menuKey('user-1'),
        UsersScreen.statusKey('user-2'),
      ].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
      [UsersScreen.editKey, UsersScreen.rolesKey, UsersScreen.resetPasswordKey, UsersScreen.disableKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.resetPasswordKey)));
      [UsersScreen.resetExplainKey, UsersScreen.resetPasswordFieldKey, UsersScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.rolesKey)));
      [
        UserRolesScreen.nameKey,
        UserRolesScreen.hintKey,
        UserRolesScreen.roleKey('role-manager'),
        UserRolesScreen.roleKey('role-finance'),
        UserRolesScreen.roleKey('role-field'),
        UserRolesScreen.roleKey('role-reader'),
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.addExistingKey)));
      [UsersScreen.existingUsernameKey, UsersScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.newUserKey)));
      [NewUserScreen.nameKey, NewUserScreen.usernameKey, NewUserScreen.mobileKey, NewUserScreen.passwordKey].forEach(expectFits);
      await tester.ensureVisible(find.byKey(NewUserScreen.submitKey));
      expectFits(NewUserScreen.submitKey);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
      [SettingsScreen.switchProjectKey, SettingsScreen.registeredKey, SettingsScreen.myAccountKey].forEach(expectFits);
      api.addRegistered('غصون 8');
      await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.registeredKey)));
      [
        RegisteredProjectsScreen.detailsKey('registered-0'),
        RegisteredProjectsScreen.managerKey('registered-0'),
        RegisteredProjectsScreen.approveKey('registered-0'),
        RegisteredProjectsScreen.rejectKey('registered-0'),
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(RegisteredProjectsScreen.rejectKey('registered-0'))));
      [RegisteredProjectsScreen.reasonKey, RegisteredProjectsScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));
      [MyAccountScreen.arabicKey, MyAccountScreen.englishKey, MyAccountScreen.changePasswordKey, MyAccountScreen.signOutKey].forEach(expectFits);
    });
  }
}
