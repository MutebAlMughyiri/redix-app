import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  TextDirection direction(WidgetTester tester, Key key) => Directionality.of(tester.element(find.byKey(key)));

  Future<void> openMyAccount(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byKey(HomeScreen.myAccountKey)));

  Future<void> choose(WidgetTester tester, FakeApi api, Key language) => act(tester, api, () => tester.tap(find.byKey(language)));

  testWidgets('choosing English on an Arabic phone switches every screen to English, left to right', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await openMyAccount(tester, api);

    await choose(tester, api, MyAccountScreen.englishKey);

    expect(text(tester, MyAccountScreen.englishKey), 'en myAccount.english');
    expect(direction(tester, MyAccountScreen.englishKey), TextDirection.ltr);
    await act(tester, api, tester.pageBack);
    expect(text(tester, HomeScreen.subtitleKey), 'en app.subtitle');
    expect(direction(tester, HomeScreen.subtitleKey), TextDirection.ltr);
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

    expect(text(tester, HomeScreen.subtitleKey), 'en app.subtitle');
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

      final api = FakeApi()..mustChangePassword = true;
      await pumpRedix(tester, api, locale: Locale(language));
      [SignInScreen.logoKey, SignInScreen.titleKey, SignInScreen.usernameKey, SignInScreen.passwordKey, SignInScreen.submitKey].forEach(expectFits);

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
      [HomeScreen.titleKey, HomeScreen.subtitleKey, HomeScreen.myAccountKey].forEach(expectFits);

      await openMyAccount(tester, api);
      [MyAccountScreen.arabicKey, MyAccountScreen.englishKey, MyAccountScreen.changePasswordKey].forEach(expectFits);
    });
  }
}
