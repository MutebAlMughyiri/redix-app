import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/users/users_screen.dart';
import 'package:redix/words/language_switch.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('The people of a project (UC-007 and UC-008)', () {
    phoneCase('everyone added shows, each row with the whole menu', ($) async {
      final manager = await Given.manager(project: 'غصون 7', manager: 'ريم');
      final member = await Given.member(manager, name: 'نواف', mobile: '0533333333');
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      await $.says(UsersScreen.nameKey(member.id), 'نواف');
      await $.picture('users');
      await $.tapOn(UsersScreen.menuKey(member.id));
      for (final key in [UsersScreen.editKey, UsersScreen.permissionsKey, UsersScreen.resetPasswordKey, UsersScreen.disableKey]) {
        await $.reach($(key));
      }
    });

    phoneCase('the people show in Arabic too', ($) async {
      final manager = await Given.manager(project: 'غصون 7', manager: 'ريم');
      await Given.member(manager, name: 'نواف', mobile: '0533333333');
      await $.onTheList(manager);
      await $(ProjectsScreen.sharedSettingsKey).tap();
      await $.goTo($(LanguageSwitch.arabicKey));
      await $(LanguageSwitch.arabicKey).tap();
      await $.until(() => Directionality.of($.tester.element(find.byKey(SharedSettingsScreen.languageKey))) == TextDirection.rtl);
      await $.tapOn(SharedSettingsScreen.switchProjectKey);
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.usersKey(manager.projectId));
      await $.idShowing('users.name.', 'نواف');
      await $.picture('users-arabic');
    });

    phoneCase('only this project\'s people show', ($) async {
      final manager = await Given.manager();
      final other = await Given.member(await Given.manager());
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      await $.idShowing('users.name.', manager.displayName);
      expect($(UsersScreen.nameKey(other.id)), findsNothing);
    });

    phoneCase('a row shows the username alone when there is no mobile', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      await $.says(UsersScreen.detailsKey(member.id), member.username);
    });

    phoneCase('an existing user is added by username', ($) async {
      final manager = await Given.manager();
      final other = await Given.member(await Given.manager());
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      await $.tapOn(UsersScreen.addExistingKey);
      await $.fill(UsersScreen.existingUsernameKey, other.username);
      await $(ChangeDialog.saveKey).tap();
      await $.reach($(UsersScreen.nameKey(other.id)));
    });

    phoneCase('an unknown username says so', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.usersKey(manager.projectId));
      await $.tapOn(UsersScreen.addExistingKey);
      await $.fill(UsersScreen.existingUsernameKey, 'nobody-${Given.unique()}');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.usersUnknownUser);
    });

    phoneCase('without a network the list says so', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await Pc.cutNetwork();
      await $.tapOn(HomeScreen.usersKey(manager.projectId));
      await $.says(ApiListBody.messageKey, $.words.usersLoadFailed);
    });
  });
}
