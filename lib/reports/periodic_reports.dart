import '../api_list.dart';
import '../api_object.dart';
import '../auth/session.dart';

/// A periodic report issued.
class PeriodicReportRow {
  /// A row as the API answers it.
  PeriodicReportRow.fromJson(Map<String, dynamic> json) : number = json['number'] as int, issuedAt = DateTime.parse(json['issuedAt'] as String), expenses = (json['expenses'] as num).toDouble();

  /// Its number.
  final int number;

  /// When it was issued.
  final DateTime issuedAt;

  /// Its expenses.
  final double expenses;
}

/// A project's periodic reports, newest first (UC-053), and the way to issue the next.
class PeriodicReports extends ApiList<PeriodicReportRow> {
  /// The reports of the project [projectId], seen through [session].
  PeriodicReports(Session session, this.projectId) : super(session, '/projects/$projectId/periodic-reports', 'reports', PeriodicReportRow.fromJson);

  /// The project.
  final String projectId;

  /// Issues the next report. Returns an empty string once issued, otherwise the word key of the refusal.
  Future<String> issue() => change('/projects/$projectId/periodic-reports', {});
}

/// What the next report takes: its number, and what waits for approval, which it shows as one line.
class NextReportFigures {
  /// The figures as the API answers them.
  NextReportFigures.fromJson(Map<String, dynamic> json) : number = json['number'] as int, pendingCount = json['pendingCount'] as int, pendingAmount = (json['pendingAmount'] as num).toDouble();

  /// Nothing yet.
  NextReportFigures.none() : number = 1, pendingCount = 0, pendingAmount = 0;

  /// Its number.
  final int number;

  /// How many entries wait.
  final int pendingCount;

  /// What they come to.
  final double pendingAmount;
}

/// What a project's next report takes.
class NextReport extends ApiObject<NextReportFigures> {
  /// The next report of the project [projectId], seen through [session].
  NextReport(Session session, String projectId) : super(session, '/projects/$projectId/periodic-reports/next', 'reports', (json) => NextReportFigures.fromJson(json! as Map<String, dynamic>), NextReportFigures.none());
}

/// A label and an amount of a report.
class ReportLine {
  /// The line [label] of [amount].
  const ReportLine(this.label, this.amount);

  /// What it is.
  final String label;

  /// How much.
  final double amount;
}

/// A partner's line in a report.
class ReportPartner {
  /// A line as the API answers it.
  ReportPartner.fromJson(Map<String, dynamic> json) : name = json['name'] as String, balance = (json['balance'] as num).toDouble(), sharePercent = (json['sharePercent'] as num).toDouble();

  /// Their name.
  final String name;

  /// Their capital.
  final double balance;

  /// Their share.
  final double sharePercent;
}

/// A periodic report as it was issued.
class PeriodicReportFigures {
  /// The report as the API answers it.
  PeriodicReportFigures.fromJson(Map<String, dynamic> json)
    : number = json['number'] as int,
      issuedAt = DateTime.parse(json['issuedAt'] as String),
      accounts = [for (final row in json['accounts'] as List<dynamic>) ReportLine((row as Map<String, dynamic>)['name'] as String, (row['balance'] as num).toDouble())],
      accountsTotal = (json['accountsTotal'] as num).toDouble(),
      previousExpenses = (json['previousExpenses'] as num).toDouble(),
      expenses = (json['expenses'] as num).toDouble(),
      expensesDifference = (json['expensesDifference'] as num).toDouble(),
      capital = (json['capital'] as num).toDouble(),
      vatRefunds = (json['vatRefunds'] as num).toDouble(),
      sales = (json['sales'] as num).toDouble(),
      revenue = (json['revenue'] as num).toDouble(),
      revenueWithoutSales = (json['revenueWithoutSales'] as num).toDouble(),
      categories = [for (final row in json['categories'] as List<dynamic>) ReportLine((row as Map<String, dynamic>)['name'] as String, (row['total'] as num).toDouble())],
      surplus = (json['surplus'] as num).toDouble(),
      surplusWithoutSales = (json['surplusWithoutSales'] as num).toDouble(),
      liquidation = (json['liquidation'] as num).toDouble(),
      reconciliationDifference = (json['reconciliationDifference'] as num).toDouble(),
      pendingCount = json['pendingCount'] as int,
      pendingAmount = (json['pendingAmount'] as num).toDouble(),
      capitalTotal = (json['capitalTotal'] as num).toDouble(),
      partners = [for (final row in json['partners'] as List<dynamic>) ReportPartner.fromJson(row as Map<String, dynamic>)];

  /// Nothing yet.
  PeriodicReportFigures.none()
    : number = 0,
      issuedAt = DateTime(1),
      accounts = const [],
      accountsTotal = 0,
      previousExpenses = 0,
      expenses = 0,
      expensesDifference = 0,
      capital = 0,
      vatRefunds = 0,
      sales = 0,
      revenue = 0,
      revenueWithoutSales = 0,
      categories = const [],
      surplus = 0,
      surplusWithoutSales = 0,
      liquidation = 0,
      reconciliationDifference = 0,
      pendingCount = 0,
      pendingAmount = 0,
      capitalTotal = 0,
      partners = const [];

  /// Its number.
  final int number;

  /// When it was issued.
  final DateTime issuedAt;

  /// Each account's real balance.
  final List<ReportLine> accounts;

  /// Their total.
  final double accountsTotal;

  /// The previous report's expenses.
  final double previousExpenses;

  /// Its expenses.
  final double expenses;

  /// The difference (BR-09).
  final double expensesDifference;

  /// Partners' capital.
  final double capital;

  /// VAT refunded.
  final double vatRefunds;

  /// Sales.
  final double sales;

  /// All revenue.
  final double revenue;

  /// All revenue but sales.
  final double revenueWithoutSales;

  /// Each category's total.
  final List<ReportLine> categories;

  /// The surplus.
  final double surplus;

  /// The surplus without sales.
  final double surplusWithoutSales;

  /// What was distributed at closing.
  final double liquidation;

  /// The reconciliation difference.
  final double reconciliationDifference;

  /// How many entries waited.
  final int pendingCount;

  /// What they came to.
  final double pendingAmount;

  /// All partners' capital.
  final double capitalTotal;

  /// The partner lines the reader may see.
  final List<ReportPartner> partners;
}

/// One periodic report, as it was issued.
class PeriodicReport extends ApiObject<PeriodicReportFigures> {
  /// The report [number] of the project [projectId], seen through [session].
  PeriodicReport(Session session, String projectId, int number)
    : super(session, '/projects/$projectId/periodic-reports/$number', 'reports', (json) => PeriodicReportFigures.fromJson(json! as Map<String, dynamic>), PeriodicReportFigures.none());
}
