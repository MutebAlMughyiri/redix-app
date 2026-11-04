import 'role.dart';
import 'user_project.dart';

/// A user as the API answers them. The rules live in the API; the app only draws what it is told.
class User {
  /// The user the API describes in [json].
  User.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      username = json['username'] as String,
      displayName = json['displayName'] as String,
      mobile = json['mobile'] as String,
      isActive = json['isActive'] as bool,
      projects = [for (final project in json['projects'] as List<dynamic>) UserProject.fromJson(project as Map<String, dynamic>)];

  /// The user's id.
  final String id;

  /// The name the user signs in with.
  final String username;

  /// The name as it shows on entries.
  final String displayName;

  /// The user's mobile; empty when none.
  final String mobile;

  /// False once disabled.
  final bool isActive;

  /// Their roles, one line per role, in the projects the signed-in user may see.
  final List<UserProject> projects;

  /// Whether the user holds [role]; asked on a project's list, where only that project's lines come.
  bool holds(Role role) => projects.any((project) => project.role.id == role.id);
}
