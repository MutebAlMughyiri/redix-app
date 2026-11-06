import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../auth/session.dart';
import 'invoice_capture.dart';
import '../words/words.dart';

/// Opens a file a project keeps (row 92 of the findings, AC-18.1): a picture to zoom into, a PDF handed to the phone's own viewer, or any other file handed to the phone to open (UC-064).
class AttachmentScreen extends StatefulWidget {
  /// The file [attachmentId] of the project [projectId], named [fileName] and holding [contentType], read through [session] and handed to the phone through [capture].
  const AttachmentScreen({super.key, required this.projectId, required this.attachmentId, required this.fileName, required this.contentType, required this.session, required this.capture});

  /// The address of the screen.
  static const path = '/projects/:projectId/attachments/:attachmentId';

  /// The address of the file [attachmentId] of the project [projectId], named [fileName] when the phone needs its name to open it.
  static String pathOf(String projectId, String attachmentId, {String fileName = ''}) =>
      Uri(path: '/projects/$projectId/attachments/$attachmentId', queryParameters: fileName.isEmpty ? null : {'name': fileName}).toString();

  /// The picture.
  static const pictureKey = Key('attachment.picture');

  /// The line saying the file could not be read.
  static const failedKey = Key('attachment.failed');

  /// The button handing a PDF to the phone.
  static const openPdfKey = Key('attachment.openPdf');

  /// The button handing any other file to the phone.
  static const openFileKey = Key('attachment.openFile');

  /// The project.
  final String projectId;

  /// The file.
  final String attachmentId;

  /// Its name; empty when it is a picture or a PDF, which need none.
  final String fileName;

  /// What it is.
  final String contentType;

  /// How it is read.
  final Session session;

  /// How it is handed to the phone.
  final InvoiceCapture capture;

  @override
  State<AttachmentScreen> createState() => _AttachmentScreenState();
}

class _AttachmentScreenState extends State<AttachmentScreen> {
  late final _file = _read();

  Future<Uint8List> _read() async {
    final response = await widget.session.read(AttachmentScreen.pathOf(widget.projectId, widget.attachmentId));
    return response.statusCode == 200 ? response.bodyBytes : Uint8List(0);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.approvalsOpenFile)),
      body: FutureBuilder<Uint8List>(
        future: _file,
        builder: (context, file) {
          if (file.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (file.hasError || (file.data ?? Uint8List(0)).isEmpty) {
            return Center(child: Text(words.approvalsFileFailed, key: AttachmentScreen.failedKey));
          }
          final bytes = file.requireData;
          if (widget.contentType == 'application/pdf') {
            return Center(
              child: FilledButton(key: AttachmentScreen.openPdfKey, onPressed: () => Printing.sharePdf(bytes: bytes, filename: 'invoice.pdf'), child: Text(words.approvalsOpenFile)),
            );
          }
          if (!widget.contentType.startsWith('image/')) {
            return Center(
              child: FilledButton(key: AttachmentScreen.openFileKey, onPressed: () => widget.capture.shareFile(bytes, widget.fileName, widget.contentType), child: Text(words.approvalsOpenFile)),
            );
          }
          return InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(bytes, key: AttachmentScreen.pictureKey)));
        },
      ),
    );
  }
}
