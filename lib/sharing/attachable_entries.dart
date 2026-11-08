import '../api_list.dart';
import '../auth/session.dart';
import '../expenses/invoice_qr.dart';
import 'attachable_entry.dart';
import '../format/date_format.dart';

/// What in one item of a project can take a shared invoice (UC-039), and the way to put it there.
class AttachableEntries extends ApiList<AttachableEntry> {
  /// The expenses of the project [projectId], seen through [session].
  AttachableEntries(Session session, this.projectId) : super(session, '/projects/$projectId/entries/attachable', 'share', AttachableEntry.fromJson);

  /// The project.
  final String projectId;

  /// Reads what the item [itemId] holds, marking what matches [qr].
  Future<void> findIn(String itemId, InvoiceQr qr) {
    pointAt(
      Uri(
        path: '/projects/$projectId/entries/attachable',
        queryParameters: {'itemId': itemId, 'vatNumber': qr.vatNumber, 'total': '${qr.total}', 'date': apiDate(qr.issuedAt)},
      ).toString(),
    );
    return load();
  }

  /// Puts the file [attachmentId] on [entry], and changes nothing else (D15). Returns an empty string once attached, otherwise the word key of the refusal.
  Future<String> attach(AttachableEntry entry, String attachmentId) => change('/projects/$projectId/entries/${entry.id}/invoice', {'attachmentId': attachmentId});
}
