import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/summary_card.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Drafts (UC-033 and UC-028)', () {
    phoneCase('a partner\'s draft is saved, then sent from القيود', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.tableKey);
      await $(TablePicker.searchKey).enterText('هيثم');
      await $.tapOn(TablePicker.optionKey(partner));
      await $.pumpAndSettle();
      await $.fill(AddEntryScreen.amountKey, '700');
      await $.tapOn(PaymentChoices.accountKey(account));
      await $.saveDraft();
      final id = await $.idOf('entries.row.', () => Given.entryOf(manager, 700));
      await $.tapOn(EntriesScreen.rowKey(id));
      await $.tapOn(AddEntryScreen.sendDraftKey);
      await $.says(SummaryCard.pendingKey.title, $.words.summaryPending.replaceFirst('{0}', '1'));
    });

    phoneCase('a purchase draft is saved, changed and sent', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager, sent: false);
      await $.onTheHome(manager);
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.tapOn(AddEntryScreen.changeKey);
      await $.fill(AddEntryScreen.amountKey, '150');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      expect((await Given.entries(manager)).single['amount'], 150);
      expect(await Given.waitingIds(manager), [entry]);
    });

    phoneCase('a contractor payment draft is saved and sent', ($) async {
      final manager = await Given.manager();
      final entry = await Given.contractorPayment(manager, await Given.contract(manager), sent: false);
      await $.onTheHome(manager);
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.tapOn(AddEntryScreen.sendDraftKey);
      await $.until(() => find.byKey(AddEntryScreen.sendDraftKey).evaluate().isEmpty);
      expect(await Given.waitingIds(manager), [entry]);
    });

    phoneCase('BR-42: with manageAnyEntry someone else\'s draft is not listed, so it cannot be sent', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager, sent: false);
      final member = await Given.member(manager, permissions: [Permission.manageAnyEntry, Permission.recordEntries, Permission.chargeAnyAccount]);
      final own = await Given.entry(member, accountId: await Given.account(manager));
      await $.onTheHome(member);
      await $.goTo($(EntriesScreen.rowKey(own)));
      expect($(EntriesScreen.rowKey(entry)), findsNothing);
    });

    phoneCase('a draft does not raise the waiting count', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager, sent: false);
      await $.onTheHome(manager);
      await $.reach($(SummaryCard.surplusKey));
      expect($(SummaryCard.pendingKey), findsNothing);
    });

    phoneCase('UC-028: without manageAnyEntry someone else\'s draft is not listed, so it cannot be sent', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager, sent: false);
      final member = await Given.member(manager, permissions: [Permission.recordEntries, Permission.chargeAnyAccount]);
      final own = await Given.entry(member, accountId: await Given.account(manager));
      await $.onTheHome(member);
      await $.goTo($(EntriesScreen.rowKey(own)));
      expect($(EntriesScreen.rowKey(entry)), findsNothing);
    });
  });
}
