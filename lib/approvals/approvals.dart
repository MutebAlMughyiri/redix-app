import '../api_list.dart';
import '../auth/session.dart';
import 'pending_approval.dart';

/// What waits for a decision in a project (UC-031), and the way to decide it (UC-032).
class Approvals extends ApiList<PendingApproval> {
  /// The inbox of the project [projectId], seen through [session].
  Approvals(Session session, this.projectId) : super(session, '/projects/$projectId/entries/pending', 'approvals', PendingApproval.fromJson);

  /// The project whose entries these are.
  final String projectId;

  /// What the last [approve] could not approve, by id, with the word key of why.
  Map<String, String> get failed => {
    for (final failure in lastAnswer['failed'] as List<dynamic>? ?? const <dynamic>[])
      (failure as Map<String, dynamic>)['entryId'] as String: 'approvals.${failure['code'] as String}',
  };

  /// Approves the entries [ids]. Returns an empty string once asked, otherwise the word key of the refusal; [failed] says what could not go.
  Future<String> approve(Iterable<String> ids) => change('/projects/$projectId/entries/approve', {'entryIds': ids.toList()});


  /// Rejects the entry [id], saying [reason]. Returns an empty string once rejected, otherwise the word key of the refusal.
  Future<String> reject(String id, String reason) => change('/projects/$projectId/entries/$id/reject', {'reason': reason});
}
