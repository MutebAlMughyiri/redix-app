import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/structure/apply_to_all_dialog.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/category.dart';
import 'package:redix/structure/columns.dart';
import 'package:redix/structure/item_columns_screen.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  final itemPath = Columns.itemPath('project-0', 'item-1');
  final templatePath = Columns.templatePath('project-0', ItemType.both);

  /// The tiles item of a project, opened as far as its own columns: a core date, a unit that is not core, and a custom area.
  Future<({FakeApi api, String date, String unit, String area})> openColumns(WidgetTester tester, {String status = 'running', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, permissions: permissions);
    final finishing = api.addCategory('project-0', 'التشطيب');
    api.addItem(finishing, 'البلاط');
    final date = api.addColumn(itemPath, 'التاريخ', dataType: 'date', isCore: true, isRequired: true, showInReports: true);
    final unit = api.addColumn(itemPath, 'الوحدة', dataType: 'list');
    final area = api.addColumn(itemPath, 'المساحة م²', dataType: 'number', isCustom: true, isRequired: true, showInReports: true);
    api.addColumn(templatePath, 'تاريخ القالب', dataType: 'date', isCore: true, isRequired: true);
    api.addColumn(templatePath, 'وحدة القالب', dataType: 'list');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.categoriesKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.categoriesKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.categoryTileKey('category-0'))));
    await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.itemColumnsKey('item-1'))));
    return (api: api, date: date['id'] as String, unit: unit['id'] as String, area: area['id'] as String);
  }

  String templateColumn(FakeApi api, int index) => api.columns[templatePath]![index]['id'] as String;

  Future<void> showTemplate(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byKey(ItemColumnsScreen.templateKey)));

  Future<void> addColumn(WidgetTester tester, FakeApi api, String name) => act(tester, api, () async {
    await tester.tap(find.byKey(ItemColumnsScreen.addKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(ItemColumnsScreen.columnNameKey), name);
    await tester.tap(find.byKey(ItemColumnsScreen.saveKey));
  });

  Future<void> drag(WidgetTester tester, FakeApi api, Key handle, double by) => act(tester, api, () async {
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(handle)));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(Offset(0, by));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
  });

  testWidgets('it opens on this item, saying where the item sits and what it is', (tester) async {
    final opened = await openColumns(tester);

    expect(find.text('en columns.title · البلاط'), findsOneWidget);
    expect(text(tester, ItemColumnsScreen.itemDetailsKey), 'التشطيب · en categories.typeBoth');
    expect(text(tester, ItemColumnsScreen.nameKey(opened.date)), 'التاريخ');
  });

  testWidgets('a row says what the column is', (tester) async {
    final opened = await openColumns(tester);

    expect(text(tester, ItemColumnsScreen.detailsKey(opened.date)), 'en columns.typeDate · en columns.required · en columns.inReports');
    expect(text(tester, ItemColumnsScreen.detailsKey(opened.unit)), 'en columns.typeList · en columns.optional');
    expect(text(tester, ItemColumnsScreen.detailsKey(opened.area)), 'en columns.custom · en columns.typeNumber · en columns.required · en columns.inReports');
  });

  testWidgets('AC-41.2: a core column has a lock and no delete; any other has a delete and no lock', (tester) async {
    final opened = await openColumns(tester);

    expect(find.byKey(ItemColumnsScreen.lockKey(opened.date)), findsOneWidget);
    expect(find.byKey(ItemColumnsScreen.deleteKey(opened.date)), findsNothing);
    expect(find.byKey(ItemColumnsScreen.editKey(opened.date)), findsOneWidget);
    expect(find.byKey(ItemColumnsScreen.deleteKey(opened.unit)), findsOneWidget);
    expect(find.byKey(ItemColumnsScreen.lockKey(opened.unit)), findsNothing);
  });

  testWidgets('AC-41.1: a column is added to this item with what was chosen, asking nothing about other items', (tester) async {
    final opened = await openColumns(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.addKey)));
    await tester.enterText(find.byKey(ItemColumnsScreen.columnNameKey), 'رقم أمر الشراء');
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.dataTypeKey)));
    await act(tester, opened.api, () => tester.tap(find.text('en columns.typeNumber').last));
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.requiredKey)));
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.saveKey)));

    expect(find.byType(ApplyToAllDialog), findsNothing);
    expect(opened.api.sentStructureChanges.single.$1, itemPath);
    expect(opened.api.sentStructureChanges.single.$2, {
      'name': 'رقم أمر الشراء',
      'dataType': 'number',
      'isRequired': true,
      'showInReports': true,
      'options': <String>[],
      'applyToAllItems': false,
    });
    expect(find.text('رقم أمر الشراء'), findsOneWidget);
  });

  testWidgets('a pick list sends its choices, one a line, and offers no file type', (tester) async {
    final opened = await openColumns(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.addKey)));
    expect(find.byKey(ItemColumnsScreen.choicesKey), findsNothing);
    await tester.enterText(find.byKey(ItemColumnsScreen.columnNameKey), 'اللون');
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.dataTypeKey)));
    expect(find.text('en columns.typeFile'), findsNothing);
    await act(tester, opened.api, () => tester.tap(find.text('en columns.typeList').last));
    await tester.enterText(find.byKey(ItemColumnsScreen.choicesKey), 'أبيض\nرمادي');
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.saveKey)));

    expect(opened.api.sentStructureChanges.single.$2['options'], ['أبيض', 'رمادي']);
  });

  testWidgets('a refused column stays in its dialog with why', (tester) async {
    final opened = await openColumns(tester);
    opened.api.structureAnswer = (status: 400, code: 'invalidOptions');

    await addColumn(tester, opened.api, 'اللون');

    expect(text(tester, ItemColumnsScreen.dialogMessageKey), 'en columns.invalidOptions');
  });

  testWidgets('a core column changes its name only: its switches are off', (tester) async {
    final opened = await openColumns(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.editKey(opened.date))));

    expect(tester.widget<SwitchListTile>(find.byKey(ItemColumnsScreen.requiredKey)).onChanged, isNull);
    expect(tester.widget<SwitchListTile>(find.byKey(ItemColumnsScreen.showInReportsKey)).onChanged, isNull);
    await tester.enterText(find.byKey(ItemColumnsScreen.columnNameKey), 'تاريخ الفاتورة');
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.saveKey)));

    expect(opened.api.sentStructureChanges.single.$1, '$itemPath/${opened.date}');
    expect(opened.api.sentStructureChanges.single.$2, {'name': 'تاريخ الفاتورة', 'isRequired': true, 'showInReports': true, 'applyToAllItems': false});
    expect(text(tester, ItemColumnsScreen.nameKey(opened.date)), 'تاريخ الفاتورة');
  });

  testWidgets('another column changes what entry asks and what prints; no dialog offers its type', (tester) async {
    final opened = await openColumns(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.editKey(opened.unit))));
    expect(find.byKey(ItemColumnsScreen.dataTypeKey), findsNothing);
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.requiredKey)));
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.showInReportsKey)));
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.saveKey)));

    expect(text(tester, ItemColumnsScreen.detailsKey(opened.unit)), 'en columns.typeList · en columns.required · en columns.inReports');
  });

  testWidgets('deleting asks first and says values stay; Cancel changes nothing', (tester) async {
    final opened = await openColumns(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.deleteKey(opened.area))));
    expect(text(tester, ItemColumnsScreen.deleteExplainKey), 'en columns.deleteExplain');
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.cancelDeleteKey)));
    expect(opened.api.sentStructureChanges, isEmpty);

    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.deleteKey(opened.area))));
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.confirmDeleteKey)));

    expect(opened.api.sentStructureChanges.single.$1, '$itemPath/${opened.area}/delete');
    expect(find.byKey(ItemColumnsScreen.nameKey(opened.area)), findsNothing);
  });

  testWidgets('a refused delete shows why', (tester) async {
    final opened = await openColumns(tester);
    opened.api.structureAnswer = (status: 409, code: 'coreColumn');

    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.deleteKey(opened.unit))));
    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.confirmDeleteKey)));

    expect(find.text('en columns.coreColumn'), findsOneWidget);
    expect(find.byKey(ItemColumnsScreen.nameKey(opened.unit)), findsOneWidget);
  });

  testWidgets('dragging a column sends the new order, asking nothing on an item', (tester) async {
    final opened = await openColumns(tester);

    await drag(tester, opened.api, ItemColumnsScreen.handleKey(opened.date), 300);

    expect(find.byType(ApplyToAllDialog), findsNothing);
    expect(opened.api.sentStructureChanges.single.$1, '$itemPath/reorder');
    expect((opened.api.sentStructureChanges.single.$2['ids'] as List<dynamic>).first, opened.unit);
    expect(tester.getTopLeft(find.byKey(ItemColumnsScreen.rowKey(opened.unit))).dy, lessThan(tester.getTopLeft(find.byKey(ItemColumnsScreen.rowKey(opened.date))).dy));
  });

  testWidgets('the default template shows its own columns, and this item comes back', (tester) async {
    final opened = await openColumns(tester);

    await showTemplate(tester, opened.api);
    expect(find.text('تاريخ القالب'), findsOneWidget);
    expect(find.text('التاريخ'), findsNothing);

    await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.thisItemKey)));
    expect(find.text('التاريخ'), findsOneWidget);
  });

  group('AC-41.3: a change to the default template', () {
    testWidgets('adding asks, and Template only leaves existing items alone', (tester) async {
      final opened = await openColumns(tester);
      await showTemplate(tester, opened.api);

      await addColumn(tester, opened.api, 'رقم أمر الشراء');
      expect(find.byType(ApplyToAllDialog), findsOneWidget);
      expect(text(tester, ApplyToAllDialog.explainKey), 'en columns.applyExplain');
      expect(opened.api.sentStructureChanges, isEmpty);

      await act(tester, opened.api, () => tester.tap(find.byKey(ApplyToAllDialog.templateOnlyKey)));

      expect(opened.api.sentStructureChanges.single.$1, templatePath);
      expect(opened.api.sentStructureChanges.single.$2['applyToAllItems'], isFalse);
      expect(find.text('رقم أمر الشراء'), findsOneWidget);
    });

    testWidgets('adding with Apply to all items says so', (tester) async {
      final opened = await openColumns(tester);
      await showTemplate(tester, opened.api);

      await addColumn(tester, opened.api, 'رقم أمر الشراء');
      await act(tester, opened.api, () => tester.tap(find.byKey(ApplyToAllDialog.applyKey)));

      expect(opened.api.sentStructureChanges.single.$2['applyToAllItems'], isTrue);
    });

    testWidgets('changing a column asks', (tester) async {
      final opened = await openColumns(tester);
      await showTemplate(tester, opened.api);

      await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.editKey(templateColumn(opened.api, 0)))));
      await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.saveKey)));
      await act(tester, opened.api, () => tester.tap(find.byKey(ApplyToAllDialog.applyKey)));

      expect(opened.api.sentStructureChanges.single.$1, '$templatePath/${templateColumn(opened.api, 0)}');
      expect(opened.api.sentStructureChanges.single.$2['applyToAllItems'], isTrue);
    });

    testWidgets('deleting a column asks', (tester) async {
      final opened = await openColumns(tester);
      await showTemplate(tester, opened.api);
      final unit = templateColumn(opened.api, 1);

      await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.deleteKey(unit))));
      await act(tester, opened.api, () => tester.tap(find.byKey(ItemColumnsScreen.confirmDeleteKey)));
      await act(tester, opened.api, () => tester.tap(find.byKey(ApplyToAllDialog.templateOnlyKey)));

      expect(opened.api.sentStructureChanges.single.$1, '$templatePath/$unit/delete');
      expect(opened.api.sentStructureChanges.single.$2['applyToAllItems'], isFalse);
    });

    testWidgets('dragging a column asks', (tester) async {
      final opened = await openColumns(tester);
      await showTemplate(tester, opened.api);
      final date = templateColumn(opened.api, 0);

      await drag(tester, opened.api, ItemColumnsScreen.handleKey(date), 300);
      expect(opened.api.sentStructureChanges, isEmpty);
      await act(tester, opened.api, () => tester.tap(find.byKey(ApplyToAllDialog.applyKey)));

      expect(opened.api.sentStructureChanges.single.$1, '$templatePath/reorder');
      expect(opened.api.sentStructureChanges.single.$2['applyToAllItems'], isTrue);
    });
  });

  testWidgets('a list that cannot be read offers to try again', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    api.addItem(api.addCategory('project-0', 'التشطيب'), 'البلاط');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.categoriesKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.categoriesKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.categoryTileKey('category-0'))));
    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.itemColumnsKey('item-1'))));

    expect(text(tester, ItemColumnsScreen.messageKey), 'en columns.loadFailed');
  });

  testWidgets('a finished project shows its columns with nothing to change', (tester) async {
    final opened = await openColumns(tester, status: 'finished');

    expect(text(tester, ItemColumnsScreen.nameKey(opened.date)), 'التاريخ');
    expect(find.byKey(ItemColumnsScreen.lockKey(opened.date)), findsOneWidget);
    expect(find.byKey(ItemColumnsScreen.addKey), findsNothing);
    expect(find.byKey(ItemColumnsScreen.hintKey), findsNothing);
    expect(find.byKey(ItemColumnsScreen.handleKey(opened.date)), findsNothing);
    expect(find.byKey(ItemColumnsScreen.editKey(opened.date)), findsNothing);
    expect(find.byKey(ItemColumnsScreen.deleteKey(opened.unit)), findsNothing);
  });
}
