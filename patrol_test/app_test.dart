import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/main.dart';

/// The test owner, created by the API with a temporary password.
const username = String.fromEnvironment('TEST_USERNAME');
const temporaryPassword = String.fromEnvironment('TEST_PASSWORD');
const newPassword = String.fromEnvironment('TEST_NEW_PASSWORD');

void main() {
  patrolTest('a new user signs in, must change the temporary password, and lands on home', ($) async {
    final session = Session();
    await session.restore();
    await $.pumpWidgetAndSettle(RedixApp(session: session));
    await $(SignInScreen.usernameKey).waitUntilVisible();
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
  });
}
