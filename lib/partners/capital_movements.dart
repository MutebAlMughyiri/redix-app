import '../api_list.dart';
import '../auth/session.dart';
import 'capital_movement.dart';

/// One partner's movements, newest first (UC-044).
class CapitalMovements extends ApiList<CapitalMovement> {
  /// The movements of the partner [partnerId] in the project [projectId], seen through [session].
  CapitalMovements(Session session, this.projectId, String partnerId) : super(session, '/projects/$projectId/partners/$partnerId/movements', 'capital', CapitalMovement.fromJson);

  /// The project.
  final String projectId;

  /// Removes [movement], an approved one, softly (redix-api #119). Returns an empty string once removed, otherwise the word key of the refusal.
  Future<String> remove(CapitalMovement movement) => deleteAt('/projects/$projectId/entries/${movement.id}', wordPrefix: 'entries');

  /// Brings [movement] back once removed, the undo of [remove]. Returns an empty string once back, otherwise the word key of the refusal.
  Future<String> restore(CapitalMovement movement) => change('/projects/$projectId/entries/${movement.id}/restore', {}, wordPrefix: 'entries');
}
