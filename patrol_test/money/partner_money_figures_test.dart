import 'package:patrol/patrol.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/money_steps.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Signs [person] in and opens Partners.
Future<void> onPartners(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.partnersKey(person.projectId));
  await $.reach($(PartnersScreen.addKey));
}

/// Money of the partner [partner], approved.
Future<String> approvedMoney(Person manager, String partner, num amount, {bool withdrawal = false, String accountId = ''}) async {
  final entry = await Given.partnerMoney(manager, partner, amount: amount, withdrawal: withdrawal, accountId: accountId);
  await Given.entriesApproved(manager, [entry]);
  return entry;
}

void main() {
  phoneClass('A partner\'s money in the figures (BR-05 and BR-06)', () {
    phoneCase('BR-06: a contribution entered on the phone waits and moves nothing, and approving it raises the capital, the revenue, the surplus and the account', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.pickTable(partner, search: 'هيثم');
      await $.fill(AddEntryScreen.amountKey, '5000');
      await $.tapOn(PaymentChoices.accountKey(account));
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      await $.revenueWaiting(1, '5,000.00');
      await $.homeFigures(surplus: '0.00', revenue: '0.00', expenses: '0.00');
      await $.approveOnThePhone(manager, (await Given.waitingIds(manager)).single);
      await $.homeFigures(surplus: '5,000.00', revenue: '5,000.00', expenses: '0.00');
      await $.tapOn(HomeScreen.partnersKey(manager.projectId));
      await $.reach($(PartnersScreen.addKey));
      await $.says(PartnersScreen.totalKey, '5,000.00');
      await $.says(PartnersScreen.balanceKey(partner), '5,000.00');
      await $.says(PartnersScreen.shareKey(partner), '100.0000000000%');
      await $.back();
      await $.accountStands(manager, account, '5,000.00');
    });

    phoneCase('BR-05: a withdrawal lowers the capital, the revenue, the surplus and the account', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      final account = await Given.account(manager);
      await approvedMoney(manager, partner, 1000, accountId: account);
      await approvedMoney(manager, partner, 300, withdrawal: true, accountId: account);
      await onPartners($, manager);
      await $.says(PartnersScreen.totalKey, '700.00');
      await $.says(PartnersScreen.balanceKey(partner), '700.00');
      await $.back();
      await $.homeFigures(surplus: '700.00', revenue: '700.00', expenses: '0.00');
      await $.accountStands(manager, account, '700.00');
    });

    phoneCase('BR-10: money waiting leaves the partner\'s balance alone', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      await approvedMoney(manager, partner, 1000);
      await Given.partnerMoney(manager, partner, amount: 500);
      await onPartners($, manager);
      await $.says(PartnersScreen.balanceKey(partner), '1,000.00');
      await $.back();
      await $.homeFigures(surplus: '1,000.00', revenue: '1,000.00', expenses: '0.00');
      await $.revenueWaiting(1, '500.00');
    });

    phoneCase('a withdrawal waiting shows as less revenue waiting', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      await approvedMoney(manager, partner, 1000);
      await Given.partnerMoney(manager, partner, amount: 700, withdrawal: true);
      await $.onTheHome(manager);
      await $.homeFigures(surplus: '1,000.00', revenue: '1,000.00', expenses: '0.00');
      await $.revenueWaiting(1, '(700.00)');
    });

    phoneCase('BR-10: rejected money counts nowhere', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      await approvedMoney(manager, partner, 1000);
      await Given.entryRejected(manager, await Given.partnerMoney(manager, partner, amount: 500));
      await onPartners($, manager);
      await $.says(PartnersScreen.balanceKey(partner), '1,000.00');
      await $.back();
      await $.homeFigures(surplus: '1,000.00', revenue: '1,000.00', expenses: '0.00');
      await $.nothingWaits();
    });

    phoneCase('AC-50.1: a removed withdrawal puts the balance, the surplus and the account back', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      final account = await Given.account(manager);
      await approvedMoney(manager, partner, 1000, accountId: account);
      await Given.entryRemoved(manager, await approvedMoney(manager, partner, 300, withdrawal: true, accountId: account));
      await onPartners($, manager);
      await $.says(PartnersScreen.balanceKey(partner), '1,000.00');
      await $.back();
      await $.homeFigures(surplus: '1,000.00', revenue: '1,000.00', expenses: '0.00');
      await $.accountStands(manager, account, '1,000.00');
    });

    phoneCase('each partner\'s share is their balance over the total', ($) async {
      final manager = await Given.manager();
      final first = await Given.partner(manager, 'هيثم');
      final second = await Given.partner(manager, 'نواف');
      await approvedMoney(manager, first, 1000);
      await approvedMoney(manager, second, 3000);
      await onPartners($, manager);
      await $.says(PartnersScreen.totalKey, '4,000.00');
      await $.says(PartnersScreen.shareKey(first), '25.0000000000%');
      await $.says(PartnersScreen.shareKey(second), '75.0000000000%');
    });

    phoneCase('a withdrawal changes every partner\'s share', ($) async {
      final manager = await Given.manager();
      final first = await Given.partner(manager, 'هيثم');
      final second = await Given.partner(manager, 'نواف');
      await approvedMoney(manager, first, 1000);
      await approvedMoney(manager, second, 3000);
      await approvedMoney(manager, second, 1000, withdrawal: true);
      await onPartners($, manager);
      await $.says(PartnersScreen.totalKey, '3,000.00');
      await $.says(PartnersScreen.shareKey(first), '33.3333333333%');
      await $.says(PartnersScreen.shareKey(second), '66.6666666667%');
    });
  });
}
