import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/sharing/share_screen.dart';

import '../support/given.dart';
import '../support/made_up_invoice.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
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

/// Picks the table [tableId] on the share screen.
Future<void> chooseTable(PatrolIntegrationTester $, String tableId) async {
  await $.tapOn(ShareScreen.tableKey);
  await $.tapOn(TablePicker.optionKey(tableId));
  await $.pumpAndSettle();
}

void main() {
  phoneClass('A shared file (UC-038 and UC-046)', () {
    phoneCase('AC-49.1: a shared file opens the attach screen', ($) async {
      final manager = await Given.manager();
      await shareInto($, manager);
      await $.reach($(ShareScreen.tableKey));
    });

    phoneCase('AC-49.1: not signed in, sign-in comes first and continues with the file', ($) async {
      final manager = await Given.manager();
      await shareInto($, Person.none);
      await $.reach($(SignInScreen.usernameKey));
      await $.signIn(manager.username, manager.password);
      await $.reach($(ShareScreen.tableKey));
    });

    phoneCase('with more than one project, the person chooses', ($) async {
      final manager = await Given.manager();
      final other = await Given.manager();
      await Given.joined(manager, by: other, permissions: [Permission.recordEntries, Permission.attachFiles]);
      await shareInto($, manager);
      await $.reach($(ShareScreen.projectKey(manager.projectId)));
      await $.reach($(ShareScreen.projectKey(other.projectId)));
    });

    phoneCase('AC-49.2: the expense matching the QR code is marked and chosen', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final seller = await Given.supplier(manager, name: 'شركة النخيل', vatNumber: madeUpSellerVatNumber);
      final match = await Given.entry(manager, amount: 1075, supplierId: seller);
      await shareInto($, manager);
      await chooseTable($, table.tableId);
      await $.reach($(ShareScreen.matchingKey(match)));
      await $.reach($(ShareScreen.attachKey));
      expect($(ShareScreen.amountDiffersKey), findsNothing);
    });

    phoneCase('AC-49.3: choosing shows what differs from the QR code', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final entry = await Given.entry(manager, amount: 500);
      await shareInto($, manager);
      await chooseTable($, table.tableId);
      await $.tapOn(ShareScreen.entryKey(entry));
      await $.reach($(ShareScreen.amountDiffersKey));
    });

    phoneCase('D15: attaching puts only the file on the expense, whose status stays', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      await shareInto($, manager);
      await chooseTable($, table.tableId);
      await $.tapOn(ShareScreen.entryKey(entry));
      await $.tapOn(ShareScreen.attachKey);
      await $.gone($(ShareScreen.tableKey));
      expect((await Given.entries(manager)).single['status'], 'approved');
    });

    phoneCase('UC-046: a new expense opens with the shared file and its QR code', ($) async {
      final manager = await Given.manager();
      await shareInto($, manager);
      await $.tapOn(ShareScreen.newExpenseKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.reach($(AddEntryScreen.qrReadKey));
    });

    phoneCase('R12: a shared file offers New entry and no capital receipt, and goes with a partner picked in Add entry', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      await shareInto($, manager);
      await $.tapOn(ShareScreen.newExpenseKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.tapOn(AddEntryScreen.tableKey);
      await $(TablePicker.searchKey).enterText('هيثم');
      await $.reach($(TablePicker.optionKey(partner)));
    });

    phoneCase('without a project to enter in, the screen says so', ($) async {
      final member = await Given.member(await Given.manager());
      await shareInto($, member);
      await $.reach($(ShareScreen.noProjectKey));
    });

    phoneCase('BR-22: a file already on another expense is refused, and the person stays', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final first = await Given.entry(manager, amount: 111);
      final second = await Given.entry(manager, amount: 222);
      await shareInto($, manager);
      await chooseTable($, table.tableId);
      await $.tapOn(ShareScreen.entryKey(first));
      await $.tapOn(ShareScreen.attachKey);
      await $.gone($(ShareScreen.tableKey));
      await shareTheInvoice($);
      await chooseTable($, table.tableId);
      await $.tapOn(ShareScreen.entryKey(second));
      await $.tapOn(ShareScreen.attachKey);
      await $.says(ShareScreen.messageKey, $.words.shareInvoiceAlreadyAttached);
      expect($(ShareScreen.tableKey), findsOneWidget);
    });

    phoneCase('leaving lets go of the file', ($) async {
      final manager = await Given.manager();
      await shareInto($, manager);
      await $.reach($(ShareScreen.tableKey));
      await $.tapOn(ShareScreen.closeKey);
      await $.reach($(ProjectsScreen.titleKey));
      expect($(ShareScreen.tableKey), findsNothing);
    });
  });
}
