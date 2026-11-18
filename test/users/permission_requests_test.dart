// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/notifications/notifications_bell.dart';
import 'package:redix/notifications/notifications_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/one_field_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/reason_sheet.dart';
import 'package:redix/users/my_permissions_screen.dart';
import 'package:redix/users/permission_request_screen.dart';
import 'package:redix/users/permission_requests_screen.dart';

import '../app_harness.dart';

/// redix-api #112: a person asks from صلاحياتي to change their own permissions, and whoever manages the project's users approves or refuses it.
void main() {
  const project = 'project-0';
  const sara = ['readProject', 'seeReports'];

  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// صلاحياتي of a project seen with [permissions].
  Future<FakeApi> onMyPermissions(WidgetTester tester, {List<String> permissions = sara, void Function(FakeApi api)? arrange}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions);
    arrange?.call(api);
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.myPermissionsKey(project));
    return api;
  }

  /// The tick of [permission] on the request screen.
  Future<void> tick(WidgetTester tester, Permission permission) async {
    final tickKey = PermissionRequestScreen.permissionKey(permission).body;
    await tester.ensureVisible(find.byKey(tickKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(tickKey));
    await tester.pumpAndSettle();
  }

  testWidgets('R1, R5, R8: «طلب تغيير» opens the ticks; what is ticked is asked for and what is unticked given up, sent with its reason', (tester) async {
    final api = await onMyPermissions(tester);
    await act(tester, api, () => tester.tap(find.byKey(MyPermissionsScreen.askKey)));
    expect(isEnabled(tester, PermissionRequestScreen.sendKey), isFalse, reason: 'nothing asked yet');

    await tick(tester, Permission.moveMoney);
    await tick(tester, Permission.seeReports);
    await act(tester, api, () => tester.tap(find.byKey(PermissionRequestScreen.sendKey)));
    expect(text(tester, PermissionRequestScreen.askedKey), 'en permissionRequests.gives en permissions.moveMoney\nen permissionRequests.takes en permissions.seeReports');
    await tester.enterText(find.byKey(OneFieldDialog.fieldKey), 'أنقل المال');
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(api.sentPermissionRequests, [
      {
        'gives': ['moveMoney'],
        'takes': ['seeReports'],
        'reason': 'أنقل المال',
      },
    ]);
    expect(find.byKey(messageKeyOf('permissionRequests.sent')), findsOneWidget);
    expect(find.byType(MyPermissionsScreen), findsOneWidget);
  });

  testWidgets('R1: being in the project is not asked for, and one capital tick takes the other', (tester) async {
    final api = await onMyPermissions(tester, permissions: const ['readProject', 'seeAllCapital']);
    await act(tester, api, () => tester.tap(find.byKey(MyPermissionsScreen.askKey)));

    expect(tester.widget<CheckboxListTile>(find.byKey(PermissionRequestScreen.permissionKey(Permission.readProject).body)).onChanged, isNull);
    await tick(tester, Permission.seeChosenCapital);
    expect(tester.widget<CheckboxListTile>(find.byKey(PermissionRequestScreen.permissionKey(Permission.seeAllCapital).body)).value, isFalse);
  });

  testWidgets('R7: a waiting request shows what it asks above the ticks, and withdrawing it sends the withdrawal', (tester) async {
    final api = await onMyPermissions(tester, arrange: (api) => api.myPermissionRequest = [FakeApi.permissionRequestRow(displayName: '')]);

    final askedAt = momentOf('2026-11-18T10:00:00Z');
    expect(text(tester, MyPermissionsScreen.requestKey), [
      'en permissionRequests.waiting',
      'en permissionRequests.gives en permissions.moveMoney',
      'en permissionRequests.takes en permissions.seeReports',
      'أنقل المال',
      '${formatDate(askedAt)} ${formatTime(askedAt)}',
    ].join('\n'));
    api.myPermissionRequest = [];
    await act(tester, api, () => tester.tap(find.byKey(MyPermissionsScreen.withdrawKey)));

    expect(api.permissionDecisions.single.$1, '/projects/$project/permission-requests/mine');
    expect(find.byKey(MyPermissionsScreen.requestKey), findsNothing);
  });

  testWidgets('R8: a refused request says why on صلاحياتي', (tester) async {
    await onMyPermissions(tester, arrange: (api) => api.myPermissionRequest = [FakeApi.permissionRequestRow(status: 'rejected', rejectionReason: 'ليس الآن')]);

    expect(text(tester, MyPermissionsScreen.requestKey), 'en permissionRequests.rejected ليس الآن');
    expect(find.byKey(MyPermissionsScreen.withdrawKey), findsNothing);
  });

  /// «طلبات الصلاحيات» of a manager, one request waiting.
  Future<FakeApi> onRequests(WidgetTester tester) async {
    final api = FakeApi()..addProject('غصون 6');
    api.waitingPermissionRequests.add(FakeApi.permissionRequestRow());
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.permissionRequestsKey(project));
    return api;
  }

  testWidgets('R3, R4: a manager sees who asks, what and why, and approving sends the approval', (tester) async {
    final api = await onRequests(tester);

    expect(text(tester, PermissionRequestsScreen.rowKey('request-0').title), 'سارة');
    expect(text(tester, PermissionRequestsScreen.rowKey('request-0').subtitle), startsWith('en permissionRequests.gives en permissions.moveMoney\n'));
    await act(tester, api, () => tester.tap(find.byKey(PermissionRequestsScreen.approveKey('request-0'))));

    expect(api.permissionDecisions.single.$1, '/projects/$project/permission-requests/request-0/approve');
    expect(text(tester, messageKeyOf('permissionRequests.approvedDone').label), 'en permissionRequests.approvedDone سارة');
  });

  testWidgets('R8: refusing asks why, and sends it', (tester) async {
    final api = await onRequests(tester);

    await act(tester, api, () => tester.tap(find.byKey(PermissionRequestsScreen.rejectKey('request-0'))));
    expect(text(tester, ReasonSheet.titleKey), 'en permissionRequests.rejectTitle سارة');
    await tester.enterText(find.byKey(ReasonSheet.reasonKey), 'ليس الآن');
    await act(tester, api, () => tester.tap(find.byKey(ReasonSheet.sendKey)));

    expect(api.permissionDecisions.single.$1, '/projects/$project/permission-requests/request-0/reject');
    expect(api.permissionDecisions.single.$2, {'reason': 'ليس الآن'});
  });

  testWidgets('R3: without «إدارة المستخدمين» the card has no «طلبات الصلاحيات»', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: sara);
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.permissionRequestsKey(project));

    expect(find.byKey(HomeScreen.permissionRequestsKey(project)), findsNothing);
  });

  for (final (kind, screen) in [('permissionRequested', PermissionRequestsScreen), ('permissionRequestRejected', MyPermissionsScreen)]) {
    testWidgets('R6: the notice $kind opens $screen', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      api.addNotification(kind: kind);
      await openProject(tester, api);
      await act(tester, api, () => tester.tap(find.byKey(NotificationsBell.buttonKey)));

      expect(text(tester, NotificationsScreen.rowKey('notification-0').title), 'en notifications.$kind');
      await act(tester, api, () => tester.tap(find.byKey(NotificationsScreen.rowKey('notification-0'))));
      expect(find.byType(screen), findsOneWidget);
    });
  }
}
