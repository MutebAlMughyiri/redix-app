import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/users/my_permissions_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('صلاحياتي (Muteb, 9 Nov 2026)', () {
    phoneCase('it shows what I hold, ticked', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.recordEntries]);
      await $.fromTheHome(member, HomeScreen.myPermissionsKey(member.projectId));
      await $.reach($(MyPermissionsScreen.hintKey));
      await $.goTo($(MyPermissionsScreen.permissionKey(Permission.recordEntries)));
      expect($.isTicked(MyPermissionsScreen.permissionKey(Permission.recordEntries)), isTrue);
      await $.goTo($(MyPermissionsScreen.permissionKey(Permission.approveEntries)));
      expect($.isTicked(MyPermissionsScreen.permissionKey(Permission.approveEntries)), isFalse);
    });

    phoneCase('nothing on it can be changed', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.myPermissionsKey(manager.projectId));
      await $.goTo($(MyPermissionsScreen.permissionKey(Permission.recordEntries)));
      expect($.canTick(MyPermissionsScreen.permissionKey(Permission.recordEntries)), isFalse);
    });
  });
}
