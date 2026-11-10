import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/general_settings_screen.dart';
import 'package:redix/ui/app_color.dart';
import 'package:redix/ui/app_theme.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/words/language_switch.dart';
import 'package:redix/words/no_words_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

void main() {
  const stateKey = 'darkMode_state';

  /// Settings, opened from the project list, with what the phone already keeps in [preferences].
  Future<FakeApi> openSettings(WidgetTester tester, {Map<String, Object> preferences = const {}}) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession}, preferences: preferences);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.generalSettingsKey)));
    return api;
  }

  Future<void> tapDarkMode(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byKey(GeneralSettingsScreen.darkModeKey)));

  Brightness brightnessAt(WidgetTester tester, Finder finder) => Theme.of(tester.element(finder)).brightness;

  Brightness settingsBrightness(WidgetTester tester) => brightnessAt(tester, find.byKey(GeneralSettingsScreen.darkModeKey));

  SwitchListTile darkModeSwitch(WidgetTester tester) => tester.widget<SwitchListTile>(find.byKey(GeneralSettingsScreen.darkModeKey));

  Future<int?> kept() async => (await SharedPreferences.getInstance()).getInt(stateKey);

  String? text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data;

  testWidgets('redix-app #87 R1, R2: Dark mode in Settings turns the app dark at once, and a second tap turns it light', (tester) async {
    final api = await openSettings(tester);
    expect(settingsBrightness(tester), Brightness.light);

    await tapDarkMode(tester, api);
    expect(settingsBrightness(tester), Brightness.dark);
    expect(darkModeSwitch(tester).value, isTrue);

    await tapDarkMode(tester, api);
    expect(settingsBrightness(tester), Brightness.light);
    expect(darkModeSwitch(tester).value, isFalse);
  });

  testWidgets('R4: Dark mode is a switch like the fingerprint one, with its icon and its word, right under the language choice', (tester) async {
    await openSettings(tester);

    expect(darkModeSwitch(tester).secondary, isA<Icon>().having((icon) => icon.icon, 'icon', Icons.dark_mode_outlined));
    expect(text(tester, GeneralSettingsScreen.darkModeKey.title), 'en generalSettings.darkMode');
    expect(tester.widget(find.byKey(GeneralSettingsScreen.biometricsKey)), isA<SwitchListTile>());
    final language = tester.getTopLeft(find.byKey(LanguageSwitch.choiceKey)).dy;
    final darkMode = tester.getTopLeft(find.byKey(GeneralSettingsScreen.darkModeKey)).dy;
    final biometrics = tester.getTopLeft(find.byKey(GeneralSettingsScreen.biometricsKey)).dy;
    expect(language < darkMode && darkMode < biometrics, isTrue);
  });

  testWidgets('R5: every Settings component sits in its own border, the language heading and its choice in one, and no divider is left', (tester) async {
    await openSettings(tester);

    final components = [
      GeneralSettingsScreen.whoKey,
      GeneralSettingsScreen.switchProjectKey,
      GeneralSettingsScreen.defaultProjectKey,
      GeneralSettingsScreen.languageKey,
      GeneralSettingsScreen.darkModeKey,
      GeneralSettingsScreen.biometricsKey,
      GeneralSettingsScreen.changePasswordKey,
      GeneralSettingsScreen.signOutKey,
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
    expect(tester.widget<Card>(cardOf(find.byKey(LanguageSwitch.choiceKey))), same(tester.widget<Card>(cardOf(find.byKey(GeneralSettingsScreen.languageKey)))));
    expect(find.descendant(of: find.byType(GeneralSettingsScreen), matching: find.byType(Divider)), findsNothing);
  });

  testWidgets('R6: the key holds 1 while dark and 0 while light', (tester) async {
    final api = await openSettings(tester);

    await tapDarkMode(tester, api);
    expect(await kept(), 1);

    await tapDarkMode(tester, api);
    expect(await kept(), 0);
  });

  testWidgets('R6: a phone that never chose starts light, and the key is saved as 0', (tester) async {
    await openSettings(tester);

    expect(settingsBrightness(tester), Brightness.light);
    expect(await kept(), 0);
  });

  testWidgets('R6: a phone kept at 1 opens dark, from its first frame', (tester) async {
    await openSettings(tester, preferences: {stateKey: 1});

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
    expect(settingsBrightness(tester), Brightness.dark);
    expect(darkModeSwitch(tester).value, isTrue);
  });

  testWidgets('R7: the change reaches the screen behind Settings too, with no restart', (tester) async {
    final api = await openSettings(tester);

    await tapDarkMode(tester, api);
    await act(tester, api, () => tester.pageBack());

    expect(brightnessAt(tester, find.byKey(ProjectsScreen.generalSettingsKey)), Brightness.dark);
  });

  testWidgets('R9: sign-in follows the choice', (tester) async {
    await pumpRedix(tester, FakeApi(), preferences: {stateKey: 1});

    expect(brightnessAt(tester, find.byType(SignInScreen)), Brightness.dark);
  });

  testWidgets('R9: the no-words screen follows the choice', (tester) async {
    await pumpRedix(tester, FakeApi()..online = false, stored: {'session': keptSession}, preferences: {stateKey: 1});

    expect(brightnessAt(tester, find.byKey(NoWordsScreen.iconKey)), Brightness.dark);
  });

  testWidgets('R3: choosing a language leaves the mode as it is, and turning the mode leaves the language as it is', (tester) async {
    final api = await openSettings(tester);

    await tapDarkMode(tester, api);
    expect(Localizations.localeOf(tester.element(find.byKey(GeneralSettingsScreen.darkModeKey))).languageCode, 'en');

    await act(tester, api, () => tester.tap(find.byKey(LanguageSwitch.arabicKey)));
    expect(text(tester, GeneralSettingsScreen.darkModeKey.title), 'ar generalSettings.darkMode');
    expect(settingsBrightness(tester), Brightness.dark);
    expect(await kept(), 1);
  });

  testWidgets('R10: the waiting orange, the one color not grown from the seed, reads on the dark ground', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(theme: appThemeOf(Brightness.dark), home: Builder(builder: (built) {
      context = built;
      return const SizedBox();
    })));

    double contrast(Color one, Color other) {
      final (lighter, darker) = (max(one.computeLuminance(), other.computeLuminance()), min(one.computeLuminance(), other.computeLuminance()));
      return (lighter + 0.05) / (darker + 0.05);
    }

    expect(contrast(AppColor.waiting.of(context), Theme.of(context).colorScheme.surface), greaterThanOrEqualTo(4.5));
  });
}
