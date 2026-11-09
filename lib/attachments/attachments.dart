import 'package:flutter/foundation.dart';

import '../api.dart';
import '../auth/session.dart';
import 'attachment.dart';
import 'picked_file.dart';
import 'file_kind.dart';

/// Keeps a project's files on the API (UC-021), for an entry or a contract to name.
class Attachments {
  /// The files of the project [projectId], kept through [_session].
  Attachments(this._session, this.projectId);

  final Session _session;

  /// The project these files belong to.
  final String projectId;

  var _kept = Attachment.none();

  /// The attachment the last [keep] made; none when it made none.
  Attachment get kept => _kept;

  /// The file [attachmentId] as it was kept, under the name it was kept with (findings row 185), to show an entry as it was filled (redix-app #90); none when it cannot
  /// be read.
  Future<PickedFile> read(String attachmentId) async {
    try {
      final response = await _session.read('/projects/$projectId/attachments/$attachmentId', file: true);
      final isPdf = FileKind.of(response.headers['content-type'] ?? '') == FileKind.pdf;
      return response.statusCode == 200 ? PickedFile(_nameOf(response.headers, isPdf ? 'file.pdf' : 'file.jpg'), '', response.bodyBytes) : PickedFile.none();
    } on Exception catch (error) {
      debugPrint('File not read: $error');
      return PickedFile.none();
    }
  }

  /// The file's name as the API's answer gives it in `Content-Disposition`, the encoded `filename*` first so an Arabic name survives; [fallback] when it gives none.
  static String _nameOf(Map<String, String> headers, String fallback) {
    final disposition = headers['content-disposition'] ?? '';
    final encoded = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false).firstMatch(disposition);
    final plain = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return encoded != null ? Uri.decodeComponent(encoded.group(1)!) : plain?.group(1) ?? fallback;
  }

  /// Sends an entry's [file], a picture or a PDF, to the API. Returns an empty string once kept, otherwise the word key of the refusal.
  Future<String> keep(PickedFile file) => _keep('/projects/$projectId/attachments', file);

  /// Sends a document's [file], any file, to the API (findings row 138). Returns an empty string once kept, otherwise the word key of the refusal.
  Future<String> keepDocument(PickedFile file) => _keep('/projects/$projectId/attachments/document', file);

  Future<String> _keep(String path, PickedFile file) async {
    _kept = Attachment.none();
    try {
      final response = await _session.postFile(path, file.name, file.bytes);
      final answer = answerOf(response);
      if (response.statusCode >= 300) {
        return refusalOf(answer, 'attachments');
      }
      _kept = Attachment.fromJson(answer);
      return '';
    } on Exception catch (error) {
      debugPrint('File not kept: $error');
      return 'attachments.noConnection';
    }
  }
}
