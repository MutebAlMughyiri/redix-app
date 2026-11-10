import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/general_settings_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('The Settings screen (UC-009 and UC-010)', () {
    phoneCase('everyone has Switch project and Default project', ($) async {
      final admin = await Given.admin();
      await $.startApp();
      await $.signIn(admin.username, admin.password);
      await $.reach($(ProjectsScreen.generalSettingsKey));
      await $(ProjectsScreen.generalSettingsKey).tap();
      await $.reach($(GeneralSettingsScreen.switchProjectKey));
      expect($(GeneralSettingsScreen.defaultProjectKey), findsOneWidget);
      await $.reach($(GeneralSettingsScreen.registeredKey));
      await $.picture('settings');
    });

    phoneCase('Switch project reaches the list', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $(HomeScreen.generalSettingsKey(manager.projectId)).tap();
      await $.tapOn(GeneralSettingsScreen.switchProjectKey);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
    });

    phoneCase('Settings shows who is signed in', ($) async {
      final manager = await Given.manager(manager: 'ريم');
      await $.onTheList(manager);
      await $(ProjectsScreen.generalSettingsKey).tap();
      await $.says(GeneralSettingsScreen.whoKey.title, 'ريم');
      await $.says(GeneralSettingsScreen.whoKey.subtitle, manager.username);
      await $.picture('my-account');
    });

    phoneCase('Settings holds no project screen', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $(HomeScreen.generalSettingsKey(manager.projectId)).tap();
      await $.reach($(GeneralSettingsScreen.signOutKey));
      for (final key in [HomeScreen.projectInfoKey(manager.projectId), HomeScreen.usersKey(manager.projectId), HomeScreen.categoriesKey(manager.projectId), HomeScreen.paymentMethodsKey(manager.projectId)]) {
        expect($(key), findsNothing);
      }
    });
  });
}
