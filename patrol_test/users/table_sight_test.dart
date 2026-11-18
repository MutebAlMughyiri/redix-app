// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/users/table_ticks.dart';
import 'package:redix/users/users_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('«الجداول»: which tables a person sees (redix-api #106)', () {
    phoneCase('R4, R6: the manager unticks a table on a person\'s permissions, and its entry leaves their القيود', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.recordEntries]);
      final table = await Given.firstPurchaseTable(manager);
      final columns = await Given.subgroup(manager, table.itemId, 'الأعمدة');
      final seen = await Given.entry(manager, amount: 100);
      final unseen = await Given.entry(manager, amount: 200, itemId: table.itemId, tableId: columns);
      await Given.entriesApproved(manager, [seen, unseen]);
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.usersKey(manager.projectId));
      await $.tapOn(UsersScreen.menuKey(member.id));
      await $.tapOn(UsersScreen.permissionsKey);

      await $.tapOn(TableTicks.categoryKey(await Given.categoryOfTable(manager, columns)));
      await $.tapOn(TableTicks.tableKey(columns).body);
      await $.picture('table-ticks');

      expect($.isTicked(TableTicks.tableKey(columns)), isFalse);
      expect($.isTicked(TableTicks.tableKey(table.tableId)), isTrue);
      expect([for (final entry in await Given.entries(member)) entry['id']], [seen]);
    });

    phoneCase('D9, R7: صلاحياتي shows the tables one sees, read only, and that the periodic report is for whoever sees every table', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.seeReports]);
      final table = await Given.firstPurchaseTable(manager);
      final columns = await Given.subgroup(manager, table.itemId, 'الأعمدة');
      await Given.tableUnticked(manager, member, columns);
      await $.fromTheHome(member, HomeScreen.myPermissionsKey(member.projectId));

      await $.tapOn(TableTicks.categoryKey(await Given.categoryOfTable(member, table.tableId)));
      await $.reach($(TableTicks.tableKey(table.tableId)));

      expect($.isTicked(TableTicks.tableKey(table.tableId)), isTrue);
      expect($.canTick(TableTicks.tableKey(table.tableId)), isFalse);
      expect($(TableTicks.tableKey(columns)), findsNothing);
      await $.saysContaining(TableTicks.headingKey.subtitle, $.words.reportsPeriodicNotForYou);
      await $.picture('my-tables');
    });
  });
}
