import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../auth/session.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import 'file_kind.dart';
import 'invoice_capture.dart';
import '../words/words.dart';
import '../ui/act_once.dart';
import '../ui/screen_message.dart';

/// Opens a file a project keeps (row 92 of the findings, AC-18.1): a picture to zoom into, or any other file, a PDF included, handed to the phone by its name to open (UC-064).
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

  /// The button handing a file that is not a picture to the phone.
  static const openFileKey = Key('attachment.openFile');

  /// The file's name, over the way to open a file that is not a picture (redix-app #96).
  static const fileNameKey = Key('attachment.fileName');

  /// The spinner while the file is read.
  static const loadingKey = Key('attachment.loading');

  /// The project.
  final String projectId;

  /// The file.
  final String attachmentId;

  /// Its name, which the phone shows once it is handed over.
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
    final response = await widget.session.read(AttachmentScreen.pathOf(widget.projectId, widget.attachmentId), file: true);
    return response.statusCode == 200 ? response.bodyBytes : Uint8List(0);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.approvalsOpenFile, key: ScreenTitle.titleKey)),
      body: FutureBuilder<Uint8List>(
        future: _file,
        builder: (context, file) {
          if (file.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(key: AttachmentScreen.loadingKey));
          }
          if (file.hasError || (file.data ?? Uint8List(0)).isEmpty) {
            return ScreenMessage(words.approvalsFileFailed, textKey: AttachmentScreen.failedKey);
          }
          final bytes = file.requireData;
          if (FileKind.of(widget.contentType) != FileKind.picture) {
            return ScreenMessage(
              widget.fileName,
              textKey: AttachmentScreen.fileNameKey,
              action: ActOnce(builder: (once) => FilledButton(key: AttachmentScreen.openFileKey, onPressed: once(() => widget.capture.shareFile(bytes, widget.fileName, widget.contentType)), child: Text(words.approvalsOpenFile, key: AttachmentScreen.openFileKey.label))),
            );
          }
          return InteractiveViewer(maxScale: 6, child: Center(child: Image.memory(bytes, key: AttachmentScreen.pictureKey)));
        },
      ),
    );
  }
}
