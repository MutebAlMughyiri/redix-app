import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/general_settings_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/words/language_switch.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager, signed in and standing on the project list.
Future<Person> onTheProjectList(PatrolIntegrationTester $) async {
  final manager = await Given.manager();
  await $.onTheList(manager);
  return manager;
}

void main() {
  phoneClass('Sign out (UC-062)', () {
    phoneCase('signing out asks first, then leads to sign-in with no message', ($) async {
      await onTheProjectList($);
      await $(ProjectsScreen.generalSettingsKey).tap();
      await $.goTo($(GeneralSettingsScreen.signOutKey));
      await $(GeneralSettingsScreen.signOutKey).tap();
      await $.reach($(ConfirmDialog.confirmKey));
      await $(ConfirmDialog.confirmKey).tap();
      await $.reach($(SignInScreen.usernameKey));
      expect($(SignInScreen.messageKey), findsNothing);
    });

    phoneCase('the next user signs in as themselves', ($) async {
      final first = await onTheProjectList($);
      final second = await Given.manager();
      await $.signOutFromTheList();
      await $.signIn(second.username, second.password);
      await $.reach($(ProjectsScreen.cardKey(second.projectId)));
      expect($(ProjectsScreen.cardKey(first.projectId)), findsNothing);
    });

    phoneCase('the chosen language stays after signing out', ($) async {
      await onTheProjectList($);
      await $(ProjectsScreen.generalSettingsKey).tap();
      await $.goTo($(LanguageSwitch.arabicKey));
      await $(LanguageSwitch.arabicKey).tap();
      await $.until(() => Directionality.of($.tester.element(find.byKey(GeneralSettingsScreen.languageKey))) == TextDirection.rtl);
      await $.goTo($(GeneralSettingsScreen.signOutKey));
      await $(GeneralSettingsScreen.signOutKey).tap();
      await $(ConfirmDialog.confirmKey).tap();
      await $.reach($(SignInScreen.usernameKey));
      expect(Directionality.of($.tester.element(find.byKey(SignInScreen.titleKey))), TextDirection.rtl);
    });

    phoneCase('Cancel changes nothing', ($) async {
      await onTheProjectList($);
      await $(ProjectsScreen.generalSettingsKey).tap();
      await $.goTo($(GeneralSettingsScreen.signOutKey));
      await $(GeneralSettingsScreen.signOutKey).tap();
      await $(ConfirmDialog.cancelKey).tap();
      await $.reach($(GeneralSettingsScreen.signOutKey));
      expect($(SignInScreen.usernameKey), findsNothing);
    });

    phoneCase('back after signing out does not return to the app', ($) async {
      await onTheProjectList($);
      await $.signOutFromTheList();
      await $.reach($(SignInScreen.usernameKey));
      expect($.canGoBack, isFalse);
    });

    phoneCase('without a network the phone still signs out', ($) async {
      await onTheProjectList($);
      await Pc.cutNetwork();
      await $.signOutFromTheList();
      await $.reach($(SignInScreen.usernameKey));
    });
  });
}
