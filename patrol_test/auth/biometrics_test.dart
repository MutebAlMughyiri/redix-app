import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Fingerprint (UC-011)', () {
    phoneCase('on a phone with no fingerprint, turning it on refuses, says what to do, and stays off', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await $(ProjectsScreen.sharedSettingsKey).tap();
      await $.goTo($(SharedSettingsScreen.biometricsKey));
      await $(SharedSettingsScreen.biometricsKey).tap();
      await $.says(SharedSettingsScreen.biometricsMessageKey, $.words.biometricsNotAvailable);
      expect($.tester.widget<SwitchListTile>(find.byKey(SharedSettingsScreen.biometricsKey)).value, isFalse);
    }, skip: const bool.fromEnvironment('TEST_HAS_FINGERPRINT'));
  });
}
