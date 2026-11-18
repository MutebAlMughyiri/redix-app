// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/format/number_format.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/home/home_screen.dart';

import '../app_harness.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/one_field_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/messages.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A project with شبكة and the disabled سداد, opened as far as its payment methods.
  Future<({FakeApi api, String card, String sadad})> openMethods(WidgetTester tester, {String status = 'active', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, permissions: permissions);
    final card = api.addPaymentMethod('project-0', 'شبكة');
    final sadad = api.addPaymentMethod('project-0', 'سداد', isActive: false);
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.paymentMethodsKey('project-0'));
    return (api: api, card: card['id'] as String, sadad: sadad['id'] as String);
  }

  Future<void> saveName(WidgetTester tester, FakeApi api, String name) => act(tester, api, () async {
    await tester.enterText(find.byKey(OneFieldDialog.fieldKey), name);
    await tester.tap(find.byKey(ChangeDialog.saveKey));
  });

  Future<void> chooseInMenu(WidgetTester tester, FakeApi api, String id, Key item) async {
    await act(tester, api, () => tester.tap(find.byKey(PaymentMethodsScreen.menuKey(id))));
    await act(tester, api, () => tester.tap(find.byKey(item)));
  }

  testWidgets('methods show in order, and a disabled one says so', (tester) async {
    final opened = await openMethods(tester);

    expect(text(tester, PaymentMethodsScreen.nameKey(opened.card)), 'شبكة');
    expect(find.byKey(PaymentMethodsScreen.disabledKey(opened.card)), findsNothing);
    expect(text(tester, PaymentMethodsScreen.disabledKey(opened.sadad)), 'en paymentMethods.disabled');
    expect(tester.getTopLeft(find.byKey(PaymentMethodsScreen.nameKey(opened.card))).dy, lessThan(tester.getTopLeft(find.byKey(PaymentMethodsScreen.nameKey(opened.sadad))).dy));
  });

  testWidgets('adding sends the name and shows the new method', (tester) async {
    final opened = await openMethods(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.addKey)));
    await saveName(tester, opened.api, 'مدى');

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/payment-methods');
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'مدى', 'accountIds': <String>[]});
    final added = opened.api.paymentMethods['project-0']!.singleWhere((method) => method['name'] == 'مدى')['id']! as String;
    expect(text(tester, PaymentMethodsScreen.nameKey(added)), 'مدى');
  });

  /// A project with a bank account and a custody, and شبكة paying from [paysFrom] of them, opened as far as its payment methods.
  Future<({FakeApi api, String card, String bank, String custody})> openWithAccounts(WidgetTester tester, {List<String> paysFrom = const ['bank', 'custody']}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance);
    final bank = api.addAccount('project-0', 'حساب المؤسسة')['id']! as String;
    final custody = api.addAccount('project-0', 'عهدتي', type: 'cashCustody')['id']! as String;
    final named = {'bank': bank, 'custody': custody};
    final card = api.addPaymentMethod('project-0', 'شبكة', accountIds: [for (final name in paysFrom) named[name]!])['id']! as String;
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.paymentMethodsKey('project-0'));
    return (api: api, card: card, bank: bank, custody: custody);
  }

  bool ticked(WidgetTester tester, String accountId) => tester.widget<CheckboxListTile>(find.byKey(PaymentMethodsScreen.accountTickKey(accountId))).value!;

  testWidgets('redix-app #109 R3, D1b: a new method starts with every account ticked, and sends the ones left ticked', (tester) async {
    final opened = await openWithAccounts(tester);
    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.addKey)));

    expect(ticked(tester, opened.bank) && ticked(tester, opened.custody), isTrue);
    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.accountTickKey(opened.bank))));
    await saveName(tester, opened.api, 'نقداً');

    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'نقداً', 'accountIds': [opened.custody]});
  });

  testWidgets('redix-app #109 R3: the row of a method names the accounts it pays from, and its dialog starts from them', (tester) async {
    final opened = await openWithAccounts(tester, paysFrom: ['custody']);

    expect(text(tester, PaymentMethodsScreen.paysFromKey(opened.card)), 'en paymentMethods.paysFrom: عهدتي');
    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.renameKey);
    expect(ticked(tester, opened.custody), isTrue);
    expect(ticked(tester, opened.bank), isFalse);
    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.accountTickKey(opened.bank))));
    await saveName(tester, opened.api, 'شبكة');

    expect(opened.api.sentSettingsChanges.last.$2, {'name': 'شبكة', 'accountIds': [opened.custody, opened.bank]});
  });

  testWidgets('a refused name stays in the dialog with its reason', (tester) async {
    final opened = await openMethods(tester);
    opened.api.settingsAnswer = (status: 400, code: 'invalidName');

    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.addKey)));
    await saveName(tester, opened.api, ' ');

    expect(text(tester, ChangeDialog.messageKey), 'en paymentMethods.invalidName');
    expect(find.byKey(OneFieldDialog.fieldKey), findsOneWidget);
  });

  testWidgets('renaming starts from the name and sends the new one', (tester) async {
    final opened = await openMethods(tester);

    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.renameKey);
    expect(tester.widget<TextField>(find.byKey(OneFieldDialog.fieldKey)).controller!.text, 'شبكة');
    await saveName(tester, opened.api, 'بطاقة');

    expect(opened.api.sentSettingsChanges.single.$1, 'PUT /projects/project-0/payment-methods/${opened.card}');
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'بطاقة', 'accountIds': <String>[]});
    expect(text(tester, PaymentMethodsScreen.nameKey(opened.card)), 'بطاقة');
  });

  testWidgets('disabling keeps the method on the list, and enable brings it back', (tester) async {
    final opened = await openMethods(tester);

    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.disableKey);
    expect(find.byKey(PaymentMethodsScreen.disabledKey(opened.card)), findsOneWidget);

    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.enableKey);
    expect(find.byKey(PaymentMethodsScreen.disabledKey(opened.card)), findsNothing);
  });

  testWidgets('redix-api #102: a swipe deletes a method with no question, and the method leaves the list', (tester) async {
    final opened = await openMethods(tester);
    expect(find.byKey(PaymentMethodsScreen.rowKey(opened.card).bar), findsOneWidget);

    await swipeToRemove(tester, opened.api, PaymentMethodsScreen.rowKey(opened.card));

    expect(find.byKey(ConfirmDialog.dialogKey), findsNothing);

    expect(opened.api.sentSettingsChanges.last.$1, 'DELETE /projects/project-0/payment-methods/${opened.card}');
    expect(find.byKey(PaymentMethodsScreen.nameKey(opened.card)), findsNothing);
  });

  testWidgets('a method an expense was paid with is not deleted, and the refusal says to disable it', (tester) async {
    final opened = await openMethods(tester);
    opened.api.settingsAnswer = (status: 409, code: 'paymentMethodUsed');

    await swipeToRemove(tester, opened.api, PaymentMethodsScreen.rowKey(opened.card));

    expect(text(tester, messageKeyOf('paymentMethods.paymentMethodUsed').label), 'en paymentMethods.paymentMethodUsed');
    expect(find.byKey(PaymentMethodsScreen.nameKey(opened.card)), findsOneWidget);
  });

  testWidgets('a refused disable says why', (tester) async {
    final opened = await openMethods(tester);
    opened.api.settingsAnswer = (status: 409, code: 'projectFinished');

    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.disableKey);

    expect(text(tester, messageKeyOf('paymentMethods.projectFinished').label), 'en paymentMethods.projectFinished');
  });

  testWidgets('a finished project shows its methods with nothing to change', (tester) async {
    final opened = await openMethods(tester, status: 'finished');

    expect(find.byKey(PaymentMethodsScreen.nameKey(opened.card)), findsOneWidget);
    expect(isEnabled(tester, PaymentMethodsScreen.addKey), isFalse);
    for (final key in [PaymentMethodsScreen.menuKey(opened.card), PaymentMethodsScreen.menuKey(opened.sadad)]) {
      expect(find.byKey(key), findsNothing);
    }
  });

  testWidgets('without manageSettings there is no way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject']);
    await openProject(tester, api);

    await showProjectSetting(tester, HomeScreen.paymentMethodsKey('project-0'));
    expect(find.byKey(HomeScreen.paymentMethodsKey('project-0')), findsNothing);
  });

  testWidgets('with no network the list shows what was kept, and no failure', (tester) async {
    final opened = await openMethods(tester);
    opened.api.online = false;

    await act(tester, opened.api, () => tester.pageBack());
    await scrollAndTap(tester, opened.api, HomeScreen.paymentMethodsKey('project-0'));

    expect(find.byKey(ApiListBody.messageKey), findsNothing);
  });

  test('a plain number shows as few decimals as it needs', () {
    expect(formatPlain(15), '15');
    expect(formatPlain(100), '100');
    expect(formatPlain(7.5), '7.5');
    expect(formatPlain(7.25), '7.25');
    expect(formatPlain(0), '0');
  });

  test('a typed number reads Western and Arabic digits and thousands separators', () {
    expect(parseNumber(' 1,234.5 '), 1234.5);
    expect(parseNumber('١٢٣٤٫٥'), 1234.5);
    expect(parseNumber('١٬٢٣٤'), 1234);
    expect(parseNumber('-5'), -5);
    expect(parseNumber('abc').isNaN, isTrue);
    expect(parseNumber('').isNaN, isTrue);
  });
}
