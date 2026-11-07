/// An entry waiting for Finance's decision (UC-031).
class PendingApproval {
  /// An entry as the API answers it.
  PendingApproval.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      kind = json['kind'] as String,
      date = DateTime.parse(json['entryDate'] as String),
      amount = (json['amount'] as num).toDouble(),
      itemName = json['itemName'] as String,
      supplierName = json['supplierName'] as String,
      invoiceNumber = json['invoiceNumber'] as String,
      accountName = json['accountName'] as String,
      notes = json['notes'] as String,
      attachmentId = json['attachmentId'] as String,
      contentType = json['contentType'] as String,
      authorName = json['authorName'] as String;

  /// The entry's id.
  final String id;

  /// `purchase` or `contractorPayment`.
  final String kind;

  /// Its date.
  final DateTime date;

  /// Its total.
  final double amount;

  /// Its item.
  final String itemName;

  /// Its supplier, or the contract's contractor.
  final String supplierName;

  /// The number of an older bill that had one; empty for the rest.
  final String invoiceNumber;

  /// What paid it.
  final String accountName;

  /// What was noted.
  final String notes;

  /// Its file; empty when it has none.
  final String attachmentId;

  /// What the file is; empty when it has none.
  final String contentType;

  /// Who entered it.
  final String authorName;

  /// True for a contractor's payment.
  bool get isContractorPayment => kind == 'contractorPayment';

  /// True when it has a file to open.
  bool get hasFile => attachmentId.isNotEmpty;
}
