import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/projects/projects_screen.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  group('Sign in (UC-002)', () {
    phoneCase('without a session the app opens on sign-in, headed by the logo', ($) async {
      await $.startApp();
      await $.reach($(SignInScreen.usernameKey));
      final logo = find.byKey(SignInScreen.logoKey);
      await precacheImage($.tester.widget<Image>(logo).image, $.tester.element(logo));
      await $.pumpAndSettle();
      expect($.tester.widget<RawImage>(find.descendant(of: logo, matching: find.byType(RawImage))).image, isNotNull);
      await $.picture('sign-in');
    });

    phoneCase('FR-01: the right username and password open the app', ($) async {
      final manager = await Given.manager();
      await $.startApp();
      await $.signIn(manager.username, manager.password);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
    });

    phoneCase('a kept session opens the app at the next start, with no sign-in', ($) async {
      final manager = await Given.manager();
      await $.startApp();
      await $.signIn(manager.username, manager.password);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      await $.restartApp();
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      expect($(SignInScreen.usernameKey), findsNothing);
    });

    phoneCase('FR-16: without a network a kept session stays open, and work goes on', ($) async {
      final manager = await Given.manager();
      await $.startApp();
      await $.signIn(manager.username, manager.password);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      await Pc.cutNetwork();
      await $.restartApp();
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      expect($(SignInScreen.usernameKey), findsNothing);
    });

    phoneCase('AC-01.2: a wrong password shows one line that does not say which field was wrong', ($) async {
      final manager = await Given.manager();
      await $.startApp();
      await $.signIn(manager.username, 'not-the-password');
      await $.says(SignInScreen.messageKey, $.words.signInInvalidCredentials);
    });

    phoneCase('AC-01.2: an unknown username shows that same line', ($) async {
      await $.startApp();
      await $.signIn('nobody-${Given.unique()}', 'not-the-password');
      await $.says(SignInScreen.messageKey, $.words.signInInvalidCredentials);
    });

    phoneCase('AC-01.2: a disabled user shows that same line', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await Given.disabled(member, by: manager);
      await $.startApp();
      await $.signIn(member.username, member.password);
      await $.says(SignInScreen.messageKey, $.words.signInInvalidCredentials);
    });

    phoneCase('nothing typed is refused, and the app stays on sign-in', ($) async {
      await $.startApp();
      await $.reach($(SignInScreen.usernameKey));
      await $.goTo($(SignInScreen.submitKey));
      await $(SignInScreen.submitKey).tap();
      await $.says(SignInScreen.messageKey, $.words.signInInvalidCredentials);
      expect($(SignInScreen.usernameKey), findsOneWidget);
    });

    phoneCase('AC-01.2: repeated wrong passwords lock the account, and the screen says to try again later', ($) async {
      final manager = await Given.manager();
      await $.startApp();
      for (var tries = 0; tries < 5; tries++) {
        await $.signIn(manager.username, 'not-the-password');
      }
      await $.signIn(manager.username, manager.password);
      await $.says(SignInScreen.messageKey, $.words.signInAccountLocked);
    });

    phoneCase('AC-01.3: someone disabled while signed in ends on sign-in at their next request, with a notice', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await $.startApp();
      await $.signIn(member.username, member.password);
      await $.reach($(ProjectsScreen.cardKey(member.projectId)));
      await Given.disabled(member, by: manager);
      await $(ProjectsScreen.cardKey(member.projectId)).tap();
      await $.reach($(SignInScreen.usernameKey));
      await $.says(SignInScreen.messageKey, $.words.signInSessionExpired);
    });

    phoneCase('without a network sign-in says there is no connection', ($) async {
      final manager = await Given.manager();
      await $.startApp();
      await $.reach($(SignInScreen.usernameKey));
      await Pc.cutNetwork();
      await $.signIn(manager.username, manager.password);
      await $.says(SignInScreen.messageKey, $.words.signInNoConnection);
    });
  });
}
