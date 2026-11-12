import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/movements_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('A partner\'s movements (UC-040)', () {
    phoneCase('a partner opens to their movements, each with its receipt', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'متعب');
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.pickTable(partner, search: 'متعب');
      await $.fill(AddEntryScreen.amountKey, '500');
      await $.tapOn(PaymentChoices.accountKey(account));
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      final entry = (await Given.waitingIds(manager)).single;
      await Given.entriesApproved(manager, [entry]);
      await $.tapOn(HomeScreen.partnersKey(manager.projectId));
      await $.tapOn(PartnersScreen.rowKey(partner));
      await $.reach($(MovementsScreen.rowKey(entry)));
      await $.reach($(MovementsScreen.receiptKey(entry)));
    });

    phoneCase('redix-api #119: whoever holds the removal swipes a movement away, and it leaves the list', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'متعب');
      final entry = await Given.partnerMoney(manager, partner);
      await Given.entriesApproved(manager, [entry]);
      await Given.ticked(manager, [Permission.removeApprovedEntries], by: manager);
      await $.fromTheHome(manager, HomeScreen.partnersKey(manager.projectId));
      await $.tapOn(PartnersScreen.rowKey(partner));
      await $.swipeAway(MovementsScreen.rowKey(entry));
      await $.gone($(MovementsScreen.rowKey(entry)));
    });

    phoneCase('redix-api #119: without the removal a movement shows no red bar, even to whoever approves', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'متعب');
      final entry = await Given.partnerMoney(manager, partner);
      await Given.entriesApproved(manager, [entry]);
      await $.fromTheHome(manager, HomeScreen.partnersKey(manager.projectId));
      await $.tapOn(PartnersScreen.rowKey(partner));
      await $.reach($(MovementsScreen.rowKey(entry)));
      expect($(MovementsScreen.rowKey(entry).bar), findsNothing);
    });
  });
}
