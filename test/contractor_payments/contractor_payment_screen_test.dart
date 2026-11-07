import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/contractor_payments/contract_picker.dart';
import 'package:redix/contractor_payments/contractor_payment_screen.dart';
import 'package:redix/expenses/add_expense_screen.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';

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
    arrange?.call(api);
    final capture = FakeCapture();
    await openProject(tester, api, capture: capture);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractorPaymentKey('project-0'))));
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
    await tapVisible(tester, api, ContractorPaymentScreen.contractKey);
    await act(tester, api, () => tester.tap(find.byKey(ContractPicker.optionKey(id))));
  }

  testWidgets('AC-12.1: choosing a contract shows its value, what was paid and what remains after this payment, before saving', (tester) async {
    final opened = await openPayment(tester);

    await pickContract(tester, opened.api, opened.running);
    await type(tester, ContractorPaymentScreen.amountKey, '3000');

    expect(shown(tester, ContractorPaymentScreen.valueKey), '34,000.00');
    expect(shown(tester, ContractorPaymentScreen.paidKey), '30,000.00');
    expect(shown(tester, ContractorPaymentScreen.remainingKey), '1,000.00');
    expect(find.byKey(ContractorPaymentScreen.overrunKey), findsNothing);
  });

  testWidgets('AC-07.1: a payment of 5,000 on 4,000 remaining shows an overrun alert and (1,000), and is still saved', (tester) async {
    final opened = await openPayment(tester, arrange: (api) => api.expenseAnswer = (status: 201, body: const {'isOverrun': true}));
    await pickContract(tester, opened.api, opened.running);
    await tapVisible(tester, opened.api, PaymentChoices.paymentMethodKey(opened.method));

    await type(tester, ContractorPaymentScreen.amountKey, '5000');

    expect(shown(tester, ContractorPaymentScreen.remainingKey), '(1,000.00)');
    expect(find.byKey(ContractorPaymentScreen.overrunKey), findsOneWidget);

    await tapVisible(tester, opened.api, ContractorPaymentScreen.draftKey);

    expect(opened.api.sentContractorPayments.single['amount'], 5000);
    expect(find.text('en contractorPayments.savedOverrun'), findsOneWidget);
  });

  testWidgets('what waits for approval shows beside what was paid, and counts in what remains', (tester) async {
    final opened = await openPayment(tester, pending: 2000);
    await pickContract(tester, opened.api, opened.running);

    await type(tester, ContractorPaymentScreen.amountKey, '3000');

    expect(shown(tester, ContractorPaymentScreen.paidKey), '30,000.00');
    expect(shown(tester, ContractorPaymentScreen.pendingKey), 'en contracts.pending 2,000.00');
    expect(shown(tester, ContractorPaymentScreen.remainingKey), '(1,000.00)');
    expect(find.byKey(ContractorPaymentScreen.overrunKey), findsOneWidget);
  });

  testWidgets('AC-07.2: an open-value contract has no remaining, no bar and no alert', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.open);

    await type(tester, ContractorPaymentScreen.amountKey, '900000');

    expect(shown(tester, ContractorPaymentScreen.remainingKey), '—');
    expect(find.byKey(ContractorPaymentScreen.progressKey), findsNothing);
    expect(find.byKey(ContractorPaymentScreen.overrunKey), findsNothing);
  });

  testWidgets('AC-13.1: outside the contract the remaining does not change', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.running);
    await type(tester, ContractorPaymentScreen.amountKey, '5000');

    await tapVisible(tester, opened.api, ContractorPaymentScreen.outsideKey);

    expect(shown(tester, ContractorPaymentScreen.remainingKey), '4,000.00');
    expect(find.byKey(ContractorPaymentScreen.overrunKey), findsNothing);
    await tapVisible(tester, opened.api, ContractorPaymentScreen.draftKey);
    expect(opened.api.sentContractorPayments.single['isOutsideContract'], isTrue);
  });

  testWidgets('AC-14.1, D14: a deduction is a negative amount, which raises what remains, has no receipt, and says why in its notes', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.running);

    await type(tester, ContractorPaymentScreen.amountKey, '-136');

    expect(shown(tester, ContractorPaymentScreen.remainingKey), '4,136.00');
    expect(find.byKey(ContractorPaymentScreen.cameraKey), findsNothing);
    expect(tester.widget<TextField>(find.byKey(ContractorPaymentScreen.amountKey)).keyboardType, const TextInputType.numberWithOptions(decimal: true, signed: true));

    await tapVisible(tester, opened.api, ContractorPaymentScreen.sendKey);
    expect(opened.api.sentContractorPayments, isEmpty);
    expect(shown(tester, ContractorPaymentScreen.messageKey), 'en contractorPayments.deductionNeedsNotes');

    await type(tester, ContractorPaymentScreen.notesKey, 'خصم من المبلط');
    await tapVisible(tester, opened.api, ContractorPaymentScreen.sendKey);

    final sent = opened.api.sentContractorPayments.single;
    expect(sent['amount'], -136);
    expect(sent['notes'], 'خصم من المبلط');
    expect(sent.containsKey('attachmentId'), isFalse);
  });

  testWidgets('D16: a payment is sent with no receipt', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.running);
    await type(tester, ContractorPaymentScreen.amountKey, '3000');

    await tapVisible(tester, opened.api, ContractorPaymentScreen.sendKey);

    final sent = opened.api.sentContractorPayments.single;
    expect((sent.containsKey('attachmentId'), sent['submit']), (false, true));
  });

  testWidgets('a receipt taken is kept and sent', (tester) async {
    final opened = await openPayment(tester);
    opened.capture.camera = PickedFile('receipt.png', '/phone/receipt.png', Uint8List.fromList(onePixelPng));
    await pickContract(tester, opened.api, opened.running);
    await type(tester, ContractorPaymentScreen.amountKey, '3000');

    await tapVisible(tester, opened.api, ContractorPaymentScreen.cameraKey);
    expect(find.byKey(AddExpenseScreen.invoicePictureKey), findsOneWidget);
    await tapVisible(tester, opened.api, ContractorPaymentScreen.sendKey);

    expect(opened.api.sentContractorPayments.single['attachmentId'], startsWith('attachment-'));
  });

  testWidgets('a draft sends what is chosen, and the date as the payment date', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.running);
    await type(tester, ContractorPaymentScreen.amountKey, '٣٠٠٠');
    await tapVisible(tester, opened.api, PaymentChoices.paymentMethodKey(opened.method));
    await type(tester, ContractorPaymentScreen.notesKey, 'دفعة الدور الأرضي');

    await tapVisible(tester, opened.api, ContractorPaymentScreen.draftKey);

    final sent = opened.api.sentContractorPayments.single;
    expect(sent['contractId'], opened.running);
    expect(sent['amount'], 3000);
    expect(sent['paymentMethodId'], opened.method);
    expect(sent['accountId'], isNotNull);
    expect(sent['notes'], 'دفعة الدور الأرضي');
    expect(sent['paymentDate'], DateTime.now().toIso8601String().substring(0, 10));
    expect(sent['submit'], isFalse);
    expect(sent.containsKey('invoiceNumber'), isFalse);
  });

  testWidgets('a disabled contract is not on offer', (tester) async {
    final opened = await openPayment(tester);

    await tapVisible(tester, opened.api, ContractorPaymentScreen.contractKey);

    expect(find.byKey(ContractPicker.optionKey(opened.running)), findsOneWidget);
    expect(find.byKey(ContractPicker.optionKey(opened.disabled)), findsNothing);
  });

  testWidgets('what is no number is refused here and never sent', (tester) async {
    final opened = await openPayment(tester);
    await pickContract(tester, opened.api, opened.running);
    await type(tester, ContractorPaymentScreen.amountKey, 'abc');

    await tapVisible(tester, opened.api, ContractorPaymentScreen.draftKey);

    expect(opened.api.sentContractorPayments, isEmpty);
    expect(shown(tester, ContractorPaymentScreen.messageKey), 'en expenses.invalidAmount');
  });

  testWidgets('FR-41: the contract\'s item asks its custom columns, and what is required is marked by the API\'s answer', (tester) async {
    final opened = await openPayment(tester, arrange: (api) {
      final contract = api.addContract('project-0', 'سباك', value: 500, itemId: 'item-9');
      api.addColumn('/projects/project-0/items/item-9/columns', 'custom.stage', isCustom: true, isRequired: true);
      api.expenseAnswer = (status: 400, body: const {'code': 'requiredColumnMissing', 'columnKey': 'custom.stage'});
      contract['supplierName'] = 'سباك';
    });
    final plumber = opened.api.contracts['project-0']!.last['id']! as String;
    await pickContract(tester, opened.api, plumber);
    await type(tester, ContractorPaymentScreen.amountKey, '100');

    await tapVisible(tester, opened.api, ContractorPaymentScreen.sendKey);

    expect(find.text('en expenses.requiredColumnMissing'), findsWidgets);
  });

  testWidgets('who holds no recordEntries has no way in', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject'], units: ['الفلة الغربية']);
    await openProject(tester, api);

    expect(find.byKey(HomeScreen.contractorPaymentKey('project-0')), findsNothing);
  });

  testWidgets('a finished project offers no new payment', (tester) async {
    final api = FakeApi()..addProject('غصون 5', status: 'finished', permissions: field, units: ['الفلة الشرقية']);
    await openProject(tester, api);

    expect(find.byKey(HomeScreen.contractorPaymentKey('project-0')), findsNothing);
  });

  testWidgets('a payment goes under the subgroup chosen, when the contract\'s item has named ones', (tester) async {
    var contractId = '';
    var subgroupId = '';
    final opened = await openPayment(
      tester,
      arrange: (api) {
        api.expenseAnswer = (status: 201, body: const {'isOverrun': false});
        final item = api.addItem(api.addCategory('project-0', 'العظم'), 'بند الحديد', subgroups: ['الدور الأرضي']);
        contractId = api.addContract('project-0', 'مقاول الحديد', value: 1000, itemId: item['id']! as String)['id']! as String;
        subgroupId = (item['subgroups']! as List<Map<String, Object>>).last['id']! as String;
      },
    );
    await pickContract(tester, opened.api, contractId);
    await tapVisible(tester, opened.api, PaymentChoices.paymentMethodKey(opened.method));
    await tapVisible(tester, opened.api, ContractorPaymentScreen.subgroupKey(subgroupId));
    await type(tester, ContractorPaymentScreen.amountKey, '500');

    await tapVisible(tester, opened.api, ContractorPaymentScreen.draftKey);

    expect(opened.api.sentContractorPayments.single['subgroupId'], subgroupId);
  });

  testWidgets('a contract whose item has no named subgroups offers none, and the payment goes under the general one', (tester) async {
    final opened = await openPayment(tester, arrange: (api) => api.expenseAnswer = (status: 201, body: const {'isOverrun': false}));
    await pickContract(tester, opened.api, opened.running);
    await tapVisible(tester, opened.api, PaymentChoices.paymentMethodKey(opened.method));
    await type(tester, ContractorPaymentScreen.amountKey, '500');

    await tapVisible(tester, opened.api, ContractorPaymentScreen.draftKey);

    expect(find.byKey(ContractorPaymentScreen.subgroupKey('any')), findsNothing);
    expect(opened.api.sentContractorPayments.single.containsKey('subgroupId'), isFalse);
  });
}
