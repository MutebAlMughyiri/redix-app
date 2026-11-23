// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:redix/attachments/invoice_capture.dart';
import 'package:redix/attachments/picked_file.dart';

/// A picture of a made-up invoice, a different one for each photo taken in the case, since the same file is refused on a second entry (BR-22).
Uint8List pictureOfAnInvoice() {
  final picture = img.fill(img.Image(width: 300, height: 300), color: img.ColorRgb8(255, 255, 255));
  img.fillRect(picture, x1: 20, y1: 20, x2: 20 + picturesTaken * 10, y2: 60, color: img.ColorRgb8(0, 0, 0));
  return img.encodePng(picture);
}

/// How many photos were taken in this case: each is of another invoice, because the same file is refused on a second entry (BR-22).
var picturesTaken = 0;

/// The VAT number of the made-up seller, شركة النخيل.
const madeUpSellerVatNumber = '300000000000003';

/// The name of a picture of an invoice kept on the phone.
const madeUpPictureName = 'made-up-invoice.png';

/// The name of a PDF kept on the phone.
const madeUpPdfName = 'made-up-invoice.pdf';

/// The name of any other file kept on the phone.
const madeUpDocumentName = 'made-up-document.txt';

/// What a made-up PDF holds.
List<int> get madeUpPdf => utf8.encode('%PDF-1.4 made up');

/// What any other made-up file holds.
List<int> get madeUpDocument => utf8.encode('A made-up document.');

/// A new picture of a made-up invoice.
Uint8List madeUpPicture() {
  picturesTaken++;
  return pictureOfAnInvoice();
}

/// A camera that hands over a picture, because no test can point a phone's camera at an invoice. It is the one stand-in: files, the share sheet and the printer are the phone's own (redix-app #92).
class CameraWithAPicture extends InvoiceCapture {
  /// The camera whose every photo is of a made-up invoice.
  CameraWithAPicture();

  /// Whether the next photo is the same file as the one before it.
  static var sameFile = false;

  /// Whether the person backs out of the camera with no picture.
  static var backedOut = false;

  /// Whether the phone refuses the camera, as it does without its permission.
  static var cameraRefused = false;

  /// Puts everything a case may have changed back as it was.
  static void reset() {
    sameFile = false;
    backedOut = false;
    cameraRefused = false;
  }

  @override
  Future<PickedFile> fromCamera() async {
    if (backedOut) {
      return PickedFile.none();
    }
    if (cameraRefused) {
      return PickedFile.failed('attachments.cameraFailed');
    }
    if (!sameFile) {
      picturesTaken++;
    }
    final bytes = pictureOfAnInvoice();
    final file = await File('${Directory.systemTemp.path}/made-up-invoice.png').writeAsBytes(bytes);
    return PickedFile('made-up-invoice.png', file.path, bytes);
  }
}
