// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/one_field_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/messages.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Opens Add unit on More info.
Future<void> openAddUnit(PatrolIntegrationTester $) async {
  await $.tapOn(ProjectInfoScreen.addUnitKey);
  await $.reach($(OneFieldDialog.fieldKey));
}

void main() {
  phoneClass('Rename the project, and its units (UC-006)', () {
    phoneCase('BR-38: renaming the project starts from its name, and More info and the home follow', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await $.menuChoice(ProjectInfoScreen.nameMenuKey, ProjectInfoScreen.renameKey);
      await $.reach($(OneFieldDialog.fieldKey));
      expect($.typed(OneFieldDialog.fieldKey), manager.projectName);
      final renamed = 'Renamed ${Given.unique()}';
      await $.saveName(renamed);
      await $.says(ProjectInfoScreen.nameKey, renamed);
      await $.back();
      await $.says(HomeScreen.titleKey, renamed);
    });

    phoneCase('Add unit adds one', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await openAddUnit($);
      await $.saveName('الملحق');
      await $.idOf('projectInfo.unit.', () => Given.unitNamed(manager, 'الملحق'));
    });

    phoneCase('BR-38: renaming a unit starts from its name, and the row follows', ($) async {
      final manager = await Given.manager(units: ['الفلة الغربية']);
      await $.onMoreInfo(manager);
      final unit = await $.idOf('projectInfo.unit.', () => Given.unitNamed(manager, 'الفلة الغربية'));
      await $.tapOn(ProjectInfoScreen.unitMenuKey(unit));
      await $.tapOn(ProjectInfoScreen.renameUnitKey);
      await $.reach($(OneFieldDialog.fieldKey));
      expect($.typed(OneFieldDialog.fieldKey), 'الفلة الغربية');
      await $.saveName('ملحق الفلة');
      await $.says(ProjectInfoScreen.unitKey(unit), 'ملحق الفلة');
    });

    phoneCase('redix-api #102, #119: a swipe deletes a unit once confirmed in its row', ($) async {
      final manager = await Given.manager(units: ['الفلة الغربية', 'الفلة الجنوبية']);
      await $.onMoreInfo(manager);
      final unit = await $.idOf('projectInfo.unit.', () => Given.unitNamed(manager, 'الفلة الغربية'));
      await $.swipeAway(ProjectInfoScreen.unitRowKey(unit));
      expect($(ConfirmDialog.dialogKey), findsNothing);
      await $.gone($(ProjectInfoScreen.unitKey(unit)));
      await $.idOf('projectInfo.unit.', () => Given.unitNamed(manager, 'الفلة الجنوبية'));
    });

    phoneCase('BR-37: a repeated unit name is refused in Add unit', ($) async {
      final manager = await Given.manager(units: ['الفلة الغربية']);
      await $.onMoreInfo(manager);
      await openAddUnit($);
      await $.saveName('الفلة الغربية');
      await $.says(ChangeDialog.messageKey, $.words.projectsUnitNameTaken);
      expect($.typed(OneFieldDialog.fieldKey), 'الفلة الغربية');
    });

    phoneCase('redix-api #102: a short swipe deletes nothing', ($) async {
      final manager = await Given.manager(units: ['الفلة الغربية']);
      await $.onMoreInfo(manager);
      final unit = await $.idOf('projectInfo.unit.', () => Given.unitNamed(manager, 'الفلة الغربية'));
      await $.swipeToAsk(ProjectInfoScreen.unitRowKey(unit), share: 0.15);
      await Future<void>.delayed(const Duration(seconds: 1));
      await $.pumpAndSettle();
      expect($(ProjectInfoScreen.unitKey(unit)), findsOneWidget);
    });

    phoneCase('a refused name shows its own line, and nothing typed is lost', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await $.menuChoice(ProjectInfoScreen.nameMenuKey, ProjectInfoScreen.renameKey);
      await $.saveName(' ');
      await $.says(ChangeDialog.messageKey, $.words.projectsInvalidName);
      expect($(OneFieldDialog.fieldKey), findsOneWidget);
      await $.says(ProjectInfoScreen.nameKey, manager.projectName);
    });

    phoneCase('BR-38: a unit that cannot be deleted comes back, and the refusal says why', ($) async {
      final manager = await Given.manager(units: ['الفلة الغربية']);
      await $.onMoreInfo(manager);
      final unit = await $.idOf('projectInfo.unit.', () => Given.unitNamed(manager, 'الفلة الغربية'));
      await Given.closed(manager);
      await $.swipeAway(ProjectInfoScreen.unitRowKey(unit));
      await $.says(messageKeyOf('projects.projectFinished').label, $.words.projectsProjectFinished);
      await $.reach($(ProjectInfoScreen.unitKey(unit)));
    });
  });
}
