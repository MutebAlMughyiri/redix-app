import '../api_object.dart';
import '../auth/session.dart';

/// One purchase invoice of the statement.
class VatPurchaseRow {
  /// A row as the API answers it.
  VatPurchaseRow.fromJson(Map<String, dynamic> json)
    : row = json['row'] as int,
      entryId = json['entryId'] as String,
      date = DateTime.parse(json['date'] as String),
      companyName = json['companyName'] as String,
      description = json['description'] as String,
      total = (json['total'] as num).toDouble(),
      isCreditNote = json['isCreditNote'] as bool;

  /// Its line.
  final int row;

  /// The entry.
  final String entryId;

  /// The invoice's date.
  final DateTime date;

  /// The supplier.
  final String companyName;

  /// What it was, who from, and the number.
  final String description;

  /// Its total.
  final double total;

  /// True for a credit note.
  final bool isCreditNote;
}

/// One quarter of the statement, its totals as the API added them.
class VatQuarter {
  /// A quarter as the API answers it.
  VatQuarter.fromJson(Map<String, dynamic> json)
    : start = DateTime.parse(json['start'] as String),
      end = DateTime.parse(json['end'] as String),
      purchases = [for (final row in json['purchases'] as List<dynamic>) VatPurchaseRow.fromJson(row as Map<String, dynamic>)],
      salesCount = (json['sales'] as List<dynamic>).length,
      purchasesAfterDiscount = (json['purchasesAfterDiscount'] as num).toDouble(),
      purchasesVat = (json['purchasesVat'] as num).toDouble(),
      purchasesTotal = (json['purchasesTotal'] as num).toDouble(),
      salesVat = (json['salesVat'] as num).toDouble(),
      realEstateTax = (json['realEstateTax'] as num).toDouble(),
      netDue = (json['netDue'] as num).toDouble();

  /// Its first day.
  final DateTime start;

  /// Its last day.
  final DateTime end;

  /// Its purchase invoices.
  final List<VatPurchaseRow> purchases;

  /// How many sales invoices it holds.
  final int salesCount;

  /// The purchases before VAT, after the discount.
  final double purchasesAfterDiscount;

  /// The purchases' VAT.
  final double purchasesVat;

  /// The purchases with VAT.
  final double purchasesTotal;

  /// The sales' VAT.
  final double salesVat;

  /// The sales' real estate transaction tax.
  final double realEstateTax;

  /// Sales VAT less purchases VAT; negative when it is refunded.
  final double netDue;

  /// Its number in its year, 1 to 4.
  int get number => (start.month - 1) ~/ 3 + 1;
}

/// Something left out of the statement, or that needs a look.
class VatException {
  /// An exception as the API answers it.
  VatException.fromJson(Map<String, dynamic> json)
    : reason = json['reason'] as String,
      entryId = json['entryId'] as String,
      date = DateTime.parse(json['date'] as String),
      companyName = json['companyName'] as String,
      invoiceNumber = json['invoiceNumber'] as String,
      amount = (json['amount'] as num).toDouble();

  /// Why, the end of its word key.
  final String reason;

  /// The entry.
  final String entryId;

  /// Its date.
  final DateTime date;

  /// The supplier.
  final String companyName;

  /// The invoice's number; empty when it has none.
  final String invoiceNumber;

  /// Its total.
  final double amount;
}

/// A VAT statement.
class VatStatementFigures {
  /// A statement as the API answers it.
  VatStatementFigures.fromJson(Map<String, dynamic> json)
    : quarters = [for (final row in json['quarters'] as List<dynamic>) VatQuarter.fromJson(row as Map<String, dynamic>)],
      exceptions = [for (final row in json['exceptions'] as List<dynamic>) VatException.fromJson(row as Map<String, dynamic>)];

  /// Nothing yet.
  VatStatementFigures.none() : quarters = const [], exceptions = const [];

  /// A section per quarter.
  final List<VatQuarter> quarters;

  /// What was left out, or needs a look.
  final List<VatException> exceptions;
}

/// A project's VAT statement for a period (UC-056), and the way to declare an invoice later (BR-17).
class VatStatement extends ApiObject<VatStatementFigures> {
  /// The statement of the project [projectId], seen through [session].
  VatStatement(Session session, this.projectId) : super(session, '/projects/$projectId/vat-statement', 'vat', (json) => VatStatementFigures.fromJson(json! as Map<String, dynamic>), VatStatementFigures.none());

  /// The project.
  final String projectId;

  String _isoOf(DateTime date) => date.toIso8601String().substring(0, 10);

  /// Reads the statement from [first] to [last].
  Future<void> readPeriod(DateTime first, DateTime last) {
    pointAt('/projects/$projectId/vat-statement?from=${_isoOf(first)}&to=${_isoOf(last)}');
    return load();
  }

  /// Declares the invoice of the entry [entryId] in the quarter starting [start]. Returns an empty string once declared, otherwise the word key of the refusal.
  Future<String> declareIn(String entryId, DateTime start) => change('/projects/$projectId/entries/$entryId/vat-period', {'periodStart': _isoOf(start)});
}
