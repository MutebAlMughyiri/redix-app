import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/search_line.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/search_steps.dart';
import '../support/steps.dart';

/// Signs [person] in and opens the list of entries, searched on the API a page at a time (redix-app #104).
Future<void> onEntries(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.searchEntriesKey(person.projectId));
  await $.reach($(SearchLine.searchKey));
}

void main() {
  phoneClass('The list of entries (UC-033)', () {
    phoneCase('everyone sees all entries, and starts on their own', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final member = await Given.member(manager, permissions: [Permission.recordEntries, Permission.chargeAnyAccount]);
      final mine = await Given.entry(member, accountId: account);
      final theirs = await Given.entry(manager, accountId: account);
      await onEntries($, member);
      await $.reach($(EntriesScreen.rowKey(mine)));
      expect($(EntriesScreen.rowKey(theirs)), findsNothing);
      await $.filterBy(EntriesScreen.mineKey);
      await $.reach($(EntriesScreen.rowKey(theirs)));
    });

    phoneCase('redix-api #110: القيود lists every kind: expenses, revenue and partners\' money, each saying what it is', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final partner = await Given.partner(manager, 'هيثم');
      final purchase = await Given.entry(manager, accountId: account);
      final revenue = await Given.revenue(manager, accountId: account);
      final money = await Given.partnerMoney(manager, partner, accountId: account);
      await onEntries($, manager);
      await $.reach($(EntriesScreen.rowKey(purchase)));
      await $.goTo($(EntriesScreen.detailsKey(revenue)));
      await $.goTo($(EntriesScreen.detailsKey(money)));
      expect($.tester.widget<Text>(find.byKey(EntriesScreen.detailsKey(money))).data, contains($.words.capitalContribution));
    });

    phoneCase('R8, R16, redix-app #104: the API searches the supplier and amount, Arabic spelling read as one, digits in either script', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final supplier = await Given.supplier(manager, name: 'أحمد للمقاولات');
      final found = await Given.entry(manager, amount: 345, accountId: account, supplierId: supplier);
      final other = await Given.entry(manager, amount: 111, accountId: account, supplierId: await Given.supplier(manager, name: 'مورد الميدان'));
      await onEntries($, manager);
      await $.searchFor('احمد');
      await $.gone($(EntriesScreen.rowKey(other)));
      await $.reach($(EntriesScreen.rowKey(found)));
      await $.searchFor('٣٤٥');
      await $.reach($(EntriesScreen.rowKey(found)));
      await $.searchFor('111');
      await $.gone($(EntriesScreen.rowKey(found)));
      await $.reach($(EntriesScreen.rowKey(other)));
    });

    phoneCase('R8, redix-app #104: a kind and a status, chosen from their chips under the arrow, keep what holds both', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final purchase = await Given.entry(manager, accountId: account);
      final approved = await Given.contractorPayment(manager, await Given.contract(manager), accountId: account);
      final waiting = await Given.contractorPayment(manager, await Given.contract(manager), accountId: account);
      await Given.entriesApproved(manager, [approved]);
      await onEntries($, manager);
      await $.reach($(EntriesScreen.rowKey(purchase)));
      await $.chooseIn(EntriesScreen.kindChoiceKey, EntriesScreen.kindKey('contractorPayment'));
      await $.gone($(EntriesScreen.rowKey(purchase)));
      await $.chooseIn(EntriesScreen.statusChoiceKey, EntriesScreen.statusFilterKey('entries.approved'));
      await $.gone($(EntriesScreen.rowKey(waiting)));
      await $.reach($(EntriesScreen.rowKey(approved)));
      await $.tapOn(SearchLine.filtersKey);
      expect($.filtersArrow, Icons.filter_alt);
    });

    phoneCase('R8: mine keeps mine, a kind narrows the list, and clearing brings back what it hid', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final member = await Given.member(manager, permissions: [Permission.recordEntries, Permission.chargeAnyAccount]);
      final mine = await Given.entry(manager, accountId: account);
      final theirs = await Given.entry(member, accountId: account);
      await onEntries($, manager);
      await $.reach($(EntriesScreen.rowKey(mine)));
      expect($(EntriesScreen.rowKey(theirs)), findsNothing);
      await $.filterBy(EntriesScreen.mineKey);
      await $.reach($(EntriesScreen.rowKey(theirs)));
      expect($(EntriesScreen.clearKey), findsNothing);
      await $.chooseIn(EntriesScreen.kindChoiceKey, EntriesScreen.kindKey('revenue'));
      await $.gone($(EntriesScreen.rowKey(mine)));
      await $.gone($(EntriesScreen.rowKey(theirs)));
      await $.tapOn(EntriesScreen.clearKey);
      await $.reach($(EntriesScreen.rowKey(mine)));
      await $.reach($(EntriesScreen.rowKey(theirs)));
      expect($(EntriesScreen.clearKey), findsNothing);
      await $.tapOn(EntriesScreen.mineKey);
      await $.gone($(EntriesScreen.rowKey(theirs)));
    });

    phoneCase('R8: a period keeps the entries dated inside it, both ends included', ($) async {
      final today = DateTime.now();
      final manager = await Given.manager(startDate: today.subtract(const Duration(days: 60)).toIso8601String().substring(0, 10));
      final account = await Given.account(manager);
      final inside = await Given.entry(manager, accountId: account);
      final older = today.subtract(const Duration(days: 40)).toIso8601String().substring(0, 10);
      final outside = await Given.entry(manager, accountId: account, date: older);
      await onEntries($, manager);
      await $.reach($(EntriesScreen.rowKey(inside)));
      await $.goTo($(EntriesScreen.rowKey(outside)));
      await $.filterBy(EntriesScreen.periodKey);
      await $.pumpAndSettle();
      final input = find.byIcon(Icons.edit_outlined);
      await $.tester.tap(input);
      await $.pumpAndSettle();
      final fields = find.descendant(of: find.byType(DateRangePickerDialog), matching: find.byType(TextField));
      final shown = '${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}/${today.year}';
      await $(fields.first).enterText(shown);
      await $(fields.last).enterText(shown);
      await $.tester.tap(find.text(MaterialLocalizations.of($.tester.element(fields.first)).okButtonLabel));
      await $.pumpAndSettle();
      await $.gone($(EntriesScreen.rowKey(outside)));
      await $.reach($(EntriesScreen.rowKey(inside)));
    });

    phoneCase('redix-app #104: the entries come five at a time, as Settings chooses by default, and Show more reads the next', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final oldestFirst = [for (var entry = 1; entry <= 6; entry++) await Given.entry(manager, amount: entry, accountId: account)];
      await onEntries($, manager);
      await $.goTo($(EntriesScreen.moreKey));
      expect($(EntriesScreen.rowKey(oldestFirst.first)), findsNothing);
      for (final id in oldestFirst.skip(1)) {
        await $.goUpTo($(EntriesScreen.rowKey(id)));
        expect($(EntriesScreen.rowKey(id)), findsOneWidget);
      }
      await $.tapOn(EntriesScreen.moreKey);
      await $.gone($(EntriesScreen.moreKey));
      await $.goTo($(EntriesScreen.rowKey(oldestFirst.first)));
      expect($(EntriesScreen.rowKey(oldestFirst.first)), findsOneWidget);
    });

    phoneCase('a search that finds nothing says so', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      await onEntries($, manager);
      await $.searchFor('لا يوجد ${Given.unique()}');
      await $.reach($(ApiListBody.emptyKey));
    });
  });
}
