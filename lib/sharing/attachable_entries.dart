import '../api_list.dart';
import '../auth/session.dart';
import '../entries/entry_row.dart';
import '../expenses/invoice_qr.dart';
import '../format/date_format.dart';

/// The entries of a project a shared file's QR code matches (AC-49.2), which the share screen pins over its list (redix-app #115 D4, D6), and the way to put a file on an entry.
class AttachableEntries extends ApiList<EntryRow> {
  /// The entries of the project [projectId], seen through [session].
  AttachableEntries(Session session, this.projectId) : super(session, '/projects/$projectId/entries/attachable', 'share', EntryRow.fromJson);

  /// The project.
  final String projectId;

  /// Reads the entries [qr] matches; none for a file with no QR code.
  Future<void> findFor(InvoiceQr qr) async {
    if (qr.isNone) {
      show(const <EntryRow>[]);
      return;
    }
    pointAt(Uri(path: '/projects/$projectId/entries/attachable', queryParameters: {'vatNumber': qr.vatNumber, 'total': '${qr.total}', 'date': apiDate(qr.issuedAt)}).toString());
    return load();
  }

  /// Puts the file [attachmentId] on the entry [entryId], beside any it has, and changes nothing else (redix-app #115 D1, D15). Returns an empty string once attached, otherwise
  /// the word key of the refusal.
  Future<String> attach(String entryId, String attachmentId) => change('/projects/$projectId/entries/$entryId/invoice', {'attachmentId': attachmentId});
}
