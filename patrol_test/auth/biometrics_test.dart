import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  group('Fingerprint (UC-011)', () {
    phoneCase('on a phone with no fingerprint, turning it on refuses, says what to do, and stays off', ($) async {
      final manager = await Given.manager();
      await $.startApp();
      await $.signIn(manager.username, manager.password);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      await $(ProjectsScreen.settingsKey).tap();
      await $.goTo($(SettingsScreen.biometricsKey));
      await $(SettingsScreen.biometricsKey).tap();
      await $.says(SettingsScreen.biometricsMessageKey, $.words.biometricsNotAvailable);
      expect($.tester.widget<SwitchListTile>(find.byKey(SettingsScreen.biometricsKey)).value, isFalse);
    }, skip: const bool.fromEnvironment('TEST_HAS_FINGERPRINT'));
  });
}
