/// A role as the API answers it. Roles are data, so the app names none of them and a new one appears with no release.
class Role {
  /// The role the API describes in [json].
  Role.fromJson(Map<String, dynamic> json) : id = json['id'] as String, wordKey = json['wordKey'] as String;

  /// The role's id.
  final String id;

  /// The key of the word that names this role.
  final String wordKey;
}
