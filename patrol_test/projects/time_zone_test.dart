import 'package:flutter_test/flutter_test.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/project_info_screen.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass("A project's time zone (redix-app #107)", () {
    phoneCase('R2: a new project is in Riyadh, and More info says so', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await $.says(ProjectInfoScreen.timeZoneKey, '${$.words.projectsTimeZone}: ${$.words.timeZoneRiyadh} (UTC+3)');
    });

    phoneCase('D3: whoever manages the project puts it in another zone, which stays after a restart', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await $.menuChoice(ProjectInfoScreen.timeZoneMenuKey, ProjectInfoScreen.changeTimeZoneKey);
      await $(ProjectInfoScreen.timeZoneOptionKey('Asia/Shanghai')).scrollTo(view: find.byKey(ProjectInfoScreen.timeZonesKey));
      await $.tapOn(ProjectInfoScreen.timeZoneOptionKey('Asia/Shanghai'));
      await $.says(ProjectInfoScreen.timeZoneKey, '${$.words.projectsTimeZone}: ${$.words.timeZoneBeijing} (UTC+8)');
      await $.restartApp();
      await $.openProject(manager.projectId);
      await $.tapOn(HomeScreen.projectInfoKey(manager.projectId));
      await $.says(ProjectInfoScreen.timeZoneKey, '${$.words.projectsTimeZone}: ${$.words.timeZoneBeijing} (UTC+8)');
    });

    phoneCase('D3: a member reads the zone and cannot change it', ($) async {
      final manager = await Given.manager();
      final member = await Given.member(manager);
      await $.onMoreInfo(member);
      await $.says(ProjectInfoScreen.timeZoneKey, '${$.words.projectsTimeZone}: ${$.words.timeZoneRiyadh} (UTC+3)');
      expect($(ProjectInfoScreen.timeZoneMenuKey), findsNothing);
    });
  });
}
