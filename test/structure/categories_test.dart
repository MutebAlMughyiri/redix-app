import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/category.dart';
import 'package:redix/structure/subgroups_screen.dart';
import 'package:redix/ui/api_list_body.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A project with العظم (الحفر, الحديد) and التشطيب, opened as far as its categories.
  Future<({FakeApi api, String bone, String finishing, String digging, String steel})> openCategories(WidgetTester tester, {String status = 'running', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, permissions: permissions);
    final bone = api.addCategory('project-0', 'العظم');
    final finishing = api.addCategory('project-0', 'التشطيب');
    final digging = api.addItem(bone, 'الحفر');
    final steel = api.addItem(bone, 'الحديد', type: 'purchases');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.categoriesKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.categoriesKey('project-0'))));
    return (api: api, bone: bone['id'] as String, finishing: finishing['id'] as String, digging: digging['id'] as String, steel: steel['id'] as String);
  }

  Future<void> open(WidgetTester tester, FakeApi api, String categoryId) => act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.categoryTileKey(categoryId))));

  Future<void> save(WidgetTester tester, FakeApi api, String name) => act(tester, api, () async {
    await tester.enterText(find.byKey(CategoriesScreen.nameKey), name);
    await tester.tap(find.byKey(CategoriesScreen.saveKey));
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
    expect(find.byKey(CategoriesScreen.saveKey), findsNothing);
  });

  testWidgets('a refused name stays in the dialog with why', (tester) async {
    final opened = await openCategories(tester);
    opened.api.structureAnswer = (status: 400, code: 'invalidName');

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.addCategoryKey)));
    await save(tester, opened.api, ' ');

    expect(text(tester, CategoriesScreen.dialogMessageKey), 'en categories.invalidName');
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

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.renameCategoryKey(opened.bone))));
    expect(tester.widget<TextField>(find.byKey(CategoriesScreen.nameKey)).controller!.text, 'العظم');
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
    expect(find.byKey(ApiListBody.retryKey), findsOneWidget);
    opened.api.online = true;
    await act(tester, opened.api, () => tester.tap(find.byKey(ApiListBody.retryKey)));
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

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.disableCategoryKey(opened.bone))));
    expect(text(tester, CategoriesScreen.categoryDetailsKey(opened.bone)), 'en categories.disabled');
    expect(find.byKey(CategoriesScreen.disableCategoryKey(opened.bone)), findsNothing);

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.enableCategoryKey(opened.bone))));
    expect(text(tester, CategoriesScreen.categoryDetailsKey(opened.bone)), 'en categories.items: 2');
  });

  testWidgets('a refused disable shows why', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);
    opened.api.structureAnswer = (status: 409, code: 'projectFinished');

    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.disableCategoryKey(opened.bone))));

    expect(find.text('en categories.projectFinished'), findsOneWidget);
    expect(text(tester, CategoriesScreen.categoryDetailsKey(opened.bone)), 'en categories.items: 2');
  });

  testWidgets('subgroups: the general one is not shown; one is added and renamed', (tester) async {
    final opened = await openCategories(tester);
    await open(tester, opened.api, opened.bone);
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(opened.digging))));
    await act(tester, opened.api, () => tester.tap(find.byKey(CategoriesScreen.subgroupsKey)));
    expect(text(tester, SubgroupsScreen.emptyKey), 'en categories.noSubgroups');

    await act(tester, opened.api, () => tester.tap(find.byKey(SubgroupsScreen.addKey)));
    await save(tester, opened.api, 'مواد');
    expect(opened.api.sentStructureChanges.single.$1, '/projects/project-0/items/${opened.digging}/subgroups');
    expect(opened.api.sentStructureChanges.single.$2, {'name': 'مواد'});
    expect(find.text('مواد'), findsOneWidget);
    expect(find.byKey(SubgroupsScreen.emptyKey), findsNothing);

    final added = find.byWidgetPredicate((widget) => widget is IconButton && widget.key.toString().contains('subgroups.rename.'));
    await act(tester, opened.api, () => tester.tap(added));
    await save(tester, opened.api, 'دفان');
    expect(find.text('دفان'), findsOneWidget);
    expect(find.text('مواد'), findsNothing);
  });

  testWidgets('a list that cannot be read offers to try again', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.categoriesKey('project-0')));
    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.categoriesKey('project-0'))));

    expect(text(tester, CategoriesScreen.messageKey), 'en categories.loadFailed');
  });

  testWidgets('a project with no categories says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.categoriesKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.categoriesKey('project-0'))));

    expect(text(tester, CategoriesScreen.emptyKey), 'en categories.empty');
  });

  testWidgets('a finished project shows its structure with nothing to change', (tester) async {
    final opened = await openCategories(tester, status: 'finished');
    await open(tester, opened.api, opened.bone);

    expect(text(tester, CategoriesScreen.itemNameKey(opened.digging)), 'الحفر');
    expect(find.byKey(CategoriesScreen.addCategoryKey), findsNothing);
    expect(find.byKey(CategoriesScreen.hintKey), findsNothing);
    expect(find.byKey(CategoriesScreen.categoryHandleKey(opened.bone)), findsNothing);
    expect(find.byKey(CategoriesScreen.addItemKey(opened.bone)), findsNothing);
    expect(find.byKey(CategoriesScreen.itemHandleKey(opened.digging)), findsNothing);
    expect(find.byKey(CategoriesScreen.itemMenuKey(opened.digging)), findsNothing);
  });

  testWidgets('without the permission there is no way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject']);
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));

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
