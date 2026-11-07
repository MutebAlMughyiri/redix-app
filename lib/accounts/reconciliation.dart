import '../api_object.dart';
import '../auth/session.dart';
import 'account.dart';

/// One account against the books.
class ReconciliationBalance {
  /// A balance as the API answers it.
  ReconciliationBalance.fromJson(Map<String, dynamic> json)
    : accountId = json['accountId'] as String,
      accountName = json['accountName'] as String,
      type = AccountType.values.byName(json['type'] as String),
      booksBalance = (json['booksBalance'] as num).toDouble(),
      actualBalance = (json['actualBalance'] as num).toDouble();

  /// The account.
  final String accountId;

  /// Its name.
  final String accountName;

  /// What kind it is.
  final AccountType type;

  /// What the books say it holds now.
  final double booksBalance;

  /// What it really held at the latest check.
  final double actualBalance;
}

/// The accounts against the books (BR-08).
class ReconciliationFigures {
  /// The figures as the API answers them.
  ReconciliationFigures.fromJson(Map<String, dynamic> json)
    : at = DateTime.parse(json['at'] as String),
      surplus = (json['surplus'] as num).toDouble(),
      actualTotal = (json['actualTotal'] as num).toDouble(),
      difference = (json['difference'] as num).toDouble(),
      balances = [for (final row in json['balances'] as List<dynamic>) ReconciliationBalance.fromJson(row as Map<String, dynamic>)];

  /// Nothing yet.
  ReconciliationFigures.none() : at = DateTime(1), surplus = 0, actualTotal = 0, difference = 0, balances = const [];

  /// When the latest check was done.
  final DateTime at;

  /// What the accounts should hold.
  final double surplus;

  /// What they really held at the latest check.
  final double actualTotal;

  /// That total less the surplus.
  final double difference;

  /// Each bank account and custody.
  final List<ReconciliationBalance> balances;

  /// True once a check was done.
  bool get wasChecked => at.year > 1;
}

/// A project's accounts against its books (UC-041), and the way to enter what they really hold.
class Reconciliations extends ApiObject<ReconciliationFigures> {
  /// The figures of the project [projectId], seen through [session].
  Reconciliations(Session session, this.projectId)
    : super(session, '/projects/$projectId/reconciliations/latest', 'reconciliations', (json) => ReconciliationFigures.fromJson(json! as Map<String, dynamic>), ReconciliationFigures.none());

  /// The project.
  final String projectId;

  /// Keeps what each account really holds, by account id. Returns an empty string once kept, otherwise the word key of the refusal.
  Future<String> enter(Map<String, double> balances) => change('/projects/$projectId/reconciliations', {
    'balances': [for (final MapEntry(key: accountId, value: balance) in balances.entries) {'accountId': accountId, 'actualBalance': balance}],
  });
}
