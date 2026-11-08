/// What waits for approval, as two figures (findings row 147): expenses, which lower the surplus once approved, and revenue with partners' money, which raises it.
class WaitingFigures {
  /// The figures as the API answers them.
  WaitingFigures.fromJson(Map<String, dynamic> json)
    : expensesCount = json['expensesCount'] as int,
      expensesAmount = (json['expensesAmount'] as num).toDouble(),
      revenueCount = json['revenueCount'] as int,
      revenueAmount = (json['revenueAmount'] as num).toDouble();

  /// Nothing waits.
  const WaitingFigures.none() : expensesCount = 0, expensesAmount = 0, revenueCount = 0, revenueAmount = 0;

  /// How many purchases and contractor payments wait.
  final int expensesCount;

  /// What they come to.
  final double expensesAmount;

  /// How many revenue entries and partners' movements wait.
  final int revenueCount;

  /// What they would add to revenue; a withdrawal takes away.
  final double revenueAmount;

  /// How many entries wait in all: what Approvals lists.
  int get count => expensesCount + revenueCount;
}
