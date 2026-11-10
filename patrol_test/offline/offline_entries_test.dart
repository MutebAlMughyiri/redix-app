import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/offline/waiting_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// What every case here needs: a manager, an account, and a purchase table.
Future<({Person manager, String account, String tableId, String supplier})> project() async {
  final manager = await Given.manager();
  final account = await Given.account(manager);
  return (manager: manager, account: account, tableId: (await Given.firstPurchaseTable(manager)).tableId, supplier: await Given.supplier(manager));
}

/// With the network cut, fills in a purchase and sends it, keeping it on the phone.
Future<void> keepOnPhone(PatrolIntegrationTester $, ({Person manager, String account, String tableId, String supplier}) made, {String amount = '100'}) async {
  await $.reach($(HomeScreen.addEntryKey(made.manager.projectId)));
  await $(HomeScreen.addEntryKey(made.manager.projectId)).tap();
  await $.pickTable(made.tableId);
  await $.chooseSupplier(made.supplier);
  await $.fill(AddEntryScreen.amountKey, amount);
  await $.choosePayment(made.manager, made.account, methodId: methods.first);
  await $.sendEntry();
  await $.messageShows('expenses.keptOnPhone');
}

/// The payment methods a case read before the network was cut.
var methods = <String>[];

/// Signs the manager in, reads what Add entry needs while there is a network, and stands on the home.
Future<void> readyOnTheHome(PatrolIntegrationTester $, ({Person manager, String account, String tableId, String supplier}) made) async {
  methods = [for (final method in await Given.paymentMethods(made.manager)) method['id'] as String];
  await $.onTheHome(made.manager);
  await $.tapOn(HomeScreen.addEntryKey(made.manager.projectId));
  await $.pickTable(made.tableId);
  await $.chooseSupplier(made.supplier);
  await $.goTo($(PaymentChoices.accountKey(made.account)));
  await $.back();
  await $.reach($(HomeScreen.titleKey));
}

void main() {
  phoneClass('Entries with no network (UC-029)', () {
    phoneCase('without a network an entry is kept, whatever its table, and the person is told', ($) async {
      final made = await project();
      await readyOnTheHome($, made);
      await Pc.cutNetwork();
      await keepOnPhone($, made);
      await $.reach($(HomeScreen.waitingKey(made.manager.projectId)));
      await Pc.restoreNetwork();
    });

    phoneCase('AC-16.1: five expenses go within a minute of the network returning', ($) async {
      final made = await project();
      await readyOnTheHome($, made);
      await Pc.cutNetwork();
      for (var entry = 1; entry <= 5; entry++) {
        await keepOnPhone($, made, amount: '$entry');
      }
      await Pc.restoreNetwork();
      await $.tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      await $.pullDown();
      var sent = <String>[];
      for (var tries = 0; tries < 30 && sent.length < 5; tries++) {
        await $.tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
        await $.pump();
        sent = await Given.waitingIds(made.manager);
      }
      expect(sent, hasLength(5));
    });

    phoneCase('FR-16: a list read once answers with no network', ($) async {
      final made = await project();
      final name = 'Supplier ${Given.unique()}';
      await Given.supplier(made.manager, name: name);
      await $.onTheHome(made.manager);
      await $.tapOn(HomeScreen.suppliersKey(made.manager.projectId));
      await $.idShowing('suppliers.name.', name);
      await $.back();
      await Pc.cutNetwork();
      await $.tapOn(HomeScreen.suppliersKey(made.manager.projectId));
      await $.idShowing('suppliers.name.', name);
    });

    phoneCase('opening a project keeps every list the sync answers', ($) async {
      final made = await project();
      await readyOnTheHome($, made);
      await Pc.cutNetwork();
      await $.tapOn(HomeScreen.accountsKey(made.manager.projectId));
      await $(keyStartingWith('accounts.name.')).waitUntilExists();
    });

    phoneCase('a typed search looks in what was kept, whichever way the name is spelled', ($) async {
      final made = await project();
      final supplier = await Given.supplier(made.manager, name: 'أحمد للمقاولات');
      await readyOnTheHome($, made);
      await $.tapOn(HomeScreen.addEntryKey(made.manager.projectId));
      await $.tapOn(AddEntryScreen.supplierKey);
      await $.reach($(SupplierPicker.rowKey(supplier)));
      await $.tapOn(SupplierPicker.closeKey);
      await Pc.cutNetwork();
      await $.tapOn(AddEntryScreen.supplierKey);
      await $(SupplierPicker.searchKey).enterText('احمد');
      await $.reach($(SupplierPicker.rowKey(supplier)));
    });

    phoneCase('what waits survives a sign-out', ($) async {
      final made = await project();
      await readyOnTheHome($, made);
      await Pc.cutNetwork();
      await keepOnPhone($, made);
      await $.signOutFromTheHome(made.manager.projectId);
      await $.reach($(SignInScreen.usernameKey));
      await Pc.restoreNetwork();
      await $.signIn(made.manager.username, made.manager.password);
      await $.openProject(made.manager.projectId);
      await $.until(() => find.byKey(HomeScreen.waitingKey(made.manager.projectId)).evaluate().isEmpty);
      await $.pullDown();
      await $.tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      expect(await Given.waitingIds(made.manager), hasLength(1));
    });

    phoneCase('signing out forgets what was kept of the lists', ($) async {
      final made = await project();
      await readyOnTheHome($, made);
      await $.signOutFromTheHome(made.manager.projectId);
      await $.reach($(SignInScreen.usernameKey));
      final other = await Given.manager();
      await $.signIn(other.username, other.password);
      await $.reach($(ProjectsScreen.cardKey(other.projectId)));
      expect($(ProjectsScreen.cardKey(made.manager.projectId)), findsNothing);
    });

    phoneCase('what someone else entered neither shows nor goes', ($) async {
      final made = await project();
      final other = await otherPerson(made.manager);
      await readyOnTheHome($, made);
      await Pc.cutNetwork();
      await keepOnPhone($, made);
      await $.signOutFromTheHome(made.manager.projectId);
      await $.reach($(SignInScreen.usernameKey));
      await Pc.restoreNetwork();
      await $.signIn(other.username, other.password);
      await $.openProject(other.projectId);
      await $.pumpAndSettle();
      expect($(HomeScreen.waitingKey(other.projectId)), findsNothing);
      expect(await Given.waitingIds(made.manager), isEmpty);
    });

    phoneCase('an entry the API refuses waits for its author, and is not tried again', ($) async {
      final made = await project();
      await readyOnTheHome($, made);
      await Given.supplierDisabled(made.manager, made.supplier);
      await Pc.cutNetwork();
      await keepOnPhone($, made);
      await Pc.restoreNetwork();
      await $.pullDown();
      await $.tapOn(HomeScreen.waitingKey(made.manager.projectId));
      final row = $(keyStartingWith('waiting.state.'));
      await row.waitUntilExists();
      expect(row, findsOneWidget);
    });

    phoneCase('AC-16.2: a change made offline that arrives after approval says it was not applied', ($) async {
      final made = await project();
      final entry = await Given.entry(made.manager, sent: false, accountId: made.account);
      await readyOnTheHome($, made);
      await $.tapOn(EntriesScreen.rowKey(entry));
      await $.tapOn(AddEntryScreen.changeKey);
      await $.fill(AddEntryScreen.amountKey, '175');
      await Pc.cutNetwork();
      await $.sendEntry();
      await $.messageShows('expenses.keptOnPhone');
      await Pc.restoreNetwork();
      await Given.submitted(made.manager, entry);
      await Given.entriesApproved(made.manager, [entry]);
      await $.pullDown();
      await $.tapOn(HomeScreen.waitingKey(made.manager.projectId));
      await $.says(WaitingScreen.stateKey(entry), $.words.expensesEntryApproved);
    });
  });
}

/// Someone else in the project of [manager] who may enter expenses.
Future<Person> otherPerson(Person manager) => Given.member(manager, permissions: [Permission.recordEntries]);

