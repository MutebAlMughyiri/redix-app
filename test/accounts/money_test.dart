import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/accounts/reconcile_screen.dart';
import 'package:redix/accounts/reconciliation_card.dart';
import 'package:redix/accounts/transfer_screen.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/entries/reverse_sheet.dart';
import 'package:redix/expenses/add_expense_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/capital_move_screen.dart';
import 'package:redix/partners/movements_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/sharing/share_screen.dart';

import '../app_harness.dart';

PickedFile _picture() => PickedFile('receipt.png', '', Uint8List.fromList(onePixelPng));

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

  Map<String, Object> reconciled(double surplus, double total, {double owed = 0, List<Map<String, Object>> balances = const []}) => {
    'at': '2026-11-05T10:00:00Z',
    'surplus': surplus,
    'actualTotal': total,
    'difference': total - surplus,
    'owedToPartners': owed,
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
      ..addAccount('project-0', 'متعب بن عبدالله بن محمد المغيري الشريك المؤسس', type: 'partnerPocket')
      ..transferRows.add({'id': 'entry-0', 'date': '2026-11-05', 'amount': 9999999.99, 'fromAccountName': longName, 'toAccountName': longName, 'description': longName})
      ..reconciliationAnswer = reconciled(9999999.99, 8888888.88, owed: 7777777.77, balances: [balanceRow(longName, 9999999.99, 8888888.88)])
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

    await tester.ensureVisible(find.byKey(AccountsScreen.transferKey));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.transferKey)));
    expect(find.byKey(TransferScreen.saveKey, skipOffstage: false), findsOneWidget);
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

    await act(tester, api, () => tester.tap(find.byKey(PartnersScreen.moveKey)));
    expect(find.byKey(CapitalMoveScreen.saveKey, skipOffstage: false), findsOneWidget);
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

    testWidgets('what is owed to partners shows beside it', (tester) async {
      await openAccounts(tester, (api) {
        api
          ..addAccount('project-0', 'حساب')
          ..reconciliationAnswer = reconciled(1000, 1000, owed: 72.5);
      });

      expect(tester.widget<Text>(find.byKey(ReconciliationCard.owedKey)).data, '72.50');
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

    testWidgets('only whoever moves money enters balances or a transfer, and everyone sees the card', (tester) async {
      await openAccounts(tester, (api) => api.addAccount('project-0', 'حساب'), permissions: field);

      expect(find.byKey(ReconciliationCard.neverKey), findsOneWidget);
      expect(find.byKey(AccountsScreen.reconcileKey), findsNothing);
      expect(find.byKey(AccountsScreen.transferKey), findsNothing);
    });
  });

  group('UC-040', () {
    testWidgets('AC-23.1: a transfer sends both accounts, the amount, the date and the file', (tester) async {
      final (:api, :capture) = await openAccounts(tester, (api) {
        api
          ..addAccount('project-0', 'البنك')
          ..addAccount('project-0', 'العهدة');
      });
      capture.files = _picture();
      final ids = [for (final row in api.accounts['project-0']!) row['id']! as String];
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.transferKey)));

      await act(tester, api, () => tester.tap(find.byKey(TransferScreen.fromKey(ids[0]))));
      await act(tester, api, () => tester.tap(find.byKey(TransferScreen.toKey(ids[1]))));
      await tester.enterText(find.byKey(TransferScreen.amountKey), '5000');
      await tester.enterText(find.byKey(TransferScreen.descriptionKey), 'تغذية العهدة');
      await act(tester, api, () => tester.tap(find.byKey(AddExpenseScreen.filesKey)));
      await act(tester, api, () => tester.tap(find.byKey(TransferScreen.saveKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-0/transfers');
      expect((body['fromAccountId'], body['toAccountId'], body['amount'], body['description']), (ids[0], ids[1], 5000.0, 'تغذية العهدة'));
      expect(body['attachmentId'], isNotNull);
      expect(find.byKey(TransferScreen.saveKey), findsNothing);
    });

    testWidgets('a refused transfer says why and stays', (tester) async {
      final (:api, capture: _) = await openAccounts(tester, (api) {
        api
          ..addAccount('project-0', 'البنك')
          ..moneyAnswer = (status: 400, code: 'sameAccount');
      });
      final id = api.accounts['project-0']!.single['id']! as String;
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.transferKey)));

      await act(tester, api, () => tester.tap(find.byKey(TransferScreen.fromKey(id))));
      await act(tester, api, () => tester.tap(find.byKey(TransferScreen.toKey(id))));
      await tester.enterText(find.byKey(TransferScreen.amountKey), '5');
      await act(tester, api, () => tester.tap(find.byKey(TransferScreen.saveKey)));

      expect(find.text('en transfers.sameAccount'), findsOneWidget);
      expect(find.byKey(TransferScreen.saveKey), findsOneWidget);
    });

    testWidgets('the latest transfers show, and Finance can reverse one', (tester) async {
      final (:api, capture: _) = await openAccounts(tester, (api) {
        api
          ..addAccount('project-0', 'البنك')
          ..transferRows.add({'id': 'entry-0', 'date': '2026-11-05', 'amount': 5000, 'fromAccountName': 'البنك', 'toAccountName': 'العهدة', 'description': 'تغذية'})
          ..addEntry(status: 'approved');
      });

      expect(find.byKey(AccountsScreen.transferRowKey('entry-0')), findsOneWidget);

      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.reverseTransferKey('entry-0'))));
      await tester.enterText(find.byKey(ReverseSheet.reasonKey), 'خطأ');
      await act(tester, api, () => tester.tap(find.byKey(ReverseSheet.sendKey)));

      expect(api.sentEntryChanges.single.$1, 'entry-0');
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

    testWidgets('BR-31: a reader has a way in, and no way to enter a movement', (tester) async {
      await openPartners(tester, (api) {
        final partner = api.addPartner('project-0', 'نفسه');
        api.addCapitalLine(partner['id']! as String, 100, 25);
      }, permissions: const ['readProject']);

      expect(find.byKey(PartnersScreen.totalKey), findsOneWidget);
      expect(find.byKey(PartnersScreen.moveKey), findsNothing);
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

    Future<({FakeApi api, FakeCapture capture, String partnerId, String accountId})> openMove(WidgetTester tester, void Function(FakeApi api) arrange) async {
      final opened = await openPartners(tester, (api) {
        api
          ..addPartner('project-0', 'متعب')
          ..addAccount('project-0', 'البنك');
        arrange(api);
      });
      await act(tester, opened.api, () => tester.tap(find.byKey(PartnersScreen.moveKey)));
      return (api: opened.api, capture: opened.capture, partnerId: opened.api.partners['project-0']!.first['id']! as String, accountId: opened.api.accounts['project-0']!.first['id']! as String);
    }

    testWidgets('AC-25.1: a movement sends its receipt', (tester) async {
      final (:api, :capture, :partnerId, :accountId) = await openMove(tester, (api) {});
      capture.files = _picture();

      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.partnerKey(partnerId))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.accountKey(accountId))));
      await tester.enterText(find.byKey(CapitalMoveScreen.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(AddExpenseScreen.filesKey)));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.saveKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-0/capital-movements');
      expect((body['partnerId'], body['type'], body['amount'], body['accountId']), (partnerId, 'contribution', 1000.0, accountId));
      expect(body['attachmentId'], isNotNull);
    });

    testWidgets('AC-25.1: refused without a receipt, it says why and stays', (tester) async {
      final (:api, capture: _, :partnerId, :accountId) = await openMove(tester, (api) => api.moneyAnswer = (status: 400, code: 'receiptRequired'));

      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.partnerKey(partnerId))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.accountKey(accountId))));
      await tester.enterText(find.byKey(CapitalMoveScreen.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.saveKey)));

      expect(find.text('en capital.receiptRequired'), findsOneWidget);
    });

    testWidgets('AC-25.1: paid in cash asks why, not for a receipt', (tester) async {
      final (:api, capture: _, :partnerId, :accountId) = await openMove(tester, (api) {});

      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.partnerKey(partnerId))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.accountKey(accountId))));
      await tester.enterText(find.byKey(CapitalMoveScreen.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.cashKey)));

      expect(find.byKey(AddExpenseScreen.filesKey), findsNothing);

      await tester.enterText(find.byKey(CapitalMoveScreen.reasonKey), 'دفع في الموقع');
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.saveKey)));

      expect(api.sentMoney.single.$2['cashReason'], 'دفع في الموقع');
    });

    testWidgets('BR-23: a receipt saying another amount warns', (tester) async {
      await openMove(tester, (api) {});

      await tester.enterText(find.byKey(CapitalMoveScreen.amountKey), '1000');
      await tester.enterText(find.byKey(CapitalMoveScreen.receiptAmountKey), '900');
      await tester.pump();

      expect(find.byKey(CapitalMoveScreen.receiptDiffersKey), findsOneWidget);
    });

    testWidgets('a settlement fills in all the partner holds', (tester) async {
      final (:api, capture: _, :partnerId, accountId: _) = await openMove(tester, (api) {
        final partner = api.partners.putIfAbsent('project-0', () => []).first;
        api.addCapitalLine(partner['id']! as String, 700, 100);
      });

      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.partnerKey(partnerId))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.typeKey(MoveType.settlementAndExit))));

      expect(tester.widget<TextField>(find.byKey(CapitalMoveScreen.amountKey)).controller!.text, '700');
    });

    testWidgets('AC-26.1: a carry asks for no receipt, and sends each side', (tester) async {
      final (:api, capture: _, :partnerId, :accountId) = await openMove(tester, (api) {
        api.addProject('غصون 7', permissions: managerAndFinance, units: ['الفلة']);
        api
          ..addPartner('project-1', 'متعب')
          ..addAccount('project-1', 'بنك السابع');
      });
      final targetPartner = api.partners['project-1']!.single['id']! as String;
      final targetAccount = api.accounts['project-1']!.single['id']! as String;

      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.partnerKey(partnerId))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.accountKey(accountId))));
      await tester.enterText(find.byKey(CapitalMoveScreen.amountKey), '400');
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.typeKey(MoveType.carryOut))));

      expect(find.byKey(AddExpenseScreen.filesKey), findsNothing);

      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.targetProjectKey('project-1'))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.targetPartnerKey(targetPartner))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.targetAccountKey(targetAccount))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.saveKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-0/capital-movements/carry');
      expect((body['partnerId'], body['targetProjectId'], body['targetPartnerId'], body['targetAccountId']), (partnerId, 'project-1', targetPartner, targetAccount));
    });

    testWidgets('a carry from a project is the same route from the other side', (tester) async {
      final (:api, capture: _, :partnerId, :accountId) = await openMove(tester, (api) {
        api.addProject('غصون 7', permissions: managerAndFinance, units: ['الفلة']);
        api
          ..addPartner('project-1', 'متعب')
          ..addAccount('project-1', 'بنك السابع');
      });
      final otherPartner = api.partners['project-1']!.single['id']! as String;
      final otherAccount = api.accounts['project-1']!.single['id']! as String;

      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.partnerKey(partnerId))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.accountKey(accountId))));
      await tester.enterText(find.byKey(CapitalMoveScreen.amountKey), '400');
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.typeKey(MoveType.carryIn))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.targetProjectKey('project-1'))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.targetPartnerKey(otherPartner))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.targetAccountKey(otherAccount))));
      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.saveKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-1/capital-movements/carry');
      expect((body['partnerId'], body['targetProjectId'], body['targetPartnerId']), (otherPartner, 'project-0', partnerId));
    });

    testWidgets('with no other project to carry to it says so', (tester) async {
      final (:api, capture: _, partnerId: _, accountId: _) = await openMove(tester, (api) {});

      await act(tester, api, () => tester.tap(find.byKey(CapitalMoveScreen.typeKey(MoveType.carryOut))));

      expect(find.byKey(CapitalMoveScreen.noTargetKey), findsOneWidget);
    });
  });

  testWidgets('a pocket on the accounts screen has no menu', (tester) async {
    final (:api, capture: _) = await openAccounts(tester, (api) => api.addAccount('project-0', 'نواف', type: 'partnerPocket'));

    final id = api.accounts['project-0']!.single['id']! as String;
    expect(find.byKey(AccountsScreen.nameKey(id)), findsOneWidget);
    expect(find.byKey(AccountsScreen.menuKey(id)), findsNothing);
  });

  group('UC-046', () {
    testWidgets('AC-49.4: Finance may use a shared file as a capital movement receipt, and Field may not', (tester) async {
      final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance, units: ['الفلة']);
      final capture = FakeCapture();
      await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
      capture.share(_picture());
      await act(tester, api, () async {});

      await tester.ensureVisible(find.byKey(ShareScreen.capitalReceiptKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(ShareScreen.capitalReceiptKey)));

      expect(find.byKey(CapitalMoveScreen.saveKey), findsOneWidget);
      expect(capture.cameraOpened, 0);
      await tester.scrollUntilVisible(find.byKey(AddExpenseScreen.invoicePictureKey), 100, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsOneWidget);
    });

    testWidgets('AC-49.4: Field sees no capital movement option', (tester) async {
      final api = FakeApi()..addProject('غصون 6', permissions: field, units: ['الفلة']);
      final capture = FakeCapture();
      await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
      capture.share(_picture());
      await act(tester, api, () async {});

      expect(find.byKey(ShareScreen.capitalReceiptKey), findsNothing);
    });
  });
}
