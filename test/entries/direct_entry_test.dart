import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/direct_entry_fields.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/sharing/share_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';
import 'package:redix/ui/refusal_snack_bar.dart';

/// One way in (redix-api #101): a revenue item's table and a partner are picked from Add entry's table list, for whoever moves money, and sent for approval with one button.
void main() {
  PickedFile picture() => PickedFile('receipt.png', '', Uint8List.fromList(onePixelPng));

  /// A project with an expense item, a revenue item, a partner and an account, opened as far as Add entry.
  Future<({FakeApi api, FakeCapture capture, String refund, String partner, String account})> openAddEntry(WidgetTester tester, {List<String> permissions = managerAndFinance}) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة']);
    api.addItem(api.addCategory('project-0', 'التشطيب'), 'البلاط', type: 'purchases');
    final refund = api.addItem(api.addCategory('project-0', 'الإيرادات'), 'استرداد الضريبة', type: 'vatRefund');
    final partner = api.addPartner('project-0', 'نواف');
    final account = api.addAccount('project-0', 'حساب المؤسسة');
    final capture = FakeCapture();
    await openProject(tester, api, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));
    final general = (refund['subgroups']! as List<Map<String, Object>>).first['id']! as String;
    return (api: api, capture: capture, refund: general, partner: partner['id']! as String, account: account['id']! as String);
  }

  Future<void> pick(WidgetTester tester, FakeApi api, String tableId) async {
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.tableKey)));
    await act(tester, api, () => tester.tap(find.byKey(TablePicker.optionKey(tableId))));
  }

  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  group('the table list', () {
    testWidgets('R3, R5, R13, redix-api #109: Finance finds the revenue items, and the partners as the tables of رأس المال', (tester) async {
      final (:api, capture: _, :refund, :partner, account: _) = await openAddEntry(tester);

      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.tableKey)));

      expect(text(tester, TablePicker.optionKey(refund).subtitle), 'en categories.tableRevenue');
      expect(find.byKey(TablePicker.categoryKey('رأس المال')), findsOneWidget);
      expect(text(tester, TablePicker.itemKey('item-capital').title), 'رأس المال');
      expect(text(tester, TablePicker.optionKey(partner).title), 'نواف');
      expect(text(tester, TablePicker.optionKey(partner).subtitle), 'en categories.tableCapital');
    });

    testWidgets('redix-api #109 (Muteb, 8 Nov 2026: "راس المال" found nothing): the search finds رأس المال by its name in either spelling, with every partner under it', (tester) async {
      final (:api, capture: _, :refund, :partner, account: _) = await openAddEntry(tester);
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.tableKey)));

      await tester.enterText(find.byKey(TablePicker.searchKey), 'راس المال');
      await tester.pumpAndSettle();

      expect(find.byKey(TablePicker.optionKey(partner)), findsOneWidget);
      expect(find.byKey(TablePicker.optionKey(refund)), findsNothing);
      expect(find.byKey(TablePicker.noMatchKey), findsNothing);
    });

    testWidgets('R9: someone who moves no money finds no revenue item and no partner', (tester) async {
      final (:api, capture: _, :refund, :partner, account: _) = await openAddEntry(tester, permissions: field);

      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.tableKey)));

      expect(find.byKey(TablePicker.optionKey(refund)), findsNothing);
      expect(find.byKey(TablePicker.optionKey(partner)), findsNothing);
      expect(find.byKey(TablePicker.categoryKey('رأس المال')), findsNothing);
    });
  });

  group('a partner', () {
    testWidgets('R2, R7, R11: a contribution with its receipt is sent for approval, and says so', (tester) async {
      final (:api, :capture, refund: _, :partner, :account) = await openAddEntry(tester);
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
      expect(text(tester, messageKeyOf('expenses.sent').label), 'en expenses.sent');
      expect(find.byKey(DirectEntryFields.sendKey), findsNothing);
    });

    testWidgets('redix-app #83 R1: once sent, the message offers Share, which hands the partner\'s money the API now lists to the share sheet', (tester) async {
      final (:api, :capture, refund: _, :partner, :account) = await openAddEntry(tester);
      capture.files = picture();
      await pick(tester, api, partner);
      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));

      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));
      api.addEntry(id: 'sent-1', kind: 'capitalIn', partnerName: 'نواف', amount: 1000);
      await act(tester, api, () => tester.tap(find.byKey(messageKeyOf('expenses.sent').icon)));

      final lines = capture.sharedTexts.single.split('\n');
      expect((lines.first, lines[1], lines.last), ('en capital.contribution · غصون 6', 'en entryShare.partner: نواف', 'https://redix.test/projects/project-0/entries/sent-1/open'));
    });

    testWidgets('R7: with سحب on it is a withdrawal', (tester) async {
      final (:api, :capture, refund: _, :partner, :account) = await openAddEntry(tester);
      capture.files = picture();
      await pick(tester, api, partner);

      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.withdrawalKey)));
      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '300');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));

      expect(api.sentMoney.single.$2['type'], 'withdrawal');
    });

    testWidgets('Muteb, 8 Nov 2026: a contribution is one amount and is sent as it is, its receipt optional like every entry\'s, with no cash switch and no second amount', (tester) async {
      final (:api, capture: _, refund: _, :partner, :account) = await openAddEntry(tester);
      await pick(tester, api, partner);

      expect(find.byType(SwitchListTile), findsOneWidget, reason: 'only سحب; no "paid in cash"');
      expect(find.byKey(DirectEntryFields.amountKey), findsOneWidget);
      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));

      final body = api.sentMoney.single.$2;
      expect((body['amount'], body.containsKey('attachmentId'), body.containsKey('cashReason')), (1000.0, false, false));
      expect(text(tester, messageKeyOf('expenses.sent').label), 'en expenses.sent');
    });

    testWidgets('Muteb, 8 Nov 2026: Add entry never opens the camera by itself, and the photo stays where it was when a table is picked', (tester) async {
      final (:api, :capture, refund: _, :partner, account: _) = await openAddEntry(tester);
      expect(capture.cameraOpened, 0);
      capture.camera = picture();
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.cameraKey)));
      final before = tester.getTopLeft(find.byKey(AddEntryScreen.cameraKey));

      await pick(tester, api, partner);

      expect(capture.cameraOpened, 1);
      expect(tester.getTopLeft(find.byKey(AddEntryScreen.cameraKey)), before);
      expect(tester.getTopLeft(find.byKey(AddEntryScreen.cameraKey)).dy < tester.getTopLeft(find.byKey(DirectEntryFields.amountKey)).dy, isTrue);
    });
  });

  group('a revenue item', () {
    testWidgets('R3: revenue is sent for approval on its item and table, with no partner fields', (tester) async {
      final (:api, capture: _, :refund, partner: _, :account) = await openAddEntry(tester);
      await pick(tester, api, refund);

      expect(find.byKey(DirectEntryFields.withdrawalKey), findsNothing);
      await tester.enterText(find.byKey(DirectEntryFields.amountKey), '140');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));

      final (path, body) = api.sentMoney.single;
      expect(path, '/projects/project-0/revenue');
      expect((body['subgroupId'], body['amount'], body['accountId']), (refund, 140.0, account));
      expect(body['itemId'], isNotEmpty);
      expect(text(tester, messageKeyOf('expenses.sent').label), 'en expenses.sent');
    });

    testWidgets('R10: an amount that is no number stops it before it is sent, and nothing is lost', (tester) async {
      final (:api, capture: _, :refund, partner: _, account: _) = await openAddEntry(tester);
      await pick(tester, api, refund);

      await tester.enterText(find.byKey(DirectEntryFields.descriptionKey), 'استرداد الربع الثالث');
      await act(tester, api, () => tester.tap(find.byKey(DirectEntryFields.sendKey)));

      expect(api.sentMoney, isEmpty);
      expect(text(tester, DirectEntryFields.messageKey), 'en revenue.invalidAmount');
      expect(tester.widget<TextField>(find.byKey(DirectEntryFields.descriptionKey)).controller!.text, 'استرداد الربع الثالث');
    });

    testWidgets('D9: a revenue or partner entry has one button, never a draft; an expense keeps its draft', (tester) async {
      final (:api, capture: _, :refund, partner: _, account: _) = await openAddEntry(tester);
      expect(find.byKey(AddEntryScreen.draftKey), findsOneWidget);

      await pick(tester, api, refund);

      expect(find.byKey(AddEntryScreen.draftKey), findsNothing);
      expect(find.byKey(AddEntryScreen.sendKey), findsNothing);
      expect(find.byKey(DirectEntryFields.sendKey), findsOneWidget);
    });
  });

  group('the screens that lost their buttons', () {
    testWidgets('R1: Partners has no حركة, and still shows the total and its partners', (tester) async {
      final (:api, capture: _, refund: _, :partner, account: _) = await openAddEntry(tester);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await tester.ensureVisible(find.byKey(HomeScreen.partnersKey('project-0')));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.partnersKey('project-0'))));

      expect(find.byKey(PartnersScreen.totalKey), findsOneWidget);
      expect(find.byKey(PartnersScreen.nameKey(partner)), findsOneWidget);
      expect(find.byKey(const Key('partners.move')), findsNothing);
    });

    testWidgets('No Revenue screen: the home has no Revenue, and القيود lists revenue and a partner\'s money, each saying what it is', (tester) async {
      final (:api, capture: _, refund: _, partner: _, account: _) = await openAddEntry(tester);
      api
        ..addEntry(kind: 'revenue', status: 'approved', itemName: 'استرجاع ضرائب', amount: 140)
        ..addEntry(kind: 'capitalOut', status: 'pendingApproval', itemName: '', partnerName: 'نواف', amount: 300);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      expect(find.byKey(const Key('home.revenue.project-0')), findsNothing);
      expect(text(tester, EntriesScreen.rowKey('entry-0').title), 'استرجاع ضرائب');
      expect(text(tester, EntriesScreen.detailsKey('entry-0')), startsWith('en categories.tableRevenue'));
      expect(text(tester, EntriesScreen.rowKey('entry-1').title), 'نواف');
      expect(text(tester, EntriesScreen.detailsKey('entry-1')), startsWith('en capital.withdrawal'));
    });

    testWidgets('No Revenue screen: a revenue entry\'s sheet offers Reverse and never Edit, which only an expense has', (tester) async {
      final (:api, capture: _, refund: _, partner: _, account: _) = await openAddEntry(tester);
      api
        ..addEntry(kind: 'revenue', status: 'approved', itemName: 'استرجاع ضرائب', amount: 140)
        ..addEntry(kind: 'revenue', status: 'rejected', itemName: 'استرجاع ضرائب', amount: 90, rejectionReason: 'المبلغ خطأ');
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey('entry-0'))));
      expect(find.byKey(EntriesScreen.reverseKey), findsOneWidget);
      expect(find.byKey(EntriesScreen.editKey), findsNothing);
      await act(tester, api, () => tester.tapAt(const Offset(10, 10)));

      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey('entry-1'))));
      expect(find.byKey(EntriesScreen.editKey), findsNothing);
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
