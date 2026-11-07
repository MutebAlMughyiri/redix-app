import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/offline/folder_store.dart';
import 'package:redix/offline/outbox.dart';
import 'package:redix/offline/pending_entry.dart';
import 'package:redix/offline/waiting_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/suppliers/supplier_search.dart';

import '../app_harness.dart';

void main() {
  PendingEntry pending(String id, {String ownerId = 'user-signed-in', String refusal = ''}) => PendingEntry(
    ownerId: ownerId,
    projectId: 'project-0',
    route: 'expenses',
    body: {'id': id, 'amount': 6000, 'paymentDate': '2026-11-05'},
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
    expect(api.sentExpenses, isEmpty);
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
      ..expenseAnswer = (status: 400, body: const {'code': 'unknownSupplier'});
    await openProject(tester, api, store: store);
    await act(tester, api, () => tester.pump(Outbox.tryEvery));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));

    expect(tester.widget<Text>(find.byKey(WaitingScreen.stateKey('entry-1'))).data, 'en expenses.unknownSupplier');

    final tries = api.sentExpenses.length;
    await act(tester, api, () => tester.pump(Outbox.tryEvery));
    expect(api.sentExpenses, hasLength(tries));
  });

  testWidgets('a refused entry can be sent again, and leaves once it lands', (tester) async {
    final store = await storeHolding([pending('entry-1', refusal: 'expenses.unknownSupplier')]);
    final api = await openHome(tester, store);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));

    await act(tester, api, () => tester.tap(find.byKey(WaitingScreen.sendAgainKey('entry-1'))));

    expect(api.sentExpenses.single['id'], 'entry-1');
    expect(await store.namesIn('outbox'), isEmpty);
  });

  testWidgets('deleting one asks first, and forgets it', (tester) async {
    final store = await storeHolding([pending('entry-1', refusal: 'expenses.unknownSupplier')]);
    final api = await openHome(tester, store);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.waitingKey('project-0'))));

    await act(tester, api, () => tester.tap(find.byKey(WaitingScreen.discardKey('entry-1'))));
    expect(await store.namesIn('outbox'), ['entry-1']);

    await act(tester, api, () => tester.tap(find.text('en offline.discard').last));

    expect(await store.namesIn('outbox'), isEmpty);
    expect(find.byKey(WaitingScreen.emptyKey), findsOneWidget);
  });

  testWidgets('an answer the server could not give leaves it waiting, to be tried again', (tester) async {
    final store = await storeHolding([pending('entry-1')]);
    final api = FakeApi()
      ..addProject('غصون 6')
      ..expenseAnswer = (status: 503, body: const <String, dynamic>{});
    await openProject(tester, api, store: store);
    await act(tester, api, () => tester.pump(Outbox.tryEvery));

    expect(find.text('en offline.title · 1'), findsOneWidget);
    expect(jsonDecode(await store.read('outbox', 'entry-1'))['refusal'], '');
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
