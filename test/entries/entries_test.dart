import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/expenses/add_expense_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openHome(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = field, String status = 'running'}) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, status: status, units: ['الفلة الغربية']);
    arrange(api);
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    return api;
  }

  Future<FakeApi> openEntries(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = field, String status = 'running'}) async {
    final api = await openHome(tester, arrange, permissions: permissions, status: status);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.entriesKey('project-0'))));
    return api;
  }

  Future<void> openActions(WidgetTester tester, FakeApi api, String id) => act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey(id))));

  testWidgets('AC-22.1: the home counts what waits and what was rejected, and shows the latest with where each stands', (tester) async {
    await openHome(tester, (api) {
      api
        ..addEntry(status: 'draft')
        ..addEntry()
        ..addEntry(status: 'rejected', rejectionReason: 'الصورة غير واضحة')
        ..addEntry(status: 'approved');
    });

    expect(find.text('en entries.pendingApproval · 1'), findsOneWidget);
    expect(find.text('en entries.rejected · 1'), findsOneWidget);
    expect(find.byKey(EntriesScreen.rowKey('entry-3')), findsOneWidget);
    expect(find.byKey(EntriesScreen.rowKey('entry-1')), findsOneWidget);
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsNothing);
    expect(find.text('en entries.reason: الصورة غير واضحة'), findsOneWidget);
  });

  testWidgets('with no entries of their own the home offers only the way to all of them', (tester) async {
    await openHome(tester, (api) => api.addEntry(isMine: false));

    expect(find.byKey(HomeScreen.waitingCountKey('project-0')), findsNothing);
    expect(find.byKey(HomeScreen.entriesKey('project-0')), findsOneWidget);
  });

  testWidgets('everyone sees all entries, and starts on their own', (tester) async {
    final api = await openEntries(tester, (api) {
      api
        ..addEntry()
        ..addEntry(isMine: false);
    });

    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsOneWidget);
    expect(find.byKey(EntriesScreen.rowKey('entry-1')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.allKey)));

    expect(find.byKey(EntriesScreen.rowKey('entry-1')), findsOneWidget);
  });

  testWidgets('a reversed entry says so', (tester) async {
    await openEntries(tester, (api) => api.addEntry(status: 'approved', isReversed: true));

    expect(tester.widget<Text>(find.byKey(EntriesScreen.statusKey('entry-0'))).data, 'en entries.reversed');
  });

  testWidgets('a draft of their own can be changed, sent or deleted', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft'));

    await openActions(tester, api, 'entry-0');
    expect(find.byKey(EntriesScreen.editKey), findsOneWidget);
    expect(find.byKey(EntriesScreen.deleteKey), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.sendKey)));

    expect(api.sentEntryChanges.single.$2, 'submit');
    expect(tester.widget<Text>(find.byKey(EntriesScreen.statusKey('entry-0'))).data, 'en entries.pendingApproval');
  });

  testWidgets('what waits for a decision offers the field nothing to change', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry());

    await openActions(tester, api, 'entry-0');

    expect(find.byKey(EntriesScreen.editKey), findsNothing);
    expect(find.byKey(EntriesScreen.deleteKey), findsNothing);
  });

  testWidgets('Finance can change what waits, and what someone else entered', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(isMine: false), permissions: managerAndFinance);
    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.allKey)));

    await openActions(tester, api, 'entry-0');

    expect(find.byKey(EntriesScreen.editKey), findsOneWidget);
  });

  testWidgets('someone else\'s entry offers the field nothing', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft', isMine: false));
    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.allKey)));

    await openActions(tester, api, 'entry-0');

    expect(find.byKey(EntriesScreen.editKey), findsNothing);
  });

  testWidgets('what is approved cannot be changed, only reversed, and only by whoever decides', (tester) async {
    final field_ = await openEntries(tester, (api) => api.addEntry(status: 'approved'));
    await openActions(tester, field_, 'entry-0');

    expect(find.byKey(EntriesScreen.editKey), findsNothing);
    expect(find.byKey(EntriesScreen.reverseKey), findsNothing);
  });

  testWidgets('AC-50.1: reversing asks why, and the entry then says it was reversed', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'approved'), permissions: managerAndFinance);
    await openActions(tester, api, 'entry-0');

    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.reverseKey)));
    await act(tester, api, () async {
      await tester.enterText(find.byKey(EntriesScreen.reverseReasonKey), 'إدخال خاطئ');
      await tester.tap(find.byKey(EntriesScreen.reverseSendKey));
    });

    expect((api.sentEntryChanges.single.$1, api.sentEntryChanges.single.$2, api.sentEntryChanges.single.$3['reason']), ('entry-0', 'reverse', 'إدخال خاطئ'));
    expect(find.byKey(EntriesScreen.reverseSendKey), findsNothing);
    expect(tester.widget<Text>(find.byKey(EntriesScreen.statusKey('entry-0'))).data, 'en entries.reversed');
  });

  testWidgets('a refused reversal stays open, saying why', (tester) async {
    final api = await openEntries(tester, (api) {
      api
        ..addEntry(status: 'approved')
        ..entryChangeAnswer = (status: 400, code: 'reasonRequired');
    }, permissions: managerAndFinance);
    await openActions(tester, api, 'entry-0');
    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.reverseKey)));

    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.reverseSendKey)));

    expect(find.text('en entries.reasonRequired'), findsOneWidget);
    expect(find.byKey(EntriesScreen.reverseSendKey), findsOneWidget);
  });

  testWidgets('a reversed entry cannot be reversed again', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'approved', isReversed: true), permissions: managerAndFinance);

    await openActions(tester, api, 'entry-0');

    expect(find.byKey(EntriesScreen.reverseKey), findsNothing);
  });

  testWidgets('deleting asks first, and it leaves the list', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft'));
    await openActions(tester, api, 'entry-0');

    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.deleteKey)));
    expect(api.sentEntryChanges, isEmpty);
    await act(tester, api, () => tester.tap(find.text('en entries.delete').last));

    expect(api.sentEntryChanges.single.$2, 'delete');
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsNothing);
  });

  testWidgets('a finished project changes nothing', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft'), status: 'finished');

    await openActions(tester, api, 'entry-0');

    expect(find.byKey(EntriesScreen.editKey), findsNothing);
    expect(find.byKey(EntriesScreen.deleteKey), findsNothing);
  });

  group('AC-19.1: fixing a rejected entry', () {
    Future<FakeApi> openRejected(WidgetTester tester) async {
      final api = await openEntries(tester, (api) {
        final item = api.addItem(api.addCategory('project-0', 'التشطيب'), 'بند اللياسة', subgroups: ['مواد']);
        for (final key in ['product', 'notes']) {
          api.addColumn('/projects/project-0/items/${item['id']}/columns', key);
        }
        final supplier = api.addSupplier('project-0', 'شركة البواني', vatNumber: '300000000000003');
        final method = api.addPaymentMethod('project-0', 'شبكة');
        final account = api.addAccount('project-0', 'عهدتي', type: 'cashCustody', isMine: true);
        api
          ..addEntry(status: 'rejected', rejectionReason: 'الصورة غير واضحة')
          ..entryDetails['entry-0'] = {
            'entry': {'id': 'entry-0', 'status': 'rejected', 'entryDate': '2026-11-05', 'amount': 1150, 'accountId': account['id']!, 'notes': 'دفعة أولى'},
            'expense': {'itemId': item['id']!, 'subgroupId': (item['subgroups']! as List<Map<String, Object>>).first['id']!, 'unitId': 'project-0-unit-0', 'paymentMethodId': method['id']!, 'bankFees': 0, 'withoutInvoiceReason': '', 'customValues': '{}'},
            'purchase': {'supplierId': supplier['id']!, 'product': 'مواد لياسة', 'unitPrice': 0, 'quantity': 0},
            'contractorPayment': {'contractId': '00000000-0000-0000-0000-000000000000', 'isOutsideContract': false},
            'invoice': {'number': '2617', 'invoiceDate': '2026-11-05', 'amountBeforeDiscount': 1000, 'discount': 0, 'amountAfterDiscount': 1000, 'vat': 150, 'total': 1150, 'isCreditNote': false},
            'attachments': [
              {'attachmentId': 'attachment-1'},
            ],
            'links': const <Object>[],
          };
      });
      await openActions(tester, api, 'entry-0');
      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.editKey)));
      return api;
    }

    String typed(WidgetTester tester, Key key) => tester.widget<TextField>(find.descendant(of: find.byKey(key), matching: find.byType(TextField), matchRoot: true)).controller!.text;

    testWidgets('the reason shows at the top, and the form holds what it held', (tester) async {
      await openRejected(tester);

      expect(tester.widget<Text>(find.byKey(AddExpenseScreen.rejectionKey)).data, 'en entries.reason: الصورة غير واضحة');
      expect(typed(tester, AddExpenseScreen.invoiceNumberKey), '2617');
      expect(typed(tester, AddExpenseScreen.amountKey), '1000');
      expect(typed(tester, AddExpenseScreen.notesKey), 'دفعة أولى');
    });

    testWidgets('saving goes to that entry, with its own id, file and figures', (tester) async {
      final api = await openRejected(tester);

      await tester.ensureVisible(find.byKey(AddExpenseScreen.sendKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AddExpenseScreen.sendKey)));

      expect(api.sentExpensePaths.single, '/projects/project-0/expenses/entry-0');
      final body = api.sentExpenses.single;
      expect((body['id'], body['attachmentId'], body['amount'], body['amountIncludesVat'], body['submit']), ('entry-0', 'attachment-1', 1000, false, true));
      expect(body['supplierId'], isNotEmpty);
      expect(body['subgroupId'], isNotEmpty);
    });
  });

  testWidgets('AC-16.2: an offline change that arrives after approval says it was not applied', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6', permissions: field, units: ['الفلة الغربية'])
      ..expenseAnswer = (status: 409, body: const {'code': 'entryApproved'});
    final store = MemoryStore();
    await store.write('outbox', 'entry-0', '{"ownerId":"user-signed-in","projectId":"project-0","route":"expenses/entry-0","body":{"id":"entry-0","amount":9},"fileName":"","refusal":""}');
    await pumpRedix(tester, api, stored: {'session': keptSession}, store: store);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await act(tester, api, () => tester.pump(const Duration(seconds: 20)));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));

    expect(find.text('en expenses.entryApproved'), findsOneWidget);
  });
}
