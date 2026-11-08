import '../api.dart';
import '../attachments/invoice_capture.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../words/words.dart';
import 'entry_kind.dart';
import 'entry_link_screen.dart';
import 'entry_row.dart';
import 'project_entries.dart';

/// An entry as text for any app the phone shares to, ending in its link (redix-app #83): the one owner of that text and that link, for every kind.
abstract final class EntryShare {
  /// The link that opens [entry] of the project [projectId] in REDIX (R6).
  static String linkOf(String projectId, EntryRow entry) => 'https://$linkHost${EntryLinkScreen.pathOf(projectId, entry.id)}';

  /// [entry] of [project] as lines in the app's language, its money and date as the app shows them, then its link (R3, R4, R10).
  static String textOf(Project project, EntryRow entry, Words words) => [
    '${words.text(entry.kind.wordKey)} · ${project.name}',
    if (entry.partnerName.isNotEmpty) '${words.entrySharePartner}: ${entry.partnerName}' else '${words.entryShareItem}: ${entry.itemName}',
    if (entry.supplierName.isNotEmpty) '${entry.kind == EntryKind.contractorPayment ? words.entryShareContractor : words.entryShareSupplier}: ${entry.supplierName}',
    '${words.entryShareAmount}: ${formatMoney(entry.amount)}',
    '${words.entryShareDate}: ${formatDate(entry.date)}',
    '${words.entryShareStatus}: ${words.text(entry.statusWordKey)}',
    if (entry.accountName.isNotEmpty) '${words.entryShareAccount}: ${entry.accountName}',
    if (entry.paymentMethodName.isNotEmpty) '${words.entrySharePaymentMethod}: ${entry.paymentMethodName}',
    '${words.entryShareAuthor}: ${entry.authorName}',
    if (entry.notes.isNotEmpty) '${words.entryShareNotes}: ${entry.notes}',
    linkOf(project.id, entry),
  ].join('\n');

  /// Hands [entry]'s text, and nothing else, to the phone's share sheet through [capture] (R2, R5).
  static Future<void> share(InvoiceCapture capture, Project project, EntryRow entry, Words words) => capture.shareText(textOf(project, entry, words));

  /// Reads [entries] again and shares the entry [entryId] among them: what the message after saving offers (R1). An entry the list does not hold shares nothing.
  static Future<void> shareSaved(InvoiceCapture capture, Project project, ProjectEntries entries, String entryId, Words words) async {
    await entries.load();
    for (final entry in entries.all.where((row) => row.id == entryId)) {
      await share(capture, project, entry, words);
    }
  }
}
