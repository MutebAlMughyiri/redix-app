/// A partner in a project, as the API answers them. Their own login only says whose account they are; who sees their capital is ticked on people's permissions (redix-api #106).
class Partner {
  /// The partner the API describes in [json].
  Partner.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      userId = json['userId'] as String,
      userName = json['userName'] as String;

  /// No partner yet, for the dialog that adds one.
  Partner.none() : id = '', name = '', userId = '', userName = '';

  /// The partner's id; empty for a partner not added yet.
  final String id;

  /// The partner's name, as it was typed.
  final String name;

  /// The partner's own login; empty for a partner with no login.
  final String userId;

  /// That login's name; empty for a partner with no login.
  final String userName;
}
