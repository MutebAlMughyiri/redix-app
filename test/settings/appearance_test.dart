// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/app_color.dart';
import 'package:redix/ui/app_theme.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/words/language_switch.dart';
import 'package:redix/words/no_words_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

void main() {
  const stateKey = 'themeMode_state';

  /// Settings, opened from the project list in [locale], with what the phone already keeps in [preferences].
  Future<FakeApi> openSettings(WidgetTester tester, {Map<String, Object> preferences = const {}, Locale locale = const Locale('en')}) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: locale, stored: {'session': keptSession}, preferences: preferences);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.sharedSettingsKey)));
    return api;
  }

  /// Sets the test phone's own light or dark setting, as its settings would, and redraws.
  Future<void> phoneIs(WidgetTester tester, Brightness brightness) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, FakeApi api, Key choice) => act(tester, api, () => tester.tap(find.byKey(choice)));

  Brightness brightnessAt(WidgetTester tester, Finder finder) => Theme.of(tester.element(finder)).brightness;

  Brightness settingsBrightness(WidgetTester tester) => brightnessAt(tester, find.byKey(SharedSettingsScreen.appearanceKey));

  SegmentedButton<ThemeMode> themeChoice(WidgetTester tester) => tester.widget<SegmentedButton<ThemeMode>>(find.byKey(SharedSettingsScreen.themeChoiceKey));

  Future<int?> kept() async => (await SharedPreferences.getInstance()).getInt(stateKey);

  String? text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data;

  testWidgets('redix-app #97 T1, R1: on System, a dark phone draws the app dark, and a light one light', (tester) async {
    await phoneIs(tester, Brightness.dark);
    await openSettings(tester);
    expect(themeChoice(tester).selected, {ThemeMode.system});
    expect(settingsBrightness(tester), Brightness.dark);

    await phoneIs(tester, Brightness.light);
    expect(settingsBrightness(tester), Brightness.light);
  });

  testWidgets('T2, R3: on System, the app turns dark and light with the phone while it is open', (tester) async {
    final api = await openSettings(tester, preferences: {stateKey: 0});
    await choose(tester, api, SharedSettingsScreen.themeSystemKey);
    expect(settingsBrightness(tester), Brightness.light);

    await phoneIs(tester, Brightness.dark);
    expect(settingsBrightness(tester), Brightness.dark);

    await phoneIs(tester, Brightness.light);
    expect(settingsBrightness(tester), Brightness.light);
  });

  testWidgets('T3, R2: Light stays light on a dark phone, and Dark stays dark on a light one', (tester) async {
    await phoneIs(tester, Brightness.dark);
    final api = await openSettings(tester);
    await choose(tester, api, SharedSettingsScreen.themeLightKey);
    expect(settingsBrightness(tester), Brightness.light);

    await phoneIs(tester, Brightness.light);
    await choose(tester, api, SharedSettingsScreen.themeDarkKey);
    expect(settingsBrightness(tester), Brightness.dark);
    expect(themeChoice(tester).selected, {ThemeMode.dark});
  });

  testWidgets('T4, R4: each choice keeps its number, 0 Light, 1 Dark and 2 System', (tester) async {
    final api = await openSettings(tester);

    await choose(tester, api, SharedSettingsScreen.themeLightKey);
    expect(await kept(), 0);
    await choose(tester, api, SharedSettingsScreen.themeDarkKey);
    expect(await kept(), 1);
    await choose(tester, api, SharedSettingsScreen.themeSystemKey);
    expect(await kept(), 2);
  });

  testWidgets('T4, R4: a phone kept at 1 opens dark, from its first frame, with Dark chosen', (tester) async {
    await openSettings(tester, preferences: {stateKey: 1});

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
    expect(settingsBrightness(tester), Brightness.dark);
    expect(themeChoice(tester).selected, {ThemeMode.dark});
  });

  testWidgets('T5, D2: a phone that never chose follows the phone, and 2 is saved', (tester) async {
    await openSettings(tester);

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.system);
    expect(themeChoice(tester).selected, {ThemeMode.system});
    expect(await kept(), 2);
  });

  testWidgets('T6, R5: a phone holding the light #87 saved by itself, darkMode_state 0, follows the phone, and that key stays unread', (tester) async {
    await phoneIs(tester, Brightness.dark);
    await openSettings(tester, preferences: {'darkMode_state': 0});

    expect(settingsBrightness(tester), Brightness.dark);
    expect(themeChoice(tester).selected, {ThemeMode.system});
    expect(await kept(), 2);
  });

  testWidgets('T6: a phone kept at Light under the new key stays light on a dark phone', (tester) async {
    await phoneIs(tester, Brightness.dark);
    await openSettings(tester, preferences: {stateKey: 0});

    expect(settingsBrightness(tester), Brightness.light);
    expect(themeChoice(tester).selected, {ThemeMode.light});
  });

  testWidgets('T7: a number no build kept reads as System, with no error', (tester) async {
    await openSettings(tester, preferences: {stateKey: 7});

    expect(themeChoice(tester).selected, {ThemeMode.system});
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.system);
  });

  for (final language in ['ar', 'en']) {
    testWidgets('T8: the heading and the three choices fit a phone 360 points wide, in $language', (tester) async {
      tester.view.physicalSize = const Size(360, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await openSettings(tester, locale: Locale(language));

      expect(tester.takeException(), isNull);
      for (final key in [SharedSettingsScreen.appearanceKey, SharedSettingsScreen.themeSystemKey, SharedSettingsScreen.themeLightKey, SharedSettingsScreen.themeDarkKey]) {
        final rect = tester.getRect(find.byKey(key));
        expect(rect.left, greaterThanOrEqualTo(0), reason: '$key starts off the screen');
        expect(rect.right, lessThanOrEqualTo(360), reason: '$key ends off the screen');
      }
    });
  }

  testWidgets('T11, R8: the three choices read System, Light and Dark, words only, under the heading Appearance with its icon', (tester) async {
    await openSettings(tester);

    expect(text(tester, SharedSettingsScreen.appearanceKey.title), 'en sharedSettings.appearance');
    expect(tester.widget<Icon>(find.byKey(SharedSettingsScreen.appearanceKey.icon)).icon, Icons.dark_mode_outlined);
    expect(text(tester, SharedSettingsScreen.themeSystemKey), 'en sharedSettings.themeSystem');
    expect(text(tester, SharedSettingsScreen.themeLightKey), 'en sharedSettings.themeLight');
    expect(text(tester, SharedSettingsScreen.themeDarkKey), 'en sharedSettings.themeDark');
    expect([for (final segment in themeChoice(tester).segments) segment.value], [ThemeMode.system, ThemeMode.light, ThemeMode.dark]);
    expect(themeChoice(tester).segments.every((segment) => segment.icon == null), isTrue);
  });

  testWidgets('#87 R4: Appearance sits right under the language choice, and above fingerprint or face', (tester) async {
    await openSettings(tester);

    final language = tester.getTopLeft(find.byKey(LanguageSwitch.choiceKey)).dy;
    final appearance = tester.getTopLeft(find.byKey(SharedSettingsScreen.appearanceKey)).dy;
    final biometrics = tester.getTopLeft(find.byKey(SharedSettingsScreen.biometricsKey)).dy;
    expect(language < appearance && appearance < biometrics, isTrue);
  });

  testWidgets('#87 R5: every Settings component sits in its own border, each heading and its choice in one, and no divider is left', (tester) async {
    await openSettings(tester);

    final components = [
      SharedSettingsScreen.whoKey,
      SharedSettingsScreen.switchProjectKey,
      SharedSettingsScreen.defaultProjectKey,
      SharedSettingsScreen.languageKey,
      SharedSettingsScreen.appearanceKey,
      SharedSettingsScreen.biometricsKey,
      SharedSettingsScreen.changePasswordKey,
      SharedSettingsScreen.signOutKey,
    ];
    Finder cardOf(Finder finder) => find.ancestor(of: finder, matching: find.byType(Card));
    for (final key in components) {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      expect(cardOf(find.byKey(key)), findsOneWidget, reason: '$key');
      final frame = tester.widget<Material>(find.descendant(of: cardOf(find.byKey(key)), matching: find.byType(Material)).first);
      expect((frame.shape! as OutlinedBorder).side.color, AppColor.frame.of(tester.element(find.byKey(key))), reason: '$key');
    }
    expect({for (final key in components) tester.widget<Card>(cardOf(find.byKey(key)))}.length, components.length);
    expect(tester.widget<Card>(cardOf(find.byKey(LanguageSwitch.choiceKey))), same(tester.widget<Card>(cardOf(find.byKey(SharedSettingsScreen.languageKey)))));
    expect(tester.widget<Card>(cardOf(find.byKey(SharedSettingsScreen.themeChoiceKey))), same(tester.widget<Card>(cardOf(find.byKey(SharedSettingsScreen.appearanceKey)))));
    expect(find.descendant(of: find.byKey(SharedSettingsScreen.bodyKey), matching: find.byType(Divider)), findsNothing);
  });

  testWidgets('#87 R7: the change reaches the screen behind Settings too, with no restart', (tester) async {
    final api = await openSettings(tester);

    await choose(tester, api, SharedSettingsScreen.themeDarkKey);
    await act(tester, api, () => tester.pageBack());

    expect(brightnessAt(tester, find.byKey(ProjectsScreen.sharedSettingsKey)), Brightness.dark);
  });

  testWidgets('#87 R9: sign-in follows the choice', (tester) async {
    await pumpRedix(tester, FakeApi(), preferences: {stateKey: 1});

    expect(brightnessAt(tester, find.byKey(SignInScreen.usernameKey)), Brightness.dark);
  });

  testWidgets('#87 R9: the no-words screen follows the choice', (tester) async {
    await pumpRedix(tester, FakeApi()..online = false, stored: {'session': keptSession}, preferences: {stateKey: 1});

    expect(brightnessAt(tester, find.byKey(NoWordsScreen.iconKey)), Brightness.dark);
  });

  testWidgets('T9, R7: choosing a language leaves the appearance as it is, and choosing the appearance leaves the language as it is', (tester) async {
    final api = await openSettings(tester);

    await choose(tester, api, SharedSettingsScreen.themeDarkKey);
    expect(Localizations.localeOf(tester.element(find.byKey(SharedSettingsScreen.appearanceKey))).languageCode, 'en');

    await act(tester, api, () => tester.tap(find.byKey(LanguageSwitch.arabicKey)));
    expect(text(tester, SharedSettingsScreen.appearanceKey.title), 'ar sharedSettings.appearance');
    expect(settingsBrightness(tester), Brightness.dark);
    expect(await kept(), 1);
  });

  /// The ground of the app in [brightness], and the waiting orange on it.
  Future<(Color, Color)> waitingOn(WidgetTester tester, Brightness brightness) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(theme: appThemeOf(brightness), home: Builder(builder: (built) {
      context = built;
      return const SizedBox();
    })));
    return (AppColor.waiting.of(context), Theme.of(context).colorScheme.surface);
  }

  double contrast(Color one, Color other) {
    final (lighter, darker) = (max(one.computeLuminance(), other.computeLuminance()), min(one.computeLuminance(), other.computeLuminance()));
    return (lighter + 0.05) / (darker + 0.05);
  }

  testWidgets('#87 R10: the waiting orange, the one color not grown from the seed, reads on the dark ground', (tester) async {
    final (waiting, ground) = await waitingOn(tester, Brightness.dark);

    expect(waiting, Colors.orange.shade700);
    expect(contrast(waiting, ground), greaterThanOrEqualTo(4.5));
  });

  testWidgets('findings row 191: on the light ground the waiting orange is orange 900, its frame read at 3:1 or more, where orange 700 read at 2.6:1', (tester) async {
    final (waiting, ground) = await waitingOn(tester, Brightness.light);

    expect(waiting, Colors.orange.shade900);
    expect(contrast(waiting, ground), greaterThanOrEqualTo(3));
    expect(contrast(Colors.orange.shade700, ground), lessThan(3));
  });
}
