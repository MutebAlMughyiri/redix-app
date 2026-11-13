import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// How many of [entries] the home shows.
int entriesShown(List<String> entries) => entries.where((entry) => find.byKey(EntriesScreen.rowKey(entry)).evaluate().isNotEmpty).length;

/// Chooses [count] as the number of entries shown at a time, in Settings opened from the home of [projectId], and comes back to the home.
Future<void> chooseEntriesShown(PatrolIntegrationTester $, String projectId, int count) async {
  await $.tapOn(HomeScreen.sharedSettingsKey(projectId));
  await $.tapOn(SharedSettingsScreen.entriesShownChoiceKey);
  await $.tester.tap(find.byKey(SharedSettingsScreen.entriesShownOptionKey(count)));
  await $.pumpAndSettle();
  await $.back();
  await $.reach($(HomeScreen.titleKey));
}

void main() {
  phoneClass('Show more on the home (redix-app #105)', () {
    phoneCase('R2, R5: the home shows the newest five, each Show more five more, and Show more goes once none is left', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final entries = [for (var entry = 1; entry <= 7; entry++) await Given.entry(manager, amount: entry, accountId: account)];
      await $.onTheHome(manager);
      await $.reach($(HomeScreen.moreEntriesKey(manager.projectId)));
      expect(entriesShown(entries), 5);

      await $.tapOn(HomeScreen.moreEntriesKey(manager.projectId));

      expect(entriesShown(entries), 7);
      expect($(HomeScreen.moreEntriesKey(manager.projectId)), findsNothing);
    });

    phoneCase('R1, R4: a count chosen in Settings is how many the home shows on coming back, and it is kept', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final entries = [for (var entry = 1; entry <= 7; entry++) await Given.entry(manager, amount: entry, accountId: account)];
      await $.onTheHome(manager);
      await $.reach($(HomeScreen.moreEntriesKey(manager.projectId)));

      await chooseEntriesShown($, manager.projectId, 6);
      await $.reach($(HomeScreen.moreEntriesKey(manager.projectId)));
      expect(entriesShown(entries), 6);

      await chooseEntriesShown($, manager.projectId, 5);
      expect(entriesShown(entries), 5);
    });
  });
}
