import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/forgot_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Future<void> openForgotPassword(WidgetTester tester, FakeApi api, {Locale locale = const Locale('en')}) async {
    await pumpRedix(tester, api, locale: locale);
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.forgotKey)));
  }

  Future<void> askCode(WidgetTester tester, FakeApi api, String login) => act(tester, api, () async {
    await tester.enterText(find.byKey(ForgotPasswordScreen.loginKey), login);
    await tester.tap(find.byKey(ForgotPasswordScreen.sendKey));
  });

  Future<void> reset(WidgetTester tester, FakeApi api, {String code = '482913', String password = 'Remembered-2', String again = 'Remembered-2'}) => act(tester, api, () async {
    await tester.enterText(find.byKey(ForgotPasswordScreen.codeKey), code);
    await tester.enterText(find.byKey(ForgotPasswordScreen.newKey), password);
    await tester.enterText(find.byKey(ForgotPasswordScreen.confirmKey), again);
    await tester.ensureVisible(find.byKey(ForgotPasswordScreen.resetKey));
    await tester.tap(find.byKey(ForgotPasswordScreen.resetKey));
  });

  testWidgets('redix-api #127 AC-02.6: «نسيت كلمة المرور؟» on sign-in opens the reset without a session, and the link names it', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api);

    expect(text(tester, SignInScreen.forgotKey.label), 'en auth.forgotPassword');
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.forgotKey)));

    expect(find.byKey(ForgotPasswordScreen.loginKey), findsOneWidget);
    expect(find.byKey(SignInScreen.usernameKey), findsNothing);
  });

  testWidgets('redix-api #127 AC-02.6, AC-02.10: the code is asked for the username or email typed, in the language the phone is in', (tester) async {
    final api = FakeApi();
    await openForgotPassword(tester, api, locale: const Locale('ar'));

    await askCode(tester, api, ' muteb@example.com ');

    final sent = api.sentCodeRequests.single;
    expect([sent.$1, sent.$2, sent.$3], ['/auth/forgot-password', {'login': 'muteb@example.com'}, 'ar']);
  });

  testWidgets('redix-api #127 AC-02.7: once asked, one sentence says a code went to the email if the account has one, then the code and the new password are asked; not before', (tester) async {
    final api = FakeApi();
    await openForgotPassword(tester, api);
    expect(find.byKey(ForgotPasswordScreen.sentKey), findsNothing);
    expect(find.byKey(ForgotPasswordScreen.codeKey), findsNothing);

    await askCode(tester, api, 'muteb');

    expect(text(tester, ForgotPasswordScreen.sentKey), 'en auth.codeSent');
    expect(find.byKey(ForgotPasswordScreen.codeKey), findsOneWidget);
    expect(find.byKey(ForgotPasswordScreen.messageKey), findsNothing);
  });

  testWidgets('redix-api #127 AC-02.6: the code and a new password typed twice change it, back on sign-in saying so', (tester) async {
    final api = FakeApi();
    await openForgotPassword(tester, api);
    await askCode(tester, api, 'muteb');

    await reset(tester, api);

    final sent = api.sentCodeRequests.last;
    expect([sent.$1, sent.$2], ['/auth/reset-with-code', {'login': 'muteb', 'code': '482913', 'newPassword': 'Remembered-2'}]);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
    expect(text(tester, messageKeyOf('auth.passwordReset').label), 'en auth.passwordReset');
  });

  testWidgets('redix-api #127: new passwords that differ send nothing and say so', (tester) async {
    final api = FakeApi();
    await openForgotPassword(tester, api);
    await askCode(tester, api, 'muteb');

    await reset(tester, api, again: 'Remembered-3');

    expect(api.sentCodeRequests.map((sent) => sent.$1), ['/auth/forgot-password']);
    expect(text(tester, ForgotPasswordScreen.messageKey), 'en changePassword.mismatch');
    expectErrorAbove(tester, ForgotPasswordScreen.messageKey, ForgotPasswordScreen.loginKey);
  });

  testWidgets('redix-api #127 AC-02.8: a wrong or spent code, and a weak password, are refused with their words and the screen stays', (tester) async {
    final api = FakeApi()..codeAnswers['/auth/reset-with-code'] = (status: 400, code: 'codeWrong');
    await openForgotPassword(tester, api);
    await askCode(tester, api, 'muteb');

    await reset(tester, api);
    expect(text(tester, ForgotPasswordScreen.messageKey), 'en auth.codeWrong');

    api.codeAnswers['/auth/reset-with-code'] = (status: 400, code: 'weakPassword');
    await reset(tester, api, password: 'short', again: 'short');
    expect(text(tester, ForgotPasswordScreen.messageKey), 'en auth.weakPassword');
    expect(find.byKey(ForgotPasswordScreen.resetKey), findsOneWidget);
  });

  testWidgets('redix-api #127 AC-02.8, D4: asking too often is refused for a while, and says so without the code fields', (tester) async {
    final api = FakeApi()..codeAnswers['/auth/forgot-password'] = (status: 429, code: '');
    await openForgotPassword(tester, api);

    await askCode(tester, api, 'muteb');

    expect(text(tester, ForgotPasswordScreen.messageKey), 'en auth.tooManyRequests');
    expect(find.byKey(ForgotPasswordScreen.codeKey), findsNothing);
  });

  testWidgets('redix-api #127: without a network asking says so', (tester) async {
    final api = FakeApi();
    await openForgotPassword(tester, api);

    api.online = false;
    await askCode(tester, api, 'muteb');

    expect(text(tester, ForgotPasswordScreen.messageKey), 'en auth.noConnection');
    expect(find.byKey(ForgotPasswordScreen.sentKey), findsNothing);
  });
}
