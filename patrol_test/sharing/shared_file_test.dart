// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/sharing/share_screen.dart';
import 'package:redix/ui/search_line.dart';

import '../support/given.dart';
import '../support/made_up_invoice.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/search_steps.dart';
import '../support/steps.dart';

/// Shares the picture of a made-up invoice with its QR code into the app, as another app's share sheet does.
Future<void> shareTheInvoice(PatrolIntegrationTester $) async {
  await Pc.shareIntoTheApp(await keptInTheAppsFolder('made-up-shared-invoice.png', pictureOfQr(madeUpInvoiceQr)), 'image/png');
  await $.pumpAndSettle();
}

/// Starts the app afresh, signed in as [person] unless it is nobody, and shares a file into it.
Future<void> shareInto(PatrolIntegrationTester $, Person person) async {
  await $.startApp();
  await $.restartApp();
  if (!person.isNone) {
    await $.signIn(person.username, person.password);
    await $.reach($(ProjectsScreen.titleKey));
  }
  await shareTheInvoice($);
}

void main() {
  phoneClass('A shared file (UC-038, UC-039 and UC-046)', () {
    phoneCase('AC-49.1, AC-46.10b, AC-46.10c: a shared file opens the share screen, القيود\'s list and its search in its middle', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await shareInto($, manager);
      await $.reach($(ShareScreen.pictureKey));
      await $.reach($(SearchLine.searchKey));
      await $.goTo($(EntriesScreen.rowKey(entry)));
    });

    phoneCase('AC-49.1: not signed in, sign-in comes first and continues with the file', ($) async {
      final manager = await Given.manager();
      await shareInto($, Person.none);
      await $.reach($(SignInScreen.usernameKey));
      await $.signIn(manager.username, manager.password);
      await $.reach($(ShareScreen.pictureKey));
    });

    phoneCase('with more than one project, the person chooses', ($) async {
      final manager = await Given.manager();
      final other = await Given.manager();
      await Given.joined(manager, by: other, permissions: [Permission.recordEntries, Permission.attachFiles]);
      await shareInto($, manager);
      await $.reach($(ShareScreen.projectKey(manager.projectId)));
      await $.reach($(ShareScreen.projectKey(other.projectId)));
    });

    phoneCase('AC-49.2, D4: the entry the QR code matches is pinned over the list and chosen', ($) async {
      final manager = await Given.manager();
      final seller = await Given.supplier(manager, name: 'شركة النخيل', vatNumber: madeUpSellerVatNumber);
      final match = await Given.entry(manager, amount: 1075, supplierId: seller);
      await shareInto($, manager);
      await $.reach($(ShareScreen.matchingKey(match)));
      await $.reach($(ShareScreen.attachKey));
      expect($.tester.widget<ListTile>(find.byKey(EntriesScreen.rowKey(match))).selected, isTrue);
      expect($(ShareScreen.amountDiffersKey), findsNothing);
    });

    phoneCase('AC-49.3, R3: an entry found by the search and chosen shows what differs from the QR code', ($) async {
      final manager = await Given.manager();
      final supplier = await Given.supplier(manager, name: 'مؤسسة البلاط ${Given.unique()}');
      final entry = await Given.entry(manager, amount: 500, supplierId: supplier);
      await shareInto($, manager);
      await $.searchFor('البلاط');
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.reach($(ShareScreen.amountDiffersKey));
    });

    phoneCase('AC-46.10a, D15: a file goes on an approved entry, which stays approved', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      await shareInto($, manager);
      await $.goTo($(EntriesScreen.rowKey(entry)));
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.tapOn(ShareScreen.attachKey);
      await $.gone($(ShareScreen.pictureKey));
      expect((await Given.entries(manager)).single['status'], 'approved');
    });

    phoneCase('AC-46.10f: someone without «إدارة قيود الآخرين» finds only their own entries', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.recordEntries, Permission.attachFiles, Permission.chargeAnyAccount]);
      final theirs = await Given.entry(manager);
      final own = await Given.entry(member, accountId: await Given.account(manager));
      await shareInto($, member);
      await $.goTo($(EntriesScreen.rowKey(own)));
      expect($(EntriesScreen.rowKey(theirs)), findsNothing);
    });

    phoneCase('UC-046: a new expense opens with the shared file and its QR code', ($) async {
      final manager = await Given.manager();
      await shareInto($, manager);
      await $.tapOn(ShareScreen.newEntryKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.reach($(AddEntryScreen.qrReadKey));
    });

    phoneCase('R12: a shared file offers New entry and no capital receipt, and goes with a partner picked in Add entry', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'C');
      await shareInto($, manager);
      await $.tapOn(ShareScreen.newEntryKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.tapOn(AddEntryScreen.tableKey);
      await $(TablePicker.searchKey).enterText('C');
      await $.reach($(TablePicker.optionKey(partner)));
    });

    phoneCase('without a project to enter in, the screen says so', ($) async {
      final member = await Given.member(await Given.manager());
      await shareInto($, member);
      await $.reach($(ShareScreen.noProjectKey));
    });

    phoneCase('BR-22: a file already on another entry is refused, and the person stays', ($) async {
      final manager = await Given.manager();
      final first = await Given.entry(manager, amount: 111);
      final second = await Given.entry(manager, amount: 222);
      await shareInto($, manager);
      await $.goTo($(EntriesScreen.rowKey(first)));
      await $.tapOn(EntriesScreen.rowKey(first));
      await $.tapOn(ShareScreen.attachKey);
      await $.gone($(ShareScreen.pictureKey));
      await shareTheInvoice($);
      await $.goTo($(EntriesScreen.rowKey(second)));
      await $.tapOn(EntriesScreen.rowKey(second));
      await $.tapOn(ShareScreen.attachKey);
      await $.says(ShareScreen.messageKey, $.words.shareInvoiceAlreadyAttached);
      expect($(ShareScreen.pictureKey), findsOneWidget);
    });

    phoneCase('leaving lets go of the file', ($) async {
      final manager = await Given.manager();
      await shareInto($, manager);
      await $.reach($(ShareScreen.pictureKey));
      await $.tapOn(ShareScreen.closeKey);
      await $.reach($(ProjectsScreen.titleKey));
      expect($(ShareScreen.pictureKey), findsNothing);
    });
  });
}
