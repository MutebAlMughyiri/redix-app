import '../api_list.dart';
import '../auth/session.dart';
import 'entry_row.dart';
import 'opened_entry.dart';

/// A project's entries, newest first (UC-037): everyone who reads the project sees them all, and only their own drafts. A row's swipe deletes one here (UC-033); what is done to an
/// entry opened on its own page is [OpenedEntry]'s (findings row 201).
class ProjectEntries extends ApiList<EntryRow> {
  /// The entries of the project [projectId], seen through [session].
  ProjectEntries(Session session, this.projectId) : super(session, '/projects/$projectId/entries', 'entries', EntryRow.fromJson);

  /// The project these belong to.
  final String projectId;

  /// Deletes an entry never approved. Returns an empty string once deleted, otherwise the word key of the refusal.
  Future<String> delete(EntryRow entry) => change('/projects/$projectId/entries/${entry.id}/delete', {});
}
