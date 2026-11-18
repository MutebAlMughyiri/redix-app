// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter_test/flutter_test.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/ui/part_keys.dart';

import '../support/entry_steps.dart';
import '../support/given.dart';
import '../support/made_up_invoice.dart';
import '../support/phone_case.dart';
import '../support/phone_screens.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Invoice picture and QR code (UC-021 and UC-024)', () {
    phoneCase('FR-10: the camera opens only when asked, and its picture stays on the screen', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      expect($(AddEntryScreen.invoicePictureKey), findsNothing);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
    });

    phoneCase('AC-11.1: a QR code fills the total', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.qrReadKey));
      expect($.typed(AddEntryScreen.amountKey), '1075');
    });

    phoneCase('a supplier not in the register is offered a quick add', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.qrSupplierMissingKey));
      await $.reach($(AddEntryScreen.qrAddSupplierKey));
    });

    phoneCase('D21: a QR code fills the date and chooses the supplier with that number', ($) async {
      final manager = await Given.manager();
      await Given.supplier(manager, name: 'شركة النخيل', vatNumber: madeUpSellerVatNumber);
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.qrReadKey));
      await $.says(AddEntryScreen.supplierKey.label, 'شركة النخيل');
    });

    phoneCase('a picture chosen from the files is read too', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await $.pickFromThePhone(AddEntryScreen.filesKey, madeUpPictureName, madeUpPicture());
      await $.reach($(AddEntryScreen.qrReadKey));
      expect($.typed(AddEntryScreen.amountKey), '1075');
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

    phoneCase('AC-11.2: a picture with no code shows the message, and the fields stay open', ($) async {
      final manager = await Given.manager();
      CameraWithAPicture.noCode = true;
      await $.onAddEntry(manager);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.says(AddEntryScreen.qrMessageKey, $.words.expensesQrUnreadable);
      await $.fill(AddEntryScreen.amountKey, '100');
    });

    phoneCase('a PDF is not read for a code', ($) async {
      final manager = await Given.manager();
      await $.onAddEntry(manager);
      await $.pickFromThePhone(AddEntryScreen.filesKey, madeUpPdfName, madeUpPdf);
      await $.says(AddEntryScreen.invoiceNameKey, madeUpPdfName);
      expect($(AddEntryScreen.qrMessageKey), findsNothing);
      expect($(AddEntryScreen.qrReadKey), findsNothing);
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
      await $.choosePayment(manager, account);
      await $.sendEntry();
      await $.messageShows('expenses.sent');
      CameraWithAPicture.sameFile = true;
      await $.reach($(HomeScreen.addEntryKey(manager.projectId)));
      await $(HomeScreen.addEntryKey(manager.projectId)).tap();
      await $.pickTable(table.tableId);
      await $.tapOn(AddEntryScreen.cameraKey);
      await $.reach($(AddEntryScreen.invoicePictureKey));
      await $.choosePayment(manager, account);
      await $.sendEntry();
      await $.reach($(AddEntryScreen.messageKey));
      expect($(AddEntryScreen.sendKey), findsOneWidget);
    });
  });
}
