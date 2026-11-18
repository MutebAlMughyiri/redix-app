// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/words/language_switch.dart';
import 'package:redix/words/no_words_screen.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Which way the screen under [key] reads.
TextDirection directionOf(PatrolIntegrationTester $, Key key) => Directionality.of($.tester.element(find.byKey(key)));

/// Waits until the screen under [key] reads [direction], and checks it does.
Future<void> reads(PatrolIntegrationTester $, Key key, TextDirection direction) async {
  await $.until(() => find.byKey(key).evaluate().isNotEmpty && directionOf($, key) == direction);
  expect(directionOf($, key), direction);
}

/// A new manager standing on Settings, answered.
Future<Person> onSettings(PatrolIntegrationTester $) async {
  final manager = await Given.manager();
  await $.onTheList(manager);
  await $(ProjectsScreen.sharedSettingsKey).tap();
  await $.reach($(SharedSettingsScreen.languageKey));
  return manager;
}

void main() {
  phoneClass('Language (UC-001 and UC-004)', () {
    phoneCase('the real app opens with words from the real API', ($) async {
      await $.startApp();
      await $.reach($(SignInScreen.usernameKey));
      expect($.words.signInSubmit, isNot('signIn.submit'));
      expect($.words.isEmpty, isFalse);
    });

    phoneCase('Arabic turns the screens right to left, with its words', ($) async {
      await onSettings($);
      await $.goTo($(LanguageSwitch.arabicKey));
      await $.picture('language');
      await $(LanguageSwitch.arabicKey).tap();
      await reads($, SharedSettingsScreen.languageKey, TextDirection.rtl);
      await $.says(LanguageSwitch.arabicKey, 'العربية');
      await $.tapOn(SharedSettingsScreen.switchProjectKey);
      await $.reach($(ProjectsScreen.titleKey));
      await reads($, ProjectsScreen.titleKey, TextDirection.rtl);
    });

    phoneCase('English turns the screens left to right, with its words', ($) async {
      await onSettings($);
      await $.goTo($(LanguageSwitch.arabicKey));
      await $(LanguageSwitch.arabicKey).tap();
      await reads($, SharedSettingsScreen.languageKey, TextDirection.rtl);
      await $.goTo($(LanguageSwitch.englishKey));
      await $(LanguageSwitch.englishKey).tap();
      await reads($, SharedSettingsScreen.languageKey, TextDirection.ltr);
      await $.says(LanguageSwitch.englishKey, 'English');
    });

    phoneCase('Settings shows the switch itself, the language in use chosen', ($) async {
      await onSettings($);
      await $.goTo($(LanguageSwitch.choiceKey));
      final choice = $.tester.widget<SegmentedButton<String>>(find.byKey(LanguageSwitch.choiceKey));
      expect(choice.selected, {Localizations.localeOf($.tester.element(find.byKey(LanguageSwitch.choiceKey))).languageCode});
    });

    phoneCase('a language chosen before signing in is kept after', ($) async {
      final manager = await Given.manager();
      await $.startApp();
      await $.reach($(LanguageSwitch.arabicKey));
      await $(LanguageSwitch.arabicKey).tap();
      await reads($, SignInScreen.titleKey, TextDirection.rtl);
      await $.signIn(manager.username, manager.password);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      await reads($, ProjectsScreen.titleKey, TextDirection.rtl);
    });

    phoneCase('the choice is used at the next start', ($) async {
      await onSettings($);
      await $.goTo($(LanguageSwitch.arabicKey));
      await $(LanguageSwitch.arabicKey).tap();
      await reads($, SharedSettingsScreen.languageKey, TextDirection.rtl);
      await $.restartApp();
      await $.reach($(ProjectsScreen.titleKey));
      await reads($, ProjectsScreen.titleKey, TextDirection.rtl);
    });

    phoneCase('without a network the language stays, and the app says switching needs one', ($) async {
      await onSettings($);
      final before = directionOf($, SharedSettingsScreen.languageKey);
      await Pc.cutNetwork();
      await $.goTo($(LanguageSwitch.arabicKey));
      await $(before == TextDirection.ltr ? LanguageSwitch.arabicKey : LanguageSwitch.englishKey).tap();
      await $.says(LanguageSwitch.messageKey, $.words.myAccountLanguageNeedsNetwork);
      expect(directionOf($, SharedSettingsScreen.languageKey), before);
    });

    phoneCase('a first start without a network shows no words and retries', ($) async {
      await $.startApp();
      await $.forgetTheSettings();
      await Pc.cutNetwork();
      await $.restartApp();
      await $.reach($(NoWordsScreen.retryKey));
      await Pc.restoreNetwork();
      await $(NoWordsScreen.retryKey).tap();
      await $.reach($(SignInScreen.usernameKey));
    });
  });
}
