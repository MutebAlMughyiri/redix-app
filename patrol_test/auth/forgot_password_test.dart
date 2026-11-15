import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/forgot_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Opens «نسيت كلمة المرور؟» from the sign-in screen and asks a code for [login].
Future<void> askCode(PatrolIntegrationTester $, String login) async {
  await $.startApp();
  await $.tapOn(SignInScreen.forgotKey);
  await $.fill(ForgotPasswordScreen.loginKey, login);
  await $.tapOn(ForgotPasswordScreen.sendKey);
  await $.answered(ForgotPasswordScreen.sendKey);
}

void main() {
  phoneClass('Forgot password (UC-002, redix-api #127)', () {
    phoneCase('AC-02.6: «نسيت كلمة المرور؟» opens the reset, and asking a code for an account says the one sentence and asks the code and the new password', ($) async {
      final manager = await Given.manager();
      await askCode($, manager.username);
      await $.says(ForgotPasswordScreen.sentKey, $.words.authCodeSent);
      await $.reach($(ForgotPasswordScreen.codeKey));
      await $.picture('forgot-password');
    });

    phoneCase('AC-02.7: an unknown username is answered with that same sentence', ($) async {
      await askCode($, 'nobody-${Given.unique()}');
      await $.says(ForgotPasswordScreen.sentKey, $.words.authCodeSent);
      expect($(ForgotPasswordScreen.messageKey), findsNothing);
    });

    phoneCase('AC-02.8: a wrong code is refused with its word, and the screen stays', ($) async {
      final manager = await Given.manager();
      await askCode($, manager.username);
      await $.fill(ForgotPasswordScreen.codeKey, '000000');
      await $.fill(ForgotPasswordScreen.newKey, 'Remembered-2');
      await $.fill(ForgotPasswordScreen.confirmKey, 'Remembered-2');
      await $.tapOn(ForgotPasswordScreen.resetKey);
      await $.says(ForgotPasswordScreen.messageKey, $.words.authCodeWrong);
      expect($(ForgotPasswordScreen.resetKey), findsOneWidget);
    });

    phoneCase('new passwords that differ are refused before anything is sent', ($) async {
      final manager = await Given.manager();
      await askCode($, manager.username);
      await $.fill(ForgotPasswordScreen.codeKey, '000000');
      await $.fill(ForgotPasswordScreen.newKey, 'Remembered-2');
      await $.fill(ForgotPasswordScreen.confirmKey, 'Remembered-3');
      await $.tapOn(ForgotPasswordScreen.resetKey);
      await $.says(ForgotPasswordScreen.messageKey, $.words.changePasswordMismatch);
    });
  });
}
