import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'picked_file.dart';
import 'picture_compression.dart';

/// The phone's camera and files, as the app reaches them: the one place that touches them, so a test can stand in for hardware it does not have.
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
      return PickedFile(file.uri.pathSegments.last, file.path, await compute(compressedPicture, await file.readAsBytes()));
    } on Exception catch (error) {
      debugPrint('Camera not opened: $error');
      return PickedFile.failed('attachments.cameraFailed');
    }
  }

  /// Opens the phone's files for a picture or a PDF; a picture comes back under 1 MB.
  Future<PickedFile> fromFiles() async {
    try {
      final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf']);
      if (picked == null) {
        return PickedFile.none();
      }
      final bytes = await picked.readAsBytes();
      final file = PickedFile(picked.name, picked.path ?? '', bytes);
      return file.isPdf ? file : PickedFile(picked.name, picked.path ?? '', await compute(compressedPicture, bytes));
    } on Exception catch (error) {
      debugPrint('File not read: $error');
      return PickedFile.failed('attachments.unreadable');
    }
  }
}
