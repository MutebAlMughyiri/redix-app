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
      vat = (json['vat'] as num).toDouble(),
      accountName = json['accountName'] as String,
      notes = json['notes'] as String,
      withoutInvoiceReason = json['withoutInvoiceReason'] as String,
      attachmentId = json['attachmentId'] as String,
      contentType = json['contentType'] as String,
      authorName = json['authorName'] as String,
      invoiceTotal = (json['invoiceTotal'] as num).toDouble(),
      sellerVatNumber = json['sellerVatNumber'] as String,
      supplierVatNumber = json['supplierVatNumber'] as String;

  /// The entry's id.
  final String id;

  /// `purchase` or `contractorPayment`.
  final String kind;

  /// Its date.
  final DateTime date;

  /// What was paid.
  final double amount;

  /// Its item.
  final String itemName;

  /// Its supplier, or the contract's contractor.
  final String supplierName;

  /// Its invoice's number; empty when it has none.
  final String invoiceNumber;

  /// Its invoice's VAT.
  final double vat;

  /// What paid it.
  final String accountName;

  /// What was noted.
  final String notes;

  /// Why it has no invoice; empty when it has one.
  final String withoutInvoiceReason;

  /// Its file; empty when it has none.
  final String attachmentId;

  /// What the file is; empty when it has none.
  final String contentType;

  /// Who entered it.
  final String authorName;

  /// Its invoice's total, which may differ from what was paid.
  final double invoiceTotal;

  /// The seller's VAT number on an invoice attached later; empty otherwise.
  final String sellerVatNumber;

  /// Its supplier's VAT number.
  final String supplierVatNumber;

  /// True when an invoice was attached that says something other than what was paid (AC-49.3).
  bool get totalDiffers => invoiceNumber.isNotEmpty && invoiceTotal != amount;

  /// True when an invoice was attached from another seller than the supplier (AC-49.3).
  bool get sellerDiffers => sellerVatNumber.isNotEmpty && sellerVatNumber != supplierVatNumber;

  /// True for a contractor's payment.
  bool get isContractorPayment => kind == 'contractorPayment';

  /// True when it has a file to open.
  bool get hasFile => attachmentId.isNotEmpty;
}
