import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/name_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/refusal_snack_bar.dart';

import '../app_harness.dart';

/// More info (redix-api 93): the project's own record on one page in Settings, read by everyone in it, changed only by whoever manages it while it is open.
void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  String typed(WidgetTester tester, Key key) => tester.widget<TextField>(find.byKey(key)).controller!.text;

  Future<void> tap(WidgetTester tester, FakeApi api, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await act(tester, api, () => tester.tap(find.byKey(key)));
  }

  Future<void> openInfo(WidgetTester tester, FakeApi api) async {
    await openProject(tester, api);
    await openProjectInfo(tester, api);
  }

  Future<void> chooseInUnitMenu(WidgetTester tester, FakeApi api, String unitId, Key item) async {
    await tap(tester, api, ProjectInfoScreen.unitMenuKey(unitId));
    await act(tester, api, () => tester.tap(find.byKey(item)));
  }

  /// Goes back from More info and Settings to the project's home, which reads the project again.
  Future<void> backHome(WidgetTester tester, FakeApi api) async {
    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await act(tester, api, () => tester.tap(find.byType(BackButton)));
  }

  void expectNoChangeOffered() {
    for (final key in [ProjectInfoScreen.renameKey, ProjectInfoScreen.addUnitKey, ProjectInfoScreen.descriptionKey, ProjectInfoScreen.saveDescriptionKey, ProjectInfoScreen.closeKey]) {
      expect(find.byKey(key), findsNothing, reason: '$key');
    }
  }

  group('what More info shows', () {
    testWidgets('R1: the start date, status and units in order, which the home no longer shows', (tester) async {
      final api = FakeApi()..addProject('غصون 6', startDate: '2026-03-01', units: ['الفلة الغربية', 'الفلة الجنوبية']);
      await openInfo(tester, api);

      expect(text(tester, ProjectInfoScreen.nameKey), 'غصون 6');
      expect(text(tester, ProjectInfoScreen.detailsKey), 'en projects.startDate 01.03.2026');
      expect(text(tester, ProjectInfoScreen.statusKey.label), 'en projects.active');
      expect(text(tester, ProjectInfoScreen.unitKey('project-0-unit-0')), 'الفلة الغربية');
      expect(text(tester, ProjectInfoScreen.unitKey('project-0-unit-1')), 'الفلة الجنوبية');
      expect(
        tester.getTopLeft(find.byKey(ProjectInfoScreen.unitKey('project-0-unit-0'))).dy,
        lessThan(tester.getTopLeft(find.byKey(ProjectInfoScreen.unitKey('project-0-unit-1'))).dy),
      );
    });

    testWidgets('a project with no units says so', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);

      expect(text(tester, ProjectInfoScreen.noUnitsKey), 'en projects.noUnits');
    });

    testWidgets('whoever manages an open project has Rename, Add unit, a unit menu, the description and Close', (tester) async {
      final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية']);
      await openInfo(tester, api);

      for (final key in [ProjectInfoScreen.renameKey, ProjectInfoScreen.addUnitKey, ProjectInfoScreen.unitMenuKey('project-0-unit-0'), ProjectInfoScreen.descriptionKey, ProjectInfoScreen.saveDescriptionKey, ProjectInfoScreen.closeKey]) {
        expect(find.byKey(key), findsOneWidget, reason: '$key');
      }
    });

    testWidgets('R8: a reader reads the project and its description, and can change nothing', (tester) async {
      final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية'], description: 'فيلتان سكنيتان في حي النرجس.', permissions: reader);
      await openInfo(tester, api);

      expect(text(tester, ProjectInfoScreen.unitKey('project-0-unit-0')), 'الفلة الغربية');
      expect(text(tester, ProjectInfoScreen.descriptionTextKey), 'فيلتان سكنيتان في حي النرجس.');
      expect(find.byKey(ProjectInfoScreen.unitMenuKey('project-0-unit-0')), findsNothing);
      expectNoChangeOffered();
    });

    testWidgets('R10: with no description, a reader reads "No description yet."', (tester) async {
      final api = FakeApi()..addProject('غصون 6', permissions: field);
      await openInfo(tester, api);

      expect(text(tester, ProjectInfoScreen.descriptionTextKey), 'en projectInfo.noDescription');
    });

    testWidgets('AC-04.1: a finished project shows read-only, and offers no change even to its manager', (tester) async {
      final api = FakeApi()..addProject('غصون 5', status: 'finished', startDate: '2024-01-15', units: ['الفلة الشرقية'], description: 'فيلا واحدة.');
      await openInfo(tester, api);

      expect(text(tester, ProjectInfoScreen.statusKey.label), 'en projects.finished');
      expect(text(tester, ProjectInfoScreen.detailsKey), 'en projects.startDate 15.01.2024 · en projects.readOnly');
      expect(text(tester, ProjectInfoScreen.descriptionTextKey), 'فيلا واحدة.');
      expect(find.byKey(ProjectInfoScreen.unitMenuKey('project-0-unit-0')), findsNothing);
      expectNoChangeOffered();
    });
  });

  group('the description', () {
    testWidgets('R3, R12: Save keeps what was typed, says "Description saved." and keeps the text on the page', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);

      await tester.enterText(find.byKey(ProjectInfoScreen.descriptionKey), 'فيلتان سكنيتان في حي النرجس.\nالتسليم ديسمبر 2027.');
      await tap(tester, api, ProjectInfoScreen.saveDescriptionKey);

      expect(api.sentProjectChanges.single.$1, '/projects/project-0/description');
      expect(api.sentProjectChanges.single.$2, {'description': 'فيلتان سكنيتان في حي النرجس.\nالتسليم ديسمبر 2027.'});
      expect(text(tester, messageKeyOf('projectInfo.saved').label), 'en projectInfo.saved');
      expect(api.projects.single['description'], 'فيلتان سكنيتان في حي النرجس.\nالتسليم ديسمبر 2027.');
      expect(typed(tester, ProjectInfoScreen.descriptionKey), 'فيلتان سكنيتان في حي النرجس.\nالتسليم ديسمبر 2027.');
    });

    testWidgets('the description kept starts the field, and saving it empty clears it', (tester) async {
      final api = FakeApi()..addProject('غصون 6', description: 'فيلتان');
      await openInfo(tester, api);
      expect(typed(tester, ProjectInfoScreen.descriptionKey), 'فيلتان');

      await tester.enterText(find.byKey(ProjectInfoScreen.descriptionKey), '');
      await tap(tester, api, ProjectInfoScreen.saveDescriptionKey);

      expect(api.sentProjectChanges.single.$2, {'description': ''});
      expect(api.projects.single['description'], '');
    });

    testWidgets('R10: the field takes at most 2,000 characters and counts them', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);

      await tester.enterText(find.byKey(ProjectInfoScreen.descriptionKey), 'و' * 2001);
      await tester.pump();

      expect(typed(tester, ProjectInfoScreen.descriptionKey).length, 2000);
      expect(find.text('2000/2000'), findsOneWidget);
    });

    testWidgets('R14: a refusal says why and keeps what was typed', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);

      api.projectAnswer = (status: 400, code: 'invalidDescription');
      await tester.enterText(find.byKey(ProjectInfoScreen.descriptionKey), 'فيلتان');
      await tap(tester, api, ProjectInfoScreen.saveDescriptionKey);

      expect(text(tester, messageKeyOf('projects.invalidDescription').label), 'en projects.invalidDescription');
      expect(find.byKey(messageKeyOf('projectInfo.saved')), findsNothing);
      expect(typed(tester, ProjectInfoScreen.descriptionKey), 'فيلتان');
    });

    testWidgets('R14: with no network it says so and keeps what was typed', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);

      api.online = false;
      await tester.enterText(find.byKey(ProjectInfoScreen.descriptionKey), 'فيلتان');
      await tap(tester, api, ProjectInfoScreen.saveDescriptionKey);

      expect(text(tester, messageKeyOf('projects.noConnection').label), 'en projects.noConnection');
      expect(typed(tester, ProjectInfoScreen.descriptionKey), 'فيلتان');
    });

    testWidgets('R14: reading the project again never replaces what is being typed', (tester) async {
      final api = FakeApi()..addProject('غصون 6', description: 'فيلتان');
      await openInfo(tester, api);
      await tester.enterText(find.byKey(ProjectInfoScreen.descriptionKey), 'ثلاث فلل');

      await tap(tester, api, ProjectInfoScreen.renameKey);
      await tester.enterText(find.byKey(NameDialog.nameKey), 'غصون السادس');
      await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

      expect(text(tester, ProjectInfoScreen.nameKey), 'غصون السادس');
      expect(typed(tester, ProjectInfoScreen.descriptionKey), 'ثلاث فلل');
    });
  });

  group('the name (BR-38)', () {
    testWidgets('whoever manages the project renames it, starting from its name, and More info and the home follow', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);

      await tap(tester, api, ProjectInfoScreen.renameKey);
      expect(typed(tester, NameDialog.nameKey), 'غصون 6');
      await tester.enterText(find.byKey(NameDialog.nameKey), 'غصون السادس');
      await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

      expect(api.sentProjectChanges.single.$1, '/projects/project-0');
      expect(api.sentProjectChanges.single.$2, {'name': 'غصون السادس'});
      expect(text(tester, ProjectInfoScreen.nameKey), 'غصون السادس');
      await backHome(tester, api);
      expect(text(tester, HomeScreen.titleKey), 'غصون السادس');
    });

    testWidgets('a refused name stays in the dialog with its reason', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);
      await tap(tester, api, ProjectInfoScreen.renameKey);

      api.projectAnswer = (status: 400, code: 'invalidName');
      await tester.enterText(find.byKey(NameDialog.nameKey), ' ');
      await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

      expect(text(tester, ChangeDialog.messageKey), 'en projects.invalidName');
      expect(text(tester, ProjectInfoScreen.nameKey), 'غصون 6');
    });
  });

  group('units', () {
    testWidgets('R2: Add unit adds to the end of an active project', (tester) async {
      final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية']);
      await openInfo(tester, api);

      await tap(tester, api, ProjectInfoScreen.addUnitKey);
      await tester.enterText(find.byKey(ProjectInfoScreen.unitNameKey), 'الفلة الجنوبية');
      await act(tester, api, () => tester.tap(find.byKey(ProjectInfoScreen.saveUnitKey)));

      expect(find.byKey(ProjectInfoScreen.saveUnitKey), findsNothing);
      expect(api.sentProjectChanges.single.$1, '/projects/project-0/units');
      expect(api.sentProjectChanges.single.$2, {'name': 'الفلة الجنوبية'});
      expect(text(tester, ProjectInfoScreen.unitKey('project-0-unit-1')), 'الفلة الجنوبية');
    });

    testWidgets('BR-37: a unit name the project already has stays in the dialog with its reason', (tester) async {
      final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية']);
      await openInfo(tester, api);
      await tap(tester, api, ProjectInfoScreen.addUnitKey);

      api.projectAnswer = (status: 409, code: 'unitNameTaken');
      await tester.enterText(find.byKey(ProjectInfoScreen.unitNameKey), 'الفلة الغربية');
      await act(tester, api, () => tester.tap(find.byKey(ProjectInfoScreen.saveUnitKey)));

      expect(text(tester, ProjectInfoScreen.unitMessageKey), 'en projects.unitNameTaken');
      expect(typed(tester, ProjectInfoScreen.unitNameKey), 'الفلة الغربية');
    });

    testWidgets('BR-38: a unit is renamed from its menu, starting from its name', (tester) async {
      final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية']);
      await openInfo(tester, api);

      await chooseInUnitMenu(tester, api, 'project-0-unit-0', ProjectInfoScreen.renameUnitKey);
      expect(typed(tester, NameDialog.nameKey), 'الفلة الغربية');
      await tester.enterText(find.byKey(NameDialog.nameKey), 'الفلة الجنوبية');
      await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

      expect(api.sentProjectChanges.single.$1, '/projects/project-0/units/project-0-unit-0');
      expect(api.sentProjectChanges.single.$2, {'name': 'الفلة الجنوبية'});
      expect(text(tester, ProjectInfoScreen.unitKey('project-0-unit-0')), 'الفلة الجنوبية');
    });

    testWidgets('BR-37: a name another unit holds stays in the rename dialog with its reason', (tester) async {
      final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية', 'الفلة الشرقية']);
      await openInfo(tester, api);
      await chooseInUnitMenu(tester, api, 'project-0-unit-0', ProjectInfoScreen.renameUnitKey);

      api.projectAnswer = (status: 409, code: 'unitNameTaken');
      await tester.enterText(find.byKey(NameDialog.nameKey), 'الفلة الشرقية');
      await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));

      expect(text(tester, ChangeDialog.messageKey), 'en projects.unitNameTaken');
    });

    testWidgets('BR-38: a unit is deleted from its menu only after asking, naming it', (tester) async {
      final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية', 'الفلة الشرقية']);
      await openInfo(tester, api);

      await chooseInUnitMenu(tester, api, 'project-0-unit-0', ProjectInfoScreen.deleteUnitKey);
      expect(text(tester, ConfirmDialog.subjectKey), 'الفلة الغربية');
      expect(text(tester, ConfirmDialog.explanationKey), 'en projects.removeUnitExplain');
      expect(api.sentProjectChanges, isEmpty);
      await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));

      expect(api.sentProjectChanges.single.$1, '/projects/project-0/units/project-0-unit-0/delete');
      expect(find.byKey(ProjectInfoScreen.unitKey('project-0-unit-0')), findsNothing);
      expect(find.byKey(ProjectInfoScreen.unitKey('project-0-unit-1')), findsOneWidget);
    });

    testWidgets('BR-38: without manageProject nothing offers a unit rename or deletion', (tester) async {
      final api = FakeApi()..addProject('غصون 6', units: ['الفلة الغربية'], permissions: field);
      await openInfo(tester, api);

      expect(find.byKey(ProjectInfoScreen.unitKey('project-0-unit-0')), findsOneWidget);
      expect(find.byKey(ProjectInfoScreen.unitMenuKey('project-0-unit-0')), findsNothing);
    });
  });

  group('closing (AC-04.1, BR-35)', () {
    testWidgets('closing asks first, says what it means, and Cancel changes nothing', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);

      await tap(tester, api, ProjectInfoScreen.closeKey);
      expect(text(tester, ProjectInfoScreen.closeNameKey), 'غصون 6');
      expect(text(tester, ProjectInfoScreen.closeExplainKey), 'en projects.closeExplain');
      await act(tester, api, () => tester.tap(find.byKey(ProjectInfoScreen.cancelCloseKey)));

      expect(api.sentProjectChanges, isEmpty);
      expect(text(tester, ProjectInfoScreen.statusKey.label), 'en projects.active');
    });

    testWidgets('closing makes it finished: the page turns read-only and the home says so', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);

      await tap(tester, api, ProjectInfoScreen.closeKey);
      await act(tester, api, () => tester.tap(find.byKey(ProjectInfoScreen.confirmCloseKey)));

      expect(api.sentProjectChanges.single.$1, '/projects/project-0/close');
      expect(text(tester, ProjectInfoScreen.statusKey.label), 'en projects.finished');
      expectNoChangeOffered();
      await backHome(tester, api);
      expect(text(tester, HomeScreen.finishedKey('project-0').title), 'en projects.finished · en projects.readOnly');
    });

    testWidgets('BR-35: a project with entries waiting for approval stays open and says why', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);
      await tap(tester, api, ProjectInfoScreen.closeKey);

      api.projectAnswer = (status: 409, code: 'pendingEntries');
      await act(tester, api, () => tester.tap(find.byKey(ProjectInfoScreen.confirmCloseKey)));

      expect(text(tester, messageKeyOf('projects.pendingEntries').label), 'en projects.pendingEntries');
      expect(find.byKey(ProjectInfoScreen.closeKey), findsOneWidget);
      expect(text(tester, ProjectInfoScreen.statusKey.label), 'en projects.active');
    });

    testWidgets('closing without a network says so, and the project stays as it was', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);
      await tap(tester, api, ProjectInfoScreen.closeKey);

      api.online = false;
      await act(tester, api, () => tester.tap(find.byKey(ProjectInfoScreen.confirmCloseKey)));

      expect(text(tester, messageKeyOf('projects.noConnection').label), 'en projects.noConnection');
      expect(find.byKey(ProjectInfoScreen.closeKey), findsOneWidget);
    });

    testWidgets('a project someone else closed shows its refusal, and the page reads it again', (tester) async {
      final api = FakeApi();
      final project = api.addProject('غصون 6');
      await openInfo(tester, api);
      await tap(tester, api, ProjectInfoScreen.closeKey);

      project['status'] = 'finished';
      api.projectAnswer = (status: 409, code: 'projectFinished');
      await act(tester, api, () => tester.tap(find.byKey(ProjectInfoScreen.confirmCloseKey)));

      expect(text(tester, messageKeyOf('projects.projectFinished').label), 'en projects.projectFinished');
      expect(find.byKey(ProjectInfoScreen.closeKey), findsNothing);
      expect(text(tester, ProjectInfoScreen.statusKey.label), 'en projects.finished');
    });

    testWidgets('a refusal with no code shows the general word, never a raw key', (tester) async {
      final api = FakeApi()..addProject('غصون 6');
      await openInfo(tester, api);
      await tap(tester, api, ProjectInfoScreen.closeKey);

      api.projectAnswer = (status: 403, code: '');
      await act(tester, api, () => tester.tap(find.byKey(ProjectInfoScreen.confirmCloseKey)));

      expect(text(tester, messageKeyOf('projects.refused').label), 'en projects.refused');
    });
  });

  testWidgets('More info of a second project shows that project, not the first', (tester) async {
    final api = FakeApi()
      ..addProject('غصون 6', units: ['الفلة الغربية'])
      ..addProject('غصون 5', status: 'finished', units: ['الفلة الشرقية']);
    await openProject(tester, api);
    await act(tester, api, () => tester.tap(find.byType(BackButton)));
    await tester.ensureVisible(find.byKey(ProjectsScreen.cardKey('project-1')));
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey('project-1'))));

    await openProjectInfo(tester, api, projectId: 'project-1');

    expect(text(tester, ProjectInfoScreen.nameKey), 'غصون 5');
    expect(find.byKey(ProjectInfoScreen.unitKey('project-1-unit-0')), findsOneWidget);
    expect(find.byKey(ProjectInfoScreen.unitKey('project-0-unit-0')), findsNothing);
  });
}
