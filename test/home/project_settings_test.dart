import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

/// Muteb, 11 Nov 2026: the home's Project settings show the four used most, two by two, and the arrow under them opens the rest in place. Nothing is kept: the app
/// starts with them closed.
void main() {
  const project = 'project-0';
  final arrow = find.byKey(HomeScreen.moreSettingsKey(project));
  final always = [HomeScreen.contractsKey(project), HomeScreen.reportsKey(project), HomeScreen.itemReportsKey(project), HomeScreen.suppliersKey(project)];
  final rest = [
    HomeScreen.accountsKey(project),
    HomeScreen.partnersKey(project),
    HomeScreen.vatKey(project),
    HomeScreen.approvalsKey(project),
    HomeScreen.documentsKey(project),
    HomeScreen.projectInfoKey(project),
    HomeScreen.myPermissionsKey(project),
    HomeScreen.usersKey(project),
    HomeScreen.categoriesKey(project),
    HomeScreen.paymentMethodsKey(project),
    HomeScreen.importSettingsKey(project),
  ];

  /// The app started and the home of a project opened, seen with [permissions], without touching the arrow.
  Future<FakeApi> openHome(WidgetTester tester, {List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions);
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey(project))));
    return api;
  }

  IconData arrowIcon(WidgetTester tester) => tester.widget<Icon>(find.byKey(HomeScreen.moreSettingsKey(project).icon)).icon!;

  Future<void> tapArrow(WidgetTester tester, FakeApi api) async {
    await tester.ensureVisible(arrow);
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(arrow));
  }

  testWidgets('the app starts with the card closed on the four used most, two by two, and the arrow down; none of the rest', (tester) async {
    await openHome(tester);

    for (final key in always) {
      expect(find.byKey(key), findsOneWidget);
    }
    for (final key in rest) {
      expect(find.byKey(key), findsNothing);
    }
    expect(tester.getTopLeft(find.byKey(always[0])).dy, tester.getTopLeft(find.byKey(always[1])).dy);
    expect(tester.getTopLeft(find.byKey(always[2])).dy, greaterThan(tester.getTopLeft(find.byKey(always[0])).dy));
    expect(arrowIcon(tester), Icons.expand_more);
  });

  testWidgets('the arrow opens the card on every button and, tapped again, closes it on the four', (tester) async {
    final api = await openHome(tester);

    await tapArrow(tester, api);

    for (final key in [...always, ...rest]) {
      expect(find.byKey(key), findsOneWidget);
    }
    expect(arrowIcon(tester), Icons.expand_less);

    await tapArrow(tester, api);

    expect(find.byKey(HomeScreen.accountsKey(project)), findsNothing);
    expect(find.byKey(HomeScreen.contractsKey(project)), findsOneWidget);
    expect(arrowIcon(tester), Icons.expand_more);
  });

  testWidgets('opened, the card stays open on coming back from a screen it opened, and the next start opens it closed', (tester) async {
    final api = await openHome(tester);
    await tapArrow(tester, api);

    await scrollAndTap(tester, api, HomeScreen.accountsKey(project));
    await act(tester, api, () => tester.pageBack());
    expect(find.byKey(HomeScreen.accountsKey(project)), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await openHome(tester);
    expect(find.byKey(HomeScreen.accountsKey(project)), findsNothing);
  });

  testWidgets('opened, the rest keep their permissions: a field supervisor sees no Approvals, Users, Categories or Payment methods', (tester) async {
    final api = await openHome(tester, permissions: field);

    await tapArrow(tester, api);

    for (final key in [HomeScreen.approvalsKey(project), HomeScreen.usersKey(project), HomeScreen.categoriesKey(project), HomeScreen.paymentMethodsKey(project)]) {
      expect(find.byKey(key), findsNothing);
    }
    expect(find.byKey(HomeScreen.accountsKey(project)), findsOneWidget);
    expect(isEnabled(tester, HomeScreen.importSettingsKey(project)), isFalse);
  });
}
