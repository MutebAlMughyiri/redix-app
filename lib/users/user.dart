import '../auth/permission.dart';

/// A person in a project, as the API answers them. The rules live in the API; the app only draws what it is told.
class User {
  /// The user the API describes in [json].
  User.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      username = json['username'] as String,
      displayName = json['displayName'] as String,
      mobile = json['mobile'] as String,
      isActive = json['isActive'] as bool,
      roleName = [for (final line in (json['projects'] as List<dynamic>).cast<Map<String, dynamic>>()) line['roleName'] as String? ?? ''].firstOrNull ?? '',
      _permissions = {
        for (final line in (json['projects'] as List<dynamic>).cast<Map<String, dynamic>>()) ...(line['permissions'] as List<dynamic>).cast<String>(),
      },
      _partnerIds = {
        for (final line in (json['projects'] as List<dynamic>).cast<Map<String, dynamic>>()) ...(line['partnerIds'] as List<dynamic>).cast<String>(),
      };

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

  /// What they are called in this project (Muteb, 9 Nov 2026); empty when nothing was typed.
  final String roleName;

  /// What they may do in this project, by the API's names.
  final Set<String> _permissions;

  /// The partners chosen for them in this project, whose capital they see with [Permission.seeChosenCapital] (redix-api #106).
  final Set<String> _partnerIds;

  /// Whether the user holds [permission] in this project.
  bool holds(Permission permission) => _permissions.contains(permission.name);

  /// Whether the partner [partnerId] is chosen for the user in this project.
  bool sees(String partnerId) => _partnerIds.contains(partnerId);

  /// How many permissions the user holds in this project.
  int get permissionCount => _permissions.length;
}
