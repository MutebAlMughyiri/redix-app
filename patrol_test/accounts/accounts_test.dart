import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/accounts/account.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/member_picker.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/general_settings_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/words/language_switch.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Accounts.
Future<void> onAccounts(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.accountsKey(person.projectId));
  await $.reach($(AccountsScreen.addKey));
}

/// Fills in the dialog of a new bank account, which asks no balance (redix-app #89).
Future<void> fillBank(PatrolIntegrationTester $, String name) async {
  await $.tapOn(AccountsScreen.addKey);
  await $.reach($(AccountsScreen.accountNameKey));
  await $(AccountsScreen.accountNameKey).enterText(name);
}

/// The line under the account [id].
String detailsOf(PatrolIntegrationTester $, String id) => $.tester.widget<Text>(find.byKey(AccountsScreen.detailsKey(id))).data!;

void main() {
  phoneClass('Accounts (UC-015)', () {
    phoneCase('redix-app #89 R10: a bank account is added holding nothing, and the money that comes in shows with separators and two decimals (NFR-04)', ($) async {
      final manager = await Given.manager();
      await onAccounts($, manager);
      await fillBank($, 'حساب المؤسسة');
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('accounts.name.', 'حساب المؤسسة');
      await $.says(AccountsScreen.balanceKey(id), '0.00');
      await Given.funded(manager, id, 64250.75);
      await $.pullDown();
      await $.says(AccountsScreen.balanceKey(id), '64,250.75');
    });

    phoneCase('a cash account is added with its custodian', ($) async {
      final manager = await Given.manager(project: 'غصون 7', manager: 'ريم');
      await Given.funded(manager, await Given.account(manager, name: 'حساب المؤسسة'), 64250.75);
      await onAccounts($, manager);
      await $.tapOn(AccountsScreen.addKey);
      await $(AccountsScreen.typeKey(AccountType.cashCustody)).tap();
      await $(AccountsScreen.accountNameKey).enterText('كاش مع مدير المشروع');
      await $.chooseMember(AccountsScreen.custodianKey, manager.id);
      await $.picture('account-dialog');
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('accounts.name.', 'كاش مع مدير المشروع');
      await Given.funded(manager, id, 2750);
      await $.pullDown();
      await $.says(AccountsScreen.balanceKey(id), '2,750.00');
      await $.picture('accounts');
    });

    phoneCase('an account is added while the app is in Arabic', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await $(ProjectsScreen.generalSettingsKey).tap();
      await $.goTo($(LanguageSwitch.arabicKey));
      await $(LanguageSwitch.arabicKey).tap();
      await $.until(() => Directionality.of($.tester.element(find.byKey(GeneralSettingsScreen.languageKey))) == TextDirection.rtl);
      await $.tapOn(GeneralSettingsScreen.switchProjectKey);
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.accountsKey(manager.projectId));
      await fillBank($, 'حساب الموقع');
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('accounts.name.', 'حساب الموقع');
      await $.says(AccountsScreen.balanceKey(id), '0.00');
    });

    phoneCase('each account shows its type, who holds it and what it holds', ($) async {
      final manager = await Given.manager(manager: 'ريم');
      final custody = await Given.account(manager, custodian: manager);
      await Given.funded(manager, custody, 300);
      await onAccounts($, manager);
      await $.reach($(AccountsScreen.detailsKey(custody)));
      expect(detailsOf($, custody), allOf(contains($.words.accountsTypeCashCustody), contains('ريم')));
      await $.says(AccountsScreen.balanceKey(custody), '300.00');
    });

    phoneCase('NFR-04: a negative balance shows in brackets', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await Given.entriesApproved(manager, [await Given.entry(manager, accountId: account)]);
      await onAccounts($, manager);
      await $.says(AccountsScreen.balanceKey(account), '(100.00)');
    });

    phoneCase('editing starts from the account', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager, name: 'حساب المؤسسة');
      await onAccounts($, manager);
      await $.menuChoice(AccountsScreen.menuKey(account), AccountsScreen.editKey);
      await $.reach($(AccountsScreen.accountNameKey));
      expect($.typed(AccountsScreen.accountNameKey), 'حساب المؤسسة');
      await $(AccountsScreen.accountNameKey).enterText('حساب جديد');
      await $(ChangeDialog.saveKey).tap();
      await $.says(AccountsScreen.nameKey(account), 'حساب جديد');
    });

    phoneCase('choosing nobody leaves the account with no custodian', ($) async {
      final manager = await Given.manager(manager: 'ريم');
      await onAccounts($, manager);
      await fillBank($, 'حساب بلا عهدة');
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('accounts.name.', 'حساب بلا عهدة');
      expect(detailsOf($, id), isNot(contains('ريم')));
    });

    phoneCase('a custodian who left the project stays on offer until changed', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      final custody = await Given.account(manager, custodian: member);
      await Given.removed(member, by: manager);
      await onAccounts($, manager);
      await $.menuChoice(AccountsScreen.menuKey(custody), AccountsScreen.editKey);
      await $(MemberPicker.optionKey(member.id)).waitUntilExists();
    });

    phoneCase('BR-15: disabled, it says so on the row, and Enable brings it back', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await onAccounts($, manager);
      await $.menuChoice(AccountsScreen.menuKey(account), AccountsScreen.disableKey);
      await $.until(() => detailsOf($, account).contains($.words.accountsDisabled));
      expect(detailsOf($, account), contains($.words.accountsDisabled));
      await $.menuChoice(AccountsScreen.menuKey(account), AccountsScreen.enableKey);
      await $.until(() => !detailsOf($, account).contains($.words.accountsDisabled));
      expect(detailsOf($, account), isNot(contains($.words.accountsDisabled)));
    });

    phoneCase('its balance follows an approved entry paid from it', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await Given.funded(manager, account, 1000);
      await Given.entriesApproved(manager, [await Given.entry(manager, accountId: account, amount: 250)]);
      await onAccounts($, manager);
      await $.says(AccountsScreen.balanceKey(account), '750.00');
    });

    phoneCase('an account\'s type cannot change when editing', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await onAccounts($, manager);
      await $.menuChoice(AccountsScreen.menuKey(account), AccountsScreen.editKey);
      await $.reach($(AccountsScreen.accountNameKey));
      expect($(AccountsScreen.typeKey(AccountType.cashCustody)), findsNothing);
    });

    phoneCase('redix-app #89 R10: neither adding nor editing asks a balance', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      await onAccounts($, manager);
      await fillBank($, 'حساب');
      expect($(TextField), findsOneWidget);
      await $(ChangeDialog.cancelKey).tap();
      await $.menuChoice(AccountsScreen.menuKey(account), AccountsScreen.editKey);
      await $.reach($(AccountsScreen.accountNameKey));
      expect($(TextField), findsOneWidget);
    });

    phoneCase('a refusal stays in the dialog', ($) async {
      final manager = await Given.manager();
      await onAccounts($, manager);
      await $.tapOn(AccountsScreen.addKey);
      await $(AccountsScreen.typeKey(AccountType.cashCustody)).tap();
      await $(AccountsScreen.accountNameKey).enterText('كاش');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.accountsCustodianRequired);
      expect($(AccountsScreen.accountNameKey), findsOneWidget);
    });

    phoneCase('AC-22.1: without manageSettings the accounts show with nothing to change', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager);
      final member = await Given.member(manager);
      await onAccounts($, member);
      await $.reach($(AccountsScreen.nameKey(account)));
      expect($.isEnabled(AccountsScreen.addKey), isFalse);
      expect($(AccountsScreen.menuKey(account)), findsNothing);
    });

    phoneCase('a list that cannot be read says so', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await Pc.cutNetwork();
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.accountsKey(manager.projectId));
      await $.says(ApiListBody.messageKey, $.words.accountsLoadFailed);
    });
  });
}
