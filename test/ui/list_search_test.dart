import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/contracts/contract.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/search_line.dart';
import 'package:redix/ui/search_scope.dart';
import 'package:redix/ui/app_color.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

/// redix-app #104: a search line on every list that grows, shown from the title bar's search icon, and its filters from the filter icon beside it (version 3).
void main() {
  IconData filterIcon(WidgetTester tester) => tester.widget<Icon>(find.byKey(SearchIcons.filtersKey.icon)).icon!;

  /// Signs in, opens Suppliers holding مؤسسة الأفق and شركة النخيل, and answers the API and their ids.
  Future<(FakeApi, String, String)> onSuppliers(WidgetTester tester) async {
    final api = FakeApi()..addProject('غصون 6');
    final horizon = api.addSupplier('project-0', 'مؤسسة الأفق', vatNumber: '300000000000003')['id']! as String;
    final palm = api.addSupplier('project-0', 'شركة النخيل', vatNumber: '311111111111113')['id']! as String;
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.suppliersKey('project-0'));
    return (api, horizon, palm);
  }

  testWidgets('R2: a screen with search opens on its rows, with no search line', (tester) async {
    final (_, horizon, _) = await onSuppliers(tester);

    expect(find.byKey(SearchLine.searchKey), findsNothing);
    expect(find.byKey(SearchIcons.searchKey), findsOneWidget);
    expect(find.byKey(SuppliersScreen.rowKey(horizon)), findsOneWidget);
  });

  testWidgets('R1, R3: the search icon shows the line ready to type, and its ✕ closes it and shows every row again', (tester) async {
    final (api, horizon, palm) = await onSuppliers(tester);
    await act(tester, api, () => tester.tap(find.byKey(SearchIcons.searchKey)));

    expect(find.byKey(SearchLine.searchKey), findsOneWidget);
    expect(tester.widget<SearchBar>(find.byKey(SearchLine.searchKey)).autoFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue, reason: 'the line holds the keyboard, ready to type');
    await searchFor(tester, api, 'الافق');
    expect(find.byKey(SuppliersScreen.rowKey(palm)), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(SearchLine.closeKey)));
    expect(find.byKey(SearchLine.searchKey), findsNothing);
    expect(find.byKey(SuppliersScreen.rowKey(horizon)), findsOneWidget);
    expect(find.byKey(SuppliersScreen.rowKey(palm)), findsOneWidget);
  });

  testWidgets('R4: the search icon tapped again hides the line and clears it, and leaving the screen clears it too', (tester) async {
    final (api, horizon, palm) = await onSuppliers(tester);
    await searchFor(tester, api, 'الافق');
    expect(find.byKey(SuppliersScreen.rowKey(palm)), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(SearchIcons.searchKey)));
    expect(find.byKey(SearchLine.searchKey), findsNothing);
    expect(find.byKey(SuppliersScreen.rowKey(palm)), findsOneWidget);

    await searchFor(tester, api, 'الافق');
    await act(tester, api, () => tester.pageBack());
    await scrollAndTap(tester, api, HomeScreen.suppliersKey('project-0'));
    expect(find.byKey(SearchLine.searchKey), findsNothing);
    expect(find.byKey(SuppliersScreen.rowKey(horizon)), findsOneWidget);
    expect(find.byKey(SuppliersScreen.rowKey(palm)), findsOneWidget);
  });

  testWidgets('R7: a search line with no SearchScope over its screen says so rather than showing nothing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SearchLine(hint: 'search'))));

    expect(tester.takeException(), isA<FlutterError>());
  });

  testWidgets('findings row 210: Suppliers, searched on the phone, answers a letter at once, with no pause', (tester) async {
    final (api, horizon, palm) = await onSuppliers(tester);
    await act(tester, api, () => tester.tap(find.byKey(SearchIcons.searchKey)));

    await tester.enterText(find.byKey(SearchLine.searchKey), 'الافق');
    await tester.pump();

    expect(find.byKey(SuppliersScreen.rowKey(horizon)), findsOneWidget);
    expect(find.byKey(SuppliersScreen.rowKey(palm)), findsNothing);
  });

  testWidgets('Suppliers: typing keeps the suppliers holding it, whichever way an Arabic name is spelled, by name or VAT number; cleared, every one', (tester) async {
    final (api, horizon, palm) = await onSuppliers(tester);

    expect(find.byKey(SearchIcons.filtersKey), findsNothing);
    await searchFor(tester, api, 'الافق');
    expect(find.byKey(SuppliersScreen.rowKey(horizon)), findsOneWidget);
    expect(find.byKey(SuppliersScreen.rowKey(palm)), findsNothing);

    await searchFor(tester, api, '٣١١١');
    expect(find.byKey(SuppliersScreen.rowKey(horizon)), findsNothing);
    expect(find.byKey(SuppliersScreen.rowKey(palm)), findsOneWidget);

    await searchFor(tester, api, '');
    expect(find.byKey(SuppliersScreen.rowKey(horizon)), findsOneWidget);
    expect(find.byKey(SuppliersScreen.rowKey(palm)), findsOneWidget);
  });

  testWidgets('D8, R6: on Contracts the filter icon opens the filters and folds them, without the search line; folded with a filter in use it is filled, with none outlined', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    api
      ..addContract('project-0', 'مبلط الغربية', value: 34000, paid: 30000)
      ..addContract('project-0', 'مبلط الجنوبية', value: 34000, paid: 35000);
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.contractsKey('project-0'));

    expect(filterIcon(tester), Icons.filter_alt_outlined);
    expect(find.byKey(ContractsScreen.filterKey(ContractFilter.overrun)), findsNothing);

    await openFilters(tester, api);
    expect(find.byKey(ContractsScreen.filterKey(ContractFilter.overrun)), findsOneWidget);
    expect(find.byKey(SearchLine.searchKey), findsNothing);
    await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.filterKey(ContractFilter.overrun))));
    await foldFilters(tester, api);
    expect(find.byKey(ContractsScreen.filterKey(ContractFilter.overrun)), findsNothing);
    expect(filterIcon(tester), Icons.filter_alt);

    await openFilters(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.filterKey(ContractFilter.all))));
    await foldFilters(tester, api);
    expect(filterIcon(tester), Icons.filter_alt_outlined);
  });

  testWidgets('Categories: while a search holds text every drag handle stays in place, grayed, and drags nothing; cleared, they drag again', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    final finishing = api.addCategory('project-0', 'التشطيب');
    final bone = api.addCategory('project-0', 'العظم')['id']! as String;
    api.addItem(finishing, 'البلاط');
    final finishingId = finishing['id']! as String;
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.categoriesKey('project-0'));
    final handle = find.byKey(CategoriesScreen.categoryHandleKey(finishingId));
    bool drags() => tester.widget<ReorderableDragStartListener>(find.byKey(CategoriesScreen.categoryHandleKey(finishingId).body)).enabled;

    expect(drags(), isTrue);

    await searchFor(tester, api, 'البلاط');
    expect(handle, findsOneWidget);
    expect(drags(), isFalse);
    expect(tester.widget<Icon>(find.byKey(CategoriesScreen.categoryHandleKey(finishingId).icon)).color, AppColor.quiet.of(tester.element(handle)));
    expect(find.byKey(CategoriesScreen.cardKey(bone)), findsNothing);

    await searchFor(tester, api, '');
    expect(drags(), isTrue);
    expect(find.byKey(CategoriesScreen.cardKey(bone)), findsOneWidget);
  });
}
