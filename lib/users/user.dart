import 'project_role.dart';
import 'user_project.dart';

/// A user as the API answers them. The rules live in the API; the app only draws what it is told.
class User {
  /// The user the API describes in [json].
  User.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      username = json['username'] as String,
      displayName = json['displayName'] as String,
      mobile = json['mobile'] as String,
      isOwner = json['isOwner'] as bool,
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

  /// True for an owner, who can only be edited here (BR-29).
  final bool isOwner;

  /// False once disabled.
  final bool isActive;

  /// The projects the user works on, and as what; empty for an owner, who is in every project.
  final List<UserProject> projects;

  /// Whether the user has been given the project [projectId].
  bool hasProject(String projectId) => projects.any((project) => project.projectId == projectId);

  /// The user's role in the project [projectId], which they have been given.
  ProjectRole roleIn(String projectId) => projects.firstWhere((project) => project.projectId == projectId).role;
}
