import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/ui/reason_sheet.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// An approved entry of a new manager, who stands on its page, answered.
Future<({Person manager, String entry})> onApproved(PatrolIntegrationTester $) async {
  final manager = await Given.manager();
  final entry = await Given.entry(manager);
  await Given.entriesApproved(manager, [entry]);
  await $.onTheHome(manager);
  await $.tapOn(EntriesScreen.rowKey(entry));
  await $.reach($(AddEntryScreen.statusKey));
  return (manager: manager, entry: entry);
}

void main() {
  phoneClass('Reverse an approved entry (UC-035)', () {
    phoneCase('AC-50.1: an approved entry is reversed by حذف, which asks why', ($) async {
      await onApproved($);
      await $.tapOn(AddEntryScreen.reverseKey);
      await $.reach($(ReasonSheet.reasonKey));
      await $.says(ReasonSheet.aboutKey, $.words.entriesReverseExplain);
    });

    phoneCase('AC-50.1: the entry\'s page then says it was reversed', ($) async {
      await onApproved($);
      await $.tapOn(AddEntryScreen.reverseKey);
      await $.fill(ReasonSheet.reasonKey, 'أدخل بالخطأ');
      await $.tapOn(ReasonSheet.sendKey);
      await $.says(AddEntryScreen.statusKey, $.words.entriesReversed);
    });

    phoneCase("findings row 201: the home's fifth entry, reversed while someone records another, still says it was reversed", ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      for (var newer = 1; newer < 5; newer++) {
        await Given.entry(manager);
      }
      await $.onTheHome(manager);
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.reach($(AddEntryScreen.statusKey));
      await Given.entry(manager);
      await $.tapOn(AddEntryScreen.reverseKey);
      await $.fill(ReasonSheet.reasonKey, 'أدخل بالخطأ');
      await $.tapOn(ReasonSheet.sendKey);
      await $.says(AddEntryScreen.statusKey, $.words.entriesReversed);
      expect($(AddEntryScreen.reverseKey), findsNothing);
    });

    phoneCase('AC-50.1: a reverse with no reason is refused', ($) async {
      await onApproved($);
      await $.tapOn(AddEntryScreen.reverseKey);
      await $.tapOn(ReasonSheet.sendKey);
      await $.says(ReasonSheet.messageKey, $.words.entriesReasonRequired);
    });

    phoneCase('whoever does not approve has no way to reverse', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      final member = await Given.member(manager, permissions: [Permission.recordEntries]);
      await $.onTheHome(member);
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.reach($(AddEntryScreen.statusKey));
      expect($(AddEntryScreen.reverseKey), findsNothing);
    });
  });
}
