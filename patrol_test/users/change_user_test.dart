import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/users/users_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A manager and a person in their project, the manager standing on the list of people.
Future<({Person manager, Person member})> onThePeople(PatrolIntegrationTester $) async {
  final manager = await Given.manager();
  final member = await Given.member(manager, mobile: '0533333333');
  await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
  await $.reach($(UsersScreen.nameKey(member.id)));
  return (manager: manager, member: member);
}

/// Answers Disable for [member], standing on its question.
Future<void> askToDisable(PatrolIntegrationTester $, Person member) async {
  await $.menuChoice(UsersScreen.menuKey(member.id), UsersScreen.disableKey);
  await $.reach($(ConfirmDialog.confirmKey));
}

void main() {
  phoneClass('Edit, reset, disable (UC-007)', () {
    phoneCase('editing a name updates the row', ($) async {
      final people = await onThePeople($);
      await $.menuChoice(UsersScreen.menuKey(people.member.id), UsersScreen.editKey);
      await $.reach($(UsersScreen.editNameKey));
      expect($.typed(UsersScreen.editNameKey), people.member.displayName);
      await $.fill(UsersScreen.editNameKey, 'نواف الأول');
      await $(ChangeDialog.saveKey).tap();
      await $.says(UsersScreen.nameKey(people.member.id), 'نواف الأول');
    });

    phoneCase('redix-api #127 AC-07.8: Edit starts from the email and changes it', ($) async {
      final people = await onThePeople($);
      final email = 'changed-${Given.unique()}@example.com';
      await $.menuChoice(UsersScreen.menuKey(people.member.id), UsersScreen.editKey);
      await $.reach($(UsersScreen.editEmailKey));
      expect($.typed(UsersScreen.editEmailKey), '${people.member.username}@example.com');
      await $.fill(UsersScreen.editEmailKey, email);
      await $(ChangeDialog.saveKey).tap();
      await $.gone($(UsersScreen.editEmailKey));
      await $.menuChoice(UsersScreen.menuKey(people.member.id), UsersScreen.editKey);
      await $.reach($(UsersScreen.editEmailKey));
      expect($.typed(UsersScreen.editEmailKey), email);
    });

    phoneCase('reset password names the user, and they must change it at the next sign-in', ($) async {
      final people = await onThePeople($);
      await $.menuChoice(UsersScreen.menuKey(people.member.id), UsersScreen.resetPasswordKey);
      await $.says(UsersScreen.resetNameKey, people.member.displayName);
      await $.fill(UsersScreen.resetPasswordFieldKey, 'Temporary-9');
      await $(ChangeDialog.saveKey).tap();
      await $.gone($(UsersScreen.resetPasswordFieldKey));
      await $.back();
      await $.signOutFromTheHome(people.manager.projectId);
      await $.signIn(people.member.username, 'Temporary-9');
      await $.reach($(ChangePasswordScreen.currentKey));
    });

    phoneCase('disabling asks first and says what it means, and Enable brings them back', ($) async {
      final people = await onThePeople($);
      await askToDisable($, people.member);
      await $.says(ConfirmDialog.explanationKey, $.words.usersDisableExplain);
      await $(ConfirmDialog.confirmKey).tap();
      await $.reach($(UsersScreen.statusKey(people.member.id)));
      await $.menuChoice(UsersScreen.menuKey(people.member.id), UsersScreen.enableKey);
      await $.gone($(UsersScreen.statusKey(people.member.id)));
    });

    phoneCase('redix-api #126 D1: a person made inactive in the project stays listed, muted, with «معطّل»', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await Given.disabled(member, by: manager);
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      await $.reach($(UsersScreen.nameKey(member.id)));
      await $.says(UsersScreen.statusKey(member.id).label, $.words.usersDisabled);
    });

    phoneCase('Cancel on Disable changes nothing', ($) async {
      final people = await onThePeople($);
      await askToDisable($, people.member);
      await $(ConfirmDialog.cancelKey).tap();
      await $.gone($(ConfirmDialog.confirmKey));
      expect($(UsersScreen.statusKey(people.member.id)), findsNothing);
    });

    phoneCase('the last manager of a project cannot be disabled, and the refusal says why', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      final id = await $.idOf('users.name.', () async => manager.id);
      await $.menuChoice(UsersScreen.menuKey(id), UsersScreen.disableKey);
      await $(ConfirmDialog.confirmKey).tap();
      await $.messageSays('users.lastManager', $.words.usersLastManager);
      expect($(UsersScreen.statusKey(id)), findsNothing);
    });

    phoneCase('a refused change stays in its dialog with what was typed', ($) async {
      final people = await onThePeople($);
      await $.menuChoice(UsersScreen.menuKey(people.member.id), UsersScreen.editKey);
      await $.fill(UsersScreen.editNameKey, ' ');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.usersInvalidName);
      expect($(UsersScreen.editNameKey), findsOneWidget);
    });
  });
}
