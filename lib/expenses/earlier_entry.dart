/// The entry an invoice number repeats, in a project the signed-in user can read, as the API answers it (AC-17.1).
class EarlierEntry {
  /// The entry the API describes in [json].
  EarlierEntry.fromJson(Map<String, dynamic> json)
    : projectName = json['projectName'] as String,
      invoiceDate = DateTime.parse(json['invoiceDate'] as String),
      total = (json['total'] as num).toDouble();

  /// The project it is in.
  final String projectName;

  /// The invoice's date.
  final DateTime invoiceDate;

  /// The invoice's total.
  final double total;
}
