import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../auth/session.dart';
import '../words/words.dart';

/// Opens a file a project keeps (row 92 of the findings, AC-18.1): a picture to zoom into, or a PDF handed to the phone's own viewer.
class AttachmentScreen extends StatefulWidget {
  /// The file [attachmentId] of the project [projectId], holding [contentType], read through [session].
  const AttachmentScreen({super.key, required this.projectId, required this.attachmentId, required this.contentType, required this.session});

  /// The address of the screen.
  static const path = '/projects/:projectId/attachments/:attachmentId';

  /// The address of the file [attachmentId] of the project [projectId].
  static String pathOf(String projectId, String attachmentId) => '/projects/$projectId/attachments/$attachmentId';

  /// The picture.
  static const pictureKey = Key('attachment.picture');

  /// The line saying the file could not be read.
  static const failedKey = Key('attachment.failed');

  /// The button handing a PDF to the phone.
  static const openPdfKey = Key('attachment.openPdf');

  /// The project.
  final String projectId;

  /// The file.
  final String attachmentId;

  /// What it is.
  final String contentType;

  /// How it is read.
  final Session session;

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
          return InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(bytes, key: AttachmentScreen.pictureKey)));
        },
      ),
    );
  }
}
