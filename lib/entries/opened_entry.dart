import '../api_object.dart';
import '../auth/session.dart';
import 'entry_row.dart';

/// The entry a screen opened, as the lists show it, read by its id (findings row 201): where it stands and what can be done to it, whichever list opened it and whether that
/// list still holds it. What is done to it here reads it again (UC-028, UC-035).
class OpenedEntry extends ApiObject<EntryRow> {
  /// The entry of the project [projectId] a screen opens, seen through [session]; none until [open] names one.
  OpenedEntry(Session session, this.projectId) : super(session, '', 'entries', _rowOf, EntryRow.none());

  /// The project it belongs to.
  final String projectId;

  /// Reads the entry [entryId], showing none until it answers, so an entry opened before never shows in its place.
  Future<void> open(String entryId) {
    show(EntryRow.none());
    pointAt('/projects/$projectId/entries/$entryId/row');
    return load();
  }

  /// Sends it, a draft or a rejected entry, for approval. Returns an empty string once sent, otherwise the word key of the refusal.
  Future<String> send() => change('/projects/$projectId/entries/${value.id}/submit', {});

  /// Removes it, an approved entry, softly (redix-api #119). Returns an empty string once removed, otherwise the word key of the refusal.
  Future<String> remove() => deleteAt('/projects/$projectId/entries/${value.id}');

  /// Brings it back once removed, the undo of [remove] (redix-api #119). Returns an empty string once back, otherwise the word key of the refusal.
  Future<String> restore() => change('/projects/$projectId/entries/${value.id}/restore', {});

  static EntryRow _rowOf(Object? json) => EntryRow.fromJson(json! as Map<String, dynamic>);
}
