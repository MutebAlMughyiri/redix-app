/// What kind of account holds a project's money (FR-22), as the API names it, each knowing its word.
enum AccountType {
  /// A bank account.
  bank('accounts.typeBank', 'accounts.banks'),

  /// Cash held by one person.
  cashCustody('accounts.typeCashCustody', 'accounts.custodies');

  const AccountType(this.wordKey, this.groupWordKey);

  /// The key of the word that names this type.
  final String wordKey;

  /// The key of the word over the accounts of this type on Accounts (redix-app #89).
  final String groupWordKey;
}

/// Where a project's money sits, as the API answers it. The rules live in the API; the app only draws what it is told.
class Account {
  /// The account the API describes in [json].
  Account.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = AccountType.values.byName(json['type'] as String),
      name = json['name'] as String,
      balance = (json['balance'] as num).toDouble(),
      custodianId = json['custodianId'] as String,
      custodianName = json['custodianName'] as String,
      isMine = json['isMine'] as bool,
      isActive = json['isActive'] as bool,
      isUsed = json['isUsed'] as bool? ?? false;

  /// No account yet, for the dialog that adds one.
  Account.none() : id = '', type = AccountType.bank, name = '', balance = 0, custodianId = '', custodianName = '', isMine = false, isActive = true, isUsed = false;

  /// The account's id; empty for an account not added yet.
  final String id;

  /// What kind of account it is; it never changes.
  final AccountType type;

  /// The account's name, as it was typed.
  final String name;

  /// What it holds now: what its approved entries and transfers moved; it has no opening balance (redix-app #89).
  final double balance;

  /// The user who holds it; empty when nobody does.
  final String custodianId;

  /// That user's name; empty when nobody does.
  final String custodianName;

  /// Whether the signed-in user holds it.
  final bool isMine;

  /// False once disabled: it disappears from entry and stays in the reports.
  final bool isActive;

  /// True once an entry, a check or a transfer names it, so it can only be disabled, never deleted (BR-15).
  final bool isUsed;
}
