/// The entry an invoice number repeats, as the API answers it (FR-17). One in a project the signed-in user cannot read says only that it exists.
class EarlierEntry {
  /// The entry the API describes in [json].
  EarlierEntry.fromJson(Map<String, dynamic> json)
    : isVisible = json['isVisible'] as bool,
      projectName = json['projectName'] as String,
      invoiceDate = DateTime.parse(json['invoiceDate'] as String),
      total = (json['total'] as num).toDouble();

  /// Whether the signed-in user can read its project, and so whether the rest says anything.
  final bool isVisible;

  /// The project it is in.
  final String projectName;

  /// The invoice's date.
  final DateTime invoiceDate;

  /// The invoice's total.
  final double total;
}
