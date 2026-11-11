import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/documents/documents_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/ui/bottom_button.dart';
import 'package:redix/users/users_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Opens [screen] from the home of [manager]'s project and checks its add is a + in the title bar keyed [add], with no bottom button.
Future<void> addsFromTheTitleBar(PatrolIntegrationTester $, Person manager, Key screen, Key add) async {
  await $.onTheHome(manager);
  await $.tapOn(screen);
  await $.reach($(add));
  expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(add)), findsOneWidget);
  expect($.tester.widget<Icon>(find.descendant(of: find.byKey(add), matching: find.byType(Icon))).icon, Icons.add);
  expect(find.byType(BottomButton), findsNothing);
}

void main() {
  phoneClass('A + in the title bar on Documents, Payment methods and Users (redix-app #106)', () {
    phoneCase('R1: Documents adds from a + in the title bar', ($) async {
      final manager = await Given.manager();
      await addsFromTheTitleBar($, manager, HomeScreen.documentsKey(manager.projectId), DocumentsScreen.addKey);
    });

    phoneCase('R1: Payment methods adds from a + in the title bar', ($) async {
      final manager = await Given.manager();
      await addsFromTheTitleBar($, manager, HomeScreen.paymentMethodsKey(manager.projectId), PaymentMethodsScreen.addKey);
    });

    phoneCase('R1: Users adds from a + in the title bar, beside adding someone who has an account', ($) async {
      final manager = await Given.manager();
      await addsFromTheTitleBar($, manager, HomeScreen.usersKey(manager.projectId), UsersScreen.newUserKey);
      expect(find.descendant(of: find.byType(AppBar), matching: find.byKey(UsersScreen.addExistingKey)), findsOneWidget);
    });
  });
}
