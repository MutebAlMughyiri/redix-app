import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/api.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/entries/entry_link_screen.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/refusal_snack_bar.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/steps.dart';

/// The link a shared [entry] of the project of [person] carries, on the host of the environment the app was built for.
String linkOf(Person person, String entry) => 'https://$linkHost${EntryLinkScreen.pathOf(person.projectId, entry)}';

/// Signs [person] in, opens the entry [entry], taps Share, sends it to Notepad, and answers the text Notepad received.
Future<String> sharedTextOf(PatrolIntegrationTester $, Person person, String entry) async {
  await $.onTheHome(person);
  await $.tapOn(EntriesScreen.rowKey(entry));
  await $.reach($(AddEntryScreen.statusKey));
  await $.tapToThePhone(AddEntryScreen.shareKey);
  return $.textSharedToNotepad();
}

void main() {
  phoneClass('Share an entry (UC-033)', () {
    phoneCase('redix-app #83 R2: an entry\'s sheet shares it as text, one line each, in the app\'s language', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager, amount: 150);
      final text = await sharedTextOf($, manager, entry);
      expect(text.split('\n').length, greaterThan(3));
      expect(text, allOf(contains(manager.projectName), contains('150.00'), contains(linkOf(manager, entry))));
    });

    phoneCase('redix-app #83 R3: every kind shares the same way, leaving out a line it has nothing for', ($) async {
      final manager = await Given.manager();
      final partner = await Given.partner(manager, 'هيثم');
      final entry = await Given.partnerMoney(manager, partner, amount: 700);
      final text = await sharedTextOf($, manager, entry);
      expect(text, allOf(contains('هيثم'), contains('700.00')));
      expect(text, isNot(contains($.words.entrySharePaymentMethod)));
    });

    phoneCase('redix-app #83 R1: once kept, the message offers Share', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.pickTable(table.tableId);
      await $.chooseANewSupplier(manager);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.choosePayment(manager, account);
      await $.sendEntry();
      await $(messageKeyOf('expenses.sent').icon).waitUntilExists();
    });

    phoneCase('redix-app #83 R7: a link for someone who decides opens Approvals on that one entry, the rest one tap away', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      final other = await Given.entry(manager);
      await $.onTheList(manager);
      await Pc.openLink(linkOf(manager, entry));
      await $.reach($(ApprovalsScreen.cardKey(entry)));
      expect($(ApprovalsScreen.cardKey(other)), findsNothing);
      await $.tapOn(ApprovalsScreen.showAllKey);
      await $.reach($(ApprovalsScreen.cardKey(other)));
    });

    phoneCase('redix-app #83 R8: a link for someone who cannot decide opens it read only', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      final member = await Given.member(manager);
      await $.onTheList(member);
      await Pc.openLink(linkOf(member, entry));
      await $.says(AddEntryScreen.statusKey, $.words.entriesPendingApproval);
    });

    phoneCase('redix-app #83 R8: signed out, the link asks to sign in and then opens the entry', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      final member = await Given.member(manager);
      await $.startApp();
      await $.reach($(SignInScreen.usernameKey));
      await Pc.openLink(linkOf(member, entry));
      await $.pumpAndSettle();
      await $.signIn(member.username, member.password);
      await $.says(AddEntryScreen.statusKey, $.words.entriesPendingApproval);
    });

    phoneCase('redix-app #83 R8: signed out with a temporary password, the link opens once it is changed', ($) async {
      final manager = await Given.manager();
      final entry = await Given.entry(manager);
      final member = await Given.member(manager, temporary: true);
      await $.startApp();
      await $.reach($(SignInScreen.usernameKey));
      await Pc.openLink(linkOf(member, entry));
      await $.pumpAndSettle();
      await $.signIn(member.username, member.password);
      await $.reach($(ChangePasswordScreen.currentKey));
      final chosen = 'Chosen-${Given.unique()}';
      await $(ChangePasswordScreen.currentKey).enterText(member.password);
      await $(ChangePasswordScreen.newKey).enterText(chosen);
      await $(ChangePasswordScreen.confirmKey).enterText(chosen);
      await $.tapOn(ChangePasswordScreen.submitKey);
      await $.says(AddEntryScreen.statusKey, $.words.entriesPendingApproval);
    });

    phoneCase('redix-app #83 R1: an entry kept only on the phone offers no Share', ($) async {
      final manager = await Given.manager();
      final table = await Given.firstPurchaseTable(manager);
      final account = await Given.account(manager);
      await $.onAddEntry(manager);
      await $.pickTable(table.tableId);
      await $.chooseANewSupplier(manager);
      await $.fill(AddEntryScreen.amountKey, '100');
      await $.tapOn(PaymentChoices.paymentMethodKey((await Given.paymentMethods(manager)).first['id'] as String));
      await $.tapOn(PaymentChoices.accountKey(account));
      await Pc.cutNetwork();
      await $.sendEntry();
      await $.messageShows('expenses.keptOnPhone');
      expect($(messageKeyOf('expenses.keptOnPhone').icon), findsNothing);
    });

    phoneCase('redix-app #83 R9: the link of an entry no longer listed says it cannot be found', ($) async {
      final manager = await Given.manager();
      await $.onTheList(manager);
      await Pc.openLink(linkOf(manager, '01900000-0000-7000-8000-000000000000'));
      await $.says(EntryLinkScreen.notFoundKey, $.words.entriesNotFound);
    });

    phoneCase('redix-app #83 R9: the link of a project the reader is not in says it cannot be found', ($) async {
      final other = await Given.manager();
      final entry = await Given.entry(other);
      final manager = await Given.manager();
      await $.onTheList(manager);
      await Pc.openLink(linkOf(other, entry));
      await $.says(EntryLinkScreen.notFoundKey, $.words.entriesNotFound);
    });
  });
}
