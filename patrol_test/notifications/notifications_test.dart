// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/notifications/notifications_bell.dart';
import 'package:redix/notifications/notifications_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// What the bell counts now.
int? bellCount(PatrolIntegrationTester $) => $.tester.widget<Badge>(find.byKey(NotificationsBell.buttonKey.label)).isLabelVisible ? int.tryParse(($.tester.widget<Badge>(find.byKey(NotificationsBell.buttonKey.label)).label! as Text).data!) : 0;

/// Someone whose entry was just decided, and the manager who decided it.
Future<({Person manager, Person author, String entry})> withDecision() async {
  final manager = await Given.manager();
  final author = await Given.member(manager, permissions: [Permission.recordEntries, Permission.chargeAnyAccount]);
  final entry = await Given.entry(author, accountId: await Given.account(manager));
  await Given.entryRejected(manager, entry);
  return (manager: manager, author: author, entry: entry);
}

/// The id of the newest notification of [kind] that [person] was told, such as `entryRejected`.
Future<String> toldOf(Person person, String kind) async => (await Given.notifications(person)).firstWhere((notification) => notification['kind'] == kind)['id'] as String;

/// Opens from the bell the newest notification of [kind] that [person] was told.
Future<void> openTold(PatrolIntegrationTester $, Person person, String kind) async {
  final notification = $(NotificationsScreen.rowKey(await toldOf(person, kind)));
  await $(NotificationsBell.buttonKey).tap();
  await $.reach(notification);
  await notification.tap();
  await $.pumpAndSettle();
}

void main() {
  phoneClass('Notifications (UC-036)', () {
    phoneCase('the bell counts what was not seen', ($) async {
      final made = await withDecision();
      await $.onTheList(made.author);
      await $.until(() => bellCount($) == 1);
      expect(bellCount($), 1);
    });

    phoneCase('the list says what happened and where, in the phone\'s language', ($) async {
      final made = await withDecision();
      await $.onTheList(made.author);
      await $(NotificationsBell.buttonKey).tap();
      await $.saysContaining(NotificationsScreen.rowKey(await toldOf(made.author, 'entryRejected')).subtitle, made.author.projectName);
    });

    phoneCase('AC-20.1: tapping a decision opens the entry, and marks it seen', ($) async {
      final made = await withDecision();
      await $.onTheList(made.author);
      await openTold($, made.author, 'entryRejected');
      await $.says(AddEntryScreen.statusKey, $.words.entriesRejected);
    });

    phoneCase('tapping what waits opens the inbox', ($) async {
      final manager = await Given.manager();
      final author = await Given.member(manager, permissions: [Permission.recordEntries, Permission.chargeAnyAccount]);
      final entry = await Given.entry(author, accountId: await Given.account(manager));
      await $.onTheList(manager);
      await openTold($, manager, 'entrySubmitted');
      await $.reach($(ApprovalsScreen.cardKey(entry)));
    });

    phoneCase('tapping a decided project goes to the project list, which says why', ($) async {
      final manager = await Given.registered();
      await Given.rejected(manager.projectId, 'الاسم مكرر');
      await $.onTheList(manager);
      await openTold($, manager, 'projectRejected');
      await $.says(ProjectsScreen.reasonKey(manager.projectId), 'الاسم مكرر');
    });

    phoneCase('a notification already seen stops counting', ($) async {
      final made = await withDecision();
      await $.onTheList(made.author);
      await openTold($, made.author, 'entryRejected');
      await $.reach($(AddEntryScreen.statusKey));
      for (var step = 0; step < 4 && find.byKey(ProjectsScreen.titleKey).evaluate().isEmpty; step++) {
        await $.back();
      }
      await $.reach($(ProjectsScreen.titleKey));
      await $.until(() => bellCount($) == 0);
      expect(bellCount($), 0);
    });
  });
}
