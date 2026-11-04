import 'project_role.dart';

/// A project a user works on, and as what.
class UserProject {
  /// The project the API describes in [json].
  UserProject.fromJson(Map<String, dynamic> json)
    : projectId = json['projectId'] as String,
      name = json['name'] as String,
      role = ProjectRole.values.byName(json['role'] as String);

  /// The project's id.
  final String projectId;

  /// The project's name.
  final String name;

  /// The user's role in it.
  final ProjectRole role;
}
