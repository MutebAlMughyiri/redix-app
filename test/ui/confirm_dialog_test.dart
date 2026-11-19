// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/app_color.dart';
import 'package:redix/ui/confirm_dialog.dart';

import '../app_harness.dart';

/// The color the open question's button is filled with; none of its own when it takes the theme's.
Color? _filledWith(WidgetTester tester) => tester.widget<FilledButton>(find.byKey(ConfirmDialog.confirmKey)).style?.backgroundColor?.resolve({});

void main() {
  testWidgets('findings row 276: closing a project, which destroys, asks with a red button', (tester) async {
    final api = FakeApi()..addProject('مشروع A', permissions: ['readProject', 'manageProject']);
    await openProject(tester, api);
    await scrollAndTap(tester, api, HomeScreen.projectInfoKey('project-0'));

    await scrollAndTap(tester, api, ProjectInfoScreen.closeKey);

    expect(_filledWith(tester), AppColor.refusal.of(tester.element(find.byKey(ConfirmDialog.dialogKey))));
  });

  testWidgets('findings row 276: signing out, which destroys nothing, asks with the theme\'s own button', (tester) async {
    final api = FakeApi()..addProject('مشروع A');
    await openProject(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.sharedSettingsKey('project-0'))));
    await tester.ensureVisible(find.byKey(SharedSettingsScreen.signOutKey));
    await tester.pumpAndSettle();

    await act(tester, api, () => tester.tap(find.byKey(SharedSettingsScreen.signOutKey)));

    expect(_filledWith(tester), isNull);
  });
}
