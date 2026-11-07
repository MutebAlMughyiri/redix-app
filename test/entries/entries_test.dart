import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/config/app_config.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/entries/entry_filter.dart';
import 'package:redix/entries/entry_row.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/home/home_screen.dart';

import 'package:redix/ui/refresh_button.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openHome(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = field, String status = 'running'}) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, status: status, units: ['الفلة الغربية']);
    arrange(api);
    await openProject(tester, api);
    return api;
  }

  Future<FakeApi> openEntries(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = field, String status = 'running'}) async {
    final api = await openHome(tester, arrange, permissions: permissions, status: status);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.entriesKey('project-0'))));
    return api;
  }

  Future<void> openActions(WidgetTester tester, FakeApi api, String id) => act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey(id))));

  testWidgets('AC-22.1, R1, R2, R3, R15: the home lists the project\'s latest five entries by anyone under القيود, someone else\'s saying who entered it, and counts what of mine waits and was rejected', (tester) async {
    await openHome(tester, (api) {
      api
        ..addEntry(status: 'draft')
        ..addEntry()
        ..addEntry(status: 'rejected', rejectionReason: 'الصورة غير واضحة')
        ..addEntry(status: 'approved')
        ..addEntry(isMine: false)
        ..addEntry(isMine: false, status: 'approved');
    });

    expect(find.text('en entries.title'), findsOneWidget);
    expect(find.text('en entries.pendingApproval · 1'), findsOneWidget);
    expect(find.text('en entries.rejected · 1'), findsOneWidget);
    for (final shown in ['entry-5', 'entry-4', 'entry-3', 'entry-2', 'entry-1']) {
      expect(find.byKey(EntriesScreen.rowKey(shown)), findsOneWidget, reason: shown);
    }
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsNothing);
    expect(find.textContaining('en entries.enteredBy'), findsNWidgets(2));
    expect(find.text('en entries.reason: الصورة غير واضحة'), findsOneWidget);
  });

  testWidgets('R3, R14: with no entries of their own the home counts nothing of theirs and still lists the project\'s, and with none at all says so under its heading', (tester) async {
    await openHome(tester, (api) => api.addEntry(isMine: false));

    expect(find.byKey(HomeScreen.waitingCountKey('project-0')), findsNothing);
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsOneWidget);
    expect(find.byKey(HomeScreen.entriesKey('project-0')), findsOneWidget);
  });

  testWidgets('R14: a project with no entries keeps its heading, its search and the way to all, and says it has none', (tester) async {
    await openHome(tester, (api) {});

    expect(find.text('en entries.title'), findsOneWidget);
    expect(find.text('en entries.empty'), findsOneWidget);
    expect(find.byKey(HomeScreen.searchEntriesKey('project-0')), findsOneWidget);
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

  testWidgets('the refresh button and pulling the list down each read the entries again', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry());

    api.entryRows.single['status'] = 'approved';
    await act(tester, api, () => tester.tap(find.byKey(RefreshButton.buttonKey)));
    expect(tester.widget<Text>(find.byKey(EntriesScreen.statusKey('entry-0'))).data, 'en entries.approved');

    api.entryRows.single['status'] = 'draft';
    await act(tester, api, () => tester.drag(find.byType(ListView), const Offset(0, 500)));
    expect(tester.widget<Text>(find.byKey(EntriesScreen.statusKey('entry-0'))).data, 'en entries.draft');
  });

  testWidgets('a reversal being sent cannot be sent again: its button is disabled until the answer comes', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'approved'), permissions: managerAndFinance);
    await openActions(tester, api, 'entry-0');
    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.reverseKey)));
    await tester.enterText(find.byKey(EntriesScreen.reverseReasonKey), 'إدخال خاطئ');
    api.heldEntryChange = Completer<void>();

    await act(tester, api, () async {
      await tester.tap(find.byKey(EntriesScreen.reverseSendKey));
      await tester.pump();
      await tester.tap(find.byKey(EntriesScreen.reverseSendKey), warnIfMissed: false);
    });

    expect(tester.widget<FilledButton>(find.byKey(EntriesScreen.reverseSendKey)).onPressed, isNull);
    await act(tester, api, () async => api.heldEntryChange.complete());
    expect(api.sentEntryChanges.length, 1);
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

  for (final status in ['draft', 'pendingApproval', 'rejected']) {
    testWidgets('a bill that is $status, not approved, is removed: Delete asks first, then it leaves the list', (tester) async {
      final api = await openEntries(tester, (api) => api.addEntry(status: status, rejectionReason: status == 'rejected' ? 'الصورة غير واضحة' : ''), permissions: managerAndFinance);
      await openActions(tester, api, 'entry-0');
      expect(find.byKey(EntriesScreen.reverseKey), findsNothing);

      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.deleteKey)));
      await act(tester, api, () => tester.tap(find.text('en entries.delete').last));

      expect((api.sentEntryChanges.single.$1, api.sentEntryChanges.single.$2), ('entry-0', 'delete'));
      expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsNothing);
    });
  }

  testWidgets('an approved bill cannot be removed, only reversed, and stays on the list said to be reversed', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'approved'), permissions: managerAndFinance);
    await openActions(tester, api, 'entry-0');

    expect(find.byKey(EntriesScreen.deleteKey), findsNothing);
    expect(find.byKey(EntriesScreen.editKey), findsNothing);
    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.reverseKey)));
    await act(tester, api, () async {
      await tester.enterText(find.byKey(EntriesScreen.reverseReasonKey), 'فاتورة مكررة');
      await tester.tap(find.byKey(EntriesScreen.reverseSendKey));
    });

    expect((api.sentEntryChanges.single.$1, api.sentEntryChanges.single.$2), ('entry-0', 'reverse'));
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(EntriesScreen.statusKey('entry-0'))).data, 'en entries.reversed');
  });

  testWidgets('without Delete entries a bill offers no Delete, though it can still be changed', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft'), permissions: [for (final permission in field) if (permission != 'deleteEntries') permission]);
    await openActions(tester, api, 'entry-0');

    expect(find.byKey(EntriesScreen.editKey), findsOneWidget);
    expect(find.byKey(EntriesScreen.deleteKey), findsNothing);
  });

  testWidgets('UC-070: a change with no answer within the configured time ends as no connection, and the bill stays', (tester) async {
    config.apply({'requestTimeoutSeconds': '10', 'fileTimeoutSeconds': '120'});
    addTearDown(() => config.apply({}));
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft'));
    await openActions(tester, api, 'entry-0');
    api.heldEntryChange = Completer<void>();

    await act(tester, api, () async {
      await tester.tap(find.byKey(EntriesScreen.deleteKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('en entries.delete').last);
      await tester.pump(const Duration(seconds: 11));
    });

    expect(find.text('en entries.noConnection'), findsOneWidget);
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsOneWidget);
    api.heldEntryChange.complete();
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
            'expense': {'itemId': item['id']!, 'subgroupId': (item['subgroups']! as List<Map<String, Object>>).first['id']!, 'paymentMethodId': method['id']!, 'customValues': '{}'},
            'purchase': {'supplierId': supplier['id']!, 'product': 'مواد لياسة', 'unitPrice': 0, 'quantity': 0},
            'contractorPayment': {'contractId': '00000000-0000-0000-0000-000000000000', 'isOutsideContract': false},
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

      expect(tester.widget<Text>(find.byKey(AddEntryScreen.rejectionKey)).data, 'en entries.reason: الصورة غير واضحة');
      expect(typed(tester, AddEntryScreen.amountKey), '1150');
      expect(typed(tester, AddEntryScreen.notesKey), 'دفعة أولى');
    });

    testWidgets('saving goes to that entry, with its own id, file and figures', (tester) async {
      final api = await openRejected(tester);

      await tester.ensureVisible(find.byKey(AddEntryScreen.sendKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      expect(api.sentExpensePaths.single, '/projects/project-0/expenses/entry-0');
      final body = api.sentExpenses.single;
      expect((body['id'], body['attachmentId'], body['amount'], body['paymentDate'], body['submit']), ('entry-0', 'attachment-1', 1150, '2026-11-05', true));
      expect(body['supplierId'], isNotEmpty);
      expect(body['subgroupId'], isNotEmpty);
    });

    testWidgets('R12, D10: a rejected contractor payment opens in its contract\'s table under the title تعديل, and goes back to its own route', (tester) async {
      final api = await openEntries(tester, (api) {
        final item = api.addItem(api.addCategory('project-0', 'العظم'), 'بند الحديد', type: 'contractorPayments');
        api.addColumn('/projects/project-0/items/${item['id']}/columns', 'notes');
        final contract = api.addContract('project-0', 'مقاول الحديد', value: 1000, itemId: item['id']! as String);
        final method = api.addPaymentMethod('project-0', 'شبكة');
        final account = api.addAccount('project-0', 'عهدتي', type: 'cashCustody', isMine: true);
        api
          ..addEntry(kind: 'contractorPayment', status: 'rejected', rejectionReason: 'المبلغ خطأ')
          ..entryDetails['entry-0'] = {
            'entry': {'id': 'entry-0', 'kind': 'contractorPayment', 'status': 'rejected', 'entryDate': '2026-11-05', 'amount': 500, 'accountId': account['id']!, 'notes': 'دفعة'},
            'expense': {'itemId': item['id']!, 'subgroupId': (item['subgroups']! as List<Map<String, Object>>).first['id']!, 'paymentMethodId': method['id']!, 'customValues': '{}'},
            'purchase': {'supplierId': '00000000-0000-0000-0000-000000000000', 'product': '', 'unitPrice': 0, 'quantity': 0},
            'contractorPayment': {'contractId': contract['id']!, 'isOutsideContract': true},
            'attachments': const <Object>[],
            'links': const <Object>[],
          };
      });
      await openActions(tester, api, 'entry-0');
      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.editKey)));

      expect(tester.widget<Text>(find.byKey(AddEntryScreen.titleKey)).data, 'en entries.edit');
      expect(tester.widget<TablePicker>(find.byKey(AddEntryScreen.tableKey)).chosen.label, 'بند الحديد › مقاول الحديد');
      expect(find.byKey(AddEntryScreen.supplierKey), findsNothing);
      await tester.ensureVisible(find.byKey(AddEntryScreen.sendKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      expect(api.sentExpensePaths.single, '/projects/project-0/contractor-payments/entry-0');
      final body = api.sentContractorPayments.single;
      expect((body['contractId'], body['isOutsideContract'], body['amount'], body['notes']), (api.contracts['project-0']!.single['id'], true, 500, 'دفعة'));
    });
  });

  testWidgets('R5: one إضافة قيد button sits at the bottom of the home, and opens the screen to add an entry', (tester) async {
    final api = await openHome(tester, (api) {});

    expect(find.text('en entries.new'), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey('project-0'))));

    expect(tester.widget<Text>(find.byKey(AddEntryScreen.titleKey)).data, 'en entries.new');
  });

  group('search', () {
    /// القيود opened from the home's search button, over entries of two kinds, two people and several days.
    Future<FakeApi> openSearch(WidgetTester tester) async {
      final api = await openHome(tester, (api) {
        api
          ..addEntry(status: 'approved')
          ..addEntry(kind: 'contractorPayment', status: 'approved', amount: 12000)
          ..addEntry(isMine: false, status: 'rejected', amount: 300)
          ..addEntry(kind: 'contractorPayment', isMine: false);
        api.entryRows.firstWhere((row) => row['id'] == 'entry-3')
          ..['supplierName'] = 'مؤسسة أحمد للمقاولات'
          ..['entryDate'] = '2026-10-20';
        api.entryRows.firstWhere((row) => row['id'] == 'entry-1')['itemName'] = 'بند الحديد';
      });
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.searchEntriesKey('project-0'))));
      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.allKey)));
      return api;
    }

    List<String> shownRows(WidgetTester tester) => [
      for (final element in find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith('entries.row.')).evaluate())
        (element.widget.key! as ValueKey<String>).value.substring('entries.row.'.length),
    ];

    testWidgets('R4: the search beside القيود opens the list ready to type, with every entry counted', (tester) async {
      await openSearch(tester);

      expect(tester.widget<SearchBar>(find.byKey(EntriesScreen.searchKey)).autoFocus, isTrue);
      expect(shownRows(tester), ['entry-3', 'entry-2', 'entry-1', 'entry-0']);
      expect(find.text('en entries.found'), findsOneWidget);
    });

    testWidgets('R8, R16: the text finds the item, the supplier and the amount, Arabic spelling read as one and digits in either script', (tester) async {
      final api = await openSearch(tester);

      await act(tester, api, () => tester.enterText(find.byKey(EntriesScreen.searchKey), 'احمد'));
      expect(shownRows(tester), ['entry-3']);
      await act(tester, api, () => tester.enterText(find.byKey(EntriesScreen.searchKey), 'الحديد'));
      expect(shownRows(tester), ['entry-1']);
      await act(tester, api, () => tester.enterText(find.byKey(EntriesScreen.searchKey), '١٢٠٠٠'));
      expect(shownRows(tester), ['entry-1']);
    });

    testWidgets('R8: a kind and a status keep only what holds both, mine keeps only mine, and clearing shows all again', (tester) async {
      final api = await openSearch(tester);

      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.kindKey('contractorPayment'))));
      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.statusFilterKey('entries.approved'))));
      expect(shownRows(tester), ['entry-1']);

      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.clearKey)));
      expect(shownRows(tester), ['entry-3', 'entry-2', 'entry-1', 'entry-0']);
      expect(find.byKey(EntriesScreen.clearKey), findsNothing);

      await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.mineKey)));
      expect(shownRows(tester), ['entry-1', 'entry-0']);
    });

    testWidgets('R8: a period keeps the entries dated inside it, both ends included', (tester) async {
      final filter = EntryFilter()
        ..onlyMine = false
        ..period = DateTimeRange(start: DateTime(2026, 10, 20), end: DateTime(2026, 11, 4));
      final api = await openSearch(tester);

      expect(api.entryRows.map(EntryRow.fromJson).where(filter.keeps).map((entry) => entry.id), ['entry-3']);
      filter.period = DateTimeRange(start: DateTime(2026, 11, 5), end: DateTime(2026, 11, 5));
      expect(api.entryRows.map(EntryRow.fromJson).where(filter.keeps).map((entry) => entry.id), ['entry-2', 'entry-1', 'entry-0']);
    });
  });

  testWidgets('AC-16.2: an offline change that arrives after approval says it was not applied', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6', permissions: field, units: ['الفلة الغربية'])
      ..expenseAnswer = (status: 409, body: const {'code': 'entryApproved'});
    final store = MemoryStore();
    await store.write('outbox', 'entry-0', '{"ownerId":"user-signed-in","projectId":"project-0","route":"expenses/entry-0","body":{"id":"entry-0","amount":9},"fileName":"","refusal":""}');
    await openProject(tester, api, store: store);
    await act(tester, api, () => tester.pump(const Duration(seconds: 20)));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));

    expect(find.text('en expenses.entryApproved'), findsOneWidget);
  });
}
