// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/one_field_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/reason_sheet.dart';
import 'package:redix/users/my_permissions_screen.dart';
import 'package:redix/users/permission_request_screen.dart';
import 'package:redix/users/permission_requests_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Ask for a permission change, and the manager decides it (redix-api #112)', () {
    phoneCase('R1, R5, R8: someone asks from صلاحياتي for a permission, with its reason, and it waits for the manager', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.seeReports]);
      await $.onTheHome(member);
      await $.tapOn(HomeScreen.myPermissionsKey(member.projectId));
      await $.tapOn(MyPermissionsScreen.askKey);

      await $.tapOn(PermissionRequestScreen.permissionKey(Permission.moveMoney).body);
      await $.tapOn(PermissionRequestScreen.sendKey);
      await $.fill(OneFieldDialog.fieldKey, 'أنقل المال');
      await $.picture('permission-request');
      await $.tapOn(ChangeDialog.saveKey);

      await $.messageShows('permissionRequests.sent');
      final waiting = await Given.waitingPermissionRequests(manager);
      expect(waiting.single['gives'], ['moveMoney']);
      expect(waiting.single['reason'], 'أنقل المال');
    });

    phoneCase('R3, R4: the manager approves a request from «طلبات الصلاحيات», and the person holds what they asked', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      final request = await Given.permissionRequested(member);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.permissionRequestsKey(manager.projectId));

      await $.picture('permission-requests');
      await $.tapOn(PermissionRequestsScreen.approveKey(request));

      await $.messageShows('permissionRequests.approvedDone');
      expect(await Given.permissionsOf(manager, member.username), contains('moveMoney'));
    });

    phoneCase('R8: the manager refuses a request with its reason, and the person reads it on صلاحياتي', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      final request = await Given.permissionRequested(member);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.permissionRequestsKey(manager.projectId));
      await $.tapOn(PermissionRequestsScreen.rejectKey(request));
      await $.fill(ReasonSheet.reasonKey, 'ليس الآن');
      await $.tapOn(ReasonSheet.sendKey);
      await $.messageShows('permissionRequests.rejectedDone');

      await $.onTheHome(member);
      await $.tapOn(HomeScreen.myPermissionsKey(member.projectId));
      await $.saysContaining(MyPermissionsScreen.requestKey, 'ليس الآن');
      expect(await Given.permissionsOf(manager, member.username), isNot(contains('moveMoney')));
    });
  });
}
