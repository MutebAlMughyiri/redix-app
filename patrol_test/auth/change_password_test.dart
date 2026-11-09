import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';

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
  group('Change password (UC-003)', () {
    phoneCase('AC-02.1: a temporary password leads straight to the change screen', ($) async {
      await onTheChangeScreen($);
      await $.picture('change-password');
    });

    phoneCase('a changed password opens the app', ($) async {
      final member = await onTheChangeScreen($);
      final chosen = 'Chosen-${Given.unique()}';
      await sendChange($, member.password, chosen, chosen);
      await $.reach($(ProjectsScreen.cardKey(member.projectId)));
    });

    phoneCase('the new password signs in next time', ($) async {
      final member = await onTheChangeScreen($);
      final chosen = 'Chosen-${Given.unique()}';
      await sendChange($, member.password, chosen, chosen);
      await $.reach($(ProjectsScreen.cardKey(member.projectId)));
      await $.signOutFromTheList();
      await $.signIn(member.username, chosen);
      await $.reach($(ProjectsScreen.cardKey(member.projectId)));
    });

    phoneCase('opened from Settings, the screen has a way back, and the change is kept', ($) async {
      final manager = await Given.manager();
      await $.startApp();
      await $.signIn(manager.username, manager.password);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      await $(ProjectsScreen.settingsKey).tap();
      await $.goTo($(SettingsScreen.changePasswordKey));
      await $(SettingsScreen.changePasswordKey).tap();
      await $.reach($(ChangePasswordScreen.currentKey));
      expect($.canGoBack, isTrue);
      await $.back();
      await $.reach($(SettingsScreen.changePasswordKey));
      await $(SettingsScreen.changePasswordKey).tap();
      final chosen = 'Chosen-${Given.unique()}';
      await sendChange($, manager.password, chosen, chosen);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      expect(await Given.canSignIn(manager.username, chosen), isTrue);
    });

    phoneCase('the old password stops working after the change', ($) async {
      final member = await onTheChangeScreen($);
      final chosen = 'Chosen-${Given.unique()}';
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
      final chosen = 'Chosen-${Given.unique()}';
      await sendChange($, 'not-the-password', chosen, chosen);
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordInvalidCredentials);
    });

    phoneCase('a weak new password shows its own line', ($) async {
      final member = await onTheChangeScreen($);
      await sendChange($, member.password, 'short', 'short');
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordWeakPassword);
    });

    phoneCase('AC-01.2: repeated wrong current passwords lock the account', ($) async {
      final member = await onTheChangeScreen($);
      final chosen = 'Chosen-${Given.unique()}';
      for (var tries = 0; tries < 5; tries++) {
        await sendChange($, 'not-the-password', chosen, chosen);
      }
      await sendChange($, member.password, chosen, chosen);
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordAccountLocked);
    });

    phoneCase('without a network the change says so', ($) async {
      final member = await onTheChangeScreen($);
      await Pc.cutNetwork();
      final chosen = 'Chosen-${Given.unique()}';
      await sendChange($, member.password, chosen, chosen);
      await $.says(ChangePasswordScreen.messageKey, $.words.changePasswordNoConnection);
    });
  });
}
