import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/reports/summary.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/project_info_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Project settings, four to a page, swiped round (Muteb, 11 Nov 2026)', () {
    phoneCase('the card opens on the four used most; a swipe shows the next four; after the last page comes the first again', ($) async {
      final manager = await Given.manager();
      final id = manager.projectId;
      await $.onTheHome(manager);
      await $.reach($(HomeScreen.contractsKey(id)));
      for (final key in [HomeScreen.reportsKey(id), HomeScreen.itemReportsKey(id, SummarySide.expenses), HomeScreen.itemReportsKey(id, SummarySide.revenue)]) {
        expect($(key), findsOneWidget);
      }
      expect($(HomeScreen.suppliersKey(id)), findsNothing);
      expect($(HomeScreen.accountsKey(id)), findsNothing);
      expect($(HomeScreen.settingsDotKey(id, 3)), findsOneWidget);

      await $.swipeProjectSettings();
      expect($(HomeScreen.suppliersKey(id)), findsOneWidget);
      expect($(HomeScreen.accountsKey(id)), findsOneWidget);
      expect($.tester.widget<TextButton>(find.byKey(HomeScreen.vatKey(id))).onPressed, isNull, reason: 'Muteb, 12 Nov 2026: grayed until the next release');
      expect($(HomeScreen.contractsKey(id)), findsNothing);

      for (var page = 2; page <= 4; page++) {
        await $.swipeProjectSettings();
      }
      expect($(HomeScreen.contractsKey(id)), findsOneWidget);
    });

    phoneCase('a button on another page opens its screen once swiped to', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $.tapOn(HomeScreen.projectInfoKey(manager.projectId));
      await $.reach($(ProjectInfoScreen.nameKey));
    });
  });
}
