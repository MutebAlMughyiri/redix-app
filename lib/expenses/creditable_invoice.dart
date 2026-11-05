/// An invoice a credit note can return, as the API answers it, or none.
class CreditableInvoice {
  /// The invoice the API describes in [json].
  CreditableInvoice.fromJson(Map<String, dynamic> json)
    : entryId = json['entryId'] as String,
      number = json['number'] as String,
      invoiceDate = DateTime.parse(json['invoiceDate'] as String),
      returnable = (json['returnable'] as num).toDouble(),
      vatRate = (json['vatRate'] as num).toDouble();

  /// No invoice: a credit note not linked to one.
  CreditableInvoice.none() : entryId = '', number = '', invoiceDate = DateTime(1900), returnable = 0, vatRate = 0;

  /// The invoice's entry; empty for none.
  final String entryId;

  /// The invoice's number.
  final String number;

  /// The invoice's date.
  final DateTime invoiceDate;

  /// What is left of its total, after the credit notes that already name it.
  final double returnable;

  /// The rate it was computed at, as a fraction, which its credit note follows.
  final double vatRate;

  /// Whether this is no invoice at all.
  bool get isNone => entryId.isEmpty;
}
