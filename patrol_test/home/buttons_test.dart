import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/users/users_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// A new person in a new project holding [permissions], standing on its home.
Future<Person> onTheHomeHolding(PatrolIntegrationTester $, List<Permission> permissions) async {
  final member = await Given.member(await Given.manager(), permissions: permissions);
  await $.onTheHome(member);
  return member;
}

/// Checks the button [button] of the home is not there, reaching the last button first so that the whole list was built.
Future<void> noButton(PatrolIntegrationTester $, Person member, Key button) async {
  await $.goTo($(HomeScreen.importSettingsKey(member.projectId)));
  expect($(button), findsNothing);
}

void main() {
  phoneClass('The buttons follow my permissions (UC-009, AC-36.2)', () {
    phoneCase('with manageUsers, Users opens', ($) async {
      final member = await onTheHomeHolding($, [Permission.manageUsers]);
      await $.tapOn(HomeScreen.usersKey(member.projectId));
      await $.reach($(UsersScreen.newUserKey));
    });

    phoneCase('with manageStructure, Categories opens', ($) async {
      final member = await onTheHomeHolding($, [Permission.manageStructure]);
      await $.tapOn(HomeScreen.categoriesKey(member.projectId));
      await $.reach($(CategoriesScreen.addCategoryKey));
    });

    phoneCase('with manageSettings, Payment methods opens', ($) async {
      final member = await onTheHomeHolding($, [Permission.manageSettings]);
      await $.tapOn(HomeScreen.paymentMethodsKey(member.projectId));
      await $.reach($(PaymentMethodsScreen.addKey));
    });

    phoneCase('with approveEntries, Waiting for approval opens', ($) async {
      final member = await onTheHomeHolding($, [Permission.approveEntries]);
      await $.tapOn(HomeScreen.approvalsKey(member.projectId));
      await $.reach($(ApprovalsScreen.allKey));
    });

    phoneCase('with recordEntries, Add entry opens', ($) async {
      final member = await onTheHomeHolding($, [Permission.recordEntries]);
      await $.tapOn(HomeScreen.addEntryKey(member.projectId));
      await $.reach($(AddEntryScreen.tableKey));
    });

    phoneCase('everyone has Accounts, Partners, Suppliers, Contracts, Reports, الإيرادات والمصروفات, Actual balances, VAT, Documents, More info and My permissions', ($) async {
      final member = await onTheHomeHolding($, []);
      final id = member.projectId;
      for (final key in [HomeScreen.accountsKey(id), HomeScreen.partnersKey(id), HomeScreen.suppliersKey(id), HomeScreen.contractsKey(id), HomeScreen.reportsKey(id), HomeScreen.itemReportsKey(id), HomeScreen.actualBalancesKey(id), HomeScreen.vatKey(id), HomeScreen.documentsKey(id), HomeScreen.projectInfoKey(id), HomeScreen.myPermissionsKey(id)]) {
        await $.goTo($(key));
      }
    });

    phoneCase('AC-36.2: the buttons change when I switch to a project where I hold other permissions', ($) async {
      final mine = await Given.manager();
      final other = await Given.manager();
      await Given.joined(mine, by: other);
      await $.onTheHome(mine);
      await $.goTo($(HomeScreen.usersKey(mine.projectId)));
      await $.back();
      await $.openProject(other.projectId);
      await noButton($, other, HomeScreen.usersKey(other.projectId));
    });

    phoneCase('without manageUsers there is no Users', ($) async {
      final member = await onTheHomeHolding($, []);
      await noButton($, member, HomeScreen.usersKey(member.projectId));
    });

    phoneCase('without manageStructure there is no Categories', ($) async {
      final member = await onTheHomeHolding($, []);
      await noButton($, member, HomeScreen.categoriesKey(member.projectId));
    });

    phoneCase('without manageSettings there is no Payment methods', ($) async {
      final member = await onTheHomeHolding($, []);
      await noButton($, member, HomeScreen.paymentMethodsKey(member.projectId));
    });

    phoneCase('without approveEntries there is no Waiting for approval', ($) async {
      final member = await onTheHomeHolding($, []);
      await noButton($, member, HomeScreen.approvalsKey(member.projectId));
    });

    phoneCase('without recordEntries Add entry is gray', ($) async {
      final member = await onTheHomeHolding($, []);
      await $.reach($(HomeScreen.addEntryKey(member.projectId)));
      expect($.isEnabled(HomeScreen.addEntryKey(member.projectId)), isFalse);
    });

    phoneCase('redix-api #114: Import settings is gray for everyone', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $.goTo($(HomeScreen.importSettingsKey(manager.projectId)));
      expect($.isEnabled(HomeScreen.importSettingsKey(manager.projectId)), isFalse);
    });
  });
}
