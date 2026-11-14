import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/sharing/share_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';
import 'package:redix/ui/messages.dart';

/// One entry for every table (redix-api #110): a revenue item's table and a partner are picked from Add entry's table list, for whoever moves money, and entered in the same form
/// as an expense, sent through the same route, as a draft or for approval, kept on the phone without a network, and fixed after a rejection.
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
    api.addColumn('/projects/project-0/items/${partner['itemId']}/columns', 'نوع الحركة', key: 'movementType', dataType: 'list', isCore: true, choices: [FakeApi.choice('choice-contribution', 'إضافة مبلغ', sign: 'plus'), FakeApi.choice('choice-withdrawal', 'سحب مبلغ', sign: 'minus')]);
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
    testWidgets('R8: a contribution with its receipt is sent for approval through the one route, asking no payment method, and says so', (tester) async {
      final (:api, :capture, refund: _, :partner, :account) = await openAddEntry(tester);
      capture.files = picture();
      await pick(tester, api, partner);

      expect(find.byKey(AddEntryScreen.columnKey('movementType')), findsOneWidget);
      expect(find.byKey(AddEntryScreen.supplierKey), findsNothing);
      expect(find.byKey(AddEntryScreen.columnKey('entryType')), findsNothing);
      expect(find.byKey(PaymentChoices.methodChoiceKey), findsNothing);
      await tester.enterText(find.byKey(AddEntryScreen.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(PaymentChoices.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      final body = api.sentEntries.single;
      expect(api.sentEntryPaths.single, '/projects/project-0/entries');
      expect((body['itemId'], body['tableId'], body.containsKey('isWithdrawal'), body['amount'], body['accountId'], body['submit']), ('item-capital', partner, false, 1000.0, account, true));
      expect((body.containsKey('paymentMethodId'), body.containsKey('supplierId')), (false, false));
      expect(body['attachmentId'], isNotNull);
      expect(text(tester, messageKeyOf('expenses.sent').label), 'en expenses.sent');
      expect(find.byKey(AddEntryScreen.sendKey), findsNothing);
    });

    testWidgets('redix-app #83 R1: once sent, the message offers Share, which hands the partner\'s money the API now lists to the share sheet', (tester) async {
      final (:api, :capture, refund: _, :partner, :account) = await openAddEntry(tester);
      capture.files = picture();
      await pick(tester, api, partner);
      await tester.enterText(find.byKey(AddEntryScreen.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(PaymentChoices.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));

      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));
      final id = api.sentEntries.single['id']! as String;
      api.addEntry(id: id, kind: 'capitalIn', partnerName: 'نواف', amount: 1000);
      await act(tester, api, () => tester.tap(find.byKey(messageKeyOf('expenses.sent').icon)));

      final lines = capture.sharedTexts.single.split('\n');
      expect((lines.first, lines[1], lines.last), ('en capital.contribution · غصون 6', 'en entryShare.partner: نواف', 'https://redix.test/projects/project-0/entries/$id/open'));
    });

    testWidgets('R7, redix-api #129: «سحب مبلغ» of «نوع الحركة» makes it a withdrawal', (tester) async {
      final (:api, :capture, refund: _, :partner, :account) = await openAddEntry(tester);
      capture.files = picture();
      await pick(tester, api, partner);

      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.columnKey('movementType'))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.columnOptionKey('movementType', 'choice-withdrawal').label).hitTestable()));
      await tester.enterText(find.byKey(AddEntryScreen.amountKey), '300');
      await act(tester, api, () => tester.tap(find.byKey(PaymentChoices.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.filesKey)));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      expect((api.sentEntries.single['columnValues'] as Map<String, dynamic>)['movementType'], 'choice-withdrawal');
    });

    testWidgets('Muteb, 8 Nov 2026: a contribution is one amount and is sent as it is, its receipt optional like every entry\'s, with no cash switch and no second amount', (tester) async {
      final (:api, capture: _, refund: _, :partner, :account) = await openAddEntry(tester);
      await pick(tester, api, partner);

      expect(find.byType(SwitchListTile), findsOneWidget, reason: 'only سحب; no "paid in cash"');
      expect(find.byKey(AddEntryScreen.amountKey), findsOneWidget);
      await tester.enterText(find.byKey(AddEntryScreen.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(PaymentChoices.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      final body = api.sentEntries.single;
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
      expect(tester.getTopLeft(find.byKey(AddEntryScreen.cameraKey)).dy < tester.getTopLeft(find.byKey(AddEntryScreen.amountKey)).dy, isTrue);
    });
  });

  group('a revenue item', () {
    testWidgets('R3: revenue is sent for approval on its item and table, with no partner fields', (tester) async {
      final (:api, capture: _, :refund, partner: _, :account) = await openAddEntry(tester);
      await pick(tester, api, refund);

      expect(find.byKey(AddEntryScreen.columnKey('movementType')), findsNothing);
      await tester.enterText(find.byKey(AddEntryScreen.amountKey), '140');
      await act(tester, api, () => tester.tap(find.byKey(PaymentChoices.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      final body = api.sentEntries.single;
      expect(api.sentEntryPaths.single, '/projects/project-0/entries');
      expect((body['tableId'], body['amount'], body['accountId'], body.containsKey('isWithdrawal'), body.containsKey('paymentMethodId')), (refund, 140.0, account, false, false));
      expect(body['itemId'], isNotEmpty);
      expect(find.byKey(AddEntryScreen.supplierKey), findsNothing);
      expect(text(tester, messageKeyOf('expenses.sent').label), 'en expenses.sent');
    });

    testWidgets('R10: an amount that is no number stops it before it is sent, and nothing is lost', (tester) async {
      final (:api, capture: _, :refund, partner: _, account: _) = await openAddEntry(tester);
      await pick(tester, api, refund);

      await tester.enterText(find.byKey(AddEntryScreen.amountKey), 'كثير');
      await tester.enterText(find.byKey(AddEntryScreen.descriptionKey), 'استرداد الربع الثالث');
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      expect(api.sentEntries, isEmpty);
      expect(text(tester, AddEntryScreen.messageKey), 'en expenses.invalidAmount');
      expect(tester.widget<TextField>(find.byKey(AddEntryScreen.descriptionKey)).controller!.text, 'استرداد الربع الثالث');
    });

    testWidgets('R8, D6 (Muteb, 9 Nov 2026, reversing redix-api #101 D9): revenue is saved as a draft, as an expense is', (tester) async {
      final (:api, capture: _, :refund, partner: _, :account) = await openAddEntry(tester);
      await pick(tester, api, refund);
      await tester.enterText(find.byKey(AddEntryScreen.amountKey), '140');
      await act(tester, api, () => tester.tap(find.byKey(PaymentChoices.accountKey(account))));

      await tester.ensureVisible(find.byKey(AddEntryScreen.draftKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.draftKey)));

      expect(api.sentEntries.single['submit'], isFalse);
      expect(text(tester, messageKeyOf('expenses.saved').label), 'en expenses.saved');
    });

    testWidgets('R8, D12: without a network a partner\'s money is kept on the phone, as an expense is', (tester) async {
      final (:api, capture: _, refund: _, :partner, :account) = await openAddEntry(tester);
      await pick(tester, api, partner);
      await tester.enterText(find.byKey(AddEntryScreen.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(PaymentChoices.accountKey(account))));
      api.online = false;

      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      expect(text(tester, messageKeyOf('expenses.keptOnPhone').label), 'en expenses.keptOnPhone');
      expect(find.byKey(HomeScreen.waitingKey('project-0')), findsOneWidget);
    });
  });

  group('the screens that lost their buttons', () {
    testWidgets('R1: Partners has no حركة, and still shows the total and its partners', (tester) async {
      final (:api, capture: _, refund: _, :partner, account: _) = await openAddEntry(tester);
      await act(tester, api, () => tester.pageBack());

      await showProjectSetting(tester, HomeScreen.partnersKey('project-0'));
      await tester.ensureVisible(projectSettingPages);
      await scrollAndTap(tester, api, HomeScreen.partnersKey('project-0'));

      expect(find.byKey(PartnersScreen.totalKey), findsOneWidget);
      expect(find.byKey(PartnersScreen.nameKey(partner)), findsOneWidget);
    });

    testWidgets('No Revenue screen: the home has no Revenue, and القيود lists revenue and a partner\'s money, each saying what it is', (tester) async {
      final (:api, capture: _, refund: _, partner: _, account: _) = await openAddEntry(tester);
      api
        ..addEntry(kind: 'revenue', status: 'approved', itemName: 'استرجاع ضرائب', amount: 140)
        ..addEntry(kind: 'capitalOut', status: 'pendingApproval', itemName: '', partnerName: 'نواف', amount: 300);
      await act(tester, api, () => tester.pageBack());

      expect(text(tester, EntriesScreen.rowKey('entry-0').title), 'استرجاع ضرائب');
      expect(text(tester, EntriesScreen.detailsKey('entry-0')), startsWith('en categories.tableRevenue'));
      expect(text(tester, EntriesScreen.rowKey('entry-1').title), 'نواف');
      expect(text(tester, EntriesScreen.detailsKey('entry-1')), startsWith('en capital.withdrawal'));
    });

    testWidgets('R14, redix-api #119: an approved revenue entry\'s sheet offers no Edit, and no حذف without the removal; a rejected one offers Fix, as an expense\'s does', (tester) async {
      final (:api, capture: _, refund: _, partner: _, account: _) = await openAddEntry(tester);
      api
        ..addEntry(kind: 'revenue', status: 'approved', itemName: 'استرجاع ضرائب', amount: 140)
        ..addEntry(kind: 'revenue', status: 'rejected', itemName: 'استرجاع ضرائب', amount: 90, rejectionReason: 'المبلغ خطأ');
      await act(tester, api, () => tester.pageBack());

      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey('entry-0'))));
      expect(find.byKey(AddEntryScreen.removeKey), findsNothing);
      expect(isEnabled(tester, AddEntryScreen.changeKey), isFalse);
      await act(tester, api, () => tester.pageBack());

      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey('entry-1'))));
      expect(text(tester, AddEntryScreen.changeKey.label), 'en entries.fix');
    });

    testWidgets('R12: a shared file offers New entry and no capital receipt, and goes with a partner picked in Add entry', (tester) async {
      final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance, units: ['الفلة']);
      final partner = api.addPartner('project-0', 'نواف')['id']! as String;
      final account = api.addAccount('project-0', 'حساب المؤسسة')['id']! as String;
      final capture = FakeCapture();
      await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
      capture.share(picture());
      await act(tester, api, () async {});

      await tester.ensureVisible(find.byKey(ShareScreen.newExpenseKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(ShareScreen.newExpenseKey)));
      await pick(tester, api, partner);
      await tester.enterText(find.byKey(AddEntryScreen.amountKey), '1000');
      await act(tester, api, () => tester.tap(find.byKey(PaymentChoices.accountKey(account))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      expect(capture.cameraOpened, 0);
      expect(api.sentEntries.single['attachmentId'], isNotNull);
    });
  });

  testWidgets('R14: a rejected partner entry opens in Add entry in its partner\'s table, with what it held, and is sent again to its own entry', (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: managerAndFinance, units: ['الفلة']);
    final added = api.addPartner('project-0', 'نواف');
    final partner = added['id']! as String;
    api.addColumn('/projects/project-0/items/${added['itemId']}/columns', 'نوع الحركة', key: 'movementType', dataType: 'list', isCore: true, choices: [FakeApi.choice('choice-contribution', 'إضافة مبلغ', sign: 'plus'), FakeApi.choice('choice-withdrawal', 'سحب مبلغ', sign: 'minus')]);
    final account = api.addAccount('project-0', 'حساب المؤسسة')['id']! as String;
    api
      ..addEntry(kind: 'capitalOut', status: 'rejected', rejectionReason: 'أرفق الإيصال', itemName: '', partnerName: 'نواف', amount: 300)
      ..entryDetails['entry-0'] = {
        'tableId': partner,
        'entry': {'id': 'entry-0', 'kind': 'capitalOut', 'status': 'rejected', 'entryDate': '2026-11-05', 'amount': 300, 'accountId': account, 'description': 'سحب', 'columnValues': '{"movementType":"choice-withdrawal"}'},
        'expense': {'itemId': '00000000-0000-0000-0000-000000000000', 'subgroupId': '00000000-0000-0000-0000-000000000000', 'paymentMethodId': '00000000-0000-0000-0000-000000000000'},
        'purchase': {'supplierId': '00000000-0000-0000-0000-000000000000'},
        'contractorPayment': {'contractId': '00000000-0000-0000-0000-000000000000', 'isOutsideContract': false},
        'attachments': const <Object>[],
      };
    await openProject(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.searchEntriesKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.searchEntriesKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey('entry-0'))));

    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.changeKey)));

    expect(tester.widget<TablePicker>(find.byKey(AddEntryScreen.tableKey)).chosen.id, partner);
    expect(tester.widget<DropdownButtonFormField<String>>(find.byKey(AddEntryScreen.columnKey('movementType'))).initialValue, 'choice-withdrawal');
    await tester.ensureVisible(find.byKey(AddEntryScreen.sendKey));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

    expect(api.sentEntryPaths.single, 'PUT /projects/project-0/entries/entry-0');
    final body = api.sentEntries.single;
    expect((body['tableId'], (body['columnValues'] as Map<String, dynamic>)['movementType'], body['amount'], body['accountId'], body['description'], body['submit']), (partner, 'choice-withdrawal', 300, account, 'سحب', true));
  });
}
