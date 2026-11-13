import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/summary.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/reports/item_report_screen.dart';
import 'package:redix/reports/item_reports_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

/// redix-app #108: rows one under another alternate their ground, an odd row taking the scheme's next tone.
void main() {
  Color? cardGround(WidgetTester tester, Key cardKey) => tester.widget<Material>(find.descendant(of: find.byKey(cardKey), matching: find.byType(Material)).first).color;

  Color? tileGround(WidgetTester tester, Key tileKey) => Theme.of(tester.element(find.byKey(tileKey))).listTileTheme.tileColor;

  ColorScheme schemeAt(WidgetTester tester, Key key) => Theme.of(tester.element(find.byKey(key))).colorScheme;

  /// The home of a project, drawn light or dark as [brightness] says, after [arrange] filled the API.
  Future<FakeApi> openHome(WidgetTester tester, Brightness brightness, void Function(FakeApi api) arrange) async {
    final api = FakeApi()..addProject('غصون 6');
    arrange(api);
    await pumpRedix(tester, api, stored: {'session': keptSession}, preferences: {'themeMode_state': brightness == Brightness.dark ? 1 : 0});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    return api;
  }

  for (final brightness in Brightness.values) {
    testWidgets('R1, R2, R6: in ${brightness.name}, the home\'s 2nd entry takes the scheme\'s next tone, the 1st and 3rd keep the ground, and every frame stays', (tester) async {
      await openHome(tester, brightness, (api) {
        for (var entry = 0; entry < 3; entry++) {
          api.addEntry();
        }
      });
      final scheme = schemeAt(tester, HomeScreen.searchEntriesKey('project-0'));
      final (first, second, third) = (EntriesScreen.rowKey('entry-2').card, EntriesScreen.rowKey('entry-1').card, EntriesScreen.rowKey('entry-0').card);

      expect(cardGround(tester, second), scheme.surfaceContainerLow);
      expect(cardGround(tester, first), cardGround(tester, third));
      expect(cardGround(tester, first), isNot(cardGround(tester, second)));
      expect(frameOf(tester, 'entry-1'), frameOf(tester, 'entry-0'));
    });
  }

  /// الإيرادات والمصروفات, drawn as [brightness] says, with the category الأرض opened on its three items.
  Future<FakeApi> openLandCategory(WidgetTester tester, Brightness brightness) async {
    final api = await openHome(tester, brightness, (api) => api.summaryAnswer = {
      'revenue': 0,
      'expenses': 4000,
      'surplus': -4000,
      'wasReconciled': false,
      'reconciliationDifference': 0,
      'waiting': waiting(),
      'completionPercent': 0,
      'categories': [
        {
          'id': 'category-1',
          'name': 'الأرض',
          'total': 4000,
          'items': [
            {'id': 'item-1', 'name': 'تكلفة الأرض', 'total': 3000},
            {'id': 'item-2', 'name': 'رسوم السعي', 'total': 600},
            {'id': 'item-3', 'name': 'رسوم كتابة العدل', 'total': 400},
          ],
        },
      ],
      'revenueCategories': const <Object>[],
    });
    await scrollAndTap(tester, api, HomeScreen.itemReportsKey('project-0', SummarySide.expenses));
    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.categoryKey('category-1'))));
    return api;
  }

  testWidgets('R3, D3: on الإيرادات والمصروفات the items of an opened category alternate, and the category keeps its ground', (tester) async {
    await openLandCategory(tester, Brightness.light);
    final scheme = schemeAt(tester, ItemReportsScreen.itemKey('item-1'));

    expect(tileGround(tester, ItemReportsScreen.itemKey('item-1')), isNull);
    expect(tileGround(tester, ItemReportsScreen.itemKey('item-2')), scheme.surfaceContainerLow);
    expect(tileGround(tester, ItemReportsScreen.itemKey('item-3')), isNull);
    expect(tileGround(tester, ItemReportsScreen.categoryKey('category-1')), isNull);
  });

  testWidgets('R3: an item\'s lines alternate inside their card, counted from the card\'s first, and the card keeps its ground', (tester) async {
    Map<String, Object> line(String id) => {
      'entryId': id,
      'date': '2026-11-02',
      'amount': 1000,
      'isOutsideContract': false,
      'values': ['دفعة للأرض'],
    };
    final api = await openLandCategory(tester, Brightness.dark);
    api.itemReportAnswer = {
      'itemName': 'تكلفة الأرض',
      'categoryName': 'الأرض',
      'total': 3000,
      'subgroups': [
        {'id': 'subgroup-1', 'name': '', 'total': 3000, 'columns': [{'key': 'description', 'name': 'الوصف', 'dataType': 'text'}], 'rows': [line('entry-a'), line('entry-b'), line('entry-c')]},
      ],
      'contracts': const <Object>[],
    };

    await act(tester, api, () => tester.tap(find.byKey(ItemReportsScreen.itemKey('item-1'))));
    final scheme = schemeAt(tester, ItemReportScreen.rowKey('entry-a'));

    expect(tileGround(tester, ItemReportScreen.rowKey('entry-a')), isNull);
    expect(tileGround(tester, ItemReportScreen.rowKey('entry-b')), scheme.surfaceContainerLow);
    expect(tileGround(tester, ItemReportScreen.rowKey('entry-c')), isNull);
    expect(cardGround(tester, ItemReportScreen.subgroupKey('subgroup-1')), isNot(scheme.surfaceContainerLow));
  });
}
