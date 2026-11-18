// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/api.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/legal/legal_page.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../app_harness.dart';

/// The phone's browser, which keeps what it was asked to open.
class FakeBrowser extends UrlLauncherPlatform {
  final opened = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add('$url ${options.mode.name}');
    return true;
  }
}

void main() {
  late FakeBrowser browser;

  setUp(() => UrlLauncherPlatform.instance = browser = FakeBrowser());

  Future<FakeApi> openSettingsSignedIn(WidgetTester tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.sharedSettingsKey)));
    return api;
  }

  testWidgets('R7: Settings opens the privacy policy and the terms in the phone\'s browser, from the API that serves them', (tester) async {
    final api = await openSettingsSignedIn(tester);

    expect(find.byKey(LegalPage.privacy.key.title), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(LegalPage.privacy.key.title)).data, 'en legal.privacy');
    await scrollAndTap(tester, api, LegalPage.privacy.key);
    await scrollAndTap(tester, api, LegalPage.terms.key);

    expect(browser.opened, ['$apiBaseUrl/privacy externalApplication', '$apiBaseUrl/terms externalApplication']);
  });

  testWidgets('R8: Settings opens Flutter\'s own page of the licences of the packages the app ships', (tester) async {
    final api = await openSettingsSignedIn(tester);

    await scrollAndTap(tester, api, SharedSettingsScreen.licensesKey);
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('R7: registering shows what it agrees to, with a link to each page, before an account is made', (tester) async {
    tester.view.physicalSize = const Size(2400, 7200);
    addTearDown(tester.view.reset);
    final api = FakeApi();
    await pumpRedix(tester, api);
    await tester.ensureVisible(find.byKey(SignInScreen.registerKey));
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.registerKey)));

    expect(tester.widget<Text>(find.byKey(LegalAgreement.sentenceKey)).data, 'en legal.agreement');
    await tester.ensureVisible(find.byKey(LegalPage.terms.key));
    await act(tester, api, () => tester.tap(find.byKey(LegalPage.terms.key)));

    expect(browser.opened, ['$apiBaseUrl/terms externalApplication']);
  });

  testWidgets('a signed-in person making a project agreed when registering, and is not asked again', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.newProjectKey)));

    expect(find.byKey(LegalAgreement.sentenceKey), findsNothing);
  });
}
