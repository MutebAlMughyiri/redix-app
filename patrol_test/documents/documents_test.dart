import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/attachments/attachment_screen.dart';
import 'package:redix/documents/documents_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/given.dart';
import '../support/made_up_invoice.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/steps.dart';

/// Signs [person] in and opens the documents.
Future<void> onDocuments(PatrolIntegrationTester $, Person person) async {
  await $.fromTheHome(person, HomeScreen.documentsKey(person.projectId));
  await $.reach($(DocumentsScreen.addKey));
}

/// Opens the dialog of a new document and types its [name] and [group].
Future<void> fillDocument(PatrolIntegrationTester $, String name, String group) async {
  await $.tapOn(DocumentsScreen.addKey);
  await $(DocumentsScreen.nameKey).enterText(name);
  await $(DocumentsScreen.groupKey).enterText(group);
}

void main() {
  phoneClass('Documents (UC-064)', () {
    phoneCase('everyone opens the documents, those in no group first, then each group under its name', ($) async {
      final manager = await Given.manager();
      final grouped = await Given.document(manager, name: 'رخصة البناء', group: 'التراخيص');
      final loose = await Given.document(manager, name: 'عقد الأرض');
      final member = await Given.member(manager);
      await onDocuments($, member);
      await $.reach($(DocumentsScreen.documentKey(grouped)));
      await $.reach($(DocumentsScreen.groupHeadingKey('التراخيص')));
      expect($.topOf(DocumentsScreen.documentKey(loose)), lessThan($.topOf(DocumentsScreen.groupHeadingKey('التراخيص'))));
      expect($.topOf(DocumentsScreen.groupHeadingKey('التراخيص')), lessThan($.topOf(DocumentsScreen.documentKey(grouped))));
    });

    phoneCase('a picture opens on the phone, and any other file is handed on by its own name', ($) async {
      final manager = await Given.manager();
      final document = await Given.document(manager, name: 'تعليمات');
      await onDocuments($, manager);
      await $.tapOn(DocumentsScreen.documentKey(document));
      await $.tapToThePhone(AttachmentScreen.openFileKey);
      await $.shareSheetOffers('document.txt');
    });

    phoneCase('any file is kept under a name and a group', ($) async {
      final manager = await Given.manager();
      await onDocuments($, manager);
      await fillDocument($, 'رخصة البناء', 'التراخيص');
      await $.pickFromThePhone(DocumentsScreen.fileKey, madeUpDocumentName, madeUpDocument);
      await $(find.text(madeUpDocumentName)).waitUntilExists();
      await $(ChangeDialog.saveKey).tap();
      await $.idShowing('documents.document.', 'رخصة البناء');
      await $.reach($(DocumentsScreen.groupHeadingKey('التراخيص')));
    });

    phoneCase('a document with no group is sent with none', ($) async {
      final manager = await Given.manager();
      await onDocuments($, manager);
      await fillDocument($, 'عقد الأرض', '');
      await $.pickFromThePhone(DocumentsScreen.fileKey, madeUpDocumentName, madeUpDocument);
      await $(find.text(madeUpDocumentName)).waitUntilExists();
      await $(ChangeDialog.saveKey).tap();
      await $.idShowing('documents.document.', 'عقد الأرض');
      expect($(keyStartingWith('documents.group.')), findsNothing);
    });

    phoneCase('redix-api #102, #119: a swipe removes one once confirmed in its row', ($) async {
      final manager = await Given.manager();
      final document = await Given.document(manager);
      await onDocuments($, manager);
      await $.swipeAway(DocumentsScreen.documentKey(document));
      expect(find.byType(AlertDialog), findsNothing);
      await $.gone($(DocumentsScreen.documentKey(document)));
    });

    phoneCase('a document needs its file', ($) async {
      final manager = await Given.manager();
      await onDocuments($, manager);
      await fillDocument($, 'بلا ملف', '');
      await $(ChangeDialog.saveKey).tap();
      await $.says(ChangeDialog.messageKey, $.words.documentsFileRequired);
    });

    phoneCase('redix-api #102: a short swipe springs back', ($) async {
      final manager = await Given.manager();
      final document = await Given.document(manager);
      await onDocuments($, manager);
      await $.swipeToAsk(DocumentsScreen.documentKey(document), share: 0.15);
      await Future<void>.delayed(const Duration(seconds: 1));
      await $.pumpAndSettle();
      expect($(DocumentsScreen.documentKey(document).title), findsOneWidget);
    });
  });
}
