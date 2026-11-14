import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/project.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/suppliers/supplier.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/words/words.dart';

import '../app_harness.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/api_list_body.dart';

void main() {
  testWidgets('AC-43.1: the title over what was used most shows only while nothing is typed, and only once something was used', (tester) async {
    final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية']);
    final supplier = api.addSupplier('project-0', 'شركة النخيل', vatNumber: '300000000000003', timesUsed: 3);
    api.addCategory('project-0', 'التشطيب');
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.addEntryKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));
    await tester.ensureVisible(find.byKey(AddEntryScreen.supplierKey));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.supplierKey)));

    expect(tester.widget<Text>(find.byKey(SupplierPicker.mostUsedKey)).data, 'en suppliers.mostUsed');

    await act(tester, api, () => tester.enterText(find.byKey(SupplierPicker.searchKey), 'نخيل'));
    expect(find.byKey(SupplierPicker.mostUsedKey), findsNothing);

    await act(tester, api, () => tester.enterText(find.byKey(SupplierPicker.searchKey), ''));
    expect(find.byKey(SupplierPicker.mostUsedKey), findsOneWidget);

    supplier['timesUsed'] = 0;
    await act(tester, api, () => tester.enterText(find.byKey(SupplierPicker.searchKey), ' '));
    expect(find.byKey(SupplierPicker.mostUsedKey), findsNothing);
  });

  const vatNumber = '300000000000003';

  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A register with two suppliers, the picker open on it for someone with [permissions] in a project of [status]; what it answers lands in the record's list.
  Future<({FakeApi api, Project project, Suppliers suppliers, String palm, String oasis, List<Supplier> picked})> openPicker(WidgetTester tester, {List<String> permissions = managerAndFinance, String status = 'active'}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, status: status);
    final project = Project.fromJson(jsonDecode(jsonEncode(api.projects.single)) as Map<String, dynamic>);
    final palm = api.addSupplier('project-0', 'شركة النخيل', vatNumber: vatNumber, defaultItemName: 'البلاط');
    final oasis = api.addSupplier('project-0', 'مؤسسة الواحة');
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    final suppliers = Suppliers(session, 'project-0');
    final picked = <Supplier>[];
    await act(tester, api, () async => unawaited(SupplierPicker.show(tester.element(find.byKey(ProjectsScreen.sharedSettingsKey)), project, suppliers).then(picked.add)));
    return (api: api, project: project, suppliers: suppliers, palm: palm['id'] as String, oasis: oasis['id'] as String, picked: picked);
  }

  testWidgets('opening shows what is on offer, each with its VAT number and default item', (tester) async {
    final opened = await openPicker(tester);

    expect(find.byKey(SupplierPicker.rowKey(opened.palm)), findsOneWidget);
    expect(find.byKey(SupplierPicker.rowKey(opened.oasis)), findsOneWidget);
    expect(text(tester, SupplierPicker.detailsKey(opened.palm)), '$vatNumber · البلاط');
  });

  testWidgets('typing shows what the API finds', (tester) async {
    final opened = await openPicker(tester);

    await act(tester, opened.api, () => tester.enterText(find.byKey(SupplierPicker.searchKey), 'نخي'));

    expect(find.byKey(SupplierPicker.rowKey(opened.palm)), findsOneWidget);
    expect(find.byKey(SupplierPicker.rowKey(opened.oasis)), findsNothing);
  });

  testWidgets('part of a VAT number typed in Arabic digits is asked in Western ones', (tester) async {
    final opened = await openPicker(tester);

    await act(tester, opened.api, () => tester.enterText(find.byKey(SupplierPicker.searchKey), '٣٠٠٠'));

    expect(opened.api.supplierSearches.last, '3000');
    expect(find.byKey(SupplierPicker.rowKey(opened.palm)), findsOneWidget);
  });

  testWidgets('picking closes the sheet and answers the supplier, with its VAT number', (tester) async {
    final opened = await openPicker(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(SupplierPicker.rowKey(opened.palm))));

    expect(find.byKey(SupplierPicker.searchKey), findsNothing);
    expect(opened.picked.single.id, opened.palm);
    expect(opened.picked.single.vatNumber, vatNumber);
  });

  testWidgets('closing answers no supplier', (tester) async {
    final opened = await openPicker(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(SupplierPicker.closeKey)));

    expect(opened.picked.single.id, isEmpty);
  });

  testWidgets('a search that finds nothing says so', (tester) async {
    final opened = await openPicker(tester);

    await act(tester, opened.api, () => tester.enterText(find.byKey(SupplierPicker.searchKey), 'لا أحد'));

    expect(text(tester, ApiListBody.emptyKey), 'en suppliers.noMatch');
  });

  testWidgets('an answer to an older search never replaces a newer one', (tester) async {
    final opened = await openPicker(tester);
    final older = Completer<void>();
    opened.api.heldSupplierSearches['نخي'] = older;

    await act(tester, opened.api, () async {
      await tester.enterText(find.byKey(SupplierPicker.searchKey), 'نخي');
      await tester.pump();
      await tester.enterText(find.byKey(SupplierPicker.searchKey), 'واح');
    });
    expect(find.byKey(SupplierPicker.rowKey(opened.oasis)), findsOneWidget);

    await act(tester, opened.api, () async => older.complete());

    expect(find.byKey(SupplierPicker.rowKey(opened.oasis)), findsOneWidget);
    expect(find.byKey(SupplierPicker.rowKey(opened.palm)), findsNothing);
  });

  Future<void> quickAdd(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byKey(SupplierPicker.quickAddKey)));

  Future<void> save(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

  String typedIn(WidgetTester tester, Key key) => tester.widget<TextField>(find.byKey(key)).controller!.text;

  testWidgets('a name typed in the search starts the quick add\'s name', (tester) async {
    final opened = await openPicker(tester, permissions: field);

    await act(tester, opened.api, () => tester.enterText(find.byKey(SupplierPicker.searchKey), 'شركة الأفق'));
    await quickAdd(tester, opened.api);

    expect(typedIn(tester, SuppliersScreen.supplierNameKey), 'شركة الأفق');
    expect(typedIn(tester, SuppliersScreen.vatNumberKey), isEmpty);
  });

  testWidgets('a number typed in the search starts the quick add\'s VAT number', (tester) async {
    final opened = await openPicker(tester, permissions: field);

    await act(tester, opened.api, () => tester.enterText(find.byKey(SupplierPicker.searchKey), '٣١١١١١١١١١١١١١٣'));
    await quickAdd(tester, opened.api);

    expect(typedIn(tester, SuppliersScreen.vatNumberKey), '311111111111113');
    expect(typedIn(tester, SuppliersScreen.supplierNameKey), isEmpty);
  });

  testWidgets('AC-44.1: what Field adds is picked, and shows to them pending approval', (tester) async {
    final opened = await openPicker(tester, permissions: field);

    await quickAdd(tester, opened.api);
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'شركة الأفق');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), '311111111111113');
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'شركة الأفق', 'vatNumber': '311111111111113'});
    expect(find.byKey(SupplierPicker.searchKey), findsNothing);
    expect(opened.picked.single.name, 'شركة الأفق');
    expect(opened.picked.single.status, SupplierStatus.pendingApproval);
    expect(opened.picked.single.detailsIn(Words.of(tester.element(find.byKey(ProjectsScreen.sharedSettingsKey)))), startsWith('en suppliers.pendingApproval'));
  });

  testWidgets('the quick add says a new supplier waits for approval to whoever does not keep the settings', (tester) async {
    final opened = await openPicker(tester, permissions: field);

    await quickAdd(tester, opened.api);

    expect(text(tester, SupplierPicker.pendingHintKey), 'en suppliers.pendingHint');
  });

  testWidgets('whoever keeps the settings adds an approved supplier, and is told nothing of waiting', (tester) async {
    final opened = await openPicker(tester);

    await quickAdd(tester, opened.api);
    expect(find.byKey(SupplierPicker.pendingHintKey), findsNothing);
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'شركة الأفق');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), '311111111111113');
    await save(tester, opened.api);

    expect(opened.picked.single.status, SupplierStatus.approved);
  });

  testWidgets('an invalid VAT number is blocked with the rule shown', (tester) async {
    final opened = await openPicker(tester, permissions: field);
    opened.api.settingsAnswer = (status: 400, code: 'invalidVatNumber');

    await quickAdd(tester, opened.api);
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'مورد');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), '30088967710003');
    await save(tester, opened.api);

    expect(text(tester, ChangeDialog.messageKey), 'en suppliers.invalidVatNumber');
    expect(opened.picked, isEmpty);
    expect(find.byKey(SupplierPicker.useExistingKey), findsNothing);
  });

  testWidgets('a VAT number already used names the existing supplier and offers it instead', (tester) async {
    final opened = await openPicker(tester, permissions: field);
    opened.api
      ..settingsAnswer = (status: 409, code: 'vatNumberTaken')
      ..supplierHolder = opened.api.suppliers['project-0']!.first;

    await quickAdd(tester, opened.api);
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'النخيل');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), vatNumber);
    await save(tester, opened.api);
    expect(text(tester, SuppliersScreen.holderKey), 'en suppliers.holder شركة النخيل');

    await act(tester, opened.api, () => tester.tap(find.byKey(SupplierPicker.useExistingKey)));

    expect(find.byKey(SupplierPicker.searchKey), findsNothing);
    expect(opened.picked.single.id, opened.palm);
  });

  testWidgets('a disabled supplier holding the number is named and not offered', (tester) async {
    final opened = await openPicker(tester, permissions: field);
    opened.api
      ..settingsAnswer = (status: 409, code: 'vatNumberTaken')
      ..supplierHolder = {...opened.api.suppliers['project-0']!.first, 'isActive': false};

    await quickAdd(tester, opened.api);
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'النخيل');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), vatNumber);
    await save(tester, opened.api);

    expect(text(tester, SuppliersScreen.holderKey), 'en suppliers.holder شركة النخيل');
    expect(find.byKey(SupplierPicker.useExistingKey), findsNothing);
  });

  testWidgets('closing the quick add goes back to the search', (tester) async {
    final opened = await openPicker(tester, permissions: field);

    await quickAdd(tester, opened.api);
    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.cancelKey)));

    expect(find.byKey(SupplierPicker.searchKey), findsOneWidget);
    expect(opened.picked, isEmpty);
  });

  testWidgets('without a way to add a supplier there is no quick add', (tester) async {
    await openPicker(tester, permissions: ['readProject']);

    expect(find.byKey(SupplierPicker.quickAddKey), findsNothing);
  });

  testWidgets('a finished project offers no quick add', (tester) async {
    await openPicker(tester, status: 'finished');

    expect(find.byKey(SupplierPicker.quickAddKey), findsNothing);
  });

  testWidgets('opening again starts with nothing typed', (tester) async {
    final opened = await openPicker(tester);
    await act(tester, opened.api, () => tester.enterText(find.byKey(SupplierPicker.searchKey), 'نخي'));
    await act(tester, opened.api, () => tester.tap(find.byKey(SupplierPicker.closeKey)));

    await act(tester, opened.api, () async => unawaited(SupplierPicker.show(tester.element(find.byKey(ProjectsScreen.sharedSettingsKey)), opened.project, opened.suppliers)));

    expect(opened.api.supplierSearches.last, isEmpty);
    expect(find.byKey(SupplierPicker.rowKey(opened.oasis)), findsOneWidget);
  });
}
