import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Delete an entry by swiping (UC-033)', () {
    phoneCase('redix-api #102, #119: a swipe deletes a draft once confirmed in its row', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager, sent: false);
      await $.onTheHome(manager);
      await $.swipeAway(EntriesScreen.rowKey(entry));
      expect(find.byKey(ConfirmDialog.dialogKey), findsNothing);
      await $.gone($(EntriesScreen.rowKey(entry)));
      expect(await Given.entries(manager), isEmpty);
    });

    phoneCase('redix-api #102, #119: a swipe deletes a rejected entry once confirmed in its row', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entryRejected(manager, entry);
      await $.onTheHome(manager);
      await $.swipeAway(EntriesScreen.rowKey(entry));
      await $.gone($(EntriesScreen.rowKey(entry)));
    });

    phoneCase('redix-api #102: a short swipe deletes nothing', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager, sent: false);
      await $.onTheHome(manager);
      await $.swipeToAsk(EntriesScreen.rowKey(entry), share: 0.15);
      await Future<void>.delayed(const Duration(seconds: 1));
      await $.pumpAndSettle();
      expect($(EntriesScreen.rowKey(entry)), findsOneWidget);
      expect(await Given.entries(manager), hasLength(1));
    });

    phoneCase('redix-api #102: without deleteEntries an entry does not swipe', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager, permissions: [Permission.recordEntries, Permission.chargeAnyAccount]);
      final entry = await Given.entry(member, sent: false, accountId: await Given.account(manager));
      await $.onTheHome(member);
      await $.goTo($(EntriesScreen.rowKey(entry)));
      expect($(EntriesScreen.rowKey(entry).swipe), findsNothing);
      expect($(EntriesScreen.rowKey(entry).bar), findsNothing);
    });

    phoneCase('redix-api #102: an approved entry does not swipe', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await Given.entriesApproved(manager, [entry]);
      await $.onTheHome(manager);
      await $.goTo($(EntriesScreen.rowKey(entry)));
      expect($(EntriesScreen.rowKey(entry).swipe), findsNothing);
      expect($(EntriesScreen.rowKey(entry).bar), findsNothing);
    });
  });
}
