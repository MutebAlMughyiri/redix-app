import 'role.dart';

/// One role a user holds in one project.
class UserProject {
  /// The line the API describes in [json].
  UserProject.fromJson(Map<String, dynamic> json)
    : projectId = json['projectId'] as String,
      name = json['name'] as String,
      role = Role.fromJson(json['role'] as Map<String, dynamic>);

  /// The project's id.
  final String projectId;

  /// The project's name.
  final String name;

  /// The role.
  final Role role;
}
