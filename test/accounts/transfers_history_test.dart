import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/accounts/account_history_screen.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/accounts/transfer_dialog.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/refusal_snack_bar.dart';
import 'package:redix/words/word_fill.dart';

import '../app_harness.dart';

/// redix-app #89: moving money between accounts, deleting one nothing names, and the account history, on Accounts.
void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A project with a bank account and a custody, arranged further by [arrange], opened as far as its accounts.
  Future<({FakeApi api, String bank, String custody})> openAccounts(WidgetTester tester, {void Function(FakeApi api)? arrange, List<String> permissions = managerAndFinance}) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions);
    api.addMember('user-nawaf', 'نواف');
    final bank = api.addAccount('project-0', 'حساب المؤسسة', balance: 1000);
    final custody = api.addAccount('project-0', 'كاش مع نواف', type: 'cashCustody', balance: 200, custodianId: 'user-nawaf', custodianName: 'نواف');
    arrange?.call(api);
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.accountsKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, api, HomeScreen.accountsKey('project-0'));
    return (api: api, bank: bank['id'] as String, custody: custody['id'] as String);
  }

  Future<void> openTransfer(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byKey(AccountsScreen.transferKey)));

  Future<void> chooseInMenu(WidgetTester tester, FakeApi api, String id, Key item) async {
    await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.menuKey(id))));
    await act(tester, api, () => tester.tap(find.byKey(item)));
  }

  group('Transfer', () {
    testWidgets('FR-23: it opens from the bottom bar, From the first account, To the next, and says what From holds now', (tester) async {
      final opened = await openAccounts(tester);

      await openTransfer(tester, opened.api);

      expect(tester.widget<DropdownButton<String>>(find.byKey(TransferDialog.fromKey)).value, opened.bank);
      expect(tester.widget<DropdownButton<String>>(find.byKey(TransferDialog.toKey)).value, opened.custody);
      expect(text(tester, TransferDialog.balanceNowKey), 'en transfers.balanceNow');
    });

    testWidgets('R14: To never offers From, so the same account cannot be chosen twice', (tester) async {
      final opened = await openAccounts(tester);
      await openTransfer(tester, opened.api);

      final offered = tester.widget<DropdownButton<String>>(find.byKey(TransferDialog.toKey)).items!.map((item) => item.value);

      expect(offered, [opened.custody]);
    });

    testWidgets('choosing as From the account To held moves To to another one', (tester) async {
      final opened = await openAccounts(tester);
      await openTransfer(tester, opened.api);

      await act(tester, opened.api, () => tester.tap(find.byKey(TransferDialog.fromKey)));
      await act(tester, opened.api, () => tester.tap(find.byKey(TransferDialog.choiceKey(TransferDialog.fromKey, opened.custody)).last));

      expect(tester.widget<DropdownButton<String>>(find.byKey(TransferDialog.fromKey)).value, opened.custody);
      expect(tester.widget<DropdownButton<String>>(find.byKey(TransferDialog.toKey)).value, opened.bank);
    });

    testWidgets('a transfer sends both accounts, the amount, the day and the notes, closes, and both balances follow at once', (tester) async {
      final opened = await openAccounts(tester);
      await openTransfer(tester, opened.api);

      await tester.enterText(find.byKey(TransferDialog.amountKey), '٤٠٠');
      await tester.enterText(find.byKey(TransferDialog.notesKey), 'تغذية العهدة');
      await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

      final (project, body) = opened.api.sentTransfers.single;
      expect(project, 'project-0');
      expect(body, {'fromAccountId': opened.bank, 'toAccountId': opened.custody, 'amount': 400.0, 'date': body['date'], 'notes': 'تغذية العهدة'});
      expect(find.byKey(TransferDialog.amountKey), findsNothing);
      expect(text(tester, AccountsScreen.balanceKey(opened.bank)), '600.00');
      expect(text(tester, AccountsScreen.balanceKey(opened.custody)), '600.00');
    });

    testWidgets('an amount that is not a number is refused in the dialog, and nothing is sent', (tester) async {
      final opened = await openAccounts(tester);
      await openTransfer(tester, opened.api);

      await tester.enterText(find.byKey(TransferDialog.amountKey), 'abc');
      await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

      expect(opened.api.sentTransfers, isEmpty);
      expect(text(tester, ChangeDialog.messageKey), 'en transfers.invalidAmount');
    });

    testWidgets('R26: a refusal stays in the dialog in the transfer\'s own words, and nothing moves', (tester) async {
      final opened = await openAccounts(tester);
      opened.api.settingsAnswer = (status: 400, code: 'insufficientBalance');
      await openTransfer(tester, opened.api);

      await tester.enterText(find.byKey(TransferDialog.amountKey), '5000');
      await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

      expect(text(tester, ChangeDialog.messageKey), 'en transfers.insufficientBalance');
      await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.cancelKey)));
      expect(text(tester, AccountsScreen.balanceKey(opened.bank)), '1,000.00');
    });

    testWidgets('a disabled account is offered neither as From nor as To', (tester) async {
      late String old;
      final opened = await openAccounts(tester, arrange: (api) => old = api.addAccount('project-0', 'قديم', isActive: false)['id']! as String);
      await openTransfer(tester, opened.api);

      final from = tester.widget<DropdownButton<String>>(find.byKey(TransferDialog.fromKey)).items!.map((item) => item.value);
      final to = tester.widget<DropdownButton<String>>(find.byKey(TransferDialog.toKey)).items!.map((item) => item.value);

      expect(from, isNot(contains(old)));
      expect(to, isNot(contains(old)));
    });
  });

  group('Delete', () {
    testWidgets('BR-15: an account something names keeps Delete in its menu, gray, saying why', (tester) async {
      late String used;
      final opened = await openAccounts(tester, arrange: (api) => used = api.addAccount('project-0', 'مستخدم', isUsed: true)['id']! as String);

      await act(tester, opened.api, () => tester.tap(find.byKey(AccountsScreen.menuKey(used))));

      expect(tester.widget<PopupMenuItem<VoidCallback>>(find.byKey(AccountsScreen.deleteKey)).enabled, isFalse);
      expect(text(tester, AccountsScreen.deleteKey.subtitle), 'en accounts.accountInUse');
    });

    testWidgets('BR-15: an account nothing names is deleted after the question, and says so', (tester) async {
      final opened = await openAccounts(tester);

      await chooseInMenu(tester, opened.api, opened.custody, AccountsScreen.deleteKey);
      expect(find.byKey(ConfirmDialog.dialogKey), findsOneWidget);
      await act(tester, opened.api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

      expect(opened.api.sentSettingsChanges.last.$1, '/projects/project-0/accounts/${opened.custody}/delete');
      expect(find.byKey(AccountsScreen.rowKey(opened.custody)), findsNothing);
      expect(find.byKey(messageKeyOf('accounts.deleted')), findsOneWidget);
    });

    testWidgets('a refused delete says why, and the account stays', (tester) async {
      final opened = await openAccounts(tester);
      opened.api.settingsAnswer = (status: 409, code: 'accountInUse');

      await chooseInMenu(tester, opened.api, opened.custody, AccountsScreen.deleteKey);
      await act(tester, opened.api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

      expect(find.byKey(messageKeyOf('accounts.accountInUse')), findsOneWidget);
      expect(find.byKey(AccountsScreen.rowKey(opened.custody)), findsOneWidget);
    });
  });

  group('History', () {
    Future<FakeApi> openHistory(WidgetTester tester, {void Function(FakeApi api)? arrange, List<String> permissions = managerAndFinance}) async {
      final opened = await openAccounts(tester, arrange: arrange, permissions: permissions);
      await act(tester, opened.api, () => tester.tap(find.byKey(AccountsScreen.historyKey)));
      return opened.api;
    }

    testWidgets('R17: History opens from the top bar for everyone who reads the project, and its lines say what, who and when, newest first', (tester) async {
      final api = await openHistory(tester, permissions: const ['readProject'], arrange: (api) {
        api
          ..addHistoryLine('project-0', 'check', amount: 1200)
          ..addHistoryLine('project-0', 'transfer', by: 'ريم', amount: 500, otherAccount: 'كاش مع نواف')
          ..addHistoryLine('project-0', 'entryOut', amount: 300);
      });

      expect(api.historyReads.single.queryParameters, {'account': '', 'mine': 'false', 'before': '0'});
      expect(text(tester, AccountHistoryScreen.lineKey(1000).title), 'en history.check');
      expect(text(tester, AccountHistoryScreen.lineKey(999).title), 'en history.transfer');
      expect(text(tester, AccountHistoryScreen.lineKey(999).subtitle), contains('ريم'));
      expect(text(tester, AccountHistoryScreen.lineKey(998).subtitle), startsWith('en history.approvedBy'));
      expect(tester.getTopLeft(find.byKey(AccountHistoryScreen.lineKey(1000))).dy, lessThan(tester.getTopLeft(find.byKey(AccountHistoryScreen.lineKey(999))).dy));
    });

    Future<void> chooseAccount(WidgetTester tester, FakeApi api, Key account) async {
      await openFilters(tester, api);
      await act(tester, api, () => tester.tap(find.byKey(AccountHistoryScreen.accountChoiceKey)));
      await act(tester, api, () => tester.tap(find.byKey(account)));
    }

    testWidgets('R22, redix-app #104: the account chip under the search line reads one account\'s lines and says its name, and All reads every account again', (tester) async {
      late String bankId;
      late String bankName;
      final api = await openHistory(tester, arrange: (api) {
        bankId = api.accounts['project-0']!.first['id']! as String;
        bankName = api.accounts['project-0']!.first['name']! as String;
      });

      await chooseAccount(tester, api, AccountHistoryScreen.accountKey(bankId));
      expect(api.historyReads.last.queryParameters['account'], bankId);
      expect(tester.widget<FilterChip>(find.byKey(AccountHistoryScreen.accountChoiceKey)).selected, isTrue);
      expect(text(tester, AccountHistoryScreen.accountChoiceKey.label), 'en history.account: $bankName');

      await chooseAccount(tester, api, AccountHistoryScreen.allKey);
      expect(api.historyReads.last.queryParameters['account'], '');
      expect(tester.widget<FilterChip>(find.byKey(AccountHistoryScreen.accountChoiceKey)).selected, isFalse);
      expect(text(tester, AccountHistoryScreen.accountChoiceKey.label), 'en history.account: en history.all');
    });

    testWidgets('H10: What I did reads only the signed-in user\'s lines, and the filters stay when nothing is found', (tester) async {
      final api = await openHistory(tester);

      await openFilters(tester, api);
      await act(tester, api, () => tester.tap(find.byKey(AccountHistoryScreen.mineKey)));

      expect(api.historyReads.last.queryParameters['mine'], 'true');
      expect(find.byKey(ApiListBody.emptyKey), findsOneWidget);
      expect(find.byKey(AccountHistoryScreen.mineKey), findsOneWidget);
      expect(find.byKey(AccountHistoryScreen.accountChoiceKey), findsOneWidget);
    });

    testWidgets('redix-app #104: what is typed is asked of the API in Western digits, only the lines holding it show, and choosing an account keeps it', (tester) async {
      late String bankId;
      final api = await openHistory(tester, arrange: (api) {
        bankId = api.accounts['project-0']!.first['id']! as String;
        api
          ..addHistoryLine('project-0', 'transfer', by: 'ريم', amount: 500, otherAccount: 'كاش مع نواف')
          ..addHistoryLine('project-0', 'entryOut', amount: 300);
      });

      await searchFor(tester, api, 'نواف');
      expect(find.byKey(AccountHistoryScreen.lineKey(1000)), findsOneWidget);
      expect(find.byKey(AccountHistoryScreen.lineKey(999)), findsNothing);

      await searchFor(tester, api, '٥٠٠');
      await chooseAccount(tester, api, AccountHistoryScreen.accountKey(bankId));
      expect(api.historyReads.last.queryParameters, {'account': bankId, 'mine': 'false', 'before': '0', 'text': '500'});
    });

    testWidgets('redix-app #104, D4: a search does not outlive its screen; History opens again with every line', (tester) async {
      final api = await openHistory(tester, arrange: (api) => api.addHistoryLine('project-0', 'entryOut', amount: 300));

      await searchFor(tester, api, 'نواف');
      expect(find.byKey(AccountHistoryScreen.lineKey(1000)), findsNothing);
      await act(tester, api, () => tester.pageBack());
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.historyKey)));

      expect(api.historyReads.last.queryParameters.containsKey('text'), isFalse);
      expect(find.byKey(AccountHistoryScreen.lineKey(1000)), findsOneWidget);
    });

    testWidgets('R22: a full page offers More, which reads the page after its last line and adds it below', (tester) async {
      final api = await openHistory(tester, arrange: (api) {
        for (var i = 0; i < 60; i++) {
          api.addHistoryLine('project-0', 'accountChanged', nameWas: 'قديم');
        }
      });

      await tester.scrollUntilVisible(find.byKey(AccountHistoryScreen.moreKey), 400, scrollable: listRows);
      await act(tester, api, () => tester.tap(find.byKey(AccountHistoryScreen.moreKey)));

      expect(api.historyReads.last.queryParameters['before'], '951');
      await tester.scrollUntilVisible(find.byKey(AccountHistoryScreen.lineKey(941)), 400, scrollable: listRows);
      expect(find.byKey(AccountHistoryScreen.lineKey(941)), findsOneWidget);
      expect(find.byKey(AccountHistoryScreen.moreKey), findsNothing);
    });

    testWidgets('a history with fewer lines than a page offers no More', (tester) async {
      await openHistory(tester, arrange: (api) => api.addHistoryLine('project-0', 'accountCreated'));

      expect(find.byKey(AccountHistoryScreen.moreKey), findsNothing);
    });
  });

  test('a word fills each of its places, and leaves a word without places as it is', () {
    expect('Transferred {0} from {1} to {2}'.fill(['500.00', 'البنك', 'كاش']), 'Transferred 500.00 from البنك to كاش');
    expect('{0} holds {1}; {2} waits on it, {3} short.'.fill(['كاش', '1,000.00', '1,200.00', '200.00']), 'كاش holds 1,000.00; 1,200.00 waits on it, 200.00 short.');
    expect('Nothing yet.'.fill(['x']), 'Nothing yet.');
  });
}
