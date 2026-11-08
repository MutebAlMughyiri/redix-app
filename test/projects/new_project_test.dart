import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/projects_screen.dart';

import 'package:redix/ui/part_keys.dart';

import '../app_harness.dart';

void main() {
  Future<void> openForm(WidgetTester tester, FakeApi api) async {
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.newProjectKey)));
  }

  Future<void> addUnit(WidgetTester tester, FakeApi api, String name) => act(tester, api, () async {
    await tester.enterText(find.byKey(NewProjectScreen.unitNameKey), name);
    await tester.pump();
    await tester.tap(find.byKey(NewProjectScreen.addUnitKey));
  });

  Future<void> submit(WidgetTester tester, FakeApi api) => act(tester, api, () async {
    await tester.ensureVisible(find.byKey(NewProjectScreen.submitKey));
    await tester.tap(find.byKey(NewProjectScreen.submitKey));
  });

  Finder startDateShowing(DateTime date) => find.descendant(of: find.byKey(NewProjectScreen.startDateKey), matching: find.text(formatDate(date)));

  testWidgets('a project is created with its units, at once, and the list shows it', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);

    await tester.enterText(find.byKey(NewProjectScreen.nameKey), 'غصون 7');
    await addUnit(tester, api, 'الفلة الشرقية');
    await addUnit(tester, api, 'الفلة الشمالية');
    await submit(tester, api);

    final (path, body) = api.sentProjectChanges.single;
    expect(path, '/projects');
    expect(body['name'], 'غصون 7');
    expect(body['units'], ['الفلة الشرقية', 'الفلة الشمالية']);
    expect(find.byKey(NewProjectScreen.submitKey), findsNothing);
    expect(tester.widget<Text>(find.byKey(ProjectsScreen.nameKey('project-0'))).data, 'غصون 7');
    expect(tester.widget<Text>(find.byKey(ProjectsScreen.detailsKey('project-0'))).data, 'الفلة الشرقية · الفلة الشمالية');
  });

  testWidgets('a unit typed but not yet added goes with the project', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);

    await tester.enterText(find.byKey(NewProjectScreen.nameKey), 'غصون 7');
    await addUnit(tester, api, 'الفلة الشرقية');
    await tester.enterText(find.byKey(NewProjectScreen.unitNameKey), 'الفلة الشمالية');
    await submit(tester, api);

    expect(api.sentProjectChanges.single.$2['units'], ['الفلة الشرقية', 'الفلة الشمالية']);
  });

  testWidgets('R5: the description written under the name goes with the project', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);

    await tester.enterText(find.byKey(NewProjectScreen.nameKey), 'غصون 7');
    await tester.enterText(find.byKey(NewProjectScreen.descriptionKey), 'ثلاث فلل في حي الياسمين.');
    await submit(tester, api);

    expect(api.sentProjectChanges.single.$2['description'], 'ثلاث فلل في حي الياسمين.');
    expect(api.projects.single['description'], 'ثلاث فلل في حي الياسمين.');
  });

  testWidgets('R5: a project needs no description, and sends it empty', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);

    await tester.enterText(find.byKey(NewProjectScreen.nameKey), 'غصون 7');
    await submit(tester, api);

    expect(api.sentProjectChanges.single.$2['description'], '');
  });

  testWidgets('R10: the description takes at most 2,000 characters, and a refused one says why and stays', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);
    await tester.enterText(find.byKey(NewProjectScreen.descriptionKey), 'و' * 2001);
    expect(tester.widget<TextField>(find.byKey(NewProjectScreen.descriptionKey)).controller!.text.length, 2000);

    api.projectAnswer = (status: 400, code: 'invalidDescription');
    await submit(tester, api);

    expect(tester.widget<Text>(find.byKey(NewProjectScreen.messageKey)).data, 'en projects.invalidDescription');
    expect(tester.widget<TextField>(find.byKey(NewProjectScreen.descriptionKey)).controller!.text.length, 2000);
  });

  testWidgets('a project needs no units', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);

    await tester.enterText(find.byKey(NewProjectScreen.nameKey), 'غصون 7');
    await submit(tester, api);

    expect(api.sentProjectChanges.single.$2['units'], isEmpty);
    expect(tester.widget<Text>(find.byKey(ProjectsScreen.detailsKey('project-0'))).data, 'en projects.noUnits');
  });

  testWidgets('redix-api #102: a unit is swiped off the list until the project is created, and the next one keeps its place', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);
    expect(find.byKey(NewProjectScreen.swipeHintKey), findsNothing);

    await tester.enterText(find.byKey(NewProjectScreen.nameKey), 'غصون 7');
    await addUnit(tester, api, 'الفلة الشرقية');
    await addUnit(tester, api, 'الفلة الشمالية');
    expect(find.byKey(NewProjectScreen.swipeHintKey), findsOneWidget);
    await swipeToRemove(tester, api, NewProjectScreen.unitKey(0));

    expect(find.byKey(NewProjectScreen.unitKey(0)), findsNothing);
    expect(tester.widget<Text>(find.byKey(NewProjectScreen.unitKey(1).title)).data, 'الفلة الشمالية');
    await submit(tester, api);
    expect(api.sentProjectChanges.single.$2['units'], ['الفلة الشمالية']);
  });

  testWidgets('Add unit waits for a name', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);

    TextButton addUnitButton() => tester.widget<TextButton>(find.byKey(NewProjectScreen.addUnitKey));

    expect(addUnitButton().onPressed, isNull);

    await tester.enterText(find.byKey(NewProjectScreen.unitNameKey), '   ');
    await tester.pump();
    expect(addUnitButton().onPressed, isNull);

    await tester.enterText(find.byKey(NewProjectScreen.unitNameKey), 'الفلة الشرقية');
    await tester.pump();
    expect(addUnitButton().onPressed, isNotNull);
  });

  testWidgets('a refused name shows its own line, and nothing typed is lost', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);
    await addUnit(tester, api, 'الفلة الشرقية');

    api.projectAnswer = (status: 400, code: 'invalidName');
    await submit(tester, api);

    expect(tester.widget<Text>(find.byKey(NewProjectScreen.messageKey)).data, 'en projects.invalidName');
    expect(find.byKey(NewProjectScreen.unitKey(0)), findsOneWidget);
  });

  testWidgets('a unit name the project already has is refused with its own word (BR-37)', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);
    await addUnit(tester, api, 'الفلة الشرقية');
    await tester.enterText(find.byKey(NewProjectScreen.unitNameKey), 'الفلة الشرقية');

    api.projectAnswer = (status: 400, code: 'unitNameTaken');
    await submit(tester, api);

    expect(tester.widget<Text>(find.byKey(NewProjectScreen.messageKey)).data, 'en projects.unitNameTaken');
    expect(find.byKey(NewProjectScreen.unitKey(0)), findsOneWidget);
  });

  testWidgets('without a network the form says so, and nothing typed is lost', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);
    await tester.enterText(find.byKey(NewProjectScreen.nameKey), 'غصون 7');

    api.online = false;
    await submit(tester, api);

    expect(tester.widget<Text>(find.byKey(NewProjectScreen.messageKey)).data, 'en projects.noConnection');
    expect(tester.widget<TextField>(find.byKey(NewProjectScreen.nameKey)).controller!.text, 'غصون 7');
  });

  testWidgets('the start date is today until changed, sent as a date and shown as dd.MM.yyyy', (tester) async {
    final api = FakeApi();
    await openForm(tester, api);
    final today = DateTime.now();

    expect(startDateShowing(today), findsOneWidget);

    await act(tester, api, () => tester.tap(find.byKey(NewProjectScreen.startDateKey)));
    await act(tester, api, () async {
      await tester.tap(find.text('15'));
      await tester.pump();
      await tester.tap(find.text('OK'));
    });
    final picked = DateTime(today.year, today.month, 15);
    expect(startDateShowing(picked), findsOneWidget);

    await tester.enterText(find.byKey(NewProjectScreen.nameKey), 'غصون 7');
    await submit(tester, api);
    expect(api.sentProjectChanges.single.$2['startDate'], picked.toIso8601String().substring(0, 10));
  });
}
