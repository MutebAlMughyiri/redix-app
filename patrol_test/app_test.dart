import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/main.dart';

const username = String.fromEnvironment('TEST_USERNAME');
const password = String.fromEnvironment('TEST_PASSWORD');

void main() {
  patrolTest('a user signs in with the real API and lands on home', ($) async {
    final session = Session();
    await session.restore();
    await $.pumpWidgetAndSettle(RedixApp(session: session));
    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $.takeNativeScreenshot('sign-in');

    await $(SignInScreen.usernameKey).enterText(username);
    await $(SignInScreen.passwordKey).enterText(password);
    await $(SignInScreen.submitKey).tap();
    await $(HomeScreen.titleKey).waitUntilVisible();

    expect($(HomeScreen.subtitleKey), findsOneWidget);
    await $.takeNativeScreenshot('home');
  });
}
