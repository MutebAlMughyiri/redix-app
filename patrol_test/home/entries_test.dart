import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/home/summary_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/app_color.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// The color of the frame of the row of [id].
Color frameOf(PatrolIntegrationTester $, String id) {
  final card = find.byKey(EntriesScreen.rowKey(id).card);
  return ($.tester.widget<Card>(card).shape! as RoundedRectangleBorder).side.color;
}

/// What [color] paints on the screen showing now.
Color painted(PatrolIntegrationTester $, AppColor color) => color.of($.tester.element(find.byKey(HomeScreen.titleKey)));

void main() {
  phoneClass('القيود on the home (UC-033)', () {
    phoneCase('a draft shows under القيود and opens to be sent', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager, sent: false);
      await $.onTheHome(manager);
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.reach($(AddEntryScreen.sendDraftKey));
    });

    phoneCase('a rejected entry shows under القيود and opens to be fixed', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entryRejected(manager, entry);
      await $.onTheHome(manager);
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.reach($(AddEntryScreen.changeKey));
    });

    phoneCase('AC-22.1: the home lists the project\'s latest five, by anyone', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final entries = [for (var i = 0; i < 6; i++) await Given.entry(manager, accountId: account)];
      final member = await Given.member(manager);
      await $.onTheHome(member);
      for (final entry in entries.skip(1)) {
        await $.goTo($(EntriesScreen.rowKey(entry)));
      }
      expect($(EntriesScreen.rowKey(entries.first)), findsNothing);
    });

    phoneCase('AC-22.1: someone else\'s entry says who entered it', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      final member = await Given.member(manager);
      await $.onTheHome(member);
      await $.goTo($(EntriesScreen.detailsKey(entry)));
      expect($.tester.widget<Text>(find.byKey(EntriesScreen.detailsKey(entry))).data, contains($.words.entriesEnteredBy.replaceFirst('{0}', manager.displayName)));
    });

    phoneCase('a row\'s frame says where it stands: teal draft, orange waiting, red rejected, plain approved', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final draft = await Given.entry(manager, sent: false, accountId: account);
      final waiting = await Given.entry(manager, accountId: account);
      final rejected = await Given.entry(manager, accountId: account);
      await Given.entryRejected(manager, rejected);
      final approved = await Given.entry(manager, accountId: account);
      await Given.entriesApproved(manager, [approved]);
      await $.onTheHome(manager);
      for (final (id, color) in [(draft, AppColor.brand), (waiting, AppColor.waiting), (rejected, AppColor.refusal), (approved, AppColor.frame)]) {
        await $.goTo($(EntriesScreen.rowKey(id)));
        expect(frameOf($, id), painted($, color));
      }
    });

    phoneCase('R3: with none of mine the home still lists the project\'s', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      final member = await Given.member(manager);
      await $.onTheHome(member);
      await $.goTo($(EntriesScreen.rowKey(entry)));
    });

    phoneCase('R4: the search opens the list ready to type', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.searchEntriesKey(manager.projectId));
      await $.reach($(EntriesScreen.searchKey));
      expect($.tester.widget<SearchBar>(find.byKey(EntriesScreen.searchKey)).autoFocus, isTrue);
    });

    phoneCase('the way to all opens the whole list', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await $.fromTheHome(manager, HomeScreen.searchEntriesKey(manager.projectId));
      await $.reach($(EntriesScreen.foundKey));
      await $.goTo($(EntriesScreen.rowKey(entry)));
    });

    phoneCase('a swipe deletes a row, and the waiting count follows', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await $.onTheHome(manager);
      await $.reach($(SummaryCard.pendingKey));
      await $.swipeAway(EntriesScreen.rowKey(entry));
      await $.gone($(EntriesScreen.rowKey(entry)));
      await $.gone($(SummaryCard.pendingKey));
    });

    phoneCase('coming back from approving reads the latest entries again', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await $.onTheHome(manager);
      await $.goTo($(EntriesScreen.rowKey(entry)));
      expect(frameOf($, entry), painted($, AppColor.waiting));
      await $.tapOn(HomeScreen.approvalsKey(manager.projectId));
      await $.tapOn(ApprovalsScreen.approveKey(entry));
      await $.gone($(ApprovalsScreen.cardKey(entry)));
      await $.back();
      await $.goTo($(EntriesScreen.rowKey(entry)));
      await $.until(() => frameOf($, entry) == painted($, AppColor.frame));
      expect(frameOf($, entry), painted($, AppColor.frame));
    });

    phoneCase('AC-22.1: the home shows no count of mine waiting or rejected', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entryRejected(manager, await Given.entry(manager));
      await $.onTheHome(manager);
      await $.goTo($(EntriesScreen.rowKey(entry)));
      expect(find.textContaining('${$.words.entriesPendingApproval} ·'), findsNothing);
      expect(find.textContaining('${$.words.entriesRejected} ·'), findsNothing);
    });

    phoneCase('R14: with none at all it keeps its heading, search and way to all', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $.goTo($(HomeScreen.entriesEmptyKey(manager.projectId)));
      await $.says(HomeScreen.entriesEmptyKey(manager.projectId), $.words.entriesEmpty);
      expect($(HomeScreen.entriesHeadingKey(manager.projectId)), findsOneWidget);
      expect($(HomeScreen.searchEntriesKey(manager.projectId)), findsOneWidget);
      expect($(HomeScreen.searchEntriesKey(manager.projectId)), findsOneWidget);
    });

    phoneCase('entries that cannot be read say so, never that there are none', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      final member = await Given.member(manager, permissions: [Permission.recordEntries]);
      await $.onTheList(member);
      await Pc.cutNetwork();
      await $.openProject(member.projectId);
      await $.goTo($(HomeScreen.entriesEmptyKey(member.projectId)));
      await $.says(HomeScreen.entriesEmptyKey(member.projectId), $.words.entriesLoadFailed);
    });
  });
}
