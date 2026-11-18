// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/attachments/attachment_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/search_scope.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/made_up_invoice.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/search_steps.dart';
import '../support/steps.dart';

/// Signs [manager] in and opens what waits.
Future<void> onApprovals(PatrolIntegrationTester $, Person manager) async {
  await $.fromTheHome(manager, HomeScreen.approvalsKey(manager.projectId));
  await $.reach($(SearchIcons.searchKey));
}

/// A purchase with a file sent for approval through the screens, whose id is answered.
Future<String> sentWithFile(PatrolIntegrationTester $, Person manager, String name, List<int> bytes) async {
  final table = await Given.firstPurchaseTable(manager);
  final account = await Given.account(manager);
  await $.onAddEntry(manager);
  await $.pickTable(table.tableId);
  await $.chooseANewSupplier(manager);
  await $.pickFromThePhone(AddEntryScreen.filesKey, name, bytes);
  await $.fill(AddEntryScreen.amountKey, '100');
  await $.choosePayment(manager, account);
  await $.sendEntry();
  await $.messageShows('expenses.sent');
  return (await Given.waitingIds(manager)).single;
}

void main() {
  phoneClass('Review what waits (UC-031)', () {
    phoneCase('AC-18.1: what waits shows what Finance needs, in the API\'s order', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final supplier = await Given.supplier(manager, name: 'شركة النخيل');
      final first = await Given.entry(manager, amount: 150, accountId: account, supplierId: supplier);
      final second = await Given.entry(manager, amount: 250, accountId: account);
      await onApprovals($, manager);
      await $.says(ApprovalsScreen.supplierKey(first), 'شركة النخيل');
      await $.says(ApprovalsScreen.amountKey(first), '150.00');
      await $.goTo($(ApprovalsScreen.cardKey(second)));
      final ordered = await Given.waitingIds(manager);
      expect($.topOf(ApprovalsScreen.cardKey(ordered.first)), lessThan($.topOf(ApprovalsScreen.cardKey(ordered.last))));
    });

    phoneCase('AC-18.1: a picture opens to zoom into', ($) async {
      final manager = await Given.manager();
      final entry = await sentWithFile($, manager, madeUpPictureName, madeUpPicture());
      await $.tapOn(HomeScreen.approvalsKey(manager.projectId));
      await $.tapOn(ApprovalsScreen.fileKey(entry));
      await $.reach($(AttachmentScreen.pictureKey));
      expect($.tester.widget<InteractiveViewer>(find.byKey(AttachmentScreen.zoomKey)).maxScale, greaterThan(1));
    });

    phoneCase('a PDF goes to the phone by its own name', ($) async {
      final manager = await Given.manager();
      final entry = await sentWithFile($, manager, madeUpPdfName, madeUpPdf);
      await $.tapOn(HomeScreen.approvalsKey(manager.projectId));
      await $.tapOn(ApprovalsScreen.fileKey(entry));
      await $.tapToThePhone(AttachmentScreen.openFileKey);
      await $.shareSheetOffers(madeUpPdfName);
    });

    phoneCase('a filter shows one kind', ($) async {
      final manager = await Given.manager();
      final purchase = await Given.entry(manager);
      final payment = await Given.contractorPayment(manager, await Given.contract(manager));
      await onApprovals($, manager);
      await $.reach($(ApprovalsScreen.cardKey(purchase)));
      await $.filterBy(ApprovalsScreen.contractorPaymentsKey);
      await $.gone($(ApprovalsScreen.cardKey(purchase)));
      await $.reach($(ApprovalsScreen.cardKey(payment)));
    });

    phoneCase('each filter counts what it keeps', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      await Given.entry(manager);
      await Given.contractorPayment(manager, await Given.contract(manager));
      await onApprovals($, manager);
      await $.openFilters();
      await $.saysContaining(ApprovalsScreen.allKey.label, '3');
      expect($.tester.widget<Text>(find.byKey(ApprovalsScreen.purchasesKey.label)).data, contains('2'));
      expect($.tester.widget<Text>(find.byKey(ApprovalsScreen.contractorPaymentsKey.label)).data, contains('1'));
    });

    phoneCase('R16: Approvals names a partner\'s entry and its kind, and a revenue entry\'s item', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      final money = await Given.partnerMoney(manager, partner);
      await Given.revenue(manager);
      await onApprovals($, manager);
      await $.says(ApprovalsScreen.itemKey(money), 'هيثم');
      await $.says(ApprovalsScreen.kindKey(money), $.words.capitalContribution);
    });

    phoneCase('a filter that keeps nothing says nothing waits', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      await onApprovals($, manager);
      await $.filterBy(ApprovalsScreen.contractorPaymentsKey);
      await $.says(ApiListBody.emptyKey, $.words.approvalsEmpty);
    });

    phoneCase('nothing waiting says so', ($) async {
      final manager = await Given.manager();
      await onApprovals($, manager);
      await $.says(ApiListBody.emptyKey, $.words.approvalsEmpty);
    });
  });
}
