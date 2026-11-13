import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Signs a new manager in and opens the form, answering the manager.
Future<Person> onTheForm(PatrolIntegrationTester $) async {
  final manager = await Given.manager();
  await $.onTheList(manager);
  await $.tapOn(ProjectsScreen.newProjectKey);
  await $.reach($(NewProjectScreen.nameKey));
  return manager;
}

/// Sends the form, returning once the API has answered.
Future<void> send(PatrolIntegrationTester $) async {
  await $.tapOn(NewProjectScreen.submitKey);
  await $.answered(NewProjectScreen.submitKey);
}

void main() {
  phoneClass('Start a project while signed in (UC-006, UC-066)', () {
    phoneCase('Register new project is offered to everyone signed in', ($) async {
      final member = await Given.member(await Given.manager());
      await $.onTheList(member);
      await $.reach($(ProjectsScreen.newProjectKey));
    });

    phoneCase('a signed-in person starts a project, with its units, under their own login', ($) async {
      await onTheForm($);
      expect($(NewProjectScreen.managerNameKey), findsNothing);
      final project = 'Project ${Given.unique()}';
      await $.fill(NewProjectScreen.nameKey, project);
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الغربية');
      await $.tapOn(NewProjectScreen.addUnitKey);
      await send($);
      final id = await $.idShowing('projects.card.', project);
      await $.says(ProjectsScreen.detailsKey(id), 'الفلة الغربية');
      await $.says(ProjectsScreen.statusKey(id).label, $.words.projectsPending);
    });

    phoneCase('AC-05.2: a new project copies the structure of an approved earlier one', ($) async {
      final manager = await Given.manager();
      final category = 'Category ${Given.unique()}';
      await Given.category(manager, category);
      await $.onTheList(manager);
      await $.tapOn(ProjectsScreen.newProjectKey);
      final project = 'Project ${Given.unique()}';
      await $.fill(NewProjectScreen.nameKey, project);
      await $.tapOn(NewProjectScreen.structureSourceKey);
      await $.tapOn(NewProjectScreen.structureSourceOptionKey(manager.projectId).label);
      await send($);
      final id = await $.idShowing('projects.card.', project);
      await Given.approved(id);
      await $.restartApp();
      await $.openProject(id);
      await $.tapOn(HomeScreen.categoriesKey(id));
      await $.idShowing('categories.name.', category);
    });

    phoneCase('NFR-04: the start date is today until changed, and shows as dd.MM.yyyy', ($) async {
      await onTheForm($);
      final today = DateTime.now();
      await $.says(NewProjectScreen.startDateKey.label, formatDate(today));
      final day = today.day == 1 ? 2 : 1;
      await $.tapOn(NewProjectScreen.startDateKey);
      await $.pumpAndSettle();
      final picker = find.byType(DatePickerDialog);
      await $.tester.tap(find.descendant(of: picker, matching: find.text('$day')));
      await $.pumpAndSettle();
      await $.tester.tap(find.descendant(of: picker, matching: find.text(MaterialLocalizations.of($.tester.element(picker)).okButtonLabel)));
      await $.pumpAndSettle();
      await $.says(NewProjectScreen.startDateKey.label, formatDate(DateTime(today.year, today.month, day)));
    });

    phoneCase('Add unit waits for a name', ($) async {
      await onTheForm($);
      await $.goTo($(NewProjectScreen.addUnitKey));
      expect($.isEnabled(NewProjectScreen.addUnitKey), isFalse);
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الغربية');
      await $.pumpAndSettle();
      expect($.isEnabled(NewProjectScreen.addUnitKey), isTrue);
    });

    phoneCase('a refused name shows its own line, and nothing typed is lost', ($) async {
      await onTheForm($);
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الغربية');
      await send($);
      await $.says(NewProjectScreen.messageKey, $.words.projectsInvalidName);
      expect($.typed(NewProjectScreen.unitNameKey), 'الفلة الغربية');
    });

    phoneCase('BR-37: a repeated unit name is refused on this form too', ($) async {
      await onTheForm($);
      await $.fill(NewProjectScreen.nameKey, 'Project ${Given.unique()}');
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الشرقية');
      await $.tapOn(NewProjectScreen.addUnitKey);
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الشرقية');
      await send($);
      await $.says(NewProjectScreen.messageKey, $.words.projectsUnitNameTaken);
      await $.reach($(NewProjectScreen.unitKey(0)));
    });

    phoneCase('without a network the form says so, and nothing changes', ($) async {
      await onTheForm($);
      final project = 'Project ${Given.unique()}';
      await $.fill(NewProjectScreen.nameKey, project);
      await Pc.cutNetwork();
      await send($);
      await $.says(NewProjectScreen.messageKey, $.words.projectsNoConnection);
      expect($.typed(NewProjectScreen.nameKey), project);
    });
  });
}
