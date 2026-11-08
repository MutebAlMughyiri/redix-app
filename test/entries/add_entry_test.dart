import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/expenses/original_invoice_picker.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/offline/outbox.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/change_dialog.dart';

import '../app_harness.dart';
import 'package:redix/ui/refusal_snack_bar.dart';
import 'package:redix/ui/part_keys.dart';

void main() {
  /// A project with an item, a supplier, a supplier with no number, a payment method, and an account the signed-in user holds and one they do not, opened as far as a new expense.
  Future<({FakeApi api, FakeCapture capture, String item, String otherItem, String supplier, String cash, String method, String custody, String bank})> openExpense(
    WidgetTester tester, {
    List<String> permissions = field,
    List<String> units = const ['الفلة الغربية'],
    PickedFile? camera,
    void Function(FakeApi api)? arrange,
  }) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: units);
    final category = api.addCategory('project-0', 'التشطيب');
    final item = api.addItem(category, 'البلاط', subgroups: ['مواد']);
    final otherItem = api.addItem(category, 'الجبس');
    for (final added in [item, otherItem]) {
      for (final key in ['product', 'unitPrice', 'quantity', 'notes']) {
        api.addColumn('/projects/project-0/items/${added['id']}/columns', key);
      }
    }
    final supplier = api.addSupplier('project-0', 'شركة النخيل', vatNumber: '300000000000003');
    final cash = api.addSupplier('project-0', 'مورد نقدي عام');
    final method = api.addPaymentMethod('project-0', 'شبكة');
    api.addPaymentMethod('project-0', 'معطّلة', isActive: false);
    final custody = api.addAccount('project-0', 'عهدتي', type: 'cashCustody', isMine: true);
    final bank = api.addAccount('project-0', 'حساب المؤسسة');
    arrange?.call(api);
    final capture = FakeCapture()..camera = camera ?? PickedFile.none();
    await openProject(tester, api, capture: capture);
    await tester.ensureVisible(find.byKey(HomeScreen.addEntryKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));
    return (
      api: api,
      capture: capture,
      item: item['id']! as String,
      otherItem: otherItem['id']! as String,
      supplier: supplier['id']! as String,
      cash: cash['id']! as String,
      method: method['id']! as String,
      custody: custody['id']! as String,
      bank: bank['id']! as String,
    );
  }

  Future<void> tapVisible(WidgetTester tester, FakeApi api, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(key)));
  }

  Future<void> type(WidgetTester tester, Key key, String text) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(key), text);
    await tester.pumpAndSettle();
  }

  String shown(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Future<void> pickSupplier(WidgetTester tester, FakeApi api, String id) async {
    await tapVisible(tester, api, AddEntryScreen.supplierKey);
    await act(tester, api, () => tester.tap(find.byKey(SupplierPicker.rowKey(id))));
  }

  /// Chooses the general table of the item [id].
  Future<void> pickItem(WidgetTester tester, FakeApi api, String id) async {
    final item = api.categories['project-0']!.expand((category) => category['items']! as List<Map<String, Object>>).singleWhere((item) => item['id'] == id);
    await tapVisible(tester, api, AddEntryScreen.tableKey);
    await act(tester, api, () => tester.tap(find.byKey(TablePicker.optionKey((item['subgroups']! as List<Map<String, Object>>).first['id']! as String))));
  }

  /// The tables of the item [id]: its general one first, then each named one.
  List<String> tableIdsOf(FakeApi api, String id) => [
    for (final subgroup in api.categories['project-0']!.expand((category) => category['items']! as List<Map<String, Object>>).singleWhere((item) => item['id'] == id)['subgroups']! as List<Map<String, Object>>)
      subgroup['id']! as String,
  ];

  String chosenTable(WidgetTester tester) => tester.widget<TablePicker>(find.byKey(AddEntryScreen.tableKey)).chosen.label;

  /// Fills everything an expense needs, for a test whose subject is something else.
  Future<void> fill(WidgetTester tester, ({FakeApi api, FakeCapture capture, String item, String otherItem, String supplier, String cash, String method, String custody, String bank}) opened) async {
    await pickItem(tester, opened.api, opened.item);
    await pickSupplier(tester, opened.api, opened.supplier);
    await type(tester, AddEntryScreen.amountKey, '6000');
    await tapVisible(tester, opened.api, PaymentChoices.paymentMethodKey(opened.method));
  }

  testWidgets('what a person types in Arabic digits counts', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);

    await type(tester, AddEntryScreen.amountKey, '٦٠٠٠');
    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect(opened.api.sentExpenses.single['amount'], 6000);
  });

  testWidgets('saving a draft sends what was typed and chosen, never a figure, with an id made on the phone', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    await type(tester, AddEntryScreen.productKey, 'مواد لياسة');
    await type(tester, AddEntryScreen.notesKey, 'ملاحظة');

    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    final body = opened.api.sentExpenses.single;
    expect(body['itemId'], opened.item);
    expect(body['supplierId'], opened.supplier);
    expect(body['paymentDate'], DateTime.now().toIso8601String().substring(0, 10));
    expect(body['product'], 'مواد لياسة');
    expect(body['notes'], 'ملاحظة');
    expect(body['amount'], 6000);
    for (final gone in ['invoiceNumber', 'invoiceDate', 'amountIncludesVat', 'isNotTaxable', 'discount', 'withoutInvoiceReason']) {
      expect(body.containsKey(gone), isFalse);
    }
    expect(body['accountId'], opened.custody);
    expect(body['paymentMethodId'], opened.method);
    expect(body['submit'], isFalse);
    expect(body['id'], matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    for (final figure in ['vat', 'total', 'amountAfterDiscount', 'amountBeforeDiscount']) {
      expect(body.containsKey(figure), isFalse);
    }
    expect(shown(tester, messageKeyOf('expenses.saved').label), 'en expenses.saved');
    expect(find.byKey(AddEntryScreen.sendKey), findsNothing);
  });

  testWidgets('FR-09: sending keeps the invoice first and names it', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng)));
    await fill(tester, opened);

    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    expect(opened.api.sentAttachments.single, contains('invoice.png'));
    expect(opened.api.sentExpenses.single['attachmentId'], startsWith('attachment-'));
    expect(opened.api.sentExpenses.single['submit'], isTrue);
    expect(shown(tester, messageKeyOf('expenses.sent').label), 'en expenses.sent');
  });

  testWidgets('a refusal stays on the screen with what was typed, and trying again sends the file once and the same id', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng)));
    await fill(tester, opened);
    opened.api.expenseAnswer = (status: 400, body: const {'code': 'invalidPaymentDate'});

    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    expect(shown(tester, AddEntryScreen.messageKey), 'en expenses.invalidPaymentDate');
    expect(tester.widget<TextField>(find.byKey(AddEntryScreen.amountKey)).controller!.text, '6000');

    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    expect(opened.api.sentAttachments, hasLength(1));
    expect(opened.api.sentExpenses[1]['id'], opened.api.sentExpenses[0]['id']);
    expect(opened.api.sentExpenses[1]['attachmentId'], opened.api.sentExpenses[0]['attachmentId']);
  });

  testWidgets('a picture taken again is kept again', (tester) async {
    final picture = PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng));
    final opened = await openExpense(tester, camera: picture);
    await fill(tester, opened);
    opened.api.expenseAnswer = (status: 400, body: const {'code': 'invalidPaymentDate'});
    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    await tapVisible(tester, opened.api, AddEntryScreen.cameraKey);
    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    expect(opened.api.sentAttachments, hasLength(2));
  });

  testWidgets('a file the API refuses says why, and the expense is not sent', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng)));
    await fill(tester, opened);
    opened.api.attachmentAnswer = (status: 400, code: 'imageTooLarge');

    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    expect(shown(tester, AddEntryScreen.messageKey), 'en attachments.imageTooLarge');
    expect(opened.api.sentExpenses, isEmpty);
  });

  testWidgets('what is not a number is refused here, and nothing is sent', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    await type(tester, AddEntryScreen.amountKey, 'كثير');

    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect(shown(tester, AddEntryScreen.messageKey), 'en expenses.invalidAmount');
    expect(opened.api.sentExpenses, isEmpty);
  });

  testWidgets('without a network the expense is kept on the phone, and the screen says so', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    opened.api.online = false;

    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect(shown(tester, messageKeyOf('expenses.keptOnPhone').label), 'en expenses.keptOnPhone');
    expect(find.byKey(HomeScreen.waitingKey('project-0')), findsOneWidget);
  });

  testWidgets('AC-16.1: five expenses with their photos, entered with no network, all go within a minute of it returning', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng)));
    for (var entered = 1; entered <= 5; entered++) {
      await fill(tester, opened);
      opened.api.online = false;
      await tapVisible(tester, opened.api, AddEntryScreen.cameraKey);
      await tapVisible(tester, opened.api, AddEntryScreen.draftKey);
      expect(find.text('en offline.title · $entered'), findsOneWidget);
      if (entered < 5) {
        await tester.ensureVisible(find.byKey(HomeScreen.addEntryKey('project-0')));
        await act(tester, opened.api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));
      }
    }

    opened.api.online = true;
    await act(tester, opened.api, () => tester.pump(Outbox.tryEvery));

    expect(opened.api.sentExpenses, hasLength(5));
    expect(opened.api.sentAttachments, hasLength(5));
    expect(opened.api.sentExpenses.map((body) => body['id']).toSet(), hasLength(5));
    expect(find.byKey(HomeScreen.waitingKey('project-0')), findsNothing);
  });

  testWidgets('AC-16.3: an upload cut after its file went keeps the file\'s id, and sends the entry once', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng)));
    await fill(tester, opened);
    opened.api.online = false;
    await tapVisible(tester, opened.api, AddEntryScreen.cameraKey);
    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    opened.api
      ..online = true
      ..expenseAnswer = (status: 503, body: const <String, dynamic>{});
    await act(tester, opened.api, () => tester.pump(Outbox.tryEvery));
    expect(opened.api.sentAttachments, hasLength(1));
    expect(find.byKey(HomeScreen.waitingKey('project-0')), findsOneWidget);

    opened.api.expenseAnswer = (status: 201, body: const <String, dynamic>{});
    await act(tester, opened.api, () => tester.pump(Outbox.tryEvery));

    expect(opened.api.sentAttachments, hasLength(1));
    expect(opened.api.sentExpenses.last['attachmentId'], startsWith('attachment-'));
    expect(find.byKey(HomeScreen.waitingKey('project-0')), findsNothing);
  });

  testWidgets('AC-41.1: a required custom column is marked, asked only in its item, and the refusal marks its field', (tester) async {
    final opened = await openExpense(tester);
    opened.api.addColumn('/projects/project-0/items/${opened.item}/columns', 'custom.area', dataType: 'number', isCustom: true, isRequired: true);

    await pickItem(tester, opened.api, opened.otherItem);
    expect(find.byKey(AddEntryScreen.columnKey('custom.area')), findsNothing);

    await pickItem(tester, opened.api, opened.item);
    expect(find.text('custom.area *'), findsOneWidget);

    await fill(tester, opened);
    opened.api.expenseAnswer = (status: 400, body: const {'code': 'requiredColumnMissing', 'columnKey': 'custom.area'});
    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    expect(find.descendant(of: find.byKey(AddEntryScreen.columnKey('custom.area')), matching: find.text('en expenses.requiredColumnMissing')), findsOneWidget);
  });

  testWidgets('FR-41: each custom column is drawn from what it holds, and its value is sent under its key', (tester) async {
    final opened = await openExpense(tester);
    final path = '/projects/project-0/items/${opened.item}/columns';
    opened.api.addColumn(path, 'custom.area', dataType: 'number', isCustom: true);
    opened.api.addColumn(path, 'custom.note', isCustom: true);
    opened.api.addColumn(path, 'custom.colour', dataType: 'list', isCustom: true)['options'] = ['أحمر', 'أزرق'];
    opened.api.addColumn(path, 'custom.day', dataType: 'date', isCustom: true);
    await fill(tester, opened);

    await type(tester, AddEntryScreen.columnKey('custom.area'), '١٢٥٫٥');
    await type(tester, AddEntryScreen.columnKey('custom.note'), 'نص');
    await tapVisible(tester, opened.api, AddEntryScreen.columnKey('custom.colour'));
    await act(tester, opened.api, () => tester.tap(find.text('أزرق').last));
    await tapVisible(tester, opened.api, AddEntryScreen.columnKey('custom.day'));
    await act(tester, opened.api, () => tester.tap(find.text('OK')));
    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    final values = opened.api.sentExpenses.single['customValues'] as Map<String, dynamic>;
    expect(values['custom.area'], '125.5');
    expect(values['custom.note'], 'نص');
    expect(values['custom.colour'], 'أزرق');
    expect(values['custom.day'], DateTime.now().toIso8601String().substring(0, 10));
  });

  testWidgets('a built-in field Finance made required is marked, and one it deleted is gone', (tester) async {
    final opened = await openExpense(tester);
    final columns = opened.api.columns['/projects/project-0/items/${opened.item}/columns']!;
    columns.singleWhere((column) => column['key'] == 'product')['isRequired'] = true;
    columns.removeWhere((column) => column['key'] == 'notes');

    expect(find.byKey(AddEntryScreen.notesKey), findsOneWidget);
    await pickItem(tester, opened.api, opened.item);

    expect(find.text('en expenses.product *'), findsOneWidget);
    expect(find.byKey(AddEntryScreen.notesKey), findsNothing);
    expect(find.byKey(AddEntryScreen.unitPriceKey), findsOneWidget);
  });

  testWidgets('choosing another item starts its fields afresh', (tester) async {
    final opened = await openExpense(tester);
    opened.api.addColumn('/projects/project-0/items/${opened.item}/columns', 'custom.area', dataType: 'number', isCustom: true);
    await fill(tester, opened);
    await type(tester, AddEntryScreen.columnKey('custom.area'), '12');

    await pickItem(tester, opened.api, opened.otherItem);
    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect(opened.api.sentExpenses.single['customValues'], isEmpty);
  });

  testWidgets('the table sheet searches the items\' and the tables\' names in one spelling, and says when nothing matches', (tester) async {
    var steel = <String, Object>{};
    final opened = await openExpense(tester, arrange: (api) => steel = api.addItem(api.categories['project-0']!.single, 'أعمال الحديد'));
    String generalOf(String itemId) => tableIdsOf(opened.api, itemId).first;
    final tiles = tableIdsOf(opened.api, opened.item);
    await tapVisible(tester, opened.api, AddEntryScreen.tableKey);

    await tester.enterText(find.byKey(TablePicker.searchKey), 'مواد');
    await tester.pumpAndSettle();
    expect(find.byKey(TablePicker.optionKey(tiles.last)), findsOneWidget);
    expect(find.byKey(TablePicker.optionKey(generalOf(opened.otherItem))), findsNothing);

    await tester.enterText(find.byKey(TablePicker.searchKey), 'اعمال');
    await tester.pumpAndSettle();
    expect(find.byKey(TablePicker.optionKey(generalOf(steel['id']! as String))), findsOneWidget);
    expect(find.byKey(TablePicker.optionKey(tiles.first)), findsNothing);

    await tester.enterText(find.byKey(TablePicker.searchKey), 'البلاط');
    await tester.pumpAndSettle();
    expect(find.byKey(TablePicker.optionKey(tiles.first)), findsOneWidget);
    expect(find.byKey(TablePicker.optionKey(tiles.last)), findsOneWidget);

    await tester.enterText(find.byKey(TablePicker.searchKey), 'لا شيء');
    await tester.pumpAndSettle();
    expect(find.byKey(TablePicker.noMatchKey), findsOneWidget);
  });

  testWidgets('R10: an item\'s named table takes the purchase into that subgroup', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    final subgroups = (opened.api.categories['project-0']!.single['items']! as List<Map<String, Object>>).first['subgroups']! as List<Map<String, Object>>;

    await tapVisible(tester, opened.api, AddEntryScreen.tableKey);
    await act(tester, opened.api, () => tester.tap(find.byKey(TablePicker.optionKey(subgroups.last['id']! as String))));
    expect(chosenTable(tester), 'مواد (البلاط)');
    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect((opened.api.sentExpenses.single['itemId'], opened.api.sentExpenses.single['subgroupId']), (opened.item, subgroups.last['id']));
  });

  testWidgets('open question 4: Field is offered only what they hold, and one account is already chosen', (tester) async {
    final opened = await openExpense(tester);

    expect(find.byKey(PaymentChoices.accountKey(opened.custody)), findsOneWidget);
    expect(find.byKey(PaymentChoices.accountKey(opened.bank)), findsNothing);
    expect(tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>)).groupValue, opened.custody);
  });

  testWidgets('ChargeAnyAccount: Finance is offered every account and chooses one', (tester) async {
    final opened = await openExpense(tester, permissions: managerAndFinance);
    await fill(tester, opened);

    expect(find.byKey(PaymentChoices.accountKey(opened.custody)), findsOneWidget);
    await tapVisible(tester, opened.api, PaymentChoices.accountKey(opened.bank));
    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect(opened.api.sentExpenses.single['accountId'], opened.bank);
  });

  testWidgets('someone who holds nothing is told so, with no account to choose', (tester) async {
    await openExpense(tester, arrange: (api) => api.accounts['project-0']!.clear());

    expect(find.byKey(AddEntryScreen.noAccountKey), findsOneWidget);
    expect(find.byType(RadioListTile<String>), findsNothing);
  });

  testWidgets('a disabled payment method is not on offer', (tester) async {
    await openExpense(tester);

    expect(find.text('شبكة'), findsOneWidget);
    expect(find.text('معطّلة'), findsNothing);
  });

  testWidgets('a list that cannot be read says so, and Try again reads it', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: field, units: ['الفلة الغربية']);
    api.addAccount('project-0', 'عهدتي', type: 'cashCustody', isMine: true);
    await openProject(tester, api, capture: FakeCapture());
    await tester.ensureVisible(find.byKey(HomeScreen.addEntryKey('project-0')));
    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));

    await tester.ensureVisible(find.byKey(AddEntryScreen.retryKey));
    expect(shown(tester, AddEntryScreen.listMessageKey), 'en accounts.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.retryKey)));

    expect(find.text('عهدتي'), findsOneWidget);
    expect(find.byKey(AddEntryScreen.listMessageKey), findsNothing);
  });

  testWidgets('D10: an expense has one date, sent as its payment date, and no payment of its own', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    expect(find.byKey(AddEntryScreen.dateKey), findsOneWidget);

    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    final body = opened.api.sentExpenses.single;
    expect(body['paymentDate'], DateTime.now().toIso8601String().substring(0, 10));
    expect(body.containsKey('paymentAmount'), isFalse);
    expect(body.containsKey('bankFees'), isFalse);
  });

  testWidgets('findings row 79: Field reaches the supplier sheet from the expense, and goes on with a supplier quick-added', (tester) async {
    final opened = await openExpense(tester);

    await tapVisible(tester, opened.api, AddEntryScreen.supplierKey);
    await tester.enterText(find.byKey(SupplierPicker.searchKey), 'مبلط الغربية');
    await act(tester, opened.api, () => tester.tap(find.byKey(SupplierPicker.quickAddKey)));
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), '311111111111113');
    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(find.text('مبلط الغربية'), findsOneWidget);
    expect(shown(tester, AddEntryScreen.supplierDetailsKey), contains('311111111111113'));
  });

  testWidgets('D3: an expense with no file is sent, with no reason asked', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);

    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    final body = opened.api.sentExpenses.single;
    expect(body.containsKey('attachmentId'), isFalse);
    expect(body['submit'], isTrue);
    expect(shown(tester, messageKeyOf('expenses.sent').label), 'en expenses.sent');
  });

  Map<String, Object> creditable(String entryId, {double returnable = 1035, String number = ''}) => {'entryId': entryId, 'number': number, 'date': '2026-10-01', 'returnable': returnable};

  testWidgets('AC-14.2, D13: a credit note names the bill it returns and sends a plain amount', (tester) async {
    final opened = await openExpense(tester, arrange: (api) => api.creditableInvoices.add(creditable('e1', returnable: 700)));
    await fill(tester, opened);
    await tapVisible(tester, opened.api, AddEntryScreen.creditNoteKey);
    await type(tester, AddEntryScreen.amountKey, '320');

    await tapVisible(tester, opened.api, AddEntryScreen.originalInvoiceKey);
    expect(find.textContaining('700.00'), findsOneWidget);
    expect(find.byKey(OriginalInvoicePicker.optionKey('')), findsNothing);
    await act(tester, opened.api, () => tester.tap(find.byKey(OriginalInvoicePicker.optionKey('e1'))));
    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    final sent = opened.api.sentExpenses.single;
    expect((sent['isCreditNote'], sent['amount'], sent['originalEntryId']), (true, 320, 'e1'));
  });

  testWidgets('an older bill shows its number, and a new one its date', (tester) async {
    final opened = await openExpense(tester, arrange: (api) => api.creditableInvoices..add(creditable('e1', number: 'F-1'))..add(creditable('e2')));
    await fill(tester, opened);
    await tapVisible(tester, opened.api, AddEntryScreen.creditNoteKey);

    await tapVisible(tester, opened.api, AddEntryScreen.originalInvoiceKey);

    expect(find.descendant(of: find.byKey(OriginalInvoicePicker.optionKey('e1')), matching: find.text('F-1')), findsOneWidget);
    expect(find.descendant(of: find.byKey(OriginalInvoicePicker.optionKey('e2')), matching: find.text('01.10.2026')), findsOneWidget);
  });

  testWidgets('another supplier takes the link away, because the invoice was the first one\'s', (tester) async {
    final opened = await openExpense(tester, arrange: (api) => api.creditableInvoices.add(creditable('e1')));
    await fill(tester, opened);
    await tapVisible(tester, opened.api, AddEntryScreen.creditNoteKey);
    await tapVisible(tester, opened.api, AddEntryScreen.originalInvoiceKey);
    await act(tester, opened.api, () => tester.tap(find.byKey(OriginalInvoicePicker.optionKey('e1'))));

    await pickSupplier(tester, opened.api, opened.cash);
    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect(opened.api.sentExpenses.single.containsKey('originalEntryId'), isFalse);
  });

  testWidgets('BR-18: a credit note above what is left of its invoice is blocked with a message', (tester) async {
    final opened = await openExpense(tester, arrange: (api) => api.expenseAnswer = (status: 400, body: const {'code': 'creditNoteAboveOriginal'}));
    await fill(tester, opened);
    await tapVisible(tester, opened.api, AddEntryScreen.creditNoteKey);

    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect(shown(tester, AddEntryScreen.messageKey), 'en expenses.creditNoteAboveOriginal');
  });

  testWidgets('AC-14.1, D14: a deduction is a negative amount, typed in either digits, sent as it is with why in its notes', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    await type(tester, AddEntryScreen.notesKey, 'خصم من المورد');

    await type(tester, AddEntryScreen.amountKey, '-١٣٦');

    expect(tester.widget<TextField>(find.byKey(AddEntryScreen.amountKey)).keyboardType, const TextInputType.numberWithOptions(decimal: true, signed: true));
    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);
    expect((opened.api.sentExpenses.single['amount'], opened.api.sentExpenses.single['notes']), (-136, 'خصم من المورد'));
  });

  testWidgets('D14: a deduction with no notes is refused with the API\'s reason', (tester) async {
    final opened = await openExpense(tester, arrange: (api) => api.expenseAnswer = (status: 400, body: const {'code': 'deductionNeedsNotes'}));
    await fill(tester, opened);
    await type(tester, AddEntryScreen.amountKey, '-136');

    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect(shown(tester, AddEntryScreen.messageKey), 'en expenses.deductionNeedsNotes');
  });

  testWidgets('who holds no recordEntries has no way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject'], units: ['الفلة الغربية']);
    await openProject(tester, api);
    expect(isEnabled(tester, HomeScreen.addEntryKey('project-0')), isFalse);
  });

  testWidgets('a finished project offers no new expense', (tester) async {
    final api = FakeApi()..addProject('غصون 5', status: 'finished', permissions: field, units: ['الفلة الشرقية']);
    await openProject(tester, api);

    expect(isEnabled(tester, HomeScreen.addEntryKey('project-0')), isFalse);
  });

  testWidgets('choosing a supplier fills its usual item while none is chosen', (tester) async {
    final opened = await openExpense(tester);
    final usual = opened.api.addSupplier('project-0', 'مورد الجبس', defaultItemId: opened.otherItem, defaultItemName: 'الجبس');

    await pickSupplier(tester, opened.api, usual['id']! as String);

    expect(chosenTable(tester), 'الجبس');
  });

  testWidgets('an item already chosen stays when the supplier usually has another', (tester) async {
    final opened = await openExpense(tester);
    final usual = opened.api.addSupplier('project-0', 'مورد الجبس', defaultItemId: opened.otherItem, defaultItemName: 'الجبس');

    await pickItem(tester, opened.api, opened.item);
    await pickSupplier(tester, opened.api, usual['id']! as String);

    expect(chosenTable(tester), 'البلاط');
  });

  testWidgets('a usual item no longer on offer fills nothing', (tester) async {
    final opened = await openExpense(tester);
    final usual = opened.api.addSupplier('project-0', 'مورد قديم', defaultItemId: 'item-gone', defaultItemName: 'بند معطّل');

    await pickSupplier(tester, opened.api, usual['id']! as String);

    expect(chosenTable(tester), '');
  });
}
