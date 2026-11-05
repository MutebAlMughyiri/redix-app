import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/users/new_user_screen.dart';
import 'package:redix/users/users_screen.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openForm(WidgetTester tester) async {
    final api = FakeApi()..addProject('غصون 6');
    api.giveRole(api.addUser('متعب', username: 'muteb'), 'project-0', 'role-manager');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.usersKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.newUserKey)));
    return api;
  }

  Future<void> fillAndSubmit(WidgetTester tester, FakeApi api) => act(tester, api, () async {
    await tester.enterText(find.byKey(NewUserScreen.nameKey), 'نواف');
    await tester.enterText(find.byKey(NewUserScreen.usernameKey), 'nawaf');
    await tester.enterText(find.byKey(NewUserScreen.mobileKey), '0500000000');
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
    expect(body, {'displayName': 'نواف', 'username': 'nawaf', 'mobile': '0500000000', 'temporaryPassword': 'Temporary-1'});
    expect(find.byKey(NewUserScreen.submitKey), findsNothing);
    expect(tester.widget<Text>(find.byKey(UsersScreen.nameKey('user-1'))).data, 'نواف');
  });

  testWidgets('the temporary password shows as typed, so the project manager can pass it on', (tester) async {
    await openForm(tester);

    expect(tester.widget<TextField>(find.byKey(NewUserScreen.passwordKey)).obscureText, isFalse);
  });

  testWidgets('a taken username shows its own line, and nothing typed is lost', (tester) async {
    final api = await openForm(tester);

    api.userAnswer = (status: 409, code: 'usernameTaken');
    await fillAndSubmit(tester, api);

    expect(tester.widget<Text>(find.byKey(NewUserScreen.messageKey)).data, 'en users.usernameTaken');
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
