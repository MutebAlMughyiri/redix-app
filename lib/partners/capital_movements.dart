import '../api_list.dart';
import '../auth/session.dart';
import 'capital_movement.dart';

/// One partner's movements, newest first (UC-044).
class CapitalMovements extends ApiList<CapitalMovement> {
  /// The movements of the partner [partnerId] in the project [projectId], seen through [session].
  CapitalMovements(Session session, this.projectId, String partnerId) : super(session, '/projects/$projectId/partners/$partnerId/movements', 'capital', CapitalMovement.fromJson);

  /// The project.
  final String projectId;

  /// Reverses [movement], with whatever was entered with it, saying [reason]. Returns an empty string once reversed, otherwise the word key of the refusal.
  Future<String> reverse(CapitalMovement movement, String reason) => change('/projects/$projectId/entries/${movement.id}/reverse', {'reason': reason}, wordPrefix: 'entries');
}
