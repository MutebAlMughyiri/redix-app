// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/approvals/approval_history_screen.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/format/number_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/search_scope.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/search_steps.dart';
import '../support/steps.dart';

/// Signs [manager] in and opens what waits.
Future<void> onApprovals(PatrolIntegrationTester $, Person manager) async {
  await $.fromTheHome(manager, HomeScreen.approvalsKey(manager.projectId));
  await $.reach($(SearchIcons.searchKey));
}

void main() {
  phoneClass('Approve entries (UC-031)', () {
    phoneCase('Approve selected sends what was ticked, and they leave', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final first = await Given.entry(manager, accountId: account);
      final second = await Given.entry(manager, accountId: account);
      final kept = await Given.entry(manager, accountId: account);
      await onApprovals($, manager);
      await $.tapOn(ApprovalsScreen.selectKey(first));
      await $.tapOn(ApprovalsScreen.selectKey(second));
      await $.tapOn(ApprovalsScreen.approveSelectedKey);
      await $.gone($(ApprovalsScreen.cardKey(first)));
      await $.gone($(ApprovalsScreen.cardKey(second)));
      await $.reach($(ApprovalsScreen.cardKey(kept)));
      expect(await Given.waitingIds(manager), [kept]);
    });

    phoneCase('a double tap on Approve sends one approval, and the button is gray in between', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await onApprovals($, manager);
      await $.goTo($(ApprovalsScreen.approveKey(entry)));
      final approve = find.byKey(ApprovalsScreen.approveKey(entry));
      await $.tester.tap(approve);
      await $.tester.tap(approve, warnIfMissed: false);
      await $.tester.pump();
      expect($.isEnabled(ApprovalsScreen.approveKey(entry)), isFalse);
      await $.gone($(ApprovalsScreen.cardKey(entry)));
      expect(find.byType(SnackBar), findsNothing);
      expect(await Given.waitingIds(manager), isEmpty);
    });

    phoneCase('approving one sends it, and it leaves', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await onApprovals($, manager);
      await $.tapOn(ApprovalsScreen.approveKey(entry));
      await $.gone($(ApprovalsScreen.cardKey(entry)));
      expect(await Given.waitingIds(manager), isEmpty);
    });

    phoneCase('an entry someone else decided meanwhile leaves the inbox when Approve is tapped', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await onApprovals($, manager);
      await Given.entryRejected(manager, entry);
      await $.tapOn(ApprovalsScreen.approveKey(entry));
      await $.gone($(ApprovalsScreen.cardKey(entry)));
      expect(await Given.waitingIds(manager), isEmpty);
    });

    phoneCase('the owner, 12 Nov 2026: السجل in the title bar lists what was approved, and its search finds it by its amount', ($) async {
      final manager = await Given.manager();
      final amount = 1000 + DateTime.now().millisecond;
      await Given.entriesApproved(manager, [await Given.entry(manager, amount: amount)]);
      await onApprovals($, manager);
      await $.tapOn(ApprovalsScreen.historyKey);
      await $.reach($(SearchIcons.searchKey));
      await $.searchFor('$amount');
      final approval = (await Given.history(manager, 'approvals/history')).single['id'] as int;
      await $.saysContaining(ApprovalHistoryScreen.lineKey(approval).title, formatMoney(amount.toDouble()));
    });
  });
}
