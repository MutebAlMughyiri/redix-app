// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/users/permission_ticks.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/users/new_user_screen.dart';
import 'package:redix/users/users_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openForm(WidgetTester tester, {void Function(FakeApi api)? arrange}) async {
    final api = FakeApi()..addProject('غصون 6');
    arrange?.call(api);
    api.give(api.addUser('متعب', username: 'muteb'), 'project-0', managerAndFinance);
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.usersKey('project-0'));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.newUserKey)));
    return api;
  }

  Future<void> fillAndSubmit(WidgetTester tester, FakeApi api) => act(tester, api, () async {
    await tester.enterText(find.byKey(NewUserScreen.nameKey), 'نواف');
    await tester.enterText(find.byKey(NewUserScreen.usernameKey), 'nawaf');
    await tester.enterText(find.byKey(NewUserScreen.mobileKey), '0500000000');
    await tester.enterText(find.byKey(NewUserScreen.emailKey), 'nawaf@example.com');
    await tester.enterText(find.byKey(NewUserScreen.passwordKey), 'Temporary-1');
    await tester.ensureVisible(find.byKey(NewUserScreen.submitKey));
    await tester.tap(find.byKey(NewUserScreen.submitKey));
  });

  String typed(WidgetTester tester, Key key) => tester.widget<TextField>(find.byKey(key)).controller!.text;

  testWidgets('a user is added, and the list shows them', (tester) async {
    final api = await openForm(tester);

    await fillAndSubmit(tester, api);

    final (path, body) = api.sentUserChanges.single;
    expect(path, '/projects/project-0/users');
    expect(body, {'displayName': 'نواف', 'username': 'nawaf', 'roleName': '', 'mobile': '0500000000', 'email': 'nawaf@example.com', 'temporaryPassword': 'Temporary-1', 'permissions': ['readProject'], 'partnerIds': <String>[]});
    expect(find.byKey(NewUserScreen.submitKey), findsNothing);
    expect(tester.widget<Text>(find.byKey(UsersScreen.nameKey('user-1'))).data, 'نواف');
  });

  testWidgets('redix-api #127 AC-07.8: the form asks for the email, which is sent with the new person', (tester) async {
    final api = await openForm(tester);

    expect(tester.widget<TextField>(find.byKey(NewUserScreen.emailKey)).decoration!.labelText, 'en users.email');
    await fillAndSubmit(tester, api);

    expect(api.sentUserChanges.single.$2['email'], 'nawaf@example.com');
  });

  testWidgets('redix-api #127 AC-07.8, R9: an email the API refuses keeps the form open saying why, with what was typed', (tester) async {
    final api = await openForm(tester);
    api.userAnswer = (status: 409, code: 'emailTaken');

    await fillAndSubmit(tester, api);

    expect(tester.widget<Text>(find.byKey(NewUserScreen.messageKey)).data, 'en users.emailTaken');
    expect(typed(tester, NewUserScreen.emailKey), 'nawaf@example.com');
    expect(find.byKey(NewUserScreen.submitKey), findsOneWidget);
  });

  testWidgets('Muteb, 9 Nov 2026: a role name typed beside the username is sent with the new user, and the list shows it beside the username', (tester) async {
    final api = await openForm(tester);

    await tester.enterText(find.byKey(NewUserScreen.roleNameKey), 'مشرف ميداني');
    await fillAndSubmit(tester, api);

    expect(api.sentUserChanges.single.$2['roleName'], 'مشرف ميداني');
    expect(tester.widget<Text>(find.byKey(UsersScreen.detailsKey('user-1'))).data, 'nawaf · مشرف ميداني · 0500000000');
  });

  testWidgets('what is ticked is sent with the new user, and See the project is always ticked', (tester) async {
    final api = await openForm(tester);
    Finder tick(Permission permission) => find.byKey(NewUserScreen.permissionKey(permission).body);

    expect(tester.widget<CheckboxListTile>(tick(Permission.readProject)).onChanged, isNull);
    await tester.ensureVisible(tick(Permission.recordEntries));
    await tester.tap(tick(Permission.recordEntries));
    await tester.pump();
    await fillAndSubmit(tester, api);

    expect(api.sentUserChanges.single.$2['permissions'], ['readProject', 'recordEntries']);
    expect(find.byKey(NewUserScreen.permissionKey(Permission.approveProjects)), findsNothing);
  });

  testWidgets('a tick taken off again is not sent', (tester) async {
    final api = await openForm(tester);
    final recordEntries = find.byKey(NewUserScreen.permissionKey(Permission.recordEntries).body);
    await tester.ensureVisible(recordEntries);
    await tester.tap(recordEntries);
    await tester.pump();
    await tester.tap(recordEntries);
    await tester.pump();
    await fillAndSubmit(tester, api);

    expect(api.sentUserChanges.single.$2['permissions'], ['readProject']);
  });

  group('redix-api #106: the partners a new person sees', () {
    Future<(FakeApi, String, String)> openWithPartners(WidgetTester tester) async {
      late String khaled;
      late String saad;
      final api = await openForm(tester, arrange: (api) {
        khaled = api.addPartner('project-0', 'خالد')['id']! as String;
        saad = api.addPartner('project-0', 'سعد')['id']! as String;
      });
      return (api, khaled, saad);
    }

    Future<void> tap(WidgetTester tester, Key key) async {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    testWidgets('the partners ticked under رأس مال شركاء محددين are sent with the new person; one unticked again is not', (tester) async {
      final (api, khaled, saad) = await openWithPartners(tester);
      await tap(tester, NewUserScreen.permissionKey(Permission.seeChosenCapital).body);
      await tap(tester, PermissionTicks.partnerKey(khaled).body);
      await tap(tester, PermissionTicks.partnerKey(saad).body);
      await tap(tester, PermissionTicks.partnerKey(saad).body);

      expect(tester.widget<CheckboxListTile>(find.byKey(PermissionTicks.partnerKey(khaled).body)).value, isTrue);
      await fillAndSubmit(tester, api);

      expect(api.sentUserChanges.single.$2['permissions'], ['readProject', 'seeChosenCapital']);
      expect(api.sentUserChanges.single.$2['partnerIds'], [khaled]);
    });

    testWidgets('رأس مال كل الشركاء takes رأس مال شركاء محددين, and the partners chosen under it are not sent', (tester) async {
      final (api, khaled, _) = await openWithPartners(tester);
      await tap(tester, NewUserScreen.permissionKey(Permission.seeChosenCapital).body);
      await tap(tester, PermissionTicks.partnerKey(khaled).body);
      await tap(tester, NewUserScreen.permissionKey(Permission.seeAllCapital).body);
      await fillAndSubmit(tester, api);

      expect(api.sentUserChanges.single.$2['permissions'], ['readProject', 'seeAllCapital']);
      expect(api.sentUserChanges.single.$2['partnerIds'], isEmpty);
    });
  });

  testWidgets('a mobile typed in Arabic digits is sent in Western digits', (tester) async {
    final api = await openForm(tester);

    await act(tester, api, () async {
      await tester.enterText(find.byKey(NewUserScreen.nameKey), 'نواف');
      await tester.enterText(find.byKey(NewUserScreen.usernameKey), 'nawaf');
      await tester.enterText(find.byKey(NewUserScreen.mobileKey), '٠٥٠٠٠٠٠٠٠٠');
      await tester.enterText(find.byKey(NewUserScreen.passwordKey), 'Temporary-1');
      await tester.ensureVisible(find.byKey(NewUserScreen.submitKey));
      await tester.tap(find.byKey(NewUserScreen.submitKey));
    });

    expect(api.sentUserChanges.single.$2['mobile'], '0500000000');
  });

  testWidgets('the temporary password shows as typed, so the project manager can pass it on', (tester) async {
    await openForm(tester);

    expect(tester.widget<TextField>(find.byKey(NewUserScreen.passwordKey)).obscureText, isFalse);
  });

  testWidgets('redix-api #113: the temporary password says it changes at first sign-in, and what the password policy asks', (tester) async {
    await openForm(tester);

    expect(tester.widget<TextField>(find.byKey(NewUserScreen.passwordKey)).decoration!.helperText, 'en users.temporaryPasswordHint · en common.passwordRules');
  });

  testWidgets('redix-app #98: refused from the bottom of a long form on a small screen, its line above the first field is built and brought into view', (tester) async {
    tester.view.physicalSize = const Size(360, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = await openForm(tester);

    api.userAnswer = (status: 409, code: 'usernameTaken');
    await fillAndSubmit(tester, api);

    expectErrorAbove(tester, NewUserScreen.messageKey, NewUserScreen.nameKey);
  });

  testWidgets('a taken username shows its own line, and nothing typed is lost', (tester) async {
    final api = await openForm(tester);

    api.userAnswer = (status: 409, code: 'usernameTaken');
    await fillAndSubmit(tester, api);

    expect(tester.widget<Text>(find.byKey(NewUserScreen.messageKey)).data, 'en users.usernameTaken');
    expectErrorAbove(tester, NewUserScreen.messageKey, NewUserScreen.nameKey);
    expect(typed(tester, NewUserScreen.nameKey), 'نواف');
    expect(typed(tester, NewUserScreen.usernameKey), 'nawaf');
    expect(typed(tester, NewUserScreen.passwordKey), 'Temporary-1');
  });

  testWidgets('without a network the form says so, and nothing typed is lost', (tester) async {
    final api = await openForm(tester);

    api.online = false;
    await fillAndSubmit(tester, api);

    expect(tester.widget<Text>(find.byKey(NewUserScreen.messageKey)).data, 'en users.noConnection');
    expect(typed(tester, NewUserScreen.usernameKey), 'nawaf');
  });
}
