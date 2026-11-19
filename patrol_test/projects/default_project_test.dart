// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/default_project_sheet.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/messages.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// The icon of the star on the card of [projectId].
IconData starOf(PatrolIntegrationTester $, String projectId) => $.tester.widget<Icon>(find.byKey(ProjectsScreen.starKey(projectId).icon)).icon!;

/// Whether the project [projectId] is ticked in Default project.
bool isTicked(PatrolIntegrationTester $, String projectId) => $.tester.widget<CheckboxListTile>(find.byKey(DefaultProjectSheet.optionKey(projectId))).value!;

/// Opens Default project from the list, standing on the sheet.
Future<void> openSheet(PatrolIntegrationTester $, String projectId) async {
  await $(ProjectsScreen.sharedSettingsKey).tap();
  await $.tapOn(SharedSettingsScreen.defaultProjectKey);
  await $.reach($(DefaultProjectSheet.optionKey(projectId)));
}

/// Ticks or unticks [projectId] in the sheet, waiting until it is [ticked].
Future<void> tick(PatrolIntegrationTester $, String projectId, {required bool ticked}) async {
  await $(DefaultProjectSheet.optionKey(projectId)).tap();
  await $.until(() => isTicked($, projectId) == ticked);
  expect(isTicked($, projectId), ticked);
}

void main() {
  phoneClass('The default project (UC-010)', () {
    phoneCase('AC-37.1: the star makes a project the default', ($) async {
      final manager = await Given.manager(project: 'مشروع B', units: ['الفلة الشرقية', 'الفلة الشمالية']);
      await $.onTheList(manager);
      expect(starOf($, manager.projectId), Icons.star_border);
      await $(ProjectsScreen.starKey(manager.projectId)).tap();
      await $.until(() => starOf($, manager.projectId) == Icons.star);
      expect(starOf($, manager.projectId), Icons.star);
      await $.picture('projects');
    });

    phoneCase('Default project in Settings ticks the default', ($) async {
      final manager = await Given.manager(project: 'مشروع B');
      await $.onTheList(manager);
      await openSheet($, manager.projectId);
      expect(isTicked($, manager.projectId), isFalse);
      await tick($, manager.projectId, ticked: true);
      await $.picture('default-project');
    });

    phoneCase('AC-37.1: a default opens directly at sign-in, with no way back', ($) async {
      final manager = await Given.manager();
      await Given.defaultProject(manager);
      await $.startApp();
      await $.signIn(manager.username, manager.password);
      await $.reach($(HomeScreen.titleKey));
      await $.says(HomeScreen.titleKey, manager.projectName);
      expect($.canGoBack, isFalse);
    });

    phoneCase('AC-37.1: a default opens directly at the next start', ($) async {
      final manager = await Given.manager();
      await Given.defaultProject(manager);
      await $.startApp();
      await $.signIn(manager.username, manager.password);
      await $.reach($(HomeScreen.titleKey));
      await $.restartApp();
      await $.reach($(HomeScreen.titleKey));
      await $.says(HomeScreen.titleKey, manager.projectName);
    });

    phoneCase('AC-37.1: the star and the tick say so in a message', ($) async {
      final mine = await Given.manager();
      final other = await Given.manager();
      await Given.joined(mine, by: other);
      await $.onTheList(mine);
      await $(ProjectsScreen.starKey(mine.projectId)).tap();
      final message = $(messageKeyOf('projects.defaultSet').label);
      await message.waitUntilExists();
      await $.gone(message);
      await openSheet($, other.projectId);
      await $(DefaultProjectSheet.optionKey(other.projectId)).tap();
      await message.waitUntilExists();
    });

    phoneCase('ticking another moves the default', ($) async {
      final mine = await Given.manager();
      final other = await Given.manager();
      await Given.joined(mine, by: other);
      await $.onTheList(mine);
      await openSheet($, mine.projectId);
      await tick($, mine.projectId, ticked: true);
      await tick($, other.projectId, ticked: true);
      await $.until(() => !isTicked($, mine.projectId));
      expect(isTicked($, mine.projectId), isFalse);
    });

    phoneCase('unticking clears it, and the next sign-in lands on the list', ($) async {
      final manager = await Given.manager();
      await Given.defaultProject(manager);
      await $.startApp();
      await $.signIn(manager.username, manager.password);
      await $.reach($(HomeScreen.titleKey));
      await $(HomeScreen.sharedSettingsKey(manager.projectId)).tap();
      await $.tapOn(SharedSettingsScreen.defaultProjectKey);
      await $.reach($(DefaultProjectSheet.optionKey(manager.projectId)));
      await tick($, manager.projectId, ticked: false);
      await $.back();
      await $.signOutFromSettings();
      await $.signIn(manager.username, manager.password);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      expect($(HomeScreen.titleKey), findsNothing);
    });

    phoneCase('Switch project from a default opens the list, with the back arrow to Settings (the owner, 11 Nov 2026)', ($) async {
      final manager = await Given.manager();
      await Given.defaultProject(manager);
      await $.startApp();
      await $.signIn(manager.username, manager.password);
      await $.reach($(HomeScreen.titleKey));
      await $(HomeScreen.sharedSettingsKey(manager.projectId)).tap();
      await $.tapOn(SharedSettingsScreen.switchProjectKey);
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      expect($.canGoBack, isTrue);
      await $.back();
      await $.reach($(SharedSettingsScreen.whoKey));
    });

    phoneCase('waiting and rejected projects are not offered in Default project', ($) async {
      final manager = await Given.manager();
      final waiting = await Given.started(manager);
      final rejected = await Given.started(manager);
      await Given.rejected(rejected, 'الاسم مكرر');
      await $.onTheList(manager);
      await openSheet($, manager.projectId);
      expect($(DefaultProjectSheet.optionKey(waiting)), findsNothing);
      expect($(DefaultProjectSheet.optionKey(rejected)), findsNothing);
    });

    phoneCase('a default the person no longer has access to lands on the list', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await Given.defaultProject(member);
      await Given.removed(member, by: manager);
      await $.startApp();
      await $.signIn(member.username, member.password);
      await $.reach($(ProjectsScreen.titleKey));
      expect($(HomeScreen.titleKey), findsNothing);
    });
  });
}
