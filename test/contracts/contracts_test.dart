import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/contracts/contract.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/structure/item_picker.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/picker_field.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  late FakeApi apiOfDocuments;

  /// A project with a contract running, one overrun and one of open value, opened as far as its contracts.
  Future<({FakeApi api, String running, String overrun, String open, String contractor, String item})> openContracts(WidgetTester tester, {bool hasPayments = false, String status = 'active', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, permissions: permissions, units: ['الفلة الغربية']);
    final contractor = api.addSupplier('project-0', 'شركة النخيل', vatNumber: '300000000000003');
    final item = api.addItem(api.addCategory('project-0', 'التشطيب'), 'البلاط');
    final running = api.addContract('project-0', 'مبلط الغربية', value: 34000, paid: 30000, hasPayments: hasPayments);
    final overrun = api.addContract('project-0', 'مبلط الجنوبية', value: 34000, paid: 35000);
    final open = api.addContract('project-0', 'دهان داخلي', isOpenValue: true, paid: 12000);
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.contractsKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractsKey('project-0'))));
    return (api: api, running: running['id'] as String, overrun: overrun['id'] as String, open: open['id'] as String, contractor: contractor['id'] as String, item: item['id'] as String);
  }

  Future<void> tapVisible(WidgetTester tester, FakeApi api, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(key)));
  }

  Future<void> save(WidgetTester tester, FakeApi api) => tapVisible(tester, api, ChangeDialog.saveKey);

  Future<void> pickContractor(WidgetTester tester, FakeApi api, String id) async {
    await tapVisible(tester, api, ContractsScreen.contractorKey);
    await act(tester, api, () => tester.tap(find.byKey(SupplierPicker.rowKey(id))));
  }

  Future<void> pickItem(WidgetTester tester, FakeApi api, String id) async {
    await tapVisible(tester, api, ContractsScreen.itemKey);
    await act(tester, api, () => tester.tap(find.byKey(ItemPicker.optionKey(id))));
  }

  Future<FakeCapture> openAmendWithFiles(WidgetTester tester, PickedFile picked) async {
    final capture = FakeCapture()..files = picked;
    final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance, units: ['الفلة الغربية']);
    final contract = api.addContract('project-0', 'مبلط الغربية', value: 34000);
    contract['documents'] = [
      {'id': 'kept-document', 'fileName': 'العقد.pdf'},
    ];
    apiOfDocuments = api;
    await openProject(tester, api, capture: capture);
    await tester.ensureVisible(find.byKey(HomeScreen.contractsKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractsKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.menuKey(contract['id']! as String))));
    await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.editKey)));
    return capture;
  }

  final pdf = PickedFile('ملحق.pdf', '/phone/ملحق.pdf', Uint8List.fromList([0x25, 0x50, 0x44, 0x46]));

  testWidgets('BR-10: what waits for approval shows beside what was paid, and leaves the remaining alone', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance, units: ['الفلة الغربية']);
    final contract = api.addContract('project-0', 'مبلط الغربية', value: 34000, paid: 30000, pending: 2000);
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.contractsKey('project-0')));
    await tester.pumpAndSettle();

    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractsKey('project-0'))));

    final id = contract['id']! as String;
    expect(text(tester, ContractsScreen.pendingKey(id)), 'en contracts.pending 2,000.00 · 2,000.00 en contracts.afterApproval');
    expect(text(tester, ContractsScreen.remainingKey(id)), '4,000.00');
  });

  testWidgets("the dialog shows a contract's documents, and a document picked is kept and named on save", (tester) async {
    await openAmendWithFiles(tester, pdf);
    final api = apiOfDocuments;
    expect(find.text('العقد.pdf'), findsOneWidget);

    await tapVisible(tester, api, ContractsScreen.addDocumentKey);
    expect(api.sentAttachments, hasLength(1));
    await save(tester, api);

    final (path, body) = api.sentSettingsChanges.single;
    expect(path, endsWith('/contracts/contract-0'));
    expect((body['attachmentIds'] as List<dynamic>).single, startsWith('attachment-'));
  });

  testWidgets("findings row 138: a contract's document may be any file, and goes up as a document, as the project's Documents do", (tester) async {
    await openAmendWithFiles(tester, PickedFile('quantities.xlsx', '/phone/quantities.xlsx', Uint8List.fromList([0x50, 0x4B, 0x03, 0x04])));
    final api = apiOfDocuments;

    await tapVisible(tester, api, ContractsScreen.addDocumentKey);

    expect(api.sentAttachmentPaths.single, '/projects/project-0/attachments/document');
    expect(find.text('quantities.xlsx'), findsOneWidget);
  });

  testWidgets('a document the API refuses says why, and nothing is named on save', (tester) async {
    await openAmendWithFiles(tester, pdf);
    final api = apiOfDocuments..attachmentAnswer = (status: 400, code: 'invalidFileType');

    await tapVisible(tester, api, ContractsScreen.addDocumentKey);

    expect(tester.widget<Text>(find.byKey(ContractsScreen.documentMessageKey)).data, 'en attachments.invalidFileType');
    await save(tester, api);
    expect(api.sentSettingsChanges.single.$2.containsKey('attachmentIds'), isFalse);
  });

  testWidgets('going back from the files keeps nothing', (tester) async {
    await openAmendWithFiles(tester, PickedFile.none());
    final api = apiOfDocuments;

    await tapVisible(tester, api, ContractsScreen.addDocumentKey);

    expect(api.sentAttachments, isEmpty);
    expect(find.byKey(ContractsScreen.documentMessageKey), findsNothing);
  });

  testWidgets('each contract shows its contractor, item and figures', (tester) async {
    final opened = await openContracts(tester);

    expect(text(tester, ContractsScreen.nameKey(opened.running)), 'مبلط الغربية');
    expect(text(tester, ContractsScreen.termsKey(opened.running)), 'البلاط');
    expect(text(tester, ContractsScreen.valueOfKey(opened.running)), '34,000.00');
    expect(text(tester, ContractsScreen.paidKey(opened.running)), '30,000.00');
  });

  testWidgets('AC-07.1: a contract shows what remains of it, and how it stands', (tester) async {
    final opened = await openContracts(tester);

    expect(text(tester, ContractsScreen.remainingKey(opened.running)), '4,000.00');
    expect(find.descendant(of: find.byKey(ContractsScreen.standingKey(opened.running)), matching: find.text('en contracts.running')), findsOneWidget);
  });

  testWidgets('AC-07.1: an overrun shows its remaining in brackets, with an alert', (tester) async {
    final opened = await openContracts(tester);

    expect(text(tester, ContractsScreen.remainingKey(opened.overrun)), '(1,000.00)');
    expect(find.descendant(of: find.byKey(ContractsScreen.standingKey(opened.overrun)), matching: find.text('en contracts.overrun')), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byKey(ContractsScreen.progressKey(opened.overrun))).value, 1);
  });

  testWidgets('an open-value contract has nothing to remain, so what waits stands alone', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance, units: ['الفلة الغربية']);
    final contract = api.addContract('project-0', 'دهان داخلي', isOpenValue: true, paid: 12000, pending: 500);
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.contractsKey('project-0')));
    await tester.pumpAndSettle();

    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractsKey('project-0'))));

    expect(text(tester, ContractsScreen.pendingKey(contract['id']! as String)), 'en contracts.pending 500.00');
  });

  testWidgets('AC-07.2: an open-value contract adds up, with no remaining and no alert', (tester) async {
    final opened = await openContracts(tester);

    expect(text(tester, ContractsScreen.valueOfKey(opened.open)), 'en contracts.open');
    expect(text(tester, ContractsScreen.paidKey(opened.open)), '12,000.00');
    expect(text(tester, ContractsScreen.remainingKey(opened.open)), '—');
    expect(find.descendant(of: find.byKey(ContractsScreen.standingKey(opened.open)), matching: find.text('en contracts.openValue')), findsOneWidget);
  });

  testWidgets('a contract with nothing paid has not started', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    final contract = api.addContract('project-0', 'الدرابزين', value: 19000, unitPrice: 380, quantity: 50)['id'] as String;
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.contractsKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractsKey('project-0'))));

    expect(find.descendant(of: find.byKey(ContractsScreen.standingKey(contract)), matching: find.text('en contracts.notStarted')), findsOneWidget);
    expect(text(tester, ContractsScreen.termsKey(contract)), 'البلاط · 380 × 50');
  });

  testWidgets('the filters count their contracts and keep only those', (tester) async {
    final opened = await openContracts(tester);

    expect(find.text('en contracts.filterAll · 3'), findsOneWidget);
    expect(find.text('en contracts.filterOverrun · 1'), findsOneWidget);
    expect(find.text('en contracts.filterOpenValue · 1'), findsOneWidget);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.filterKey(ContractFilter.overrun))));
    expect(find.byKey(ContractsScreen.nameKey(opened.overrun)), findsOneWidget);
    expect(find.byKey(ContractsScreen.nameKey(opened.running)), findsNothing);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.filterKey(ContractFilter.openValue))));
    expect(find.byKey(ContractsScreen.nameKey(opened.open)), findsOneWidget);
    expect(find.byKey(ContractsScreen.nameKey(opened.overrun)), findsNothing);
  });

  testWidgets('a filter that keeps no contract says there are none rather than showing a blank page', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    api.addContract('project-0', 'مبلط الغربية', value: 34000, paid: 30000);
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.contractsKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractsKey('project-0'))));

    await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.filterKey(ContractFilter.overrun))));

    expect(text(tester, ApiListBody.emptyKey), 'en contracts.empty');
  });

  testWidgets('adding sends the contractor, item and terms', (tester) async {
    final opened = await openContracts(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.addKey)));
    await pickContractor(tester, opened.api, opened.contractor);
    expect(find.text('شركة النخيل'), findsOneWidget);
    await pickItem(tester, opened.api, opened.item);
    await tester.enterText(find.byKey(ContractsScreen.valueKey), '٣٤٬٠٠٠');
    await tester.enterText(find.byKey(ContractsScreen.unitPriceKey), '380');
    await tester.enterText(find.byKey(ContractsScreen.quantityKey), '89.47');
    await tester.enterText(find.byKey(ContractsScreen.notesKey), 'دفعات شهرية');
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/contracts');
    expect(opened.api.sentSettingsChanges.single.$2, {
      'supplierId': opened.contractor,
      'itemId': opened.item,
      'value': 34000.0,
      'isOpenValue': false,
      'unitPrice': 380.0,
      'quantity': 89.47,
      'notes': 'دفعات شهرية',
    });
    expect(find.byKey(ContractsScreen.contractorKey), findsNothing);
  });

  testWidgets('a contractor missing from the register is added from the picker and goes on', (tester) async {
    final opened = await openContracts(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.addKey)));
    await tapVisible(tester, opened.api, ContractsScreen.contractorKey);
    await act(tester, opened.api, () => tester.tap(find.byKey(SupplierPicker.quickAddKey)));
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'مبلط جديد');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), '311111111111113');
    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey).last));

    expect(find.byKey(SupplierPicker.searchKey), findsNothing);
    expect(find.byKey(ContractsScreen.contractorKey), findsOneWidget);
    expect(find.text('مبلط جديد'), findsOneWidget);
  });

  testWidgets('nothing chosen is left for the API to refuse, and stays in the dialog', (tester) async {
    final opened = await openContracts(tester);
    opened.api.settingsAnswer = (status: 400, code: 'unknownSupplier');

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.addKey)));
    await tester.enterText(find.byKey(ContractsScreen.valueKey), '1000');
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.single.$2.containsKey('supplierId'), isFalse);
    expect(text(tester, ChangeDialog.messageKey), 'en contracts.unknownSupplier');
  });

  testWidgets('an open-value contract asks no value and sends the mark', (tester) async {
    final opened = await openContracts(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.addKey)));
    await pickContractor(tester, opened.api, opened.contractor);
    await pickItem(tester, opened.api, opened.item);
    await tapVisible(tester, opened.api, ContractsScreen.openValueKey);
    expect(find.byKey(ContractsScreen.valueKey), findsNothing);
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.single.$2['isOpenValue'], isTrue);
    expect(opened.api.sentSettingsChanges.single.$2['value'], 0.0);
  });

  testWidgets('figures that are not numbers are refused before anything is sent', (tester) async {
    final opened = await openContracts(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.addKey)));
    await tester.enterText(find.byKey(ContractsScreen.valueKey), 'x');
    await save(tester, opened.api);
    expect(text(tester, ChangeDialog.messageKey), 'en contracts.invalidValue');

    await tester.enterText(find.byKey(ContractsScreen.valueKey), '1000');
    await tester.enterText(find.byKey(ContractsScreen.unitPriceKey), 'x');
    await save(tester, opened.api);
    expect(text(tester, ChangeDialog.messageKey), 'en contracts.invalidUnitPrice');

    await tester.enterText(find.byKey(ContractsScreen.unitPriceKey), '');
    await tester.enterText(find.byKey(ContractsScreen.quantityKey), 'x');
    await save(tester, opened.api);
    expect(text(tester, ChangeDialog.messageKey), 'en contracts.invalidQuantity');

    expect(opened.api.sentSettingsChanges, isEmpty);
  });

  testWidgets('a contract with no payments offers its contractor and item, starting from what it has, and sends them', (tester) async {
    final opened = await openContracts(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.menuKey(opened.running))));
    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.editKey)));

    expect(find.byKey(ContractsScreen.partiesKey), findsNothing);
    expect(tester.widget<PickerField>(find.byKey(ContractsScreen.contractorKey)).value, 'مبلط الغربية');
    expect(tester.widget<ItemPicker>(find.byKey(ContractsScreen.itemKey)).itemName, 'البلاط');
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.single.$2, containsPair('supplierId', 'supplier-of-contract'));
    expect(opened.api.sentSettingsChanges.single.$2, containsPair('itemId', 'item-of-contract'));
  });

  testWidgets('a refused change of contractor stays in the dialog and says why', (tester) async {
    final opened = await openContracts(tester);
    opened.api.settingsAnswer = (status: 409, code: 'contractHasPayments');

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.menuKey(opened.running))));
    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.editKey)));
    await save(tester, opened.api);

    expect(text(tester, ChangeDialog.messageKey), 'en contracts.contractHasPayments');
  });

  testWidgets('amending a contract with payments starts from it, whose contractor and item stay', (tester) async {
    final opened = await openContracts(tester, hasPayments: true);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.menuKey(opened.running))));
    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.editKey)));

    expect(text(tester, ContractsScreen.partiesKey), 'مبلط الغربية · البلاط');
    expect(find.byKey(ContractsScreen.contractorKey), findsNothing);
    expect(find.byKey(ContractsScreen.itemKey), findsNothing);
    expect(tester.widget<TextField>(find.byKey(ContractsScreen.valueKey)).controller!.text, '34000');

    await tester.enterText(find.byKey(ContractsScreen.valueKey), '36000');
    await tester.enterText(find.byKey(ContractsScreen.notesKey), 'زيادة بملحق');
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/contracts/${opened.running}');
    expect(opened.api.sentSettingsChanges.single.$2, {'value': 36000.0, 'isOpenValue': false, 'unitPrice': 0.0, 'quantity': 0.0, 'notes': 'زيادة بملحق'});
    expect(text(tester, ContractsScreen.valueOfKey(opened.running)), '36,000.00');
    expect(text(tester, ContractsScreen.contractNotesKey(opened.running)), 'زيادة بملحق');
  });

  testWidgets('saving with the keyboard up closes it with the dialog', (tester) async {
    final opened = await openContracts(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.menuKey(opened.running))));
    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.editKey)));
    await tester.tap(find.byKey(ContractsScreen.valueKey));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await save(tester, opened.api);

    expect(find.byKey(ContractsScreen.valueKey), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('a disabled contract stays on the list, marked, and can be enabled', (tester) async {
    final opened = await openContracts(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.menuKey(opened.running))));
    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.disableKey)));
    expect(find.descendant(of: find.byKey(ContractsScreen.standingKey(opened.running)), matching: find.text('en contracts.disabled')), findsOneWidget);

    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.menuKey(opened.running))));
    await act(tester, opened.api, () => tester.tap(find.byKey(ContractsScreen.enableKey)));
    expect(find.descendant(of: find.byKey(ContractsScreen.standingKey(opened.running)), matching: find.text('en contracts.running')), findsOneWidget);
  });

  testWidgets('a project with no contracts says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.contractsKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractsKey('project-0'))));

    expect(text(tester, ApiListBody.emptyKey), 'en contracts.empty');
  });

  testWidgets('without keeping the settings the contracts show with nothing to change', (tester) async {
    final opened = await openContracts(tester, permissions: field);

    expect(text(tester, ContractsScreen.remainingKey(opened.running)), '4,000.00');
    expect(isEnabled(tester, ContractsScreen.addKey), isFalse);
    expect(find.byKey(ContractsScreen.menuKey(opened.running)), findsNothing);
  });

  testWidgets('a finished project shows its contracts with nothing to change', (tester) async {
    final opened = await openContracts(tester, status: 'finished');

    expect(isEnabled(tester, ContractsScreen.addKey), isFalse);
    expect(find.byKey(ContractsScreen.menuKey(opened.running)), findsNothing);
  });

  testWidgets('a list that cannot be read says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.contractsKey('project-0')));
    await tester.pumpAndSettle();
    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractsKey('project-0'))));

    expect(text(tester, ApiListBody.messageKey), 'en contracts.loadFailed');
  });
}
