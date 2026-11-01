import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';

import '../app_harness.dart';

void main() {
  String message(WidgetTester tester) => tester.widget<Text>(find.byKey(ChangePasswordScreen.messageKey)).data!;

  Future<void> change(WidgetTester tester, FakeApi api, {String current = 'temporary', String newPassword = 'chosen-pass', String? confirm}) =>
      act(tester, api, () async {
        await tester.enterText(find.byKey(ChangePasswordScreen.currentKey), current);
        await tester.enterText(find.byKey(ChangePasswordScreen.newKey), newPassword);
        await tester.enterText(find.byKey(ChangePasswordScreen.confirmKey), confirm ?? newPassword);
        await tester.tap(find.byKey(ChangePasswordScreen.submitKey));
      });

  testWidgets('signing in with a temporary password leads straight to the password change', (tester) async {
    final api = FakeApi()..mustChangePassword = true;
    await pumpRedix(tester, api);

    await act(tester, api, () async {
      await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
      await tester.enterText(find.byKey(SignInScreen.passwordKey), 'temporary');
      await tester.tap(find.byKey(SignInScreen.submitKey));
    });

    expect(find.byKey(ChangePasswordScreen.currentKey), findsOneWidget);
  });

  testWidgets('the password change cannot be skipped while the password is temporary', (tester) async {
    final api = FakeApi()..mustChangePassword = true;
    await pumpRedix(tester, api, stored: {'session': keptTemporarySession});

    await act(tester, api, () async => GoRouter.of(tester.element(find.byKey(ChangePasswordScreen.currentKey))).go(HomeScreen.path));

    expect(find.byKey(ChangePasswordScreen.currentKey), findsOneWidget);
    expect(find.byKey(HomeScreen.titleKey), findsNothing);
  });

  testWidgets('a changed password opens home', (tester) async {
    final api = FakeApi();
    final session = await pumpRedix(tester, api..mustChangePassword = true, stored: {'session': keptTemporarySession});

    await change(tester, api);

    expect(find.byKey(HomeScreen.titleKey), findsOneWidget);
    expect(session.mustChangePassword, isFalse);
  });

  testWidgets('new passwords that differ are caught before anything is sent', (tester) async {
    final api = FakeApi()..mustChangePassword = true;
    await pumpRedix(tester, api, stored: {'session': keptTemporarySession});

    await change(tester, api, confirm: 'something-else');

    expect(message(tester), 'en changePassword.mismatch');
    expect(api.sentAccessTokens, isEmpty);
  });

  testWidgets('a refusal from the API shows its own line', (tester) async {
    for (final code in ['invalidCredentials', 'accountLocked', 'weakPassword']) {
      final api = FakeApi()
        ..mustChangePassword = true
        ..changePasswordAnswer = (status: 400, code: code);
      await pumpRedix(tester, api, stored: {'session': keptTemporarySession});

      await change(tester, api);

      expect(message(tester), 'en changePassword.$code');
    }
  });

  testWidgets('an expired access token is renewed once and the change sent again', (tester) async {
    final api = FakeApi()
      ..mustChangePassword = true
      ..refreshStatus = 500;
    await pumpRedix(tester, api, stored: {'session': keptTemporarySession});
    api
      ..expiredAccessTokens.add('kept-access')
      ..refreshStatus = 200;

    await change(tester, api);

    expect(api.sentAccessTokens, ['kept-access', 'new-access']);
    expect(find.byKey(HomeScreen.titleKey), findsOneWidget);
  });

  testWidgets('without a network the change says there is no connection', (tester) async {
    final api = FakeApi()..mustChangePassword = true;
    await pumpRedix(tester, api, stored: {'session': keptTemporarySession});

    api.online = false;
    await change(tester, api);

    expect(message(tester), 'en changePassword.noConnection');
  });
}
