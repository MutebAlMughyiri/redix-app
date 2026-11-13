import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/users/users_screen.dart';
import 'package:redix/home/home_screen.dart';

import '../app_harness.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/messages.dart';
import 'package:redix/ui/part_keys.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Future<FakeApi> openProjectUsers(WidgetTester tester) async {
    final api = FakeApi()..addProject('غصون 6');
    final manager = api.addUser('متعب', username: 'muteb');
    final nawaf = api.addUser('نواف', username: 'nawaf', mobile: '0500000000');
    final disabled = api.addUser('سالم', username: 'salem');
    api
      ..give(manager, 'project-0', managerAndFinance)
      ..give(nawaf, 'project-0', field)
      ..give(disabled, 'project-0', reader)
      ..makeUserInactive(disabled, 'project-0');
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.usersKey('project-0'));
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

    expect(find.text('en users.title'), findsOneWidget);
    expect(find.text('غصون 6'), findsOneWidget);
    expect(text(tester, UsersScreen.permissionsLineKey('user-0')), 'en permissions.count');
    expect(text(tester, UsersScreen.permissionsLineKey('user-1')), 'en permissions.count');
  });

  testWidgets('every row has the whole menu, a manager included', (tester) async {
    final api = await openProjectUsers(tester);

    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-0'))));

    expect(find.byKey(UsersScreen.editKey), findsOneWidget);
    expect(find.byKey(UsersScreen.permissionsKey), findsOneWidget);
    expect(find.byKey(UsersScreen.resetPasswordKey), findsOneWidget);
    expect(find.byKey(UsersScreen.disableKey), findsOneWidget);
    expect(find.byKey(UsersScreen.enableKey), findsNothing);
  });

  testWidgets('redix-api #126 D1: a person active in this project has no badge; one inactive in it shows «معطّل» and offers Enable', (tester) async {
    final api = await openProjectUsers(tester);

    expect(find.byKey(UsersScreen.statusKey('user-1')), findsNothing);
    expect(text(tester, UsersScreen.statusKey('user-2').label), 'en users.disabled');

    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-2'))));
    expect(find.byKey(UsersScreen.enableKey), findsOneWidget);
    expect(find.byKey(UsersScreen.disableKey), findsNothing);
  });

  testWidgets('disabling asks first, says what it means, and Cancel changes nothing', (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.disableKey);
    expect(text(tester, ConfirmDialog.subjectKey), 'نواف');
    expect(text(tester, ConfirmDialog.explanationKey), 'en users.disableExplain');
    expect(api.sentUserChanges, isEmpty);

    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.cancelKey)));
    expect(api.sentUserChanges, isEmpty);
    expect(find.byKey(UsersScreen.statusKey('user-1')), findsNothing);
  });

  testWidgets("redix-api #126 D1: Disable makes a person inactive through this project's route, listed with «معطّل», and Enable makes them active again through its own", (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.disableKey);
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));
    expect(api.sentUserChanges.single.$1, '/projects/project-0/users/user-1/disable');
    expect(text(tester, UsersScreen.statusKey('user-1').label), 'en users.disabled');

    await choose(tester, api, 'user-1', UsersScreen.enableKey);
    expect(api.sentUserChanges.last.$1, '/projects/project-0/users/user-1/enable');
    expect(find.byKey(UsersScreen.statusKey('user-1')), findsNothing);
  });

  testWidgets('redix-api #126 D1: a person inactive in another project shows active in this one, and offers Disable', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..addProject('غصون 7');
    final manager = api.addUser('متعب', username: 'muteb');
    final nawaf = api.addUser('نواف', username: 'nawaf');
    api
      ..give(manager, 'project-0', managerAndFinance)
      ..give(nawaf, 'project-0', field)
      ..give(nawaf, 'project-1', field)
      ..makeUserInactive(nawaf, 'project-1');
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.usersKey('project-0'));

    expect(find.byKey(UsersScreen.statusKey('user-1')), findsNothing);
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
    expect(find.byKey(UsersScreen.disableKey), findsOneWidget);
    expect(find.byKey(UsersScreen.enableKey), findsNothing);
  });

  testWidgets('redix-api #126 R8: making the last manager inactive is refused with its word in a SnackBar, and they stay active', (tester) async {
    final api = await openProjectUsers(tester);
    await choose(tester, api, 'user-0', UsersScreen.disableKey);

    api.userAnswer = (status: 409, code: 'lastManager');
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(text(tester, messageKeyOf('users.lastManager').label), 'en users.lastManager');
    expect(find.byKey(UsersScreen.statusKey('user-0')), findsNothing);
  });

  testWidgets('Edit sends a mobile typed in Arabic digits in Western digits', (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.editKey);
    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.editMobileKey), '٠٥٠٠٠٠٠٠٠١');
      await tester.tap(find.byKey(ChangeDialog.saveKey));
    });

    expect(api.sentUserChanges.first.$2['mobile'], '0500000001');
  });

  testWidgets('Edit starts from the current name and mobile, and the row shows the change', (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.editKey);
    expect(tester.widget<TextField>(find.byKey(UsersScreen.editNameKey)).controller!.text, 'نواف');
    expect(tester.widget<TextField>(find.byKey(UsersScreen.editMobileKey)).controller!.text, '0500000000');

    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.editNameKey), 'نواف الأول');
      await tester.tap(find.byKey(ChangeDialog.saveKey));
    });

    expect(find.byKey(ChangeDialog.saveKey), findsNothing);
    expect(api.sentUserChanges.first.$2, {'displayName': 'نواف الأول', 'mobile': '0500000000'});
    expect(text(tester, UsersScreen.nameKey('user-1')), 'نواف الأول');
  });

  testWidgets('Muteb, 9 Nov 2026: Edit holds the role name in this project, starting from it, sends it alone to the project when the name and mobile stay as they were, so someone also in another project can still be named, and the row shows it beside the username', (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.editKey);
    expect(tester.widget<TextField>(find.byKey(UsersScreen.editRoleNameKey)).controller!.text, '');
    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.editRoleNameKey), 'مشرف مالي');
      await tester.tap(find.byKey(ChangeDialog.saveKey));
    });

    final (path, body) = api.sentUserChanges.single;
    expect((path, body['roleName']), ('PUT /projects/project-0/users/user-1/role-name', 'مشرف مالي'));
    expect(text(tester, UsersScreen.detailsKey('user-1')), 'nawaf · مشرف مالي · 0500000000');

    await choose(tester, api, 'user-1', UsersScreen.editKey);
    expect(tester.widget<TextField>(find.byKey(UsersScreen.editRoleNameKey)).controller!.text, 'مشرف مالي');
  });

  testWidgets('a refused edit stays in the dialog with what was typed', (tester) async {
    final api = await openProjectUsers(tester);
    await choose(tester, api, 'user-1', UsersScreen.editKey);

    api.userAnswer = (status: 400, code: 'invalidName');
    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.editNameKey), ' ');
      await tester.tap(find.byKey(ChangeDialog.saveKey));
    });

    expect(text(tester, ChangeDialog.messageKey), 'en users.invalidName');
    expect(tester.widget<TextField>(find.byKey(UsersScreen.editNameKey)).controller!.text, ' ');
  });

  testWidgets('Reset password names the user, says what it means, and sends the temporary password', (tester) async {
    final api = await openProjectUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.resetPasswordKey);
    expect(text(tester, UsersScreen.resetNameKey), 'نواف');
    expect(text(tester, UsersScreen.resetExplainKey), 'en users.resetExplain');
    expect(tester.widget<TextField>(find.byKey(UsersScreen.resetPasswordFieldKey)).decoration!.helperText, 'en common.passwordRules', reason: 'redix-api #113');

    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.resetPasswordFieldKey), 'Temporary-2');
      await tester.tap(find.byKey(ChangeDialog.saveKey));
    });

    expect(find.byKey(ChangeDialog.saveKey), findsNothing);
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
      await tester.tap(find.byKey(ChangeDialog.saveKey));
    });

    expect(api.sentUserChanges.single.$1, '/projects/project-0/users/existing');
    expect(api.sentUserChanges.single.$2, {'username': 'reem'});
    expect(find.byKey(ChangeDialog.saveKey), findsNothing);
    expect(text(tester, UsersScreen.permissionsLineKey('user-3')), 'en permissions.count');
    expect(api.users.last['projects'], [{'projectId': 'project-0', 'name': 'غصون 6', 'isInactive': false, 'permissions': ['readProject'], 'partnerIds': <String>[]}]);
  });

  testWidgets('an unknown username stays in the dialog and says so', (tester) async {
    final api = await openProjectUsers(tester);
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.addExistingKey)));

    api.userAnswer = (status: 404, code: 'unknownUser');
    await act(tester, api, () async {
      await tester.enterText(find.byKey(UsersScreen.existingUsernameKey), 'nobody');
      await tester.tap(find.byKey(ChangeDialog.saveKey));
    });

    expect(text(tester, ChangeDialog.messageKey), 'en users.unknownUser');
  });

  testWidgets('without a network the list says so, and Try again reads it', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    api.give(api.addUser('متعب', username: 'muteb'), 'project-0', const ['manageUsers', 'readProject', 'seeAllCapital']);
    await openProject(tester, api);
    api.online = false;
    await scrollAndTap(tester, api, HomeScreen.usersKey('project-0'));
    expect(text(tester, ApiListBody.messageKey), 'en users.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(ApiListBody.retryKey)));
    expect(find.byKey(UsersScreen.rowKey('user-0')), findsOneWidget);
  });
}
