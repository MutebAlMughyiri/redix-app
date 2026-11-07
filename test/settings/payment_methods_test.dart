import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/format/number_format.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/settings/settings_screen.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// A project with شبكة and the disabled سداد, opened as far as its payment methods.
  Future<({FakeApi api, String card, String sadad})> openMethods(WidgetTester tester, {String status = 'running', List<String> permissions = managerAndFinance}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, permissions: permissions);
    final card = api.addPaymentMethod('project-0', 'شبكة');
    final sadad = api.addPaymentMethod('project-0', 'سداد', isActive: false);
    await openProject(tester, api);
    await openSettings(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.paymentMethodsKey)));
    return (api: api, card: card['id'] as String, sadad: sadad['id'] as String);
  }

  Future<void> saveName(WidgetTester tester, FakeApi api, String name) => act(tester, api, () async {
    await tester.enterText(find.byKey(PaymentMethodsScreen.dialogNameKey), name);
    await tester.tap(find.byKey(PaymentMethodsScreen.saveKey));
  });

  Future<void> saveVat(WidgetTester tester, FakeApi api, String percent) => act(tester, api, () async {
    await tester.enterText(find.byKey(PaymentMethodsScreen.vatPercentKey), percent);
    await tester.tap(find.byKey(PaymentMethodsScreen.saveKey));
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
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'مدى'});
    expect(find.text('مدى'), findsOneWidget);
  });

  testWidgets('a refused name stays in the dialog with its reason', (tester) async {
    final opened = await openMethods(tester);
    opened.api.settingsAnswer = (status: 400, code: 'invalidName');

    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.addKey)));
    await saveName(tester, opened.api, ' ');

    expect(text(tester, PaymentMethodsScreen.dialogMessageKey), 'en paymentMethods.invalidName');
    expect(find.byKey(PaymentMethodsScreen.dialogNameKey), findsOneWidget);
  });

  testWidgets('renaming starts from the name and sends the new one', (tester) async {
    final opened = await openMethods(tester);

    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.renameKey);
    expect(tester.widget<TextField>(find.byKey(PaymentMethodsScreen.dialogNameKey)).controller!.text, 'شبكة');
    await saveName(tester, opened.api, 'بطاقة');

    expect(opened.api.sentSettingsChanges.single.$1, '/projects/project-0/payment-methods/${opened.card}');
    expect(opened.api.sentSettingsChanges.single.$2, {'name': 'بطاقة'});
    expect(text(tester, PaymentMethodsScreen.nameKey(opened.card)), 'بطاقة');
  });

  testWidgets('disabling keeps the method on the list, and enable brings it back', (tester) async {
    final opened = await openMethods(tester);

    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.disableKey);
    expect(find.byKey(PaymentMethodsScreen.disabledKey(opened.card)), findsOneWidget);

    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.enableKey);
    expect(find.byKey(PaymentMethodsScreen.disabledKey(opened.card)), findsNothing);
  });

  testWidgets('deleting asks first, then sends the delete and the method leaves the list', (tester) async {
    final opened = await openMethods(tester);

    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.deleteKey);
    expect(find.text('en paymentMethods.deleteQuestion'), findsOneWidget);
    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.deleteConfirmKey)));

    expect(opened.api.sentSettingsChanges.last.$1, '/projects/project-0/payment-methods/${opened.card}/delete');
    expect(find.byKey(PaymentMethodsScreen.nameKey(opened.card)), findsNothing);
  });

  testWidgets('a method an expense was paid with is not deleted, and the refusal says to disable it', (tester) async {
    final opened = await openMethods(tester);
    opened.api.settingsAnswer = (status: 409, code: 'paymentMethodUsed');

    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.deleteKey);
    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.deleteConfirmKey)));

    expect(find.text('en paymentMethods.paymentMethodUsed'), findsOneWidget);
    expect(find.byKey(PaymentMethodsScreen.nameKey(opened.card)), findsOneWidget);
  });

  testWidgets('a refused disable says why', (tester) async {
    final opened = await openMethods(tester);
    opened.api.settingsAnswer = (status: 409, code: 'projectFinished');

    await chooseInMenu(tester, opened.api, opened.card, PaymentMethodsScreen.disableKey);

    expect(find.text('en paymentMethods.projectFinished'), findsOneWidget);
  });

  testWidgets('the rate shows as a percentage, with what it applies to', (tester) async {
    await openMethods(tester);

    expect(text(tester, PaymentMethodsScreen.vatRateKey), '15%');
    expect(text(tester, PaymentMethodsScreen.vatHintKey), 'en paymentMethods.vatHint');
  });

  testWidgets('changing the rate starts from it, sends the percentage and shows the new one', (tester) async {
    final opened = await openMethods(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.changeVatRateKey)));
    expect(tester.widget<TextField>(find.byKey(PaymentMethodsScreen.vatPercentKey)).controller!.text, '15');
    await saveVat(tester, opened.api, '7.5');

    expect(opened.api.sentProjectChanges.single.$1, '/projects/project-0/vat-rate');
    expect(opened.api.sentProjectChanges.single.$2, {'vatPercent': 7.5});
    expect(text(tester, PaymentMethodsScreen.vatRateKey), '7.5%');
    expect(find.byKey(PaymentMethodsScreen.vatPercentKey), findsNothing);
  });

  testWidgets('a rate in Arabic digits is understood', (tester) async {
    final opened = await openMethods(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.changeVatRateKey)));
    await saveVat(tester, opened.api, '٧٫٥');

    expect(opened.api.sentProjectChanges.single.$1, '/projects/project-0/vat-rate');
    expect(opened.api.sentProjectChanges.single.$2, {'vatPercent': 7.5});
  });

  testWidgets('what is not a number is refused without asking the API', (tester) async {
    final opened = await openMethods(tester);

    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.changeVatRateKey)));
    await saveVat(tester, opened.api, 'abc');

    expect(opened.api.sentProjectChanges, isEmpty);
    expect(text(tester, PaymentMethodsScreen.dialogMessageKey), 'en projects.invalidVatRate');
  });

  testWidgets('a rate the API refuses stays in the dialog with its reason', (tester) async {
    final opened = await openMethods(tester);
    opened.api.projectAnswer = (status: 400, code: 'invalidVatRate');

    await act(tester, opened.api, () => tester.tap(find.byKey(PaymentMethodsScreen.changeVatRateKey)));
    await saveVat(tester, opened.api, '101');

    expect(text(tester, PaymentMethodsScreen.dialogMessageKey), 'en projects.invalidVatRate');
    expect(text(tester, PaymentMethodsScreen.vatRateKey), '15%');
  });

  testWidgets('a finished project shows its methods and rate with nothing to change', (tester) async {
    final opened = await openMethods(tester, status: 'finished');

    expect(find.byKey(PaymentMethodsScreen.nameKey(opened.card)), findsOneWidget);
    expect(find.byKey(PaymentMethodsScreen.vatRateKey), findsOneWidget);
    for (final key in [
      PaymentMethodsScreen.addKey,
      PaymentMethodsScreen.changeVatRateKey,
      PaymentMethodsScreen.menuKey(opened.card),
      PaymentMethodsScreen.menuKey(opened.sadad),
    ]) {
      expect(find.byKey(key), findsNothing);
    }
  });

  testWidgets('without manageSettings there is no way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject']);
    await openProject(tester, api);

    await openSettings(tester, api);
    expect(find.byKey(SettingsScreen.paymentMethodsKey), findsNothing);
  });

  testWidgets('with no network the list shows what was kept, and no failure', (tester) async {
    final opened = await openMethods(tester);
    opened.api.online = false;

    await act(tester, opened.api, () => tester.tap(find.byType(BackButton)));
    await act(tester, opened.api, () => tester.tap(find.byKey(SettingsScreen.paymentMethodsKey)));

    expect(find.byKey(PaymentMethodsScreen.messageKey), findsNothing);
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
