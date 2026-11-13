import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/expenses/payment_choices.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Add a partner\'s money (UC-040)', () {
    phoneCase('redix-api #110: a partner\'s contribution is sent for approval from Add entry', ($) async {
      final manager = await Given.manager(project: 'غصون 7');
      final partner = await Given.partner(manager, 'هيثم');
      final account = await Given.account(manager, name: 'حساب المؤسسة');
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.tableKey);
      await $(TablePicker.searchKey).enterText('هيثم');
      await $.tapOn(TablePicker.optionKey(partner));
      await $.pumpAndSettle();
      await $.fill(AddEntryScreen.amountKey, '5000');
      await $.tapOn(PaymentChoices.accountKey(account));
      await $.goTo($(AddEntryScreen.sendKey));
      await $.picture('add-entry-partner');
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('redix-api #110, #129: with «سحب مبلغ» chosen in «نوع الحركة», it is a withdrawal', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.pickTable(partner, search: 'هيثم');
      await $.fill(AddEntryScreen.amountKey, '700');
      await $.tapOn(AddEntryScreen.columnKey('movementType'));
      await $.tapOn(AddEntryScreen.columnOptionKey('movementType', Given.withdrawalChoiceId));
      await $.tapOn(PaymentChoices.accountKey(account));
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      expect((await Given.entries(manager)).single['kind'], 'capitalOut');
    });

    phoneCase('R5: رأس المال is found by its name, in either spelling', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.tableKey);
      await $(TablePicker.searchKey).enterText('راس المال');
      await $.reach($(TablePicker.optionKey(partner)));
    });

    phoneCase('a receipt is optional, and the amount is one figure', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.pickTable(partner, search: 'هيثم');
      await $.fill(AddEntryScreen.amountKey, '700');
      await $.tapOn(PaymentChoices.accountKey(account));
      await $.sendEntry();
      await $.messageShows('expenses.sent');
    });

    phoneCase('R9: without moveMoney no partner table is offered', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      final member = await Given.member(manager, permissions: [Permission.recordEntries]);
      await $.onAddEntry(member);
      await $.tapOn(AddEntryScreen.tableKey);
      await $.reach($(TablePicker.searchKey));
      expect($(TablePicker.optionKey(partner)), findsNothing);
    });
  });
}
