import 'role.dart';

/// A person in a project, as the API answers them. The rules live in the API; the app only draws what it is told.
class User {
  /// The user the API describes in [json].
  User.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      username = json['username'] as String,
      displayName = json['displayName'] as String,
      mobile = json['mobile'] as String,
      isActive = json['isActive'] as bool,
      roles = [
        for (final line in (json['projects'] as List<dynamic>).cast<Map<String, dynamic>>()) Role.fromJson(line['role'] as Map<String, dynamic>),
      ];

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

  /// Their roles in this project.
  final List<Role> roles;

  /// Whether the user holds [role] in this project.
  bool holds(Role role) => roles.any((held) => held.id == role.id);
}
