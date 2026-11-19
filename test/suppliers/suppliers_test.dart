// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/structure/item_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';
import 'package:redix/ui/change_dialog.dart';

void main() {
  const vatNumber = '300000000000003';

  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A project with one approved supplier and one pending, opened as far as its register.
  Future<({FakeApi api, String approved, String pending})> openSuppliers(WidgetTester tester, {String status = 'active', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('مشروع A', status: status, permissions: permissions);
    final tiling = api.addCategory('project-0', 'التشطيب');
    api.addItem(tiling, 'البلاط');
    final approved = api.addSupplier('project-0', 'شركة النخيل', vatNumber: vatNumber, defaultItemName: 'اللياسة');
    final pending = api.addSupplier('project-0', 'بقالة الحي', status: 'pendingApproval');
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.suppliersKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, api, HomeScreen.suppliersKey('project-0'));
    return (api: api, approved: approved['id'] as String, pending: pending['id'] as String);
  }

  Future<void> openMenu(WidgetTester tester, FakeApi api, String id) => act(tester, api, () => tester.tap(find.byKey(SuppliersScreen.menuKey(id))));

  Future<void> save(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

  testWidgets('each supplier shows its VAT number and default item', (tester) async {
    final opened = await openSuppliers(tester);

    expect(text(tester, SuppliersScreen.nameKey(opened.approved)), 'شركة النخيل');
    expect(text(tester, SuppliersScreen.detailsKey(opened.approved)), '$vatNumber · اللياسة');
  });

  testWidgets('a supplier pending approval is marked, and one with no number shows none', (tester) async {
    final opened = await openSuppliers(tester);

    expect(text(tester, SuppliersScreen.detailsKey(opened.pending)), 'en suppliers.pendingApproval');
  });

  testWidgets('adding sends the name and the VAT number, and only what was filled in', (tester) async {
    final opened = await openSuppliers(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.addKey)));
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'شركة الأفق');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), '311111111111113');
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/suppliers');
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'شركة الأفق', 'vatNumber': '311111111111113'});
    final added = opened.api.suppliers['project-0']!.singleWhere((supplier) => supplier['name'] == 'شركة الأفق')['id']! as String;
    expect(text(tester, SuppliersScreen.nameKey(added)), 'شركة الأفق');
    expect(find.byKey(SuppliersScreen.supplierNameKey), findsNothing);
  });

  testWidgets('a VAT number and a mobile typed in Arabic digits are sent in Western ones', (tester) async {
    final opened = await openSuppliers(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.addKey)));
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'مورد');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), '٣١١١١١١١١١١١١١٣');
    await tester.enterText(find.byKey(SuppliersScreen.mobileKey), '٠٥٠٠');
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'مورد', 'vatNumber': '311111111111113', 'mobile': '0500'});
  });

  testWidgets('BR-16: a supplier is sent with its VAT number left empty, as having none, and there is no switch for it', (tester) async {
    final opened = await openSuppliers(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.addKey)));
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'مورد');
    await save(tester, opened.api);

    expect(find.byType(SwitchListTile), findsNothing);
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'مورد', 'vatNumber': ''});
  });

  testWidgets('an invalid VAT number stays in the dialog with the rule', (tester) async {
    final opened = await openSuppliers(tester);
    opened.api.settingsAnswer = (status: 400, code: 'invalidVatNumber');

    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.addKey)));
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'مورد');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), '30088967710003');
    await save(tester, opened.api);

    expect(text(tester, ChangeDialog.messageKey), 'en suppliers.invalidVatNumber');
    expect(find.byKey(SuppliersScreen.holderKey), findsNothing);
  });

  testWidgets('a VAT number another supplier holds is refused, naming that supplier', (tester) async {
    final opened = await openSuppliers(tester);
    opened.api
      ..settingsAnswer = (status: 409, code: 'vatNumberTaken')
      ..supplierHolder = opened.api.suppliers['project-0']!.first;

    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.addKey)));
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'النخيل للتجارة');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), vatNumber);
    await save(tester, opened.api);

    expect(text(tester, ChangeDialog.messageKey), 'en suppliers.vatNumberTaken');
    expect(text(tester, SuppliersScreen.holderKey), 'en suppliers.holder شركة النخيل');
  });

  testWidgets('editing starts from the supplier and changes it', (tester) async {
    final opened = await openSuppliers(tester);

    await openMenu(tester, opened.api, opened.approved);
    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.editKey)));
    expect(tester.widget<TextField>(find.byKey(SuppliersScreen.vatNumberKey)).controller!.text, vatNumber);
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'النخيل');
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.single.$1, 'PUT /projects/project-0/suppliers/${opened.approved}');
    expect(text(tester, SuppliersScreen.nameKey(opened.approved)), 'النخيل');
  });

  testWidgets('editing a supplier with no number shows its VAT number empty', (tester) async {
    final opened = await openSuppliers(tester);

    await openMenu(tester, opened.api, opened.pending);
    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.editKey)));

    expect(tester.widget<TextField>(find.byKey(SuppliersScreen.vatNumberKey)).controller!.text, '');
  });

  testWidgets('a default item is chosen among what a purchase is offered, and can be taken away', (tester) async {
    final opened = await openSuppliers(tester);
    final item = (opened.api.categories['project-0']!.first['items']! as List<Map<String, Object>>).first['id']! as String;

    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.addKey)));
    await tester.enterText(find.byKey(SuppliersScreen.supplierNameKey), 'مورد');
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), '311111111111113');
    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.defaultItemKey)));
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemPicker.optionKey(item))));
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.single.$2['defaultItemId'], item);
    final added = opened.api.suppliers['project-0']!.last['id']! as String;
    expect(text(tester, SuppliersScreen.detailsKey(added)), '311111111111113 · البلاط');

    await openMenu(tester, opened.api, added);
    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.editKey)));
    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.defaultItemKey)));
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemPicker.optionKey(''))));
    await save(tester, opened.api);

    expect(opened.api.sentSettingsChanges.last.$2.containsKey('defaultItemId'), isFalse);
  });

  testWidgets('the general cash supplier stays active, and the refusal says why', (tester) async {
    final opened = await openSuppliers(tester);
    opened.api.settingsAnswer = (status: 409, code: 'generalCashSupplier');

    await openMenu(tester, opened.api, opened.approved);
    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.disableKey)));

    expect(text(tester, messageKeyOf('suppliers.generalCashSupplier').label), 'en suppliers.generalCashSupplier');
    expect(text(tester, SuppliersScreen.detailsKey(opened.approved)), isNot(contains('en suppliers.disabled')));
  });

  testWidgets('a disabled supplier stays on the list, marked, and can be enabled', (tester) async {
    final opened = await openSuppliers(tester);

    await openMenu(tester, opened.api, opened.approved);
    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.disableKey)));
    expect(text(tester, SuppliersScreen.detailsKey(opened.approved)), startsWith('en suppliers.disabled'));

    await openMenu(tester, opened.api, opened.approved);
    await act(tester, opened.api, () => tester.tap(find.byKey(SuppliersScreen.enableKey)));
    expect(text(tester, SuppliersScreen.detailsKey(opened.approved)), isNot(startsWith('en suppliers.disabled')));
  });

  testWidgets('a project with no suppliers says so', (tester) async {
    final api = FakeApi()..addProject('مشروع A');
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.suppliersKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, api, HomeScreen.suppliersKey('project-0'));

    expect(text(tester, ApiListBody.emptyKey), 'en suppliers.empty');
  });

  testWidgets('without keeping the settings the register shows with nothing to change', (tester) async {
    final opened = await openSuppliers(tester, permissions: ['readProject']);

    expect(text(tester, SuppliersScreen.nameKey(opened.approved)), 'شركة النخيل');
    expect(isEnabled(tester, SuppliersScreen.addKey), isFalse);
    expect(find.byKey(SuppliersScreen.menuKey(opened.approved)), findsNothing);
  });

  testWidgets('a finished project shows its register with nothing to change', (tester) async {
    final opened = await openSuppliers(tester, status: 'finished');

    expect(isEnabled(tester, SuppliersScreen.addKey), isFalse);
    expect(find.byKey(SuppliersScreen.menuKey(opened.approved)), findsNothing);
  });

  testWidgets('a list that cannot be read says so', (tester) async {
    final api = FakeApi()..addProject('مشروع A');
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.suppliersKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    api.online = false;
    await scrollAndTap(tester, api, HomeScreen.suppliersKey('project-0'));

    expect(text(tester, ApiListBody.messageKey), 'en suppliers.loadFailed');
  });
}
