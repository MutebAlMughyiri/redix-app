// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';

import 'given.dart';
import 'steps.dart';

/// The steps of filling in Add entry, shared by every class that enters money.
extension EntrySteps on PatrolIntegrationTester {
  /// Signs [person] in and opens Add entry from the home of their project.
  Future<void> onAddEntry(Person person) async {
    await fromTheHome(person, HomeScreen.addEntryKey(person.projectId));
    await reach(this(AddEntryScreen.tableKey));
  }

  /// Signs [person] in and opens the entry [entry] from the home of their project.
  Future<void> onTheEntry(Person person, String entry) async {
    await onTheHome(person);
    await tapOn(EntriesScreen.rowKey(entry));
    await reach(this(AddEntryScreen.statusKey));
  }

  /// Picks the table [tableId] in Add entry, typing [search] into the sheet first when it may be further down the list.
  Future<void> pickTable(String tableId, {String search = ''}) async {
    await tapOn(AddEntryScreen.tableKey);
    await reach(this(TablePicker.searchKey));
    if (search.isNotEmpty) {
      await this(TablePicker.searchKey).enterText(search);
    }
    await this(TablePicker.optionKey(tableId)).waitUntilExists();
    await tapOn(TablePicker.optionKey(tableId));
    await pumpAndSettle();
  }

  /// Picks the supplier [supplierId] in Add entry.
  Future<void> chooseSupplier(String supplierId) async {
    await tapOn(AddEntryScreen.supplierKey);
    await tapOn(SupplierPicker.rowKey(supplierId));
    await pumpAndSettle();
  }

  /// Registers a new supplier as [person] and picks it in Add entry, as a purchase asks.
  Future<void> chooseANewSupplier(Person person) async => chooseSupplier(await Given.supplier(person));

  /// Chooses how an expense was paid: the first method the project offers, unless [methodId] is given, then the account [accountId] among those the method
  /// pays from. The one account a method pays from is named on its own line, chosen already (redix-app #109, D2).
  Future<void> choosePayment(Person person, String accountId, {String methodId = ''}) async {
    final method = methodId.isEmpty ? (await Given.paymentMethods(person)).first['id'] as String : methodId;
    await tapOn(PaymentChoices.paymentMethodKey(method));
    if (this(PaymentChoices.accountKey(accountId)).exists) {
      await tapOn(PaymentChoices.accountKey(accountId));
    } else {
      await reach(this(PaymentChoices.paidFromKey));
    }
    await pumpAndSettle();
  }

  /// Sends the entry for approval.
  Future<void> sendEntry() async {
    await tapOn(AddEntryScreen.sendKey);
  }

  /// Keeps the entry as a draft.
  Future<void> saveDraft() async {
    await tapOn(AddEntryScreen.draftKey);
  }
}
