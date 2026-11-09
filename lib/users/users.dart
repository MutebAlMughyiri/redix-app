import '../api_list.dart';
import '../auth/session.dart';
import '../format/number_format.dart';
import '../auth/permission.dart';
import 'user.dart';

/// The people of one project, and the one way to change them. Each change returns an empty string once made, otherwise the word key of the refusal.
class Users extends ApiList<User> {
  /// The people of the project [projectId], seen through [session].
  Users(Session session, this.projectId) : super(session, '/projects/$projectId/users', 'users', User.fromJson);

  /// The project these people belong to.
  final String projectId;

  /// Creates a login in this project holding [permissions], called [roleName] there, who must change [temporaryPassword] at first sign-in.
  Future<String> create(String displayName, String username, String roleName, String mobile, String temporaryPassword, Set<Permission> permissions) => change('/projects/$projectId/users', {
    'displayName': displayName,
    'username': username,
    'roleName': roleName,
    'mobile': westernDigits(mobile),
    'temporaryPassword': temporaryPassword,
    'permissions': [for (final permission in permissions) permission.name],
  });

  /// Adds someone who already has a login to this project, by their exact [username].
  Future<String> addExisting(String username) => change('/projects/$projectId/users/existing', {'username': username});

  /// Changes the name and mobile of [user], then what they are called in this project, [roleName] (Muteb, 9 Nov 2026). Returns the first refusal.
  Future<String> edit(User user, String displayName, String mobile, String roleName) async {
    final refusal = await change('/users/${user.id}', {'displayName': displayName, 'mobile': westernDigits(mobile)});
    return refusal.isEmpty ? change('/projects/$projectId/users/${user.id}/role-name', {'roleName': roleName}) : refusal;
  }

  /// Sets a new temporary password for [user], who is signed out everywhere.
  Future<String> resetPassword(User user, String temporaryPassword) =>
      change('/users/${user.id}/reset-password', {'temporaryPassword': temporaryPassword});

  /// Disables [user], who is signed out at their next request.
  Future<String> disable(User user) => change('/users/${user.id}/disable', {});

  /// Lets the disabled [user] sign in again.
  Future<String> enable(User user) => change('/users/${user.id}/enable', {});

  /// Gives [user] the [permission] in this project.
  Future<String> give(User user, Permission permission) => change('/projects/$projectId/users/${user.id}/permissions/${permission.name}', {});

  /// Takes the [permission] in this project from [user]; taking [Permission.readProject] takes them out of it.
  Future<String> take(User user, Permission permission) => change('/projects/$projectId/users/${user.id}/permissions/${permission.name}/remove', {});
}
