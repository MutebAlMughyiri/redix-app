import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/users/users_screen.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Future<FakeApi> openProjectUsers(WidgetTester tester) async {
    final api = FakeApi()..addProject('غصون 6');
    final manager = api.addUser('متعب', username: 'muteb');
    final field = api.addUser('نواف', username: 'nawaf', mobile: '0500000000');
    final disabled = api.addUser('سالم', username: 'salem', isActive: false);
    api
      ..giveRole(manager, 'project-0', 'role-manager')
      ..giveRole(manager, 'project-0', 'role-finance')
      ..giveRole(field, 'project-0', 'role-field')
      ..giveRole(disabled, 'project-0', 'role-reader');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.usersKey('project-0'))));
    return api;
  }

  Future<void> choose(WidgetTester tester, FakeApi api, String userId, Key item) async {
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey(userId))));
    await act(tester, api, () => tester.tap(find.byKey(item)));
  }

  testWidgets('a row shows the name, username and mobile; the username alone when there is no mobile', (tester) async {
    await openProjectUsers(tester);

    expect(text(tester, UsersScreen.nameKey('user-1')), 'نواف');
    expect(text(tester, UsersScreen.detailsKey('user-1')), 'nawaf · 0500000000');
    expect(text(tester, UsersScreen.detailsKey('user-0')), 'muteb');
  });

  testWidgets('the title names the project, and a row in it shows the roles alone', (tester) async {
    await openProjectUsers(tester);

    expect(find.text('en users.title · غصون 6'), findsOneWidget);
    expect(text(tester, UsersScreen.rolesLineKey('user-0')), 'en users.roleManager · en users.roleFinance');
    expect(text(tester, UsersScreen.rolesLineKey('user-1')), 'en users.roleField');
  });

  testWidgets('every row has the whole menu, a manager included', (tester) async {
    final api = await openProjectUsers(tester);

    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-0'))));

    expect(find.byKey(UsersScreen.editKey), findsOneWidget);
    expect(find.byKey(UsersScreen.rolesKey), findsOneWidget);
    expect(find.byKey(UsersScreen.resetPasswordKey), findsOneWidget);
    expect(find.byKey(UsersScreen.disableKey), findsOneWidget);
    expect(find.byKey(UsersScreen.enableKey), findsNothing);
  });

  testWidgets('an active user has no badge, and a disabled one offers Enable', (tester) async {
    final api = await openProjectUsers(tester);

    expect(find.byKey(UsersScreen.statusKey('user-1')), findsNothing);
    expect(find.descendant(of: find.byKey(UsersScreen.statusKey('user-2')), matching: find.text('en users.disabled')), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-2'))));
    expect(find.byKey(UsersScreen.enableKey), findsOneWidget);
    expect(find.byKey(UsersScreen.disableKey), findsNothing);
  });

  testWidgets('disabling asks first, says what it means, and Cancel changes nothing', (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.disableKey);
    expect(text(tester, UsersScreen.disableNameKey), 'نواف');
    expect(text(tester, UsersScreen.disableExplainKey), 'en users.disableExplain');
    expect(api.sentUserChanges, isEmpty);

    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.cancelDisableKey)));
    expect(api.sentUserChanges, isEmpty);
    expect(find.byKey(UsersScreen.statusKey('user-1')), findsNothing);
  });

  testWidgets('a disabled user stays listed with the Disabled badge, and Enable brings them back', (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.disableKey);
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.confirmDisableKey)));
    expect(api.sentUserChanges.single.$1, '/users/user-1/disable');
    expect(find.descendant(of: find.byKey(UsersScreen.statusKey('user-1')), matching: find.text('en users.disabled')), findsOneWidget);

    await choose(tester, api, 'user-1', UsersScreen.enableKey);
    expect(api.sentUserChanges.last.$1, '/users/user-1/enable');
    expect(find.byKey(UsersScreen.statusKey('user-1')), findsNothing);
  });

  testWidgets("a refused disable shows its word in a SnackBar: the last manager, or someone also in another project", (tester) async {
    final api = await openProjectUsers(tester);
    await choose(tester, api, 'user-1', UsersScreen.disableKey);

    api.userAnswer = (status: 409, code: 'lastManager');
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.confirmDisableKey)));
    expect(find.text('en users.lastManager'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 5));
    await choose(tester, api, 'user-1', UsersScreen.disableKey);
    api.userAnswer = (status: 403, code: 'otherProject');
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.confirmDisableKey)));
    expect(find.text('en users.otherProject'), findsOneWidget);
  });

  testWidgets('Edit sends a mobile typed in Arabic digits in Western digits', (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.editKey);
    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.editMobileKey), '٠٥٠٠٠٠٠٠٠١');
      await tester.tap(find.byKey(UsersScreen.saveKey));
    });

    expect(api.sentUserChanges.single.$2['mobile'], '0500000001');
  });

  testWidgets('Edit starts from the current name and mobile, and the row shows the change', (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.editKey);
    expect(tester.widget<TextField>(find.byKey(UsersScreen.editNameKey)).controller!.text, 'نواف');
    expect(tester.widget<TextField>(find.byKey(UsersScreen.editMobileKey)).controller!.text, '0500000000');

    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.editNameKey), 'نواف الأول');
      await tester.tap(find.byKey(UsersScreen.saveKey));
    });

    expect(find.byKey(UsersScreen.saveKey), findsNothing);
    expect(api.sentUserChanges.single.$2, {'displayName': 'نواف الأول', 'mobile': '0500000000'});
    expect(text(tester, UsersScreen.nameKey('user-1')), 'نواف الأول');
  });

  testWidgets('a refused edit stays in the dialog with what was typed', (tester) async {
    final api = await openProjectUsers(tester);
    await choose(tester, api, 'user-1', UsersScreen.editKey);

    api.userAnswer = (status: 400, code: 'invalidName');
    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.editNameKey), ' ');
      await tester.tap(find.byKey(UsersScreen.saveKey));
    });

    expect(text(tester, UsersScreen.dialogMessageKey), 'en users.invalidName');
    expect(tester.widget<TextField>(find.byKey(UsersScreen.editNameKey)).controller!.text, ' ');
  });

  testWidgets('Reset password names the user, says what it means, and sends the temporary password', (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.resetPasswordKey);
    expect(text(tester, UsersScreen.resetNameKey), 'نواف');
    expect(text(tester, UsersScreen.resetExplainKey), 'en users.resetExplain');

    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.resetPasswordFieldKey), 'Temporary-2');
      await tester.tap(find.byKey(UsersScreen.saveKey));
    });

    expect(find.byKey(UsersScreen.saveKey), findsNothing);
    final (path, body) = api.sentUserChanges.single;
    expect(path, '/users/user-1/reset-password');
    expect(body, {'temporaryPassword': 'Temporary-2'});
  });

  testWidgets('an existing user is added by their username', (tester) async {
    final api = await openProjectUsers(tester);
    api.addUser('ريم', username: 'reem');

    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.addExistingKey)));
    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.existingUsernameKey), 'reem');
      await tester.tap(find.byKey(UsersScreen.saveKey));
    });

    expect(api.sentUserChanges.single.$1, '/projects/project-0/users/existing');
    expect(api.sentUserChanges.single.$2, {'username': 'reem'});
    expect(find.byKey(UsersScreen.saveKey), findsNothing);
    expect(text(tester, UsersScreen.rolesLineKey('user-3')), 'en users.roleReader');
  });

  testWidgets('an unknown username stays in the dialog and says so', (tester) async {
    final api = await openProjectUsers(tester);
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.addExistingKey)));

    api.userAnswer = (status: 404, code: 'unknownUser');
    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.existingUsernameKey), 'nobody');
      await tester.tap(find.byKey(UsersScreen.saveKey));
    });

    expect(text(tester, UsersScreen.dialogMessageKey), 'en users.unknownUser');
  });

  testWidgets('without a network the list says so, and Try again reads it', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    api.giveRole(api.addUser('متعب', username: 'muteb'), 'project-0', 'role-manager');
    await pumpRedix(tester, api, stored: {'session': keptSession});

    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.usersKey('project-0'))));
    expect(text(tester, UsersScreen.messageKey), 'en users.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.retryKey)));
    expect(find.byKey(UsersScreen.rowKey('user-0')), findsOneWidget);
  });
}
