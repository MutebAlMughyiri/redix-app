// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/users/new_user_screen.dart';
import 'package:redix/users/table_ticks.dart';
import 'package:redix/users/users_screen.dart';

import '../app_harness.dart';

/// redix-api #106: «الجداول», where a manager ticks which tables a person sees, on the person's permissions, the new-person form and صلاحياتي.
void main() {
  late String general, columns, finishing;

  /// A project whose item الحديد has its general group and «الأعمدة», and whose item التشطيب has its own, with B in it.
  FakeApi project() {
    final api = FakeApi()..addProject('مشروع A');
    final skeleton = api.addCategory('project-0', 'العظم');
    final subgroups = api.addItem(skeleton, 'الحديد', type: 'purchases', subgroups: ['الأعمدة'])['subgroups']! as List<Map<String, Object>>;
    general = subgroups.first['id']! as String;
    columns = subgroups.last['id']! as String;
    finishing = (api.addItem(api.addCategory('project-0', 'التشطيب'), 'الدهان', type: 'purchases')['subgroups']! as List<Map<String, Object>>).single['id']! as String;
    final manager = api.addUser('A', username: 'owner');
    final user = api.addUser('B', username: 'b');
    api
      ..give(manager, 'project-0', managerAndFinance)
      ..give(user, 'project-0', reader);
    return api;
  }

  Future<FakeApi> openPermissions(WidgetTester tester) async {
    final api = project();
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.usersKey('project-0'));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.permissionsKey)));
    return api;
  }

  Future<void> unfold(WidgetTester tester, FakeApi api, String category) async {
    await bringIntoView(tester, find.byKey(TableTicks.categoryKey(category)));
    await act(tester, api, () => tester.tap(find.byKey(TableTicks.categoryKey(category))));
  }

  bool? ticked(WidgetTester tester, Key key) => tester.widget<CheckboxListTile>(find.byKey(key.body)).value;

  Future<void> tap(WidgetTester tester, FakeApi api, Key key) async {
    await bringIntoView(tester, find.byKey(key));
    await act(tester, api, () => tester.tap(find.byKey(key.body)));
  }

  testWidgets('R5, D8: every table is ticked until unticked, each category folded under «الجداول»', (tester) async {
    final api = await openPermissions(tester);
    final skeleton = api.categories['project-0']!.first['id']! as String;

    await bringIntoView(tester, find.byKey(TableTicks.headingKey));
    expect(find.byKey(TableTicks.tableKey(general)), findsNothing);
    await unfold(tester, api, skeleton);

    expect((ticked(tester, TableTicks.tableKey(general)), ticked(tester, TableTicks.tableKey(columns))), (true, true));
    expect(ticked(tester, TableTicks.itemKey(_itemOf(api, 'الحديد'))), isTrue);
  });

  testWidgets('R4: unticking a table sends it and leaves its item half-ticked; ticking it again sends it back', (tester) async {
    final api = await openPermissions(tester);
    await unfold(tester, api, api.categories['project-0']!.first['id']! as String);

    await tap(tester, api, TableTicks.tableKey(columns));

    expect(api.sentUserChanges.last.$1, '/projects/project-0/users/user-1/tables');
    expect(api.sentUserChanges.last.$2, {'seen': false, 'tableIds': [columns]});
    expect((ticked(tester, TableTicks.tableKey(columns)), ticked(tester, TableTicks.itemKey(_itemOf(api, 'الحديد')))), (false, null));

    await tap(tester, api, TableTicks.tableKey(columns));

    expect(api.sentUserChanges.last.$2, {'seen': true, 'tableIds': [columns]});
    expect(ticked(tester, TableTicks.itemKey(_itemOf(api, 'الحديد'))), isTrue);
  });

  testWidgets("D8, findings row 280: an item's tick unticks all its tables in one request", (tester) async {
    final api = await openPermissions(tester);
    await unfold(tester, api, api.categories['project-0']!.first['id']! as String);

    await tap(tester, api, TableTicks.itemKey(_itemOf(api, 'الحديد')));

    expect(api.sentUserChanges.single.$2, {'seen': false, 'tableIds': [general, columns]});
    expect((ticked(tester, TableTicks.tableKey(general)), ticked(tester, TableTicks.tableKey(columns))), (false, false));
  });

  testWidgets('R3: a new person is added with the tables left unticked on the form', (tester) async {
    final api = project();
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.usersKey('project-0'));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.newUserKey)));
    await tester.enterText(find.byKey(NewUserScreen.nameKey), 'سارة');
    await tester.enterText(find.byKey(NewUserScreen.usernameKey), 'sara');
    await tester.enterText(find.byKey(NewUserScreen.emailKey), 'sara@example.com');
    await tester.enterText(find.byKey(NewUserScreen.passwordKey), 'Temporary-1');
    await unfold(tester, api, api.categories['project-0']!.last['id']! as String);

    await tap(tester, api, TableTicks.tableKey(finishing));
    await bringIntoView(tester, find.byKey(NewUserScreen.submitKey));
    await act(tester, api, () => tester.tap(find.byKey(NewUserScreen.submitKey)));

    expect(api.sentUserChanges.single.$2['unseenTableIds'], [finishing]);
  });

  testWidgets('D9, R7: صلاحياتي shows the tables one sees, read only, and says the periodic report is for whoever sees every table', (tester) async {
    final api = project();
    api.projects.single['unseenTables'] = [columns];
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.myPermissionsKey('project-0'));
    await unfold(tester, api, api.categories['project-0']!.first['id']! as String);

    expect((ticked(tester, TableTicks.tableKey(general)), ticked(tester, TableTicks.tableKey(columns))), (true, false));
    expect(tester.widget<CheckboxListTile>(find.byKey(TableTicks.tableKey(general).body)).onChanged, isNull);
    expect(tester.widget<Text>(find.byKey(TableTicks.headingKey.subtitle)).data, isNotEmpty);
  });

  testWidgets('R7: the periodic reports button is gray for someone who does not see every table', (tester) async {
    final api = project();
    api.projects.single['unseenTables'] = [columns];
    await openProject(tester, api);

    await showProjectSetting(tester, HomeScreen.reportsKey('project-0'));
    expect(tester.widget<TextButton>(find.byKey(HomeScreen.reportsKey('project-0'))).onPressed, isNull);
  });
}

/// The id of the item named [name] in the project.
String _itemOf(FakeApi api, String name) => [
  for (final category in api.categories['project-0']!)
    for (final item in category['items']! as List<Map<String, Object>>)
      if (item['name'] == name) item['id']! as String,
].single;
