/// An expense entered without an invoice, which a shared file can go on (UC-039).
class AttachableEntry {
  /// An expense as the API answers it.
  AttachableEntry.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      status = json['status'] as String,
      date = DateTime.parse(json['entryDate'] as String),
      amount = (json['amount'] as num).toDouble(),
      description = json['description'] as String,
      supplierName = json['supplierName'] as String,
      supplierVatNumber = json['supplierVatNumber'] as String,
      isMatching = json['isMatching'] as bool;

  /// The entry's id.
  final String id;

  /// Where it stands.
  final String status;

  /// Its date.
  final DateTime date;

  /// What was paid.
  final double amount;

  /// «الوصف», what it says (redix-api #129).
  final String description;

  /// Its supplier, or the contract's contractor.
  final String supplierName;

  /// That supplier's VAT number; empty when none.
  final String supplierVatNumber;

  /// True when the invoice's QR code matches it (AC-49.2).
  final bool isMatching;

}
