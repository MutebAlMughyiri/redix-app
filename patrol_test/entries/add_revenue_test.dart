// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/expenses/payment_choices.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Picks the VAT refund table in Add entry by searching for it, and answers its id.
Future<String> pickRefund(PatrolIntegrationTester $, Person person) async {
  await $.tapOn(AddEntryScreen.tableKey);
  await $(TablePicker.searchKey).enterText('استرجاع');
  final id = await $.idOf('tablePicker.option.', () => Given.entryTableNamed(person, 'استرجاع الضرائب'));
  await $.tapOn(TablePicker.optionKey(id));
  await $.pumpAndSettle();
  return id;
}

void main() {
  phoneClass('Add revenue (UC-047 and UC-040)', () {
    phoneCase('R3: a revenue entry is sent for approval on its item and table', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await pickRefund($, manager);
      await $.fill(AddEntryScreen.amountKey, '300');
      await $.tapOn(PaymentChoices.accountKey(account));
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      expect(await Given.waitingIds(manager), hasLength(1));
    });

    phoneCase('R5: Finance finds the revenue items, in either spelling', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.tableKey);
      await $(TablePicker.searchKey).enterText('استرجاع الضرائب');
      await $.idOf('tablePicker.option.', () => Given.entryTableNamed(manager, 'استرجاع الضرائب'));
      await $(TablePicker.searchKey).enterText('أسترجاع الضرائب');
      await $.idOf('tablePicker.option.', () => Given.entryTableNamed(manager, 'استرجاع الضرائب'));
    });

    phoneCase('redix-api #110: a revenue entry is saved as a draft and sent later', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await pickRefund($, manager);
      await $.fill(AddEntryScreen.amountKey, '300');
      await $.tapOn(PaymentChoices.accountKey(account));
      await $.saveDraft();
      await $.messageShows('expenses.saved');
      expect(await Given.waitingIds(manager), isEmpty);
      expect(await Given.entries(manager), hasLength(1));
    });

    phoneCase('R10: an amount that is no number stops it', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await pickRefund($, manager);
      await $.fill(AddEntryScreen.amountKey, 'abc');
      await $.sendEntry();
      await $.says(AddEntryScreen.messageKey, $.words.expensesInvalidAmount);
    });

    phoneCase('R9: without moveMoney no revenue item is offered', ($) async {
      final member = await Given.member(await Given.manager(), permissions: [Permission.recordEntries]);
      await $.onAddEntry(member);
      await $.tapOn(AddEntryScreen.tableKey);
      await $(TablePicker.searchKey).enterText('استرجاع');
      await $.reach($(TablePicker.noMatchKey));
    });
  });
}
