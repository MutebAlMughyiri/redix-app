import '../api_list.dart';
import '../auth/session.dart';
import 'payment_method.dart';

/// A project's payment methods (UC-014), and the one way to change them. Each change returns an empty string once made, otherwise the word key of the refusal.
class PaymentMethods extends ApiList<PaymentMethod> {
  /// The payment methods of the project [projectId], seen through [session].
  PaymentMethods(Session session, this.projectId) : super(session, '/projects/$projectId/payment-methods', 'paymentMethods', PaymentMethod.fromJson);

  /// The project these payment methods belong to.
  final String projectId;

  /// Adds a payment method named [name] at the end of the list, paying from the accounts [accountIds] (redix-app #109).
  Future<String> add(String name, Set<String> accountIds) => change('/projects/$projectId/payment-methods', {'name': name, 'accountIds': accountIds.toList()});

  /// Names [method] [name], paying from the accounts [accountIds].
  Future<String> rename(PaymentMethod method, String name, Set<String> accountIds) =>
      put('/projects/$projectId/payment-methods/${method.id}', {'name': name, 'accountIds': accountIds.toList()});

  /// Takes [method] out of entry; it stays on the entries that used it.
  Future<String> disable(PaymentMethod method) => change('/projects/$projectId/payment-methods/${method.id}/disable', {});

  /// Brings the disabled [method] back into entry.
  Future<String> enable(PaymentMethod method) => change('/projects/$projectId/payment-methods/${method.id}/enable', {});

  /// Deletes [method]; one an expense was paid with is refused, and can be disabled instead.
  Future<String> delete(PaymentMethod method) => deleteAt('/projects/$projectId/payment-methods/${method.id}');
}
