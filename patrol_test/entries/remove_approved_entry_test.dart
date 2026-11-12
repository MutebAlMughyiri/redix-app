import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/messages.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// An approved entry of a new manager, who holds the removal when [removes], standing on the entry's page.
Future<({Person manager, String entry})> onApproved(PatrolIntegrationTester $, {bool removes = true}) async {
  final manager = await Given.manager();
  final entry = await Given.entry(manager);
  await Given.entriesApproved(manager, [entry]);
  if (removes) {
    await Given.ticked(manager, [Permission.removeApprovedEntries], by: manager);
  }
  await $.onTheHome(manager);
  await $.tapOn(EntriesScreen.rowKey(entry));
  await $.reach($(AddEntryScreen.statusKey));
  return (manager: manager, entry: entry);
}

void main() {
  phoneClass('Remove an approved entry (redix-api #119)', () {
    phoneCase('AC-50.1: whoever holds the removal removes an approved entry by حذف, and it leaves the list', ($) async {
      final made = await onApproved($);
      await $.tapOn(AddEntryScreen.removeKey);
      await $.tapOn(AddEntryScreen.removeKey.confirm);
      await $.gone($(AddEntryScreen.removeKey.confirm));
      await $.gone($(EntriesScreen.rowKey(made.entry)));
      expect((await Given.entries(made.manager)).map((entry) => entry['id']), isNot(contains(made.entry)));
    });

    phoneCase("findings row 201: the home's fifth entry, removed while someone records another, is the one removed", ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      await Given.ticked(manager, [Permission.removeApprovedEntries], by: manager);
      for (var newer = 1; newer < 5; newer++) {
        await Given.entry(manager);
      }
      await $.onTheHome(manager);
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.reach($(AddEntryScreen.statusKey));
      final recorded = await Given.entry(manager);
      await $.tapOn(AddEntryScreen.removeKey);
      await $.tapOn(AddEntryScreen.removeKey.confirm);
      await $.gone($(AddEntryScreen.removeKey.confirm));
      final ids = (await Given.entries(manager)).map((row) => row['id']).toList();
      expect((ids.contains(entry), ids.contains(recorded), ids.length), (false, true, 5));
    });

    phoneCase('redix-api #119: حذف asks in place, and تراجع in the bar brings the entry back to the list', ($) async {
      final made = await onApproved($);
      await $.tapOn(AddEntryScreen.removeKey);
      await $.reach($(AddEntryScreen.removeKey.question));
      await $.tapOn(AddEntryScreen.removeKey.confirm);
      await $.gone($(EntriesScreen.rowKey(made.entry)));
      await $.tapOn(messageKeyOf('swipe.removed').icon);
      await $.reach($(EntriesScreen.rowKey(made.entry)));
      expect((await Given.entries(made.manager)).map((entry) => entry['id']), contains(made.entry));
    });

    phoneCase('redix-api #119: إلغاء in the row puts it back, and nothing is removed', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      await Given.ticked(manager, [Permission.removeApprovedEntries], by: manager);
      await $.onTheHome(manager);
      await $.swipeToAsk(EntriesScreen.rowKey(entry));
      await $.tapOn(EntriesScreen.rowKey(entry).cancel);
      await $.reach($(EntriesScreen.rowKey(entry).bar));
      expect((await Given.entries(manager)).map((row) => row['id']), contains(entry));
    });

    phoneCase('AC-50.1: without the removal an approved entry offers no حذف, even to whoever approves', ($) async {
      await onApproved($, removes: false);
      expect($(AddEntryScreen.removeKey), findsNothing);
    });

    phoneCase('AC-50.1: whoever holds the removal swipes an approved entry off the list', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      await Given.ticked(manager, [Permission.removeApprovedEntries], by: manager);
      await $.onTheHome(manager);
      await $.swipeAway(EntriesScreen.rowKey(entry));
      await $.gone($(EntriesScreen.rowKey(entry)));
    });

    phoneCase('AC-50.1: without the removal an approved entry on the list shows no red bar', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      await $.onTheHome(manager);
      await $.reach($(EntriesScreen.rowKey(entry)));
      expect($(EntriesScreen.rowKey(entry).bar), findsNothing);
    });
  });
}
