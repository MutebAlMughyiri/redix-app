import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  TextDirection direction(WidgetTester tester, Key key) => Directionality.of(tester.element(find.byKey(key)));

  Future<void> openMyAccount(WidgetTester tester, FakeApi api) async {
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));
  }

  Future<void> choose(WidgetTester tester, FakeApi api, Key language) => act(tester, api, () => tester.tap(find.byKey(language)));

  testWidgets('choosing English on an Arabic phone switches every screen to English, left to right', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await openMyAccount(tester, api);

    await choose(tester, api, MyAccountScreen.englishKey);

    expect(text(tester, MyAccountScreen.englishKey), 'en myAccount.english');
    expect(direction(tester, MyAccountScreen.englishKey), TextDirection.ltr);
    await act(tester, api, tester.pageBack);
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

      final api = FakeApi()
        ..mustChangePassword = true
        ..isOwner = true;
      final running = api.addProject('غصون 6', units: ['الفلة الغربية', 'الفلة الجنوبية']);
      final finished = api.addProject('غصون 5', status: 'finished', units: ['الفلة الشرقية']);
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
      [HomeScreen.titleKey, HomeScreen.subtitleKey, HomeScreen.settingsKey].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));
      [SettingsScreen.projectsKey, SettingsScreen.myAccountKey].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.projectsKey)));
      final runningId = running['id'] as String;
      final finishedId = finished['id'] as String;
      [
        ProjectsScreen.newProjectKey,
        ProjectsScreen.nameKey(runningId),
        ProjectsScreen.detailsKey(runningId),
        ProjectsScreen.statusKey(runningId),
        ProjectsScreen.addUnitKey(runningId),
        ProjectsScreen.closeKey(runningId),
        ProjectsScreen.statusKey(finishedId),
        ProjectsScreen.detailsKey(finishedId),
      ].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.closeKey(runningId))));
      [ProjectsScreen.closeExplainKey, ProjectsScreen.confirmCloseKey, ProjectsScreen.cancelCloseKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cancelCloseKey)));

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.newProjectKey)));
      [NewProjectScreen.nameKey, NewProjectScreen.startDateKey, NewProjectScreen.unitNameKey, NewProjectScreen.addUnitKey, NewProjectScreen.submitKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));
      [MyAccountScreen.arabicKey, MyAccountScreen.englishKey, MyAccountScreen.changePasswordKey].forEach(expectFits);
    });
  }
}
