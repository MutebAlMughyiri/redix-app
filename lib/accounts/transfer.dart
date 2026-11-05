/// Money moved between two accounts (UC-040).
class Transfer {
  /// A transfer as the API answers it.
  Transfer.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      date = DateTime.parse(json['date'] as String),
      amount = (json['amount'] as num).toDouble(),
      fromAccountName = json['fromAccountName'] as String,
      toAccountName = json['toAccountName'] as String,
      description = json['description'] as String;

  /// The entry that left.
  final String id;

  /// The day it moved.
  final DateTime date;

  /// How much.
  final double amount;

  /// Where it left.
  final String fromAccountName;

  /// Where it arrived.
  final String toAccountName;

  /// What it is for.
  final String description;
}
