import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';

import '../app_harness.dart';
import 'package:redix/ui/confirm_dialog.dart';

void main() {
  String message(WidgetTester tester) => tester.widget<Text>(find.byKey(SignInScreen.messageKey)).data!;

  FakeApi apiWithBiometrics() => FakeApi()..usesBiometrics = true;

  Future<void> signInWithPassword(WidgetTester tester, FakeApi api) => act(tester, api, () async {
    await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
    await tester.enterText(find.byKey(SignInScreen.passwordKey), 'secret');
    await tester.tap(find.byKey(SignInScreen.submitKey));
  });

  testWidgets('AC-35.1: with it on, opening the app asks, and a pass opens the kept session with no password', (tester) async {
    final prompt = FakePrompt();
    await pumpRedix(tester, apiWithBiometrics(), stored: {'session': keptBiometricSession}, prompt: prompt);

    expect(prompt.shown, 1);
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
    expect(find.byKey(SignInScreen.usernameKey), findsNothing);
  });

  testWidgets('the prompt speaks the app\'s words, and only a strong biometric passes', (tester) async {
    final prompt = FakePrompt();
    await pumpRedix(tester, apiWithBiometrics(), locale: const Locale('ar'), stored: {'session': keptBiometricSession}, prompt: prompt);

    expect(prompt.options['biometricPromptTitle'], 'ar biometrics.promptTitle');
    expect(prompt.options['biometricPromptSubtitle'], 'ar biometrics.signIn');
    expect(prompt.options['biometricPromptNegativeButton'], 'ar biometrics.promptCancel');
    expect(prompt.options['biometricType'], 'strongBiometricOnly');
    expect(prompt.options['enforceBiometrics'], 'true');
  });

  testWidgets('until it passes the session stays closed, and nothing is sent', (tester) async {
    final api = apiWithBiometrics();
    final session = await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: FakePrompt()..neverAnswers = true);

    expect(session.isOpen, isFalse);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
    expect(find.byKey(SignInScreen.unlockKey), findsOneWidget);
    expect(find.byKey(SignInScreen.orKey), findsOneWidget);
    expect(api.sentAccessTokens, isEmpty);
  });

  testWidgets('with it off, opening the app asks nothing and shows no button', (tester) async {
    final prompt = FakePrompt();
    await pumpRedix(tester, FakeApi(), stored: {'session': keptSession}, prompt: prompt);

    expect(prompt.shown, 0);
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('with no session at all, the sign-in page asks nothing and shows no button', (tester) async {
    final prompt = FakePrompt();
    await pumpRedix(tester, FakeApi(), prompt: prompt);

    expect(prompt.shown, 0);
    expect(find.byKey(SignInScreen.unlockKey), findsNothing);
    expect(find.byKey(SignInScreen.orKey), findsNothing);
  });

  testWidgets('a pass lands where the person chose to land', (tester) async {
    final api = apiWithBiometrics()
      ..defaultProjectId = 'project-0'
      ..addProject('غصون 6');
    const kept = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false, "usesBiometrics": true, "defaultProjectId": "project-0"}';

    await pumpRedix(tester, api, stored: {'session': kept}, prompt: FakePrompt());

    expect(tester.widget<Text>(find.byKey(HomeScreen.titleKey)).data, 'غصون 6');
  });

  testWidgets('a failed try says so, and the button tries again', (tester) async {
    final api = apiWithBiometrics();
    final prompt = FakePrompt()..fails = true;
    await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: prompt);
    expect(message(tester), 'en biometrics.failed');

    prompt.fails = false;
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.unlockKey)));

    expect(prompt.shown, 2);
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('AC-35.2: after ${Session.maxUnlockAttempts} failed tries only the password remains', (tester) async {
    final api = apiWithBiometrics();
    final prompt = FakePrompt()..fails = true;
    await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: prompt);

    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.unlockKey)));
    expect(message(tester), 'en biometrics.failed');
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.unlockKey)));

    expect(prompt.shown, Session.maxUnlockAttempts);
    expect(message(tester), 'en biometrics.usePassword');
    expect(find.byKey(SignInScreen.unlockKey), findsNothing);
    expect(find.byKey(SignInScreen.orKey), findsNothing);
    expect(find.byKey(SignInScreen.passwordKey), findsOneWidget);
  });

  testWidgets('AC-35.2: with a new fingerprint on the phone the check can never pass, even with the new finger', (tester) async {
    final prompt = FakePrompt()..answer = null;
    final session = await pumpRedix(tester, apiWithBiometrics(), stored: {'session': keptBiometricSession}, prompt: prompt);

    expect(session.isOpen, isFalse);
    expect(message(tester), 'en biometrics.failed');
    expect(find.byKey(SignInScreen.passwordKey), findsOneWidget);
  });

  testWidgets('a prompt with no answer leaves the password form working', (tester) async {
    final api = apiWithBiometrics();
    await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: FakePrompt()..neverAnswers = true);

    await signInWithPassword(tester, api);

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('a prompt with no answer counts as a try, so the button still goes after ${Session.maxUnlockAttempts}', (tester) async {
    final api = apiWithBiometrics();
    await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: FakePrompt()..neverAnswers = true);

    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.unlockKey)));
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.unlockKey)));

    expect(find.byKey(SignInScreen.unlockKey), findsNothing);
  });

  testWidgets('signing in with the password starts with it off, so the next person does not inherit it', (tester) async {
    final api = apiWithBiometrics();
    final prompt = FakePrompt()..fails = true;
    final session = await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: prompt);

    await signInWithPassword(tester, api);

    expect(session.usesBiometrics, isFalse);
    expect(await const FlutterSecureStorage().read(key: 'session'), contains('"usesBiometrics": false'));
  });

  testWidgets('renewals never ask: the new tokens are kept with no prompt', (tester) async {
    final api = apiWithBiometrics();
    final prompt = FakePrompt();
    final session = await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: prompt);
    expect(await const FlutterSecureStorage().read(key: 'session'), contains('new-access'));

    await act(tester, api, () => session.setDefaultProject('project-0'));

    expect(prompt.shown, 1);
    expect(await const FlutterSecureStorage().read(key: 'session'), contains('new-refresh'));
    expect(session.usesBiometrics, isTrue);
  });

  testWidgets('without a network a pass still opens the kept session', (tester) async {
    final api = apiWithBiometrics()..online = false;
    final session = await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, preferences: keptWords('en'), prompt: FakePrompt());

    expect(session.isOpen, isTrue);
    expect(await const FlutterSecureStorage().read(key: 'session'), contains('kept-access'));
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('a session ended on the server ends on sign-in after the pass, saying so', (tester) async {
    final api = apiWithBiometrics()..refreshStatus = 401;
    final session = await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: FakePrompt());

    expect(session.isOpen, isFalse);
    expect(session.usesBiometrics, isFalse);
    expect(message(tester), 'en signIn.sessionExpired');
    expect(find.byKey(SignInScreen.unlockKey), findsNothing);
    expect(await const FlutterSecureStorage().read(key: 'session'), isNull);
  });

  testWidgets('signing out ends it: the phone keeps nothing that asks again', (tester) async {
    final api = apiWithBiometrics();
    final prompt = FakePrompt();
    await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: prompt);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));

    await scrollAndTap(tester, api, SettingsScreen.signOutKey);
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(find.byKey(SignInScreen.unlockKey), findsNothing);
    expect(await const FlutterSecureStorage().read(key: 'session'), isNull);
    expect(prompt.shown, 1);
  });

  testWidgets('AC-N03: the page with the button fits a phone 360 points wide, in both languages', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.reset);
    for (final (language, direction) in [('ar', TextDirection.rtl), ('en', TextDirection.ltr)]) {
      await pumpRedix(tester, apiWithBiometrics(), locale: Locale(language), stored: {'session': keptBiometricSession}, prompt: FakePrompt()..fails = true);
      final button = tester.getRect(find.byKey(SignInScreen.unlockKey));
      expect(button.left, greaterThanOrEqualTo(0));
      expect(button.right, lessThanOrEqualTo(360));
      expect(Directionality.of(tester.element(find.byKey(SignInScreen.unlockKey))), direction);
      expect(tester.takeException(), isNull);
    }
  });
}
