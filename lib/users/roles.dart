import '../api_list.dart';
import '../auth/session.dart';
import 'role.dart';

/// The roles that can be given in one project, in their order, as the API lists them.
class Roles extends ApiList<Role> {
  /// The roles of the project [projectId], read through [session].
  Roles(Session session, String projectId) : super(session, '/projects/$projectId/roles', 'users', Role.fromJson);
}
