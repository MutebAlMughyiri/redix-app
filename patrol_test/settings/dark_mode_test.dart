import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager standing on Settings.
Future<Person> onSettings(PatrolIntegrationTester $) async {
  final manager = await Given.manager();
  await $.onTheList(manager);
  await $(ProjectsScreen.settingsKey).tap();
  await $.reach($(SettingsScreen.darkModeKey));
  return manager;
}

void main() {
  phoneClass('Dark mode (redix-app #87)', () {
    phoneCase('R1, R2: the switch in Settings turns the app dark at once, and off turns it light', ($) async {
      await onSettings($);
      expect($.isDark, isFalse);
      await $.tapOn(SettingsScreen.darkModeKey);
      await $.until(() => $.isDark);
      await $.tapOn(SettingsScreen.darkModeKey);
      await $.until(() => !$.isDark);
    });

    phoneCase('R6: the choice is kept for the next start', ($) async {
      await onSettings($);
      await $.tapOn(SettingsScreen.darkModeKey);
      await $.until(() => $.isDark);
      await $.restartApp();
      await $.reach($(ProjectsScreen.titleKey));
      expect($.isDark, isTrue);
    });

    phoneCase('R6: signing out and in keeps the choice', ($) async {
      final manager = await onSettings($);
      await $.tapOn(SettingsScreen.darkModeKey);
      await $.until(() => $.isDark);
      await $.signOutFromSettings();
      await $.signIn(manager.username, manager.password);
      await $.reach($(ProjectsScreen.titleKey));
      expect($.isDark, isTrue);
    });

    phoneCase('R12: the case before left the app dark, and this one starts light', ($) async {
      await $.startApp();
      expect($.isDark, isFalse);
    });
  });
}
