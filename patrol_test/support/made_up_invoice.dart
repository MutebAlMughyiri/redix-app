import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';
import 'package:redix/attachments/invoice_capture.dart';
import 'package:redix/attachments/picked_file.dart';

/// The picture of [text] as a QR code, with the white border a reader needs.
Uint8List pictureOfQr(String text) {
  const cell = 8;
  const border = 4;
  final code = QrImage(QrCode.fromData(data: text, errorCorrectLevel: QrErrorCorrectLevel.L));
  final size = (code.moduleCount + border * 2) * cell;
  final picture = img.fill(img.Image(width: size, height: size), color: img.ColorRgb8(255, 255, 255));
  for (var y = 0; y < code.moduleCount; y++) {
    for (var x = 0; x < code.moduleCount; x++) {
      if (code.isDark(y, x)) {
        final left = (x + border) * cell;
        final top = (y + border) * cell;
        img.fillRect(picture, x1: left, y1: top, x2: left + cell - 1, y2: top + cell - 1, color: img.ColorRgb8(0, 0, 0));
      }
    }
  }
  return img.encodePng(picture);
}

/// How many photos were taken in this case: each is of another invoice, because the same file is refused on a second entry (BR-22).
var picturesTaken = 0;

/// The VAT number of the made-up seller, شركة النخيل, on every made-up invoice.
const madeUpSellerVatNumber = '300000000000003';

/// The QR code of a made-up invoice from شركة النخيل, whose VAT is what 7.5% makes.
String get madeUpInvoiceQr {
  List<int> field(int tag, String text) => [tag, utf8.encode(text).length, ...utf8.encode(text)];
  return base64.encode([
    ...field(1, 'شركة النخيل'),
    ...field(2, madeUpSellerVatNumber),
    ...field(3, '${DateTime.now().toIso8601String().substring(0, 10)}T10:${picturesTaken.toString().padLeft(2, '0')}:00Z'),
    ...field(4, '1075.00'),
    ...field(5, '75.00'),
  ]);
}

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

/// A new picture of a made-up invoice with its QR code.
Uint8List madeUpPicture() {
  picturesTaken++;
  return pictureOfQr(madeUpInvoiceQr);
}

/// A camera that hands over a picture, because no test can point a phone's camera at an invoice. It is the one stand-in: files, the share sheet and the printer are the phone's own (redix-app #92).
class CameraWithAPicture extends InvoiceCapture {
  /// The camera whose every photo is of a made-up invoice's QR code, or of nothing readable while [noCode] is set.
  CameraWithAPicture();

  /// Whether the next photo holds no code.
  static var noCode = false;

  /// Whether the next photo is the same file as the one before it.
  static var sameFile = false;

  /// Whether the person backs out of the camera with no picture.
  static var backedOut = false;

  /// Whether the phone refuses the camera, as it does without its permission.
  static var cameraRefused = false;

  /// Puts everything a case may have changed back as it was.
  static void reset() {
    noCode = false;
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
    final bytes = noCode ? img.encodePng(img.fill(img.Image(width: 300, height: 300), color: img.ColorRgb8(255, 255, 255))) : pictureOfQr(madeUpInvoiceQr);
    final file = await File('${Directory.systemTemp.path}/made-up-invoice.png').writeAsBytes(bytes);
    return PickedFile('made-up-invoice.png', file.path, bytes);
  }
}
