import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/projects/projects_screen.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Sign in (UC-002)', () {
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
      await $.onTheList(manager);
    });

    phoneCase('a kept session opens the app at the next start, with no sign-in', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await $.restartApp();
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      expect($(SignInScreen.usernameKey), findsNothing);
    });

    phoneCase('FR-16: without a network a kept session stays open, and work goes on', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
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

    phoneCase('redix-app #98: a refused sign-in says why in one line above the user name, on the screen', ($) async {
      final manager = await Given.manager();
      await $.startApp();
      await $.signIn(manager.username, 'not-the-password');
      await $.says(SignInScreen.messageKey, $.words.signInInvalidCredentials);
      expect(find.byKey(SignInScreen.messageKey).hitTestable(), findsOneWidget);
      expect($.tester.getTopLeft(find.byKey(SignInScreen.messageKey)).dy, lessThan($.tester.getTopLeft(find.byKey(SignInScreen.usernameKey)).dy));
    });

    phoneCase('AC-01.2: an unknown username shows that same line', ($) async {
      await $.startApp();
      await $.signIn('nobody-${Given.unique()}', 'not-the-password');
      await $.says(SignInScreen.messageKey, $.words.signInInvalidCredentials);
    });

    phoneCase('redix-api #126 R2: a person made inactive in his project still signs in, and his list shows it gray, saying so', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await Given.disabled(member, by: manager);
      await $.onTheList(member);
      await $.says(ProjectsScreen.detailsKey(member.projectId), $.words.projectsInactive);
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

    phoneCase('redix-api #126 R4: made inactive while inside his project, the project list replaces it when the app comes back to the screen', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await $.onTheHome(member);
      await Given.disabled(member, by: manager);
      await $.platform.mobile.pressHome();
      await $.platform.mobile.openApp();
      await $.says(ProjectsScreen.detailsKey(member.projectId), $.words.projectsInactive);
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
