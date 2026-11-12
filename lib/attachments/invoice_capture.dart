import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:printing/printing.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';

import 'picked_file.dart';
import 'picture_compression.dart';

/// The phone's camera, files, printer and share sheet, as the app reaches them: the one place that touches them, so a test can stand in for hardware it does not have.
class InvoiceCapture {
  /// The phone's own camera and files.
  const InvoiceCapture();

  /// Opens the camera, whose scanner finds and crops the invoice (FR-10), and answers the picture under 1 MB (NFR-06). A phone that cannot, or a person who refused the camera, gets why, and picks from their files instead.
  Future<PickedFile> fromCamera() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(noOfPages: 1) ?? const [];
      if (pictures.isEmpty) {
        return PickedFile.none();
      }
      final file = File(pictures.first);
      return await _kept(PickedFile.read(file.uri.pathSegments.last, file.path, await file.readAsBytes()));
    } on Exception catch (error) {
      debugPrint('Camera not opened: $error');
      return PickedFile.failed('attachments.cameraFailed');
    }
  }

  /// The text of the QR code in the picture [file], read by the phone's own barcode reader; empty when none can be read.
  Future<String> qrTextOf(PickedFile file) async {
    final controller = MobileScannerController(autoStart: false);
    try {
      final path = file.path.isNotEmpty ? file.path : (await File('${Directory.systemTemp.path}/${file.name}').writeAsBytes(file.bytes)).path;
      final found = await controller.analyzeImage(path, formats: const [BarcodeFormat.qrCode]);
      return found?.barcodes.map((barcode) => barcode.rawValue ?? '').where((text) => text.isNotEmpty).firstOrNull ?? '';
    } on Exception catch (error) {
      debugPrint('QR code not read: $error');
      return '';
    } finally {
      await controller.dispose();
    }
  }

  /// What is shared to the app from WhatsApp, the gallery or email (FR-49): first what started it, if anything, then what arrives while it runs. A picture comes under 1 MB.
  Stream<PickedFile> shared() async* {
    final sharing = ReceiveSharingIntent.instance;
    try {
      for (final file in await sharing.getInitialMedia()) {
        yield await _fileAt(file.path);
      }
      await sharing.reset();
      await for (final files in sharing.getMediaStream()) {
        for (final file in files) {
          yield await _fileAt(file.path);
        }
        await sharing.reset();
      }
    } on Exception catch (error) {
      debugPrint('Sharing not available: $error');
    }
  }

  Future<PickedFile> _fileAt(String path) async {
    final file = File(path);
    return _kept(PickedFile.read(file.uri.pathSegments.last, path, await file.readAsBytes()));
  }

  /// [file] as the app keeps it: a picture under 1 MB (NFR-06); a PDF, and what could not be read or held nothing, as they are.
  Future<PickedFile> _kept(PickedFile file) async => file.isNone || file.isPdf ? file : PickedFile(file.name, file.path, await compute(compressedPicture, file.bytes));

  /// Hands the PDF [bytes], named [name], to the phone's print dialog: AirPrint on iPhone, the print service on Android and Huawei, with a preview (FR-48).
  Future<void> printPdf(Uint8List bytes, String name) => Printing.layoutPdf(onLayout: (_) async => bytes, name: name);

  /// Hands [text] alone to the phone's share sheet, for WhatsApp, Telegram, Signal or any app that takes text (redix-app #83).
  Future<void> shareText(String text) => SharePlus.instance.share(ShareParams(text: text));

  /// Hands [bytes], named [name], to the phone's share sheet, for WhatsApp or email with the file attached (FR-48).
  Future<void> shareFile(Uint8List bytes, String name, String mimeType) async {
    await SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: mimeType)], fileNameOverrides: [name]));
  }

  /// Keeps [bytes], named [name], in the phone's Download folder through Android's downloads store, which writes a new file every time: one of the same name already there is left whole, and the new one is numbered (FR-48).
  Future<void> saveFile(Uint8List bytes, String name, String mimeType) =>
      FileSaver.instance.saveToDownloads(name: name, bytes: bytes, includeExtension: false, mimeType: MimeType.custom, customMimeType: mimeType);

  /// Opens the phone's files for any file, kept as it is: a project's document (UC-064).
  Future<PickedFile> fromAnyFile() async {
    try {
      final picked = await FilePicker.pickFile(type: FileType.any);
      if (picked == null) {
        return PickedFile.none();
      }
      return PickedFile.read(picked.name, picked.path ?? '', await picked.readAsBytes());
    } on Exception catch (error) {
      debugPrint('File not read: $error');
      return PickedFile.failed('attachments.unreadable');
    }
  }

  /// Opens the phone's files for a picture or a PDF; a picture comes back under 1 MB.
  Future<PickedFile> fromFiles() async {
    try {
      final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf']);
      if (picked == null) {
        return PickedFile.none();
      }
      return await _kept(PickedFile.read(picked.name, picked.path ?? '', await picked.readAsBytes()));
    } on Exception catch (error) {
      debugPrint('File not read: $error');
      return PickedFile.failed('attachments.unreadable');
    }
  }
}
