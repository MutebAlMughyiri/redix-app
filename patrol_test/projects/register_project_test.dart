import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/messages.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Opens the form from the sign-in page.
Future<void> openForm(PatrolIntegrationTester $) async {
  await $.startApp();
  await $.tapOn(SignInScreen.registerKey);
  await $.reach($(NewProjectScreen.nameKey));
}

/// Fills in the project's name and its manager, whose login is [username], and answers the password they chose.
Future<String> fillProjectAndManager(PatrolIntegrationTester $, String project, String username, {String manager = 'ريم', String mobile = '0511111111'}) async {
  final password = 'Chosen-${Given.unique()}-1';
  await $.fill(NewProjectScreen.nameKey, project);
  await $.fill(NewProjectScreen.managerNameKey, manager);
  await $.fill(NewProjectScreen.usernameKey, username);
  await $.fill(NewProjectScreen.mobileKey, mobile);
  await $.fill(NewProjectScreen.passwordKey, password);
  return password;
}

/// Sends the form, returning once the API has answered.
Future<void> send(PatrolIntegrationTester $) async {
  await $.tapOn(NewProjectScreen.submitKey);
  await $.answered(NewProjectScreen.submitKey);
}

/// Signs in as whoever registered [project], standing on the list, and answers the project's id.
Future<String> signInToFind(PatrolIntegrationTester $, String username, String password, String project) async {
  await $.signIn(username, password);
  return $.idOf('projects.card.', () => Given.projectNamed(Person(id: '', username: username, password: password, displayName: '', projectId: '', projectName: ''), project));
}

void main() {
  phoneClass('Register a new project (UC-066)', () {
    phoneCase('the sign-in page leads to the form, with no session', ($) async {
      await openForm($);
      await $.says(NewProjectScreen.hintKey, $.words.registerHint);
      expect($(NewProjectScreen.managerNameKey), findsOneWidget);
    });

    phoneCase('a project sent with its units, description and manager waits for approval', ($) async {
      await openForm($);
      await $.fill(NewProjectScreen.descriptionKey, 'ثلاث فلل في حي الياسمين.');
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الشرقية');
      await $.tapOn(NewProjectScreen.addUnitKey);
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الشمالية');
      await $.tapOn(NewProjectScreen.addUnitKey);
      final password = await fillProjectAndManager($, 'غصون 7', 'patrol-reem');
      await $.picture('register-project');
      await send($);
      final id = await signInToFind($, 'patrol-reem', password, 'غصون 7');
      await $.says(ProjectsScreen.statusKey(id).label, $.words.projectsPending);
    });

    phoneCase('once sent, the form returns to sign-in and says it is waiting', ($) async {
      await openForm($);
      await fillProjectAndManager($, 'Project ${Given.unique()}', 'manager-${Given.unique()}');
      await send($);
      await $.says(messageKeyOf('register.sent').label, $.words.registerSent);
      await $.reach($(SignInScreen.usernameKey));
    });

    phoneCase('R5: a project with no description and no units is accepted', ($) async {
      final project = 'Project ${Given.unique()}';
      final username = 'manager-${Given.unique()}';
      await openForm($);
      final password = await fillProjectAndManager($, project, username);
      await send($);
      final id = await signInToFind($, username, password, project);
      await $.says(ProjectsScreen.detailsKey(id), $.words.projectsNoUnits);
    });

    phoneCase('a unit typed but not yet added goes with the project', ($) async {
      final project = 'Project ${Given.unique()}';
      final username = 'manager-${Given.unique()}';
      await openForm($);
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الغربية');
      final password = await fillProjectAndManager($, project, username);
      await send($);
      final id = await signInToFind($, username, password, project);
      await $.says(ProjectsScreen.detailsKey(id), 'الفلة الغربية');
    });

    phoneCase('redix-api #109: partners declared in the form, the last one still typed, go with the project', ($) async {
      final project = 'Project ${Given.unique()}';
      final username = 'manager-${Given.unique()}';
      await openForm($);
      await $.fill(NewProjectScreen.partnerNameKey, 'متعب');
      await $.tapOn(NewProjectScreen.addPartnerKey);
      await $.fill(NewProjectScreen.partnerNameKey, 'نواف');
      final password = await fillProjectAndManager($, project, username);
      await send($);
      final id = await signInToFind($, username, password, project);
      await Given.approved(id);
      final registrant = Person(id: '', username: username, password: password, displayName: '', projectId: id, projectName: project);
      await $.restartApp();
      await $.openProject(id);
      await $.tapOn(HomeScreen.partnersKey(id));
      await $.idOf('partners.name.', () => Given.partnerNamed(registrant, 'متعب'));
      await $.idOf('partners.name.', () => Given.partnerNamed(registrant, 'نواف'));
      expect($(PartnersScreen.addKey), findsOneWidget);
    });

    phoneCase('a mobile typed in Arabic digits is sent in Western digits', ($) async {
      final project = 'Project ${Given.unique()}';
      await openForm($);
      await fillProjectAndManager($, project, 'manager-${Given.unique()}', mobile: '٠٥٠٠٠٠٠٠٠٠');
      await send($);
      await $.reach($(SignInScreen.usernameKey));
      expect((await Given.waiting(project))['managerMobile'], '0500000000');
    });

    phoneCase('redix-api #102: a unit is swiped off the list before sending', ($) async {
      final project = 'Project ${Given.unique()}';
      final username = 'manager-${Given.unique()}';
      await openForm($);
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الشرقية');
      await $.tapOn(NewProjectScreen.addUnitKey);
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الشمالية');
      await $.tapOn(NewProjectScreen.addUnitKey);
      await $.swipeAway(NewProjectScreen.unitKey(0));
      await $.gone($(NewProjectScreen.unitKey(0)));
      final password = await fillProjectAndManager($, project, username);
      await send($);
      final id = await signInToFind($, username, password, project);
      await $.says(ProjectsScreen.detailsKey(id), 'الفلة الشمالية');
    });

    phoneCase('a waiting project offers its manager nothing: no star, no opening', ($) async {
      final manager = await Given.registered(project: 'غصون 7', manager: 'ريم');
      await $.onTheList(manager);
      await $.reach($(ProjectsScreen.statusKey(manager.projectId)));
      expect($(ProjectsScreen.starKey(manager.projectId)), findsNothing);
      await $.picture('project-waiting');
      await $(ProjectsScreen.cardKey(manager.projectId)).tap();
      await $.pumpAndSettle();
      expect($(ProjectsScreen.titleKey), findsOneWidget);
    });

    phoneCase('AC-05.2: the sign-in page offers no copy of an earlier project', ($) async {
      await openForm($);
      expect($(NewProjectScreen.structureSourceKey), findsNothing);
    });

    phoneCase('a username already taken is refused, and nothing typed is lost', ($) async {
      final taken = await Given.manager();
      await openForm($);
      await fillProjectAndManager($, 'Project ${Given.unique()}', taken.username);
      await send($);
      await $.says(NewProjectScreen.messageKey, $.words.registerUsernameTaken);
      expect($.typed(NewProjectScreen.usernameKey), taken.username);
    });

    phoneCase('BR-37: a repeated unit name is refused with its own word', ($) async {
      await openForm($);
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الشرقية');
      await $.tapOn(NewProjectScreen.addUnitKey);
      await $.fill(NewProjectScreen.unitNameKey, 'الفلة الشرقية');
      await fillProjectAndManager($, 'Project ${Given.unique()}', 'manager-${Given.unique()}');
      await send($);
      await $.says(NewProjectScreen.messageKey, $.words.registerUnitNameTaken);
      await $.reach($(NewProjectScreen.unitKey(0)));
    });

    phoneCase('R10: a description stops at 2,000 characters, and what was typed stays on the form', ($) async {
      await openForm($);
      await $.fill(NewProjectScreen.descriptionKey, 'و' * 2001);
      expect($.typed(NewProjectScreen.descriptionKey).length, 2000);
    });

    phoneCase('empty required fields are refused, and the form stays', ($) async {
      await openForm($);
      await send($);
      await $.says(NewProjectScreen.messageKey, $.words.registerInvalidName);
      expect($(NewProjectScreen.submitKey), findsOneWidget);
    });

    phoneCase('without a network the form says so, and nothing typed is lost', ($) async {
      final username = 'manager-${Given.unique()}';
      await openForm($);
      await fillProjectAndManager($, 'Project ${Given.unique()}', username);
      await Pc.cutNetwork();
      await send($);
      await $.says(NewProjectScreen.messageKey, $.words.registerNoConnection);
      expect($.typed(NewProjectScreen.usernameKey), username);
    });
  });
}
