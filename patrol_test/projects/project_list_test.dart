import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/words/language_switch.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('The project list (UC-010, UC-009)', () {
    phoneCase('a card opens its home', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await $.openProject(manager.projectId);
      await $.says(HomeScreen.titleKey, manager.projectName);
    });

    phoneCase('Arabic names show as typed', ($) async {
      final manager = await Given.manager(project: 'غصون 7', units: ['الفلة الشرقية', 'الفلة الشمالية']);
      await $.onTheList(manager);
      await $.says(ProjectsScreen.nameKey(manager.projectId), 'غصون 7');
      await $(ProjectsScreen.settingsKey).tap();
      await $.goTo($(LanguageSwitch.arabicKey));
      await $(LanguageSwitch.arabicKey).tap();
      await $.until(() => Directionality.of($.tester.element(find.byKey(SettingsScreen.languageKey))) == TextDirection.rtl);
      await $.tapOn(SettingsScreen.switchProjectKey);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      await $.picture('projects-arabic');
    });

    phoneCase('back from a home returns to the list', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      expect($.canGoBack, isTrue);
      await $.back();
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
    });

    phoneCase('only the projects I have access to show', ($) async {
      final mine = await Given.manager();
      final other = await Given.manager();
      await $.onTheList(mine);
      expect($(ProjectsScreen.cardKey(other.projectId)), findsNothing);
    });

    phoneCase('each project shows under its name its units and its status', ($) async {
      final manager = await Given.manager(units: ['الفلة الغربية', 'الفلة الجنوبية']);
      await $.onTheList(manager);
      await $.says(ProjectsScreen.detailsKey(manager.projectId), 'الفلة الغربية · الفلة الجنوبية');
      await $.says(ProjectsScreen.statusKey(manager.projectId).label, $.words.projectsActive);
    });

    phoneCase('AC-04.1: a finished project stays listed', ($) async {
      final manager = await Given.manager();
      await Given.closed(manager);
      await $.onTheList(manager);
      await $.says(ProjectsScreen.statusKey(manager.projectId).label, $.words.projectsFinished);
    });

    phoneCase('someone else\'s change shows when the list is read again', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      final renamed = 'Renamed ${Given.unique()}';
      await Given.renamed(manager, renamed);
      await $.pullDown();
      await $.says(ProjectsScreen.nameKey(manager.projectId), renamed);
    });

    phoneCase('the list has no change buttons', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      expect($(HomeScreen.settingsKey(manager.projectId)), findsNothing);
      expect($(HomeScreen.usersKey(manager.projectId)), findsNothing);
    });

    phoneCase('a project taken away while it is open returns to the list', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await $.onTheHome(member);
      await $(HomeScreen.settingsKey(member.projectId)).tap();
      await $.reach($(SettingsScreen.signOutKey));
      await Given.removed(member, by: manager);
      await $.back();
      await $.reach($(ProjectsScreen.titleKey));
      expect($(ProjectsScreen.cardKey(member.projectId)), findsNothing);
    });

    phoneCase('a person with no projects is told the list is empty', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await Given.removed(member, by: manager);
      await $.startApp();
      await $.signIn(member.username, member.password);
      await $.reach($(ProjectsScreen.titleKey));
      await $.says(ApiListBody.emptyKey, $.words.projectsEmpty);
    });
  });
}
