// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/contracts/contract.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/format/number_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/structure/item_picker.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/made_up_invoice.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/search_steps.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Contracts.
Future<void> onContracts(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.contractsKey(person.projectId));
  await $.reach($(ContractsScreen.addKey));
}

/// The standing of the contract [id] says [text].
Future<void> standsAs(PatrolIntegrationTester $, String id, String text) => $.says(ContractsScreen.standingKey(id).label, text);

/// A payment of [amount] on [contract], approved.
Future<void> paid(Person manager, MadeContract contract, num amount) async {
  await Given.entriesApproved(manager, [await Given.contractorPayment(manager, contract, amount: amount)]);
}

/// Picks the first item a contract can take in the dialog showing now.
Future<void> pickItem(PatrolIntegrationTester $, Person person, String name) async {
  await $.tapOn(ContractsScreen.itemKey);
  final id = await $.idOf('itemPicker.option.', () => Given.itemNamed(person, name));
  await $.goTo($(ItemPicker.optionKey(id)));
  await $(ItemPicker.optionKey(id)).tap();
  await $.pumpAndSettle();
}

void main() {
  phoneClass('Contracts (UC-020)', () {
    phoneCase('a fixed-value contract is added with its contractor, item and value', ($) async {
      final manager = await Given.manager(project: 'مشروع B');
      final supplier = await Given.supplier(manager, name: 'مبلط الغربية', vatNumber: Given.vatNumber());
      await onContracts($, manager);
      await $.tapOn(ContractsScreen.addKey);
      await $(ContractsScreen.contractorKey).tap();
      await $.tapOn(SupplierPicker.rowKey(supplier));
      await pickItem($, manager, 'البناء');
      await $.fill(ContractsScreen.valueKey, '34000');
      await $.picture('contract-dialog');
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idOf('contracts.name.', () => Given.contractWith(manager, 'مبلط الغربية'));
      await $.says(ContractsScreen.valueOfKey(id), '34,000.00');
      await $.picture('contracts');
    });

    phoneCase('a contractor missing from the list is added from the picker', ($) async {
      final manager = await Given.manager();
      await onContracts($, manager);
      await $.tapOn(ContractsScreen.addKey);
      await $(ContractsScreen.contractorKey).tap();
      await $(SupplierPicker.searchKey).enterText('مبلط الغربية');
      await $.tapOn(SupplierPicker.quickAddKey);
      await $(SuppliersScreen.vatNumberKey).enterText(Given.vatNumber());
      await $(find.byKey(ChangeDialog.saveKey).hitTestable()).tap();
      await $.says(ContractsScreen.contractorKey.label, 'مبلط الغربية');
    });

    phoneCase('amending starts from the contract, and saving keeps it', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 34000);
      await onContracts($, manager);
      await $.menuChoice(ContractsScreen.menuKey(contract.id), ContractsScreen.editKey);
      await $.reach($(ContractsScreen.valueKey));
      expect($.typed(ContractsScreen.valueKey), contains('34000'));
      await $(ChangeDialog.saveKey).tap();
      await $.gone($(ContractsScreen.valueKey));
      await $.says(ContractsScreen.valueOfKey(contract.id), '34,000.00');
    });

    phoneCase('FR-07: each contract shows its contractor, item and figures', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await paid(manager, contract, 400);
      await onContracts($, manager);
      await $.says(ContractsScreen.nameKey(contract.id), contract.contractor);
      await $.says(ContractsScreen.valueOfKey(contract.id), '1,000.00');
      await $.says(ContractsScreen.paidKey(contract.id), '400.00');
    });

    phoneCase('AC-07.1: it shows what remains, and how it stands', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await paid(manager, contract, 400);
      await onContracts($, manager);
      await $.says(ContractsScreen.remainingKey(contract.id), '600.00');
      await standsAs($, contract.id, $.words.contractsRunning);
    });

    phoneCase('AC-07.1: an overrun shows in brackets, with an alert', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await paid(manager, contract, 1500);
      await onContracts($, manager);
      await $.says(ContractsScreen.remainingKey(contract.id), '(500.00)');
      await standsAs($, contract.id, $.words.contractsOverrun);
    });

    phoneCase('AC-07.2: an open-value contract asks no value, and has no remaining and no alert', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, openValue: true);
      await paid(manager, contract, 1200);
      await onContracts($, manager);
      await $.says(ContractsScreen.remainingKey(contract.id), '—');
      await standsAs($, contract.id, $.words.contractsOpenValue);
      await $.tapOn(ContractsScreen.addKey);
      await $.tapOn(ContractsScreen.openValueKey);
      await $.pumpAndSettle();
      expect($(ContractsScreen.valueKey), findsNothing);
    });

    phoneCase('a contract with nothing paid says not started', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      await onContracts($, manager);
      await $.reach($(ContractsScreen.nameKey(contract.id)));
      await standsAs($, contract.id, $.words.contractsNotStarted);
    });

    phoneCase('the filters count their contracts and keep only those', ($) async {
      final manager = await Given.manager();
      final running = await Given.contract(manager, value: 1000);
      final overrun = await Given.contract(manager, value: 100);
      await paid(manager, overrun, 200);
      await onContracts($, manager);
      await $.reach($(ContractsScreen.nameKey(running.id)));
      await $.openFilters();
      await $.says(ContractsScreen.filterKey(ContractFilter.overrun).label, '${$.words.contractsFilterOverrun} · 1');
      await $.tapOn(ContractsScreen.filterKey(ContractFilter.overrun));
      await $.gone($(ContractsScreen.nameKey(running.id)));
      await $.reach($(ContractsScreen.nameKey(overrun.id)));
    });

    phoneCase('a contract with no payments can change its contractor, item and unit', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      final supplier = await Given.supplier(manager, name: 'مقاول جديد');
      await onContracts($, manager);
      await $.menuChoice(ContractsScreen.menuKey(contract.id), ContractsScreen.editKey);
      await $.tapOn(ContractsScreen.contractorKey);
      await $.tapOn(SupplierPicker.rowKey(supplier));
      await $.pumpAndSettle();
      await $(ChangeDialog.saveKey).tap();
      await $.says(ContractsScreen.nameKey(contract.id), 'مقاول جديد');
    });

    phoneCase('saving with the keyboard up closes it with the dialog', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await onContracts($, manager);
      await $.menuChoice(ContractsScreen.menuKey(contract.id), ContractsScreen.editKey);
      await $.fill(ContractsScreen.valueKey, '2000');
      await $(ChangeDialog.saveKey).tap();
      await $.gone($(ContractsScreen.valueKey));
      await $.until(() => $.tester.view.viewInsets.bottom == 0);
      expect($.tester.view.viewInsets.bottom, 0);
      await $.says(ContractsScreen.valueOfKey(contract.id), '2,000.00');
    });

    phoneCase('disabled, it stays on the list, marked, and can be enabled', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      await onContracts($, manager);
      await $.menuChoice(ContractsScreen.menuKey(contract.id), ContractsScreen.disableKey);
      await standsAs($, contract.id, $.words.contractsDisabled);
      await $.menuChoice(ContractsScreen.menuKey(contract.id), ContractsScreen.enableKey);
      await standsAs($, contract.id, $.words.contractsNotStarted);
    });

    phoneCase('UC-021: a contract\'s document is kept and named on save', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      await onContracts($, manager);
      await $.menuChoice(ContractsScreen.menuKey(contract.id), ContractsScreen.editKey);
      await $.pickFromThePhone(ContractsScreen.addDocumentKey, madeUpDocumentName, madeUpDocument);
      await $(find.text(madeUpDocumentName)).waitUntilExists();
      await $(ChangeDialog.saveKey).tap();
      await $.gone($(ContractsScreen.valueKey));
      await $.menuChoice(ContractsScreen.menuKey(contract.id), ContractsScreen.editKey);
      await $.reach($(ContractsScreen.documentsHeadingKey));
      await $.says(ContractsScreen.documentKey((await Given.contractDocumentIds(manager, contract.id)).single), madeUpDocumentName);
    });

    phoneCase('AC-31.1, the owner, 12 Nov 2026: a contract\'s ⋮ saves its own workbook in the phone\'s Download folder', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      await onContracts($, manager);
      for (final kind in ReportFileKind.values) {
        expect($(ReportFileButtons.buttonKey('contracts', kind)), findsNothing);
      }
      await $.goTo($(ContractsScreen.nameKey(contract.id)));
      await $.menuChoice(ContractsScreen.menuKey(contract.id), ContractsScreen.fileKey(ReportFileKind.excel));
      await $.tapOn(ReportFileButtons.handingKey(contract.contractor, ReportFileKind.excel, FileHandling.save));
      await $.messageShows('reports.downloaded');
      await Pc.expectDownloaded(contract.contractor);
    });

    phoneCase('the owner, 12 Nov 2026: tapping a contract opens its own table, with its payments and what remains', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager, value: 1000);
      await Given.entriesApproved(manager, [await Given.contractorPayment(manager, contract, amount: 400)]);
      await onContracts($, manager);
      await $.goTo($(ContractsScreen.nameKey(contract.id)));
      await $.tapOn(ContractsScreen.nameKey(contract.id).body);
      await $.reach($(ItemReportScreen.contractCardKey(contract.id)));
      await $.says(ItemReportScreen.contractorKey(contract.id), contract.contractor);
      await $.says(ItemReportScreen.contractTotalKey(contract.id), '${$.words.reportsGrandTotal}: ${formatMoney(400)}');
    });

    phoneCase('a contract with payments keeps its contractor and item', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      await Given.contractorPayment(manager, contract);
      await onContracts($, manager);
      await $.menuChoice(ContractsScreen.menuKey(contract.id), ContractsScreen.editKey);
      await $.reach($(ContractsScreen.valueKey));
      expect($(ContractsScreen.contractorKey), findsNothing);
      expect($(ContractsScreen.itemKey), findsNothing);
    });

    phoneCase('a filter that keeps no contract says there are none', ($) async {
      final manager = await Given.manager();
      await Given.contract(manager);
      await onContracts($, manager);
      await $.filterBy(ContractsScreen.filterKey(ContractFilter.overrun));
      await $.says(ApiListBody.emptyKey, $.words.contractsEmpty);
    });

    phoneCase('with no contractor or item chosen the API refuses, and the dialog stays', ($) async {
      final manager = await Given.manager();
      await onContracts($, manager);
      await $.tapOn(ContractsScreen.addKey);
      await $.fill(ContractsScreen.valueKey, '1000');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.contractsUnknownSupplier);
    });

    phoneCase('figures that are not numbers are refused before sending', ($) async {
      final manager = await Given.manager();
      await onContracts($, manager);
      await $.tapOn(ContractsScreen.addKey);
      await $.fill(ContractsScreen.valueKey, 'abc');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.contractsInvalidValue);
    });

    phoneCase('a refusal stays in the dialog', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      await Given.contractorPayment(manager, contract);
      final supplier = await Given.supplier(manager, name: 'مقاول جديد');
      await onContracts($, manager);
      await Given.supplierDisabled(manager, supplier);
      await $.tapOn(ContractsScreen.addKey);
      await $.fill(ContractsScreen.valueKey, '1000');
      await $(ChangeDialog.saveKey).tap();
      await $.reach($(ChangeDialog.messageKey));
      expect($(ContractsScreen.valueKey), findsOneWidget);
    });

    phoneCase('UC-021: a document over 25 MB is refused, and the dialog says why', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      await onContracts($, manager);
      await $.menuChoice(ContractsScreen.menuKey(contract.id), ContractsScreen.editKey);
      await $.pickFromThePhone(ContractsScreen.addDocumentKey, 'made-up-large.pdf', Uint8List(26 * 1024 * 1024));
      await $.says(ContractsScreen.documentMessageKey, $.words.attachmentsFileTooLarge);
    });

    phoneCase('a project with no contracts says so', ($) async {
      final manager = await Given.manager();
      await onContracts($, manager);
      await $.says(ApiListBody.emptyKey, $.words.contractsEmpty);
    });

    phoneCase('without keeping the settings there is nothing to change: a contract\'s ⋮ holds its files alone', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      final member = await Given.member(manager);
      await onContracts($, member);
      await $.reach($(ContractsScreen.nameKey(contract.id)));
      expect($.isEnabled(ContractsScreen.addKey), isFalse);
      await $.tapOn(ContractsScreen.menuKey(contract.id));
      await $.reach($(ContractsScreen.fileKey(ReportFileKind.pdf)));
      expect($(ContractsScreen.editKey), findsNothing);
    });

    phoneCase('redix-api #131: without «يُصدر التقارير» a contract\'s PDF and Excel show gray in its ⋮, saying why', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      final member = await Given.member(manager, permissions: [Permission.recordEntries, Permission.seeAllCapital]);
      await onContracts($, member);
      await $.tapOn(ContractsScreen.menuKey(contract.id));
      await $.reach($(ContractsScreen.fileKey(ReportFileKind.pdf)));
      expect($.isEnabled(ContractsScreen.fileKey(ReportFileKind.pdf)), isFalse);
      expect($.isEnabled(ContractsScreen.fileKey(ReportFileKind.excel)), isFalse);
      await $.says(ContractsScreen.fileKey(ReportFileKind.pdf).subtitle, $.words.reportsNeedsGenerateReports);
    });

    phoneCase('redix-api #131: without «يرى التقارير» a contract opens no table', ($) async {
      final manager = await Given.manager();
      final contract = await Given.contract(manager);
      final member = await Given.member(manager);
      await onContracts($, member);
      await $.reach($(ContractsScreen.nameKey(contract.id)));
      expect($.isEnabled(ContractsScreen.nameKey(contract.id).body), isFalse);
    });

    phoneCase('a list that cannot be read says so', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await Pc.cutNetwork();
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.contractsKey(manager.projectId));
      await $.says(ApiListBody.messageKey, $.words.contractsLoadFailed);
    });
  });
}
