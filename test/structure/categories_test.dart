import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/category.dart';
import 'package:redix/structure/item_tables_screen.dart';

import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/name_dialog.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A project with العظم (الحفر, الحديد) and التشطيب, opened as far as its categories.
  Future<({FakeApi api, String bone, String finishing, String digging, String steel})> openCategories(WidgetTester tester, {String status = 'active', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, permissions: permissions);
    final bone = api.addCategory('project-0', 'العظم');
    final finishing = api.addCategory('project-0', 'التشطيب');
    final digging = api.addItem(bone, 'الحفر');
    final steel = api.addItem(bone, 'الحديد', type: 'purchases');
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.categoriesKey('project-0'));
    return (api: api, bone: bone['id'] as String, finishing: finishing['id'] as String, digging: digging['id'] as String, steel: steel['id'] as String);
  }

  Future<void> open(WidgetTester tester, FakeApi api, String categoryId) => act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.categoryTileKey(categoryId))));

  Future<void> save(WidgetTester tester, FakeApi api, String name) => act(tester, api, () async {
    await tester.enterText(find.byKey(NameDialog.nameKey), name);
    await tester.tap(find.byKey(ChangeDialog.saveKey));
  });

  Future<void> drag(WidgetTester tester, FakeApi api, Key handle, double by) => act(tester, api, () async {
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(handle)));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(Offset(0, by));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
  });

  testWidgets('categories show in order with how many items each holds', (tester) async {
    final opened = await openCategories(tester);

    expect(text(tester, CategoriesScreen.categoryNameKey(opened.bone)), 'العظم');
    expect(text(tester, CategoriesScreen.categoryDetailsKey(opened.bone)), 'en categories.items: 2');
    expect(tester.getTopLeft(find.byKey(CategoriesScreen.cardKey(opened.bone))).dy, lessThan(tester.getTopLeft(find.byKey(CategoriesScreen.cardKey(opened.finishing))).dy));
  });

  testWidgets('a category opens to its items, each with its type', (tester) async {
    final opened = await openCategories(tester);

    await open(tester, opened.api, opened.bone);

    expect(text(tester, CategoriesScreen.itemNameKey(opened.digging)), 'الحفر');
    expect(text(tester, CategoriesScreen.itemDetailsKey(opened.digging)), 'en categories.typeBoth');
    expect(text(tester, CategoriesScreen.itemDetailsKey(opened.steel)), 'en categories.typePurchases');
  });

  testWidgets('a category with no items says so', (tester) async {
    final opened = await openCategories(tester);

    await open(tester, opened.api, opened.finishing);

    expect(text(tester, CategoriesScreen.noItemsKey(opened.finishing)), 'en categories.noItems');
  });

  testWidgets('a new category joins the list', (tester) async {
    final opened = await openCategories(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.addCategoryKey)));
    await save(tester, opened.api, 'الملاحق');

    expect(opened.api.sentStructureChanges.single.$1, '/projects/project-0/categories');
    expect(opened.api.sentStructureChanges.single.$2, {'name': 'الملاحق'});
    expect(find.text('الملاحق'), findsOneWidget);
    expect(find.byKey(ChangeDialog.saveKey), findsNothing);
  });

  testWidgets('a refused name stays in the dialog with why', (tester) async {
    final opened = await openCategories(tester);
    opened.api.structureAnswer = (status: 400, code: 'invalidName');

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.addCategoryKey)));
    await save(tester, opened.api, ' ');

    expect(text(tester, ChangeDialog.messageKey), 'en categories.invalidName');
  });

  testWidgets('a new item is sent with the type chosen, both unless changed', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.addItemKey(opened.bone))));
    await save(tester, opened.api, 'بند الدرج');
    expect(opened.api.sentStructureChanges.last.$2, {'name': 'بند الدرج', 'type': 'both'});

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.addItemKey(opened.bone))));
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemTypeKey(ItemType.contractorPayments))));
    await save(tester, opened.api, 'دفعات العظم');

    expect(opened.api.sentStructureChanges.last.$1, '/projects/project-0/categories/${opened.bone}/items');
    expect(opened.api.sentStructureChanges.last.$2, {'name': 'دفعات العظم', 'type': 'contractorPayments'});
    expect(find.text('دفعات العظم'), findsOneWidget);
  });

  testWidgets('a category and an item are renamed, starting from their names', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.categoryMenuKey(opened.bone))));
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.renameCategoryKey(opened.bone))));
    expect(tester.widget<TextField>(find.byKey(NameDialog.nameKey)).controller!.text, 'العظم');
    await save(tester, opened.api, 'الهيكل');
    expect(text(tester, CategoriesScreen.categoryNameKey(opened.bone)), 'الهيكل');

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(opened.digging))));
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.renameItemKey)));
    await save(tester, opened.api, 'بند الحفر');
    expect(text(tester, CategoriesScreen.itemNameKey(opened.digging)), 'بند الحفر');
    expect(opened.api.sentStructureChanges.last.$1, '/projects/project-0/items/${opened.digging}');
  });

  testWidgets('AC-39.1: dragging a category sends the new order and it stays', (tester) async {
    final opened = await openCategories(tester);

    await drag(tester, opened.api, CategoriesScreen.categoryHandleKey(opened.bone), 200);

    expect(opened.api.sentStructureChanges.single.$1, '/projects/project-0/categories/reorder');
    expect(opened.api.sentStructureChanges.single.$2, {'ids': [opened.finishing, opened.bone]});
    expect(tester.getTopLeft(find.byKey(CategoriesScreen.cardKey(opened.finishing))).dy, lessThan(tester.getTopLeft(find.byKey(CategoriesScreen.cardKey(opened.bone))).dy));
  });

  testWidgets('dragging an item sends the new order of its category', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);

    await drag(tester, opened.api, CategoriesScreen.itemHandleKey(opened.digging), 160);

    expect(opened.api.sentStructureChanges.single.$1, '/projects/project-0/categories/${opened.bone}/items/reorder');
    expect(opened.api.sentStructureChanges.single.$2, {'ids': [opened.steel, opened.digging]});
    expect(tester.getTopLeft(find.byKey(CategoriesScreen.itemKey(opened.steel))).dy, lessThan(tester.getTopLeft(find.byKey(CategoriesScreen.itemKey(opened.digging))).dy));
  });

  testWidgets('a refused order goes back to what the API holds, and says why', (tester) async {
    final opened = await openCategories(tester);
    opened.api.structureAnswer = (status: 400, code: 'invalidOrder');

    await drag(tester, opened.api, CategoriesScreen.categoryHandleKey(opened.bone), 200);

    expect(find.text('en categories.invalidOrder'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(CategoriesScreen.cardKey(opened.bone))).dy, lessThan(tester.getTopLeft(find.byKey(CategoriesScreen.cardKey(opened.finishing))).dy));
  });

  testWidgets('an order lost with the network goes back too', (tester) async {
    final opened = await openCategories(tester);
    opened.api.online = false;

    await drag(tester, opened.api, CategoriesScreen.categoryHandleKey(opened.bone), 200);

    expect(find.text('en categories.noConnection'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(CategoriesScreen.cardKey(opened.bone))).dy, lessThan(tester.getTopLeft(find.byKey(CategoriesScreen.cardKey(opened.finishing))).dy));
  });

  testWidgets('AC-05.3: an item is disabled and enabled, never deleted', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(opened.steel))));
    expect(find.byKey(CategoriesScreen.enableItemKey), findsNothing);
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.disableItemKey)));
    expect(opened.api.sentStructureChanges.single.$1, '/projects/project-0/items/${opened.steel}/disable');
    expect(text(tester, CategoriesScreen.itemDetailsKey(opened.steel)), 'en categories.disabled');

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(opened.steel))));
    expect(find.byKey(CategoriesScreen.disableItemKey), findsNothing);
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.enableItemKey)));
    expect(text(tester, CategoriesScreen.itemDetailsKey(opened.steel)), 'en categories.typePurchases');
  });

  testWidgets('a category is disabled and enabled, and says so', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.categoryMenuKey(opened.bone))));
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.disableCategoryKey(opened.bone))));
    expect(text(tester, CategoriesScreen.categoryDetailsKey(opened.bone)), 'en categories.disabled');
    expect(find.byKey(CategoriesScreen.disableCategoryKey(opened.bone)), findsNothing);

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.categoryMenuKey(opened.bone))));
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.enableCategoryKey(opened.bone))));
    expect(text(tester, CategoriesScreen.categoryDetailsKey(opened.bone)), 'en categories.items: 2');
  });

  testWidgets('a refused disable shows why', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);
    opened.api.structureAnswer = (status: 409, code: 'projectFinished');

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.categoryMenuKey(opened.bone))));
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.disableCategoryKey(opened.bone))));

    expect(find.text('en categories.projectFinished'), findsOneWidget);
    expect(text(tester, CategoriesScreen.categoryDetailsKey(opened.bone)), 'en categories.items: 2');
  });

  /// A project whose item الحفر holds مواد and دفان and a contract with مقاول الحفر, opened as far as its tables.
  Future<({FakeApi api, String item, String general, List<String> ids})> openTables(WidgetTester tester, {String status = 'active'}) async {
    final api = FakeApi()..addProject('غصون 6', status: status);
    final bone = api.addCategory('project-0', 'العظم');
    final item = api.addItem(bone, 'الحفر', subgroups: ['مواد', 'دفان']);
    api.contractTables[item['id'] as String] = [
      {'id': 'contract-1', 'kind': 'contract', 'name': 'مقاول الحفر', 'count': 27},
    ];
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.categoriesKey('project-0'));
    await open(tester, api, bone['id'] as String);
    if (status == 'active') {
      await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(item['id'] as String))));
      await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.tablesKey)));
    }
    final subgroups = item['subgroups']! as List<Map<String, Object>>;
    return (api: api, item: item['id'] as String, general: subgroups[0]['id'] as String, ids: [for (final subgroup in subgroups.skip(1)) subgroup['id'] as String]);
  }

  testWidgets('AC-46.8: an item lists every table its sheet prints, its general one and its contract too, and only a named subgroup is renamed or removed', (tester) async {
    final opened = await openTables(tester);

    expect(text(tester, ItemTablesScreen.tableNameKey(opened.general)), 'الحفر');
    expect(text(tester, ItemTablesScreen.detailsKey(opened.general)), 'en categories.tablePurchases · 0');
    expect(text(tester, ItemTablesScreen.detailsKey('contract-1')), 'en categories.tableContract · 27');
    expect(find.byKey(ItemTablesScreen.menuKey(opened.general)), findsNothing);
    expect(find.byKey(ItemTablesScreen.rowKey('contract-1').swipe), findsNothing);
    expect(find.byKey(ItemTablesScreen.rowKey(opened.general).swipe), findsNothing);
    expect(find.byKey(ItemTablesScreen.rowKey(opened.ids[0]).swipe), findsOneWidget);
    expect(find.byKey(ItemTablesScreen.menuKey(opened.ids[0])), findsOneWidget);
  });

  testWidgets('a sub-table added here is offered in إضافة قيد as its table and sheet, and takes a purchase', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance);
    final bone = api.addCategory('project-0', 'تكلفة العظم');
    final item = api.addItem(bone, 'دفعات العظم');
    final method = api.addPaymentMethod('project-0', 'تحويل');
    api.addAccount('project-0', 'حساب المؤسسة', isMine: true);
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.categoriesKey('project-0'));
    await open(tester, api, bone['id'] as String);
    await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(item['id'] as String))));
    await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.tablesKey)));

    await act(tester, api, () => tester.tap(find.byKey(ItemTablesScreen.addKey)));
    await save(tester, api, 'الجلاي');
    final added = (item['subgroups']! as List<Map<String, Object>>).last['id']! as String;
    for (var back = 0; back < 2; back++) {
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
    }
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.tableKey)));
    await act(tester, api, () => tester.tap(find.byKey(TablePicker.optionKey(added))));

    expect(tester.widget<TablePicker>(find.byKey(AddEntryScreen.tableKey)).chosen.label, 'الجلاي (دفعات العظم)');
    await tester.ensureVisible(find.byKey(AddEntryScreen.amountKey));
    await tester.enterText(find.byKey(AddEntryScreen.amountKey), '500');
    await tester.ensureVisible(find.byKey(PaymentChoices.paymentMethodKey(method['id']! as String)));
    await act(tester, api, () => tester.tap(find.byKey(PaymentChoices.paymentMethodKey(method['id']! as String))));
    await tester.ensureVisible(find.byKey(AddEntryScreen.draftKey));
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.draftKey)));

    final sent = api.sentEntries.single;
    expect((sent['itemId'], sent['tableId'], sent['amount']), (item['id'], added, 500));
  });

  testWidgets('an item that takes no purchases offers no sub-table to add, since a sub-table holds purchases', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance);
    final bone = api.addCategory('project-0', 'تكلفة العظم');
    final item = api.addItem(bone, 'دفعات العظم', type: 'contractorPayments');
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.categoriesKey('project-0'));
    await open(tester, api, bone['id'] as String);
    await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(item['id'] as String))));
    await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.tablesKey)));

    expect(isEnabled(tester, ItemTablesScreen.addKey), isFalse);
  });

  testWidgets('a subgroup is added to the tables and renamed there', (tester) async {
    final opened = await openTables(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(ItemTablesScreen.addKey)));
    await save(tester, opened.api, 'أسمنت');
    expect(opened.api.sentStructureChanges.single.$1, '/projects/project-0/items/${opened.item}/subgroups');
    expect(opened.api.sentStructureChanges.single.$2, {'name': 'أسمنت'});
    expect(find.text('أسمنت'), findsOneWidget);

    await chooseFromMenu(tester, opened.api, ItemTablesScreen.menuKey(opened.ids[0]), ItemTablesScreen.renameKey);
    await save(tester, opened.api, 'مواد بناء');
    expect(find.text('مواد بناء'), findsOneWidget);
  });

  testWidgets('AC-46.8: dragging a table sends the order of every table, the general one and the contract too, and it stays', (tester) async {
    final opened = await openTables(tester);

    await drag(tester, opened.api, ItemTablesScreen.handleKey(opened.ids[0]), 170);

    final every = [opened.general, ...opened.ids, 'contract-1'];
    final sent = [for (final id in opened.api.sentStructureChanges.single.$2['ids'] as List<dynamic>) id as String];
    final shown = [...every]..sort((first, second) => tester.getTopLeft(find.byKey(ItemTablesScreen.rowKey(first))).dy.compareTo(tester.getTopLeft(find.byKey(ItemTablesScreen.rowKey(second))).dy));
    expect(opened.api.sentStructureChanges.single.$1, '/projects/project-0/items/${opened.item}/tables/reorder');
    expect(sent.toSet(), every.toSet());
    expect(sent, shown);
    expect(sent, isNot(every));
  });

  testWidgets('a refused order of tables goes back to what the API holds, and says why', (tester) async {
    final opened = await openTables(tester);
    opened.api.structureAnswer = (status: 400, code: 'invalidOrder');

    await drag(tester, opened.api, ItemTablesScreen.handleKey(opened.ids[0]), 170);

    expect(find.text('en categories.invalidOrder'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(ItemTablesScreen.tableNameKey(opened.ids[0]))).dy, lessThan(tester.getTopLeft(find.byKey(ItemTablesScreen.tableNameKey(opened.ids[1]))).dy));
  });

  testWidgets('redix-api #102: a named subgroup is removed by a swipe with no question', (tester) async {
    final opened = await openTables(tester);
    expect(find.byKey(ItemTablesScreen.rowKey(opened.ids[0]).bar), findsOneWidget);

    await swipeToRemove(tester, opened.api, ItemTablesScreen.rowKey(opened.ids[0]));

    expect(find.byType(AlertDialog), findsNothing);

    expect(opened.api.sentStructureChanges.single.$1, '/projects/project-0/items/${opened.item}/subgroups/${opened.ids[0]}/delete');
    expect(find.text('مواد'), findsNothing);
    expect(find.text('دفان'), findsOneWidget);
  });

  testWidgets('a subgroup that entries use stays, and the refusal says why', (tester) async {
    final opened = await openTables(tester);
    opened.api.structureAnswer = (status: 409, code: 'subgroupInUse');

    await swipeToRemove(tester, opened.api, ItemTablesScreen.rowKey(opened.ids[0]));

    expect(find.text('en categories.subgroupInUse'), findsOneWidget);
    expect(find.text('مواد'), findsOneWidget);
  });

  testWidgets('an item\'s type changes from its menu, starting from the one it has', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(opened.steel))));
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.changeTypeKey)));
    expect(tester.widget<RadioGroup<ItemType>>(find.byType(RadioGroup<ItemType>)).groupValue, ItemType.purchases);
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemTypeKey(ItemType.both))));
    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(opened.api.sentStructureChanges.single.$1, '/projects/project-0/items/${opened.steel}/type');
    expect(opened.api.sentStructureChanges.single.$2, {'type': 'both'});
    expect(text(tester, CategoriesScreen.itemDetailsKey(opened.steel)), 'en categories.typeBoth');
  });

  testWidgets('AC-46.9: an item chooses from its menu whether its sheet calculates a percentage for each table, and the menu shows the choice', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(opened.steel))));
    expect(tester.widget<CheckedPopupMenuItem<VoidCallback>>(find.byKey(CategoriesScreen.tablePercentagesKey)).checked, isFalse);
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.tablePercentagesKey)));

    expect(opened.api.sentStructureChanges.single.$1, '/projects/project-0/items/${opened.steel}/table-percentages');
    expect(opened.api.sentStructureChanges.single.$2, {'isOn': true});
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(opened.steel))));
    expect(tester.widget<CheckedPopupMenuItem<VoidCallback>>(find.byKey(CategoriesScreen.tablePercentagesKey)).checked, isTrue);
  });

  testWidgets('FR-38: an item\'s side comes first, and revenue offers only revenue types', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(opened.steel))));
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.changeTypeKey)));
    expect(find.byKey(CategoriesScreen.itemTypeKey(ItemType.sale)), findsNothing);
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.sideKey(isRevenue: true))));
    expect(find.byKey(CategoriesScreen.itemTypeKey(ItemType.both)), findsNothing);
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemTypeKey(ItemType.vatRefund))));
    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(opened.api.sentStructureChanges.single.$2, {'type': 'vatRefund'});
    expect(text(tester, CategoriesScreen.itemDetailsKey(opened.steel)), 'en categories.typeVatRefund');
  });

  testWidgets('an item with entries keeps its type, and the dialog says why', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);
    opened.api.structureAnswer = (status: 409, code: 'itemHasEntries');

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(opened.steel))));
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.changeTypeKey)));
    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(text(tester, ChangeDialog.messageKey), 'en categories.itemHasEntries');
  });

  testWidgets('a list that cannot be read offers to try again', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);
    api.online = false;
    await scrollAndTap(tester, api, HomeScreen.categoriesKey('project-0'));

    expect(text(tester, ApiListBody.messageKey), 'en categories.loadFailed');
  });

  testWidgets('a project with no categories says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.categoriesKey('project-0'));

    expect(text(tester, ApiListBody.emptyKey), 'en categories.empty');
  });

  testWidgets('a finished project shows its structure with nothing to change', (tester) async {
    final opened = await openCategories(tester, status: 'finished');
    await open(tester, opened.api, opened.bone);

    expect(text(tester, CategoriesScreen.itemNameKey(opened.digging)), 'الحفر');
    expect(isEnabled(tester, CategoriesScreen.addCategoryKey), isFalse);
    expect(find.byKey(CategoriesScreen.hintKey), findsNothing);
    expect(find.byKey(CategoriesScreen.categoryHandleKey(opened.bone)), findsNothing);
    expect(find.byKey(CategoriesScreen.addItemKey(opened.bone)), findsNothing);
    expect(find.byKey(CategoriesScreen.itemHandleKey(opened.digging)), findsNothing);
    expect(find.byKey(CategoriesScreen.itemMenuKey(opened.digging)), findsNothing);
  });

  testWidgets('without the permission there is no way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject']);
    await openProject(tester, api);

    await showProjectSetting(tester, HomeScreen.categoriesKey('project-0'));
    expect(find.byKey(HomeScreen.categoriesKey('project-0')), findsNothing);
  });

  group('a new project', () {
    Future<void> openNewProject(WidgetTester tester, FakeApi api) async {
      await pumpRedix(tester, api, stored: {'session': keptSession});
      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.newProjectKey)));
    }

    Future<void> submit(WidgetTester tester, FakeApi api) => act(tester, api, () async {
      await tester.enterText(find.byKey(NewProjectScreen.nameKey), 'غصون 7');
      await tester.ensureVisible(find.byKey(NewProjectScreen.submitKey));
      await tester.tap(find.byKey(NewProjectScreen.submitKey));
    });

    testWidgets('copies from the default template unless told otherwise', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openNewProject(tester, api);

      await submit(tester, api);

      expect(api.sentProjectChanges.single.$2.containsKey('structureSourceId'), isFalse);
    });

    testWidgets('AC-05.2: can copy from an approved earlier project, and offers no other', (tester) async {
      final api = FakeApi()
        ..addProject('غصون 6')
        ..addProject('غصون 5', status: 'finished')
        ..addProject('غصون 9', status: 'pendingApproval');
      await openNewProject(tester, api);

      await tester.ensureVisible(find.byKey(NewProjectScreen.structureSourceKey));
      await act(tester, api, () => tester.tap(find.byKey(NewProjectScreen.structureSourceKey)));
      expect(find.text('en projects.defaultTemplate'), findsWidgets);
      expect(find.text('غصون 9'), findsNothing);
      await act(tester, api, () => tester.tap(find.text('غصون 5').last));
      await submit(tester, api);

      expect(api.sentProjectChanges.single.$2['structureSourceId'], 'project-1');
    });

    testWidgets('says when the earlier project cannot be copied', (tester) async {
      final api = FakeApi()
        ..addProject('غصون 6')
        ..projectAnswer = (status: 400, code: 'unknownSource');
      await openNewProject(tester, api);

      await submit(tester, api);

      expect(text(tester, NewProjectScreen.messageKey), 'en projects.unknownSource');
    });

    testWidgets('the sign-in page offers no earlier project', (tester) async {
      await pumpRedix(tester, FakeApi());
      final api = FakeApi();
      await act(tester, api, () async {
        await tester.ensureVisible(find.byKey(SignInScreen.registerKey));
        await tester.tap(find.byKey(SignInScreen.registerKey));
      });

      expect(find.byKey(NewProjectScreen.structureSourceKey), findsNothing);
    });
  });
}
