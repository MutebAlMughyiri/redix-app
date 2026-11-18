// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/reason_sheet.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Signs the admin in and stands on Settings.
Future<void> onSettingsAsAdmin(PatrolIntegrationTester $) async {
  final admin = await Given.admin();
  await $.startApp();
  await $.signIn(admin.username, admin.password);
  await $.reach($(ProjectsScreen.sharedSettingsKey));
  await $(ProjectsScreen.sharedSettingsKey).tap();
}

/// Signs the admin in and opens Registered projects.
Future<void> onRegisteredProjects(PatrolIntegrationTester $) async {
  await onSettingsAsAdmin($);
  await $.tapOn(SharedSettingsScreen.registeredKey);
}

void main() {
  phoneClass('Approve or reject a registered project (UC-066)', () {
    phoneCase('R11: the admin reads the project\'s description before deciding', ($) async {
      await Given.nothingWaiting();
      final manager = await Given.registered(project: 'غصون 7', manager: 'ريم', mobile: '0511111111', description: 'ثلاث فلل في حي الياسمين.', units: ['الفلة الشرقية', 'الفلة الشمالية']);
      await onRegisteredProjects($);
      await $.says(RegisteredProjectsScreen.descriptionKey(manager.projectId), 'ثلاث فلل في حي الياسمين.');
      await $.picture('registered-projects');
    });

    phoneCase('Approve sends it, it leaves the list, and its manager can open it', ($) async {
      final manager = await Given.registered();
      await onRegisteredProjects($);
      await $.tapOn(RegisteredProjectsScreen.approveKey(manager.projectId));
      await $.gone($(RegisteredProjectsScreen.cardKey(manager.projectId)));
      await $.back();
      await $.signOutFromSettings();
      await $.signIn(manager.username, manager.password);
      await $.openProject(manager.projectId);
      await $.says(HomeScreen.titleKey, manager.projectName);
    });

    phoneCase('a waiting project shows the manager\'s details', ($) async {
      final manager = await Given.registered(mobile: '0522222222');
      await onRegisteredProjects($);
      await $.goTo($(RegisteredProjectsScreen.managerKey(manager.projectId)));
      await $.says(RegisteredProjectsScreen.managerKey(manager.projectId), '${manager.displayName} · ${manager.username} · 0522222222');
    });

    phoneCase('R11: a project registered with no description shows no description line', ($) async {
      final manager = await Given.registered();
      await onRegisteredProjects($);
      await $.goTo($(RegisteredProjectsScreen.cardKey(manager.projectId)));
      expect($(RegisteredProjectsScreen.descriptionKey(manager.projectId)), findsNothing);
    });

    phoneCase('with nothing waiting, the list says so', ($) async {
      await Given.nothingWaiting();
      await onRegisteredProjects($);
      await $.says(ApiListBody.emptyKey, $.words.registeredEmpty);
    });

    phoneCase('Reject names the project, sends the reason, and it leaves the list', ($) async {
      final manager = await Given.registered();
      await onRegisteredProjects($);
      await $.tapOn(RegisteredProjectsScreen.rejectKey(manager.projectId));
      await $.says(ReasonSheet.aboutKey, manager.projectName);
      await $.fill(ReasonSheet.reasonKey, 'الاسم مكرر');
      await $.tapOn(ReasonSheet.sendKey);
      await $.gone($(RegisteredProjectsScreen.cardKey(manager.projectId)));
    });

    phoneCase('a rejected project tells its owner why, on the project list', ($) async {
      final manager = await Given.registered();
      await Given.rejected(manager.projectId, 'الاسم مكرر');
      await $.onTheList(manager);
      await $.says(ProjectsScreen.statusKey(manager.projectId).label, $.words.projectsRejected);
      await $.says(ProjectsScreen.reasonKey(manager.projectId), 'الاسم مكرر');
    });

    phoneCase('whoever does not approve projects has no Registered projects in Settings', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await $(ProjectsScreen.sharedSettingsKey).tap();
      await $.reach($(SharedSettingsScreen.whoKey));
      expect($(SharedSettingsScreen.registeredKey), findsNothing);
    });

    phoneCase('a rejected project offers its owner nothing', ($) async {
      final manager = await Given.registered();
      await Given.rejected(manager.projectId, 'الاسم مكرر');
      await $.onTheList(manager);
      expect($(ProjectsScreen.starKey(manager.projectId)), findsNothing);
      await $(ProjectsScreen.cardKey(manager.projectId)).tap();
      await $.pumpAndSettle();
      expect($(ProjectsScreen.titleKey), findsOneWidget);
    });

    phoneCase('a refused or empty reason stays in the sheet', ($) async {
      final manager = await Given.registered();
      await onRegisteredProjects($);
      await $.tapOn(RegisteredProjectsScreen.rejectKey(manager.projectId));
      await $.reach($(ReasonSheet.sendKey));
      await $(ReasonSheet.sendKey).tap();
      await $.says(ReasonSheet.messageKey, $.words.registeredInvalidReason);
      expect($(ReasonSheet.reasonKey), findsOneWidget);
    });

    phoneCase('without a network the list says so, and Try again reads it', ($) async {
      final manager = await Given.registered();
      await onSettingsAsAdmin($);
      await Pc.cutNetwork();
      await $.tapOn(SharedSettingsScreen.registeredKey);
      await $.says(ApiListBody.messageKey, $.words.registeredLoadFailed);
      await Pc.restoreNetwork();
      await $.tapOn(ApiListBody.retryKey);
      await $.reach($(RegisteredProjectsScreen.cardKey(manager.projectId)));
    });
  });
}
