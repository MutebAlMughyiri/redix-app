// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager standing on Settings.
Future<Person> onSettings(PatrolIntegrationTester $) async {
  final manager = await Given.manager();
  await $.onTheList(manager);
  await $(ProjectsScreen.sharedSettingsKey).tap();
  await $.reach($(SharedSettingsScreen.themeChoiceKey));
  return manager;
}

/// Runs [body], then puts the phone's own dark mode back as its owner had it, whatever happens: a case never assumes the phone's mode, and never leaves it changed.
Future<void> keepingThePhone(Future<void> Function() body) async {
  try {
    await body();
  } finally {
    await Pc.restorePhone();
  }
}

/// Turns the phone's own dark mode to [dark] from the PC, and waits until the app sees it.
Future<void> phoneTurns(PatrolIntegrationTester $, {required bool dark}) async {
  await (dark ? Pc.turnPhoneDark() : Pc.turnPhoneLight());
  await $.until(() => $.phoneIsDark == dark);
}

void main() {
  phoneClass('Appearance (redix-app #87, #97)', () {
    phoneCase('#97 T1, T2, R1, R3: on System, the app turns dark with the phone while it is open, and light again', ($) async {
      await onSettings($);
      await $.tapOn(SharedSettingsScreen.themeSystemKey);
      await keepingThePhone(() async {
        await phoneTurns($, dark: false);
        await $.until(() => !$.isDark);
        await phoneTurns($, dark: true);
        await $.until(() => $.isDark);
        await phoneTurns($, dark: false);
        await $.until(() => !$.isDark);
      });
    });

    phoneCase('T3, R2: Light stays light on a dark phone, and Dark stays dark once the phone is light again', ($) async {
      await onSettings($);
      await keepingThePhone(() async {
        await phoneTurns($, dark: true);
        expect($.isDark, isFalse);
        await $.tapOn(SharedSettingsScreen.themeDarkKey);
        await $.until(() => $.isDark);
        await phoneTurns($, dark: false);
        expect($.isDark, isTrue);
      });
    });

    phoneCase('#87 R1, R2: Dark in Settings turns the app dark at once, and Light turns it light', ($) async {
      await onSettings($);
      expect($.isDark, isFalse);
      await $.tapOn(SharedSettingsScreen.themeDarkKey);
      await $.until(() => $.isDark);
      await $.tapOn(SharedSettingsScreen.themeLightKey);
      await $.until(() => !$.isDark);
    });

    phoneCase('#87 R6: the choice is kept for the next start', ($) async {
      await onSettings($);
      await $.tapOn(SharedSettingsScreen.themeDarkKey);
      await $.until(() => $.isDark);
      await $.restartApp();
      await $.reach($(ProjectsScreen.titleKey));
      expect($.isDark, isTrue);
    });

    phoneCase('#87 R6: signing out and in keeps the choice', ($) async {
      final manager = await onSettings($);
      await $.tapOn(SharedSettingsScreen.themeDarkKey);
      await $.until(() => $.isDark);
      await $.signOutFromSettings();
      await $.signIn(manager.username, manager.password);
      await $.reach($(ProjectsScreen.titleKey));
      expect($.isDark, isTrue);
    });

    phoneCase('T10, #87 R12: the case before left the app dark, and on a dark phone this one still starts light', ($) async {
      await keepingThePhone(() async {
        await phoneTurns($, dark: true);
        await $.startApp();
        expect($.isDark, isFalse);
      });
    });
  });
}
