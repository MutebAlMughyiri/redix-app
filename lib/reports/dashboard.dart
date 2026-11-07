import '../api_object.dart';
import '../auth/session.dart';

/// One item's total (BR-02).
class ItemTotal {
  /// A total as the API answers it.
  ItemTotal.fromJson(Map<String, dynamic> json) : id = json['id'] as String, name = json['name'] as String, total = (json['total'] as num).toDouble();

  /// The item.
  final String id;

  /// Its name.
  final String name;

  /// Its purchases and contractor payments.
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

  /// Each item's total.
  final List<ItemTotal> items;
}

/// A project's figures at a glance (UC-049, UC-063).
class DashboardFigures {
  /// The figures as the API answers them.
  DashboardFigures.fromJson(Map<String, dynamic> json)
    : revenue = (json['revenue'] as num).toDouble(),
      expenses = (json['expenses'] as num).toDouble(),
      surplus = (json['surplus'] as num).toDouble(),
      surplusWithoutSales = (json['surplusWithoutSales'] as num).toDouble(),
      wasReconciled = json['wasReconciled'] as bool,
      reconciliationDifference = (json['reconciliationDifference'] as num).toDouble(),
      pendingCount = json['pendingCount'] as int,
      pendingAmount = (json['pendingAmount'] as num).toDouble(),
      completionPercent = (json['completionPercent'] as num).toDouble(),
      categories = [for (final row in json['categories'] as List<dynamic>) CategoryTotal.fromJson(row as Map<String, dynamic>)];

  /// Nothing yet.
  DashboardFigures.none() : revenue = 0, expenses = 0, surplus = 0, surplusWithoutSales = 0, wasReconciled = false, reconciliationDifference = 0, pendingCount = 0, pendingAmount = 0, completionPercent = 0, categories = const [];

  /// Capital, VAT refunds and sales.
  final double revenue;

  /// Every approved expense: the project's cost.
  final double expenses;

  /// Revenue less expenses.
  final double surplus;

  /// The same without sales.
  final double surplusWithoutSales;

  /// True once the accounts were checked against the books.
  final bool wasReconciled;

  /// The latest check's difference.
  final double reconciliationDifference;

  /// How many entries wait for approval.
  final int pendingCount;

  /// What they come to.
  final double pendingAmount;

  /// How far the work has come.
  final double completionPercent;

  /// Each category's total.
  final List<CategoryTotal> categories;
}

/// A project's dashboard (UC-049), read again whenever its home comes back into view.
class Dashboard extends ApiObject<DashboardFigures> {
  /// The dashboard of the project [projectId], seen through [session].
  Dashboard(Session session, this.projectId) : super(session, '/projects/$projectId/dashboard', 'dashboard', (json) => DashboardFigures.fromJson(json! as Map<String, dynamic>), DashboardFigures.none());

  /// The project.
  final String projectId;
}
