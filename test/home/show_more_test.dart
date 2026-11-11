import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/entries/entry_card.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/general_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

/// redix-app #105: the home shows the newest entries as many at a time as chosen in Settings, and Show more reads as many again.
void main() {
  const countKey = 'entriesShown_count';
  final more = find.byKey(HomeScreen.moreEntriesKey('project-0'));

  /// The home of a project holding [entries] entries, on a phone that keeps [preferences].
  Future<FakeApi> openHome(WidgetTester tester, int entries, {Map<String, Object> preferences = const {}}) async {
    final api = FakeApi()..addProject('غصون 6');
    for (var entry = 0; entry < entries; entry++) {
      api.addEntry();
    }
    await pumpRedix(tester, api, stored: {'session': keptSession}, preferences: preferences);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    return api;
  }

  int shown(WidgetTester tester) => find.byType(SwipeableEntryCard).evaluate().length;

  Future<void> showMore(WidgetTester tester, FakeApi api) async {
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(more));
  }

  Future<void> chooseCount(WidgetTester tester, FakeApi api, int count) async {
    await tester.ensureVisible(find.byKey(GeneralSettingsScreen.entriesShownChoiceKey));
    await act(tester, api, () => tester.tap(find.byKey(GeneralSettingsScreen.entriesShownChoiceKey)));
    await act(tester, api, () => tester.tap(find.byKey(GeneralSettingsScreen.entriesShownOptionKey(count)).last));
  }

  testWidgets('R1: Settings offers any number from 5 to 20, shows 5 until one is chosen, and keeps the choice on the phone', (tester) async {
    final api = await openHome(tester, 0);
    await openSettings(tester, api);

    expect((await SharedPreferences.getInstance()).getInt(countKey), 5);
    final choice = tester.widget<DropdownButton<int>>(find.byKey(GeneralSettingsScreen.entriesShownChoiceKey));
    expect(choice.value, 5);
    expect([for (final item in choice.items!) item.value], [for (var count = 5; count <= 20; count++) count]);

    await chooseCount(tester, api, 12);

    expect(tester.widget<DropdownButton<int>>(find.byKey(GeneralSettingsScreen.entriesShownChoiceKey)).value, 12);
    expect((await SharedPreferences.getInstance()).getInt(countKey), 12);
  });

  testWidgets('R2, R3: the home shows the newest as many as chosen, and reads only those, never the whole list', (tester) async {
    final api = await openHome(tester, 12, preferences: {countKey: 7});

    expect(shown(tester), 7);
    expect(find.byKey(EntriesScreen.rowKey('entry-11')), findsOneWidget);
    expect(find.byKey(EntriesScreen.rowKey('entry-4')), findsNothing);
    expect(api.entryReads, everyElement(7));
  });

  testWidgets('R2, R5: each Show more adds as many again, and Show more goes once no older entry is left', (tester) async {
    final api = await openHome(tester, 12, preferences: {countKey: 5});

    await showMore(tester, api);
    expect(shown(tester), 10);
    expect(more, findsOneWidget);

    await showMore(tester, api);
    expect(shown(tester), 12);
    expect(more, findsNothing);
    expect(api.entryReads, [5, 10, 15]);
  });

  testWidgets('R4: coming back to the home keeps what showed, at the count chosen meanwhile in Settings', (tester) async {
    final api = await openHome(tester, 30, preferences: {countKey: 5});
    await showMore(tester, api);
    expect(shown(tester), 10);

    await openSettings(tester, api);
    await chooseCount(tester, api, 8);
    await act(tester, api, () => tester.pageBack());

    expect(shown(tester), 16);
    expect(api.entryReads.last, 16);
  });

  testWidgets('R4: a Show more that cannot be read says so, and what showed stays with Show more under it', (tester) async {
    final api = await openHome(tester, 12, preferences: {countKey: 5});
    api.online = false;

    await showMore(tester, api);

    expect(find.text('en entries.loadFailed'), findsOneWidget);
    expect(shown(tester), 5);
    expect(more, findsOneWidget);
  });
}
