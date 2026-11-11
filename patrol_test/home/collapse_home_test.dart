import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/home/summary_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/words/language_switch.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Whether the button beside Settings shows [icon].
bool showsIcon(PatrolIntegrationTester $, IconData icon) => $.tester.widget<Icon>(find.byKey(HomeScreen.collapseKey.icon)).icon == icon;

/// Taps the button beside Settings.
Future<void> tapCollapse(PatrolIntegrationTester $) async {
  await $(HomeScreen.collapseKey).tap();
  await $.pumpAndSettle();
}

/// Signs [manager] in and stands on their project's home, expanded, its figures read.
Future<void> onAnExpandedHome(PatrolIntegrationTester $, Person manager) async {
  await $.onTheHome(manager);
  await $.reach($(SummaryCard.surplusKey));
  expect(showsIcon($, Icons.unfold_less), isTrue);
}

/// The home of [projectId] shows no summary and none of the project's buttons, while its entries and Add entry stay.
Future<void> isCollapsed(PatrolIntegrationTester $, String projectId) async {
  await $.gone($(SummaryCard.cardKey));
  expect($(HomeScreen.cardKey(projectId)), findsNothing);
  expect(showsIcon($, Icons.unfold_more), isTrue);
  await $.reach($(HomeScreen.addEntryKey(projectId)));
}

/// How far the button beside Settings is from Settings, along the top bar: positive when it sits to the right.
double collapseFromSettings(PatrolIntegrationTester $, String projectId) =>
    $.tester.getCenter(find.byKey(HomeScreen.collapseKey)).dx - $.tester.getCenter(find.byKey(HomeScreen.sharedSettingsKey(projectId))).dx;

void main() {
  phoneClass('Collapse the home\'s summary (redix-app #91)', () {
    phoneCase('R1, R2, R4, R7: the button beside Settings hides the summary and the project\'s buttons, and the entries and إضافة قيد stay', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      await onAnExpandedHome($, manager);
      await tapCollapse($);
      await isCollapsed($, manager.projectId);
      await $.reach($(HomeScreen.searchEntriesKey(manager.projectId)));
      await $.goTo($(EntriesScreen.rowKey(entry)));
    });

    phoneCase('R2: a second tap shows them again, with fresh figures', ($) async {
      final manager = await Given.manager();
      await onAnExpandedHome($, manager);
      await $.says(SummaryCard.expensesKey, '0.00');
      await tapCollapse($);
      await $.gone($(SummaryCard.cardKey));
      await Given.entriesApproved(manager, [await Given.entry(manager, amount: 100)]);
      await tapCollapse($);
      await $.says(SummaryCard.expensesKey, '100.00');
      await $.reach($(HomeScreen.cardKey(manager.projectId)));
      expect(showsIcon($, Icons.unfold_less), isTrue);
    });

    phoneCase('R4: collapsed, scrolling the whole home finds none of the project\'s buttons', ($) async {
      final manager = await Given.manager();
      await onAnExpandedHome($, manager);
      await tapCollapse($);
      await isCollapsed($, manager.projectId);
      await $.tester.fling(find.byType(Scrollable).first, const Offset(0, -2000), 2000);
      await $.pumpAndSettle();
      expect($(HomeScreen.accountsKey(manager.projectId)), findsNothing);
      expect($(HomeScreen.contractsKey(manager.projectId)), findsNothing);
      expect($(SummaryCard.surplusKey), findsNothing);
    });

    phoneCase('R6, R10: after a restart the home opens collapsed, never showing the summary on the way', ($) async {
      final manager = await Given.manager();
      await onAnExpandedHome($, manager);
      await tapCollapse($);
      await $.gone($(SummaryCard.cardKey));
      await $.restartApp();
      await $.reach($(ProjectsScreen.cardKey(manager.projectId)));
      await $(ProjectsScreen.cardKey(manager.projectId)).tap(settlePolicy: SettlePolicy.noSettle);
      for (var frame = 0; frame < 40; frame++) {
        await $.tester.pump(const Duration(milliseconds: 50));
        expect(find.byKey(SummaryCard.cardKey), findsNothing);
      }
      await isCollapsed($, manager.projectId);
    });

    phoneCase('R9: signing out and in again keeps it collapsed', ($) async {
      final manager = await Given.manager();
      await onAnExpandedHome($, manager);
      await tapCollapse($);
      await $.gone($(SummaryCard.cardKey));
      await $.signOutFromTheHome(manager.projectId);
      await $.signIn(manager.username, manager.password);
      await $.openProject(manager.projectId);
      await isCollapsed($, manager.projectId);
    });

    phoneCase('R8: another project opens the same way, because the choice is for this phone', ($) async {
      final manager = await Given.manager();
      final other = await Given.manager();
      await Given.joined(manager, by: other);
      await onAnExpandedHome($, manager);
      await tapCollapse($);
      await $.gone($(SummaryCard.cardKey));
      await $.tapOn(HomeScreen.sharedSettingsKey(manager.projectId));
      await $.tapOn(SharedSettingsScreen.switchProjectKey);
      await $.openProject(other.projectId);
      await isCollapsed($, other.projectId);
    });

    phoneCase('R11: with the network cut it still collapses and expands', ($) async {
      final manager = await Given.manager();
      await onAnExpandedHome($, manager);
      await Pc.cutNetwork();
      await tapCollapse($);
      await isCollapsed($, manager.projectId);
      await tapCollapse($);
      await $.reach($(SummaryCard.cardKey));
      expect(showsIcon($, Icons.unfold_less), isTrue);
    });

    phoneCase('R1: in English the button sits just before Settings, to its left', ($) async {
      final manager = await Given.manager();
      await onAnExpandedHome($, manager);
      expect(collapseFromSettings($, manager.projectId), inInclusiveRange(-60, -1));
    });

    phoneCase('R1: in Arabic the button sits just before Settings, to its right', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await $(ProjectsScreen.sharedSettingsKey).tap();
      await $.goTo($(LanguageSwitch.arabicKey));
      await $(LanguageSwitch.arabicKey).tap();
      await $.until(() => Directionality.of($.tester.element(find.byKey(SharedSettingsScreen.languageKey))) == TextDirection.rtl);
      await $.tapOn(SharedSettingsScreen.switchProjectKey);
      await $.openProject(manager.projectId);
      await $.reach($(HomeScreen.collapseKey));
      expect(collapseFromSettings($, manager.projectId), inInclusiveRange(1, 60));
    });
  });
}
