import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/suppliers/supplier.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers.dart';

import '../app_harness.dart';

void main() {
  const vatNumber = '300000000000003';

  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A register with two suppliers, the picker open on it; what it answers lands in the record's list.
  Future<({FakeApi api, Suppliers suppliers, String palm, String oasis, List<Supplier> picked})> openPicker(WidgetTester tester) async {
    final api = FakeApi()..addProject('غصون 6');
    final palm = api.addSupplier('project-0', 'شركة النخيل', vatNumber: vatNumber, defaultItemName: 'البلاط');
    final oasis = api.addSupplier('project-0', 'مؤسسة الواحة');
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    final suppliers = Suppliers(session, 'project-0');
    final picked = <Supplier>[];
    await act(tester, api, () async => unawaited(SupplierPicker.show(tester.element(find.byType(ProjectsScreen)), suppliers).then(picked.add)));
    return (api: api, suppliers: suppliers, palm: palm['id'] as String, oasis: oasis['id'] as String, picked: picked);
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

    expect(text(tester, SupplierPicker.emptyKey), 'en suppliers.noMatch');
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

  testWidgets('opening again starts with nothing typed', (tester) async {
    final opened = await openPicker(tester);
    await act(tester, opened.api, () => tester.enterText(find.byKey(SupplierPicker.searchKey), 'نخي'));
    await act(tester, opened.api, () => tester.tap(find.byKey(SupplierPicker.closeKey)));

    await act(tester, opened.api, () async => unawaited(SupplierPicker.show(tester.element(find.byType(ProjectsScreen)), opened.suppliers)));

    expect(opened.api.supplierSearches.last, isEmpty);
    expect(find.byKey(SupplierPicker.rowKey(opened.oasis)), findsOneWidget);
  });
}
