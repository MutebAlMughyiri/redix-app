import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/words/language_switch.dart';

import '../app_harness.dart';

void main() {
  String message(WidgetTester tester) => tester.widget<Text>(find.byKey(SignInScreen.messageKey)).data!;

  Future<void> signIn(WidgetTester tester, FakeApi api) => act(tester, api, () async {
    await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
    await tester.enterText(find.byKey(SignInScreen.passwordKey), 'secret');
    await tester.tap(find.byKey(SignInScreen.submitKey));
  });

  testWidgets('without a session the app opens on sign-in', (tester) async {
    await pumpRedix(tester, FakeApi());

    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
    expect(find.byKey(ProjectsScreen.titleKey), findsNothing);
  });

  testWidgets('the sign-in screen is headed with the logo, drawn from its picture, then the app name', (tester) async {
    await pumpRedix(tester, FakeApi());
    final logo = find.byKey(SignInScreen.logoKey);

    await tester.runAsync(() => precacheImage(tester.widget<Image>(logo).image, tester.element(logo)));
    await tester.pump();

    expect(tester.widget<RawImage>(find.descendant(of: logo, matching: find.byType(RawImage))).image, isNotNull);
    expect(tester.widget<Text>(find.byKey(SignInScreen.titleKey)).data, 'en app.title');
    expect(tester.getBottomLeft(logo).dy, lessThan(tester.getTopLeft(find.byKey(SignInScreen.titleKey)).dy));
  });

  testWidgets('UC-004: the language is chosen before signing in, and kept for after', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'));
    expect(tester.widget<Text>(find.byKey(SignInScreen.titleKey)).data, 'ar app.title');

    await act(tester, api, () => tester.tap(find.byKey(LanguageSwitch.englishKey)));
    expect(tester.widget<Text>(find.byKey(SignInScreen.titleKey)).data, 'en app.title');
    expect(Directionality.of(tester.element(find.byKey(SignInScreen.titleKey))), TextDirection.ltr);

    await signIn(tester, api);
    expect(tester.widget<Text>(find.byKey(ProjectsScreen.titleKey)).data, 'en projects.choose');
  });

  testWidgets('without a network the sign-in screen keeps its language and says switching needs one', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'));

    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(LanguageSwitch.englishKey)));

    expect(tester.widget<Text>(find.byKey(LanguageSwitch.messageKey)).data, 'ar myAccount.languageNeedsNetwork');
    expect(tester.widget<Text>(find.byKey(SignInScreen.titleKey)).data, 'ar app.title');
  });

  testWidgets('the right password opens home and keeps the session in secure storage', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api);

    await signIn(tester, api);

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
    expect(await const FlutterSecureStorage().read(key: 'session'), contains('new-access'));
    expect(await const FlutterSecureStorage().read(key: 'session'), contains('new-refresh'));
  });

  testWidgets('a wrong password shows one line that does not say which field was wrong', (tester) async {
    final api = FakeApi()..signInAnswer = (status: 401, code: 'invalidCredentials');
    await pumpRedix(tester, api);

    await signIn(tester, api);

    expect(message(tester), 'en signIn.invalidCredentials');
    expectErrorAbove(tester, SignInScreen.messageKey, SignInScreen.usernameKey);
    expect(find.byKey(ProjectsScreen.titleKey), findsNothing);
  });

  testWidgets('a locked account says to try again later', (tester) async {
    final api = FakeApi()..signInAnswer = (status: 401, code: 'accountLocked');
    await pumpRedix(tester, api);

    await signIn(tester, api);

    expect(message(tester), 'en signIn.accountLocked');
  });

  testWidgets('a server answer that names no refusal says the server could not sign in, never that there is no connection', (tester) async {
    final api = FakeApi()..signInAnswer = (status: 500, code: '');
    await pumpRedix(tester, api);

    await signIn(tester, api);

    expect(message(tester), 'en signIn.refused');
    expect(find.byKey(ProjectsScreen.titleKey), findsNothing);
  });

  testWidgets('without a network sign-in says there is no connection', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api);

    api.online = false;
    await signIn(tester, api);

    expect(message(tester), 'en signIn.noConnection');
  });

  testWidgets('a kept session opens home directly', (tester) async {
    await pumpRedix(tester, FakeApi(), stored: {'session': keptSession});

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('without a network a kept session stays open, so work goes on offline', (tester) async {
    await pumpRedix(tester, FakeApi()..online = false, stored: {'session': keptSession}, preferences: keptWords('en'));

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
    expect(await const FlutterSecureStorage().read(key: 'session'), keptSession);
  });

  testWidgets('a kept session the API refuses ends on sign-in, saying the session ended', (tester) async {
    await pumpRedix(tester, FakeApi()..refreshStatus = 401, stored: {'session': keptSession});

    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
    expect(message(tester), 'en signIn.sessionExpired');
    expect(await const FlutterSecureStorage().read(key: 'session'), isNull);
  });
}
