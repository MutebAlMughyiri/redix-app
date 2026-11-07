import '../accounts/account.dart';

/// What a person chose to pay an entry from, and how (UC-022).
class PaymentChoice {
  /// The account last chosen; empty for none.
  var accountId = '';

  /// The payment method; empty for none.
  var paymentMethodId = '';

  /// The account it is paid from: the one chosen while [accounts] offer it, or the only one there is; empty for none.
  String chosenAccountIn(List<Account> accounts) {
    if (accounts.any((account) => account.id == accountId)) {
      return accountId;
    }
    return accounts.length == 1 ? accounts.single.id : '';
  }
}
