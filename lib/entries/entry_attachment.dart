import '../format/date_format.dart';
import 'entry_attachment_role.dart';

/// A file an entry holds, as its page lists it (redix-app #115, AC-46.10g): what it is to the entry, its name and type, which open it, and when it was sent.
class EntryAttachment {
  /// A file as `GET /projects/{id}/entries/{entryId}` answers it under `attachments`.
  EntryAttachment.fromJson(Map<String, dynamic> json)
    : attachmentId = json['attachmentId'] as String,
      role = EntryAttachmentRole.values.byName(json['role'] as String),
      fileName = json['fileName'] as String,
      contentType = json['contentType'] as String,
      uploadedAt = momentOf(json['uploadedAt'] as String);

  /// The file's id.
  final String attachmentId;

  /// What it is to the entry.
  final EntryAttachmentRole role;

  /// Its name, which the phone shows once it is handed over.
  final String fileName;

  /// What it is: a picture opens to zoom into, anything else is handed to the phone.
  final String contentType;

  /// When it was sent.
  final DateTime uploadedAt;
}
