import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/direct_entry_fields.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/revenue/revenue_screen.dart';
import 'package:redix/sharing/share_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

/// One way in (redix-api #101): a revenue item's table and a partner are picked from Add entry's table list, for whoever moves money, and sent for approval with one button.
void main() {
  PickedFile picture() => PickedFile('receipt.png', '', Uint8List.fromList(onePixelPng));

  /// A project with an expense item, a revenue item, two partners, one of whom withdrew, and an account, opened as far as Add entry.
  Future<({FakeApi api, FakeCapture capture, String refund, String partner, String gone, String account})> openAddEntry(WidgetTester tester, {List<String> permissions = managerAndFinance}) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة']);
    api.addItem(api.addCategory('project-0', 'التشطيب'), 'البلاط', type: 'purchases');
    final refund = api.addItem(api.addCategory('project-0', 'الإيرادات'), 'استرداد الضريبة', type: 'vatRefund');
    final partner = api.addPartner('project-0', 'نواف');
    final gone = api.addPartner('project-0', 'سالم')..['isActive'] = false;
    final account = api.addAccount('project-0', 'حساب المؤسسة');
    final capture = FakeCapture();
    await openProject(tester, api, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));
    final general = (refund['subgroups']! as List<Map<String, Object>>).first['id']! as String;
    return (api: api, capture: capture, refund: general, partner: partner['id']! as String, gone: gone['id']! as String, account: account['id']! as String);
  }

  Future<void> pick(WidgetTester tester, FakeApi api, String tableId) async {
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.tableKey)));
    await act(tester, api, () => tester.tap(find.byKey(TablePicker.optionKey(tableId))));
  }

  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  group('the table list', () {
    testWidgets('R3, R5, R13: Finance finds the revenue items, and last the active partners under Partners', (tester) async {
      final (:api, capture: _, :refund, :partner, :gone, account: _) = await openAddEntry(tester);

      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.tableKey)));

      expect(text(tester, TablePicker.optionKey(refund).subtitle), 'en categories.tableRevenue');
      expect(find.byKey(TablePicker.categoryKey('en partners.title')), findsOneWidget);
      expect(text(tester, TablePicker.optionKey(partner).title), 'نواف');
      expect(text(tester, TablePicker.optionKey(partner).subtitle), 'en categories.tableCapital');
      expect(find.byKey(TablePicker.optionKey(gone)), findsNothing);
      expect(find.byKey(TablePicker.itemKey(partner)), findsNothing, reason: 'a partner shows once, as its own row');
    });

    testWidgets('R9: someone who moves no money finds no revenue item and no partner', (tester) async {
      final (:api, capture: _, :refund, :partner, gone: _, account: _) = await openAddEntry(tester, permissions: field);

      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.tableKey)));

      expect(find.byKey(TablePicker.optionKey(refund)), findsNothing);
      expect(find.byKey(TablePicker.optionKey(partner)), findsNothing);
      expect(find.byKey(TablePicker.categoryKey('en partners.title')), findsNothing);
    });
  });

  group('a partner', () {
    testWidgets('R2, R7, R11: a contribution with its receipt is sent for approval, and says so', (tester) async {
      final (:api, :capture, refund: _, :partner, gone: _, :account) = await openAddEntry(tester);
      capture.files = picture();
      await pick(tester, api, partner);

      expect(tester.widget<SwitchListTile>(find.byKey(DirectEntryFields.withdrawalKey)).value, isFalse);
      expect(find.byKey(AddEntryScreen.supplierKey), findsNothing);
      expect(find.byKey(AddEntryScreen.creditNoteKey), findsNothing);
      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-0/capital-movements');
      expect((body['partnerId'], body['type'], body['amount'], body['accountId'], body.containsKey('cashReason')), (partner, 'contribution', 1000.0, account, false));
      expect(body['attachmentId'], isNotNull);
      expect(text(tester, AddEntryScreen.savedKey), 'en expenses.sent');
      expect(find.byKey(DirectEntryFields.sendKey), findsNothing);
    });

    testWidgets('R7: with سحب on it is a withdrawal', (tester) async {
      final (:api, :capture, refund: _, :partner, gone: _, :account) = await openAddEntry(tester);
      capture.files = picture();
      await pick(tester, api, partner);

      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.withdrawalKey)));
      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '300');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));

      expect(api.sentMoney.single.$2['type'], 'withdrawal');
    });

    testWidgets('AC-25.1: refused without a receipt, it says why and keeps what was typed', (tester) async {
      final (:api, capture: _, refund: _, :partner, gone: _, account: _) = await openAddEntry(tester);
      api.moneyAnswer = (status: 400, code: 'receiptRequired');
      await pick(tester, api, partner);

      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));

      expect(text(tester, DirectEntryFields.messageKey), 'en capital.receiptRequired');
      expect(tester.widget<TextField>(find.byKey(DirectEntryFields.amountKey)).controller!.text, '1000');
      expect(find.byKey(AddEntryScreen.savedKey), findsNothing);
    });

    testWidgets('AC-25.1: paid in cash asks why instead of a receipt, and sends the reason', (tester) async {
      final (:api, capture: _, refund: _, :partner, gone: _, account: _) = await openAddEntry(tester);
      await pick(tester, api, partner);
      expect(find.byKey(DirectEntryFields.receiptHeadingKey), findsOneWidget);

      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.cashKey)));

      expect(find.byKey(DirectEntryFields.receiptHeadingKey), findsNothing);
      expect(find.byKey(AddEntryScreen.filesKey), findsNothing);
      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '1000');
      await tester.enterText(find.byKey(DirectEntryFields.reasonKey), 'دفع في الموقع');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));
      expect((api.sentMoney.single.$2['cashReason'], api.sentMoney.single.$2.containsKey('attachmentId')), ('دفع في الموقع', false));
    });

    testWidgets('BR-23: a receipt saying another amount warns, and the same amount does not', (tester) async {
      final (:api, capture: _, refund: _, :partner, gone: _, account: _) = await openAddEntry(tester);
      await pick(tester, api, partner);

      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '1000');
      await tester.enterText(find.byKey(DirectEntryFields.receiptAmountKey), '1000');
      await tester.pump();
      expect(find.byKey(DirectEntryFields.receiptDiffersKey), findsNothing);

      await tester.enterText(find.byKey(DirectEntryFields.receiptAmountKey), '900');
      await tester.pump();
      expect(find.byKey(DirectEntryFields.receiptDiffersKey), findsOneWidget);
    });
  });

  group('a revenue item', () {
    testWidgets('R3: revenue is sent for approval on its item and table, with no partner fields', (tester) async {
      final (:api, capture: _, :refund, partner: _, gone: _, :account) = await openAddEntry(tester);
      await pick(tester, api, refund);

      expect(find.byKey(DirectEntryFields.withdrawalKey), findsNothing);
      expect(find.byKey(DirectEntryFields.receiptHeadingKey), findsNothing);
      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '140');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-0/revenue');
      expect((body['subgroupId'], body['amount'], body['accountId']), (refund, 140.0, account));
      expect(body['itemId'], isNotEmpty);
      expect(text(tester, AddEntryScreen.savedKey), 'en expenses.sent');
    });

    testWidgets('R10: an amount that is no number stops it before it is sent, and nothing is lost', (tester) async {
      final (:api, capture: _, :refund, partner: _, gone: _, account: _) = await openAddEntry(tester);
      await pick(tester, api, refund);

      await tester.enterText(find.byKey(DirectEntryFields.descriptionKey), 'استرداد الربع الثالث');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));

      expect(api.sentMoney, isEmpty);
      expect(text(tester, DirectEntryFields.messageKey), 'en revenue.invalidAmount');
      expect(tester.widget<TextField>(find.byKey(DirectEntryFields.descriptionKey)).controller!.text, 'استرداد الربع الثالث');
    });

    testWidgets('D9: a revenue or partner entry has one button, never a draft; an expense keeps its draft', (tester) async {
      final (:api, capture: _, :refund, partner: _, gone: _, account: _) = await openAddEntry(tester);
      expect(find.byKey(AddEntryScreen.draftKey), findsOneWidget);

      await pick(tester, api, refund);

      expect(find.byKey(AddEntryScreen.draftKey), findsNothing);
      expect(find.byKey(AddEntryScreen.sendKey), findsNothing);
      expect(find.byKey(DirectEntryFields.sendKey), findsOneWidget);
    });
  });

  group('the screens that lost their buttons', () {
    testWidgets('R1: Partners has no حركة, and still shows the total and its partners', (tester) async {
      final (:api, capture: _, refund: _, :partner, gone: _, account: _) = await openAddEntry(tester);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await tester.ensureVisible(find.byKey(HomeScreen.partnersKey('project-0')));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.partnersKey('project-0'))));

      expect(find.byKey(PartnersScreen.totalKey), findsOneWidget);
      expect(find.byKey(PartnersScreen.nameKey(partner)), findsOneWidget);
      expect(find.byKey(const Key('partners.move')), findsNothing);
    });

    testWidgets('R8: Revenue has no New revenue, and keeps New sale for whoever moves money', (tester) async {
      final (:api, capture: _, refund: _, partner: _, gone: _, account: _) = await openAddEntry(tester);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await tester.ensureVisible(find.byKey(HomeScreen.revenueKey('project-0')));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.revenueKey('project-0'))));

      expect(find.byKey(const Key('revenue.new')), findsNothing);
      expect(find.byKey(RevenueScreen.newSaleKey), findsOneWidget);
    });

    testWidgets('R12: a shared file offers New entry and no capital receipt, and goes with a partner picked in Add entry', (tester) async {
      final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance, units: ['الفلة']);
      final partner = api.addPartner('project-0', 'نواف')['id']! as String;
      final account = api.addAccount('project-0', 'حساب المؤسسة')['id']! as String;
      final capture = FakeCapture();
      await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
      capture.share(picture());
      await act(tester, api, () async {});

      expect(find.byKey(const Key('share.capitalReceipt')), findsNothing);
      await tester.ensureVisible(find.byKey(ShareScreen.newExpenseKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(ShareScreen.newExpenseKey)));
      await pick(tester, api, partner);
      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));

      expect(capture.cameraOpened, 0);
      expect(api.sentMoney.single.$2['attachmentId'], isNotNull);
    });
  });
}
