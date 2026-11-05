/// Money that came in other than capital (UC-047), as the API answers it.
class RevenueRow {
  /// A row as the API answers it.
  RevenueRow.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = json['type'] as String,
      date = DateTime.parse(json['date'] as String),
      amount = (json['amount'] as num).toDouble(),
      periodStart = DateTime.parse(json['periodStart'] as String),
      accountName = json['accountName'] as String,
      description = json['description'] as String,
      attachmentId = json['attachmentId'] as String,
      contentType = json['contentType'] as String,
      isReversed = json['isReversed'] as bool,
      statementRefund = (json['statementRefund'] as num).toDouble(),
      refundDifference = (json['refundDifference'] as num).toDouble(),
      buyerName = json['buyerName'] as String,
      invoiceNumber = json['invoiceNumber'] as String;

  /// The entry.
  final String id;

  /// `vatRefund`, `sale` or `other`, the end of its word key.
  final String type;

  /// The day it came in.
  final DateTime date;

  /// How much.
  final double amount;

  /// The first day of its period.
  final DateTime periodStart;

  /// The account it reached.
  final String accountName;

  /// What was said about it.
  final String description;

  /// Its file; empty when none.
  final String attachmentId;

  /// What the file is; empty when none.
  final String contentType;

  /// True when it was reversed, or is itself a reversal.
  final bool isReversed;

  /// What the statement of a refund's quarter expected back.
  final double statementRefund;

  /// What came back, less that.
  final double refundDifference;

  /// The buyer on its sales invoice; empty when it has none.
  final String buyerName;

  /// The number of its sales invoice; empty when it has none.
  final String invoiceNumber;

  /// True for a VAT refund.
  bool get isRefund => type == 'vatRefund';

  /// True for a sale with no invoice yet, which an invoice may go on.
  bool get isOpenSale => type == 'sale' && invoiceNumber.isEmpty && !isReversed;
}
