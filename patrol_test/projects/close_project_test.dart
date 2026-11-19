// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/messages.dart';

import '../support/given.dart';
import '../support/pc.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

/// Taps Close project on More info, standing on its question.
Future<void> askToClose(PatrolIntegrationTester $) async {
  await $.tapOn(ProjectInfoScreen.closeKey);
  await $.reach($(ConfirmDialog.confirmKey));
}

void main() {
  phoneClass('Close a project (UC-006)', () {
    phoneCase('closing asks first and says what it means', ($) async {
      final manager = await Given.manager(project: 'مشروع B');
      await $.onMoreInfo(manager);
      await askToClose($);
      await $.says(ConfirmDialog.subjectKey, 'مشروع B');
      await $.says(ConfirmDialog.explanationKey, $.words.projectsCloseExplain);
      await $.picture('close-project');
    });

    phoneCase('AC-04.1: with nothing waiting it closes, and its status says finished', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await askToClose($);
      await $(ConfirmDialog.confirmKey).tap();
      await $.gone($(ProjectInfoScreen.closeKey));
      await $.says(ProjectInfoScreen.statusKey.label, $.words.projectsFinished);
    });

    phoneCase('BR-35: a project holding only drafts closes, since only entries waiting block it', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager, sent: false);
      await $.onMoreInfo(manager);
      await askToClose($);
      await $(ConfirmDialog.confirmKey).tap();
      await $.gone($(ProjectInfoScreen.closeKey));
    });

    phoneCase('Cancel changes nothing', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await askToClose($);
      await $(ConfirmDialog.cancelKey).tap();
      await $.gone($(ConfirmDialog.confirmKey));
      await $.says(ProjectInfoScreen.statusKey.label, $.words.projectsActive);
    });

    phoneCase('BR-35: a project with entries waiting stays open, and the refusal says why', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      await $.onMoreInfo(manager);
      await askToClose($);
      await $(ConfirmDialog.confirmKey).tap();
      await $.says(messageKeyOf('projects.pendingEntries').label, $.words.projectsPendingEntries);
      await $.says(ProjectInfoScreen.statusKey.label, $.words.projectsActive);
    });

    phoneCase('without a network the close says so, and nothing changes', ($) async {
      final manager = await Given.manager();
      await $.onMoreInfo(manager);
      await askToClose($);
      await Pc.cutNetwork();
      await $(ConfirmDialog.confirmKey).tap();
      await $.says(messageKeyOf('projects.noConnection').label, $.words.projectsNoConnection);
      await $.says(ProjectInfoScreen.statusKey.label, $.words.projectsActive);
    });
  });
}
