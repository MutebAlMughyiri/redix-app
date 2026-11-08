import '../api_list.dart';
import '../auth/session.dart';
import 'entry_row.dart';

/// A project's entries, newest first (UC-037): everyone who reads the project sees them all, and only their own drafts. What can be done to one lives here too (UC-028, UC-033, UC-035).
class ProjectEntries extends ApiList<EntryRow> {
  /// The entries of the project [projectId], seen through [session].
  ProjectEntries(Session session, this.projectId) : super(session, '/projects/$projectId/entries', 'entries', EntryRow.fromJson);

  /// The project these belong to.
  final String projectId;

  /// Sends a draft or a rejected entry for approval. Returns an empty string once sent, otherwise the word key of the refusal.
  Future<String> send(EntryRow entry) => change('/projects/$projectId/entries/${entry.id}/submit', {});

  /// Sends revenue on a revenue item's table for approval (redix-api #101), and reads the list again; answers as [change] does, in revenue's words.
  Future<String> recordRevenue(Map<String, Object> body) => change('/projects/$projectId/revenue', body, wordPrefix: 'revenue');

  /// Deletes an entry never approved. Returns an empty string once deleted, otherwise the word key of the refusal.
  Future<String> delete(EntryRow entry) => change('/projects/$projectId/entries/${entry.id}/delete', {});

  /// Reverses an approved entry, saying [reason]. Returns an empty string once reversed, otherwise the word key of the refusal.
  Future<String> reverse(EntryRow entry, String reason) => change('/projects/$projectId/entries/${entry.id}/reverse', {'reason': reason});
}
