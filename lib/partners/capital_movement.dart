/// One movement of a partner's capital (UC-042, UC-044).
class CapitalMovement {
  /// A movement as the API answers it.
  CapitalMovement.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = json['type'] as String,
      date = DateTime.parse(json['date'] as String),
      amount = (json['amount'] as num).toDouble(),
      description = json['description'] as String,
      cashReason = json['cashReason'] as String,
      accountName = json['accountName'] as String,
      attachmentId = json['attachmentId'] as String,
      contentType = json['contentType'] as String,
      isReversed = json['isReversed'] as bool;

  /// The entry.
  final String id;

  /// What it is, the end of its word key.
  final String type;

  /// The day it moved.
  final DateTime date;

  /// What it did to the capital: negative when it took some away.
  final double amount;

  /// What was said about it.
  final String description;

  /// Why it has no receipt; empty when it has one.
  final String cashReason;

  /// The account it moved through.
  final String accountName;

  /// Its receipt; empty when none.
  final String attachmentId;

  /// What the receipt is; empty when none.
  final String contentType;

  /// True when it was reversed, or is itself a reversal.
  final bool isReversed;
}
