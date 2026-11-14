import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/launcher/launcher_add_entry.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/words/no_words_screen.dart';

import '../app_harness.dart';
import 'fake_launcher.dart';

/// «إضافة قيد» on the icon's menu and the home-screen widget (redix-app #86).
void main() {
  const keptWithDefault = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false, "defaultProjectId": "project-0"}';

  FakeApi apiWithDefault() => FakeApi()
    ..defaultProjectId = 'project-0'
    ..addProject('غصون 6', permissions: field);

  group('the words', () {
    for (final language in ['ar', 'en']) {
      testWidgets('redix-app #86 R1, AC-86.4: in $language, the icon\'s menu holds «إضافة قيد» alone and the widget\'s button says it, both the app\'s word', (tester) async {
        final launcher = FakeLauncher();
        await pumpRedix(tester, apiWithDefault(), stored: {'session': keptWithDefault}, locale: Locale(language));

        expect(launcher.shortcuts.single['localizedTitle'], '$language entries.new');
        expect(launcher.saved[LauncherAddEntry.widgetLabel], '$language entries.new');
        expect(launcher.saved[LauncherAddEntry.widgetLink], 'https://redix.test${LauncherAddEntry.path}');
        expect(launcher.updated.last, 'sa.redix.AddEntryWidget');
      });
    }

    testWidgets('redix-app #86 R5: a first start with no network and no words writes nothing on the icon\'s menu or the widget', (tester) async {
      final launcher = FakeLauncher();
      await pumpRedix(tester, FakeApi()..online = false);

      expect(find.byType(NoWordsScreen), findsOneWidget);
      expect(launcher.shortcuts, isEmpty);
      expect(launcher.saved, isEmpty);
    });
  });

  group('the icon\'s menu', () {
    testWidgets('redix-app #86 AC-86.1: tapping «إضافة قيد» on the icon\'s menu opens Add entry in the default project', (tester) async {
      final launcher = FakeLauncher();
      final api = apiWithDefault();
      await pumpRedix(tester, api, stored: {'session': keptWithDefault});
      expect(find.byKey(AddEntryScreen.tableKey), findsNothing);

      await act(tester, api, () => launcher.tapShortcut(launcher.shortcuts.single['type']! as String));

      expect(find.byKey(AddEntryScreen.tableKey), findsOneWidget);
    });

    testWidgets('redix-app #86 AC-86.1: started by «إضافة قيد» on the icon\'s menu, the app opens on Add entry in the default project', (tester) async {
      FakeLauncher(startedFrom: 'addEntry');
      await pumpRedix(tester, apiWithDefault(), stored: {'session': keptWithDefault});
      expect(find.byKey(AddEntryScreen.tableKey), findsOneWidget);
    });

    testWidgets('redix-app #86 AC-86.1: started from the icon itself, the app opens on the home, not on Add entry', (tester) async {
      FakeLauncher();
      await pumpRedix(tester, apiWithDefault(), stored: {'session': keptWithDefault});
      expect(find.byKey(HomeScreen.titleKey), findsOneWidget);
      expect(find.byKey(AddEntryScreen.tableKey), findsNothing);
    });
  });

  group('signing out', () {
    testWidgets('redix-app #86 R10, AC-86.8: signing out empties the widget\'s rows and when they were read', (tester) async {
      final launcher = FakeLauncher();
      final api = apiWithDefault();
      await pumpRedix(tester, api, stored: {'session': keptWithDefault});
      await openSettings(tester, api);

      await scrollAndTap(tester, api, SharedSettingsScreen.signOutKey);
      await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

      expect(launcher.saved[LauncherAddEntry.widgetEntries], '[]');
      expect(launcher.saved[LauncherAddEntry.widgetReadAt], '');
    });

    testWidgets('redix-app #86 R10: a renewal of the session, coming back to the app, empties nothing', (tester) async {
      final launcher = FakeLauncher();
      final api = apiWithDefault();
      await pumpRedix(tester, api, stored: {'session': keptWithDefault});
      launcher.saved.clear();

      await sendToBackground(tester, api);
      await bringBack(tester, api);

      expect(launcher.saved[LauncherAddEntry.widgetEntries], isNot('[]'));
    });
  });
}
