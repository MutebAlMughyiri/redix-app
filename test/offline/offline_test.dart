import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/offline/folder_store.dart';
import 'package:redix/offline/outbox.dart';
import 'package:redix/offline/pending_entry.dart';
import 'package:redix/offline/waiting_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/suppliers/supplier_search.dart';
import 'package:redix/ui/api_list_body.dart';

import '../app_harness.dart';

void main() {
  PendingEntry pending(String id, {String ownerId = 'user-signed-in', String refusal = ''}) => PendingEntry(
    ownerId: ownerId,
    projectId: 'project-0',
    route: 'entries',
    body: {'id': id, 'amount': 6000, 'date': '2026-11-05'},
    refusal: refusal,
  );

  Future<MemoryStore> storeHolding(List<PendingEntry> entries) async {
    final store = MemoryStore();
    for (final entry in entries) {
      await store.write('outbox', entry.id, jsonEncode(entry));
    }
    return store;
  }

  Future<FakeApi> openHome(WidgetTester tester, MemoryStore store) async {
    final api = FakeApi()..addProject('غصون 6');
    await openProject(tester, api, store: store);
    return api;
  }

  testWidgets('a list read once answers from what was kept when the network is gone (FR-16)', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});

    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));

    expect(find.byKey(HomeScreen.cardKey('project-0')), findsOneWidget);
  });

  testWidgets('redix-api #126: a project list an earlier version kept, with no isInactive, answers as nothing kept when the network is gone, and the next read comes from the API', (tester) async {
    final api = FakeApi()..online = false;
    final store = MemoryStore();
    await store.write('copies', '/projects', jsonEncode([{...api.addProject('غصون 6')}..remove('isInactive')]));
    await pumpRedix(tester, api, stored: {'session': keptSession}, preferences: keptWords('en'), store: store);

    expect(tester.widget<Text>(find.byKey(ApiListBody.messageKey)).data, 'en projects.loadFailed');
    expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsNothing);

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(ApiListBody.retryKey)));

    expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsOneWidget);
  });

  testWidgets('redix-api #126: a project list kept in the shape this version reads answers when the network is gone', (tester) async {
    final api = FakeApi()..online = false;
    final store = MemoryStore();
    await store.write('copies', '/projects', jsonEncode([api.addProject('غصون 6')]));
    await pumpRedix(tester, api, stored: {'session': keptSession}, preferences: keptWords('en'), store: store);

    expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsOneWidget);
    expect(find.byKey(ApiListBody.messageKey), findsNothing);
  });

  testWidgets('signing out forgets what was kept of the lists, because the next user must not see it', (tester) async {
    final store = MemoryStore();
    final api = FakeApi()..addProject('غصون 6');
    final session = await pumpRedix(tester, api, stored: {'session': keptSession}, store: store);
    expect(await store.namesIn('copies'), isNotEmpty);

    await act(tester, api, session.signOut);

    expect(await store.namesIn('copies'), isEmpty);
  });

  testWidgets('opening a project keeps every list the sync answers, at the address its own read asks', (tester) async {
    final store = MemoryStore();
    final api = FakeApi()
      ..addProject('غصون 6')
      ..syncLists = const {
        '/projects/project-0/suppliers': [
          {'id': 'kept-supplier'},
        ],
      };
    await openProject(tester, api, store: store);

    expect(await store.read('copies', '/projects/project-0/suppliers'), contains('kept-supplier'));
    expect(api.syncs, 1);
  });

  testWidgets('a sync sends the stamp it kept, so nothing changed answers nothing', (tester) async {
    final store = MemoryStore();
    await store.write('copies', '/projects/project-0/stamp', 'stamp-1');
    final api = FakeApi()
      ..addProject('غصون 6')
      ..syncLists = const {
        '/projects/project-0/suppliers': [
          {'id': 'would-be-sent-again'},
        ],
      };
    await openProject(tester, api, store: store);

    expect(await store.read('copies', '/projects/project-0/suppliers'), isEmpty);
  });

  testWidgets('without a network the sync changes nothing that was kept', (tester) async {
    final store = MemoryStore();
    await store.write('copies', '/projects/project-0/suppliers', '[{"id":"kept-before"}]');
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession}, store: store);

    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));

    expect(await store.read('copies', '/projects/project-0/suppliers'), contains('kept-before'));
  });

  testWidgets('the home says how many entries wait, and leads to them', (tester) async {
    final store = await storeHolding([pending('entry-1', refusal: 'expenses.unknownSupplier'), pending('entry-2', refusal: 'expenses.unknownSupplier')]);
    final api = await openHome(tester, store);

    expect(find.text('en offline.title · 2'), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));

    expect(find.byKey(WaitingScreen.rowKey('entry-1')), findsOneWidget);
    expect(find.byKey(WaitingScreen.rowKey('entry-2')), findsOneWidget);
  });

  testWidgets('the home says nothing when nothing waits', (tester) async {
    await openHome(tester, MemoryStore());

    expect(find.byKey(HomeScreen.waitingKey('project-0')), findsNothing);
  });

  testWidgets('what someone else entered on this phone stays theirs: it neither shows nor goes', (tester) async {
    final store = await storeHolding([pending('entry-of-another', ownerId: 'someone-else')]);
    final api = await openHome(tester, store);

    await act(tester, api, () => tester.pump(Outbox.tryEvery));

    expect(find.byKey(HomeScreen.waitingKey('project-0')), findsNothing);
    expect(api.sentEntries, isEmpty);
    expect(await store.namesIn('outbox'), ['entry-of-another']);
  });

  testWidgets('what waits survives a sign-out, and goes when its author signs in again', (tester) async {
    final store = await storeHolding([pending('entry-1', refusal: 'expenses.unknownSupplier')]);
    final api = FakeApi()..addProject('غصون 6');
    final session = await pumpRedix(tester, api, stored: {'session': keptSession}, store: store);

    await act(tester, api, session.signOut);

    expect(await store.namesIn('outbox'), ['entry-1']);
  });

  testWidgets('an entry the API refuses waits for its author, saying why, and is not tried again', (tester) async {
    final store = await storeHolding([pending('entry-1')]);
    final api = FakeApi()
      ..addProject('غصون 6')
      ..entryAnswer = (status: 400, body: const {'code': 'unknownSupplier'});
    await openProject(tester, api, store: store);
    await act(tester, api, () => tester.pump(Outbox.tryEvery));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));

    expect(tester.widget<Text>(find.byKey(WaitingScreen.stateKey('entry-1'))).data, 'en expenses.unknownSupplier');

    final tries = api.sentEntries.length;
    await act(tester, api, () => tester.pump(Outbox.tryEvery));
    expect(api.sentEntries, hasLength(tries));
  });

  testWidgets('a refused entry can be sent again, and leaves once it lands', (tester) async {
    final store = await storeHolding([pending('entry-1', refusal: 'expenses.unknownSupplier')]);
    final api = await openHome(tester, store);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));

    await act(tester, api, () => tester.tap(find.byKey(WaitingScreen.sendAgainKey('entry-1'))));

    expect(api.sentEntries.single['id'], 'entry-1');
    expect(await store.namesIn('outbox'), isEmpty);
  });

  testWidgets('redix-api #98: a kept change of an entry is put when it goes, and a kept new entry posted', (tester) async {
    final change = PendingEntry(ownerId: 'user-signed-in', projectId: 'project-0', route: 'entries/entry-2', body: {'id': 'entry-2', 'amount': 6000, 'date': '2026-11-05'});
    final store = await storeHolding([pending('entry-1'), change]);
    final api = await openHome(tester, store);

    await act(tester, api, () => tester.pump(Outbox.tryEvery));

    expect(api.sentEntryPaths, unorderedEquals(['/projects/project-0/entries', 'PUT /projects/project-0/entries/entry-2']));
    expect(await store.namesIn('outbox'), isEmpty);
  });

  testWidgets('redix-api #102: a swipe forgets one with no question, and a short one forgets nothing', (tester) async {
    final store = await storeHolding([pending('entry-1', refusal: 'expenses.unknownSupplier')]);
    final api = await openHome(tester, store);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));
    expect(find.byKey(WaitingScreen.rowKey('entry-1').bar), findsOneWidget);

    await swipeToAsk(tester, api, WaitingScreen.rowKey('entry-1'), share: 0.2);
    expect(await store.namesIn('outbox'), ['entry-1']);

    await swipeToRemove(tester, api, WaitingScreen.rowKey('entry-1'));

    expect(find.byType(AlertDialog), findsNothing);
    expect(await store.namesIn('outbox'), isEmpty);
    expect(find.byKey(WaitingScreen.emptyKey), findsOneWidget);
  });

  testWidgets('an answer the server could not give leaves it waiting, to be tried again', (tester) async {
    final store = await storeHolding([pending('entry-1')]);
    final api = FakeApi()
      ..addProject('غصون 6')
      ..entryAnswer = (status: 503, body: const <String, dynamic>{});
    await openProject(tester, api, store: store);
    await act(tester, api, () => tester.pump(Outbox.tryEvery));

    expect(find.text('en offline.title · 1'), findsOneWidget);
    expect(jsonDecode(await store.read('outbox', 'entry-1'))['refusal'], '');
  });

  Future<FakeApi> openWaiting(WidgetTester tester, MemoryStore store, {int answer = 503}) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..entryAnswer = (status: answer, body: const <String, dynamic>{});
    await openProject(tester, api, store: store);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));
    return api;
  }

  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('redix-app #103: a refused row spans the screen and says its table, amount, supplier, date, that its bill waits, and why it was refused', (tester) async {
    final entry = PendingEntry(
      ownerId: 'user-signed-in',
      projectId: 'project-0',
      route: 'entries',
      body: {'id': 'entry-1', 'amount': 1000, 'date': '2026-11-11'},
      fileName: 'bill.jpg',
      refusal: 'expenses.unknownSupplier',
      title: 'مواد (البلاط)',
      details: 'شركة النخيل',
    );
    await openWaiting(tester, await storeHolding([entry]));

    expect(text(tester, WaitingScreen.titleKey('entry-1')), 'مواد (البلاط)');
    expect(text(tester, WaitingScreen.amountKey('entry-1')), '1,000.00');
    expect(text(tester, WaitingScreen.detailsKey('entry-1')), allOf(contains('شركة النخيل'), contains(formatDate(DateTime(2026, 11, 11))), contains('en offline.withFile')));
    expect(text(tester, WaitingScreen.stateKey('entry-1')), 'en expenses.unknownSupplier');
    expect(find.byKey(WaitingScreen.autoSendKey), findsOneWidget);
    final screen = tester.getSize(find.byType(Scaffold).last).width;
    expect(tester.getSize(find.byKey(WaitingScreen.rowKey('entry-1'))).width, greaterThan(screen - 48));
  });

  testWidgets('redix-app #103: an entry kept before has its amount for a title, its date shows again, and waiting for the network it says nothing more', (tester) async {
    await openWaiting(tester, await storeHolding([pending('entry-1')]));

    expect(text(tester, WaitingScreen.titleKey('entry-1')), '6,000.00');
    expect(find.byKey(WaitingScreen.stateKey('entry-1')), findsNothing);
    expect(find.byKey(WaitingScreen.amountKey('entry-1')), findsNothing);
    expect(text(tester, WaitingScreen.detailsKey('entry-1')), formatDate(DateTime(2026, 11, 5)));
  });

  testWidgets('redix-app #103: إرسال الآن sends what waits, and the row leaves once it lands', (tester) async {
    final store = await storeHolding([pending('entry-1')]);
    final api = await openWaiting(tester, store);
    expect(find.byKey(WaitingScreen.rowKey('entry-1')), findsOneWidget);
    api.entryAnswer = (status: 200, body: const <String, dynamic>{});

    await act(tester, api, () => tester.tap(find.byKey(WaitingScreen.sendNowKey)));

    expect(api.sentEntries.last['id'], 'entry-1');
    expect(await store.namesIn('outbox'), isEmpty);
    expect(find.byKey(WaitingScreen.emptyKey), findsOneWidget);
  });

  testWidgets('with no network a typed search looks in what was kept, whichever way the name is spelled', (tester) async {
    final store = MemoryStore();
    final api = FakeApi()..addProject('غصون 6');
    final session = await pumpRedix(tester, api, stored: {'session': keptSession}, store: store);
    final kept = [api.addSupplier('project-0', 'مؤسسة أحمد', vatNumber: '300000000000003'), api.addSupplier('project-0', 'شركة النخيل')];
    await store.write('copies', '/projects/project-0/suppliers/search?text=', jsonEncode(kept));
    final search = SupplierSearch(session, 'project-0');
    addTearDown(search.dispose);
    api.online = false;

    await act(tester, api, () => search.find('مؤسسه احمد'));
    expect(search.message, '');
    expect(search.all.single.name, 'مؤسسة أحمد');

    await act(tester, api, () => search.find('٣٠٠٠'));
    expect(search.all.single.name, 'مؤسسة أحمد');

    await act(tester, api, () => search.find('لا يوجد'));
    expect(search.all, isEmpty);
  });

  test('the folder keeps any name, reads back what it was given, and forgets on request', () async {
    final root = await Directory.systemTemp.createTemp('redix-store');
    addTearDown(() => root.delete(recursive: true));
    final store = FolderStore(() async => root);
    const name = '/projects/a b/categories/offered?itemType=purchases';

    expect(await store.read('copies', name), isEmpty);

    await store.write('copies', name, 'مواد');
    await store.writeBytes('files', 'entry-1', [1, 2, 3]);

    expect(await store.read('copies', name), 'مواد');
    expect(await store.readBytes('files', 'entry-1'), [1, 2, 3]);
    expect(await store.namesIn('copies'), [name]);

    await store.delete('files', 'entry-1');
    expect(await store.readBytes('files', 'entry-1'), isEmpty);

    await store.clear('copies');
    expect(await store.namesIn('copies'), isEmpty);
  });
}
