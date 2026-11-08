import 'package:flutter/foundation.dart';

import '../api.dart';
import '../auth/session.dart';
import 'attachment.dart';
import 'picked_file.dart';

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

  /// Sends [file] to the API. Returns an empty string once kept, otherwise the word key of the refusal.
  Future<String> keep(PickedFile file) async {
    _kept = Attachment.none();
    try {
      final response = await _session.postFile('/projects/$projectId/attachments', file.name, file.bytes);
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
