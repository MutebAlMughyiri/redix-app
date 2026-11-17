import '../accounts/account.dart';
import '../settings/payment_method.dart';

/// What a person chose to pay an entry from, and how (UC-022).
class PaymentChoice {
  /// The account last chosen; empty for none.
  var accountId = '';

  /// The payment method; empty for none.
  var paymentMethodId = '';

  /// The accounts the entry may go through: the active ones of [accounts] and, for an entry that [asksPaymentMethod], only those its chosen method of
  /// [methods] pays from, none until one is chosen (redix-app #109). The one answer Add entry's form and what it sends both ask.
  List<Account> offeredIn(List<Account> accounts, {required bool asksPaymentMethod, required List<PaymentMethod> methods}) {
    final method = methods.where((method) => method.id == paymentMethodId).firstOrNull ?? PaymentMethod.none();
    return accounts.where((account) => account.isActive && (!asksPaymentMethod || method.paysFrom(account.id))).toList();
  }

  /// The account it is paid from: the one chosen while [accounts] offer it, or the only one there is; empty for none.
  String chosenAccountIn(List<Account> accounts) {
    if (accounts.any((account) => account.id == accountId)) {
      return accountId;
    }
    return accounts.length == 1 ? accounts.single.id : '';
  }
}
