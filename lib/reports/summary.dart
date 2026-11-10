import '../api_object.dart';
import '../auth/session.dart';
import 'waiting_figures.dart';

/// One item's total (BR-02).
class ItemTotal {
  /// A total as the API answers it.
  ItemTotal.fromJson(Map<String, dynamic> json) : id = json['id'] as String, name = json['name'] as String, total = (json['total'] as num).toDouble();

  /// The item.
  final String id;

  /// Its name.
  final String name;

  /// Its purchases and contractor payments, its revenue, or for رأس المال what the partners put in less what they took out.
  final double total;
}

/// One category's total (BR-03), with its items'.
class CategoryTotal {
  /// A total as the API answers it.
  CategoryTotal.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      total = (json['total'] as num).toDouble(),
      items = [for (final row in json['items'] as List<dynamic>) ItemTotal.fromJson(row as Map<String, dynamic>)];

  /// The category.
  final String id;

  /// Its name.
  final String name;

  /// The sum of its items.
  final double total;

  /// What part of [sideTotal] it is, from 0 to 1; 0 while the side holds nothing.
  double shareOf(double sideTotal) => sideTotal <= 0 ? 0 : (total / sideTotal).clamp(0, 1);

  /// Each item's total.
  final List<ItemTotal> items;
}

/// A side of a project's figures: what came in or what went out (deep review, 9 Nov 2026).
enum SummarySide {
  /// The revenue, رأس المال among it.
  revenue,

  /// The expenses.
  expenses;

  /// This side's categories in [figures].
  List<CategoryTotal> categoriesOf(SummaryFigures figures) => this == revenue ? figures.revenueCategories : figures.categories;

  /// This side's total in [figures].
  double totalOf(SummaryFigures figures) => this == revenue ? figures.revenue : figures.expenses;
}

/// A project's figures at a glance (UC-049, UC-063).
class SummaryFigures {
  /// The figures as the API answers them.
  SummaryFigures.fromJson(Map<String, dynamic> json)
    : revenue = (json['revenue'] as num).toDouble(),
      expenses = (json['expenses'] as num).toDouble(),
      surplus = (json['surplus'] as num).toDouble(),
      wasReconciled = json['wasReconciled'] as bool,
      reconciliationDifference = (json['reconciliationDifference'] as num).toDouble(),
      waiting = WaitingFigures.fromJson(json['waiting'] as Map<String, dynamic>),
      completionPercent = (json['completionPercent'] as num).toDouble(),
      categories = [for (final row in json['categories'] as List<dynamic>) CategoryTotal.fromJson(row as Map<String, dynamic>)],
      revenueCategories = [for (final row in json['revenueCategories'] as List<dynamic>) CategoryTotal.fromJson(row as Map<String, dynamic>)];

  /// Nothing yet.
  SummaryFigures.none() : revenue = 0, expenses = 0, surplus = 0, wasReconciled = false, reconciliationDifference = 0, waiting = const WaitingFigures.none(), completionPercent = 0, categories = const [], revenueCategories = const [];

  /// Capital, VAT refunds and sales.
  final double revenue;

  /// Every approved expense: the project's cost.
  final double expenses;

  /// Revenue less expenses.
  final double surplus;

  /// True once the accounts were checked against the books.
  final bool wasReconciled;

  /// The latest check's difference.
  final double reconciliationDifference;

  /// What waits for approval: expenses, and revenue with partners' money.
  final WaitingFigures waiting;

  /// How far the work has come.
  final double completionPercent;

  /// Each category's total.
  final List<CategoryTotal> categories;

  /// Each category holding revenue items, رأس المال first as the structure orders it, adding up to [revenue] (BR-06, AC-46.7, redix-api #109).
  final List<CategoryTotal> revenueCategories;
}

/// A project's summary (UC-049), read again whenever its home comes back into view.
class Summary extends ApiObject<SummaryFigures> {
  /// The summary of the project [projectId], seen through [session].
  Summary(Session session, this.projectId) : super(session, '/projects/$projectId/summary', 'summary', (json) => SummaryFigures.fromJson(json! as Map<String, dynamic>), SummaryFigures.none());

  /// The project.
  final String projectId;
}
