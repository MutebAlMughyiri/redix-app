import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
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
      await $.reach($(ProjectsScreen.settingsKey));
      await $(ProjectsScreen.settingsKey).tap();
      await $.reach($(SettingsScreen.switchProjectKey));
      expect($(SettingsScreen.defaultProjectKey), findsOneWidget);
      await $.reach($(SettingsScreen.registeredKey));
      await $.picture('settings');
    });

    phoneCase('Switch project reaches the list', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $(HomeScreen.settingsKey(manager.projectId)).tap();
      await $.tapOn(SettingsScreen.switchProjectKey);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
    });

    phoneCase('Settings shows who is signed in', ($) async {
      final manager = await Given.manager(manager: 'ريم');
      await $.onTheList(manager);
      await $(ProjectsScreen.settingsKey).tap();
      await $.says(SettingsScreen.whoKey.title, 'ريم');
      await $.says(SettingsScreen.whoKey.subtitle, manager.username);
      await $.picture('my-account');
    });

    phoneCase('Settings holds no project screen', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $(HomeScreen.settingsKey(manager.projectId)).tap();
      await $.reach($(SettingsScreen.signOutKey));
      for (final key in [HomeScreen.projectInfoKey(manager.projectId), HomeScreen.usersKey(manager.projectId), HomeScreen.categoriesKey(manager.projectId), HomeScreen.paymentMethodsKey(manager.projectId)]) {
        expect($(key), findsNothing);
      }
    });
  });
}
