import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/format/date_format.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/messages.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('More info and the description (UC-006)', () {
    phoneCase('R8: everyone in the project reads More info and its description', ($) async {
      final manager = await Given.manager(description: 'ثلاث فلل في حي الياسمين.');
      final member = await Given.member(manager);
      await $.onMoreInfo(member);
      await $.says(ProjectInfoScreen.descriptionTextKey, 'ثلاث فلل في حي الياسمين.');
    });

    phoneCase('R3: whoever manages the project saves a description', ($) async {
      final manager = await Given.manager(project: 'غصون 7', units: ['الفلة الشرقية', 'الفلة الشمالية'], description: 'ثلاث فلل في حي الياسمين.');
      await $.onMoreInfo(manager);
      expect($.typed(ProjectInfoScreen.descriptionKey), 'ثلاث فلل في حي الياسمين.');
      await $.fill(ProjectInfoScreen.descriptionKey, 'ثلاث فلل في حي الياسمين، التسليم ديسمبر 2027.');
      await $.tapOn(ProjectInfoScreen.saveDescriptionKey);
      await $(messageKeyOf('projectInfo.saved').label).waitUntilExists();
      await $.picture('project-info');
      await $.restartApp();
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.projectInfoKey(manager.projectId));
      await $.reach($(ProjectInfoScreen.descriptionKey));
      expect($.typed(ProjectInfoScreen.descriptionKey), 'ثلاث فلل في حي الياسمين، التسليم ديسمبر 2027.');
    });

    phoneCase('More info shows the project it was opened from', ($) async {
      final mine = await Given.manager();
      final other = await Given.manager();
      await Given.joined(mine, by: other);
      await $.onTheList(mine);
      await $.openProject(other.projectId);
      await $.tapOn(HomeScreen.projectInfoKey(other.projectId));
      await $.says(ProjectInfoScreen.nameKey, other.projectName);
    });

    phoneCase('R12: saving says "Description saved."', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await $.fill(ProjectInfoScreen.descriptionKey, 'فيلتان');
      await $.tapOn(ProjectInfoScreen.saveDescriptionKey);
      await $.says(messageKeyOf('projectInfo.saved').label, $.words.projectInfoSaved);
    });

    phoneCase('R3: an empty description clears it', ($) async {
      final manager = await Given.manager(description: 'فيلتان');
      final member = await Given.member(manager);
      await $.onMoreInfo(manager);
      await $.fill(ProjectInfoScreen.descriptionKey, '');
      await $.tapOn(ProjectInfoScreen.saveDescriptionKey);
      await $(messageKeyOf('projectInfo.saved').label).waitUntilExists();
      await $.back();
      await $.back();
      await $.signOutFromTheList();
      await $.signIn(member.username, member.password);
      await $.openProject(member.projectId);
      await $.tapOn(HomeScreen.projectInfoKey(member.projectId));
      await $.says(ProjectInfoScreen.descriptionTextKey, $.words.projectInfoNoDescription);
    });

    phoneCase('R10: a description of exactly 2,000 characters is kept', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await $.fill(ProjectInfoScreen.descriptionKey, 'و' * 2000);
      await $.tapOn(ProjectInfoScreen.saveDescriptionKey);
      await $.says(messageKeyOf('projectInfo.saved').label, $.words.projectInfoSaved);
      expect($.typed(ProjectInfoScreen.descriptionKey).length, 2000);
    });

    phoneCase('redix-api #93 R1: More info shows the start date, status and units in order, and the home shows none of them', ($) async {
      final manager = await Given.manager(units: ['الفلة الغربية', 'الفلة الجنوبية']);
      await $.onTheHome(manager);
      expect($(find.text('الفلة الغربية')), findsNothing);
      await $.tapOn(HomeScreen.projectInfoKey(manager.projectId));
      await $.reach($(ProjectInfoScreen.nameKey));
      await $.says(ProjectInfoScreen.detailsKey, '${$.words.projectsStartDate} ${formatDate(DateTime.now())}');
      await $.says(ProjectInfoScreen.statusKey.label, $.words.projectsActive);
      final first = await $.idShowing('projectInfo.unit.', 'الفلة الغربية');
      final second = await $.idShowing('projectInfo.unit.', 'الفلة الجنوبية');
      expect($.tester.getTopLeft(find.byKey(ProjectInfoScreen.unitKey(first))).dy, lessThan($.tester.getTopLeft(find.byKey(ProjectInfoScreen.unitKey(second))).dy));
    });

    phoneCase('R8: without manageProject there is no field to change, no Add unit and no Close', ($) async {
      final manager = await Given.manager(units: ['الفلة الغربية']);
      final member = await Given.member(manager);
      await $.onMoreInfo(member);
      await $.reach($(ProjectInfoScreen.descriptionTextKey));
      expect($(ProjectInfoScreen.descriptionKey), findsNothing);
      expect($(ProjectInfoScreen.addUnitKey), findsNothing);
      expect($(ProjectInfoScreen.closeKey), findsNothing);
      expect($(ProjectInfoScreen.nameMenuKey), findsNothing);
    });

    phoneCase('R10: a description cannot pass 2,000 characters, and the count shows', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await $.fill(ProjectInfoScreen.descriptionKey, 'و' * 2001);
      await $.pumpAndSettle();
      expect($.typed(ProjectInfoScreen.descriptionKey).length, 2000);
      expect($.tester.widget<TextField>(find.byKey(ProjectInfoScreen.descriptionKey)).maxLength, 2000, reason: 'the field counts up to its maxLength under it');
    });

    phoneCase('R14: an unsent description says why and keeps what was typed', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await $.fill(ProjectInfoScreen.descriptionKey, 'فيلتان');
      await Pc.cutNetwork();
      await $.tapOn(ProjectInfoScreen.saveDescriptionKey);
      await $.says(messageKeyOf('projects.noConnection').label, $.words.projectsNoConnection);
      expect($.typed(ProjectInfoScreen.descriptionKey), 'فيلتان');
    });
  });
}
