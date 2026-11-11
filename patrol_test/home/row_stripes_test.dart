import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// The ground the card keyed [cardKey] is drawn on.
Color? groundOf(PatrolIntegrationTester $, Key cardKey) =>
    $.tester.widget<Material>(find.descendant(of: find.byKey(cardKey), matching: find.byType(Material)).first).color;

void main() {
  phoneClass('Rows one under another, a shade apart (redix-app #108)', () {
    phoneCase('R1, R2: on the home the second entry takes the next tone of the scheme, and the first and third keep the ground', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final ids = [for (var entry = 1; entry <= 3; entry++) await Given.entry(manager, amount: entry, accountId: account)];
      await $.onTheHome(manager);
      final (newest, middle, oldest) = (EntriesScreen.rowKey(ids[2]).card, EntriesScreen.rowKey(ids[1]).card, EntriesScreen.rowKey(ids[0]).card);
      await $.reach($(oldest));
      final scheme = Theme.of($.tester.element(find.byKey(HomeScreen.titleKey))).colorScheme;

      expect(groundOf($, middle), scheme.surfaceContainerLow);
      expect(groundOf($, newest), groundOf($, oldest));
      expect(groundOf($, newest), isNot(groundOf($, middle)));
    });
  });
}
