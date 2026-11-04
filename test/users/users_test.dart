import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/users/users_screen.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Future<FakeApi> openUsers(WidgetTester tester) async {
    final api = FakeApi()..isOwner = true;
    api
      ..addUser('متعب', username: 'muteb', isOwner: true)
      ..addUser('نواف', username: 'nawaf', mobile: '0500000000')
      ..addUser('سالم', username: 'salem', isActive: false);
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.usersKey)));
    return api;
  }

  Future<void> choose(WidgetTester tester, FakeApi api, String userId, Key item) async {
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey(userId))));
    await act(tester, api, () => tester.tap(find.byKey(item)));
  }

  testWidgets('a row shows the name, username and mobile; the username alone when there is no mobile', (tester) async {
    await openUsers(tester);

    expect(text(tester, UsersScreen.nameKey('user-1')), 'نواف');
    expect(text(tester, UsersScreen.detailsKey('user-1')), 'nawaf · 0500000000');
    expect(text(tester, UsersScreen.detailsKey('user-0')), 'muteb');
  });

  testWidgets("an owner's row has the Owner badge and offers Edit only", (tester) async {
    final api = await openUsers(tester);

    expect(find.descendant(of: find.byKey(UsersScreen.statusKey('user-0')), matching: find.text('en users.owner')), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-0'))));
    expect(find.byKey(UsersScreen.editKey), findsOneWidget);
    expect(find.byKey(UsersScreen.resetPasswordKey), findsNothing);
    expect(find.byKey(UsersScreen.disableKey), findsNothing);
    expect(find.byKey(UsersScreen.enableKey), findsNothing);
  });

  testWidgets('an active user has no badge and offers Edit, Reset password and Disable', (tester) async {
    final api = await openUsers(tester);

    expect(find.byKey(UsersScreen.statusKey('user-1')), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
    expect(find.byKey(UsersScreen.editKey), findsOneWidget);
    expect(find.byKey(UsersScreen.resetPasswordKey), findsOneWidget);
    expect(find.byKey(UsersScreen.disableKey), findsOneWidget);
    expect(find.byKey(UsersScreen.enableKey), findsNothing);
  });

  testWidgets('disabling asks first, says what it means, and Cancel changes nothing', (tester) async {
    final api = await openUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.disableKey);
    expect(text(tester, UsersScreen.disableNameKey), 'نواف');
    expect(text(tester, UsersScreen.disableExplainKey), 'en users.disableExplain');
    expect(api.sentUserChanges, isEmpty);

    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.cancelDisableKey)));
    expect(api.sentUserChanges, isEmpty);
    expect(find.byKey(UsersScreen.statusKey('user-1')), findsNothing);
  });

  testWidgets('a disabled user stays listed with the Disabled badge, and Enable brings them back', (tester) async {
    final api = await openUsers(tester);

    await choose(tester, api, 'user-1', UsersScreen.disableKey);
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.confirmDisableKey)));
    expect(api.sentUserChanges.single.$1, '/users/user-1/disable');
    expect(find.descendant(of: find.byKey(UsersScreen.statusKey('user-1')), matching: find.text('en users.disabled')), findsOneWidget);

    await choose(tester, api, 'user-1', UsersScreen.enableKey);
    expect(api.sentUserChanges.last.$1, '/users/user-1/enable');
    expect(find.byKey(UsersScreen.statusKey('user-1')), findsNothing);
  });

  testWidgets('a refused disable shows its word in a SnackBar', (tester) async {
    final api = await openUsers(tester);
    await choose(tester, api, 'user-1', UsersScreen.disableKey);

    api.userAnswer = (status: 409, code: 'ownerCannotBeDisabled');
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.confirmDisableKey)));

    expect(find.text('en users.ownerCannotBeDisabled'), findsOneWidget);
  });

  testWidgets('Edit starts from the current name and mobile, and the row shows the change', (tester) async {
    final api = await openUsers(tester);

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
    final api = await openUsers(tester);
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
    final api = await openUsers(tester);

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

  testWidgets('without a network the list says so, and Try again reads it', (tester) async {
    final api = FakeApi()..isOwner = true;
    api.addUser('متعب', username: 'muteb', isOwner: true);
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));

    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.usersKey)));
    expect(text(tester, UsersScreen.messageKey), 'en users.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(UsersScreen.retryKey)));
    expect(find.byKey(UsersScreen.rowKey('user-0')), findsOneWidget);
  });
}
