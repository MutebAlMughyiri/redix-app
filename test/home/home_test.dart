import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/name_dialog.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  String status(WidgetTester tester, String id) =>
      tester.widget<Text>(find.descendant(of: find.byKey(HomeScreen.statusKey(id)), matching: find.byType(Text))).data!;

  /// Signs in with the kept session, and opens the first project from the list.
  Future<void> tapClose(WidgetTester tester, FakeApi api) async {
    await tester.ensureVisible(find.byKey(HomeScreen.closeKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.closeKey('project-0'))));
  }

  Future<void> openHome(WidgetTester tester, FakeApi api) async {
    await openProject(tester, api);
  }

  const keptDirect = '{"accessToken": "kept-access", "refreshToken": "kept-refresh", "mustChangePassword": false, "defaultProjectId": "project-0", "openDefaultProject": true}';

  testWidgets('a card opens its home, whose title names it, and back returns to the list', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openHome(tester, api);

    expect(text(tester, HomeScreen.titleKey), 'غصون 6');

    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('the buttons follow the permissions in the open project', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6')
      ..addProject('غصون 7', permissions: ['readProject']);
    await openHome(tester, api);
    expect(find.byKey(HomeScreen.closeKey('project-0')), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-1'))));

    expect(find.byKey(HomeScreen.closeKey('project-1')), findsNothing);
    expect(find.byKey(HomeScreen.addUnitKey('project-1')), findsNothing);
    expect(find.byKey(HomeScreen.usersKey('project-1')), findsNothing);
  });

  testWidgets('with a default and the switch on, the app opens that project at start, with no back arrow', (tester) async {
    final api = FakeApi()
      ..defaultProjectId = 'project-0'
      ..openDefaultProject = true
      ..addProject('غصون 6');

    await pumpRedix(tester, api, stored: {'session': keptDirect});

    expect(text(tester, HomeScreen.titleKey), 'غصون 6');
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('Switch project reaches the list from a project opened directly, and stays there', (tester) async {
    final api = FakeApi()
      ..defaultProjectId = 'project-0'
      ..openDefaultProject = true
      ..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptDirect});

    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.switchProjectKey)));

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
    expect(find.byKey(HomeScreen.titleKey), findsNothing);
  });

  testWidgets('a project gone while open returns to the list', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openHome(tester, api);

    api.projects.clear();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.usersKey('project-0'))));
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect(find.byKey(ProjectsScreen.titleKey), findsOneWidget);
  });

  testWidgets('with no network and nothing kept the home says so, and Try again reads it', (tester) async {
    final store = MemoryStore();
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession}, store: store);

    api.online = false;
    await store.clear('copies');
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-0'))));
    expect(text(tester, HomeScreen.messageKey), 'en projects.loadFailed');

    api.online = true;
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.retryKey)));
    expect(find.byKey(HomeScreen.cardKey('project-0')), findsOneWidget);
  });

  testWidgets('a running project shows its date, status and units in order, and offers its changes', (tester) async {
    final api = FakeApi()..addProject('غصون 6', startDate: '2026-03-01', units: ['الفلة الغربية', 'الفلة الجنوبية']);
    await openHome(tester, api);

    expect(text(tester, HomeScreen.detailsKey('project-0')), 'en projects.startDate 01.03.2026');
    expect(status(tester, 'project-0'), 'en projects.running');
    expect(text(tester, HomeScreen.unitKey('project-0-unit-0')), 'الفلة الغربية');
    expect(text(tester, HomeScreen.unitKey('project-0-unit-1')), 'الفلة الجنوبية');
    expect(
      tester.getTopLeft(find.byKey(HomeScreen.unitKey('project-0-unit-0'))).dy,
      lessThan(tester.getTopLeft(find.byKey(HomeScreen.unitKey('project-0-unit-1'))).dy),
    );
    expect(find.byKey(HomeScreen.addUnitKey('project-0')), findsOneWidget);
    expect(find.byKey(HomeScreen.closeKey('project-0')), findsOneWidget);
  });

  testWidgets('a project with no units says so', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openHome(tester, api);

    expect(text(tester, HomeScreen.noUnitsKey('project-0')), 'en projects.noUnits');
  });

  testWidgets('a finished project stays listed, read-only, and offers no change', (tester) async {
    final api = FakeApi()..addProject('غصون 5', status: 'finished', startDate: '2024-01-15', units: ['الفلة الشرقية']);
    await openHome(tester, api);

    expect(status(tester, 'project-0'), 'en projects.finished');
    expect(text(tester, HomeScreen.detailsKey('project-0')), 'en projects.startDate 15.01.2024 · en projects.readOnly');
    expect(find.byKey(HomeScreen.unitKey('project-0-unit-0')), findsOneWidget);
    expect(find.byKey(HomeScreen.addUnitKey('project-0')), findsNothing);
    expect(find.byKey(HomeScreen.closeKey('project-0')), findsNothing);
  });

  testWidgets('closing asks first, says what it means, and Cancel changes nothing', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openHome(tester, api);

    await tapClose(tester, api);
    expect(text(tester, HomeScreen.closeNameKey), 'غصون 6');
    expect(text(tester, HomeScreen.closeExplainKey), 'en projects.closeExplain');
    expect(api.sentProjectChanges, isEmpty);

    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.cancelCloseKey)));
    expect(api.sentProjectChanges, isEmpty);
    expect(status(tester, 'project-0'), 'en projects.running');
  });

  testWidgets('closing a project makes it finished, with no more changes offered', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openHome(tester, api);

    await tapClose(tester, api);
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.confirmCloseKey)));

    expect(api.sentProjectChanges.single.$1, '/projects/project-0/close');
    expect(status(tester, 'project-0'), 'en projects.finished');
    expect(find.byKey(HomeScreen.closeKey('project-0')), findsNothing);
  });

  testWidgets('closing without a network says so, and the project stays as it was', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openHome(tester, api);
    await tapClose(tester, api);

    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.confirmCloseKey)));

    expect(find.text('en projects.noConnection'), findsOneWidget);
    expect(status(tester, 'project-0'), 'en projects.running');
  });

  testWidgets('a project someone else closed shows its refusal, and the list is read again', (tester) async {
    final api = FakeApi();
    final project = api.addProject('غصون 6');
    await openHome(tester, api);
    await tapClose(tester, api);

    project['status'] = 'finished';
    api.projectAnswer = (status: 409, code: 'projectFinished');
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.confirmCloseKey)));

    expect(find.text('en projects.projectFinished'), findsOneWidget);
    expect(status(tester, 'project-0'), 'en projects.finished');
    expect(find.byKey(HomeScreen.closeKey('project-0')), findsNothing);
  });

  testWidgets('a unit name the project already has stays in the dialog with its reason (BR-37)', (tester) async {
    final api = FakeApi();
    api.addProject('غصون 6', units: ['الفلة الغربية']);
    await openHome(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.addUnitKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addUnitKey('project-0'))));

    api.projectAnswer = (status: 409, code: 'unitNameTaken');
    await tester.enterText(find.byKey(HomeScreen.unitNameKey), 'الفلة الغربية');
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.saveUnitKey)));

    expect(text(tester, HomeScreen.unitMessageKey), 'en projects.unitNameTaken');
  });

  Future<void> tapInHome(WidgetTester tester, FakeApi api, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(key)));
  }

  Future<void> chooseInUnitMenu(WidgetTester tester, FakeApi api, String unitId, Key item) async {
    await tapInHome(tester, api, HomeScreen.unitMenuKey(unitId));
    await act(tester, api, () => tester.tap(find.byKey(item)));
  }

  testWidgets('whoever manages the project renames it, starting from its name, and the title follows (BR-38)', (tester) async {
    final api = FakeApi();
    api.addProject('غصون 6');
    await openHome(tester, api);

    await tapInHome(tester, api, HomeScreen.renameKey('project-0'));
    expect(tester.widget<TextField>(find.byKey(NameDialog.nameKey)).controller!.text, 'غصون 6');
    await tester.enterText(find.byKey(NameDialog.nameKey), 'غصون السادس');
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(api.sentProjectChanges.single.$1, '/projects/project-0');
    expect(api.sentProjectChanges.single.$2['name'], 'غصون السادس');
    expect(text(tester, HomeScreen.titleKey), 'غصون السادس');
  });

  testWidgets('a unit is renamed from its menu, starting from its name (BR-38)', (tester) async {
    final api = FakeApi();
    api.addProject('غصون 6', units: ['الفلة الغربية']);
    await openHome(tester, api);

    await chooseInUnitMenu(tester, api, 'project-0-unit-0', HomeScreen.renameUnitKey);
    expect(tester.widget<TextField>(find.byKey(NameDialog.nameKey)).controller!.text, 'الفلة الغربية');
    await tester.enterText(find.byKey(NameDialog.nameKey), 'الفلة الجنوبية');
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(api.sentProjectChanges.single.$1, '/projects/project-0/units/project-0-unit-0');
    expect(api.sentProjectChanges.single.$2['name'], 'الفلة الجنوبية');
    expect(text(tester, HomeScreen.unitKey('project-0-unit-0')), 'الفلة الجنوبية');
  });

  testWidgets('a name another unit holds stays in the rename dialog with its reason (BR-37)', (tester) async {
    final api = FakeApi();
    api.addProject('غصون 6', units: ['الفلة الغربية', 'الفلة الشرقية']);
    await openHome(tester, api);
    await chooseInUnitMenu(tester, api, 'project-0-unit-0', HomeScreen.renameUnitKey);

    api.projectAnswer = (status: 409, code: 'unitNameTaken');
    await tester.enterText(find.byKey(NameDialog.nameKey), 'الفلة الشرقية');
    await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

    expect(text(tester, ChangeDialog.messageKey), 'en projects.unitNameTaken');
  });

  testWidgets('a unit is deleted from its menu only after asking, naming it (BR-38)', (tester) async {
    final api = FakeApi();
    api.addProject('غصون 6', units: ['الفلة الغربية', 'الفلة الشرقية']);
    await openHome(tester, api);

    await chooseInUnitMenu(tester, api, 'project-0-unit-0', HomeScreen.deleteUnitKey);
    expect(text(tester, ConfirmDialog.subjectKey), 'الفلة الغربية');
    expect(text(tester, ConfirmDialog.explanationKey), 'en projects.removeUnitExplain');
    expect(api.sentProjectChanges, isEmpty);
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(api.sentProjectChanges.single.$1, '/projects/project-0/units/project-0-unit-0/delete');
    expect(find.byKey(HomeScreen.unitKey('project-0-unit-0')), findsNothing);
    expect(find.byKey(HomeScreen.unitKey('project-0-unit-1')), findsOneWidget);
  });

  testWidgets('a unit that entries or contracts use stays, and the refusal says why (BR-38)', (tester) async {
    final api = FakeApi();
    api.addProject('غصون 6', units: ['الفلة الغربية']);
    await openHome(tester, api);
    await chooseInUnitMenu(tester, api, 'project-0-unit-0', HomeScreen.deleteUnitKey);

    api.projectAnswer = (status: 409, code: 'unitInUse');
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

    expect(find.text('en projects.unitInUse'), findsOneWidget);
    expect(find.byKey(HomeScreen.unitKey('project-0-unit-0')), findsOneWidget);
  });

  testWidgets('the shared unit is not on the list, so nothing offers to change it (BR-38)', (tester) async {
    final api = FakeApi();
    api.addProject('غصون 6', units: ['الفلة الغربية']);
    await openHome(tester, api);

    expect(find.text('مشترك'), findsNothing);
    expect(find.byKey(HomeScreen.unitMenuKey('project-0-unit-shared')), findsNothing);
  });

  testWidgets('without manageProject, or in a finished project, nothing offers a rename or a deletion (BR-38)', (tester) async {
    final api = FakeApi();
    api.addProject('غصون 6', units: ['الفلة الغربية'], permissions: field);
    api.addProject('غصون 5', status: 'finished', units: ['الفلة الشرقية']);
    await openHome(tester, api);

    expect(find.byKey(HomeScreen.renameKey('project-0')), findsNothing);
    expect(find.byKey(HomeScreen.unitMenuKey('project-0-unit-0')), findsNothing);

    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await tester.ensureVisible(find.byKey(ProjectsScreen.cardKey('project-1')));
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-1'))));

    expect(find.byKey(HomeScreen.renameKey('project-1')), findsNothing);
    expect(find.byKey(HomeScreen.unitMenuKey('project-1-unit-0')), findsNothing);
  });

  testWidgets('a project with entries waiting for approval stays open and says why (BR-35)', (tester) async {
    final api = FakeApi();
    api.addProject('غصون 6');
    await openHome(tester, api);
    await tapClose(tester, api);

    api.projectAnswer = (status: 409, code: 'pendingEntries');
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.confirmCloseKey)));

    expect(find.text('en projects.pendingEntries'), findsOneWidget);
    expect(status(tester, 'project-0'), 'en projects.running');
    expect(find.byKey(HomeScreen.closeKey('project-0')), findsOneWidget);
  });

  testWidgets('a refusal with no code shows the general word, never a raw key', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openHome(tester, api);
    await tapClose(tester, api);

    api.projectAnswer = (status: 403, code: '');
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.confirmCloseKey)));

    expect(find.text('en projects.refused'), findsOneWidget);
  });

  testWidgets('Add unit adds to the end of a running project', (tester) async {
    final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية']);
    await openHome(tester, api);

    await tester.ensureVisible(find.byKey(HomeScreen.addUnitKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addUnitKey('project-0'))));
    await act(tester, api, () async {
      await tester.enterText(find.byKey(HomeScreen.unitNameKey), 'الفلة الجنوبية');
      await tester.tap(find.byKey(HomeScreen.saveUnitKey));
    });

    expect(find.byKey(HomeScreen.saveUnitKey), findsNothing);
    expect(api.sentProjectChanges.single.$1, '/projects/project-0/units');
    expect(text(tester, HomeScreen.unitKey('project-0-unit-1')), 'الفلة الجنوبية');
  });

  testWidgets('a refused unit stays in the dialog with what was typed', (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await openHome(tester, api);
    await tester.ensureVisible(find.byKey(HomeScreen.addUnitKey('project-0')));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addUnitKey('project-0'))));

    api.projectAnswer = (status: 400, code: 'invalidName');
    await act(tester, api, () async {
      await tester.enterText(find.byKey(HomeScreen.unitNameKey), 'x');
      await tester.tap(find.byKey(HomeScreen.saveUnitKey));
    });

    expect(text(tester, HomeScreen.unitMessageKey), 'en projects.invalidName');
    expect(tester.widget<TextField>(find.byKey(HomeScreen.unitNameKey)).controller!.text, 'x');
  });

  testWidgets('a reader or a field supervisor sees the project and can change nothing', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject']);
    await openHome(tester, api);

    expect(find.byKey(HomeScreen.cardKey('project-0')), findsOneWidget);
    expect(find.byKey(HomeScreen.usersKey('project-0')), findsNothing);
    expect(find.byKey(HomeScreen.addUnitKey('project-0')), findsNothing);
    expect(find.byKey(HomeScreen.closeKey('project-0')), findsNothing);
  });

  testWidgets('whoever only manages users has Users, but no Add unit or Close', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['manageUsers', 'readProject', 'seeAllCapital']);
    await openHome(tester, api);

    expect(find.byKey(HomeScreen.usersKey('project-0')), findsOneWidget);
    expect(find.byKey(HomeScreen.addUnitKey('project-0')), findsNothing);
    expect(find.byKey(HomeScreen.closeKey('project-0')), findsNothing);
  });

  testWidgets('whoever manages the project but not its users has Add unit and Close, but no Users', (tester) async {
    final api = FakeApi()..addProject('غصون 6', permissions: ['readProject', 'seeAllCapital', 'manageProject']);
    await openHome(tester, api);

    expect(find.byKey(HomeScreen.usersKey('project-0')), findsNothing);
    expect(find.byKey(HomeScreen.addUnitKey('project-0')), findsOneWidget);
    expect(find.byKey(HomeScreen.closeKey('project-0')), findsOneWidget);
  });

  testWidgets('Users stays on a finished project, and the list is read again on coming back', (tester) async {
    final api = FakeApi()..addProject('غصون 6', status: 'finished', permissions: ['manageUsers', 'readProject']);
    await openHome(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(HomeScreen.usersKey('project-0'))));
    api.projects.single['permissions'] = ['readProject'];
    await act(tester, api, () => tester.tap(find.byType(BackButton)));

    expect(find.byKey(HomeScreen.usersKey('project-0')), findsNothing);
  });
}
