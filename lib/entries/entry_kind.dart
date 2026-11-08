import '../auth/permission.dart';

/// What an entry is, named as the API names it, with the word key that names it: the one owner the filter, the entries list and Approvals read (findings row 163).
enum EntryKind {
  /// A purchase from a supplier.
  purchase('entries.purchases'),

  /// A payment to a contractor on a contract.
  contractorPayment('entries.contractorPayments'),

  /// Revenue on a revenue item.
  revenue('categories.tableRevenue'),

  /// A partner's contribution.
  capitalIn('capital.contribution'),

  /// A partner's withdrawal.
  capitalOut('capital.withdrawal');

  const EntryKind(this.wordKey);

  /// The key of the word that names it.
  final String wordKey;

  /// True for a purchase or a contractor payment, an expense.
  bool get isExpense => this == purchase || this == contractorPayment;

  /// What its author holds to enter it, and so to change or fix it in Add entry: an expense, [Permission.recordEntries]; revenue and a partner's money, [Permission.moveMoney] (BR-30, redix-api #110).
  Permission get recordedWith => isExpense ? Permission.recordEntries : Permission.moveMoney;
}
