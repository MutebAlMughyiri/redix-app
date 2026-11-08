
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/accounts/reconcile_screen.dart';
import 'package:redix/accounts/reconciliation_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/movements_screen.dart';
import 'package:redix/partners/partners_screen.dart';

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

  Future<({FakeApi api, FakeCapture capture})> openAccounts(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    final opened = await openHome(tester, arrange, permissions: permissions);
    await act(tester, opened.api, () => tester.tap(find.byKey(HomeScreen.accountsKey('project-0'))));
    return opened;
  }

  Future<({FakeApi api, FakeCapture capture})> openPartners(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = managerAndFinance}) async {
    final opened = await openHome(tester, arrange, permissions: permissions);
    await act(tester, opened.api, () => tester.tap(find.byKey(HomeScreen.partnersKey('project-0'))));
    return opened;
  }

  Map<String, Object> reconciled(double surplus, double total, {List<Map<String, Object>> balances = const []}) => {
    'at': '2026-11-05T10:00:00Z',
    'surplus': surplus,
    'actualTotal': total,
    'difference': total - surplus,
    'balances': balances,
  };

  Map<String, Object> balanceRow(String id, double books, double actual) => {'accountId': id, 'accountName': id, 'type': 'bank', 'booksBalance': books, 'actualBalance': actual};

  testWidgets('AC-N03: the money screens fit a phone 360 points wide, in long names', (tester) async {
    const longName = 'حساب جارٍ باسم طويل جداً في بنك من البنوك المحلية في الرياض';
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('مشروع غصون السادس في شمال مدينة الرياض بالمملكة', permissions: managerAndFinance, units: ['الفلة']);
    api
      ..addAccount('project-0', longName, openingBalance: 9999999.99)
      ..reconciliationAnswer = reconciled(9999999.99, 8888888.88, balances: [balanceRow(longName, 9999999.99, 8888888.88)])
      ..capitalTotal = 9999999.99
      ..addMovement(attachmentId: 'attachment-1', amount: -9999999.99);
    final partner = api.addPartner('project-0', 'متعب بن عبدالله بن محمد المغيري الشريك المؤسس في المشروع', userId: 'user-1', userName: 'نواف بن عبدالله بن محمد العتيبي');
    api.addCapitalLine(partner['id']! as String, 9999999.99, 66.6666666667);
    await openProject(tester, api);
    final project = find.byKey(HomeScreen.accountsKey('project-0'));

    await tester.ensureVisible(project);
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(project));
    expect(find.byKey(ReconciliationCard.differenceKey), findsOneWidget);

    await tester.ensureVisible(find.byKey(AccountsScreen.reconcileKey));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.reconcileKey)));
    expect(find.byKey(ReconcileScreen.saveKey, skipOffstage: false), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    final partners = find.byKey(HomeScreen.partnersKey('project-0'));
    await tester.ensureVisible(partners);
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(partners));
    expect(find.byKey(PartnersScreen.totalKey), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(PartnersScreen.nameKey(partner['id']! as String))));
    expect(find.byKey(MovementsScreen.rowKey('movement-0')), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    expect(tester.takeException(), isNull);
  });

  group('UC-041', () {
    testWidgets('AC-24.1: the card shows the surplus, the total, and the difference in brackets', (tester) async {
      await openAccounts(tester, (api) {
        api
          ..addAccount('project-0', 'حساب')
          ..reconciliationAnswer = reconciled(1000, 900.75);
      });

      expect(tester.widget<Text>(find.byKey(ReconciliationCard.surplusKey)).data, '1,000.00');
      expect(tester.widget<Text>(find.byKey(ReconciliationCard.actualTotalKey)).data, '900.75');
      expect(tester.widget<Text>(find.byKey(ReconciliationCard.differenceKey)).data, '(99.25)');
    });

    testWidgets('before any check it says so', (tester) async {
      await openAccounts(tester, (api) => api.addAccount('project-0', 'حساب'));

      expect(find.byKey(ReconciliationCard.neverKey), findsOneWidget);
      expect(find.byKey(ReconciliationCard.differenceKey), findsNothing);
    });

    testWidgets('typing a balance shows the total and the difference, and saving sends each', (tester) async {
      final (:api, capture: _) = await openAccounts(tester, (api) {
        api
          ..addAccount('project-0', 'حساب')
          ..reconciliationAnswer = reconciled(1000, 0, balances: [balanceRow('account-a', 800, 0), balanceRow('account-b', 200, 0)]);
      });
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.reconcileKey)));

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
      final (:api, capture: _) = await openAccounts(tester, (api) {
        api
          ..addAccount('project-0', 'حساب')
          ..reconciliationAnswer = reconciled(1000, 0, balances: [balanceRow('account-a', 800, 0)]);
      });
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.reconcileKey)));

      await tester.enterText(find.byKey(ReconcileScreen.balanceKey('account-a')), '');
      await act(tester, api, () => tester.tap(find.byKey(ReconcileScreen.saveKey)));

      expect(find.byKey(ReconcileScreen.messageKey), findsOneWidget);
      expect(api.sentMoney, isEmpty);
    });

    testWidgets('only whoever moves money enters balances, and everyone sees the card', (tester) async {
      await openAccounts(tester, (api) => api.addAccount('project-0', 'حساب'), permissions: field);

      expect(find.byKey(ReconciliationCard.neverKey), findsOneWidget);
      expect(find.byKey(AccountsScreen.reconcileKey), findsNothing);
    });

    testWidgets('transfers between accounts are gone: Accounts offers only the actual balances (Muteb, 8 Nov 2026)', (tester) async {
      await openAccounts(tester, (api) => api.addAccount('project-0', 'حساب'));

      expect(find.byKey(AccountsScreen.reconcileKey), findsOneWidget);
      expect(find.byKey(const Key('accounts.transfer')), findsNothing);
      expect(find.byKey(const Key('accounts.transfersHeading')), findsNothing);
    });
  });

  group('UC-042, UC-043, UC-044', () {
    testWidgets('AC-27.1: each partner shows their balance and a share with ten decimals, under the total', (tester) async {
      await openPartners(tester, (api) {
        final partner = api.addPartner('project-0', 'متعب');
        api
          ..capitalTotal = 3000
          ..addCapitalLine(partner['id']! as String, 2000, 66.6666666667);
      });

      expect(tester.widget<Text>(find.byKey(PartnersScreen.totalKey)).data, '3,000.00');
      expect(find.text('66.6666666667%'), findsOneWidget);
      expect(find.text('2,000.00'), findsOneWidget);
    });

    testWidgets('BR-31: a reader has a way in', (tester) async {
      await openPartners(tester, (api) {
        final partner = api.addPartner('project-0', 'نفسه');
        api.addCapitalLine(partner['id']! as String, 100, 25);
      }, permissions: const ['readProject']);

      expect(find.byKey(PartnersScreen.totalKey), findsOneWidget);
    });

    testWidgets('someone who withdrew says so', (tester) async {
      await openPartners(tester, (api) {
        final partner = api.addPartner('project-0', 'هيثم');
        api.addCapitalLine(partner['id']! as String, 0, 0, isActive: false);
      });

      expect(find.textContaining('en capital.left'), findsOneWidget);
    });

    testWidgets('a partner opens to their movements, each with its receipt, and Finance can reverse one', (tester) async {
      final (:api, capture: _) = await openPartners(tester, (api) {
        api
          ..addPartner('project-0', 'متعب')
          ..addMovement(attachmentId: 'attachment-1')
          ..addMovement(type: 'withdrawal', amount: -50, cashReason: 'نقداً', isReversed: true);
      });

      await act(tester, api, () => tester.tap(find.text('متعب')));

      expect(find.byKey(MovementsScreen.rowKey('movement-0')), findsOneWidget);
      expect(find.byKey(MovementsScreen.receiptKey('movement-0')), findsOneWidget);
      expect(find.byKey(MovementsScreen.reverseKey('movement-0')), findsOneWidget);
      expect(find.byKey(MovementsScreen.receiptKey('movement-1')), findsNothing);
      expect(find.byKey(MovementsScreen.reverseKey('movement-1')), findsNothing);
      expect(find.text('(50.00)'), findsOneWidget);
    });
  });
}
