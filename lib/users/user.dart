/// A user as the API answers them. The rules live in the API; the app only draws what it is told.
class User {
  /// The user the API describes in [json].
  User.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      username = json['username'] as String,
      displayName = json['displayName'] as String,
      mobile = json['mobile'] as String,
      isOwner = json['isOwner'] as bool,
      isActive = json['isActive'] as bool;

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
}
