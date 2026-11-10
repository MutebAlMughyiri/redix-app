import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/accounts/account.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/member_picker.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
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

/// Fills in the dialog of a new bank account.
Future<void> fillBank(PatrolIntegrationTester $, String name, String opening) async {
  await $.tapOn(AccountsScreen.addKey);
  await $.reach($(AccountsScreen.accountNameKey));
  await $(AccountsScreen.accountNameKey).enterText(name);
  await $(AccountsScreen.openingBalanceKey).enterText(opening);
}

/// The line under the account [id].
String detailsOf(PatrolIntegrationTester $, String id) => $.tester.widget<Text>(find.byKey(AccountsScreen.detailsKey(id))).data!;

void main() {
  phoneClass('Accounts (UC-015)', () {
    phoneCase('NFR-04: a bank account is added with its opening balance, shown with separators and two decimals', ($) async {
      final manager = await Given.manager();
      await onAccounts($, manager);
      await fillBank($, 'حساب المؤسسة', '64250.75');
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('accounts.name.', 'حساب المؤسسة');
      await $.says(AccountsScreen.balanceKey(id), '64,250.75');
    });

    phoneCase('a cash account is added with its custodian', ($) async {
      final manager = await Given.manager(project: 'غصون 7', manager: 'ريم');
      await Given.account(manager, name: 'حساب المؤسسة', opening: 64250.75);
      await onAccounts($, manager);
      await $.tapOn(AccountsScreen.addKey);
      await $(AccountsScreen.typeKey(AccountType.cashCustody)).tap();
      await $(AccountsScreen.accountNameKey).enterText('كاش مع مدير المشروع');
      await $(AccountsScreen.openingBalanceKey).enterText('2750');
      await $.tester.ensureVisible(find.byKey(MemberPicker.optionKey(manager.id)));
      await $.pumpAndSettle();
      await $(MemberPicker.optionKey(manager.id)).tap();
      await $.pumpAndSettle();
      await $.picture('account-dialog');
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('accounts.name.', 'كاش مع مدير المشروع');
      await $.says(AccountsScreen.balanceKey(id), '2,750.00');
      await $.picture('accounts');
    });

    phoneCase('an account is added while the app is in Arabic', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await $(ProjectsScreen.settingsKey).tap();
      await $.goTo($(LanguageSwitch.arabicKey));
      await $(LanguageSwitch.arabicKey).tap();
      await $.until(() => Directionality.of($.tester.element(find.byKey(SettingsScreen.languageKey))) == TextDirection.rtl);
      await $.tapOn(SettingsScreen.switchProjectKey);
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.accountsKey(manager.projectId));
      await fillBank($, 'حساب الموقع', '٥٠٠');
      await $(ChangeDialog.saveKey).tap();
      final id = await $.idShowing('accounts.name.', 'حساب الموقع');
      await $.says(AccountsScreen.balanceKey(id), '500.00');
    });

    phoneCase('each account shows its type, who holds it and what it holds', ($) async {
      final manager = await Given.manager(manager: 'ريم');
      final custody = await Given.account(manager, opening: 300, custodian: manager);
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
      final account = await Given.account(manager, name: 'حساب المؤسسة', opening: 500);
      await onAccounts($, manager);
      await $.menuChoice(AccountsScreen.menuKey(account), AccountsScreen.editKey);
      await $.reach($(AccountsScreen.accountNameKey));
      expect($.typed(AccountsScreen.accountNameKey), 'حساب المؤسسة');
      expect($.typed(AccountsScreen.openingBalanceKey), contains('500'));
      await $(AccountsScreen.accountNameKey).enterText('حساب جديد');
      await $(ChangeDialog.saveKey).tap();
      await $.says(AccountsScreen.nameKey(account), 'حساب جديد');
    });

    phoneCase('choosing nobody leaves the account with no custodian', ($) async {
      final manager = await Given.manager(manager: 'ريم');
      await onAccounts($, manager);
      await fillBank($, 'حساب بلا عهدة', '0');
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
      final account = await Given.account(manager, opening: 1000);
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

    phoneCase('an opening balance cannot change once the account has entries, and the dialog says so', ($) async {
      final manager = await Given.manager();
      final account = await Given.account(manager, opening: 100);
      await Given.entry(manager, accountId: account);
      await onAccounts($, manager);
      await $.menuChoice(AccountsScreen.menuKey(account), AccountsScreen.editKey);
      await $.reach($(AccountsScreen.openingBalanceKey));
      await $(AccountsScreen.openingBalanceKey).enterText('900');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.accountsAccountHasEntries);
    });

    phoneCase('an opening balance that is not a number is refused without asking the API', ($) async {
      final manager = await Given.manager();
      await onAccounts($, manager);
      await fillBank($, 'حساب', 'abc');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.accountsInvalidOpeningBalance);
    });

    phoneCase('a refusal stays in the dialog', ($) async {
      final manager = await Given.manager();
      await onAccounts($, manager);
      await $.tapOn(AccountsScreen.addKey);
      await $(AccountsScreen.typeKey(AccountType.cashCustody)).tap();
      await $(AccountsScreen.accountNameKey).enterText('كاش');
      await $(AccountsScreen.openingBalanceKey).enterText('0');
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
