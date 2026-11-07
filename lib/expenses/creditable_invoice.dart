import '../format/date_format.dart';

/// A bill a credit note can return, as the API answers it, or none yet chosen (redix-api #96, D13).
class CreditableInvoice {
  /// The bill the API describes in [json].
  CreditableInvoice.fromJson(Map<String, dynamic> json)
    : entryId = json['entryId'] as String,
      number = json['number'] as String,
      date = DateTime.parse(json['date'] as String),
      returnable = (json['returnable'] as num).toDouble();

  /// None chosen yet.
  CreditableInvoice.none() : entryId = '', number = '', date = DateTime(1900), returnable = 0;

  /// The bill's entry; empty for none.
  final String entryId;

  /// The number of an older bill that had one; empty for the rest.
  final String number;

  /// The bill's date.
  final DateTime date;

  /// What is left of its total, after the credit notes that already name it.
  final double returnable;

  /// Whether none is chosen.
  bool get isNone => entryId.isEmpty;

  /// How the bill is named: its number when it has one, otherwise its date; empty while none is chosen.
  String get label => isNone ? '' : (number.isEmpty ? formatDate(date) : number);
}
