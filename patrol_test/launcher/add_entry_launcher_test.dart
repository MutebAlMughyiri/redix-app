// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/api.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entry_link_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/launcher/launcher_add_entry.dart';
import 'package:redix/projects/projects_screen.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// The link the widget's «إضافة قيد» opens, on the host of the environment the app was built for.
const addEntryLink = 'https://$linkHost${LauncherAddEntry.path}';

/// Starts the app and signs [person] in, standing on the home of their default project, where sign-in lands.
Future<void> onTheDefaultHome(PatrolIntegrationTester $, Person person) async {
  await $.startApp();
  await $.signIn(person.username, person.password);
  await $.reach($(HomeScreen.titleKey));
}

void main() {
  phoneClass('Add an entry from the app\'s icon and the home-screen widget (UC-072)', () {
    phoneCase('redix-app #86 AC-86.2: the widget\'s «إضافة قيد» opens Add entry in the default project, its home behind', ($) async {
      final manager = await Given.manager();
      await Given.defaultProject(manager);
      await onTheDefaultHome($, manager);
      await Pc.tapTheWidget(addEntryLink);
      await $(AddEntryScreen.tableKey).waitUntilExists();
      expect($.canGoBack, isTrue);
    });

    phoneCase('redix-app #86 AC-86.3: without a default project, the widget\'s «إضافة قيد» opens the project list', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await Pc.tapTheWidget(addEntryLink);
      await $(ProjectsScreen.cardKey(manager.projectId)).waitUntilExists();
      expect($(AddEntryScreen.tableKey), findsNothing);
    });

    phoneCase('redix-app #86 AC-86.6: for whoever may not record in the default project, the widget opens its home, «إضافة قيد» gray', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await Given.defaultProject(member);
      await onTheDefaultHome($, member);
      await Pc.tapTheWidget(addEntryLink);
      await $.reach($(HomeScreen.addEntryKey(member.projectId)));
      expect($.isEnabled(HomeScreen.addEntryKey(member.projectId)), isFalse);
      expect($(AddEntryScreen.tableKey), findsNothing);
    });

    phoneCase('redix-app #86 AC-86.5: signed out, the widget\'s «إضافة قيد» opens sign-in', ($) async {
      await $.startApp();
      await Pc.tapTheWidget(addEntryLink);
      await $.pumpAndSettle();
      await $.reach($(SignInScreen.usernameKey));
      expect($(AddEntryScreen.tableKey), findsNothing);
    });

    phoneCase('redix-app #86 AC-86.7: a row of the widget opens its entry', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      final member = await Given.member(manager);
      await $.onTheList(member);
      await Pc.tapTheWidget('https://$linkHost${EntryLinkScreen.pathOf(member.projectId, entry)}');
      await $.says(AddEntryScreen.statusKey, $.words.entriesPendingApproval);
    });
  });
}
