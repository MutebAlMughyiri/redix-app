// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/reports/report_files.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/words/word_fill.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/steps.dart';

/// The name of the archive a case puts in the phone's Downloads to retrieve.
const _fileName = 'archive-test.json';

/// The save choice of the sheet «أرشفة المشروع» opens for [project]'s archive, whose name ends in the minute the server's clock gave it.
Finder _saveChoice(PatrolIntegrationTester $, String project) {
  final start = 'reportFile.${$.words.projectsArchiveFileName.fill([project, ''])}';
  final end = '.${ReportFileKind.archive.name}.${FileHandling.save.name}';
  return find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith(start) && (widget.key! as ValueKey<String>).value.endsWith(end));
}

/// Picks [archive] from the phone's Downloads through «استرجاع المشروع» of [manager]'s project, standing on its home.
Future<void> pickArchive(PatrolIntegrationTester $, Person manager, List<int> archive) async {
  await $.onTheHome(manager);
  await $.goTo($(HomeScreen.retrieveKey(manager.projectId)));
  await $.pickFromThePhone(HomeScreen.retrieveKey(manager.projectId), _fileName, archive);
}

void main() {
  phoneClass('Archive a project and retrieve it (UC-073, redix-api #130)', () {
    phoneCase('AC-73.1: the manager archives the project, saved in Downloads', ($) async {
      final manager = await Given.manager();
      await $.onTheHome(manager);
      await $.goTo($(HomeScreen.archiveKey(manager.projectId)));

      await $.tapOn(HomeScreen.archiveKey(manager.projectId));
      await $(_saveChoice($, manager.projectName)).waitUntilVisible();
      await $.picture('archive-save-or-share');
      await $(_saveChoice($, manager.projectName)).tap();

      await $.messageShows('reports.downloaded');
    });

    phoneCase('AC-73.2, AC-73.3: an entry recorded after the archive is gone once the archive is retrieved, after the question says what changes', ($) async {
      final manager = await Given.manager();
      final archive = await Given.archiveOf(manager);
      final entries = (await Given.entries(manager)).length;
      await Given.entry(manager, sent: false);

      await pickArchive($, manager, archive);
      await $(ConfirmDialog.titleKey).waitUntilVisible();
      await $.saysContaining(ConfirmDialog.explanationKey, $.words.projectsRetrieveWhat);
      await $.picture('retrieve-question');
      await $.tapOn(ConfirmDialog.confirmKey);

      await $.messageShows('projects.retrieveDone');
      await $.picture('retrieve-done');
      expect(await Given.entries(manager), hasLength(entries));
    });

    phoneCase('R12: another project\'s archive is refused, the bar naming that project, and nothing changes', ($) async {
      final other = await Given.manager();
      final manager = await Given.manager();
      final archive = await Given.archiveOf(other);
      final entries = (await Given.entries(manager)).length;

      await pickArchive($, manager, archive);

      await $.messageShows('projects.retrieve.archiveOfAnotherProject');
      expect(await Given.entries(manager), hasLength(entries));
    });
  });
}
