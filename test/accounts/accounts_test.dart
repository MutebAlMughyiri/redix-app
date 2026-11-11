import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/accounts/account.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/format/number_format.dart';
import 'package:redix/home/home_screen.dart';

import '../app_harness.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/api_list_body.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A project with a bank account and نواف's custody, opened as far as its accounts.
  Future<({FakeApi api, String bank, String custody})> openAccounts(WidgetTester tester, {String status = 'active', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, permissions: permissions);
    api.addMember('user-nawaf', 'نواف');
    api.addMember('user-fawaz', 'فواز');
    final bank = api.addAccount('project-0', 'حساب المؤسسة', balance: 64250.75);
    final custody = api.addAccount('project-0', 'كاش مع نواف', type: 'cashCustody', balance: 2750, custodianId: 'user-nawaf', custodianName: 'نواف');
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.accountsKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, api, HomeScreen.accountsKey('project-0'));
    return (api: api, bank: bank['id'] as String, custody: custody['id'] as String);
  }

  Future<void> chooseInMenu(WidgetTester tester, FakeApi api, String id, Key item) async {
    await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.menuKey(id))));
    await act(tester, api, () => tester.tap(find.byKey(item)));
  }

  Future<void> chooseCustodian(WidgetTester tester, FakeApi api, String userId) => chooseMember(tester, api, AccountsScreen.custodianKey, userId);

  Future<void> save(WidgetTester tester, FakeApi api, {required String name}) => act(tester, api, () async {
    await tester.enterText(find.byKey(AccountsScreen.accountNameKey), name);
    await tester.tap(find.byKey(ChangeDialog.saveKey));
  });

  bool mayAdd(WidgetTester tester) => tester.widget<IconButton>(find.byKey(AccountsScreen.addKey)).onPressed != null;

  testWidgets('each account shows its type, who holds it and what it holds', (tester) async {
    final opened = await openAccounts(tester);

    expect(text(tester, AccountsScreen.nameKey(opened.bank)), 'حساب المؤسسة');
    expect(text(tester, AccountsScreen.detailsKey(opened.bank)), 'en accounts.typeBank');
    expect(text(tester, AccountsScreen.balanceKey(opened.bank)), '64,250.75');
    expect(text(tester, AccountsScreen.detailsKey(opened.custody)), 'en accounts.typeCashCustody · نواف');
    expect(text(tester, AccountsScreen.balanceKey(opened.custody)), '2,750.00');
  });

  testWidgets('redix-app #89 R10: adding a bank account sends its type and name, nobody, and no balance', (tester) async {
    final opened = await openAccounts(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(AccountsScreen.addKey)));
    await save(tester, opened.api, name: 'حساب جديد');

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/accounts');
    expect(opened.api.sentSettingsChanges.single.$2, {'type': 'bank', 'name': 'حساب جديد'});
    expect(find.text('حساب جديد'), findsOneWidget);
    expect(find.byKey(AccountsScreen.accountNameKey), findsNothing);
  });

  testWidgets('adding a cash custody sends who holds it', (tester) async {
    final opened = await openAccounts(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(AccountsScreen.addKey)));
    await act(tester, opened.api, () => tester.tap(find.byKey(AccountsScreen.typeKey(AccountType.cashCustody))));
    await chooseCustodian(tester, opened.api, 'user-fawaz');
    await save(tester, opened.api, name: 'كاش مع فواز');

    expect(opened.api.sentSettingsChanges.single.$2, {'type': 'cashCustody', 'name': 'كاش مع فواز', 'custodianId': 'user-fawaz'});
  });

  testWidgets('a refusal stays in the dialog with its reason', (tester) async {
    final opened = await openAccounts(tester);
    opened.api.settingsAnswer = (status: 400, code: 'custodianRequired');

    await act(tester, opened.api, () => tester.tap(find.byKey(AccountsScreen.addKey)));
    await save(tester, opened.api, name: 'كاش');

    expect(text(tester, ChangeDialog.messageKey), 'en accounts.custodianRequired');
    expect(find.byKey(AccountsScreen.accountNameKey), findsOneWidget);
  });

  testWidgets('R10: the dialog asks no balance, adding or editing', (tester) async {
    final opened = await openAccounts(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(AccountsScreen.addKey)));
    expect(find.byType(TextField), findsOneWidget);
    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.cancelKey)));

    await chooseInMenu(tester, opened.api, opened.bank, AccountsScreen.editKey);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('editing starts from the account and sends what changed, and its type cannot change', (tester) async {
    final opened = await openAccounts(tester);

    await chooseInMenu(tester, opened.api, opened.custody, AccountsScreen.editKey);

    expect(tester.widget<TextField>(find.byKey(AccountsScreen.accountNameKey)).controller!.text, 'كاش مع نواف');
    expect(find.byKey(AccountsScreen.typeKey(AccountType.bank)), findsNothing);
    await chooseCustodian(tester, opened.api, 'user-fawaz');
    await save(tester, opened.api, name: 'كاش مع فواز');

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/accounts/${opened.custody}');
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'كاش مع فواز', 'custodianId': 'user-fawaz'});
    expect(text(tester, AccountsScreen.detailsKey(opened.custody)), 'en accounts.typeCashCustody · فواز');
    expect(text(tester, AccountsScreen.balanceKey(opened.custody)), '2,750.00');
  });

  testWidgets('choosing nobody sends no custodian', (tester) async {
    final opened = await openAccounts(tester);

    await chooseInMenu(tester, opened.api, opened.custody, AccountsScreen.editKey);
    await chooseCustodian(tester, opened.api, '');
    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(opened.api.sentSettingsChanges.single.$2.containsKey('custodianId'), isFalse);
  });

  testWidgets('a custodian who left the project stays on offer until changed', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    final custody = api.addAccount('project-0', 'كاش مع هيثم', type: 'cashCustody', custodianId: 'user-gone', custodianName: 'هيثم');
    await openProject(tester, api);
    await showProjectSetting(tester, HomeScreen.accountsKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, api, HomeScreen.accountsKey('project-0'));

    await chooseInMenu(tester, api, custody['id'] as String, AccountsScreen.editKey);

    expect(find.descendant(of: find.byKey(AccountsScreen.custodianKey), matching: find.text('هيثم')), findsOneWidget);
  });

  testWidgets('disabling says so on the row, and enable brings it back', (tester) async {
    final opened = await openAccounts(tester);

    await chooseInMenu(tester, opened.api, opened.bank, AccountsScreen.disableKey);
    expect(text(tester, AccountsScreen.detailsKey(opened.bank)), 'en accounts.disabled');
    expect(text(tester, AccountsScreen.balanceKey(opened.bank)), '64,250.75');

    await chooseInMenu(tester, opened.api, opened.bank, AccountsScreen.enableKey);
    expect(text(tester, AccountsScreen.detailsKey(opened.bank)), 'en accounts.typeBank');
  });

  testWidgets('without manageSettings the accounts show with nothing to change (AC-22.1)', (tester) async {
    final opened = await openAccounts(tester, permissions: ['readProject']);

    expect(text(tester, AccountsScreen.balanceKey(opened.bank)), '64,250.75');
    expect(text(tester, AccountsScreen.balanceKey(opened.custody)), '2,750.00');
    expect(mayAdd(tester), isFalse);
    expect(find.byKey(AccountsScreen.menuKey(opened.bank)), findsNothing);
    expect(find.byKey(AccountsScreen.menuKey(opened.custody)), findsNothing);
  });

  testWidgets('a finished project shows its accounts with nothing to change', (tester) async {
    final opened = await openAccounts(tester, status: 'finished');

    expect(find.byKey(AccountsScreen.nameKey(opened.bank)), findsOneWidget);
    expect(mayAdd(tester), isFalse);
    expect(find.byKey(AccountsScreen.menuKey(opened.bank)), findsNothing);
  });

  testWidgets('a custodian sees their custody on the home, and nobody else does (AC-22.1)', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject']);
    final mine = api.addAccount('project-0', 'كاش مع نواف', type: 'cashCustody', balance: 2750, custodianId: 'user-nawaf', custodianName: 'نواف', isMine: true);
    final theirs = api.addAccount('project-0', 'كاش مع فواز', type: 'cashCustody', balance: 40, custodianId: 'user-fawaz', custodianName: 'فواز');
    await openProject(tester, api);

    expect(text(tester, HomeScreen.custodyBalanceKey(mine['id'] as String)), '2,750.00 en accounts.riyal');
    expect(find.byKey(HomeScreen.custodyKey(theirs['id'] as String)), findsNothing);
  });

  testWidgets('a disabled custody leaves the home', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject']);
    final mine = api.addAccount('project-0', 'كاش مع نواف', type: 'cashCustody', custodianId: 'user-nawaf', custodianName: 'نواف', isMine: true, isActive: false);
    await openProject(tester, api);

    expect(find.byKey(HomeScreen.custodyKey(mine['id'] as String)), findsNothing);
  });

  testWidgets('with no network the list shows what was kept, and no failure', (tester) async {
    final opened = await openAccounts(tester);
    opened.api.online = false;

    await act(tester, opened.api, () => tester.tap(find.byType(BackButton)));
    await showProjectSetting(tester, HomeScreen.accountsKey('project-0'));
    await tester.ensureVisible(projectSettingPages);
    await scrollAndTap(tester, opened.api, HomeScreen.accountsKey('project-0'));

    expect(find.byKey(ApiListBody.messageKey), findsNothing);
  });

  test('money shows two decimals, thousands separators, and negatives in brackets (NFR-04)', () {
    expect(formatMoney(0), '0.00');
    expect(formatMoney(999.5), '999.50');
    expect(formatMoney(1234.56), '1,234.56');
    expect(formatMoney(1234567.891), '1,234,567.89');
    expect(formatMoney(-120.40), '(120.40)');
  });
}
