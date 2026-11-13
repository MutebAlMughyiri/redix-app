/// One movement of a partner's capital (UC-042, UC-044).
class CapitalMovement {
  /// A movement as the API answers it.
  CapitalMovement.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      movementName = json['movementName'] as String,
      date = DateTime.parse(json['date'] as String),
      amount = (json['amount'] as num).toDouble(),
      description = json['description'] as String,
      accountName = json['accountName'] as String,
      attachmentId = json['attachmentId'] as String,
      contentType = json['contentType'] as String,
      fileName = json['fileName'] as String;

  /// The entry.
  final String id;

  /// What it is: the name of the choice of «نوع الحركة» it took (redix-api #129); empty when it took none.
  final String movementName;

  /// The day it moved.
  final DateTime date;

  /// What it did to the capital: negative when it took some away.
  final double amount;

  /// What was said about it.
  final String description;

  /// The account it moved through.
  final String accountName;

  /// Its receipt; empty when none.
  final String attachmentId;

  /// What the receipt is; empty when none.
  final String contentType;

  /// The receipt's name, which the phone shows once it is handed over; empty when none.
  final String fileName;
}
