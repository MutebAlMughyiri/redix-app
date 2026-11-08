import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/config/app_config.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/entries_screen.dart';
import 'package:redix/entries/entry_filter.dart';
import 'package:redix/entries/entry_row.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/home/home_screen.dart';


import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/app_color.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openHome(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = field, String status = 'active'}) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = FakeApi()..addProject('غصون 6', permissions: permissions, status: status, units: ['الفلة الغربية']);
    arrange(api);
    await openProject(tester, api);
    return api;
  }

  Future<FakeApi> openEntries(WidgetTester tester, void Function(FakeApi api) arrange, {List<String> permissions = field, String status = 'active'}) async {
    final api = await openHome(tester, arrange, permissions: permissions, status: status);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.entriesKey('project-0'))));
    return api;
  }

  Future<void> openActions(WidgetTester tester, FakeApi api, String id) => act(tester, api, () => tester.tap(find.byKey(EntriesScreen.rowKey(id))));

  testWidgets('AC-22.1, R1, R2, R3, R15: the home lists the project\'s latest five entries by anyone under القيود, someone else\'s saying who entered it, and counts none of mine waiting or rejected', (tester) async {
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
    expect(find.textContaining('en entries.pendingApproval ·'), findsNothing);
    expect(find.textContaining('en entries.rejected ·'), findsNothing);
    for (final shown in ['entry-5', 'entry-4', 'entry-3', 'entry-2', 'entry-1']) {
      expect(find.byKey(EntriesScreen.rowKey(shown)), findsOneWidget, reason: shown);
    }
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsNothing);
    expect(find.textContaining('en entries.enteredBy'), findsNWidgets(2));
    expect(find.text('en entries.reason: الصورة غير واضحة'), findsNothing, reason: 'Muteb, 9 Nov 2026: the reason shows once the entry is opened');
  });

  testWidgets('Muteb, 9 Nov 2026: a row says where it stands by its frame alone, orange waiting, red rejected, teal a draft and plain once approved, with no status words and no reason', (tester) async {
    await openHome(tester, (api) {
      api
        ..addEntry()
        ..addEntry(status: 'rejected', rejectionReason: 'الصورة غير واضحة')
        ..addEntry(status: 'approved')
        ..addEntry(status: 'approved', isReversed: true)
        ..addEntry(status: 'draft');
    });

    expect([for (final id in ['entry-0', 'entry-1', 'entry-2', 'entry-3', 'entry-4']) frameOf(tester, id)], [AppColor.waiting, AppColor.refusal, AppColor.frame, AppColor.frame, AppColor.brand]);
    for (final word in ['en entries.pendingApproval', 'en entries.rejected', 'en entries.reversed', 'en entries.draft']) {
      expect(find.text(word), findsNothing, reason: word);
    }
    expect(find.textContaining('الصورة غير واضحة'), findsNothing);
  });

  testWidgets('redix-app #88: in a finished project no entry shows the red bar, since nothing is deleted in it', (tester) async {
    await openEntries(tester, (api) => api.addEntry(status: 'draft'), status: 'finished');

    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsOneWidget);
    expect(find.byKey(EntriesScreen.rowKey('entry-0').bar), findsNothing);
  });

  testWidgets('R3, R14: with no entries of their own the home still lists the project\'s, and with none at all says so under its heading', (tester) async {
    await openHome(tester, (api) => api.addEntry(isMine: false));

    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsOneWidget);
    expect(find.byKey(HomeScreen.entriesKey('project-0')), findsOneWidget);
  });

  testWidgets('the home shows a spinner under القيود while its entries are first read, and the rows once they come', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6', permissions: field, units: ['الفلة الغربية'])
      ..addEntry()
      ..heldEntries = Completer<void>();
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await tapWhileWaiting(tester, api, find.byKey(ProjectsScreen.cardKey('project-0')));

    expect(find.byKey(HomeScreen.entriesLoadingKey), findsOneWidget);
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsNothing);

    api.heldEntries.complete();
    await act(tester, api, () async {});

    expect(find.byKey(HomeScreen.entriesLoadingKey), findsNothing);
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsOneWidget);
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

  testWidgets('a reversed entry says so on its page, and its row keeps the plain frame', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'approved', isReversed: true));
    expect(frameOf(tester, 'entry-0'), AppColor.frame);

    await openActions(tester, api, 'entry-0');

    expect(tester.widget<Text>(find.byKey(AddEntryScreen.statusKey)).data, 'en entries.reversed');
  });

  testWidgets('Muteb, 9 Nov 2026: whoever approves finds اعتماد beside Edit on a waiting entry read only, and approving it there approves it and goes back to the list', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(), permissions: managerAndFinance);
    await openActions(tester, api, 'entry-0');
    expect(tester.widget<Text>(find.byKey(AddEntryScreen.approveKey.label)).data, 'en approvals.approve');
    expect(find.byKey(AddEntryScreen.changeKey), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.approveKey)));

    expect(api.sentApprovals.single, ['entry-0']);
    expect(find.byKey(AddEntryScreen.approveKey), findsNothing);
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsOneWidget);
  });

  testWidgets('Muteb, 9 Nov 2026: without Approve entries, اعتماد on a waiting entry shows grayed', (tester) async {
    final field_ = await openEntries(tester, (api) => api.addEntry());
    await openActions(tester, field_, 'entry-0');

    expect(isEnabled(tester, AddEntryScreen.approveKey), isFalse);
    expect(field_.sentApprovals, isEmpty);
  });

  testWidgets('Muteb, 9 Nov 2026: اعتماد on a draft or an approved entry is not offered, even to whoever approves', (tester) async {
    final api = await openEntries(tester, (api) => api..addEntry(status: 'draft')..addEntry(status: 'approved'), permissions: managerAndFinance);
    await openActions(tester, api, 'entry-0');
    expect(find.byKey(AddEntryScreen.approveKey), findsNothing);
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    await openActions(tester, api, 'entry-1');
    expect(find.byKey(AddEntryScreen.approveKey), findsNothing);
  });

  testWidgets('Muteb, 9 Nov 2026: an approval the API refuses for that entry says why, and the entry stays open', (tester) async {
    final api = await openEntries(tester, (api) => api..addEntry()..approvalFailures['entry-0'] = 'entryNotPending', permissions: managerAndFinance);
    await openActions(tester, api, 'entry-0');

    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.approveKey)));

    expect(find.text('en approvals.entryNotPending'), findsOneWidget);
    expect(find.byKey(AddEntryScreen.approveKey), findsOneWidget);
  });

  testWidgets('a draft of their own can be changed, sent or swiped away', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft'));
    expect(find.byKey(EntriesScreen.rowKey('entry-0').swipe), findsOneWidget);

    await openActions(tester, api, 'entry-0');
    expect(find.byKey(AddEntryScreen.changeKey), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendDraftKey)));

    expect(api.sentEntryChanges.single.$2, 'submit');
    expect(frameOf(tester, 'entry-0'), AppColor.waiting);
  });

  testWidgets('redix-app #90 D4: what waits for a decision offers the field Edit grayed, saying why', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry());

    await openActions(tester, api, 'entry-0');

    expect(isEnabled(tester, AddEntryScreen.changeKey), isFalse);
    expect(tester.widget<Text>(find.byKey(AddEntryScreen.cannotChangeKey)).data, 'en entries.notYours');
    expect(find.byKey(EntriesScreen.rowKey('entry-0').swipe), findsNothing);
  });

  testWidgets('Finance can change what waits, and what someone else entered', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(isMine: false), permissions: managerAndFinance);
    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.allKey)));

    await openActions(tester, api, 'entry-0');

    expect(find.byKey(AddEntryScreen.changeKey), findsOneWidget);
  });

  testWidgets('redix-app #90 D4: someone else\'s entry offers the field Edit grayed', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft', isMine: false));
    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.allKey)));

    await openActions(tester, api, 'entry-0');

    expect(isEnabled(tester, AddEntryScreen.changeKey), isFalse);
  });

  testWidgets('what is approved cannot be changed, only reversed, and only by whoever decides', (tester) async {
    final field_ = await openEntries(tester, (api) => api.addEntry(status: 'approved'));
    await openActions(tester, field_, 'entry-0');

    expect(isEnabled(tester, AddEntryScreen.changeKey), isFalse);
    expect(tester.widget<Text>(find.byKey(AddEntryScreen.cannotChangeKey)).data, 'en entries.approvedCannotChange');
    expect(find.byKey(AddEntryScreen.reverseKey), findsNothing);
  });

  testWidgets('AC-50.1: reversing asks why, and the entry then says it was reversed', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'approved'), permissions: managerAndFinance);
    await openActions(tester, api, 'entry-0');

    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.reverseKey)));
    await act(tester, api, () async {
      await tester.enterText(find.byKey(EntriesScreen.reverseReasonKey), 'إدخال خاطئ');
      await tester.tap(find.byKey(EntriesScreen.reverseSendKey));
    });

    expect((api.sentEntryChanges.single.$1, api.sentEntryChanges.single.$2, api.sentEntryChanges.single.$3['reason']), ('entry-0', 'reverse', 'إدخال خاطئ'));
    expect(find.byKey(EntriesScreen.reverseSendKey), findsNothing);
    expect(tester.widget<Text>(find.byKey(AddEntryScreen.statusKey)).data, 'en entries.reversed');
    expect(find.byKey(AddEntryScreen.reverseKey), findsNothing);
  });

  testWidgets('Muteb, 9 Nov 2026: there is no Refresh button, and pulling the list down reads the entries again', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry());
    expect(find.byIcon(Icons.refresh), findsNothing);

    api.entryRows.single['status'] = 'approved';
    await act(tester, api, () => tester.drag(find.byType(ListView), const Offset(0, 500)));
    expect(frameOf(tester, 'entry-0'), AppColor.frame);

    api.entryRows.single['status'] = 'draft';
    await act(tester, api, () => tester.drag(find.byType(ListView), const Offset(0, 500)));
    expect(frameOf(tester, 'entry-0'), AppColor.brand);
  });

  testWidgets('a reversal being sent cannot be sent again: its button is disabled until the answer comes', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'approved'), permissions: managerAndFinance);
    await openActions(tester, api, 'entry-0');
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.reverseKey)));
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
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.reverseKey)));

    await act(tester, api, () => tester.tap(find.byKey(EntriesScreen.reverseSendKey)));

    expect(find.text('en entries.reasonRequired'), findsOneWidget);
    expect(find.byKey(EntriesScreen.reverseSendKey), findsOneWidget);
  });

  testWidgets('a reversed entry cannot be reversed again', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'approved', isReversed: true), permissions: managerAndFinance);

    await openActions(tester, api, 'entry-0');

    expect(find.byKey(AddEntryScreen.reverseKey), findsNothing);
  });

  testWidgets('redix-api #102, redix-app #88: a swipe deletes a draft with no question, and the red bar shows it can', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft'));
    expect(find.byKey(EntriesScreen.rowKey('entry-0').bar), findsOneWidget);

    await swipeToRemove(tester, api, EntriesScreen.rowKey('entry-0'));

    expect(find.byType(AlertDialog), findsNothing);
    expect(api.sentEntryChanges.single.$2, 'delete');
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsNothing);
  });

  testWidgets('redix-api #102: the home\'s latest entries swipe away too', (tester) async {
    final api = await openHome(tester, (api) => api.addEntry(status: 'draft'));
    expect(find.byKey(EntriesScreen.rowKey('entry-0').bar), findsOneWidget);

    await swipeToRemove(tester, api, EntriesScreen.rowKey('entry-0'));

    expect(api.sentEntryChanges.single.$2, 'delete');
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsNothing);
  });

  for (final status in ['draft', 'pendingApproval', 'rejected']) {
    testWidgets('a bill that is $status, not approved, is removed by a swipe, then it leaves the list', (tester) async {
      final api = await openEntries(tester, (api) => api.addEntry(status: status, rejectionReason: status == 'rejected' ? 'الصورة غير واضحة' : ''), permissions: managerAndFinance);

      await swipeToRemove(tester, api, EntriesScreen.rowKey('entry-0'));

      expect((api.sentEntryChanges.single.$1, api.sentEntryChanges.single.$2), ('entry-0', 'delete'));
      expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsNothing);
    });
  }

  testWidgets('an approved bill cannot be removed, only reversed, and stays on the list said to be reversed', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'approved'), permissions: managerAndFinance);
    expect(find.byKey(EntriesScreen.rowKey('entry-0').swipe), findsNothing);
    await openActions(tester, api, 'entry-0');

    expect(isEnabled(tester, AddEntryScreen.changeKey), isFalse);
    expect(tester.widget<Text>(find.byKey(AddEntryScreen.reverseKey.label)).data, 'en entries.reverse');
    await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.reverseKey)));
    await act(tester, api, () async {
      await tester.enterText(find.byKey(EntriesScreen.reverseReasonKey), 'فاتورة مكررة');
      await tester.tap(find.byKey(EntriesScreen.reverseSendKey));
    });
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect((api.sentEntryChanges.single.$1, api.sentEntryChanges.single.$2), ('entry-0', 'reverse'));
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsOneWidget);
    expect(frameOf(tester, 'entry-0'), AppColor.frame);
  });

  testWidgets('without Delete entries a bill does not swipe and shows no red bar, though it can still be changed', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft'), permissions: [for (final permission in field) if (permission != 'deleteEntries') permission]);
    expect(find.byKey(EntriesScreen.rowKey('entry-0').swipe), findsNothing);
    expect(find.byKey(EntriesScreen.rowKey('entry-0').bar), findsNothing);
    await openActions(tester, api, 'entry-0');

    expect(find.byKey(AddEntryScreen.changeKey), findsOneWidget);
  });

  testWidgets('UC-070: a change with no answer within the configured time ends as no connection, and the bill stays', (tester) async {
    config.apply({'requestTimeoutSeconds': '10', 'fileTimeoutSeconds': '120'});
    addTearDown(() => config.apply({}));
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft'));
    api.heldEntryChange = Completer<void>();

    await act(tester, api, () async {
      await tester.drag(find.byKey(EntriesScreen.rowKey('entry-0').swipe), const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();
    });

    expect(find.text('en entries.noConnection'), findsOneWidget);
    expect(find.byKey(EntriesScreen.rowKey('entry-0')), findsOneWidget);
    api.heldEntryChange.complete();
  });

  testWidgets('a finished project changes nothing', (tester) async {
    final api = await openEntries(tester, (api) => api.addEntry(status: 'draft'), status: 'finished');

    expect(find.byKey(EntriesScreen.rowKey('entry-0').swipe), findsNothing);
    await openActions(tester, api, 'entry-0');

    expect(isEnabled(tester, AddEntryScreen.changeKey), isFalse);
  });

  group('AC-19.1: fixing a rejected entry', () {
    Future<FakeApi> openRejected(WidgetTester tester, {bool change = true}) async {
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
            'tableId': (item['subgroups']! as List<Map<String, Object>>).first['id']!,
            'entry': {'id': 'entry-0', 'kind': 'purchase', 'status': 'rejected', 'entryDate': '2026-11-05', 'amount': 1150, 'accountId': account['id']!, 'notes': 'دفعة أولى'},
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
      if (change) {
        await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.changeKey)));
      }
      return api;
    }

    String typed(WidgetTester tester, Key key) => tester.widget<TextField>(find.descendant(of: find.byKey(key), matching: find.byType(TextField), matchRoot: true)).controller!.text;

    testWidgets('redix-app #90 (Muteb, 9 Nov 2026: "let me show all entered details en read mode"): a tap opens the entry read only, its photo and every value as it was filled, with no way to type or take another file', (tester) async {
      await openRejected(tester, change: false);

      expect(tester.widget<Text>(find.byKey(AddEntryScreen.titleKey)).data, 'en entries.view');
      expect(tester.widget<Text>(find.byKey(AddEntryScreen.statusKey)).data, 'en entries.rejected');
      expect(find.byKey(AddEntryScreen.invoicePictureKey), findsOneWidget);
      expect(find.byKey(AddEntryScreen.cameraKey), findsNothing);
      expect(find.byKey(AddEntryScreen.filesKey), findsNothing);
      expect(find.ancestor(of: find.byKey(AddEntryScreen.amountKey), matching: find.byWidgetPredicate((widget) => widget is IgnorePointer && widget.ignoring)), findsWidgets);
      expect(typed(tester, AddEntryScreen.amountKey), '1150');
      expect(typed(tester, AddEntryScreen.notesKey), 'دفعة أولى');
    });

    testWidgets('the reason shows at the top, and the form holds what it held', (tester) async {
      await openRejected(tester);

      expect(tester.widget<Text>(find.byKey(AddEntryScreen.rejectionKey)).data, 'en entries.reason: الصورة غير واضحة');
      expect(typed(tester, AddEntryScreen.amountKey), '1150');
      expect(typed(tester, AddEntryScreen.notesKey), 'دفعة أولى');
      expect(find.byKey(AddEntryScreen.invoicePictureKey), findsOneWidget, reason: 'redix-app #90: the photo it was filled with stays after Edit');
      expect(find.byKey(AddEntryScreen.cameraKey), findsOneWidget);
    });

    testWidgets('saving goes to that entry, with its own id, file and figures', (tester) async {
      final api = await openRejected(tester);

      await tester.ensureVisible(find.byKey(AddEntryScreen.sendKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      expect(api.sentEntryPaths.single, '/projects/project-0/entries/entry-0');
      final body = api.sentEntries.single;
      expect((body['id'], body['attachmentId'], body['amount'], body['date'], body['submit']), ('entry-0', 'attachment-1', 1150, '2026-11-05', true));
      expect(body['supplierId'], isNotEmpty);
      expect(api.sentAttachments, isEmpty, reason: 'redix-app #90: the file it holds is not sent again');
      expect(body['tableId'], isNotEmpty);
    });

    testWidgets('R12, D10: a rejected contractor payment opens in its contract\'s table under the title تعديل, and goes back to its own entry', (tester) async {
      final api = await openEntries(tester, (api) {
        final item = api.addItem(api.addCategory('project-0', 'العظم'), 'بند الحديد', type: 'contractorPayments');
        api.addColumn('/projects/project-0/items/${item['id']}/columns', 'notes');
        final contract = api.addContract('project-0', 'مقاول الحديد', value: 1000, itemId: item['id']! as String);
        final method = api.addPaymentMethod('project-0', 'شبكة');
        final account = api.addAccount('project-0', 'عهدتي', type: 'cashCustody', isMine: true);
        api
          ..addEntry(kind: 'contractorPayment', status: 'rejected', rejectionReason: 'المبلغ خطأ')
          ..entryDetails['entry-0'] = {
            'tableId': contract['id']!,
            'entry': {'id': 'entry-0', 'kind': 'contractorPayment', 'status': 'rejected', 'entryDate': '2026-11-05', 'amount': 500, 'accountId': account['id']!, 'notes': 'دفعة'},
            'expense': {'itemId': item['id']!, 'subgroupId': (item['subgroups']! as List<Map<String, Object>>).first['id']!, 'paymentMethodId': method['id']!, 'customValues': '{}'},
            'purchase': {'supplierId': '00000000-0000-0000-0000-000000000000', 'product': '', 'unitPrice': 0, 'quantity': 0},
            'contractorPayment': {'contractId': contract['id']!, 'isOutsideContract': true},
            'attachments': const <Object>[],
            'links': const <Object>[],
          };
      });
      await openActions(tester, api, 'entry-0');
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.changeKey)));

      expect(tester.widget<Text>(find.byKey(AddEntryScreen.titleKey)).data, 'en entries.edit');
      expect(tester.widget<TablePicker>(find.byKey(AddEntryScreen.tableKey)).chosen.label, 'مقاول الحديد (بند الحديد)');
      expect(find.byKey(AddEntryScreen.supplierKey), findsNothing);
      await tester.ensureVisible(find.byKey(AddEntryScreen.sendKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.sendKey)));

      expect(api.sentEntryPaths.single, '/projects/project-0/entries/entry-0');
      final body = api.sentEntries.single;
      expect((body['tableId'], body['isOutsideContract'], body['amount'], body['notes']), (api.contracts['project-0']!.single['id'], true, 500, 'دفعة'));
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
      ..entryAnswer = (status: 409, body: const {'code': 'entryApproved'});
    final store = MemoryStore();
    await store.write('outbox', 'entry-0', '{"ownerId":"user-signed-in","projectId":"project-0","route":"entries/entry-0","body":{"id":"entry-0","amount":9},"fileName":"","refusal":""}');
    await openProject(tester, api, store: store);
    await act(tester, api, () => tester.pump(const Duration(seconds: 20)));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));

    expect(find.text('en expenses.entryApproved'), findsOneWidget);
  });
}
