import '../api_list.dart';
import '../auth/session.dart';
import 'project_role.dart';
import 'user.dart';

/// The users (UC-007), and the one way to change them. Each change returns an empty string once made, otherwise the word key of the refusal.
class Users extends ApiList<User> {
  /// The users, as seen by the owner signed in through [session].
  Users(Session session) : super(session, '/users', 'users', User.fromJson);

  /// Creates a user who must change [temporaryPassword] at first sign-in.
  Future<String> create(String displayName, String username, String mobile, String temporaryPassword) =>
      change('/users', {'displayName': displayName, 'username': username, 'mobile': mobile, 'temporaryPassword': temporaryPassword});

  /// Changes the name and mobile of [user].
  Future<String> edit(User user, String displayName, String mobile) => change('/users/${user.id}', {'displayName': displayName, 'mobile': mobile});

  /// Sets a new temporary password for [user], who is signed out everywhere.
  Future<String> resetPassword(User user, String temporaryPassword) =>
      change('/users/${user.id}/reset-password', {'temporaryPassword': temporaryPassword});

  /// Disables [user], who is signed out at their next request.
  Future<String> disable(User user) => change('/users/${user.id}/disable', {});

  /// Lets the disabled [user] sign in again.
  Future<String> enable(User user) => change('/users/${user.id}/enable', {});

  /// Gives [user] the project [projectId] with [role], or changes the role they have in it.
  Future<String> assign(User user, String projectId, ProjectRole role) => change('/users/${user.id}/projects/$projectId', {'role': role.name});

  /// Takes the project [projectId] away from [user].
  Future<String> remove(User user, String projectId) => change('/users/${user.id}/projects/$projectId/remove', {});
}
