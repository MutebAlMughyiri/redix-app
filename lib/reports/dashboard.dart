import '../api_object.dart';
import '../auth/session.dart';
import '../partners/capital.dart';
import 'waiting_figures.dart';

/// One item's total (BR-02), or one partner's capital under the capital line (BR-05).
class ItemTotal {
  /// A total as the API answers it.
  ItemTotal.fromJson(Map<String, dynamic> json) : id = json['id'] as String, name = json['name'] as String, total = (json['total'] as num).toDouble();

  /// The capital of the partner on [line].
  ItemTotal.partner(PartnerCapital line) : id = line.id, name = line.name, total = line.balance;

  /// The item, or the partner.
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

  /// The capital line that opens the revenue side (BR-06), opening to the partners the reader may see (BR-31).
  CategoryTotal.capital(CapitalFigures capital) : id = '', name = '', total = capital.total, items = [for (final line in capital.partners) ItemTotal.partner(line)];

  /// The category.
  final String id;

  /// Its name.
  final String name;

  /// The sum of its items.
  final double total;

  /// Each item's total.
  final List<ItemTotal> items;

  /// True for the capital line, which the app names.
  bool get isCapital => id.isEmpty;
}

/// A project's figures at a glance (UC-049, UC-063).
class DashboardFigures {
  /// The figures as the API answers them.
  DashboardFigures.fromJson(Map<String, dynamic> json)
    : revenue = (json['revenue'] as num).toDouble(),
      capital = CapitalFigures.fromJson(json['capital'] as Map<String, dynamic>),
      expenses = (json['expenses'] as num).toDouble(),
      surplus = (json['surplus'] as num).toDouble(),
      wasReconciled = json['wasReconciled'] as bool,
      reconciliationDifference = (json['reconciliationDifference'] as num).toDouble(),
      waiting = WaitingFigures.fromJson(json['waiting'] as Map<String, dynamic>),
      completionPercent = (json['completionPercent'] as num).toDouble(),
      categories = [for (final row in json['categories'] as List<dynamic>) CategoryTotal.fromJson(row as Map<String, dynamic>)],
      revenueCategories = [for (final row in json['revenueCategories'] as List<dynamic>) CategoryTotal.fromJson(row as Map<String, dynamic>)];

  /// Nothing yet.
  DashboardFigures.none() : revenue = 0, capital = CapitalFigures.none(), expenses = 0, surplus = 0, wasReconciled = false, reconciliationDifference = 0, waiting = const WaitingFigures.none(), completionPercent = 0, categories = const [], revenueCategories = const [];

  /// Capital, VAT refunds and sales.
  final double revenue;

  /// What the partners put in less what they took out, with the partners' lines the signed-in user may see (BR-31).
  final CapitalFigures capital;

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

  /// Each category holding revenue items, its total with those items'.
  final List<CategoryTotal> revenueCategories;

  /// The revenue side as the periodic report lays it out: capital, then each revenue category, adding up to [revenue] (BR-06, AC-46.7).
  List<CategoryTotal> get revenueSide => [CategoryTotal.capital(capital), ...revenueCategories];
}

/// A project's dashboard (UC-049), read again whenever its home comes back into view.
class Dashboard extends ApiObject<DashboardFigures> {
  /// The dashboard of the project [projectId], seen through [session].
  Dashboard(Session session, this.projectId) : super(session, '/projects/$projectId/dashboard', 'dashboard', (json) => DashboardFigures.fromJson(json! as Map<String, dynamic>), DashboardFigures.none());

  /// The project.
  final String projectId;
}
