import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';

import '../app_harness.dart';

/// Muteb, 11 Nov 2026: the home's Project settings come four to a page, two by two, swiped sideways with dots under them; the first page holds the four used most.
/// Nothing is kept: the card opens on its first page.
void main() {
  const project = 'project-0';
  final first = [HomeScreen.contractsKey(project), HomeScreen.reportsKey(project), HomeScreen.itemReportsKey(project), HomeScreen.suppliersKey(project)];
  final second = [HomeScreen.accountsKey(project), HomeScreen.partnersKey(project), HomeScreen.vatKey(project), HomeScreen.approvalsKey(project)];
  final third = [HomeScreen.documentsKey(project), HomeScreen.projectInfoKey(project), HomeScreen.myPermissionsKey(project), HomeScreen.usersKey(project)];
  final fourth = [HomeScreen.categoriesKey(project), HomeScreen.paymentMethodsKey(project), HomeScreen.importSettingsKey(project)];

  /// The app started and the home of a project opened, in [locale], seen with [permissions].
  Future<FakeApi> openHome(WidgetTester tester, {List<String> permissions = managerAndFinance, Locale locale = const Locale('en')}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions);
    await pumpRedix(tester, api, locale: locale, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey(project))));
    return api;
  }

  void expectPage(List<Key> shown, List<List<Key>> others) {
    for (final key in shown) {
      expect(find.byKey(key), findsOneWidget, reason: '$key');
    }
    for (final key in others.expand((page) => page)) {
      expect(find.byKey(key), findsNothing, reason: '$key');
    }
  }

  /// Which dot is the wide one, the page shown.
  int pageShown(WidgetTester tester, int pages) =>
      [for (var index = 0; index < pages; index++) tester.getSize(find.byKey(HomeScreen.settingsDotKey(project, index))).width].indexed.reduce((wide, dot) => dot.$2 > wide.$2 ? dot : wide).$1;

  testWidgets('the card opens on its first page: the four used most, two by two, with a dot per page and the first one wide', (tester) async {
    await openHome(tester);

    expectPage(first, [second, third, fourth]);
    expect(tester.getTopLeft(find.byKey(first[0])).dy, tester.getTopLeft(find.byKey(first[1])).dy);
    expect(tester.getTopLeft(find.byKey(first[2])).dy, greaterThan(tester.getTopLeft(find.byKey(first[0])).dy));
    expect(find.byKey(HomeScreen.settingsDotKey(project, 3)), findsOneWidget);
    expect(find.byKey(HomeScreen.settingsDotKey(project, 4)), findsNothing);
    expect(pageShown(tester, 4), 0);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('in $language, each swipe toward the start of the line shows the next four, and its dot turns wide; swiped back, the page before', (tester) async {
      await openHome(tester, locale: Locale(language));

      await swipeProjectSettings(tester);
      expectPage(second, [first, third, fourth]);
      expect(pageShown(tester, 4), 1);

      await swipeProjectSettings(tester);
      expectPage(third, [first, second, fourth]);
      await swipeProjectSettings(tester);
      expectPage(fourth, [first, second, third]);
      expect(isEnabled(tester, HomeScreen.importSettingsKey(project)), isFalse);

      await swipeProjectSettings(tester, back: true);
      expectPage(third, [first, second, fourth]);
      expect(pageShown(tester, 4), 2);
    });
  }

  testWidgets('the pages go round: back from the first shows the last, and on from the last shows the first', (tester) async {
    await openHome(tester);

    await swipeProjectSettings(tester, back: true);
    expectPage(fourth, [first, second, third]);
    expect(pageShown(tester, 4), 3);

    await swipeProjectSettings(tester);
    expectPage(first, [second, third, fourth]);
    expect(pageShown(tester, 4), 0);
  });

  testWidgets('a page swiped to stays on coming back from a screen it opened, and the next start opens on the first page', (tester) async {
    final api = await openHome(tester);
    await scrollAndTap(tester, api, HomeScreen.accountsKey(project));
    await act(tester, api, () => tester.pageBack());
    expect(find.byKey(HomeScreen.accountsKey(project)), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await openHome(tester);
    expect(find.byKey(HomeScreen.accountsKey(project)), findsNothing);
    expect(find.byKey(HomeScreen.contractsKey(project)), findsOneWidget);
  });

  testWidgets('the pages keep the permissions: a field supervisor\'s hold no Approvals, Users, Categories or Payment methods, and so one page fewer', (tester) async {
    await openHome(tester, permissions: field);

    for (final key in [HomeScreen.approvalsKey(project), HomeScreen.usersKey(project), HomeScreen.categoriesKey(project), HomeScreen.paymentMethodsKey(project)]) {
      await showProjectSetting(tester, key);
      expect(find.byKey(key), findsNothing, reason: '$key');
    }
    expect(find.byKey(HomeScreen.settingsDotKey(project, 2)), findsOneWidget);
    expect(find.byKey(HomeScreen.settingsDotKey(project, 3)), findsNothing);
  });
}
