/// Someone in a project, as a person choosing among them sees them.
class Member {
  /// The member the API describes in [json].
  Member.fromJson(Map<String, dynamic> json) : id = json['id'] as String, displayName = json['displayName'] as String;

  /// The user's id.
  final String id;

  /// The user's name.
  final String displayName;
}
