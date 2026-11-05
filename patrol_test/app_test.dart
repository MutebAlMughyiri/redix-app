import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/main.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/users/new_user_screen.dart';
import 'package:redix/users/users_screen.dart';
import 'package:redix/words/app_language.dart';

/// The test's admin, created by the API with a temporary password.
const username = String.fromEnvironment('TEST_USERNAME');
const temporaryPassword = String.fromEnvironment('TEST_PASSWORD');
const newPassword = String.fromEnvironment('TEST_NEW_PASSWORD');

void main() {
  patrolTest('a project is registered, approved and managed; a new user sees it by role', ($) async {
    final session = Session();
    final language = AppLanguage();
    await session.restore();
    await language.restore();
    await $.pumpWidgetAndSettle(RedixApp(session: session, language: language));
    await $(SignInScreen.usernameKey).waitUntilVisible();
    final logo = find.byKey(SignInScreen.logoKey);
    await precacheImage($.tester.widget<Image>(logo).image, $.tester.element(logo));
    await $.pumpAndSettle();
    expect($.tester.widget<RawImage>(find.descendant(of: logo, matching: find.byType(RawImage))).image, isNotNull);
    await $.takeNativeScreenshot('sign-in');

    Finder keyStartingWith(String start) => find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith(start));

    await $(SignInScreen.registerKey).scrollTo().tap();
    await $(NewProjectScreen.nameKey).enterText('غصون 7');
    await $(NewProjectScreen.unitNameKey).enterText('الفلة الشرقية');
    await $(NewProjectScreen.addUnitKey).tap();
    await $(NewProjectScreen.unitNameKey).enterText('الفلة الشمالية');
    await $(NewProjectScreen.addUnitKey).tap();
    await $(NewProjectScreen.managerNameKey).scrollTo().enterText('ريم');
    await $(NewProjectScreen.usernameKey).scrollTo().enterText('patrol-reem');
    await $(NewProjectScreen.mobileKey).scrollTo().enterText('0511111111');
    await $(NewProjectScreen.passwordKey).scrollTo().enterText('Reem-chosen-1');
    await $.takeNativeScreenshot('register-project');
    await $(NewProjectScreen.submitKey).scrollTo().tap();

    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $(SignInScreen.usernameKey).enterText('patrol-reem');
    await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
    await $(SignInScreen.submitKey).scrollTo().tap();
    await $(keyStartingWith('projects.status.')).waitUntilVisible();
    expect($(keyStartingWith('projects.star.')), findsNothing);
    await $.takeNativeScreenshot('project-waiting');
    await $(keyStartingWith('projects.card.')).tap();
    expect($(ProjectsScreen.titleKey), findsOneWidget);
    await $(ProjectsScreen.settingsKey).tap();
    expect($(SettingsScreen.registeredKey), findsNothing);
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.confirmSignOutKey).tap();

    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $(SignInScreen.usernameKey).enterText(username);
    await $(SignInScreen.passwordKey).enterText(temporaryPassword);
    await $(SignInScreen.submitKey).scrollTo().tap();
    await $(ChangePasswordScreen.currentKey).waitUntilVisible();
    await $.takeNativeScreenshot('change-password');

    await $(ChangePasswordScreen.currentKey).enterText(temporaryPassword);
    await $(ChangePasswordScreen.newKey).enterText(newPassword);
    await $(ChangePasswordScreen.confirmKey).enterText(newPassword);
    await $(ChangePasswordScreen.submitKey).scrollTo().tap();
    await $(ProjectsScreen.titleKey).waitUntilVisible();

    await $(ProjectsScreen.settingsKey).tap();
    await $(SettingsScreen.registeredKey).waitUntilVisible();
    await $.takeNativeScreenshot('settings');
    await $(SettingsScreen.registeredKey).tap();
    await $(keyStartingWith('registered.approve.')).waitUntilVisible();
    await $.takeNativeScreenshot('registered-projects');
    await $(keyStartingWith('registered.approve.')).tap();
    await $(RegisteredProjectsScreen.emptyKey).waitUntilVisible();
    await $(BackButton).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.confirmSignOutKey).tap();

    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $(SignInScreen.usernameKey).enterText('patrol-reem');
    await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
    await $(SignInScreen.submitKey).scrollTo().tap();
    await $(keyStartingWith('projects.card.')).waitUntilVisible();
    expect($(keyStartingWith('home.users.')), findsNothing);
    await $(keyStartingWith('projects.card.')).tap();

    final projectUsers = $(keyStartingWith('home.users.'));
    await projectUsers.waitUntilVisible();
    expect($(keyStartingWith('home.addUnit.')), findsNothing);
    await projectUsers.tap();
    await $(keyStartingWith('users.menu.')).waitUntilVisible();
    await $(keyStartingWith('users.menu.')).tap();
    await $(UsersScreen.rolesKey).tap();
    await $(keyStartingWith('userRoles.role.')).at(1).waitUntilVisible();
    await $(keyStartingWith('userRoles.role.')).at(1).tap();
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('user-roles');
    await $(BackButton).tap();
    await $(BackButton).tap();

    final addUnit = $(keyStartingWith('home.addUnit.'));
    await addUnit.waitUntilVisible();
    expect($(find.text('الفلة الشرقية')), findsOneWidget);
    expect($(find.text('الفلة الشمالية')), findsOneWidget);
    await addUnit.tap();
    await $(HomeScreen.unitNameKey).enterText('الفلة الغربية');
    await $(HomeScreen.saveUnitKey).tap();
    await $(find.text('الفلة الغربية')).waitUntilVisible();
    await $.takeNativeScreenshot('home');

    await $(keyStartingWith('home.close.')).tap();
    await $(HomeScreen.confirmCloseKey).waitUntilVisible();
    await $.takeNativeScreenshot('close-project');
    await $(HomeScreen.cancelCloseKey).tap();
    expect($(keyStartingWith('home.close.')), findsOneWidget);

    await $(keyStartingWith('home.close.')).tap();
    await $(HomeScreen.confirmCloseKey).tap();
    await $.pumpAndSettle();
    expect($(keyStartingWith('home.close.')), findsNothing);
    expect($(keyStartingWith('home.addUnit.')), findsNothing);

    await projectUsers.tap();
    await $(keyStartingWith('users.menu.')).waitUntilVisible();

    await $(UsersScreen.newUserKey).tap();
    await $(NewUserScreen.nameKey).enterText('نواف');
    await $(NewUserScreen.usernameKey).enterText('patrol-nawaf');
    await $(NewUserScreen.mobileKey).enterText('0500000000');
    await $(NewUserScreen.passwordKey).enterText('Temporary-1');
    await $.takeNativeScreenshot('new-user');
    await $(NewUserScreen.submitKey).scrollTo().tap();
    await $(find.text('نواف')).waitUntilVisible();
    await $.takeNativeScreenshot('users');

    final newUserMenu = $(keyStartingWith('users.menu.')).last;
    await newUserMenu.tap();
    await $(UsersScreen.editKey).tap();
    await $(UsersScreen.editNameKey).enterText('نواف الأول');
    await $(UsersScreen.saveKey).tap();
    await $(find.text('نواف الأول')).waitUntilVisible();

    await newUserMenu.tap();
    await $(UsersScreen.resetPasswordKey).tap();
    await $(UsersScreen.resetPasswordFieldKey).enterText('Temporary-2');
    await $(UsersScreen.saveKey).tap();
    await $.pumpAndSettle();

    await newUserMenu.tap();
    await $(UsersScreen.disableKey).tap();
    await $(UsersScreen.confirmDisableKey).tap();
    await $(keyStartingWith('users.status.')).last.waitUntilVisible();
    await newUserMenu.tap();
    await $(UsersScreen.enableKey).tap();
    await $.pumpAndSettle();

    await newUserMenu.tap();
    await $(UsersScreen.rolesKey).tap();
    await $(keyStartingWith('userRoles.role.')).at(2).waitUntilVisible();
    await $(keyStartingWith('userRoles.role.')).at(2).tap();
    await $.pumpAndSettle();
    await $(keyStartingWith('userRoles.role.')).at(3).tap();
    await $.pumpAndSettle();
    await $(BackButton).tap();
    await $.pumpAndSettle();

    await $(BackButton).tap();
    await projectUsers.waitUntilVisible();
    await $(BackButton).tap();
    await $(keyStartingWith('projects.star.')).tap();
    await $(Icons.star).waitUntilVisible();
    await $(ProjectsScreen.openDefaultKey).tap();
    await $(find.byWidgetPredicate((widget) => widget is SwitchListTile && widget.value)).waitUntilVisible();
    await $.takeNativeScreenshot('projects');

    await $(ProjectsScreen.settingsKey).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.arabicKey).waitUntilVisible();
    await $.takeNativeScreenshot('my-account');

    await $(MyAccountScreen.arabicKey).tap();
    await $.pumpAndSettle();
    expect(Directionality.of($.tester.element(find.byKey(MyAccountScreen.arabicKey))), TextDirection.rtl);
    await $.takeNativeScreenshot('my-account-arabic');

    await $(BackButton).tap();
    await $(SettingsScreen.switchProjectKey).tap();
    await $(keyStartingWith('projects.status.')).waitUntilVisible();
    expect(Directionality.of($.tester.element(keyStartingWith('projects.status.'))), TextDirection.rtl);
    await $.takeNativeScreenshot('projects-arabic');
    await $(keyStartingWith('projects.card.')).tap();
    await projectUsers.tap();
    await $(keyStartingWith('users.menu.')).waitUntilVisible();
    await $.takeNativeScreenshot('users-arabic');
    await $(BackButton).tap();
    await projectUsers.waitUntilVisible();
    await $(BackButton).tap();
    await $(ProjectsScreen.settingsKey).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.englishKey).waitUntilVisible();

    await $(MyAccountScreen.englishKey).tap();
    await $.pumpAndSettle();
    expect(Directionality.of($.tester.element(find.byKey(MyAccountScreen.englishKey))), TextDirection.ltr);

    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.cancelSignOutKey).tap();
    expect($(MyAccountScreen.signOutKey), findsOneWidget);
    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.confirmSignOutKey).tap();

    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $(SignInScreen.usernameKey).enterText('patrol-reem');
    await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
    await $(SignInScreen.submitKey).scrollTo().tap();
    await $(HomeScreen.titleKey).waitUntilVisible();
    await $(find.text('غصون 7')).waitUntilVisible();
    expect($(BackButton), findsNothing);
    await $(HomeScreen.settingsKey).tap();
    await $(SettingsScreen.switchProjectKey).tap();
    await $(ProjectsScreen.titleKey).waitUntilVisible();
    await $(ProjectsScreen.settingsKey).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.confirmSignOutKey).tap();

    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $(SignInScreen.usernameKey).enterText('patrol-nawaf');
    await $(SignInScreen.passwordKey).enterText('Temporary-2');
    await $(SignInScreen.submitKey).scrollTo().tap();
    await $(ChangePasswordScreen.currentKey).enterText('Temporary-2');
    await $(ChangePasswordScreen.newKey).enterText('Nawaf-chosen-1');
    await $(ChangePasswordScreen.confirmKey).enterText('Nawaf-chosen-1');
    await $(ChangePasswordScreen.submitKey).scrollTo().tap();

    await $(ProjectsScreen.settingsKey).tap();
    await $(SettingsScreen.myAccountKey).waitUntilVisible();
    expect($(SettingsScreen.registeredKey), findsNothing);
    await $(SettingsScreen.switchProjectKey).tap();
    await $(keyStartingWith('projects.card.')).waitUntilVisible();
    expect($(ProjectsScreen.newProjectKey), findsOneWidget);
    await $(keyStartingWith('projects.card.')).tap();
    await $(keyStartingWith('home.roles.')).waitUntilVisible();
    expect($(keyStartingWith('home.users.')), findsNothing);
    expect($(keyStartingWith('home.addUnit.')), findsNothing);
    expect($(keyStartingWith('home.close.')), findsNothing);
  });
}
