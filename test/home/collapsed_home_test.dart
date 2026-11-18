// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/summary_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

void main() {
  const stateKey = 'summary_projectSetting_state';

  /// The home of the first project, signed in with what the phone already keeps in [preferences].
  Future<FakeApi> openHome(WidgetTester tester, {Map<String, Object> preferences = const {}, List<String> permissions = managerAndFinance}) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة الغربية']);
    await pumpRedix(tester, api, stored: {'session': keptSession}, preferences: preferences);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    return api;
  }

  Future<void> tapCollapse(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byKey(HomeScreen.collapseKey)));

  IconData iconOf(WidgetTester tester) => tester.widget<Icon>(find.byKey(HomeScreen.collapseKey.icon)).icon!;

  Future<int?> kept() async => (await SharedPreferences.getInstance()).getInt(stateKey);

  testWidgets('redix-app #91 R1: the button beside Settings hides the summary, and a second tap shows it', (tester) async {
    final api = await openHome(tester);
    expect(find.byKey(SummaryCard.cardKey), findsOneWidget);

    await tapCollapse(tester, api);
    expect(find.byKey(SummaryCard.cardKey), findsNothing);

    await tapCollapse(tester, api);
    expect(find.byKey(SummaryCard.cardKey), findsOneWidget);
  });

  testWidgets('R1: the button sits right before Settings in the top bar', (tester) async {
    await openHome(tester);

    expect(isInTitleBar(tester, HomeScreen.collapseKey), isTrue);
    expect(tester.getTopRight(find.byKey(HomeScreen.collapseKey)).dx, tester.getTopLeft(find.byKey(HomeScreen.sharedSettingsKey('project-0'))).dx);
    expect(tester.getCenter(find.byKey(HomeScreen.collapseKey)).dx, lessThan(tester.getCenter(find.byKey(HomeScreen.sharedSettingsKey('project-0'))).dx));
  });

  testWidgets('R4: collapsed, the project\'s buttons are gone too', (tester) async {
    final api = await openHome(tester);
    expect(find.byKey(HomeScreen.cardKey('project-0')), findsOneWidget);

    await tapCollapse(tester, api);

    expect(find.byKey(HomeScreen.cardKey('project-0')), findsNothing);
    await showProjectSetting(tester, HomeScreen.accountsKey('project-0'));
    expect(find.byKey(HomeScreen.accountsKey('project-0')), findsNothing);
  });

  testWidgets('R5: unfold_less while everything shows, unfold_more while collapsed', (tester) async {
    final api = await openHome(tester);
    expect(iconOf(tester), Icons.unfold_less);

    await tapCollapse(tester, api);

    expect(iconOf(tester), Icons.unfold_more);
  });

  testWidgets('R5: its tooltip says what the next tap does', (tester) async {
    final api = await openHome(tester);
    expect(tester.widget<IconButton>(find.byKey(HomeScreen.collapseKey)).tooltip, 'en home.hideDetails');

    await tapCollapse(tester, api);

    expect(tester.widget<IconButton>(find.byKey(HomeScreen.collapseKey)).tooltip, 'en home.showDetails');
  });

  testWidgets('R6: it opens the way it was left after a restart', (tester) async {
    await openHome(tester, preferences: {stateKey: 0});

    expect(find.byKey(SummaryCard.cardKey), findsNothing);
    expect(iconOf(tester), Icons.unfold_more);
  });

  testWidgets('R7: collapsed, the entries and Add entry still show', (tester) async {
    final api = await openHome(tester, preferences: {stateKey: 0});

    expect(find.byKey(HomeScreen.addEntryKey('project-0')), findsOneWidget);
    expect(find.byKey(HomeScreen.searchEntriesKey('project-0')), findsOneWidget);
    expect(api, isNotNull);
  });

  testWidgets('R8: the key holds 0 when collapsed and 1 when expanded', (tester) async {
    final api = await openHome(tester);

    await tapCollapse(tester, api);
    expect(await kept(), 0);

    await tapCollapse(tester, api);
    expect(await kept(), 1);
  });

  testWidgets('R8: a key not found starts expanded, and is set to 1', (tester) async {
    await openHome(tester);

    expect(find.byKey(SummaryCard.cardKey), findsOneWidget);
    expect(await kept(), 1);
  });

  testWidgets('R8: a key found at 1 starts expanded', (tester) async {
    await openHome(tester, preferences: {stateKey: 1});

    expect(find.byKey(SummaryCard.cardKey), findsOneWidget);
    expect(await kept(), 1);
  });

  testWidgets('R9: it survives signing out', (tester) async {
    final api = await openHome(tester, preferences: {stateKey: 0});

    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.sharedSettingsKey('project-0'))));
    await tester.ensureVisible(find.byKey(SharedSettingsScreen.signOutKey));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(SharedSettingsScreen.signOutKey)));
    await tester.pumpAndSettle();

    expect(await kept(), 0);
  });

  testWidgets('R10: a collapsed home never shows the summary as it opens', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance, units: ['الفلة الغربية']);
    await pumpRedix(tester, api, stored: {'session': keptSession}, preferences: {stateKey: 0});
    await tester.tap(find.byKey(ProjectsScreen.cardKey('project-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byKey(SummaryCard.cardKey), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(SummaryCard.cardKey), findsNothing);
  });
}
