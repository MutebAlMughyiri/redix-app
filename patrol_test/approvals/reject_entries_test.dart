// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/reason_sheet.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new manager with one entry waiting, standing on its reason sheet, answered.
Future<({Person manager, String entry})> onReasonSheet(PatrolIntegrationTester $) async {
  final manager = await Given.manager();
  final entry = await Given.entry(manager);
  await $.fromTheHome(manager, HomeScreen.approvalsKey(manager.projectId));
  await $.tapOn(ApprovalsScreen.rejectKey(entry));
  await $.reach($(ReasonSheet.reasonKey));
  return (manager: manager, entry: entry);
}

void main() {
  phoneClass('Reject entries (UC-032)', () {
    phoneCase('rejecting with a reason sends it, and the entry leaves', ($) async {
      final made = await onReasonSheet($);
      await $.fill(ReasonSheet.reasonKey, 'الصورة غير واضحة');
      await $.tapOn(ReasonSheet.sendKey);
      await $.gone($(ApprovalsScreen.cardKey(made.entry)));
      expect(await Given.waitingIds(made.manager), isEmpty);
    });

    phoneCase('a quick reason fills the field, and rejecting closes', ($) async {
      final made = await onReasonSheet($);
      await $.tapOn(ReasonSheet.quickReasonKey(0));
      await $.pumpAndSettle();
      expect($.typed(ReasonSheet.reasonKey), isNotEmpty);
      await $.tapOn(ReasonSheet.sendKey);
      await $.gone($(ReasonSheet.reasonKey));
      await $.gone($(ApprovalsScreen.cardKey(made.entry)));
    });

    phoneCase('AC-19.1: rejecting needs a reason', ($) async {
      final made = await onReasonSheet($);
      await $.tapOn(ReasonSheet.sendKey);
      await $.says(ReasonSheet.messageKey, $.words.approvalsReasonRequired);
      expect($(ApprovalsScreen.cardKey(made.entry)), findsOneWidget);
    });
  });
}
