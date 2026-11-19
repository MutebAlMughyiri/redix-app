// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/screen_title.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/made_up_invoice.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Whether the button [key] of the entry's page can be pressed.
bool enabled(PatrolIntegrationTester $, Key key) => $.isEnabled(key);

void main() {
  phoneClass('Open an entry and change it (UC-033)', () {
    phoneCase('AC-19.1: a rejected entry opens with what it held, and is sent again', ($) async {
      final manager = await Given.manager();
      final entry = await Given.revenue(manager, amount: 300);
      await Given.entryRejected(manager, entry);
      await $.onTheEntry(manager, entry);
      await $.tapOn(AddEntryScreen.changeKey);
      await $.reach($(AddEntryScreen.amountKey));
      expect($.typed(AddEntryScreen.amountKey), '300');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      expect(await Given.waitingIds(manager), [entry]);
    });

    phoneCase('AC-19.1: its rejection reason shows at the top', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entryRejected(manager, entry, reason: 'الصورة غير واضحة');
      await $.onTheEntry(manager, entry);
      await $.says(AddEntryScreen.rejectionKey, '${$.words.entriesReason}: الصورة غير واضحة');
    });

    phoneCase('redix-app #90: tapping an entry opens it read only, with its photo and every value', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager, amount: 150, notes: 'دفعة أولى');
      await $.onTheEntry(manager, entry);
      await $.says(AddEntryScreen.statusKey, $.words.entriesPendingApproval);
      await $.goTo($(AddEntryScreen.amountKey));
      expect($.typed(AddEntryScreen.amountKey), '150');
      await $.tester.tap(find.byKey(AddEntryScreen.amountKey), warnIfMissed: false);
      await $.pumpAndSettle();
      expect(holdsFocus(AddEntryScreen.amountKey), isFalse);
    });

    phoneCase('redix-app #90: تعديل turns it into the form, keeping the photo, and saving does not send the file twice', ($) async {
      final manager = await Given.manager();
      await Given.supplier(manager, name: 'شركة النخيل', vatNumber: madeUpSellerVatNumber);
      final table = await Given.firstPurchaseTable(manager);
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.pickTable(table.tableId);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.choosePayment(manager, account);
      await $.saveDraft();
      await $.messageShows('expenses.saved');
      final entry = (await Given.entries(manager)).single['id'] as String;
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.tapOn(AddEntryScreen.changeKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('R12: a contractor payment opens in its contract\'s table under تعديل', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      final entry = await Given.contractorPayment(manager, contract);
      await Given.entryRejected(manager, entry);
      await $.onTheEntry(manager, entry);
      await $.tapOn(AddEntryScreen.changeKey);
      await $.says(ScreenTitle.titleKey, $.words.entriesEdit);
      await $.saysContaining(AddEntryScreen.tableKey.field.label, contract.contractor);
    });

    phoneCase('saving goes to that entry, with its id, file and figures', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entryRejected(manager, entry);
      await $.onTheEntry(manager, entry);
      await $.tapOn(AddEntryScreen.changeKey);
      await $.fill(AddEntryScreen.amountKey, '175');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      final entries = await Given.entries(manager);
      expect(entries.single['id'], entry);
      expect(entries.single['amount'], 175);
    });

    phoneCase('Finance can change what waits, and what someone else entered', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.recordEntries, Permission.chargeAnyAccount]);
      final account = await Given.account(manager);
      final entry = await Given.entry(member, accountId: account);
      await $.onTheEntry(manager, entry);
      await $.reach($(AddEntryScreen.changeKey));
      expect($.isEnabled(AddEntryScreen.changeKey), isTrue);
    });

    phoneCase('redix-api #110: every kind of entry opens in Add entry to change or fix', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'C');
      final entry = await Given.partnerMoney(manager, partner, amount: 700);
      await Given.entryRejected(manager, entry);
      await $.onTheEntry(manager, entry);
      await $.tapOn(AddEntryScreen.changeKey);
      await $.reach($(AddEntryScreen.amountKey));
      expect($.typed(AddEntryScreen.amountKey), '700');
      await $.saysContaining(AddEntryScreen.tableKey.field.label, 'C');
    });

    phoneCase('redix-app #90: whoever approves finds اعتماد on a waiting entry, and it approves it', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await $.onTheEntry(manager, entry);
      await $.tapOn(AddEntryScreen.approveKey);
      await $.until(() => find.byKey(AddEntryScreen.statusKey).evaluate().isEmpty);
      expect(await Given.waitingIds(manager), isEmpty);
    });

    phoneCase('redix-app #90 D4: what waits offers the field تعديل grayed, saying why', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.recordEntries, Permission.chargeAnyAccount]);
      final account = await Given.account(manager);
      final entry = await Given.entry(member, accountId: account);
      await $.onTheEntry(member, entry);
      await $.reach($(AddEntryScreen.changeKey));
      expect($.isEnabled(AddEntryScreen.changeKey), isFalse);
      await $.reach($(AddEntryScreen.cannotChangeKey));
    });

    phoneCase('redix-app #90 D4: someone else\'s entry offers تعديل grayed', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      final member = await Given.member(manager, permissions: [Permission.recordEntries]);
      await $.onTheEntry(member, entry);
      await $.reach($(AddEntryScreen.changeKey));
      expect($.isEnabled(AddEntryScreen.changeKey), isFalse);
      await $.says(AddEntryScreen.cannotChangeKey, $.words.entriesNotYours);
    });

    phoneCase('an approved entry\'s تعديل is grayed, saying it does not change', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      await $.onTheEntry(manager, entry);
      await $.reach($(AddEntryScreen.changeKey));
      expect($.isEnabled(AddEntryScreen.changeKey), isFalse);
      await $.says(AddEntryScreen.cannotChangeKey, $.words.entriesApprovedCannotChange);
    });

    phoneCase('redix-app #90: اعتماد is gray for whoever may not approve', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      final member = await Given.member(manager, permissions: [Permission.recordEntries]);
      await $.onTheEntry(member, entry);
      await $.reach($(AddEntryScreen.approveKey));
      expect($.isEnabled(AddEntryScreen.approveKey), isFalse);
    });

    phoneCase('redix-app #90: a refused approval from here says why and keeps the entry open', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await $.onTheEntry(manager, entry);
      await Given.entriesApproved(manager, [entry]);
      await $.tapOn(AddEntryScreen.approveKey);
      await $.messageShows('approvals.entryNotPending');
      expect($(AddEntryScreen.statusKey), findsOneWidget);
      expect(enabled($, AddEntryScreen.approveKey), isTrue);
    });
  });
}
