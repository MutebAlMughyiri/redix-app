import '../accounts/account.dart';

/// What a person chose to pay an entry from: the account decides the source, which only narrows the choice (UC-022).
class PaymentChoice {
  /// The kind of account last chosen.
  var source = AccountType.cashCustody;

  /// The account last chosen; empty for none.
  var accountId = '';

  /// The payment method; empty for none.
  var paymentMethodId = '';

  /// The kinds of account [accounts] hold.
  List<AccountType> sourcesIn(List<Account> accounts) => AccountType.values.where((type) => accounts.any((account) => account.type == type)).toList();

  /// The kind of account in use: the one chosen while [accounts] hold it, otherwise the first they do.
  AccountType sourceIn(List<Account> accounts) {
    final sources = sourcesIn(accounts);
    return sources.isEmpty || sources.contains(source) ? source : sources.first;
  }

  /// Those of [accounts] of the kind in use.
  List<Account> accountsIn(List<Account> accounts) => accounts.where((account) => account.type == sourceIn(accounts)).toList();

  /// The account it is paid from: the one chosen, or the only one there is; empty for none.
  String chosenAccountIn(List<Account> accounts) {
    final offered = accountsIn(accounts);
    if (offered.any((account) => account.id == accountId)) {
      return accountId;
    }
    return offered.length == 1 ? offered.single.id : '';
  }
}
