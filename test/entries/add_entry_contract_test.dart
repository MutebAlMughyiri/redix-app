import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

void main() {
  /// A project with a contract of 34,000 with 30,000 paid, a disabled one and one of open value, opened as far as a new payment.
  Future<({FakeApi api, FakeCapture capture, String running, String disabled, String open, String method})> openPayment(WidgetTester tester, {void Function(FakeApi api)? arrange, double pending = 0, List<String> permissions = field}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, units: ['الفلة الغربية']);
    final running = api.addContract('project-0', 'مبلط الغربية', value: 34000, paid: 30000, pending: pending);
    final disabled = api.addContract('project-0', 'مبلط قديم', value: 1000, isActive: false);
    final open = api.addContract('project-0', 'دهان داخلي', isOpenValue: true, paid: 12000);
    final method = api.addPaymentMethod('project-0', 'شبكة');
    api.addAccount('project-0', 'عهدتي', type: 'cashCustody', isMine: true);
    api.addColumn('/projects/project-0/items/item-of-contract/columns', 'notes');
    arrange?.call(api);
    final capture = FakeCapture();
    await openProject(tester, api, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));
    return (api: api, capture: capture, running: running['id']! as String, disabled: disabled['id']! as String, open: open['id']! as String, method: method['id']! as String);
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

  Future<void> pickContract(WidgetTester tester, FakeApi api, String id) async {
    await tapVisible(tester, api, AddEntryScreen.tableKey);
    await act(tester, api, () => tester.tap(find.byKey(TablePicker.optionKey(id))));
  }

  testWidgets('AC-12.1: choosing a contract shows its value, what was paid and what remains after this payment, before saving', (tester) async {
    final opened = await openPayment(tester);

    await pickContract(tester, opened.api, opened.running);
    await type(tester, AddEntryScreen.amountKey, '3000');

    expect(shown(tester, AddEntryScreen.valueKey), '34,000.00');
    expect(shown(tester, AddEntryScreen.paidKey), '30,000.00');
    expect(shown(tester, AddEntryScreen.remainingKey), '1,000.00');
    expect(find.byKey(AddEntryScreen.overrunKey), findsNothing);
  });

  testWidgets('AC-07.1: a payment of 5,000 on 4,000 remaining shows an overrun alert and (1,000), and is still saved', (tester) async {
    final opened = await openPayment(tester, arrange: (api) => api.entryAnswer = (status: 201, body: const {'isOverrun': true}));
    await pickContract(tester, opened.api, opened.running);
    await tapVisible(tester, opened.api, PaymentChoices.paymentMethodKey(opened.method));

    await type(tester, AddEntryScreen.amountKey, '5000');

    expect(shown(tester, AddEntryScreen.remainingKey), '(1,000.00)');
    expect(find.byKey(AddEntryScreen.overrunKey), findsOneWidget);

    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect(opened.api.sentEntries.single['amount'], 5000);
    expect(shown(tester, messageKeyOf('contractorPayments.savedOverrun').label), 'en contractorPayments.savedOverrun');
  });

  testWidgets('what waits for approval shows beside what was paid, and counts in what remains', (tester) async {
    final opened = await openPayment(tester, pending: 2000);
    await pickContract(tester, opened.api, opened.running);

    await type(tester, AddEntryScreen.amountKey, '3000');

    expect(shown(tester, AddEntryScreen.paidKey), '30,000.00');
    expect(shown(tester, AddEntryScreen.pendingKey), 'en contracts.pending 2,000.00');
    expect(shown(tester, AddEntryScreen.remainingKey), '(1,000.00)');
    expect(find.byKey(AddEntryScreen.overrunKey), findsOneWidget);
  });

  testWidgets('AC-07.2: an open-value contract has no remaining, no bar and no alert', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.open);

    await type(tester, AddEntryScreen.amountKey, '900000');

    expect(shown(tester, AddEntryScreen.remainingKey), '—');
    expect(find.byKey(AddEntryScreen.progressKey), findsNothing);
    expect(find.byKey(AddEntryScreen.overrunKey), findsNothing);
  });

  testWidgets('AC-13.1: outside the contract the remaining does not change', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.running);
    await type(tester, AddEntryScreen.amountKey, '5000');

    await tapVisible(tester, opened.api, AddEntryScreen.outsideKey);

    expect(shown(tester, AddEntryScreen.remainingKey), '4,000.00');
    expect(find.byKey(AddEntryScreen.overrunKey), findsNothing);
    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);
    expect(opened.api.sentEntries.single['isOutsideContract'], isTrue);
  });

  testWidgets('AC-14.1, D14: a deduction is a negative amount, which raises what remains and says why in its notes', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.running);

    await type(tester, AddEntryScreen.amountKey, '-136');

    expect(shown(tester, AddEntryScreen.remainingKey), '4,136.00');
    expect(tester.widget<TextField>(find.byKey(AddEntryScreen.amountKey)).keyboardType, const TextInputType.numberWithOptions(decimal: true, signed: true));

    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);
    expect(opened.api.sentEntries, isEmpty);
    expect(shown(tester, AddEntryScreen.messageKey), 'en expenses.deductionNeedsNotes');

    await type(tester, AddEntryScreen.notesKey, 'خصم من المبلط');
    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    final sent = opened.api.sentEntries.single;
    expect(sent['amount'], -136);
    expect(sent['notes'], 'خصم من المبلط');
    expect(sent.containsKey('attachmentId'), isFalse);
  });

  testWidgets('D16: a payment is sent with no receipt', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.running);
    await type(tester, AddEntryScreen.amountKey, '3000');

    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    final sent = opened.api.sentEntries.single;
    expect((sent.containsKey('attachmentId'), sent['submit']), (false, true));
  });

  testWidgets('a receipt taken is kept and sent', (tester) async {
    final opened = await openPayment(tester);
    opened.capture.camera = PickedFile('receipt.png', '/phone/receipt.png', Uint8List.fromList(onePixelPng));
    await pickContract(tester, opened.api, opened.running);
    await type(tester, AddEntryScreen.amountKey, '3000');

    await tapVisible(tester, opened.api, AddEntryScreen.cameraKey);
    expect(find.byKey(AddEntryScreen.invoicePictureKey), findsOneWidget);
    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    expect(opened.api.sentEntries.single['attachmentId'], startsWith('attachment-'));
  });

  testWidgets('a draft sends what is chosen, and the date as the payment date', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.running);
    await type(tester, AddEntryScreen.amountKey, '٣٠٠٠');
    await tapVisible(tester, opened.api, PaymentChoices.paymentMethodKey(opened.method));
    await type(tester, AddEntryScreen.notesKey, 'دفعة الدور الأرضي');

    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    final sent = opened.api.sentEntries.single;
    expect(sent['tableId'], opened.running);
    expect(sent['amount'], 3000);
    expect(sent['paymentMethodId'], opened.method);
    expect(sent['accountId'], isNotNull);
    expect(sent['notes'], 'دفعة الدور الأرضي');
    expect(sent['date'], DateTime.now().toIso8601String().substring(0, 10));
    expect(sent['submit'], isFalse);
    expect(sent.containsKey('invoiceNumber'), isFalse);
  });

  testWidgets('a disabled contract is not on offer', (tester) async {
    final opened = await openPayment(tester);

    await tapVisible(tester, opened.api, AddEntryScreen.tableKey);

    expect(find.byKey(TablePicker.optionKey(opened.running)), findsOneWidget);
    expect(find.byKey(TablePicker.optionKey(opened.disabled)), findsNothing);
  });

  testWidgets('what is no number is refused here and never sent', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.running);
    await type(tester, AddEntryScreen.amountKey, 'abc');

    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    expect(opened.api.sentEntries, isEmpty);
    expect(shown(tester, AddEntryScreen.messageKey), 'en expenses.invalidAmount');
  });

  testWidgets('FR-41: the contract\'s item asks its custom columns, and what is required is marked by the API\'s answer', (tester) async {
    final opened = await openPayment(tester, arrange: (api) {
      final contract = api.addContract('project-0', 'سباك', value: 500, itemId: 'item-9');
      api.addColumn('/projects/project-0/items/item-9/columns', 'custom.stage', isCustom: true, isRequired: true);
      api.entryAnswer = (status: 400, body: const {'code': 'requiredColumnMissing', 'columnKey': 'custom.stage'});
      contract['supplierName'] = 'سباك';
    });
    final plumber = opened.api.contracts['project-0']!.last['id']! as String;
    await pickContract(tester, opened.api, plumber);
    await type(tester, AddEntryScreen.amountKey, '100');

    await tapVisible(tester, opened.api, AddEntryScreen.sendKey);

    expect(shown(tester, AddEntryScreen.messageKey), 'en expenses.requiredColumnMissing');
  });

  testWidgets('who holds no recordEntries has no way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject'], units: ['الفلة الغربية']);
    await openProject(tester, api);

    expect(isEnabled(tester, HomeScreen.addEntryKey('project-0')), isFalse);
  });

  testWidgets('a finished project offers no new payment', (tester) async {
    final api = FakeApi()..addProject('غصون 5', status: 'finished', permissions: field, units: ['الفلة الشرقية']);
    await openProject(tester, api);

    expect(isEnabled(tester, HomeScreen.addEntryKey('project-0')), isFalse);
  });

  testWidgets('R10, R11: a contract\'s table takes a contractor payment, sent with its contract and no item or subgroup, even when its item has named ones', (tester) async {
    var contractId = '';
    final opened = await openPayment(
      tester,
      arrange: (api) {
        api.entryAnswer = (status: 201, body: const {'isOverrun': false});
        final item = api.addItem(api.addCategory('project-0', 'العظم'), 'بند الحديد', subgroups: ['الدور الأرضي']);
        contractId = api.addContract('project-0', 'مقاول الحديد', value: 1000, itemId: item['id']! as String)['id']! as String;
      },
    );
    await pickContract(tester, opened.api, contractId);
    await tapVisible(tester, opened.api, PaymentChoices.paymentMethodKey(opened.method));
    await type(tester, AddEntryScreen.amountKey, '500');

    await tapVisible(tester, opened.api, AddEntryScreen.draftKey);

    final sent = opened.api.sentEntries.single;
    expect(sent['tableId'], contractId);
    for (final gone in ['supplierId', 'product', 'isCreditNote', 'isWithdrawal']) {
      expect(sent.containsKey(gone), isFalse, reason: gone);
    }
  });
}
