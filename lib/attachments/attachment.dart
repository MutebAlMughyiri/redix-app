/// A picture or a PDF the API keeps for a project, as it answers it.
class Attachment {
  /// The attachment the API describes in [json].
  Attachment.fromJson(Map<String, dynamic> json) : id = json['id'] as String, fileName = json['fileName'] as String,
      contentType = json['contentType'] as String? ?? '';

  /// No attachment, for a file not kept yet.
  Attachment.none() : contentType = '', id = '', fileName = '';

  /// The attachment's id; empty for none.
  final String id;

  /// The file's name.
  final String fileName;

  /// What the file is.
  final String contentType;
}
