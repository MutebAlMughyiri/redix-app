// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/notifications/notifications_bell.dart';
import 'package:redix/notifications/notifications_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openList(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = field}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions);
    arrange(api);
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(NotificationsBell.buttonKey)));
    return api;
  }

  testWidgets('the bell counts what was not seen', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    api
      ..addNotification()
      ..addNotification(isRead: true);
    await pumpRedix(tester, api, stored: {'session': keptSession});

    final badge = tester.widget<Badge>(find.byKey(NotificationsBell.buttonKey.label));
    expect((badge.isLabelVisible, (badge.label! as Text).data), (true, '1'));
  });

  testWidgets('the list says what happened, in which project, in the words of the phone', (tester) async {
    await openList(tester, (api) => api.addNotification(kind: 'entryRejected'));

    expect(tester.widget<Text>(find.byKey(NotificationsScreen.rowKey('notification-0').title)).data, 'en notifications.entryRejected');
    expect(tester.widget<Text>(find.byKey(NotificationsScreen.rowKey('notification-0').subtitle)).data, contains('غصون 6'));
  });

  testWidgets('with nothing told the list says so', (tester) async {
    await openList(tester, (api) {});

    expect(tester.widget<Text>(find.byKey(ApiListBody.emptyKey)).data, 'en notifications.empty');
  });

  testWidgets('AC-20.1: tapping a decision opens the entry, and marks it seen', (tester) async {
    final api = await openList(tester, (api) {
      api
        ..addEntry(status: 'rejected', rejectionReason: 'الصورة غير واضحة')
        ..addNotification(kind: 'entryRejected', entryId: 'entry-0');
    });

    await act(tester, api, () => tester.tap(find.byKey(NotificationsScreen.rowKey('notification-0'))));

    expect(find.byKey(AddEntryScreen.changeKey), findsOneWidget);
    expect(api.notificationRows.single['isRead'], isTrue);

    await act(tester, api, () => tester.pageBack());
    expect(find.byKey(NotificationsScreen.rowKey('notification-0')), findsOneWidget);
  });

  testWidgets('tapping what waits for a decision opens the inbox', (tester) async {
    final api = await openList(tester, (api) {
      api
        ..addPending()
        ..addNotification(entryId: 'entry-0');
    }, permissions: managerAndFinance);

    await act(tester, api, () => tester.tap(find.byKey(NotificationsScreen.rowKey('notification-0'))));

    expect(find.byKey(ApprovalsScreen.cardKey('entry-0')), findsOneWidget);
  });

  testWidgets('tapping a decided project goes to the project list, which says why', (tester) async {
    final api = await openList(tester, (api) => api.addNotification(kind: 'projectRejected', entryId: emptyGuid));

    await act(tester, api, () => tester.tap(find.byKey(NotificationsScreen.rowKey('notification-0'))));

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });
}
