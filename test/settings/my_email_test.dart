// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  Future<FakeApi> openSettings(WidgetTester tester, {String email = 'owner@example.com', Locale locale = const Locale('en')}) async {
    final api = FakeApi()..email = email;
    await pumpRedix(tester, api, stored: {'session': keptSession}, locale: locale);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.sharedSettingsKey)));
    await tester.ensureVisible(find.byKey(SharedSettingsScreen.myEmailKey));
    return api;
  }

  Future<void> askCode(WidgetTester tester, FakeApi api, String email) async {
    await act(tester, api, () => tester.tap(find.byKey(SharedSettingsScreen.myEmailKey)));
    await act(tester, api, () async {
      await tester.enterText(find.byKey(SharedSettingsScreen.myEmailFieldKey), email);
      await tester.tap(find.byKey(ChangeDialog.saveKey));
    });
  }

  Future<void> enterCode(WidgetTester tester, FakeApi api, String code) => act(tester, api, () async {
    await tester.enterText(find.byKey(SharedSettingsScreen.myEmailCodeKey), code);
    await tester.tap(find.byKey(ChangeDialog.saveKey));
  });

  testWidgets('redix-api #127 AC-10.4: «بريدي» shows the email the session says', (tester) async {
    await openSettings(tester);

    expect(text(tester, SharedSettingsScreen.myEmailKey.title), 'en settings.myEmail');
    expect(text(tester, SharedSettingsScreen.myEmailKey.subtitle), 'owner@example.com');
  });

  testWidgets('redix-api #127 AC-10.4, AC-02.10: a new address is sent a code in the phone\'s language, the code makes it the email, and Settings shows it', (tester) async {
    final api = await openSettings(tester, locale: const Locale('ar'));

    await askCode(tester, api, ' owner@redix.sa ');
    final (askPath, asked, language) = api.sentCodeRequests.single;
    expect([askPath, asked, language], ['/me/email', {'email': 'owner@redix.sa'}, 'ar']);
    expect(text(tester, SharedSettingsScreen.myEmailSentToKey), 'ar settings.emailConfirm owner@redix.sa');
    expect(text(tester, SharedSettingsScreen.myEmailKey.subtitle), 'owner@example.com', reason: 'the old address holds until the code is entered');

    await enterCode(tester, api, ' 482913 ');

    final (confirmPath, confirmed, _) = api.sentCodeRequests.last;
    expect([confirmPath, confirmed], ['/me/email/confirm', {'code': '482913'}]);
    expect(find.byKey(SharedSettingsScreen.myEmailCodeKey), findsNothing);
    expect(text(tester, SharedSettingsScreen.myEmailKey.subtitle), 'owner@redix.sa');
  });

  testWidgets('redix-api #127 AC-10.4: a wrong code stays in the dialog saying so, and the old address stays', (tester) async {
    final api = await openSettings(tester);
    api.codeAnswers['/me/email/confirm'] = (status: 400, code: 'codeWrong');
    await askCode(tester, api, 'owner@redix.sa');

    await enterCode(tester, api, '000000');

    expect(text(tester, ChangeDialog.messageKey), 'en auth.codeWrong');
    expect(find.byKey(SharedSettingsScreen.myEmailCodeKey), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.cancelKey)));
    expect(text(tester, SharedSettingsScreen.myEmailKey.subtitle), 'owner@example.com');
  });

  testWidgets('redix-api #127: a lost network says the same word in both steps', (tester) async {
    final api = await openSettings(tester);
    api.unreachable.add('/me/email');
    await askCode(tester, api, 'owner@redix.sa');
    final asking = text(tester, ChangeDialog.messageKey);
    api.unreachable.clear();
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));
    api.unreachable.add('/me/email/confirm');

    await enterCode(tester, api, '482913');

    expect([asking, text(tester, ChangeDialog.messageKey)], ['en users.noConnection', 'en users.noConnection']);
  });

  testWidgets('redix-api #127 R9: an address another account holds is refused in the first step, and no code is asked', (tester) async {
    final api = await openSettings(tester);
    api.codeAnswers['/me/email'] = (status: 409, code: 'emailTaken');

    await askCode(tester, api, 'taken@example.com');

    expect(text(tester, ChangeDialog.messageKey), 'en users.emailTaken');
    expect(find.byKey(SharedSettingsScreen.myEmailFieldKey), findsOneWidget);
    expect(find.byKey(SharedSettingsScreen.myEmailCodeKey), findsNothing);
  });

  testWidgets('redix-api #127 D4: asking too often says so, and an address the confirmation finds taken says that', (tester) async {
    final api = await openSettings(tester);
    api.codeAnswers['/me/email'] = (status: 429, code: '');

    await askCode(tester, api, 'owner@redix.sa');
    expect(text(tester, ChangeDialog.messageKey), 'en auth.tooManyRequests');

    api.codeAnswers['/me/email'] = (status: 202, code: '');
    api.codeAnswers['/me/email/confirm'] = (status: 409, code: 'emailTaken');
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));
    await enterCode(tester, api, '482913');
    expect(text(tester, ChangeDialog.messageKey), 'en users.emailTaken');
  });

  testWidgets('redix-api #127: someone with no email yet sees «بريدي» empty, and the field starts empty', (tester) async {
    final api = await openSettings(tester, email: '');

    expect(text(tester, SharedSettingsScreen.myEmailKey.subtitle), '');
    await act(tester, api, () => tester.tap(find.byKey(SharedSettingsScreen.myEmailKey)));
    expect(tester.widget<TextField>(find.byKey(SharedSettingsScreen.myEmailFieldKey)).controller!.text, '');
  });
}
