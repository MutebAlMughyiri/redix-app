import '../api_list.dart';
import '../auth/session.dart';
import 'role.dart';
import 'user.dart';

/// The people of one project, or every login while [projectId] is empty, and the one way to change them. Each change returns an empty string once made, otherwise
/// the word key of the refusal.
class Users extends ApiList<User> {
  /// The users seen through [session]: those of the project [projectId], or every login.
  Users(Session session, {this.projectId = ''}) : super(session, projectId.isEmpty ? '/users' : '/projects/$projectId/users', 'users', User.fromJson);

  /// The project these people belong to; empty for every login.
  final String projectId;

  /// True for a project's people, whom its manager adds and gives roles.
  bool get isOfAProject => projectId.isNotEmpty;

  /// Creates a login in this project, who must change [temporaryPassword] at first sign-in.
  Future<String> create(String displayName, String username, String mobile, String temporaryPassword) =>
      change('/projects/$projectId/users', {'displayName': displayName, 'username': username, 'mobile': mobile, 'temporaryPassword': temporaryPassword});

  /// Adds someone who already has a login to this project, by their exact [username].
  Future<String> addExisting(String username) => change('/projects/$projectId/users/existing', {'username': username});

  /// Changes the name and mobile of [user].
  Future<String> edit(User user, String displayName, String mobile) => change('/users/${user.id}', {'displayName': displayName, 'mobile': mobile});

  /// Sets a new temporary password for [user], who is signed out everywhere.
  Future<String> resetPassword(User user, String temporaryPassword) =>
      change('/users/${user.id}/reset-password', {'temporaryPassword': temporaryPassword});

  /// Disables [user], who is signed out at their next request.
  Future<String> disable(User user) => change('/users/${user.id}/disable', {});

  /// Lets the disabled [user] sign in again.
  Future<String> enable(User user) => change('/users/${user.id}/enable', {});

  /// Gives [user] the [role] in this project.
  Future<String> give(User user, Role role) => change('/projects/$projectId/users/${user.id}/roles/${role.id}', {});

  /// Takes the [role] in this project from [user]; their last role takes them out of it.
  Future<String> take(User user, Role role) => change('/projects/$projectId/users/${user.id}/roles/${role.id}/remove', {});
}
