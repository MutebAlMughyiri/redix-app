
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/accounts/account.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/accounts/reconcile_screen.dart';
import 'package:redix/accounts/reconciliation_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/movements_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/ui/bottom_button.dart';

import '../app_harness.dart';


void main() {
  Future<({FakeApi api, FakeCapture capture})> openHome(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة']);
    arrange(api);
    final capture = FakeCapture();
    await openProject(tester, api, capture: capture);
    return (api: api, capture: capture);
  }

  /// Opens Accounts from the home, where the actual balances are since redix-app #89.
  Future<({FakeApi api, FakeCapture capture})> openBalances(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    final opened = await openHome(tester, arrange, permissions: permissions);
    await showProjectSetting(tester, HomeScreen.accountsKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await tester.pumpAndSettle();
    await scrollAndTap(tester, opened.api, HomeScreen.accountsKey('project-0'));
    return opened;
  }

  String details(WidgetTester tester, String id) => tester.widget<Text>(find.byKey(AccountsScreen.detailsKey(id))).data!;

  Future<({FakeApi api, FakeCapture capture})> openPartners(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    final opened = await openHome(tester, arrange, permissions: permissions);
    await scrollAndTap(tester, opened.api, HomeScreen.partnersKey('project-0'));
    return opened;
  }

  Map<String, Object> reconciled(double surplus, double total, {List<Map<String, Object>> balances = const []}) => {
    'at': '2026-11-05T10:00:00Z',
    'surplus': surplus,
    'actualTotal': total,
    'difference': total - surplus,
    'balances': balances,
  };

  Map<String, Object> balanceRow(String id, double books, double actual, {bool wasChecked = true}) => {'accountId': id, 'accountName': id, 'type': 'bank', 'booksBalance': books, 'actualBalance': actual, 'wasChecked': wasChecked};

  testWidgets('AC-N03: the money screens fit a phone 360 points wide, in long names', (tester) async {
    const longName = 'حساب جارٍ باسم طويل جداً في بنك من البنوك المحلية في الرياض';
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('مشروع غصون السادس في شمال مدينة الرياض بالمملكة', permissions: managerAndFinance, units: ['الفلة']);
    api
      ..addAccount('project-0', longName, balance: 9999999.99)
      ..reconciliationAnswer = reconciled(9999999.99, 8888888.88, balances: [balanceRow(longName, 9999999.99, 8888888.88)])
      ..capitalTotal = 9999999.99
      ..addMovement(attachmentId: 'attachment-1', amount: -9999999.99);
    final partner = api.addPartner('project-0', 'متعب بن عبدالله بن محمد المغيري الشريك المؤسس في المشروع', userId: 'user-1', userName: 'نواف بن عبدالله بن محمد العتيبي');
    api.addCapitalLine(partner['id']! as String, 9999999.99, 66.6666666667);
    await openProject(tester, api);

    await scrollAndTap(tester, api, HomeScreen.accountsKey('project-0'));
    expect(find.byKey(ReconciliationCard.differenceKey), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.updateKey)));
    expect(find.byKey(ReconcileScreen.saveKey, skipOffstage: false), findsOneWidget);
    await act(tester, api, () => tester.pageBack());

    await act(tester, api, () => tester.pageBack());

    await scrollAndTap(tester, api, HomeScreen.partnersKey('project-0'));
    expect(find.byKey(PartnersScreen.totalKey), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(PartnersScreen.nameKey(partner['id']! as String))));
    expect(find.byKey(MovementsScreen.rowKey('movement-0')), findsOneWidget);
    await act(tester, api, () => tester.pageBack());
    expect(tester.takeException(), isNull);
  });

  group('UC-041', () {
    testWidgets('AC-24.1: the card shows the surplus, the total, and the difference in brackets', (tester) async {
      await openBalances(tester, (api) {
        api
          ..addAccount('project-0', 'حساب')
          ..reconciliationAnswer = reconciled(1000, 900.75);
      });

      expect(tester.widget<Text>(find.byKey(ReconciliationCard.surplusKey)).data, '1,000.00');
      expect(tester.widget<Text>(find.byKey(ReconciliationCard.actualTotalKey)).data, '900.75');
      expect(tester.widget<Text>(find.byKey(ReconciliationCard.differenceKey)).data, '(99.25)');
    });

    testWidgets('Muteb, 9 Nov 2026: there is no Refresh button, and pulling the actual balances down reads them again', (tester) async {
      final (:api, capture: _) = await openBalances(tester, (api) {
        api
          ..addAccount('project-0', 'حساب')
          ..reconciliationAnswer = reconciled(1000, 900.75);
      });

      api.reconciliationAnswer = reconciled(1000, 950);
      expect(find.byIcon(Icons.refresh), findsNothing);
      await act(tester, api, () => tester.drag(listRows, const Offset(0, 1500)));
      expect(tester.widget<Text>(find.byKey(ReconciliationCard.actualTotalKey)).data, '950.00');

      api.reconciliationAnswer = reconciled(1000, 975);
      await act(tester, api, () => tester.drag(listRows, const Offset(0, 1500)));
      expect(tester.widget<Text>(find.byKey(ReconciliationCard.actualTotalKey)).data, '975.00');
    });

    testWidgets('before any check it says so, and each account shows what it holds with no counted line', (tester) async {
      late String accountId;
      await openBalances(tester, (api) => accountId = api.addAccount('project-0', 'حساب', balance: 500)['id']! as String);

      expect(find.byKey(ReconciliationCard.neverKey), findsOneWidget);
      expect(find.byKey(ReconciliationCard.differenceKey), findsNothing);
      expect(tester.widget<Text>(find.byKey(AccountsScreen.balanceKey(accountId))).data, '500.00');
      expect(details(tester, accountId), isNot(contains('accounts.counted')));
    });

    testWidgets('redix-app #89: each account shows what it holds, and what was counted at the latest check on its line, grouped by type', (tester) async {
      late String bankId;
      late String cashId;
      await openBalances(tester, (api) {
        bankId = api.addAccount('project-0', 'الراجحي', balance: 800)['id']! as String;
        cashId = api.addAccount('project-0', 'عهدة الموقع', type: 'cashCustody', balance: 200)['id']! as String;
        api.reconciliationAnswer = reconciled(1000, 900.75, balances: [balanceRow(bankId, 800, 700.75), balanceRow(cashId, 200, 200)]);
      });

      expect(tester.widget<Text>(find.byKey(AccountsScreen.nameKey(bankId))).data, 'الراجحي');
      expect(tester.widget<Text>(find.byKey(AccountsScreen.balanceKey(bankId))).data, '800.00');
      expect(details(tester, bankId), 'en accounts.typeBank · en accounts.counted');
      expect(tester.widget<Text>(find.byKey(AccountsScreen.balanceKey(cashId))).data, '200.00');
      expect(tester.widget<Icon>(find.byKey(AccountsScreen.rowKey(cashId).icon)).icon, Icons.payments_outlined);
      expect(tester.widget<Text>(find.byKey(AccountsScreen.groupKey(AccountType.bank))).data, 'en accounts.banks');
      expect(tester.widget<Text>(find.byKey(AccountsScreen.groupKey(AccountType.cashCustody))).data, 'en accounts.custodies');
      expect(tester.getTopLeft(find.byKey(AccountsScreen.groupKey(AccountType.cashCustody))).dy, greaterThan(tester.getTopLeft(find.byKey(AccountsScreen.rowKey(bankId))).dy));
    });

    testWidgets('findings row 187: an account the latest check did not hold shows no counted line, and its field starts empty', (tester) async {
      late String checkedId;
      late String addedId;
      final (:api, capture: _) = await openBalances(tester, (api) {
        checkedId = api.addAccount('project-0', 'الراجحي')['id']! as String;
        addedId = api.addAccount('project-0', 'عهدة جديدة', type: 'cashCustody')['id']! as String;
        api.reconciliationAnswer = reconciled(1000, 700, balances: [balanceRow(checkedId, 1000, 700), balanceRow(addedId, 0, 0, wasChecked: false)]);
      });

      expect(details(tester, checkedId), contains('en accounts.counted'));
      expect(details(tester, addedId), isNot(contains('accounts.counted')));

      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.updateKey)));
      expect(tester.widget<TextField>(find.byKey(ReconcileScreen.balanceKey(addedId))).controller!.text, '');
    });

    testWidgets('typing a balance shows the total and the difference, and saving sends each', (tester) async {
      final (:api, capture: _) = await openBalances(tester, (api) {
        api
          ..addAccount('project-0', 'حساب')
          ..reconciliationAnswer = reconciled(1000, 0, balances: [balanceRow('account-a', 800, 0), balanceRow('account-b', 200, 0)]);
      });
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.updateKey)));

      await tester.enterText(find.byKey(ReconcileScreen.balanceKey('account-a')), '٧٠٠');
      await tester.enterText(find.byKey(ReconcileScreen.balanceKey('account-b')), '200.50');
      await tester.pump();

      expect(tester.widget<Text>(find.byKey(ReconcileScreen.differenceKey)).data, contains('(99.50)'));

      await act(tester, api, () => tester.tap(find.byKey(ReconcileScreen.saveKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-0/reconciliations');
      expect(body['balances'], [
        {'accountId': 'account-a', 'actualBalance': 700.0},
        {'accountId': 'account-b', 'actualBalance': 200.5},
      ]);
    });

    testWidgets('a balance left empty stops it before it is sent', (tester) async {
      final (:api, capture: _) = await openBalances(tester, (api) {
        api
          ..addAccount('project-0', 'حساب')
          ..reconciliationAnswer = reconciled(1000, 0, balances: [balanceRow('account-a', 800, 0)]);
      });
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.updateKey)));

      await tester.enterText(find.byKey(ReconcileScreen.balanceKey('account-a')), '');
      await act(tester, api, () => tester.tap(find.byKey(ReconcileScreen.saveKey)));

      expect(find.byKey(ReconcileScreen.messageKey), findsOneWidget);
      expectErrorAbove(tester, ReconcileScreen.messageKey, ReconcileScreen.balanceKey('account-a'));
      expect(api.sentMoney, isEmpty);
    });

    testWidgets('only whoever moves money transfers and enters balances: both bottom buttons are grayed for anyone else, and everyone sees the card', (tester) async {
      await openBalances(tester, (api) => api..addAccount('project-0', 'حساب')..addAccount('project-0', 'كاش'), permissions: field);

      expect(find.byKey(ReconciliationCard.neverKey), findsOneWidget);
      expect(isEnabled(tester, AccountsScreen.updateKey), isFalse);
      expect(isEnabled(tester, AccountsScreen.transferKey), isFalse);
    });

    testWidgets('redix-app #89 R1: Accounts holds the actual balances: the card on top, Transfer and تحديث side by side in its one bottom bar, and the home has no Actual balances button', (tester) async {
      await openBalances(tester, (api) => api..addAccount('project-0', 'حساب')..addAccount('project-0', 'كاش'));

      expect(find.byKey(ReconciliationCard.cardKey), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(AccountsScreen.updateKey.label)).data, 'en accounts.reconcile');
      expect(tester.widget<Text>(find.byKey(AccountsScreen.transferKey.label)).data, 'en transfers.button');
      final bar = find.byKey(BottomButton.barKey);
      expect(find.descendant(of: bar, matching: find.byKey(AccountsScreen.updateKey)), findsOneWidget);
      expect(find.descendant(of: bar, matching: find.byKey(AccountsScreen.transferKey)), findsOneWidget);
      expect(isEnabled(tester, AccountsScreen.transferKey), isTrue);
    });

    testWidgets('redix-app #89: with one active account there is nothing to transfer to, so Transfer is grayed', (tester) async {
      await openBalances(tester, (api) => api..addAccount('project-0', 'حساب')..addAccount('project-0', 'قديم', isActive: false));

      expect(isEnabled(tester, AccountsScreen.transferKey), isFalse);
      expect(isEnabled(tester, AccountsScreen.updateKey), isTrue);
    });
  });

  group('UC-042, UC-043, UC-044', () {
    testWidgets('AC-27.1: each partner shows their balance and a share with ten decimals, under the total', (tester) async {
      late String partner;
      await openPartners(tester, (api) {
        partner = api.addPartner('project-0', 'متعب')['id']! as String;
        api
          ..capitalTotal = 3000
          ..addCapitalLine(partner, 2000, 66.6666666667);
      });

      expect(tester.widget<Text>(find.byKey(PartnersScreen.totalKey)).data, '3,000.00');
      expect(tester.widget<Text>(find.byKey(PartnersScreen.shareKey(partner))).data, '66.6666666667%');
      expect(tester.widget<Text>(find.byKey(PartnersScreen.balanceKey(partner))).data, '2,000.00');
    });

    testWidgets('Muteb, 9 Nov 2026: there is no Refresh button, and pulling the list down reads the capital above the partners again', (tester) async {
      late String partner;
      final (:api, capture: _) = await openPartners(tester, (api) {
        partner = api.addPartner('project-0', 'متعب')['id']! as String;
        api
          ..capitalTotal = 3000
          ..addCapitalLine(partner, 3000, 100);
      });

      api.capitalTotal = 4000;
      expect(find.byIcon(Icons.refresh), findsNothing);
      await act(tester, api, () => tester.drag(listRows, const Offset(0, 1500)));
      expect(tester.widget<Text>(find.byKey(PartnersScreen.totalKey)).data, '4,000.00');

      api.capitalTotal = 5000;
      await act(tester, api, () => tester.drag(listRows, const Offset(0, 1500)));
      expect(tester.widget<Text>(find.byKey(PartnersScreen.totalKey)).data, '5,000.00');
    });

    testWidgets('BR-31: a reader has a way in', (tester) async {
      await openPartners(tester, (api) {
        final partner = api.addPartner('project-0', 'نفسه');
        api.addCapitalLine(partner['id']! as String, 100, 25);
      }, permissions: const ['readProject']);

      expect(find.byKey(PartnersScreen.totalKey), findsOneWidget);
    });

    testWidgets('a partner opens to their movements, each with its receipt', (tester) async {
      late String partner;
      final (:api, capture: _) = await openPartners(tester, (api) {
        partner = api.addPartner('project-0', 'متعب')['id']! as String;
        api
          ..addMovement(attachmentId: 'attachment-1')
          ..addMovement(type: 'withdrawal', amount: -50, cashReason: 'نقداً');
      });

      await act(tester, api, () => tester.tap(find.byKey(PartnersScreen.nameKey(partner))));

      expect(find.byKey(MovementsScreen.rowKey('movement-0')), findsOneWidget);
      expect(find.byKey(MovementsScreen.receiptKey('movement-0')), findsOneWidget);
      expect(find.byKey(MovementsScreen.receiptKey('movement-1')), findsNothing);
      expect(find.byKey(MovementsScreen.rowKey('movement-0').bar), findsNothing);
      expect(tester.widget<Text>(find.byKey(MovementsScreen.rowKey('movement-1').trailing)).data, '(50.00)');
    });

    testWidgets('redix-api #119: whoever holds the removal swipes a movement away, and the capital is read again', (tester) async {
      late String partner;
      final (:api, capture: _) = await openPartners(tester, (api) {
        partner = api.addPartner('project-0', 'متعب')['id']! as String;
        api.addMovement();
      }, permissions: [...managerAndFinance, 'removeApprovedEntries']);
      await act(tester, api, () => tester.tap(find.byKey(PartnersScreen.nameKey(partner))));
      api.sentReads.clear();

      await swipeToRemove(tester, api, MovementsScreen.rowKey('movement-0'));

      expect((api.sentEntryChanges.single.$1, api.sentEntryChanges.single.$2), ('movement-0', 'delete'));
      expect(api.sentReads, contains('/projects/project-0/capital'));
    });
  });
}
