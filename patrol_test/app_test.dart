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
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/words/app_language.dart';

/// The test owner, created by the API with a temporary password.
const username = String.fromEnvironment('TEST_USERNAME');
const temporaryPassword = String.fromEnvironment('TEST_PASSWORD');
const newPassword = String.fromEnvironment('TEST_NEW_PASSWORD');

void main() {
  patrolTest('a new user signs in, must change the temporary password, lands on home, manages a project, and switches the language', ($) async {
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

    await $(SignInScreen.usernameKey).enterText(username);
    await $(SignInScreen.passwordKey).enterText(temporaryPassword);
    await $(SignInScreen.submitKey).tap();
    await $(ChangePasswordScreen.currentKey).waitUntilVisible();
    await $.takeNativeScreenshot('change-password');

    await $(ChangePasswordScreen.currentKey).enterText(temporaryPassword);
    await $(ChangePasswordScreen.newKey).enterText(newPassword);
    await $(ChangePasswordScreen.confirmKey).enterText(newPassword);
    await $(ChangePasswordScreen.submitKey).tap();
    await $(HomeScreen.titleKey).waitUntilVisible();

    expect($(HomeScreen.subtitleKey), findsOneWidget);
    await $.takeNativeScreenshot('home');

    Finder keyStartingWith(String start) => find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith(start));

    await $(HomeScreen.settingsKey).tap();
    await $(SettingsScreen.projectsKey).waitUntilVisible();
    await $.takeNativeScreenshot('settings');

    await $(SettingsScreen.projectsKey).tap();
    await $(ProjectsScreen.emptyKey).waitUntilVisible();

    await $(ProjectsScreen.newProjectKey).tap();
    await $(NewProjectScreen.nameKey).enterText('غصون 7');
    await $(NewProjectScreen.unitNameKey).enterText('الفلة الشرقية');
    await $(NewProjectScreen.addUnitKey).tap();
    await $(NewProjectScreen.unitNameKey).enterText('الفلة الشمالية');
    await $(NewProjectScreen.addUnitKey).tap();
    await $.takeNativeScreenshot('new-project');
    await $(NewProjectScreen.submitKey).scrollTo().tap();

    final addUnit = $(keyStartingWith('projects.addUnit.'));
    await addUnit.waitUntilVisible();
    expect($(find.text('الفلة الشرقية')), findsOneWidget);
    expect($(find.text('الفلة الشمالية')), findsOneWidget);
    await addUnit.tap();
    await $(ProjectsScreen.unitNameKey).enterText('الفلة الغربية');
    await $(ProjectsScreen.saveUnitKey).tap();
    await $(find.text('الفلة الغربية')).waitUntilVisible();
    await $.takeNativeScreenshot('projects');

    await $(keyStartingWith('projects.close.')).tap();
    await $(ProjectsScreen.confirmCloseKey).waitUntilVisible();
    await $.takeNativeScreenshot('close-project');
    await $(ProjectsScreen.cancelCloseKey).tap();
    expect($(keyStartingWith('projects.close.')), findsOneWidget);

    await $(keyStartingWith('projects.close.')).tap();
    await $(ProjectsScreen.confirmCloseKey).tap();
    await $.pumpAndSettle();
    expect($(keyStartingWith('projects.close.')), findsNothing);
    expect($(keyStartingWith('projects.addUnit.')), findsNothing);

    await $(BackButton).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.arabicKey).waitUntilVisible();
    await $.takeNativeScreenshot('my-account');

    await $(MyAccountScreen.arabicKey).tap();
    await $.pumpAndSettle();
    expect(Directionality.of($.tester.element(find.byKey(MyAccountScreen.arabicKey))), TextDirection.rtl);
    await $.takeNativeScreenshot('my-account-arabic');

    await $(BackButton).tap();
    await $(SettingsScreen.projectsKey).tap();
    await $(keyStartingWith('projects.status.')).waitUntilVisible();
    expect(Directionality.of($.tester.element(keyStartingWith('projects.status.'))), TextDirection.rtl);
    await $.takeNativeScreenshot('projects-arabic');
    await $(BackButton).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.englishKey).waitUntilVisible();

    await $(MyAccountScreen.englishKey).tap();
    await $.pumpAndSettle();
    expect(Directionality.of($.tester.element(find.byKey(MyAccountScreen.englishKey))), TextDirection.ltr);
  });
}
