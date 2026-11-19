// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('My custody on the home (UC-015)', () {
    phoneCase('AC-22.1: a custodian sees their custody on the home', ($) async {
      final manager = await Given.manager(project: 'مشروع B', manager: 'ريم');
      final custody = await Given.account(manager, name: 'كاش مع مدير المشروع', custodian: manager);
      await Given.funded(manager, custody, 2750);
      await $.onTheHome(manager);
      await $.reach($(HomeScreen.custodyKey(custody)));
      await $.says(HomeScreen.custodyBalanceKey(custody), '2,750.00 ${$.words.accountsRiyal}');
      await $.picture('my-custody');
    });

    phoneCase('its balance follows an approved expense paid from it', ($) async {
      final manager = await Given.manager();
      final custody = await Given.account(manager, custodian: manager);
      await Given.funded(manager, custody, 1000);
      await Given.entriesApproved(manager, [await Given.entry(manager, accountId: custody, amount: 100)]);
      await $.onTheHome(manager);
      await $.reach($(HomeScreen.custodyBalanceKey(custody)));
      await $.says(HomeScreen.custodyBalanceKey(custody), '900.00 ${$.words.accountsRiyal}');
    });

    phoneCase('AC-22.1: nobody else sees it', ($) async {
      final manager = await Given.manager();
      final custody = await Given.account(manager, custodian: manager);
      final member = await Given.member(manager);
      await $.onTheHome(member);
      await $.goTo($(HomeScreen.documentsKey(member.projectId)));
      expect($(HomeScreen.custodyKey(custody)), findsNothing);
    });

    phoneCase('a disabled custody leaves the home', ($) async {
      final manager = await Given.manager();
      final custody = await Given.account(manager, custodian: manager);
      await Given.accountDisabled(manager, custody);
      await $.onTheHome(manager);
      await $.goTo($(HomeScreen.documentsKey(manager.projectId)));
      expect($(HomeScreen.custodyKey(custody)), findsNothing);
    });
  });
}
