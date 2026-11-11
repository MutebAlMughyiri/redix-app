import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/contracts/contract.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/app_color.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

/// redix-app #104 step 1: a search line on every list that grows, its filters folded under the line's arrow.
void main() {
  IconData arrow(WidgetTester tester) => tester.widget<Icon>(find.byKey(ApiListBody.filtersKey.icon)).icon!;

  testWidgets('Suppliers: typing keeps the suppliers holding it, whichever way an Arabic name is spelled, by name or VAT number; cleared, every one', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    final horizon = api.addSupplier('project-0', 'مؤسسة الأفق', vatNumber: '300000000000003')['id']! as String;
    final palm = api.addSupplier('project-0', 'شركة النخيل', vatNumber: '311111111111113')['id']! as String;
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.suppliersKey('project-0'));

    expect(find.byKey(ApiListBody.filtersKey), findsNothing);
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

  testWidgets('Contracts: the arrow opens the filters and folds them; folded with a filter in use it is a filled filter, folded with none it points down', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    api
      ..addContract('project-0', 'مبلط الغربية', value: 34000, paid: 30000)
      ..addContract('project-0', 'مبلط الجنوبية', value: 34000, paid: 35000);
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.contractsKey('project-0'));

    expect(arrow(tester), Icons.arrow_drop_down);
    expect(find.byKey(ContractsScreen.filterKey(ContractFilter.overrun)), findsNothing);

    await openFilters(tester, api);
    expect(arrow(tester), Icons.arrow_drop_up);
    await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.filterKey(ContractFilter.overrun))));
    await foldFilters(tester, api);
    expect(find.byKey(ContractsScreen.filterKey(ContractFilter.overrun)), findsNothing);
    expect(arrow(tester), Icons.filter_alt);

    await openFilters(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.filterKey(ContractFilter.all))));
    await foldFilters(tester, api);
    expect(arrow(tester), Icons.arrow_drop_down);
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
    bool drags() => tester.widget<ReorderableDragStartListener>(find.descendant(of: handle, matching: find.byType(ReorderableDragStartListener))).enabled;

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
