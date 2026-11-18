// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/history/my_history_screen.dart';
import 'package:redix/history/project_history_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  /// Starts the app signed in as [api]'s user, on a screen tall enough for every filter's list, and opens the first project.
  Future<void> openAsTheUser(WidgetTester tester, FakeApi api) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false, "userId": "${api.userId}"}';
    await pumpRedix(tester, api, stored: {'session': session});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
  }

  /// Opens the chip [chip] and taps [value] in its list, closing the list when it stays open, as a list of many choices does.
  Future<void> choose(WidgetTester tester, FakeApi api, Key chip, Key value) async {
    await tester.ensureVisible(find.byKey(chip));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(chip)));
    await act(tester, api, () => tester.tap(find.byKey(value)));
    if (tester.widget<Icon>(find.byKey(chip.icon)).icon == Icons.arrow_drop_up) {
      await act(tester, api, () => tester.tap(find.byKey(chip)));
    }
  }

  Future<FakeApi> openProjectHistory(WidgetTester tester, {void Function(FakeApi api)? arrange}) async {
    final api = FakeApi()..addProject('غصون 6', permissions: const ['readProject', 'seeProjectHistory']);
    arrange?.call(api);
    await openAsTheUser(tester, api);
    await scrollAndTap(tester, api, HomeScreen.projectHistoryKey('project-0'));
    return api;
  }

  group('redix-api #86: «سجل المشروع» and «سجلي»', () {
    testWidgets('R7: Project settings opens «سجل المشروع» of the project, for whoever holds its permission', (tester) async {
      final api = await openProjectHistory(tester);
      expect(find.byType(ProjectHistoryScreen), findsOneWidget);
      expect(api.historyReads.last.path, '/projects/project-0/history');
    });

    testWidgets('D5: a line says what was done to what, its name and what else it names, then who and when', (tester) async {
      await openProjectHistory(
        tester,
        arrange: (api) => api
          ..addProjectHistoryLine('project-0', 'changed', 'account', name: 'الراجحي', area: 'accounts', nameWas: 'الأهلي')
          ..addProjectHistoryLine('project-0', 'given', 'permission', name: 'approveEntries', area: 'people', about: 'سارة')
          ..addProjectHistoryLine('project-0', 'created', 'transfer', area: 'accounts', from: 'الراجحي', to: 'الصندوق', amount: 5000),
      );
      expect(text(tester, ProjectHistoryScreen.lineKey(4000).title), 'en history.action.changed en history.thing.account الراجحي · en history.nameWas');
      expect(text(tester, ProjectHistoryScreen.lineKey(3999).title), 'en history.action.given en history.thing.permission en permissions.approveEntries · سارة');
      expect(text(tester, ProjectHistoryScreen.lineKey(3998).title), startsWith('en history.action.created en history.thing.transfer · en history.fromTo · '));
      expect(text(tester, ProjectHistoryScreen.lineKey(4000).subtitle), startsWith('متعب · '));
    });

    testWidgets('UC-073 D9: a project archived and one retrieved, the moment of its archive said as a person reads one', (tester) async {
      await openProjectHistory(
        tester,
        arrange: (api) => api
          ..addProjectHistoryLine('project-0', 'archived', 'project', name: 'غصون 6', area: 'project')
          ..addProjectHistoryLine('project-0', 'retrieved', 'project', name: 'غصون 6', area: 'project', about: '2026-11-11T18:15:04Z'),
      );
      final archivedAt = momentOf('2026-11-11T18:15:04Z');
      expect(text(tester, ProjectHistoryScreen.lineKey(4000).title), 'en history.action.archived en history.thing.project غصون 6');
      expect(text(tester, ProjectHistoryScreen.lineKey(3999).title), 'en history.action.retrieved en history.thing.project غصون 6 · ${formatDate(archivedAt)} ${formatTime(archivedAt)}');
    });

    testWidgets('R5, R13: the kind chip asks for one kind of record, and the person chip for «أنا» or one member, keeping the kind', (tester) async {
      final api = await openProjectHistory(tester, arrange: (api) => api..addMember('user-sara', 'سارة')..addMember(api.userId, 'متعب'));
      await openFilters(tester, api);
      await choose(tester, api, ProjectHistoryScreen.kindChoiceKey, ProjectHistoryScreen.kindKey('accounts'));
      expect(api.historyReads.last.queryParameters['area'], 'accounts');
      expect(text(tester, ProjectHistoryScreen.kindChoiceKey.label), 'en history.kind: en history.area.accounts');

      await choose(tester, api, ProjectHistoryScreen.personChoiceKey, ProjectHistoryScreen.personKey(api.userId));
      expect(api.historyReads.last.queryParameters['by'], api.userId);
      expect(text(tester, ProjectHistoryScreen.personChoiceKey.label), 'en history.person: en history.me');

      await choose(tester, api, ProjectHistoryScreen.personChoiceKey, ProjectHistoryScreen.personKey('user-sara'));
      expect(api.historyReads.last.queryParameters['by'], 'user-sara');
      expect(api.historyReads.last.queryParameters['area'], 'accounts');
    });

    testWidgets('R9: Shared settings opens «سجلي», whose lines say what happened to one\'s login and who did it, filtered by its own kinds', (tester) async {
      final api = FakeApi()
        ..addProject('غصون 6')
        ..addMyHistoryLine('passwordReset', area: 'password', by: 'محمد')
        ..addMyHistoryLine('changed', area: 'details', about: 'sara@example.com');
      await openAsTheUser(tester, api);
      await openSettings(tester, api);
      await scrollAndTap(tester, api, SharedSettingsScreen.myHistoryKey);
      expect(find.byType(MyHistoryScreen), findsOneWidget);
      expect(text(tester, MyHistoryScreen.lineKey(5000).title), 'en history.login.passwordReset');
      expect(text(tester, MyHistoryScreen.lineKey(5000).subtitle), startsWith('محمد · '));
      expect(text(tester, MyHistoryScreen.lineKey(4999).title), 'en history.login.changed · sara@example.com');

      await openFilters(tester, api);
      await act(tester, api, () => tester.tap(find.byKey(MyHistoryScreen.kindChoiceKey)));
      expect(find.byKey(MyHistoryScreen.kindKey('accounts')), findsNothing);
      await act(tester, api, () => tester.tap(find.byKey(MyHistoryScreen.kindChoiceKey)));
      await choose(tester, api, MyHistoryScreen.kindChoiceKey, MyHistoryScreen.kindKey('password'));
      expect(api.historyReads.last.queryParameters['area'], 'password');
      expect(find.byKey(MyHistoryScreen.lineKey(4999)), findsNothing);

      await tester.ensureVisible(find.byKey(MyHistoryScreen.personChoiceKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(MyHistoryScreen.personChoiceKey)));
      expect(find.byKey(MyHistoryScreen.personKey('')), findsOneWidget);
      expect(text(tester, MyHistoryScreen.personKey(api.userId).label), 'en history.me');
    });
  });
}
