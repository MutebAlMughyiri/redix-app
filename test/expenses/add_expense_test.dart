import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/accounts/account.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/expenses/add_expense_screen.dart';
import 'package:redix/expenses/original_invoice_picker.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/structure/item_picker.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';

import '../app_harness.dart';

void main() {
  /// A project with an item, a supplier, a supplier with no number, a payment method, and an account the signed-in user holds and one they do not, opened as far as a new expense.
  Future<({FakeApi api, FakeCapture capture, String item, String otherItem, String supplier, String cash, String method, String custody, String bank})> openExpense(
    WidgetTester tester, {
    List<String> permissions = field,
    PickedFile? camera,
    void Function(FakeApi api)? arrange,
  }) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة الغربية']);
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
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.addExpenseKey('project-0')));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addExpenseKey('project-0'))));
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
    await tapVisible(tester, api, AddExpenseScreen.supplierKey);
    await act(tester, api, () => tester.tap(find.byKey(SupplierPicker.rowKey(id))));
  }

  Future<void> pickItem(WidgetTester tester, FakeApi api, String id) async {
    await tapVisible(tester, api, AddExpenseScreen.itemKey);
    await act(tester, api, () => tester.tap(find.byKey(ItemPicker.optionKey(id))));
  }

  /// Fills everything an expense needs, for a test whose subject is something else.
  Future<void> fill(WidgetTester tester, ({FakeApi api, FakeCapture capture, String item, String otherItem, String supplier, String cash, String method, String custody, String bank}) opened) async {
    await pickItem(tester, opened.api, opened.item);
    await tapVisible(tester, opened.api, AddExpenseScreen.unitKey('project-0-unit-0'));
    await pickSupplier(tester, opened.api, opened.supplier);
    await type(tester, AddExpenseScreen.invoiceNumberKey, '2617');
    await type(tester, AddExpenseScreen.amountKey, '6000');
    await tapVisible(tester, opened.api, AddExpenseScreen.paymentMethodKey(opened.method));
  }

  testWidgets('AC-08.1: an amount including VAT shows its figures rounded to two decimals', (tester) async {
    await openExpense(tester);

    await type(tester, AddExpenseScreen.amountKey, '6000');

    expect(shown(tester, AddExpenseScreen.afterDiscountKey), '5,217.39');
    expect(shown(tester, AddExpenseScreen.vatKey), '782.61');
    expect(shown(tester, AddExpenseScreen.totalKey), '6,000.00');
  });

  testWidgets('AC-08.2: an amount before VAT shows its total, 2,955.385, as 2,955.39', (tester) async {
    final opened = await openExpense(tester);

    await tapVisible(tester, opened.api, AddExpenseScreen.beforeVatKey);
    await type(tester, AddExpenseScreen.amountKey, '2569.90');

    expect(shown(tester, AddExpenseScreen.vatKey), '385.49');
    expect(shown(tester, AddExpenseScreen.totalKey), '2,955.39');
  });

  testWidgets('AC-08.3: the discount comes off before VAT', (tester) async {
    final opened = await openExpense(tester);

    await tapVisible(tester, opened.api, AddExpenseScreen.beforeVatKey);
    await type(tester, AddExpenseScreen.amountKey, '1000');
    await type(tester, AddExpenseScreen.discountKey, '100');

    expect(shown(tester, AddExpenseScreen.afterDiscountKey), '900.00');
    expect(shown(tester, AddExpenseScreen.vatKey), '135.00');
    expect(shown(tester, AddExpenseScreen.totalKey), '1,035.00');
  });

  testWidgets('a supplier not VAT-registered and an invoice not taxable show no VAT', (tester) async {
    final opened = await openExpense(tester);
    await type(tester, AddExpenseScreen.amountKey, '6000');

    await tapVisible(tester, opened.api, AddExpenseScreen.notTaxableKey);
    expect(shown(tester, AddExpenseScreen.vatKey), '0.00');
    expect(shown(tester, AddExpenseScreen.totalKey), '6,000.00');

    await tapVisible(tester, opened.api, AddExpenseScreen.notTaxableKey);
    expect(shown(tester, AddExpenseScreen.vatKey), '782.61');

    await pickSupplier(tester, opened.api, opened.cash);
    expect(shown(tester, AddExpenseScreen.vatKey), '0.00');
  });

  testWidgets('BR-01: left without an amount, the price times the quantity includes VAT', (tester) async {
    final opened = await openExpense(tester);

    await tapVisible(tester, opened.api, AddExpenseScreen.beforeVatKey);
    await type(tester, AddExpenseScreen.unitPriceKey, '230');
    await type(tester, AddExpenseScreen.quantityKey, '5');

    expect(shown(tester, AddExpenseScreen.afterDiscountKey), '1,000.00');
    expect(shown(tester, AddExpenseScreen.totalKey), '1,150.00');
  });

  testWidgets('what a person types in Arabic digits counts', (tester) async {
    await openExpense(tester);

    await type(tester, AddExpenseScreen.amountKey, '٦٠٠٠');

    expect(shown(tester, AddExpenseScreen.totalKey), '6,000.00');
  });

  testWidgets('saving a draft sends what was typed and chosen, never a figure, with an id made on the phone', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    await type(tester, AddExpenseScreen.productKey, 'مواد لياسة');
    await type(tester, AddExpenseScreen.notesKey, 'ملاحظة');

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    final body = opened.api.sentExpenses.single;
    expect(body['itemId'], opened.item);
    expect(body['unitId'], 'project-0-unit-0');
    expect(body['supplierId'], opened.supplier);
    expect(body['invoiceNumber'], '2617');
    expect(body['product'], 'مواد لياسة');
    expect(body['notes'], 'ملاحظة');
    expect(body['amount'], 6000);
    expect(body['amountIncludesVat'], isTrue);
    expect(body['accountId'], opened.custody);
    expect(body['paymentMethodId'], opened.method);
    expect(body['submit'], isFalse);
    expect(body['id'], matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    for (final figure in ['vat', 'total', 'amountAfterDiscount', 'amountBeforeDiscount']) {
      expect(body.containsKey(figure), isFalse);
    }
    expect(shown(tester, AddExpenseScreen.savedKey), 'en expenses.saved');
    expect(find.byKey(AddExpenseScreen.sendKey), findsNothing);
  });

  testWidgets('an invoice number in Arabic digits is sent in Western ones', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    await type(tester, AddExpenseScreen.invoiceNumberKey, '٢٦١٧');

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(opened.api.sentExpenses.single['invoiceNumber'], '2617');
  });

  testWidgets('FR-09: sending keeps the invoice first and names it', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng)));
    await fill(tester, opened);

    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);

    expect(opened.api.sentAttachments.single, contains('invoice.png'));
    expect(opened.api.sentExpenses.single['attachmentId'], startsWith('attachment-'));
    expect(opened.api.sentExpenses.single['submit'], isTrue);
    expect(shown(tester, AddExpenseScreen.savedKey), 'en expenses.sent');
  });

  testWidgets('a refusal stays on the screen with what was typed, and trying again sends the file once and the same id', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng)));
    await fill(tester, opened);
    opened.api.expenseAnswer = (status: 400, body: const {'code': 'invalidInvoiceDate'});

    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);

    expect(shown(tester, AddExpenseScreen.messageKey), 'en expenses.invalidInvoiceDate');
    expect(tester.widget<TextField>(find.byKey(AddExpenseScreen.invoiceNumberKey)).controller!.text, '2617');

    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);

    expect(opened.api.sentAttachments, hasLength(1));
    expect(opened.api.sentExpenses[1]['id'], opened.api.sentExpenses[0]['id']);
    expect(opened.api.sentExpenses[1]['attachmentId'], opened.api.sentExpenses[0]['attachmentId']);
  });

  testWidgets('a picture taken again is kept again', (tester) async {
    final picture = PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng));
    final opened = await openExpense(tester, camera: picture);
    await fill(tester, opened);
    opened.api.expenseAnswer = (status: 400, body: const {'code': 'invalidInvoiceDate'});
    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);

    await tapVisible(tester, opened.api, AddExpenseScreen.cameraKey);
    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);

    expect(opened.api.sentAttachments, hasLength(2));
  });

  testWidgets('a file the API refuses says why, and the expense is not sent', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng)));
    await fill(tester, opened);
    opened.api.attachmentAnswer = (status: 400, code: 'imageTooLarge');

    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);

    expect(shown(tester, AddExpenseScreen.messageKey), 'en attachments.imageTooLarge');
    expect(opened.api.sentExpenses, isEmpty);
  });

  testWidgets('what is not a number is refused here, and nothing is sent', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    await type(tester, AddExpenseScreen.amountKey, 'كثير');

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(shown(tester, AddExpenseScreen.messageKey), 'en expenses.invalidAmount');
    expect(opened.api.sentExpenses, isEmpty);
  });

  testWidgets('without a network the expense stays, and the screen says so', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    opened.api.online = false;

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(shown(tester, AddExpenseScreen.messageKey), 'en expenses.noConnection');
  });

  testWidgets('AC-41.1: a required custom column is marked, asked only in its item, and the refusal marks its field', (tester) async {
    final opened = await openExpense(tester);
    opened.api.addColumn('/projects/project-0/items/${opened.item}/columns', 'custom.area', dataType: 'number', isCustom: true, isRequired: true);

    await pickItem(tester, opened.api, opened.otherItem);
    expect(find.byKey(AddExpenseScreen.columnKey('custom.area')), findsNothing);

    await pickItem(tester, opened.api, opened.item);
    expect(find.text('custom.area *'), findsOneWidget);

    await fill(tester, opened);
    opened.api.expenseAnswer = (status: 400, body: const {'code': 'requiredColumnMissing', 'columnKey': 'custom.area'});
    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);

    expect(find.descendant(of: find.byKey(AddExpenseScreen.columnKey('custom.area')), matching: find.text('en expenses.requiredColumnMissing')), findsOneWidget);
  });

  testWidgets('FR-41: each custom column is drawn from what it holds, and its value is sent under its key', (tester) async {
    final opened = await openExpense(tester);
    final path = '/projects/project-0/items/${opened.item}/columns';
    opened.api.addColumn(path, 'custom.area', dataType: 'number', isCustom: true);
    opened.api.addColumn(path, 'custom.note', isCustom: true);
    opened.api.addColumn(path, 'custom.colour', dataType: 'list', isCustom: true)['options'] = ['أحمر', 'أزرق'];
    opened.api.addColumn(path, 'custom.day', dataType: 'date', isCustom: true);
    await fill(tester, opened);

    await type(tester, AddExpenseScreen.columnKey('custom.area'), '١٢٥٫٥');
    await type(tester, AddExpenseScreen.columnKey('custom.note'), 'نص');
    await tapVisible(tester, opened.api, AddExpenseScreen.columnKey('custom.colour'));
    await act(tester, opened.api, () => tester.tap(find.text('أزرق').last));
    await tapVisible(tester, opened.api, AddExpenseScreen.columnKey('custom.day'));
    await act(tester, opened.api, () => tester.tap(find.text('OK')));
    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

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

    expect(find.byKey(AddExpenseScreen.notesKey), findsOneWidget);
    await pickItem(tester, opened.api, opened.item);

    expect(find.text('en expenses.product *'), findsOneWidget);
    expect(find.byKey(AddExpenseScreen.notesKey), findsNothing);
    expect(find.byKey(AddExpenseScreen.unitPriceKey), findsOneWidget);
  });

  testWidgets('choosing another item starts its fields afresh', (tester) async {
    final opened = await openExpense(tester);
    opened.api.addColumn('/projects/project-0/items/${opened.item}/columns', 'custom.area', dataType: 'number', isCustom: true);
    await fill(tester, opened);
    await type(tester, AddExpenseScreen.columnKey('custom.area'), '12');

    await pickItem(tester, opened.api, opened.otherItem);
    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(opened.api.sentExpenses.single['customValues'], isEmpty);
  });

  testWidgets('an item with named subgroups offers them, its general group first', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    final subgroups = (opened.api.categories['project-0']!.single['items']! as List<Map<String, Object>>).first['subgroups']! as List<Map<String, Object>>;

    await tapVisible(tester, opened.api, AddExpenseScreen.subgroupKey(subgroups.last['id']! as String));
    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(opened.api.sentExpenses.single['subgroupId'], subgroups.last['id']);
  });

  testWidgets('an item with no named subgroup asks for none', (tester) async {
    final opened = await openExpense(tester);

    await pickItem(tester, opened.api, opened.otherItem);

    expect(find.text('en expenses.subgroup'), findsNothing);
  });

  testWidgets('open question 3: the shared unit is on offer with the project\'s own', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);

    await tapVisible(tester, opened.api, AddExpenseScreen.unitKey('project-0-unit-shared'));
    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(opened.api.sentExpenses.single['unitId'], 'project-0-unit-shared');
  });

  testWidgets('open question 4: Field is offered only what they hold, and one account is already chosen', (tester) async {
    final opened = await openExpense(tester);

    expect(find.byKey(AddExpenseScreen.accountKey(opened.custody)), findsOneWidget);
    expect(find.byKey(AddExpenseScreen.accountKey(opened.bank)), findsNothing);
    expect(find.byKey(AddExpenseScreen.sourceKey(AccountType.bank)), findsNothing);
    expect(tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>)).groupValue, opened.custody);
  });

  testWidgets('ChargeAnyAccount: Finance chooses a source, then an account of it', (tester) async {
    final opened = await openExpense(tester, permissions: managerAndFinance);
    await fill(tester, opened);

    await tapVisible(tester, opened.api, AddExpenseScreen.sourceKey(AccountType.bank));
    expect(find.byKey(AddExpenseScreen.accountKey(opened.custody)), findsNothing);
    await tapVisible(tester, opened.api, AddExpenseScreen.accountKey(opened.bank));
    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(opened.api.sentExpenses.single['accountId'], opened.bank);
  });

  testWidgets('someone who holds nothing is told so, with no account to choose', (tester) async {
    await openExpense(tester, arrange: (api) => api.accounts['project-0']!.clear());

    expect(find.byKey(AddExpenseScreen.noAccountKey), findsOneWidget);
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
    await pumpRedix(tester, api, stored: {'session': keptSession}, capture: FakeCapture());
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await tester.ensureVisible(find.byKey(HomeScreen.addExpenseKey('project-0')));
    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addExpenseKey('project-0'))));

    await tester.ensureVisible(find.byKey(AddExpenseScreen.retryKey));
    expect(shown(tester, AddExpenseScreen.listMessageKey), 'en accounts.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(AddExpenseScreen.retryKey)));

    expect(find.text('عهدتي'), findsOneWidget);
    expect(find.byKey(AddExpenseScreen.listMessageKey), findsNothing);
  });

  testWidgets('BR-24: a payment that differs sends its own date and amount, and its bank fees', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    expect(find.byKey(AddExpenseScreen.paymentAmountKey), findsNothing);

    await tapVisible(tester, opened.api, AddExpenseScreen.paymentDiffersKey);
    await type(tester, AddExpenseScreen.paymentAmountKey, '6001.50');
    await type(tester, AddExpenseScreen.bankFeesKey, '1.50');
    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    final body = opened.api.sentExpenses.single;
    expect(body['paymentAmount'], 6001.5);
    expect(body['bankFees'], 1.5);
    expect(body['paymentDate'], DateTime.now().toIso8601String().substring(0, 10));
  });

  testWidgets('a payment that does not differ sends none of its own', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    final body = opened.api.sentExpenses.single;
    expect(body.containsKey('paymentDate'), isFalse);
    expect(body.containsKey('paymentAmount'), isFalse);
    expect(body.containsKey('bankFees'), isFalse);
  });

  testWidgets('findings row 79: Field reaches the supplier sheet from the expense, and goes on with a supplier quick-added', (tester) async {
    final opened = await openExpense(tester);

    await tapVisible(tester, opened.api, AddExpenseScreen.supplierKey);
    await tester.enterText(find.byKey(SupplierPicker.searchKey), 'مبلط الغربية');
    await act(tester, opened.api, () => tester.tap(find.byKey(SupplierPicker.quickAddKey)));
    await tester.enterText(find.byKey(SuppliersScreen.vatNumberKey), '311111111111113');
    await act(tester, opened.api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(find.text('مبلط الغربية'), findsOneWidget);
    expect(shown(tester, AddExpenseScreen.supplierDetailsKey), contains('311111111111113'));
  });

  testWidgets('AC-17.1: a repeated invoice shows the earlier entry, and saves only once confirmed', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    opened.api.expenseAnswer = (
      status: 409,
      body: const {
        'code': 'duplicateInvoice',
        'earlier': {'isVisible': true, 'projectName': 'غصون 5', 'invoiceDate': '2026-10-26', 'total': 2955.385},
      },
    );

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(shown(tester, AddExpenseScreen.earlierKey), 'غصون 5 · 26.10.2026 · 2,955.39');
    expect(shown(tester, ConfirmDialog.explanationKey), 'en expenses.duplicateExplain');
    expect(find.byKey(AddExpenseScreen.messageKey), findsNothing);
    expect(opened.api.sentExpenses.single.containsKey('confirmDuplicate'), isFalse);

    opened.api.expenseAnswer = (status: 201, body: const {});
    await act(tester, opened.api, () => tester.tap(find.byKey(AddExpenseScreen.saveAnywayKey)));

    expect(opened.api.sentExpenses.last['confirmDuplicate'], isTrue);
    expect(opened.api.sentExpenses.last['id'], opened.api.sentExpenses.first['id']);
    expect(shown(tester, AddExpenseScreen.savedKey), 'en expenses.saved');
  });

  testWidgets('AC-17.1: leaving the question saves nothing, and the expense stays', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    opened.api.expenseAnswer = (
      status: 409,
      body: const {
        'code': 'duplicateInvoice',
        'earlier': {'isVisible': true, 'projectName': 'غصون 5', 'invoiceDate': '2026-10-26', 'total': 100},
      },
    );
    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    await act(tester, opened.api, () => tester.tap(find.byKey(ConfirmDialog.cancelKey)));

    expect(opened.api.sentExpenses, hasLength(1));
    expect(find.byKey(AddExpenseScreen.draftKey), findsOneWidget);
  });

  testWidgets('BR-33: an earlier entry in a project the user cannot read names nothing of it', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    opened.api.expenseAnswer = (
      status: 409,
      body: const {
        'code': 'duplicateInvoice',
        'earlier': {'isVisible': false, 'projectName': '', 'invoiceDate': '0001-01-01', 'total': 0},
      },
    );

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(find.byKey(AddExpenseScreen.earlierKey), findsNothing);
    expect(shown(tester, ConfirmDialog.explanationKey), 'en expenses.duplicateHidden');
  });

  testWidgets('AC-09.1: without an invoice, the reason takes the place of the invoice, and the expense is sent with no file', (tester) async {
    final opened = await openExpense(tester);
    await pickItem(tester, opened.api, opened.item);
    await tapVisible(tester, opened.api, AddExpenseScreen.unitKey('project-0-unit-0'));
    await pickSupplier(tester, opened.api, opened.supplier);
    await type(tester, AddExpenseScreen.amountKey, '200');
    await tapVisible(tester, opened.api, AddExpenseScreen.paymentMethodKey(opened.method));

    await tapVisible(tester, opened.api, AddExpenseScreen.withoutInvoiceKey);

    for (final gone in [AddExpenseScreen.cameraKey, AddExpenseScreen.invoiceNumberKey, AddExpenseScreen.invoiceDateKey, AddExpenseScreen.includingVatKey, AddExpenseScreen.notTaxableKey, AddExpenseScreen.paymentDiffersKey]) {
      expect(find.byKey(gone), findsNothing);
    }
    expect(find.byKey(AddExpenseScreen.paymentDateKey), findsOneWidget);
    expect(shown(tester, AddExpenseScreen.vatKey), '0.00');
    expect(shown(tester, AddExpenseScreen.totalKey), '200.00');

    await type(tester, AddExpenseScreen.withoutInvoiceReasonKey, 'شراء نقدي من السوق');
    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);

    final sent = opened.api.sentExpenses.single;
    expect(sent['withoutInvoiceReason'], 'شراء نقدي من السوق');
    expect(sent['paymentDate'], isNotNull);
    expect(sent['submit'], isTrue);
    for (final absent in ['invoiceNumber', 'invoiceDate', 'attachmentId']) {
      expect(sent.containsKey(absent), isFalse);
    }
  });

  testWidgets('AC-09.1: with the reason empty nothing is sent', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);

    await tapVisible(tester, opened.api, AddExpenseScreen.withoutInvoiceKey);
    await type(tester, AddExpenseScreen.withoutInvoiceReasonKey, '   ');
    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);

    expect(opened.api.sentExpenses, isEmpty);
    expect(shown(tester, AddExpenseScreen.messageKey), 'en expenses.invalidWithoutInvoiceReason');
  });

  testWidgets('a picture taken before turning it on is not sent, and turning it off brings it back', (tester) async {
    final opened = await openExpense(tester, camera: PickedFile('invoice.png', '/phone/invoice.png', Uint8List.fromList(onePixelPng)));
    await fill(tester, opened);

    await tapVisible(tester, opened.api, AddExpenseScreen.withoutInvoiceKey);
    expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsNothing);
    await tapVisible(tester, opened.api, AddExpenseScreen.withoutInvoiceKey);
    expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsOneWidget);

    await tapVisible(tester, opened.api, AddExpenseScreen.withoutInvoiceKey);
    await type(tester, AddExpenseScreen.withoutInvoiceReasonKey, 'ضاعت الفاتورة');
    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);

    expect(opened.api.sentAttachments, isEmpty);
    expect(opened.api.sentExpenses.single.containsKey('attachmentId'), isFalse);
  });

  Map<String, Object> creditable(String entryId, {double returnable = 1035, double vatRate = 0.15}) => {'entryId': entryId, 'number': 'F-$entryId', 'invoiceDate': '2026-10-01', 'returnable': returnable, 'vatRate': vatRate};

  testWidgets('AC-14.2: a credit note has its own number and date, shows its figures negative and sends a plain amount', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);

    await tapVisible(tester, opened.api, AddExpenseScreen.creditNoteKey);
    await type(tester, AddExpenseScreen.amountKey, '320');

    expect(shown(tester, AddExpenseScreen.totalKey), '(320.00)');
    expect(shown(tester, AddExpenseScreen.vatKey), '(41.74)');

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);
    final sent = opened.api.sentExpenses.single;
    expect(sent['isCreditNote'], isTrue);
    expect(sent['amount'], 320);
    expect(sent['invoiceNumber'], '2617');
    expect(sent.containsKey('originalEntryId'), isFalse);
  });

  testWidgets('BR-18: linking is optional; the invoice chosen says what is left, and its rate is the one shown and its id sent', (tester) async {
    final opened = await openExpense(tester, arrange: (api) => api.creditableInvoices.add(creditable('e1', returnable: 700, vatRate: 0.05)));
    await fill(tester, opened);
    await tapVisible(tester, opened.api, AddExpenseScreen.creditNoteKey);
    await type(tester, AddExpenseScreen.amountKey, '105');

    await tapVisible(tester, opened.api, AddExpenseScreen.originalInvoiceKey);
    expect(find.textContaining('700.00'), findsOneWidget);
    await act(tester, opened.api, () => tester.tap(find.byKey(OriginalInvoicePicker.optionKey('e1'))));

    expect(shown(tester, AddExpenseScreen.vatKey), '(5.00)');
    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);
    expect(opened.api.sentExpenses.single['originalEntryId'], 'e1');
  });

  testWidgets('BR-18: choosing no invoice takes the link away, and a supplier with none says so', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    await tapVisible(tester, opened.api, AddExpenseScreen.creditNoteKey);

    await tapVisible(tester, opened.api, AddExpenseScreen.originalInvoiceKey);
    expect(find.text('en expenses.noCreditableInvoice'), findsOneWidget);
    await act(tester, opened.api, () => tester.tap(find.byKey(OriginalInvoicePicker.optionKey(''))));

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);
    expect(opened.api.sentExpenses.single.containsKey('originalEntryId'), isFalse);
  });

  testWidgets('another supplier takes the link away, because the invoice was the first one\'s', (tester) async {
    final opened = await openExpense(tester, arrange: (api) => api.creditableInvoices.add(creditable('e1')));
    await fill(tester, opened);
    await tapVisible(tester, opened.api, AddExpenseScreen.creditNoteKey);
    await tapVisible(tester, opened.api, AddExpenseScreen.originalInvoiceKey);
    await act(tester, opened.api, () => tester.tap(find.byKey(OriginalInvoicePicker.optionKey('e1'))));

    await pickSupplier(tester, opened.api, opened.cash);
    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(opened.api.sentExpenses.single.containsKey('originalEntryId'), isFalse);
  });

  testWidgets('BR-18: a credit note above what is left of its invoice is blocked with a message', (tester) async {
    final opened = await openExpense(tester, arrange: (api) => api.expenseAnswer = (status: 400, body: const {'code': 'creditNoteAboveOriginal'}));
    await fill(tester, opened);
    await tapVisible(tester, opened.api, AddExpenseScreen.creditNoteKey);

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(shown(tester, AddExpenseScreen.messageKey), 'en expenses.creditNoteAboveOriginal');
  });

  testWidgets('turning on Without an invoice ends the credit note', (tester) async {
    final opened = await openExpense(tester, arrange: (api) => api.creditableInvoices.add(creditable('e1')));
    await fill(tester, opened);
    await tapVisible(tester, opened.api, AddExpenseScreen.creditNoteKey);

    await tapVisible(tester, opened.api, AddExpenseScreen.withoutInvoiceKey);

    expect(find.byKey(AddExpenseScreen.creditNoteKey), findsNothing);
    expect(find.byKey(AddExpenseScreen.originalInvoiceKey), findsNothing);
    await type(tester, AddExpenseScreen.withoutInvoiceReasonKey, 'ضاعت الفاتورة');
    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);
    expect(opened.api.sentExpenses.single.containsKey('isCreditNote'), isFalse);
  });

  testWidgets('AC-14.1: a deduction is a negative amount, typed in either digits, with no VAT, sent as it is', (tester) async {
    final opened = await openExpense(tester);
    await fill(tester, opened);
    await tapVisible(tester, opened.api, AddExpenseScreen.withoutInvoiceKey);
    await type(tester, AddExpenseScreen.withoutInvoiceReasonKey, 'خصم من المورد');

    await type(tester, AddExpenseScreen.amountKey, '-١٣٦');

    expect(shown(tester, AddExpenseScreen.vatKey), '0.00');
    expect(shown(tester, AddExpenseScreen.totalKey), '(136.00)');
    expect(tester.widget<TextField>(find.byKey(AddExpenseScreen.amountKey)).keyboardType, const TextInputType.numberWithOptions(decimal: true, signed: true));
    await tapVisible(tester, opened.api, AddExpenseScreen.sendKey);
    expect(opened.api.sentExpenses.single['amount'], -136);
  });

  testWidgets('FR-14: a negative amount with an invoice number is refused, saying what to do', (tester) async {
    final opened = await openExpense(tester, arrange: (api) => api.expenseAnswer = (status: 400, body: const {'code': 'deductionNeedsReason'}));
    await fill(tester, opened);
    await type(tester, AddExpenseScreen.amountKey, '-136');

    await tapVisible(tester, opened.api, AddExpenseScreen.draftKey);

    expect(shown(tester, AddExpenseScreen.messageKey), 'en expenses.deductionNeedsReason');
  });

  testWidgets('who holds no recordEntries has no way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject'], units: ['الفلة الغربية']);
    await pumpRedix(tester, api, stored: {'session': keptSession});

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    expect(find.byKey(HomeScreen.addExpenseKey('project-0')), findsNothing);
  });

  testWidgets('a finished project offers no new expense', (tester) async {
    final api = FakeApi()..addProject('غصون 5', status: 'finished', permissions: field, units: ['الفلة الشرقية']);
    await pumpRedix(tester, api, stored: {'session': keptSession});

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));

    expect(find.byKey(HomeScreen.addExpenseKey('project-0')), findsNothing);
  });
}
