/// A partner in a project, as the API answers them.
class Partner {
  /// The partner the API describes in [json].
  Partner.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      userId = json['userId'] as String,
      userName = json['userName'] as String,
      itemId = json['itemId'] as String,
      itemName = json['itemName'] as String;

  /// No partner yet, for the dialog that adds one.
  Partner.none() : id = '', name = '', userId = '', userName = '', itemId = '', itemName = '';

  /// The partner's id; empty for a partner not added yet.
  final String id;

  /// The partner's name, as it was typed.
  final String name;

  /// The login whose capital this is, so that person sees it as their own; empty for a partner with no login.
  final String userId;

  /// That login's name; empty for a partner with no login.
  final String userName;

  /// The capital item whose table they are (redix-api #109); empty for a partner not added yet.
  final String itemId;

  /// That item's name.
  final String itemName;
}
