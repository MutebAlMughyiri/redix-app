import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/users/new_user_screen.dart';
import 'package:redix/users/users_screen.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager standing on the New user form, answered.
Future<Person> onTheForm(PatrolIntegrationTester $) async {
  final manager = await Given.manager(project: 'غصون 7', manager: 'ريم');
  await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
  await $.tapOn(UsersScreen.newUserKey);
  await $.reach($(NewUserScreen.nameKey));
  return manager;
}

/// Fills in the form.
Future<void> fillForm(PatrolIntegrationTester $, String username, {String name = 'نواف', String password = 'Temporary-2'}) async {
  await $.fill(NewUserScreen.nameKey, name);
  await $.fill(NewUserScreen.usernameKey, username);
  await $.fill(NewUserScreen.mobileKey, '0533333333');
  await $.fill(NewUserScreen.passwordKey, password);
}

/// Sends the form, returning once the API has answered.
Future<void> send(PatrolIntegrationTester $) async {
  await $.tapOn(NewUserScreen.submitKey);
  await $.answered(NewUserScreen.submitKey);
}

void main() {
  phoneClass('New user (UC-007 and UC-008)', () {
    phoneCase('a new user is created with a temporary password', ($) async {
      await onTheForm($);
      await fillForm($, 'patrol-nawaf-${Given.unique()}');
      await $.picture('new-user');
      await send($);
      await $.idShowing('users.name.', 'نواف');
    });

    phoneCase('AC-02.1: they sign in and must change it', ($) async {
      final manager = await onTheForm($);
      final username = 'nawaf-${Given.unique()}';
      await fillForm($, username);
      await send($);
      await $.idShowing('users.name.', 'نواف');
      await $.back();
      await $.signOutFromTheHome(manager.projectId);
      await $.signIn(username, 'Temporary-2');
      await $.reach($(ChangePasswordScreen.currentKey));
    });

    phoneCase('the temporary password shows as typed, so the manager can pass it on', ($) async {
      await onTheForm($);
      await $.goTo($(NewUserScreen.passwordKey));
      expect($.tester.widget<TextField>(find.byKey(NewUserScreen.passwordKey)).obscureText, isFalse);
    });

    phoneCase('what is ticked goes with the new user, See the project always ticked', ($) async {
      final manager = await onTheForm($);
      final username = 'nawaf-${Given.unique()}';
      await fillForm($, username);
      await $.goTo($(NewUserScreen.permissionKey(Permission.readProject)));
      expect($.isTicked(NewUserScreen.permissionKey(Permission.readProject)), isTrue);
      expect($.canTick(NewUserScreen.permissionKey(Permission.readProject)), isFalse);
      await $.tapOn(NewUserScreen.permissionKey(Permission.approveEntries));
      await send($);
      await $.idShowing('users.name.', 'نواف');
      expect(await Given.permissionsOf(manager, username), containsAll(['readProject', 'approveEntries']));
    });

    phoneCase('a username already taken is refused, and nothing typed is lost', ($) async {
      final manager = await onTheForm($);
      await fillForm($, manager.username);
      await send($);
      await $.says(NewUserScreen.messageKey, $.words.usersUsernameTaken);
      await $.goUpTo($(NewUserScreen.usernameKey));
      expect($.typed(NewUserScreen.usernameKey), manager.username);
    });

    phoneCase('empty required fields are refused, and the form stays', ($) async {
      await onTheForm($);
      await send($);
      await $.says(NewUserScreen.messageKey, $.words.usersInvalidUsername);
      expect($(NewUserScreen.submitKey), findsOneWidget);
    });

    phoneCase('without a network the form says so', ($) async {
      await onTheForm($);
      await fillForm($, 'nawaf-${Given.unique()}');
      await Pc.cutNetwork();
      await send($);
      await $.says(NewUserScreen.messageKey, $.words.usersNoConnection);
    });
  });
}
