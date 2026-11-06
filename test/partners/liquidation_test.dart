import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/liquidation_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/structure/item_picker.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';

import '../app_harness.dart';

void main() {
  Map<String, Object> part(String partnerId, String name, double share, double amount) => {'partnerId': partnerId, 'name': name, 'sharePercent': share, 'amount': amount};

  Future<FakeApi> openLiquidation(WidgetTester tester, void Function(FakeApi api) arrange, {String status = 'running', FakeCapture? capture}) async {
    final api = FakeApi()..addProject('غصون 6', status: status, units: ['الفلة']);
    arrange(api);
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture ?? FakeCapture());
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.liquidateKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.liquidateKey('project-0'))));
    return api;
  }

  Future<void> tapVisible(WidgetTester tester, FakeApi api, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(key)));
  }

  bool confirmEnabled(WidgetTester tester) => tester.widget<FilledButton>(find.byKey(LiquidationScreen.confirmKey)).onPressed != null;

  testWidgets('UC-061: each part is paid out or carried as chosen, and liquidating sends how each goes', (tester) async {
    late String bank;
    late String laterPartner;
    late String laterBank;
    final api = await openLiquidation(tester, (api) {
      api.liquidationAnswer = {
        'surplus': 900,
        'pendingCount': 0,
        'parts': [part('partner-a', 'سالم', 60, 540), part('partner-b', 'فهد', 40, 360)],
        'distributed': <Map<String, Object>>[],
      };
      bank = api.addAccount('project-0', 'حساب المؤسسة')['id']! as String;
      api.addProject('غصون 7');
      laterPartner = api.addPartner('project-1', 'فهد')['id']! as String;
      laterBank = api.addAccount('project-1', 'حساب غصون 7')['id']! as String;
    });
    expect(tester.widget<Text>(find.byKey(LiquidationScreen.surplusKey)).data, '900.00');
    expect(confirmEnabled(tester), isFalse);

    await tapVisible(tester, api, LiquidationScreen.accountKey('partner-a', bank));
    await tapVisible(tester, api, LiquidationScreen.carryKey('partner-b'));
    await tapVisible(tester, api, LiquidationScreen.accountKey('partner-b', bank));
    await tapVisible(tester, api, LiquidationScreen.targetProjectKey('partner-b', 'project-1'));
    await tapVisible(tester, api, LiquidationScreen.targetPartnerKey('partner-b', laterPartner));
    await tapVisible(tester, api, LiquidationScreen.targetAccountKey('partner-b', laterBank));
    await tapVisible(tester, api, LiquidationScreen.confirmKey);
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    final (path, body) = api.sentMoney.single;
    expect(path, '/projects/project-0/liquidation');
    expect(body['lines'], [
      {'partnerId': 'partner-a', 'accountId': bank},
      {'partnerId': 'partner-b', 'accountId': bank, 'targetProjectId': 'project-1', 'targetPartnerId': laterPartner, 'targetAccountId': laterBank},
    ]);
    expect(find.text('en liquidation.done'), findsOneWidget);
  });

  testWidgets('BR-35: entries waiting for approval hold the liquidation, and say how many', (tester) async {
    await openLiquidation(tester, (api) {
      api.liquidationAnswer = {'surplus': 100, 'pendingCount': 2, 'parts': <Map<String, Object>>[], 'distributed': <Map<String, Object>>[]};
    });

    expect(tester.widget<Text>(find.byKey(LiquidationScreen.pendingKey)).data, 'en liquidation.pending');
    expect(confirmEnabled(tester), isFalse);
  });

  testWidgets('BR-27: a deficit says so, and shows what is to be paid in', (tester) async {
    await openLiquidation(tester, (api) {
      api.liquidationAnswer = {'surplus': -200, 'pendingCount': 0, 'parts': [part('partner-a', 'سالم', 100, -200)], 'distributed': <Map<String, Object>>[]};
    });

    expect(find.text('en liquidation.deficit'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(LiquidationScreen.surplusKey)).data, '200.00');
  });

  testWidgets('a refusal says why, and nothing closes', (tester) async {
    late String bank;
    final api = await openLiquidation(tester, (api) {
      api
        ..liquidationAnswer = {'surplus': 100, 'pendingCount': 0, 'parts': [part('partner-a', 'سالم', 100, 100)], 'distributed': <Map<String, Object>>[]}
        ..moneyAnswer = (status: 409, code: 'pendingEntries');
      bank = api.addAccount('project-0', 'حساب المؤسسة')['id']! as String;
    });

    await tapVisible(tester, api, LiquidationScreen.accountKey('partner-a', bank));
    await tapVisible(tester, api, LiquidationScreen.confirmKey);
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(tester.widget<Text>(find.byKey(LiquidationScreen.messageKey)).data, 'en capital.pendingEntries');
    expect(find.byType(LiquidationScreen), findsOneWidget);
  });

  testWidgets('a closed project shows what each partner was given', (tester) async {
    await openLiquidation(tester, (api) {
      api.liquidationAnswer = {
        'surplus': 0,
        'pendingCount': 0,
        'parts': <Map<String, Object>>[],
        'distributed': [
          {'entryId': 'entry-9', 'partnerName': 'سالم', 'date': '2026-11-05', 'amount': 540, 'accountName': 'حساب المؤسسة', 'description': 'تصفية المشروع', 'receiptId': '', 'receiptType': ''},
        ],
      };
    }, status: 'finished');

    expect(find.descendant(of: find.byKey(LiquidationScreen.distributedKey('entry-9')), matching: find.text('540.00')), findsOneWidget);
    expect(find.byKey(LiquidationScreen.confirmKey), findsNothing);
  });

  Map<String, Object> closedWith(List<Map<String, Object>> distributed) => {'surplus': 0, 'pendingCount': 0, 'parts': <Map<String, Object>>[], 'distributed': distributed};

  Map<String, Object> payout(String entryId, {String receiptId = ''}) =>
      {'entryId': entryId, 'partnerName': 'سالم', 'date': '2026-11-05', 'amount': 540, 'accountName': 'حساب المؤسسة', 'description': 'تصفية المشروع', 'receiptId': receiptId, 'receiptType': receiptId.isEmpty ? '' : 'image/png'};

  testWidgets('BR-23: a payout still without its receipt is marked, and attaching one sends the file', (tester) async {
    final capture = FakeCapture()..files = PickedFile('receipt.png', '/phone/receipt.png', Uint8List.fromList(onePixelPng));
    final api = await openLiquidation(tester, (api) => api.liquidationAnswer = closedWith([payout('entry-9'), payout('entry-10', receiptId: 'attachment-3')]), status: 'finished', capture: capture);

    expect(find.byKey(LiquidationScreen.receiptKey('entry-10')), findsOneWidget);
    await tapVisible(tester, api, LiquidationScreen.attachReceiptKey('entry-9'));

    expect(api.sentReceipts, ['entry-9']);
    expect(find.text('en liquidation.receiptAttached'), findsOneWidget);
  });

  testWidgets('FR-51: a late expense in a closed project is sent with its item, day, amount and account', (tester) async {
    late String item;
    late String bank;
    final api = await openLiquidation(tester, (api) {
      api.liquidationAnswer = closedWith([]);
      item = api.addItem(api.addCategory('project-0', 'التشطيب'), 'بند الكهرباء')['id']! as String;
      bank = api.addAccount('project-0', 'حساب المؤسسة')['id']! as String;
    }, status: 'finished');

    await tapVisible(tester, api, LiquidationScreen.lateKey);
    await act(tester, api, () => tester.tap(find.byKey(LiquidationScreen.lateItemKey)));
    await act(tester, api, () => tester.tap(find.byKey(ItemPicker.optionKey(item))));
    await tester.enterText(find.byKey(LiquidationScreen.lateAmountKey), '100');
    await act(tester, api, () => tester.tap(find.byKey(LiquidationScreen.lateAccountKey(bank))));
    await tester.enterText(find.byKey(LiquidationScreen.lateDescriptionKey), 'فاتورة كهرباء متأخرة');
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    final (path, body) = api.sentMoney.single;
    expect(path, '/projects/project-0/liquidation/late');
    expect(body, {'isExpense': true, 'itemId': item, 'date': isA<String>(), 'amount': 100, 'accountId': bank, 'description': 'فاتورة كهرباء متأخرة'});
    expect(find.text('en liquidation.lateRecorded'), findsOneWidget);
  });

  testWidgets('FR-51: late revenue asks no item', (tester) async {
    late String bank;
    final api = await openLiquidation(tester, (api) {
      api.liquidationAnswer = closedWith([]);
      bank = api.addAccount('project-0', 'حساب المؤسسة')['id']! as String;
    }, status: 'finished');

    await tapVisible(tester, api, LiquidationScreen.lateKey);
    await act(tester, api, () => tester.tap(find.byKey(LiquidationScreen.lateRevenueKey)));
    expect(find.byKey(LiquidationScreen.lateItemKey), findsNothing);
    await tester.enterText(find.byKey(LiquidationScreen.lateAmountKey), '50');
    await act(tester, api, () => tester.tap(find.byKey(LiquidationScreen.lateAccountKey(bank))));
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(api.sentMoney.single.$2['isExpense'], isFalse);
    expect(api.sentMoney.single.$2.containsKey('itemId'), isFalse);
  });
}

