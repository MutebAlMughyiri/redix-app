// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Types into the change screen and sends it, returning once the API has answered.
Future<void> sendChange(PatrolIntegrationTester $, String current, String chosen, String repeated) async {
  await $.reach($(ChangePasswordScreen.currentKey));
  await $(ChangePasswordScreen.currentKey).enterText(current);
  await $(ChangePasswordScreen.newKey).enterText(chosen);
  await $(ChangePasswordScreen.confirmKey).enterText(repeated);
  await $.goTo($(ChangePasswordScreen.submitKey));
  await $(ChangePasswordScreen.submitKey).tap();
  await $.answered(ChangePasswordScreen.submitKey);
}

/// A new person holding a temporary password, signed in and standing on the change screen.
Future<Person> onTheChangeScreen(PatrolIntegrationTester $) async {
  final member = await Given.member(await Given.manager(), temporary: true);
  await $.startApp();
  await $.signIn(member.username, member.password);
  await $.reach($(ChangePasswordScreen.currentKey));
  return member;
}

void main() {
  phoneClass('Change password (UC-003)', () {
    phoneCase('AC-02.1: a temporary password leads straight to the change screen', ($) async {
      await onTheChangeScreen($);
      await $.picture('change-password');
    });

    phoneCase('a changed password opens the app', ($) async {
      final member = await onTheChangeScreen($);
      final chosen = 'Chosen-${Given.unique()}-1';
      await sendChange($, member.password, chosen, chosen);
      await $.reach($(ProjectsScreen.cardKey(member.projectId)));
    });

    phoneCase('the new password signs in next time', ($) async {
      final member = await onTheChangeScreen($);
      final chosen = 'Chosen-${Given.unique()}-1';
      await sendChange($, member.password, chosen, chosen);
      await $.reach($(ProjectsScreen.cardKey(member.projectId)));
      await $.signOutFromTheList();
      await $.signIn(member.username, chosen);
      await $.reach($(ProjectsScreen.cardKey(member.projectId)));
    });

    phoneCase('opened from Settings, the screen has a way back, and the change is kept', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await $(ProjectsScreen.sharedSettingsKey).tap();
      await $.goTo($(SharedSettingsScreen.changePasswordKey));
      await $(SharedSettingsScreen.changePasswordKey).tap();
      await $.reach($(ChangePasswordScreen.currentKey));
      expect($.canGoBack, isTrue);
      await $.back();
      await $.goTo($(SharedSettingsScreen.changePasswordKey));
      await $(SharedSettingsScreen.changePasswordKey).tap();
      final chosen = 'Chosen-${Given.unique()}-1';
      await sendChange($, manager.password, chosen, chosen);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      expect(await Given.canSignIn(manager.username, chosen), isTrue);
    });

    phoneCase('the old password stops working after the change', ($) async {
      final member = await onTheChangeScreen($);
      final chosen = 'Chosen-${Given.unique()}-1';
      await sendChange($, member.password, chosen, chosen);
      await $.reach($(ProjectsScreen.cardKey(member.projectId)));
      await $.signOutFromTheList();
      await $.signIn(member.username, member.password);
      await $.says(SignInScreen.messageKey, $.words.signInInvalidCredentials);
    });

    phoneCase('the change cannot be skipped while the password is temporary', ($) async {
      await onTheChangeScreen($);
      expect($.canGoBack, isFalse);
      await $.restartApp();
      await $.reach($(ChangePasswordScreen.currentKey));
    });

    phoneCase('new passwords that differ are caught before anything is sent', ($) async {
      final member = await onTheChangeScreen($);
      await sendChange($, member.password, 'Chosen-first-1', 'Chosen-second-2');
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordMismatch);
      expect(await Given.canSignIn(member.username, member.password), isTrue);
    });

    phoneCase('a wrong current password shows its own line', ($) async {
      await onTheChangeScreen($);
      final chosen = 'Chosen-${Given.unique()}-1';
      await sendChange($, 'not-the-password', chosen, chosen);
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordInvalidCredentials);
    });

    phoneCase('a weak new password shows its own line', ($) async {
      final member = await onTheChangeScreen($);
      await sendChange($, member.password, 'short', 'short');
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordWeakPassword);
    });

    phoneCase('redix-api #113: the new password says the policy under it', ($) async {
      await onTheChangeScreen($);
      await $.reach($(ChangePasswordScreen.newKey));
      expect($.tester.widget<TextField>(find.byKey(ChangePasswordScreen.newKey)).decoration!.helperText, $.words.commonPasswordRules);
    });

    phoneCase('redix-api #113: eight letters with no digit are refused', ($) async {
      final member = await onTheChangeScreen($);
      await sendChange($, member.password, 'Abcdefgh', 'Abcdefgh');
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordWeakPassword);
    });

    phoneCase('redix-api #113: the user name is refused as a password', ($) async {
      final member = await onTheChangeScreen($);
      await sendChange($, member.password, member.username, member.username);
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordWeakPassword);
    });

    phoneCase('redix-api #113: eight characters with a letter and a digit are taken', ($) async {
      final member = await onTheChangeScreen($);
      await sendChange($, member.password, 'abcdefg1', 'abcdefg1');
      await $.reach($(ProjectsScreen.cardKey(member.projectId)));
    });

    phoneCase('AC-01.2: repeated wrong current passwords lock the account', ($) async {
      final member = await onTheChangeScreen($);
      final chosen = 'Chosen-${Given.unique()}-1';
      for (var tries = 0; tries < 5; tries++) {
        await sendChange($, 'not-the-password', chosen, chosen);
      }
      await sendChange($, member.password, chosen, chosen);
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordAccountLocked);
    });

    phoneCase('without a network the change says so', ($) async {
      final member = await onTheChangeScreen($);
      await Pc.cutNetwork();
      final chosen = 'Chosen-${Given.unique()}-1';
      await sendChange($, member.password, chosen, chosen);
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordNoConnection);
    });
  });
}
