// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/made_up_invoice.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Invoice picture (UC-021)', () {
    phoneCase('FR-10: the camera opens only when asked, and its picture stays on the screen', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      expect($(AddEntryScreen.invoicePictureKey), findsNothing);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
    });

    phoneCase('a picture chosen from the files stays on the screen', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await $.pickFromThePhone(AddEntryScreen.filesKey, madeUpPictureName, madeUpPicture());
      await $.reach($(AddEntryScreen.invoicePictureKey));
    });

    phoneCase('going back keeps what was there', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      CameraWithAPicture.backedOut = true;
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.pumpAndSettle();
      expect($(AddEntryScreen.invoicePictureKey), findsOneWidget);
    });

    phoneCase('a PDF chosen from the files shows its name', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await $.pickFromThePhone(AddEntryScreen.filesKey, madeUpPdfName, madeUpPdf);
      await $.says(AddEntryScreen.invoiceNameKey, madeUpPdfName);
    });

    phoneCase('with no camera permission the message says so, and the files stay offered', ($) async {
      final manager = await Given.manager();
      CameraWithAPicture.cameraRefused = true;
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.says(AddEntryScreen.invoiceMessageKey, $.words.attachmentsCameraFailed);
      await $.goTo($(AddEntryScreen.filesKey));
    });

    phoneCase('BR-22: the same file is refused on a second entry', ($) async {
      final manager = await Given.manager();
      await Given.supplier(manager, name: 'شركة النخيل', vatNumber: madeUpSellerVatNumber);
      final account = await Given.account(manager);
      final table = await Given.firstPurchaseTable(manager);
      await $.onAddEntry(manager);
      await $.pickTable(table.tableId);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.fill(AddEntryScreen.amountKey, '1075');
      await $.choosePayment(manager, account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      CameraWithAPicture.sameFile = true;
      await $.reach($(HomeScreen.addEntryKey(manager.projectId)));
      await $(HomeScreen.addEntryKey(manager.projectId)).tap();
      await $.pickTable(table.tableId);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.fill(AddEntryScreen.amountKey, '1075');
      await $.choosePayment(manager, account);
      await $.sendEntry();
      await $.reach($(AddEntryScreen.messageKey));
      expect($(AddEntryScreen.sendKey), findsOneWidget);
    });
  });
}
