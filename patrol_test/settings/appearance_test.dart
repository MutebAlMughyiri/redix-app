import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/general_settings_screen.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager standing on Settings.
Future<Person> onSettings(PatrolIntegrationTester $) async {
  final manager = await Given.manager();
  await $.onTheList(manager);
  await $(ProjectsScreen.generalSettingsKey).tap();
  await $.reach($(GeneralSettingsScreen.themeChoiceKey));
  return manager;
}

/// Runs [body] with the phone's own dark mode on, and turns it off again whatever happens.
Future<void> onADarkPhone(PatrolIntegrationTester $, Future<void> Function() body) async {
  try {
    await Pc.turnPhoneDark();
    await $.until(() => $.phoneIsDark);
    await body();
  } finally {
    await Pc.turnPhoneLight();
  }
}

void main() {
  phoneClass('Appearance (redix-app #87, #97)', () {
    phoneCase('#97 T1, T2, R1, R3: on System, the app turns dark with the phone while it is open, and light again', ($) async {
      await onSettings($);
      await $.tapOn(GeneralSettingsScreen.themeSystemKey);
      expect($.isDark, isFalse);
      await onADarkPhone($, () => $.until(() => $.isDark));
      await $.until(() => !$.isDark);
    });

    phoneCase('T3, R2: Light stays light on a dark phone, and Dark stays dark once the phone is light again', ($) async {
      await onSettings($);
      await onADarkPhone($, () async {
        expect($.isDark, isFalse);
        await $.tapOn(GeneralSettingsScreen.themeDarkKey);
        await $.until(() => $.isDark);
      });
      await $.until(() => !$.phoneIsDark);
      expect($.isDark, isTrue);
    });

    phoneCase('#87 R1, R2: Dark in Settings turns the app dark at once, and Light turns it light', ($) async {
      await onSettings($);
      expect($.isDark, isFalse);
      await $.tapOn(GeneralSettingsScreen.themeDarkKey);
      await $.until(() => $.isDark);
      await $.tapOn(GeneralSettingsScreen.themeLightKey);
      await $.until(() => !$.isDark);
    });

    phoneCase('#87 R6: the choice is kept for the next start', ($) async {
      await onSettings($);
      await $.tapOn(GeneralSettingsScreen.themeDarkKey);
      await $.until(() => $.isDark);
      await $.restartApp();
      await $.reach($(ProjectsScreen.titleKey));
      expect($.isDark, isTrue);
    });

    phoneCase('#87 R6: signing out and in keeps the choice', ($) async {
      final manager = await onSettings($);
      await $.tapOn(GeneralSettingsScreen.themeDarkKey);
      await $.until(() => $.isDark);
      await $.signOutFromSettings();
      await $.signIn(manager.username, manager.password);
      await $.reach($(ProjectsScreen.titleKey));
      expect($.isDark, isTrue);
    });

    phoneCase('T10, #87 R12: the case before left the app dark, and on a dark phone this one still starts light', ($) async {
      await onADarkPhone($, () async {
        await $.startApp();
        expect($.isDark, isFalse);
      });
    });
  });
}
