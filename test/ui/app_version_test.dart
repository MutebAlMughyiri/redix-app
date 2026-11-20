// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/app_version.dart';

import '../app_harness.dart';

/// The word before the version, then the version's three numbers and nothing after them: never the build number (redix-app #124 R3, R4).
final versionLine = matches(RegExp(r'^en app\.version \d+\.\d+\.\d+$'));

void main() {
  testWidgets('R1: the sign-in screen shows the installed version at its foot', (tester) async {
    await pumpRedix(tester, FakeApi());

    expect(tester.widget<Text>(find.byKey(AppVersion.lineKey)).data, versionLine);
  });

  testWidgets('R2: Shared settings shows the installed version below Sign out', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.sharedSettingsKey)));
    await bringIntoView(tester, find.byKey(AppVersion.lineKey));

    expect(tester.widget<Text>(find.byKey(AppVersion.lineKey)).data, versionLine);
    expect(tester.getTopLeft(find.byKey(AppVersion.lineKey)).dy, greaterThan(tester.getTopLeft(find.byKey(SharedSettingsScreen.signOutKey)).dy));
  });
}
